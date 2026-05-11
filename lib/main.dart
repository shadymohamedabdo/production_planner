import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/orders_screen.dart';
import 'screens/planning_screen.dart';
import 'screens/reports_screen.dart';
import 'database/database_helper.dart';

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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // متغير لتحديث البيانات عند العودة من شاشة التخطيط
  int _refreshKey = 0;

  void _refreshOrders() {
    setState(() {
      _refreshKey++;
    });
  }

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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
            ListTile(
              title: const Text('التخطيط والمحاكاة'),
              leading: const Icon(Icons.schema),
              onTap: () async {
                final orders = await DatabaseHelper().getAllOrders();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanningScreen(
                      orders: orders,
                      onDataChanged: _refreshOrders, // تمرير دالة لتحديث البيانات
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('التقارير'),
              leading: const Icon(Icons.print),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
            ),
          ],
        ),
      ),
      body: const OrdersScreen(),
    );
  }
}