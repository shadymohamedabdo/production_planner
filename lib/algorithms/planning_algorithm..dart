import '../models/order.dart';
import '../models/plan.dart';

// الكلاس المسؤول عن توليد خطط الإنتاج
class PlanningAlgorithm {

  // أقصى عرض للماكينة
  static const double maxMachineWidth = 5.00;

  // أقل عرض مقبول للتشغيل
  static const double minMachineWidth = 4.70;

  // الدالة الأساسية لتوليد الخطط
  static List<ProductionPlan> generatePlans(
      List<Order> orders,          // كل الأوردرات
      List<double> gramPriority,   // ترتيب الجرامات المطلوب تشغيلها
      ) {

    // الليست النهائية اللي هتتشال فيها كل الرصات
    List<ProductionPlan> finalPlans = [];

    // نمشي على كل جرام حسب الأولوية
    for (double targetGram in gramPriority) {

      // نجيب الأوردرات الخاصة بالجرام الحالي فقط
      // وكمان لازم تكون حالتها انتظار ولسه فيها كمية
      List<Order> gramOrders = orders
          .where((o) =>
      o.grams == targetGram &&
          o.status == "انتظار" &&
          o.quantity > 0)
          .toList();

      // لو مفيش أوردرات بالجرام دا نعديه
      if (gramOrders.isEmpty) continue;

      // هنا هنحول كل الأوردرات لبكرات منفصلة
      // يعني لو أوردر فيه 5 بكرات → يتحول لـ 5 RollUnit
      List<RollUnit> availableRolls = [];

      for (var order in gramOrders) {

        // بنكرر حسب عدد البكر
        for (int i = 0; i < order.quantity; i++) {

          availableRolls.add(
            RollUnit(
              orderId: order.id ?? 0,
              customerName: order.customerName,

              // تحويل المقاس من سم لمتر
              widthMeters: order.width / 100,

              // الاحتفاظ بالمقاس الأصلي بالسم
              widthCm: order.width,
            ),
          );
        }
      }

      // لوب مستمرة لتكوين الرصات
      while (true) {

        // البحث عن أفضل توليفة ممكنة
        CombinationResult bestResult =
        _findBestCombination(availableRolls);

        // لو ملقاش توليفة مناسبة يوقف
        if (bestResult.selectedRolls.isEmpty ||
            bestResult.total < minMachineWidth) {
          break;
        }

        // عناصر الرصة الحالية
        List<PlanItem> currentItems = [];

        // نمشي على البكرات اللي اختارها
        for (var roll in bestResult.selectedRolls) {

          // نضيفها للرصة
          currentItems.add(
            PlanItem(
              orderId: roll.orderId,
              customerName: roll.customerName,
              width: roll.widthCm,
              quantity: 1,
            ),
          );

          // نحذف البكرة من المتاح
          // عشان متستخدمش تاني
          availableRolls.remove(roll);
        }

        // إنشاء خطة إنتاج جديدة
        finalPlans.add(
          ProductionPlan(
            date: DateTime.now(),

            // الجرام الحالي
            grams: targetGram,

            // البكرات اللي اتجمعت
            items: currentItems,

            // إجمالي العرض
            totalWidth: bestResult.total,

            // الهالك = أقصى عرض - المستخدم
            waste: maxMachineWidth - bestResult.total,
          ),
        );
      }
    }

    // نرجع كل الرصات النهائية
    return finalPlans;
  }

  // ============================================
  // دالة البحث عن أفضل توليفة
  // ============================================

  static CombinationResult _findBestCombination(
      List<RollUnit> rolls) {

    // أفضل نتيجة لحد دلوقتي
    CombinationResult best =
    CombinationResult([], 0);

    // دالة Backtracking
    void backtrack(
        int index,
        List<RollUnit> current,
        double total,
        Set<int> usedOrderIds,
        ) {

      // لو العرض عدى الحد الأقصى نوقف
      if (total > maxMachineWidth) return;

      // لو دخلنا في الرينج المطلوب
      if (total >= minMachineWidth &&
          total <= maxMachineWidth) {

        // لو النتيجة الحالية أفضل من القديمة
        if (total > best.total) {

          // نخزنها كأفضل توليفة
          best = CombinationResult(
            List.from(current),
            total,
          );
        }

        // لو وصلنا 5 متر بالظبط خلاص ممتاز
        if (total == maxMachineWidth) return;
      }

      // نمشي على كل البكرات
      for (int i = index; i < rolls.length; i++) {

        RollUnit roll = rolls[i];

        // الشرط المهم:
        // مينفعش نفس الأوردر يدخل مرتين
        if (!usedOrderIds.contains(roll.orderId)) {

          // نضيف البكرة الحالية
          current.add(roll);

          // نسجل الـ ID إنه اتستخدم
          usedOrderIds.add(roll.orderId);

          // نكمل البحث
          backtrack(
            i + 1,
            current,
            total + roll.widthMeters,
            usedOrderIds,
          );

          // Backtracking
          // نرجع الحالة زي ما كانت
          usedOrderIds.remove(roll.orderId);
          current.removeLast();
        }
      }
    }

    // بدء البحث
    backtrack(0, [], 0, {});

    // إرجاع أفضل توليفة
    return best;
  }
}

// ============================================
// كلاس يمثل بكرة واحدة فقط
// ============================================

class RollUnit {

  // رقم الأوردر
  final int orderId;

  // اسم العميل
  final String customerName;

  // العرض بالمتر
  final double widthMeters;

  // العرض بالسم
  final double widthCm;

  RollUnit({
    required this.orderId,
    required this.customerName,
    required this.widthMeters,
    required this.widthCm,
  });
}

// ============================================
// كلاس النتيجة النهائية للتوليفة
// ============================================

class CombinationResult {

  // البكرات المختارة
  final List<RollUnit> selectedRolls;

  // إجمالي العرض
  final double total;

  CombinationResult(
      this.selectedRolls,
      this.total,
      );
}