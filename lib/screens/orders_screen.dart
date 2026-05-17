import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../cubit/planning_cubit.dart';
import '../models/order.dart';
import '../widgets/order_form.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'الكل';

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
      body: Column(
        children: [
          // شريط البحث والفلتر
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث بالعميل أو أمر البيع...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                    DropdownMenuItem(value: 'انتظار', child: Text('انتظار')),
                    DropdownMenuItem(value: 'مجدول', child: Text('مجدول')),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                ),
              ],
            ),
          ),

          // الجدول (الحل النهائي للـ Overflow)
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is OrdersError) {
                  return Center(child: Text('خطأ: ${state.message}'));
                }
                if (state is OrdersLoaded) {
                  final filteredOrders = _filterOrders(state.orders);
                  if (filteredOrders.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildScrollableTable(context, filteredOrders);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    return orders.where((order) {
      final matchesSearch = order.customerName.toLowerCase().contains(_searchQuery) ||
          (order.salesOrder?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesStatus = _selectedStatus == 'الكل' ||
          (_selectedStatus == 'انتظار' && order.status == 'انتظار') ||
          (_selectedStatus == 'مجدول' && order.status == 'تم الجدول');

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildScrollableTable(BuildContext context, List<Order> orders) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
              columns: _buildColumns(),
              rows: List.generate(
                orders.length,
                    (index) => _buildDataRow(context, orders[index], index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return const [
      DataColumn(label: Text('م')),
      DataColumn(label: Text('التاريخ')),
      DataColumn(label: Text('أمر البيع')),
      DataColumn(label: Text('العميل')),
      DataColumn(label: Text('العرض')),
      DataColumn(label: Text('القطر')),
      DataColumn(label: Text('الجرام')),
      DataColumn(label: Text('العدد الكلي')),
      DataColumn(label: Text('المجدول')),
      DataColumn(label: Text('المتبقي')),
      DataColumn(label: Text('متوسط البكرة')),
      DataColumn(label: Text('الوزن الكلي')),
      DataColumn(label: Text('الحالة')),
      DataColumn(label: Text('إجراءات')),
    ];
  }

  DataRow _buildDataRow(BuildContext context, Order o, int index) {
    final weightInKg = o.totalTons * 1000;
    final avgRollWeight = o.quantity > 0 ? (weightInKg / o.quantity) : 0;
    final remaining = o.quantity - (o.plannedQuantity ?? 0);

    final (bgColor, textColor) = _getRemainingColors(remaining);

    return DataRow(
      color: WidgetStateProperty.all(index.isEven ? Colors.grey.shade50 : Colors.white),
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(o.date.toString().split(' ')[0])),
        DataCell(Text(o.salesOrder ?? '-')),
        DataCell(Text(o.customerName)),
        DataCell(Text('${o.width.toInt()} سم')),
        DataCell(Text('${o.diameter.toInt()} سم')),
        DataCell(Text('${o.grams.toInt()} g')),
        DataCell(Text(o.quantity.toString())),
        DataCell(Text((o.plannedQuantity ?? 0).toString())),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Text(remaining.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          ),
        ),
        DataCell(Text('${avgRollWeight.toStringAsFixed(1)} ك')),
        DataCell(Text('${weightInKg.toInt()} ك')),
        DataCell(_buildStatusChip(o.status)),
        DataCell(
          Row(
            children: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showOrderForm(context, order: o)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _confirmDelete(context, o.id!)),
            ],
          ),
        ),
      ],
    );
  }

  (Color, Color) _getRemainingColors(int remaining) {
    if (remaining < 0) return (Colors.red.shade100, Colors.red.shade900);
    if (remaining > 0) return (Colors.orange.shade100, Colors.orange.shade900);
    return (Colors.green.shade100, Colors.green.shade900);
  }

  Widget _buildStatusChip(String status) {
    final isDone = status == "تم الجدول";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isDone ? "مجدول" : "انتظار",
        style: TextStyle(color: isDone ? Colors.green.shade900 : Colors.orange.shade900, fontSize: 11),
      ),
    );
  }

  // ====================== Dialogs ======================
  Future<void> _showOrderForm(BuildContext context, {Order? order}) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => OrderForm(order: order),
    ) ??
        false;

    if (didSave && context.mounted) {
      context.read<OrdersCubit>().fetchOrders();
      _refreshPlanning(context);
    }
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تنبيه خطير'),
        content: const Text('هل أنت متأكد من مسح جميع الطلبات وسجلات الإنتاج بالكامل؟'),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              await context.read<OrdersCubit>().clearAll();
              _refreshPlanning(context);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('تم مسح جميع البيانات')));
                Navigator.pop(ctx);
              }
            },
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟ سيتم تصفير الخطة المرتبطة به.'),
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // إغلاق الـ Dialog أولاً

              try {
                await context.read<OrdersCubit>().deleteOrderWithReset(orderId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الطلب بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل الحذف: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  void _refreshPlanning(BuildContext context) {
    try {
      context.read<PlanningCubit>().loadData();
    } catch (_) {}
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد طلبات مسجلة حالياً',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}