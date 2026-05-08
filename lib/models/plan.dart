class ProductionPlan {
  int? id;
  DateTime date;
  double grams;
  List<PlanItem> items;
  double totalWidth;
  double waste;

  ProductionPlan({
    this.id,
    required this.date,
    required this.grams,
    required this.items,
  })  : totalWidth = items.fold(0, (sum, item) => sum + (item.width * item.quantity)),
        waste = (4.95 - items.fold(0, (sum, item) => sum + (item.width * item.quantity)))
            .clamp(0, 4.95);
}

class PlanItem {
  final int orderId;
  final String customerName;
  final double width;
  int quantity;

  PlanItem({
    required this.orderId,
    required this.customerName,
    required this.width,
    required this.quantity,
  });
}