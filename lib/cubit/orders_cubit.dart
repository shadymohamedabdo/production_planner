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
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(const OrdersError("فشل في تحميل البيانات"));
    }
  }

  // إضافة طلبات (يدعم إضافة قائمة كاملة)
  Future<void> saveOrders(List<Order> orders, bool isEditing) async {
    try {
      for (var order in orders) {
        if (isEditing) {
          await db.updateOrder(order);
        } else {
          await db.insertOrder(order);
        }
      }
      fetchOrders(); // تحديث القائمة تلقائياً
    } catch (e) {
      emit(const OrdersError("حدث خطأ أثناء الحفظ"));
    }
  }

  // حذف طلب واحد
  Future<void> deleteOrder(int id) async {
    try {
      await db.deleteOrder(id);
      fetchOrders();
    } catch (e) {
      emit(const OrdersError("فشل الحذف"));
    }
  }


  // مسح الكل
  Future<void> clearAll() async {
    try {
      await db.clearAllOrders();
      emit(const OrdersLoaded([]));
    } catch (e) {
      emit(const OrdersError("فشل مسح البيانات"));
    }
  }
}