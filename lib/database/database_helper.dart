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
      version: 6, // تم الترقية لـ 6 لدعم الحسابات الجزئية للبكر
      onCreate: (db, version) async {
        // orders
        await db.execute('''
          CREATE TABLE orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            customerName TEXT,
            salesOrder TEXT,
            width REAL,
            quantity INTEGER,
            plannedQuantity INTEGER DEFAULT 0,
            grams REAL,
            totalTons REAL,
            status TEXT DEFAULT 'انتظار',
            diameter REAL,
            diameterWeight REAL
          )
        ''');
        // production_plans
        await db.execute('''
          CREATE TABLE production_plans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            grams REAL,
            totalWidth REAL,
            waste REAL
          )
        ''');
        // plan_items
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
          try { await db.execute("ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'انتظار'"); } catch (e) {}
          try { await db.execute("ALTER TABLE orders ADD COLUMN diameter REAL DEFAULT 0"); } catch (e) {}
          try { await db.execute("ALTER TABLE orders ADD COLUMN diameterWeight REAL DEFAULT 0"); } catch (e) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute('''CREATE TABLE production_plans(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, grams REAL, totalWidth REAL, waste REAL)''');
            await db.execute('''CREATE TABLE plan_items(id INTEGER PRIMARY KEY AUTOINCREMENT, planId INTEGER, orderId INTEGER, customerName TEXT, width REAL, quantity INTEGER)''');
          } catch (e) {

          }
        }
        if (oldVersion < 5) {
          try { await db.execute("ALTER TABLE orders ADD COLUMN salesOrder TEXT"); } catch (e) {}
        }
        if (oldVersion < 6) {
          try { await db.execute("ALTER TABLE orders ADD COLUMN plannedQuantity INTEGER DEFAULT 0"); } catch (e) {}
        }
      },
    );
  }
  // دالة مسؤولة عن خصم البكر المستخدمة من الأوردر
// وتحديث plannedQuantity والحالة (انتظار / تم الجدول)
// بعد كل عملية تخطيط أو إنتاج
  Future<void> consumeOrder(int orderId, int usedQty) async {
    final dbClient = await database;
    await dbClient.transaction((txn) async {
      final res = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      if (res.isEmpty) return;

      final orderMap = res.first;
      int totalQty = (orderMap['quantity'] as int);
      int currentPlanned = (orderMap['plannedQuantity'] ?? 0) as int;
      int newPlanned = currentPlanned + usedQty;

      await txn.update(
        'orders',
        {
          'plannedQuantity': newPlanned,
          'status': newPlanned >= totalQty ? 'تم الجدول' : 'انتظار'
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }
  Future<int> insertOrder(Order order) async {
    final dbClient = await database;
    return await dbClient.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateOrder(Order order) async {
    final dbClient = await database;
    return await dbClient.update('orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
  }

  Future<int> deleteOrder(int id) async {
    final dbClient = await database;
    return await dbClient.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Order>> getAllOrders() async {
    final dbClient = await database;
    final List<Map<String, dynamic>> maps = await dbClient.query('orders', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<void> saveProductionPlans(List<ProductionPlan> plans) async {
    final dbClient = await database;
    await dbClient.transaction((txn) async {
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
    final dbClient = await database;
    final plansResult = await dbClient.query('production_plans', orderBy: 'id DESC');
    final itemsResult = await dbClient.query('plan_items');

    Map<int, ProductionPlan> plansMap = {};
    for (var p in plansResult) {
      final id = p['id'] as int;
      plansMap[id] = ProductionPlan(
        id: id,
        date: DateTime.parse(p['date'] as String),
        grams: (p['grams'] as num).toDouble(),
        items: [],
        totalWidth: (p['totalWidth'] as num).toDouble(),
        waste: (p['waste'] as num).toDouble(),
      );
    }

    for (var item in itemsResult) {
      final planId = item['planId'] as int;
      if (plansMap.containsKey(planId)) {
        plansMap[planId]!.items.add(PlanItem(
          orderId: item['orderId'] as int,
          customerName: item['customerName'] as String,
          width: (item['width'] as num).toDouble(),
          quantity: item['quantity'] as int,
        ));
      }
    }
    return plansMap.values.toList();
  }
  // جلب جميع خطط الإنتاج المحفوظة مع تفاصيل كل رصة وربطها بعناصرها من الداتابيز
  Future<List<ProductionPlan>> getAllProductionPlans() async {
    return await getSavedPlans();
  }
  // تحديث الأوردر وتصفير المجدول
  Future<int> updateOrderAndResetPlanning(Order order) async {
    final dbClient = await database;
    return await dbClient.update(
      'orders',
      {
        // نحدث كل البيانات بس نجبر المجدول يكون 0 مهما كان اللي في الموديل
        'width': order.width,
        'grams': order.grams,
        'quantity': order.quantity,
        'plannedQuantity': 0, // ✅ تأكيد قاطع
        'status': 'انتظار',   // ✅ تأكيد قاطع
      },
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }
  //// تصفير التخطيط لكل الطلبات وإرجاع حالتها إلى "انتظار"
  Future<void> resetAllOrdersPlanning() async {
    final dbClient = await database;
    await dbClient.update(
      'orders',
      {'plannedQuantity': 0, 'status': 'انتظار'},
    );
  }
  Future<int> clearAllOrders() async {
    final db = await database;
    return await db.delete('orders');
  }
  Future<void> clearAllPlans() async {
    final dbClient = await database;
    await dbClient.delete('production_plans');
    await dbClient.delete('plan_items');
  }
}