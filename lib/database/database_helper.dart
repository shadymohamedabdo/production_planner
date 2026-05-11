import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';
import '../models/plan.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'production_planning.db');

    return await openDatabase(
      path,
      version: 4, // رفعنا الإصدار لـ 4 لإضافة جداول الخطط
      onCreate: (db, version) async {
        // جدول الطلبات
        await db.execute('''
          CREATE TABLE orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            customerName TEXT,
            width REAL,
            quantity INTEGER,
            grams REAL,
            totalTons REAL,
            status TEXT DEFAULT 'انتظار',
            diameter REAL,
            diameterWeight REAL
          )
        ''');
        // جدول خطط الإنتاج (رأس الخطة)
        await db.execute('''
          CREATE TABLE production_plans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            grams REAL,
            totalWidth REAL,
            waste REAL
          )
        ''');
        // جدول تفاصيل الخطة (عناصر الخطة)
        await db.execute('''
          CREATE TABLE plan_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            planId INTEGER,
            orderId INTEGER,
            customerName TEXT,
            width REAL,
            quantity INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'انتظار'");
          } catch (e) {}
          try {
            await db.execute("ALTER TABLE orders ADD COLUMN diameter REAL DEFAULT 0");
          } catch (e) {}
          try {
            await db.execute("ALTER TABLE orders ADD COLUMN diameterWeight REAL DEFAULT 0");
          } catch (e) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute('''
              CREATE TABLE production_plans(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT,
                grams REAL,
                totalWidth REAL,
                waste REAL
              )
            ''');
            await db.execute('''
              CREATE TABLE plan_items(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                planId INTEGER,
                orderId INTEGER,
                customerName TEXT,
                width REAL,
                quantity INTEGER
              )
            ''');
          } catch (e) {}
        }
      },
    );
  }

  // ======================== عمليات الطلبات (Orders) ========================

  Future<void> consumeOrder(int orderId) async {
    final db = await database;
    await db.transaction((txn) async {
      final result = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      if (result.isEmpty) return;
      int currentQty = result.first['quantity'] as int;
      if (currentQty > 1) {
        await txn.update('orders', {'quantity': currentQty - 1}, where: 'id = ?', whereArgs: [orderId]);
      } else {
        await txn.update('orders', {'quantity': 0, 'status': 'تم الجدول'}, where: 'id = ?', whereArgs: [orderId]);
      }
    });
  }

  Future<void> markOrdersAsPlanned(List<int> orderIds) async {
    for (var id in orderIds) {
      await consumeOrder(id);
    }
  }

  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return await db.update('orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<List<Order>> getUnplannedOrdersByGrams(double grams) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'grams = ? AND status = ? AND quantity > 0',
      whereArgs: [grams, 'انتظار'],
      orderBy: 'width DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<List<double>> getDistinctGrams() async {
    final db = await database;
    final result = await db.rawQuery("SELECT DISTINCT grams FROM orders WHERE status = 'انتظار' AND quantity > 0");
    return result.map((row) => row['grams'] as double).toList();
  }

  Future<int> clearAllOrders() async {
    final db = await database;
    return await db.delete('orders');
  }

  Future<void> resetPlanned() async {
    final db = await database;
    await db.update('orders', {'status': 'انتظار'});
  }

  // ======================== عمليات خطط الإنتاج (Production Plans) ========================

  // ======================== عمليات خطط الإنتاج (Production Plans) ========================

  Future<void> saveProductionPlans(List<ProductionPlan> plans) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('production_plans');
      await txn.delete('plan_items');

      for (var plan in plans) {
        final planId = await txn.insert('production_plans', {
          'date': plan.date.toIso8601String(),
          'grams': plan.grams,
          'totalWidth': plan.totalWidth,
          'waste': plan.waste,
        });
        for (var item in plan.items) {
          await txn.insert('plan_items', {
            'planId': planId,
            'orderId': item.orderId,
            'customerName': item.customerName,
            'width': item.width,
            'quantity': item.quantity,
          });
        }
      }
    });
  }

  Future<List<ProductionPlan>> getSavedPlans() async {
    final db = await database;
    final plansMap = <int, ProductionPlan>{};

    final plansResult = await db.query('production_plans', orderBy: 'date DESC');
    for (var p in plansResult) {
      final id = p['id'] as int;
      plansMap[id] = ProductionPlan(
        id: id,
        date: DateTime.parse(p['date'] as String),
        grams: p['grams'] as double,
        items: [],
        totalWidth: p['totalWidth'] as double,
        waste: p['waste'] as double,
      );
    }

    if (plansMap.isEmpty) return [];

    final itemsResult = await db.query('plan_items');
    for (var item in itemsResult) {
      final planId = item['planId'] as int;
      if (plansMap.containsKey(planId)) {
        plansMap[planId]!.items.add(PlanItem(
          orderId: item['orderId'] as int,
          customerName: item['customerName'] as String,
          width: item['width'] as double,
          quantity: item['quantity'] as int,
        ));
      }
    }

    return plansMap.values.toList();
  }

  Future<List<ProductionPlan>> getAllProductionPlans() async {
    return await getSavedPlans();
  }

  Future<ProductionPlan?> getProductionPlanById(int id) async {
    final db = await database;
    final planMaps = await db.query('production_plans', where: 'id = ?', whereArgs: [id]);
    if (planMaps.isEmpty) return null;
    final p = planMaps.first;
    final plan = ProductionPlan(
      id: p['id'] as int,
      date: DateTime.parse(p['date'] as String),
      grams: p['grams'] as double,
      items: [],
      totalWidth: p['totalWidth'] as double,
      waste: p['waste'] as double,
    );
    final itemMaps = await db.query('plan_items', where: 'planId = ?', whereArgs: [id]);
    plan.items = itemMaps.map((item) => PlanItem(
      orderId: item['orderId'] as int,
      customerName: item['customerName'] as String,
      width: item['width'] as double,
      quantity: item['quantity'] as int,
    )).toList();
    return plan;
  }

  Future<void> clearAllPlans() async {
    final db = await database;
    await db.delete('production_plans');
    await db.delete('plan_items');
  }
}