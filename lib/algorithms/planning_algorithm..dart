import '../models/order.dart';
import '../models/plan.dart';

// الكلاس المسؤول عن توليد خطط الإنتاج المطور
class PlanningAlgorithm {

  // أقصى عرض للماكينة (5 متر)
  static const double maxMachineWidth = 5.00;

  // أقل عرض مقبول للتشغيل (4.70 متر)
  static const double minMachineWidth = 4.70;

  // الدالة الأساسية لتوليد الخطط
  static List<ProductionPlan> generatePlans(
      List<Order> orders,          // كل الأوردرات
      List<double> gramPriority,   // ترتيب الجرامات المطلوب تشغيلها
      ) {

    List<ProductionPlan> finalPlans = [];

    // 1️⃣ استخراج كافة أنواع الورق المتاحة في الطلبات المتبقية (مثال: fluting, liner)
    // لفصل الإنتاج تماماً بناءً على نوع الخامة
    List<String> paperTypes = orders.map((o) => o.paperType).toSet().toList();

    for (String targetPaperType in paperTypes) {
      for (double targetGram in gramPriority) {

        // تصفية الطلبات بناءً على الجرام الحالي ونوع الخامة الحالي وشرط الانتظار
        List<Order> filteredOrders = orders
            .where((o) =>
        o.paperType == targetPaperType &&
            o.grams == targetGram &&
            o.status == "انتظار" &&
            o.quantity > 0)
            .toList();

        if (filteredOrders.isEmpty) continue;

        // 2️⃣ ترتيب الأوردرات بناءً على الأولوية (A هو الأهم، ثم B، ثم C...)
        // لضمان سحب البكر الخاص بالعملاء المهمين أولاً
        filteredOrders.sort((a, b) => a.priority.compareTo(b.priority));

        // تحويل الأوردرات إلى بكرات منفصلة (RollUnit) مع الحفاظ على ترتيب الأولويات
        List<RollUnit> availableRolls = [];
        int rollCounter = 0; // معرف فريد لكل بكرة فيزيائية مستقلة عن الـ orderId

        for (var order in filteredOrders) {
          int planned = order.plannedQuantity ?? 0;
          int remainingQty = order.quantity - planned;

          if (remainingQty <= 0) continue;

          for (int i = 0; i < remainingQty; i++) {
            rollCounter++;
            availableRolls.add(
              RollUnit(
                uniqueRollId: rollCounter, // معرف البكرة الفريد
                orderId: order.id ?? 0,
                customerName: order.customerName,
                widthMeters: order.width / 100,
                widthCm: order.width,
                priority: order.priority,
              ),
            );
          }
        }

        // بدء تكوين الرصات التجميعية بناءً على البكر المتاح المرتب بالأولويات
        while (true) {
          CombinationResult bestResult = _findBestCombination(availableRolls);

          // لو لم يجد توليفة تحقق الحد الأدنى للتشغيل نوقف اللوب لهذا الجرام والخامة
          if (bestResult.selectedRolls.isEmpty || bestResult.total < minMachineWidth) {
            break;
          }

          // تجميع عناصر الرصة الحالية ودمج المتشابه لتسهيل القراءة وتحديث الداتابيز بصورة صحيحة
          // تجميع الـ PlanItems بناءً على الـ orderId
          Map<int, PlanItem> itemsMap = {};

          for (var roll in bestResult.selectedRolls) {
            if (itemsMap.containsKey(roll.orderId)) {
              // لو العميل تكرر مقاسه في نفس الرصة (مثلاً ضربنا البكرة في 5) نزود الـ quantity
              itemsMap[roll.orderId] = PlanItem(
                orderId: roll.orderId,
                customerName: roll.customerName,
                width: roll.widthCm,
                quantity: itemsMap[roll.orderId]!.quantity + 1,
              );
            } else {
              itemsMap[roll.orderId] = PlanItem(
                orderId: roll.orderId,
                customerName: roll.customerName,
                width: roll.widthCm,
                quantity: 1,
              );
            }

            // إزالة البكرة المستخدمة من المتاح نهائياً بناءً على الـ uniqueRollId الفريد لها
            availableRolls.removeWhere((r) => r.uniqueRollId == roll.uniqueRollId);
          }

          // إضافة خطة الإنتاج المعتمدة للرصة الحالية
          finalPlans.add(
            ProductionPlan(
              date: DateTime.now(),
              grams: targetGram,
              items: itemsMap.values.toList(),
              totalWidth: bestResult.total,
              waste: maxMachineWidth - bestResult.total,
            ),
          );
        }
      }
    }

    return finalPlans;
  }

  // ==========================================================
  // دالة البحث عن أفضل توليفة (تسمح بتكرار الأوردر ومقاس العميل)
  // ==========================================================
  static CombinationResult _findBestCombination(List<RollUnit> rolls) {
    CombinationResult best = CombinationResult([], 0);

    // دالة الـ Backtracking المطورة
    void backtrack(
        int index,
        List<RollUnit> current,
        double total,
        Set<int> usedRollIds, // نمنع تكرار "البكرة نفسها" وليس "الأوردر نفسه"
        ) {

      // تجاوز الحد الأقصى لعرض السكين (5 متر) -> نرفض التوليفة
      if (total > maxMachineWidth) return;

      // لو دخلنا في النطاق الإنتاجي المسموح للماكينة
      if (total >= minMachineWidth && total <= maxMachineWidth) {
        // نختار التوليفة اللي بتقربنا أكتر للـ 5 متر (أقل هالك)
        if (total > best.total) {
          best = CombinationResult(List.from(current), total);
        }
        // لو قفلت 5 متر بالظبط نخرج فوراً لأنها النتيجة المثالية
        if (total == maxMachineWidth) return;
      }

      for (int i = index; i < rolls.length; i++) {
        RollUnit roll = rolls[i];

        // التحقق من أن البكرة الحالية لم يتم سحبها في نفس الرصة
        if (!usedRollIds.contains(roll.uniqueRollId)) {
          current.add(roll);
          usedRollIds.add(roll.uniqueRollId);

          // استدعاء ريكيرجن لباقي العناصر (البكرة التالية i + 1)
          backtrack(
            i + 1,
            current,
            total + roll.widthMeters,
            usedRollIds,
          );

          // التراجع (Backtrack) لإيجاد احتمالات أخرى
          usedRollIds.remove(roll.uniqueRollId);
          current.removeLast();
        }
      }
    }

    // بدء البحث الفعلي من أول عنصر في الليست (المرتبة بالأولوية تلقائياً)
    backtrack(0, [], 0, {});

    return best;
  }
}

// ============================================
// كلاس يمثل بكرة فيزيائية مستقلة واحدة
// ============================================
class RollUnit {
  final int uniqueRollId; // المعرّف الفريد للبكرة عشان نقدر نكرر نفس الـ orderId
  final int orderId;
  final String customerName;
  final double widthMeters;
  final double widthCm;
  final String priority;

  RollUnit({
    required this.uniqueRollId,
    required this.orderId,
    required this.customerName,
    required this.widthMeters,
    required this.widthCm,
    required this.priority,
  });
}

// ============================================
// كلاس النتيجة النهائية للتوليفة
// ============================================
class CombinationResult {
  final List<RollUnit> selectedRolls;
  final double total;

  CombinationResult(
      this.selectedRolls,
      this.total,
      );
}