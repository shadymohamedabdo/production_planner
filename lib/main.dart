import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/orders_screen.dart';
import 'screens/planning_screen.dart';
import 'screens/reports_screen.dart';
import 'database/database_helper.dart'; // تأكد من استيراد الـ helper

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const ProductionPlanningApp());
}

class ProductionPlanningApp extends StatelessWidget {
  const ProductionPlanningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام تخطيط الإنتاج',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Cairo'),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نظام تخطيط الإنتاج - قطاع الرولات')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('القائمة الرئيسية', style: TextStyle(fontSize: 24))),
            ListTile(
                title: const Text('الطلبات'),
                leading: const Icon(Icons.list_alt),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))
            ),
            ListTile(
                title: const Text('التخطيط والمحاكاة'),
                leading: const Icon(Icons.schema),
                onTap: () async {
                  // جلب الطلبات من قاعدة البيانات قبل الانتقال للشاشة
                  final orders = await DatabaseHelper().getAllOrders();
                  Navigator.push(context, MaterialPageRoute(
                    // شيلنا الـ const وبعتنا الـ orders
                      builder: (_) => PlanningScreen(orders: orders)
                  ));
                }
            ),
            ListTile(
                title: const Text('التقارير'),
                leading: const Icon(Icons.print),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))
            ),
          ],
        ),
      ),
      body: const OrdersScreen(),
    );
  }
}