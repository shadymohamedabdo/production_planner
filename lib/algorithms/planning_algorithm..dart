import '../models/order.dart';
import '../models/plan.dart';

class PlanningAlgorithm {
  static const double maxMachineWidth = 4.95;
  static const double minMachineWidth = 4.80;

  static List<ProductionPlan> generatePlans(
      List<Order> orders,
      List<double> gramPriority,
      ) {
    List<ProductionPlan> finalPlans = [];

    for (double targetGram in gramPriority) {
      List<Order> gramOrders = orders.where((o) => o.grams == targetGram).toList();
      if (gramOrders.isEmpty) continue;

      Map<double, int> inventory = {};
      for (var order in gramOrders) {
        inventory[order.width] = (inventory[order.width] ?? 0) + order.quantity;
      }

      List<double> preferredWidths = [];
      int planCounter = 1;

      while (inventory.values.any((q) => q > 0)) {
        List<double> availableWidths = inventory.keys.where((w) => inventory[w]! > 0).toList();

        // ترتيب المقاسات لضمان الأولوية للمقاسات الكبيرة أو اللي كانت شغالة
        availableWidths = sortWidthsByPreference(availableWidths, preferredWidths);

        // البحث عن أفضل توليفة (مع تفعيل نظام المرونة)
        CombinationResult bestResult = findBestCombination(availableWidths, inventory);

        // لو مفيش أي حاجة خالص (المخزن خلص)
        if (bestResult.widths.isEmpty) break;

        double currentTotal = bestResult.total;
        List<PlanItem> currentItems = [];

        for (double width in bestResult.widths) {
          inventory[width] = inventory[width]! - 1;
          int existingIndex = currentItems.indexWhere((e) => e.width == width);

          if (existingIndex != -1) {
            currentItems[existingIndex].quantity++;
          } else {
            currentItems.add(PlanItem(
              orderId: 0,
              customerName: "طلب مجمع",
              width: width,
              quantity: 1,
            ));
          }
        }

        preferredWidths = bestResult.widths;
        finalPlans.add(
          ProductionPlan(
            date: DateTime.now(),
            grams: targetGram,
            items: currentItems,
            // بنحسب التوتال والواست هنا عشان الموديل يقرأهم صح
            totalWidth: currentTotal,
            waste: maxMachineWidth - currentTotal,
          ),
        );
        planCounter++;
      }
    }
    return finalPlans;
  }

  static CombinationResult findBestCombination(
      List<double> widths,
      Map<double, int> inventory,
      ) {
    CombinationResult bestPerfect = CombinationResult([], 0, false);
    CombinationResult bestAlternative = CombinationResult([], 0, false);

    void backtrack(int index, List<double> current, double total) {
      if (total > maxMachineWidth) return;

      // تحديث أفضل البدائل (الأقرب للحد المطلوب)
      if (total > bestAlternative.total) {
        bestAlternative = CombinationResult(List.from(current), total, true);
      }

      // لو دخلنا الرينج المثالي
      if (total >= minMachineWidth && total <= maxMachineWidth) {
        if (total > bestPerfect.total) {
          bestPerfect = CombinationResult(List.from(current), total, true);
        }
      }

      // التغيير هنا: بنمر على المقاسات بالترتيب (index)
      // وكل مقاس بناخد منه بكرة واحدة بس في النقلة دي
      for (int i = index; i < widths.length; i++) {
        double width = widths[i];

        // التأكد إن المقاس لسه موجود في المخزن
        if (inventory[width]! > 0) {
          // جرب تاخد بكرة واحدة بس
          current.add(width);

          // الانتقال للمقاس اللي بعده (i + 1) عشان نضمن عدم التكرار في نفس النقلة
          backtrack(i + 1, current, total + width);

          current.removeLast();
        }
      }
    }

    // بنبدأ من أول مقاس (index 0)
    backtrack(0, [], 0);

    return bestPerfect.total > 0 ? bestPerfect : bestAlternative;
  }

  static List<double> sortWidthsByPreference(List<double> widths, List<double> preferred) {
    widths.sort((a, b) {
      bool aPref = preferred.contains(a);
      bool bPref = preferred.contains(b);
      if (aPref && !bPref) return -1;
      if (!aPref && bPref) return 1;
      return b.compareTo(a); // من الأكبر للأصغر
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