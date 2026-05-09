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
    // تشغيل ffi للـ Desktop لو مش شغال
    // sqfliteFfiInit();

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'production_planning.db');
    return await openDatabase(
      path,
      version: 1,
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
            isPlanned INTEGER
          )
        ''');
      },
    );
  }

  // --- العمليات الأساسية (CRUD) ---

  // 1. إدراج طلب جديد
  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert('orders', order.toMap());
  }

  // 2. تعديل طلب موجود (مهم جداً لزرار التعديل في الشاشة)
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

  // 4. مسح جميع الطلبات (دالة الـ Sweep)
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

  // جلب الطلبات غير المجدولة حسب الجرام
  Future<List<Order>> getUnplannedOrdersByGrams(double grams) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'grams = ? AND isPlanned = 0',
      whereArgs: [grams],
      orderBy: 'width DESC', // الترتيب من الأكبر للأصغر يساعد الخوارزمية (FFD)
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  // الحصول على قائمة الجرامات الفريدة للطلبات غير المجدولة
  Future<List<double>> getDistinctGrams() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT grams FROM orders WHERE isPlanned = 0');
    return result.map((row) => row['grams'] as double).toList();
  }

  // تحديث حالة مجموعة طلبات إلى "تم التخطيط"
  Future<void> markOrdersAsPlanned(List<int> orderIds) async {
    final db = await database;
    Batch batch = db.batch(); // استخدام الـ Batch أسرع في التحديثات الكثيرة
    for (var id in orderIds) {
      batch.update('orders', {'isPlanned': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  // إعادة تعيين جميع الطلبات إلى غير مجدولة (لأغراض إعادة التخطيط)
  Future<void> resetPlanned() async {
    final db = await database;
    await db.update('orders', {'isPlanned': 0});
  }
}