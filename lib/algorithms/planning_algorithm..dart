import '../models/order.dart';
import '../models/plan.dart';

// الكلاس المسؤول عن توليد خطط الإنتاج المطور
class PlanningAlgorithm {

  // أقصى عرض للماكينة (5 متر)
  static const double maxMachineWidth = 5.00;

  // أقل عرض مقبول للتشغيل الطبيعي (4.70 متر)
  static const double minMachineWidth = 4.70;

  // الدالة الأساسية لتوليد الخطط
// الدالة الأساسية بعد إضافة صمام الأمان لمنع الـ Infinite Loop نهائياً
  static List<ProductionPlan> generatePlans(
      List<Order> orders,
      List<double> gramPriority,
      {bool force = false,
      }) {

    List<ProductionPlan> finalPlans = [];

    // 1️⃣ استخراج كافة أنواع الورق المتاحة
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

        double effectiveMinWidth = force ? 0.10 : minMachineWidth;

        // 2️⃣ ترتيب الأوردرات بناءً على الأولوية
        filteredOrders.sort((a, b) => a.priority.compareTo(b.priority));

        // تحويل الأوردرات المفلترة إلى بكرات مستقلة
        List<RollUnit> availableRolls = [];
        int rollCounter = 0;

        for (var order in filteredOrders) {
          int planned = order.plannedQuantity ?? 0;
          int remainingQty = order.quantity - planned;

          if (remainingQty <= 0) continue;

          for (int i = 0; i < remainingQty; i++) {
            rollCounter++;
            availableRolls.add(
              RollUnit(
                uniqueRollId: rollCounter,
                orderId: order.id ?? 0,
                customerName: order.customerName,
                widthMeters: order.width / 100,
                widthCm: order.width,
                priority: order.priority,
              ),
            );
          }
        }

        // بدء تكوين الرصات التجميعية
        while (true) {
          // 🟢 صمام الأمان الفولاذي: لو المتاح فضي تماماً، اخرج فوراً من الـ while بدون نقاش
          if (availableRolls.isEmpty) {
            break;
          }

          CombinationResult bestResult = _findBestCombination(availableRolls, effectiveMinWidth);

          // لو الـ Backtracking رجع نتيجة فاضية أو المجموع صفر أو أقل من الحد الأدنى، اخرج فوراً
          if (bestResult.selectedRolls.isEmpty || bestResult.total < effectiveMinWidth || bestResult.total == 0) {
            break;
          }

          Map<int, PlanItem> itemsMap = {};

          for (var roll in bestResult.selectedRolls) {
            if (itemsMap.containsKey(roll.orderId)) {
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

            // إزالة البكرة المستخدمة
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
  static CombinationResult _findBestCombination(List<RollUnit> rolls, double effectiveMinWidth) {
    CombinationResult best = CombinationResult([], 0);

    void backtrack(
        int index,
        List<RollUnit> current,
        double total,
        Set<int> usedRollIds,
        ) {

      if (total > maxMachineWidth) return;

      if (total >= effectiveMinWidth && total <= maxMachineWidth) {
        if (total > best.total) {
          best = CombinationResult(List.from(current), total);
        }
        if (total == maxMachineWidth) return;
      }

      for (int i = index; i < rolls.length; i++) {
        RollUnit roll = rolls[i];

        if (!usedRollIds.contains(roll.uniqueRollId)) {
          current.add(roll);
          usedRollIds.add(roll.uniqueRollId);

          backtrack(
            i + 1,
            current,
            total + roll.widthMeters,
            usedRollIds,
          );

          usedRollIds.remove(roll.uniqueRollId);
          current.removeLast();
        }
      }
    }

    backtrack(0, [], 0, {});

    return best;
  }
}

// ============================================
// كلاس يمثل بكرة فيزيائية مستقلة واحدة
// ============================================
class RollUnit {
  final int uniqueRollId;
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