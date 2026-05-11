import 'order.dart';

class ProductionPlan {
  int? id; // معرف فريد للخطة
  final DateTime date;
  final double grams;
   List<PlanItem> items;

  // ضيف السطرين دول هنا
  final double totalWidth;
  final double waste;

  ProductionPlan({
    this.id,

    required this.date,
    required this.grams,
    required this.items,
    // وضيفهم في الـ Constructor كدة
    required this.totalWidth,
    required this.waste,
  });
}

class PlanItem {
  final int orderId;
  final String customerName;
  final double width;
  int quantity; // شلنا final عشان لو حبيت تعدل الكمية برمجياً

  PlanItem({
    required this.orderId,
    required this.customerName,
    required this.width,
    required this.quantity,
  });
}