import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/orders_cubit.dart';
import 'orders_screen.dart';
import 'planning_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام تخطيط الإنتاج - قطاع الرولات'),
        centerTitle: true,
        elevation: 2,
      ),
      // بنبعت الـ context بتاع الشاشة الرئيسية للدرور
      drawer: MainDrawer(parentContext: context),
      body: const OrdersScreen(),
    );
  }
}

class MainDrawer extends StatelessWidget {
  final BuildContext parentContext;
  const MainDrawer({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade500],
              ),
            ),
            child: const Center(
              child: Text(
                'القائمة الرئيسية',
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _buildItem(context, 'الطلبات الحالية', Icons.list_alt, null),
          _buildItem(context, 'التخطيط والمحاكاة', Icons.schema, const PlanningScreen()),
          // رجعنا التقارير يا بطل
          _buildItem(context, 'التقارير السابقة', Icons.print, const ReportsScreen()),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Version 1.0.1', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, Widget? destination) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context); // قفل الدرور

        if (destination != null) {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination)
          ).then((_) {
            // استخدام الـ parentContext لضمان الوصول للـ Cubit
            try {
              parentContext.read<OrdersCubit>().fetchOrders();
              debugPrint("تم تحديث سجل الطلبات بنجاح");
            } catch (e) {
              debugPrint("OrdersCubit error: $e");
            }
          });
        }
      },
    );
  }
}