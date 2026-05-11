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
      // جلب الطلبات اللي في "الانتظار" فقط لهذا الجرام
      List<Order> gramOrders = orders.where((o) => o.grams == targetGram && o.status == "انتظار").toList();
      if (gramOrders.isEmpty) continue;

      // بناء المخزون المتاح
      Map<double, int> inventory = {};
      for (var order in gramOrders) {
        double widthInMeters = order.width / 100;
        inventory[widthInMeters] = (inventory[widthInMeters] ?? 0) + order.quantity;
      }

      // محاولة استخراج تجمعات صالحة (4.70 - 5.00)
      while (true) {
        List<double> availableWidths = inventory.keys.where((w) => inventory[w]! > 0).toList();

        // البحث عن أفضل توليفة (بشرط عدم تكرار المقاس)
        CombinationResult bestResult = findBestCombination(availableWidths, inventory);

        // التعديل: لو ملقيناش تجميعه فوق الـ 4.70 نوقف فوراً
        if (bestResult.widths.isEmpty || bestResult.total < minMachineWidth) {
          break;
        }

        List<PlanItem> currentItems = [];
        for (double width in bestResult.widths) {
          inventory[width] = inventory[width]! - 1; // خصم بكرة واحدة

          double widthInCm = width * 100;
          var originalOrder = gramOrders.firstWhere((o) => o.width == widthInCm);

          currentItems.add(PlanItem(
            orderId: originalOrder.id ?? 0,
            customerName: originalOrder.customerName,
            width: widthInCm,
            quantity: 1, // دائماً بكرة واحدة لكل مقاس في الطقم
          ));
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

  static CombinationResult findBestCombination(
      List<double> widths,
      Map<double, int> inventory,
      ) {
    CombinationResult best = CombinationResult([], 0, false);

    void backtrack(int index, List<double> current, double total) {
      if (total > maxMachineWidth) return;

      // لو وصلنا للنطاق المطلوب، بنحفظ النتيجة لو هي أفضل (أقل هالك)
      if (total >= minMachineWidth && total <= maxMachineWidth) {
        if (total > best.total) {
          best = CombinationResult(List.from(current), total, true);
        }
        // لو وصلنا لـ 5.00 بالظبط (الكفاءة القصوى) ممكن نوقف بحث
        if (total == maxMachineWidth) return;
      }

      for (int i = index; i < widths.length; i++) {
        double w = widths[i];

        // شرطك الأساسي: عدم التكرار (inventory هنا مش محتاجين نخصم منه
        // لأننا بنمرر i + 1 في الـ recursion لضمان عدم الرجوع لنفس المقاس)
        current.add(w);
        backtrack(i + 1, current, total + w); // i + 1 تمنع تكرار المقاس في نفس الطقم
        current.removeLast();
      }
    }

    backtrack(0, [], 0);
    return best;
  }
}

class CombinationResult {
  final List<double> widths;
  final double total;
  final bool valid;
  CombinationResult(this.widths, this.total, this.valid);
}
