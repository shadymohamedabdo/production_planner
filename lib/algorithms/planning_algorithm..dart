import '../models/order.dart';
import '../models/plan.dart';

class PlanningAlgorithm {
  static const double maxMachineWidth = 5.00;
  static const double minMachineWidth = 4.70;

  static List<ProductionPlan> generatePlans(
      List<Order> orders,
      List<double> gramPriority,
      ) {
    List<ProductionPlan> finalPlans = [];

    for (double targetGram in gramPriority) {
      // جلب الطلبات المتاحة (انتظار وبها كمية)
      List<Order> gramOrders = orders
          .where((o) => o.grams == targetGram && o.status == "انتظار" && o.quantity > 0)
          .toList();

      if (gramOrders.isEmpty) continue;

      // تحويل المخزن إلى قائمة من "البكرات المنفردة" مع الحفاظ على الـ ID
      // كل بكرة هنا بنعتبرها قطعة مستقلة
      List<RollUnit> availableRolls = [];
      for (var order in gramOrders) {
        for (int i = 0; i < order.quantity; i++) {
          availableRolls.add(RollUnit(
            orderId: order.id ?? 0,
            customerName: order.customerName,
            widthMeters: order.width / 100,
            widthCm: order.width,
          ));
        }
      }

      while (true) {
        // البحث عن أفضل توليفة باستخدام بكرات من IDs مختلفة في نفس الطقم
        CombinationResult bestResult = _findBestCombination(availableRolls);

        if (bestResult.selectedRolls.isEmpty || bestResult.total < minMachineWidth) {
          break; // لا توجد رصة تحقق الشرط (4.70 - 5.00)
        }

        List<PlanItem> currentItems = [];
        for (var roll in bestResult.selectedRolls) {
          // إضافة البكرة للطقم
          currentItems.add(PlanItem(
            orderId: roll.orderId,
            customerName: roll.customerName,
            width: roll.widthCm,
            quantity: 1,
          ));

          // حذف هذه البكرة تحديداً من المتاح حتى لا تُستخدم في نفس الطقم أو أطقم تالية
          availableRolls.remove(roll);
        }

        finalPlans.add(
          ProductionPlan(
            date: DateTime.now(),
            grams: targetGram,
            items: currentItems,
            totalWidth: bestResult.total,
            waste: maxMachineWidth - bestResult.total,
          ),
        );
      }
    }
    return finalPlans;
  }

  static CombinationResult _findBestCombination(List<RollUnit> rolls) {
    CombinationResult best = CombinationResult([], 0);

    void backtrack(int index, List<RollUnit> current, double total, Set<int> usedOrderIds) {
      if (total > maxMachineWidth) return;

      // إذا وصلنا للنطاق المطلوب
      if (total >= minMachineWidth && total <= maxMachineWidth) {
        if (total > best.total) {
          best = CombinationResult(List.from(current), total);
        }
        if (total == maxMachineWidth) return;
      }

      for (int i = index; i < rolls.length; i++) {
        RollUnit roll = rolls[i];

        // الشرط الجوهري: لا تأخذ بكرة من نفس الـ Order ID في نفس الرصة
        if (!usedOrderIds.contains(roll.orderId)) {
          current.add(roll);
          usedOrderIds.add(roll.orderId);

          // ننتقل لـ i + 1 لأننا نعتبر القائمة بكرات فردية
          backtrack(i + 1, current, total + roll.widthMeters, usedOrderIds);

          // إرجاع الحالة (Backtracking)
          usedOrderIds.remove(roll.orderId);
          current.removeLast();
        }
      }
    }

    // نمرر Set لتتبع الـ IDs المستخدمة في الطقم الحالي
    backtrack(0, [], 0, {});
    return best;
  }
}

// كلاس مساعد لتمثيل البكرة الواحدة
class RollUnit {
  final int orderId;
  final String customerName;
  final double widthMeters;
  final double widthCm;

  RollUnit({
    required this.orderId,
    required this.customerName,
    required this.widthMeters,
    required this.widthCm,
  });
}

class CombinationResult {
  final List<RollUnit> selectedRolls;
  final double total;
  CombinationResult(this.selectedRolls, this.total);
}