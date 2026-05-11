import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';

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
      version: 3,
      onCreate: (db, version) async {
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
      },
    );
  }

  // ✅ استهلاك بكرة واحدة من طلب معين
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

  // --- العمليات الأساسية ---
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
}