// logic/orders_cubit/orders_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/database_helper.dart';
import '../../models/order.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final DatabaseHelper db = DatabaseHelper();

  OrdersCubit() : super(OrdersInitial());

  // جلب كل الطلبات
  Future<void> fetchOrders() async {
    emit(OrdersLoading());
    try {
      final orders = await db.getAllOrders();
      emit(OrdersLoaded(List.from(orders)));
    } catch (e) {
      emit(const OrdersError("فشل في تحميل البيانات"));
    }
  }

  // إضافة أو تعديل الطلبات (تحسين الأداء ونقل منطق التنظيف هنا)
  Future<void> saveOrders(List<Order> orders, bool isEditing) async {
    try {
      for (var order in orders) {
        if (isEditing) {
          await db.updateOrderAndResetPlanning(order);
        } else {
          await db.insertOrder(order);
        }
      }

      // 🟢 تحسين الأداء: مسح وتصفير الخطط مرة واحدة فقط بعد انتهاء اللووب بالكامل
      if (isEditing) {
        await db.clearAllPlans();
        await db.resetAllOrdersPlanning();
      }

      fetchOrders(); // تحديث الشاشة
    } catch (e) {
      emit(const OrdersError("حدث خطأ أثناء حفظ البيانات"));
    }
  }

  // 🟢 دالة الحذف الذكية: بتنظف الجداول وتحذف الطلب في خطوة واحدة من الخلفية
  Future<void> deleteOrderWithReset(int id) async {
    try {
      await db.clearAllPlans();
      await db.resetAllOrdersPlanning();
      await db.deleteOrder(id);

      fetchOrders(); // تحديث الشاشة فوراً بعد الحذف
    } catch (e) {
      emit(const OrdersError("فشل الحذف وسجل الإنتاج ممتلئ"));
    }
  }

  // مسح الكل
  Future<void> clearAll() async {
    try {
      await db.clearAllOrders();
      await db.clearAllPlans();
      await db.resetAllOrdersPlanning();
      emit(const OrdersLoaded([]));
    } catch (e) {
      emit(const OrdersError("فشل مسح البيانات"));
    }
  }
}