import '../models/order.dart';
import '../models/plan.dart';

// موديل جديد لجمع النتيجة النهائية شاملة الفواضل
class PlanningResult {
  final List<ProductionPlan> plans;
  final Map<double, Map<double, int>> leftoversByGram; // {جرام: {عرض: كمية}}

  PlanningResult({required this.plans, required this.leftoversByGram});
}

class PlanningAlgorithm {
  static const double maxMachineWidth = 4.95;
  static const double minMachineWidth = 4.80;

  static PlanningResult generatePlans(
      List<Order> orders,
      List<double> gramPriority,
      ) {
    List<ProductionPlan> finalPlans = [];
    Map<double, Map<double, int>> allLeftovers = {};

    for (double targetGram in gramPriority) {
      List<Order> gramOrders = orders.where((o) => o.grams == targetGram).toList();
      if (gramOrders.isEmpty) continue;

      Map<double, int> inventory = {};
      for (var order in gramOrders) {
        inventory[order.width] = (inventory[order.width] ?? 0) + order.quantity;
      }

      List<double> preferredWidths = [];

      while (inventory.values.any((q) => q > 0)) {
        List<double> availableWidths = inventory.keys.where((w) => inventory[w]! > 0).toList();

        // تحسين: الترتيب التنازلي يسرع عملية البحث
        availableWidths.sort((a, b) => b.compareTo(a));
        availableWidths = sortWidthsByPreference(availableWidths, preferredWidths);

        CombinationResult bestResult = findBestCombination(availableWidths, inventory);

        if (!bestResult.valid) break;

        List<PlanItem> currentItems = [];
        for (double width in bestResult.widths) {
          inventory[width] = inventory[width]! - 1;
          int existingIndex = currentItems.indexWhere((e) => e.width == width);

          if (existingIndex != -1) {
            currentItems[existingIndex].quantity++;
          } else {
            currentItems.add(PlanItem(orderId: 0, customerName: "مجمع", width: width, quantity: 1));
          }
        }

        preferredWidths = bestResult.widths;
        finalPlans.add(ProductionPlan(date: DateTime.now(), grams: targetGram, items: currentItems));
      }

      // تجميع ما تبقى من هذا الجرام
      Map<double, int> gramLeftovers = Map.from(inventory)..removeWhere((k, v) => v <= 0);
      if (gramLeftovers.isNotEmpty) allLeftovers[targetGram] = gramLeftovers;
    }

    return PlanningResult(plans: finalPlans, leftoversByGram: allLeftovers);
  }

  static CombinationResult findBestCombination(List<double> widths, Map<double, int> inventory) {
    CombinationResult bestResult = CombinationResult([], 0, false);

    void backtrack(List<double> current, double total, Map<double, int> tempInventory) {
      if (total > maxMachineWidth) return;

      if (total >= minMachineWidth && total <= maxMachineWidth) {
        if (total > bestResult.total) {
          bestResult = CombinationResult(List.from(current), total, true);
        }
        // لو وصلنا لأقصى عرض ممكن (4.95) نوقف البحث هنا توفيراً للوقت
        if (total == maxMachineWidth) return;
      }

      for (double width in widths) {
        if (tempInventory[width]! <= 0) continue;

        inventory[width] = inventory[width]! - 1;
        current.add(width);

        backtrack(current, total + width, tempInventory);

        if (bestResult.total == maxMachineWidth) return; // الخروج المبكر في حال الوصول للمثالية

        current.removeLast();
        inventory[width] = inventory[width]! + 1;
      }
    }

    backtrack([], 0, Map.from(inventory));
    return bestResult;
  }

  static List<double> sortWidthsByPreference(List<double> widths, List<double> preferred) {
    widths.sort((a, b) {
      bool aPref = preferred.contains(a);
      bool bPref = preferred.contains(b);
      if (aPref && !bPref) return -1;
      if (!aPref && bPref) return 1;
      return b.compareTo(a);
    });
    return widths;
  }
}

class CombinationResult {
  final List<double> widths;
  final double total;
  final bool valid;
  CombinationResult(this.widths, this.total, this.valid);
}