class Order {
  int? id;
  DateTime date;
  String customerName;
  double width;
  int quantity;
  double grams;
  double totalTons;
  bool isPlanned;
  final double diameter;       // القطر (120, 125, 140)
  final double diameterWeight; // الوزن المعادل (8, 8.5, 11.5)

  Order({
    this.id,
    required this.date,
    required this.customerName,
    required this.width,
    required this.quantity,
    required this.grams,
    required this.totalTons,
    this.isPlanned = false,
    required this.diameter,
    required this.diameterWeight,
  });

  // تحويل الكائن إلى Map لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'customerName': customerName,
    'width': width,
    'quantity': quantity,
    'grams': grams,
    'totalTons': totalTons,
    'isPlanned': isPlanned ? 1 : 0,
    'diameter': diameter,             // ضفنا السطر ده
    'diameterWeight': diameterWeight, // ضفنا السطر ده
  };

  // تحويل الـ Map القادم من قاعدة البيانات إلى كائن Order
  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'],
    date: DateTime.parse(map['date']),
    customerName: map['customerName'],
    width: map['width'],
    quantity: map['quantity'],
    grams: map['grams'],
    totalTons: map['totalTons'],
    isPlanned: map['isPlanned'] == 1,
    diameter: map['diameter'] ?? 120.0,             // ضفنا السطر ده مع قيمة افتراضية
    diameterWeight: map['diameterWeight'] ?? 8.0,   // ضفنا السطر ده مع قيمة افتراضية
  );
}