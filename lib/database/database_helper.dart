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
      version: 2, // رفعنا الإصدار لـ 2 عشان نحدث الجدول
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
            isPlanned INTEGER,
            diameter REAL,        -- العمود الجديد
            diameterWeight REAL   -- العمود الجديد
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // لو المستخدم عنده قاعدة بيانات قديمة، بنزود الأعمدة الجديدة من غير ما نمسح بياناته
          await db.execute('ALTER TABLE orders ADD COLUMN diameter REAL DEFAULT 120.0');
          await db.execute('ALTER TABLE orders ADD COLUMN diameterWeight REAL DEFAULT 8.0');
        }
      },
    );
  }

  // --- العمليات الأساسية (CRUD) ---

  // 1. إدراج طلب جديد
  Future<int> insertOrder(Order order) async {
    final db = await database;
    // بما إننا حدثنا toMap في موديل Order، البيانات هتنزل هنا أوتوماتيك
    return await db.insert('orders', order.toMap());
  }

  // 2. تعديل طلب موجود
  Future<int> updateOrder(Order order) async {
    final db = await database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  // 3. حذف طلب واحد
  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 4. مسح جميع الطلبات
  Future<int> clearAllOrders() async {
    final db = await database;
    return await db.delete('orders');
  }

  // 5. جلب جميع الطلبات للسجل
  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  // --- عمليات الخوارزمية (Algorithm Helpers) ---

  Future<List<Order>> getUnplannedOrdersByGrams(double grams) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'grams = ? AND isPlanned = 0',
      whereArgs: [grams],
      orderBy: 'width DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<List<double>> getDistinctGrams() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT grams FROM orders WHERE isPlanned = 0');
    return result.map((row) => row['grams'] as double).toList();
  }

  Future<void> markOrdersAsPlanned(List<int> orderIds) async {
    final db = await database;
    Batch batch = db.batch();
    for (var id in orderIds) {
      batch.update('orders', {'isPlanned': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> resetPlanned() async {
    final db = await database;
    await db.update('orders', {'isPlanned': 0});
  }
}