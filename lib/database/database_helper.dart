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
      version: 3, // رفعنا الإصدار لـ 3 عشان نضمن تحديث الجدول بالكامل
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
            status TEXT DEFAULT 'انتظار', -- غيرنا isPlanned لـ status
            diameter REAL,
            diameterWeight REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // لو بنحدث من نسخة قديمة، بنضيف عمود الحالة وبنمسح القديم لو لزم الأمر
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'انتظار'");
          } catch (e) {
            // العمود قد يكون موجوداً بالفعل
          }
        }
      },
    );
  }

  // --- العمليات الأساسية ---

  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
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

  // --- تحديث عمليات الخوارزمية لتناسب النظام الجديد ---

  Future<List<Order>> getUnplannedOrdersByGrams(double grams) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'grams = ? AND status = ?',
      whereArgs: [grams, 'انتظار'], // بنجيب اللي في الانتظار فقط
      orderBy: 'width DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<List<double>> getDistinctGrams() async {
    final db = await database;
    final result = await db.rawQuery("SELECT DISTINCT grams FROM orders WHERE status = 'انتظار'");
    return result.map((row) => row['grams'] as double).toList();
  }

  Future<void> markOrdersAsPlanned(List<int> orderIds) async {
    final db = await database;
    Batch batch = db.batch();
    for (var id in orderIds) {
      batch.update('orders', {'status': 'تم الجدول'}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }
  // 4. مسح جميع الطلبات
  Future<int> clearAllOrders() async {
    final db = await database;
    return await db.delete('orders');
  }

  Future<void> resetPlanned() async {
    final db = await database;
    await db.update('orders', {'status': 'انتظار'});
  }
}