class Order {
  int? id;
  DateTime date;
  String customerName;
  String? salesOrder;
  double width;
  int quantity;
  int plannedQuantity; // الحقل الجديد لمتابعة المجدول فعلياً
  double grams;
  String status;
  double totalTons;
  final double diameter;
  final double diameterWeight;

  Order({
    this.id,
    required this.date,
    required this.customerName,
    this.salesOrder,
    required this.width,
    required this.quantity,
    this.plannedQuantity = 0, // القيمة الافتراضية صفر
    required this.grams,
    required this.totalTons,
    this.status = "انتظار",
    required this.diameter,
    required this.diameterWeight,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'customerName': customerName,
    'salesOrder': salesOrder,
    'width': width,
    'quantity': quantity,
    'plannedQuantity': plannedQuantity, // إضافة الحقل للماب
    'grams': grams,
    'totalTons': totalTons,
    'status': status,
    'diameter': diameter,
    'diameterWeight': diameterWeight,
  };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'],
    date: DateTime.parse(map['date']),
    customerName: map['customerName'],
    salesOrder: map['salesOrder'],
    width: (map['width'] as num).toDouble(),
    quantity: map['quantity'],
    plannedQuantity: map['plannedQuantity'] ?? 0, // قراءة الحقل من الداتابيز
    grams: (map['grams'] as num).toDouble(),
    totalTons: (map['totalTons'] as num).toDouble(),
    status: map['status'] ?? 'انتظار',
    diameter: (map['diameter'] as num?)?.toDouble() ?? 0.0,
    diameterWeight: (map['diameterWeight'] as num?)?.toDouble() ?? 0.0,
  );

  // دالة مساعدة لو حابب تاخد نسخة معدلة من الطلب
  Order copyWith({
    int? id,
    int? plannedQuantity,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      date: date,
      customerName: customerName,
      salesOrder: salesOrder,
      width: width,
      quantity: quantity,
      plannedQuantity: plannedQuantity ?? this.plannedQuantity,
      grams: grams,
      totalTons: totalTons,
      status: status ?? this.status,
      diameter: diameter,
      diameterWeight: diameterWeight,
    );
  }
}