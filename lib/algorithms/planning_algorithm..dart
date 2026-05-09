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

    print("=============== START PRODUCTION ===============");

    for (double targetGram in gramPriority) {
      print("\n########## تشغيل جرام $targetGram ##########");

      /// فلترة حسب الجرام
      List<Order> gramOrders =
      orders.where((o) => o.grams == targetGram).toList();

      if (gramOrders.isEmpty) continue;

      /// تجميع المقاسات المتشابهة
      Map<double, int> inventory = {};

      for (var order in gramOrders) {
        inventory[order.width] =
            (inventory[order.width] ?? 0) + order.quantity;
      }

      print("\nالمخزون المجمع:");

      inventory.forEach((width, qty) {
        print("عرض: $width م | كمية: $qty");
      });

      /// المقاسات السابقة للحفاظ على استقرار التشغيل
      List<double> preferredWidths = [];

      int planCounter = 1;

      while (inventory.values.any((q) => q > 0)) {
        print("\n----------------------------------------");
        print("نقلة رقم $planCounter");

        List<double> availableWidths = inventory.keys
            .where((w) => inventory[w]! > 0)
            .toList();

        /// ترتيب حسب الأولوية السابقة
        availableWidths =
            sortWidthsByPreference(availableWidths, preferredWidths);

        print("\nالمقاسات المتاحة:");
        print(availableWidths);

        /// أفضل توليفة
        CombinationResult bestResult =
        findBestCombination(availableWidths, inventory);

        /// لو مفيش توليفة مناسبة
        if (!bestResult.valid) {
          print("\n❌ لا يوجد توليفة مناسبة ضمن الرينج");
          break;
        }

        double currentTotal = bestResult.total;

        print("\n✅ أفضل توليفة تم إيجادها:");
        print(bestResult.widths);
        print("الإجمالي = ${currentTotal.toStringAsFixed(2)}");

        /// تحويل التوليفة لـ PlanItems
        List<PlanItem> currentItems = [];

        for (double width in bestResult.widths) {
          inventory[width] = inventory[width]! - 1;

          int existingIndex =
          currentItems.indexWhere((e) => e.width == width);

          if (existingIndex != -1) {
            currentItems[existingIndex].quantity++;
          } else {
            currentItems.add(
              PlanItem(
                orderId: 0,
                customerName: "طلب مجمع",
                width: width,
                quantity: 1,
              ),
            );
          }
        }

        /// حفظ المقاسات الحالية
        preferredWidths = bestResult.widths;

        print("\nالمقاسات المفضلة الجديدة:");
        print(preferredWidths);

        print("\n========== تفاصيل النقلة ==========");

        for (var item in currentItems) {
          print("عرض ${item.width} × ${item.quantity}");
        }

        print(
            "\nالإجمالي النهائي = ${currentTotal.toStringAsFixed(2)}");

        print(
            "الهالك = ${(maxMachineWidth - currentTotal).toStringAsFixed(2)}");

        print("==================================");

        finalPlans.add(
          ProductionPlan(
            date: DateTime.now(),
            grams: targetGram,
            items: currentItems,
          ),
        );

        planCounter++;
      }

      print("\nانتهاء تشغيل جرام $targetGram");
    }

    print("\n=============== END PRODUCTION ===============");
    print("عدد النقلات النهائي = ${finalPlans.length}");

    return finalPlans;
  }

  /// ===========================================
  /// البحث عن أفضل Combination
  /// ===========================================

  static CombinationResult findBestCombination(
      List<double> widths,
      Map<double, int> inventory,
      ) {
    CombinationResult bestResult =
    CombinationResult([], 0, false);

    void backtrack(
        List<double> current,
        double total,
        Map<double, int> tempInventory,
        ) {
      /// لو تخطينا الحد
      if (total > maxMachineWidth) {
        return;
      }

      /// لو دخلنا الرينج المطلوب
      if (total >= minMachineWidth &&
          total <= maxMachineWidth) {
        /// اختيار الأقرب لـ 4.95
        if (total > bestResult.total) {
          bestResult =
              CombinationResult(List.from(current), total, true);
        }
      }

      /// تجربة كل المقاسات
      for (double width in widths) {
        if (tempInventory[width]! <= 0) continue;

        tempInventory[width] = tempInventory[width]! - 1;

        current.add(width);

        backtrack(
          current,
          total + width,
          tempInventory,
        );

        current.removeLast();

        tempInventory[width] = tempInventory[width]! + 1;
      }
    }

    backtrack(
      [],
      0,
      Map<double, int>.from(inventory),
    );

    return bestResult;
  }

  /// ===========================================
  /// ترتيب المقاسات
  /// ===========================================

  static List<double> sortWidthsByPreference(
      List<double> widths,
      List<double> preferred,
      ) {
    widths.sort((a, b) {
      bool aPreferred = preferred.contains(a);
      bool bPreferred = preferred.contains(b);

      if (aPreferred && !bPreferred) return -1;

      if (!aPreferred && bPreferred) return 1;

      return b.compareTo(a);
    });

    return widths;
  }
}

/// ===========================================
/// موديل نتيجة التوليفة
/// ===========================================

class CombinationResult {
  final List<double> widths;
  final double total;
  final bool valid;

  CombinationResult(
      this.widths,
      this.total,
      this.valid,
      );
}