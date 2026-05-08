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

  Future<void> _loadOrders() async {
    final data = await db.getAllOrders();
    setState(() => _orders = data);
  }

  // 1. دالة حذف طلب واحد
  Future<void> _deleteOrder(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final database = await db.database;
      await database.delete('orders', where: 'id = ?', whereArgs: [id]);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الطلب بنجاح')),
        );
      }
    }
  }

  // 2. دالة التعديل (فتح الفورم ببيانات الطلب)
  Future<void> _editOrder(Order order) async {
    await showDialog(
      context: context,
      builder: (_) => OrderForm(
        order: order, // تأكد أن OrderForm يقبل параметр order للتعديل
        onSaved: _loadOrders,
      ),
    );
  }

  Future<void> _deleteAllOrders() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح كل البيانات'),
        content: const Text('هل أنت متأكد أنك تريد مسح جميع الطلبات؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('مسح', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final database = await db.database;
      await database.delete('orders');
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
        title: const Text('الطلبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            onPressed: _deleteAllOrders,
            tooltip: 'مسح كل الطلبات',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => OrderForm(onSaved: _loadOrders),
          );
        },
      ),
      body: _orders.isEmpty
          ? const Center(child: Text('لا توجد طلبات. أضف طلب جديد باستخدام الزر +'))
          : RefreshIndicator(
        onRefresh: _loadOrders,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('العميل')),
                DataColumn(label: Text('العرض (م)')),
                DataColumn(label: Text('الكمية')),
                DataColumn(label: Text('الجرام')),
                DataColumn(label: Text('الطن')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('الإجراءات')), // عمود جديد
              ],
              rows: _orders.map((o) => DataRow(cells: [
                DataCell(Text(o.date.toLocal().toString().split(' ')[0])),
                DataCell(Text(o.customerName)),
                DataCell(Text(o.width.toString())),
                DataCell(Text(o.quantity.toString())),
                DataCell(Text(o.grams.toString())),
                DataCell(Text(o.totalTons.toString())),
                DataCell(Icon(
                  o.isPlanned ? Icons.check_circle : Icons.pending,
                  color: o.isPlanned ? Colors.green : Colors.orange,
                )),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editOrder(o),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteOrder(o.id!),
                      ),
                    ],
                  ),
                ),
              ])).toList(),
            ),
          ),
        ),
      ),
    );
  }
}