class Order {
  int? id;
  DateTime date;
  String customerName;
  String? salesOrder;
  double width;
  int quantity;
  int plannedQuantity; // الحقل لمتابعة المجدول فعلياً
  double grams;
  String status;
  double totalTons;
  final double diameter;
  final double diameterWeight;
  // 🟢 الحقول الجديدة لتلبية طلبات العميل
  final String paperType; // fluting, liner, test liner
  final String priority;  // A, B, C, D, F

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
    this.paperType = 'fluting', // 👈 قيمة افتراضية للأمان
    this.priority = 'C',        // 👈 قيمة افتراضية للأمان
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'customerName': customerName,
    'salesOrder': salesOrder,
    'width': width,
    'quantity': quantity,
    'plannedQuantity': plannedQuantity,
    'grams': grams,
    'totalTons': totalTons,
    'status': status,
    'diameter': diameter,
    'diameterWeight': diameterWeight,
    'paperType': paperType, // 👈 إضافة الحقل للماب للداتابيز
    'priority': priority,   // 👈 إضافة الحقل للماب للداتابيز
  };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'],
    date: DateTime.parse(map['date']),
    customerName: map['customerName'] ?? '',
    salesOrder: map['salesOrder'],
    width: (map['width'] as num).toDouble(),
    quantity: map['quantity'] ?? 0,
    plannedQuantity: map['plannedQuantity'] ?? 0,
    grams: (map['grams'] as num).toDouble(),
    totalTons: (map['totalTons'] as num).toDouble(),
    status: map['status'] ?? 'انتظار',
    diameter: (map['diameter'] as num?)?.toDouble() ?? 0.0,
    diameterWeight: (map['diameterWeight'] as num?)?.toDouble() ?? 0.0,
    // 🟢 قراءة الحقول الجديدة من الداتابيز مع وضع قيم افتراضية للأوردرات القديمة
    paperType: map['paperType'] ?? 'fluting',
    priority: map['priority'] ?? 'C',
  );

  // دالة مساعدة لأخذ نسخة معدلة من الطلب (تم تحديثها لتشمل الحقول الجديدة)
  Order copyWith({
    int? id,
    int? plannedQuantity,
    String? status,
    String? paperType,
    String? priority,
  }) {
    return Order(
      id: id ?? this.id,
      date: this.date,
      customerName: this.customerName,
      salesOrder: this.salesOrder,
      width: this.width,
      quantity: this.quantity,
      plannedQuantity: plannedQuantity ?? this.plannedQuantity,
      grams: this.grams,
      totalTons: this.totalTons,
      status: status ?? this.status,
      diameter: this.diameter,
      diameterWeight: this.diameterWeight,
      paperType: paperType ?? this.paperType, // 👈
      priority: priority ?? this.priority,   // 👈
    );
  }
}