import '../models/order.dart';
import '../models/plan.dart';

class PlanningAlgorithm {
  // التعديل الأول: القيم الجديدة للماكينة
  static const double maxMachineWidth = 5.00; // الحد الأقصى
  static const double minMachineWidth = 4.70; // الحد الأدنى المطلق

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
        // بنخزن المقاس بالمتر عشان الحسبة تظبط (بقسم على 100 لو المقاس بالسنتي)
        double widthInMeters = order.width / 100;
        inventory[widthInMeters] = (inventory[widthInMeters] ?? 0) + order.quantity;
      }

      while (inventory.values.any((q) => q > 0)) {
        List<double> availableWidths = inventory.keys.where((w) => inventory[w]! > 0).toList();

        // البحث عن أفضل توليفة في النطاق (4.70 - 5.00)
        CombinationResult bestResult = findBestCombination(availableWidths, inventory);

        // التعديل الجوهري: لو المجموع أقل من 4.70 نوقف ولا ننتج هذه الخطة
        if (bestResult.widths.isEmpty || bestResult.total < minMachineWidth) {
          print("لا توجد توليفة كافية للمقاسات المتبقية في نطاق التشغيل.");
          break;
        }

        double currentTotal = bestResult.total;
        List<PlanItem> currentItems = [];

// ... داخل دالة generatePlans ...

// ... داخل دالة generatePlans وتحديداً داخل الـ for loop الخاص بـ widths ...

        for (double width in bestResult.widths) {
          inventory[width] = inventory[width]! - 1;

          double widthInCm = width * 100;
          // البحث عن العميل صاحب هذا المقاس في الأوردرات
          var originalOrder = gramOrders.firstWhere((o) => o.width == widthInCm);

          // البحث إذا كان هذا المقاس (بنفس العرض) موجود مسبقاً في قائمة النقلة الحالية
          int existingIndex = currentItems.indexWhere((e) => e.width == widthInCm);

          if (existingIndex != -1) {
            // المقاس موجود مسبقاً، نزود الكمية فقط
            currentItems[existingIndex].quantity++;

            // ملاحظة: لو حابب تجمع الأسامي هنا، لازم الحقل ميكونش final
            // أو الأفضل إننا نعتمد على اسم العميل الأول للمقاس ده في العرض
          } else {
            // إضافة مقاس جديد للنقلة باسم صاحبه الحقيقي
            currentItems.add(PlanItem(
              orderId: originalOrder.id ?? 0,
              customerName: originalOrder.customerName, // اسم العميل الحقيقي
              width: widthInCm,
              quantity: 1,
            ));
          }
        }        finalPlans.add(
          ProductionPlan(
            date: DateTime.now(),
            grams: targetGram,
            items: currentItems,
            totalWidth: currentTotal,
            waste: maxMachineWidth - currentTotal,
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
      // لو عدينا الـ 5 متر، ده حل مرفوض
      if (total > maxMachineWidth) return;

      // لو المجموع بين 4.70 و 5.00، بنشوف لو ده أفضل من اللي لقيناه قبل كده
      if (total >= minMachineWidth && total <= maxMachineWidth) {
        if (total > best.total) {
          best = CombinationResult(List.from(current), total, true);
        }
      }

      for (int i = index; i < widths.length; i++) {
        double w = widths[i];
        if (inventory[w]! > 0) {
          inventory[w] = inventory[w]! - 1; // "احجز" بكرة للتجربة
          current.add(w);

          backtrack(i, current, total + w); // i وليس i+1 لو مسموح بتكرار نفس المقاس في الرصة

          current.removeLast();
          inventory[w] = inventory[w]! + 1; // "فك الحجز"
        }
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