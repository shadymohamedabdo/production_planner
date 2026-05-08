class Order {
  int? id;
  DateTime date;
  String customerName;
  double width;
  int quantity;
  double grams;
  double totalTons;
  bool isPlanned;

  Order({
    this.id,
    required this.date,
    required this.customerName,
    required this.width,
    required this.quantity,
    required this.grams,
    required this.totalTons,
    this.isPlanned = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'customerName': customerName,
    'width': width,
    'quantity': quantity,
    'grams': grams,
    'totalTons': totalTons,
    'isPlanned': isPlanned ? 1 : 0,
  };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'],
    date: DateTime.parse(map['date']),
    customerName: map['customerName'],
    width: map['width'],
    quantity: map['quantity'],
    grams: map['grams'],
    totalTons: map['totalTons'],
    isPlanned: map['isPlanned'] == 1,
  );
}