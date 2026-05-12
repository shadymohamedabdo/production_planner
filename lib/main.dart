import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// استيراد الـ Cubits
import 'cubit/orders_cubit.dart';
import 'cubit/planning_cubit.dart';
import 'cubit/reports_cubit.dart';

// استيراد الشاشة الرئيسية
import 'screens/main_screen.dart';

void main() async {
  // التأكد من تهيئة الـ Widgets قبل أي عمليات أخرى
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة مكتبة sqflite للعمل على أنظمة التشغيل (Windows/Linux)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const ProductionPlanningApp());
}

class ProductionPlanningApp extends StatelessWidget {
  const ProductionPlanningApp({super.key});

  @override
  Widget build(BuildContext context) {
    // الحل النهائي: وضع الـ MultiBlocProvider فوق الـ MaterialApp
    // لضمان وصول كل الشاشات (Navigator) للبيانات بدون ProviderNotFoundException
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OrdersCubit()..fetchOrders(),
        ),
        BlocProvider(
          create: (_) => PlanningCubit()..loadData(),
        ),
        BlocProvider(
          create: (_) => ReportsCubit()..loadReports(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'نظام تخطيط الإنتاج',

        // ضبط اللغة للواجهة العربية
        locale: const Locale('ar', 'EG'),

        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Cairo', // تأكد من إضافة الخط في pubspec.yaml

          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),

          scaffoldBackgroundColor: const Color(0xfff5f5f5),

          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),

          // تم استخدام CardThemeData لحل مشكلة الـ Type Mismatch
          cardTheme: CardThemeData(
            elevation: 2,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // نقطة انطلاق التطبيق
        home: const MainScreen(),
      ),
    );
  }
}