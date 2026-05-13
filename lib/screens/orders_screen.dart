// screens/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../widgets/order_form.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطلبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmClear(context),
            tooltip: 'مسح الكل',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOrderForm(context),
        label: const Text('طلب جديد'),
        icon: const Icon(Icons.add),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) return const Center(child: CircularProgressIndicator());
          if (state is OrdersError) return Center(child: Text(state.message));
          if (state is OrdersLoaded) {
            final orders = state.orders;
            if (orders.isEmpty) return _buildEmptyState();
            return _buildOrdersTable(context, orders);
          }
          return const SizedBox();
        },
      ),
    );
  }

  // دالة عرض الفورم
  void _showOrderForm(BuildContext context, {dynamic order}) {
    showDialog(
      context: context,
      builder: (_) => OrderForm(order: order),
    );
  }

  // تأكيد مسح الكل
  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تنبيه'),
        content: const Text('هل أنت متأكد من مسح جميع الطلبات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context.read<OrdersCubit>().clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // تصميم الجدول (نفس تصميمك مع تحسينات طفيفة للأداء)
  Widget _buildOrdersTable(BuildContext context, List<dynamic> orders) {
    return RefreshIndicator(
      onRefresh: () => context.read<OrdersCubit>().fetchOrders(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
              columns: _buildColumns(),
              rows: orders.map((o) => _buildDataRow(context, o)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // فصل الـ Row والـ Columns لتحسين نظافة الكود
  List<DataColumn> _buildColumns() {
    return const [
      DataColumn(label: Text('التاريخ')),
      DataColumn(label: Text('أمر البيع')),
      DataColumn(label: Text('العميل')),
      DataColumn(label: Text('العرض')),
      DataColumn(label: Text('القطر')), // العمود الجديد هنا
      DataColumn(label: Text('الجرام')),
      DataColumn(label: Text('العدد (بكرة)')),
      DataColumn(label: Text('متوسط البكرة')),
      DataColumn(label: Text('الوزن الكلي')),
      DataColumn(label: Text('الحالة')),
      DataColumn(label: Text('إجراءات')),
    ];
  }
  DataRow _buildDataRow(BuildContext context, dynamic o) {
    // حساب متوسط وزن البكرة الواحدة
    double weightInKg = o.totalTons * 1000;
    double avgRollWeight = o.quantity > 0 ? (weightInKg / o.quantity) : 0;

    return DataRow(cells: [
      DataCell(Text(o.date.toString().split(' ')[0])),
      DataCell(Text(o.salesOrder ?? '-')),
      DataCell(Text(o.customerName)),
      DataCell(Text('${o.width.toInt()} سم')),

      // إضافة خلية القطر هنا
      DataCell(Text('${o.diameter ?? "-"} سم')),

      DataCell(Text('${o.grams.toInt()}g')),
      DataCell(Text('${o.quantity}')),
      DataCell(Text('${avgRollWeight.toStringAsFixed(1)} ك')),
      DataCell(Text('${weightInKg.toInt()} ك')),
      DataCell(_buildStatusChip(o.status)),
      DataCell(Row(
        children: [
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _showOrderForm(context, order: o)
          ),
          IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => context.read<OrdersCubit>().deleteOrder(o.id!)
          ),
        ],
      )),
    ]);
  }  Widget _buildStatusChip(String status) {
    bool isDone = status == "تم الجدول";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isDone ? "مجدول" : "انتظار", style: TextStyle(color: isDone ? Colors.green.shade900 : Colors.orange.shade900, fontSize: 11)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
          const Text('لا توجد طلبات مسجلة حالياً', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}