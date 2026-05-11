class Order {
  int? id;
  DateTime date;
  String customerName;
  double width;
  int quantity;
  double grams;
  String status; // غيرنا isPlanned لـ status
  double totalTons;
  final double diameter;
  final double diameterWeight;

  Order({
    this.id,
    required this.date,
    required this.customerName,
    required this.width,
    required this.quantity,
    required this.grams,
    required this.totalTons,
    this.status = "انتظار", // القيمة الافتراضية نصية
    required this.diameter,
    required this.diameterWeight,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'customerName': customerName,
    'width': width,
    'quantity': quantity,
    'grams': grams,
    'totalTons': totalTons,
    'status': status, // بنبعت النص للداتا بيز
    'diameter': diameter,
    'diameterWeight': diameterWeight,
  };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'],
    date: DateTime.parse(map['date']),
    customerName: map['customerName'],
    width: (map['width'] as num).toDouble(),
    quantity: map['quantity'],
    grams: (map['grams'] as num).toDouble(),
    totalTons: (map['totalTons'] as num).toDouble(),
    status: map['status'] ?? 'انتظار', // بنستلم النص
    diameter: (map['diameter'] as num?)?.toDouble() ?? 120.0,
    diameterWeight: (map['diameterWeight'] as num?)?.toDouble() ?? 8.0,
  );
}