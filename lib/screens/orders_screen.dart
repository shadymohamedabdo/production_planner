import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/order.dart';
import '../widgets/order_form.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // تحميل البيانات المحدثة من الداتا بيز
  Future<void> _loadOrders() async {
    final data = await db.getAllOrders();
    setState(() => _orders = data);
  }

  // حذف طلب واحد
  Future<void> _deleteOrder(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteOrder(id);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الطلب بنجاح')),
        );
      }
    }
  }

  // تعديل طلب
  Future<void> _editOrder(Order order) async {
    await showDialog(
      context: context,
      builder: (_) => OrderForm(
        order: order,
        onSaved: _loadOrders,
      ),
    );
  }

  // مسح كل الطلبات
  Future<void> _deleteAllOrders() async {
    if (_orders.isEmpty) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح كل البيانات'),
        content: const Text('هل أنت متأكد أنك تريد مسح جميع الطلبات؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.clearAllOrders();
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح جميع الطلبات بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطلبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _deleteAllOrders,
            tooltip: 'مسح الكل',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => OrderForm(onSaved: _loadOrders),
          );
        },
        label: const Text('طلب جديد'),
        icon: const Icon(Icons.add),
      ),
      body: _orders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('لا توجد طلبات مسجلة حالياً', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadOrders,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                columnSpacing: 15,
                columns: const [
                  DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('العرض', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('الجرام', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('الوزن الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('القطر', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('متوسط الوزن', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('بكر', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _orders.map((o) {
                  // حسابات العرض في الجدول
                  double avgRollWeight = o.width * o.diameterWeight; // المتوسط الجديد: العرض × معامل القطر
                  double totalWeightInKilo = o.totalTons * 1000; // تحويل الطن لكيلو

                  return DataRow(cells: [
                    DataCell(Text(o.date.toString().split(' ')[0])),
                    DataCell(Text(o.customerName)),
                    DataCell(Text('${o.width.toInt()} سم')),
                    DataCell(Text('${o.grams.toInt()}g')),
                    DataCell(Text('${totalWeightInKilo.toInt()} ك')),
                    DataCell(Text('${o.diameter.toInt()} سم')),
                    DataCell(Text('${avgRollWeight.toStringAsFixed(1)} ك')),
                    DataCell(Text(o.quantity.toString())),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: o.isPlanned ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          o.isPlanned ? "مجدول" : "انتظار",
                          style: TextStyle(color: o.isPlanned ? Colors.green.shade900 : Colors.orange.shade900, fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                            onPressed: () => _editOrder(o),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => _deleteOrder(o.id!),
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}