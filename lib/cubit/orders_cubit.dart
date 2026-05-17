import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/database_helper.dart';
import '../../models/order.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final DatabaseHelper db = DatabaseHelper();

  OrdersCubit() : super(OrdersInitial());

  Future<void> fetchOrders() async {
    emit(OrdersLoading());
    try {
      final orders = await db.getAllOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(const OrdersError("فشل في تحميل البيانات"));
    }
  }

  Future<void> saveOrders(List<Order> orders, bool isEditing) async {
    try {
      for (var order in orders) {
        if (isEditing && order.id != null) {
          await db.clearPlansForOrder(order.id!);
          await db.resetPlanningForOrder(order.id!);
          await db.updateOrder(order);
        } else {
          await db.insertOrder(order);
        }
      }
      await fetchOrders();
    } catch (e) {
      emit(const OrdersError("حدث خطأ أثناء حفظ البيانات"));
    }
  }

  Future<void> deleteOrderWithReset(int id) async {
    try {
      await db.clearPlansForOrder(id);
      await db.resetPlanningForOrder(id);
      await db.deleteOrder(id);

      // تحديث البيانات بعد الحذف
      await fetchOrders();
    } catch (e) {
      print('Delete Error: $e'); // للتصحيح
      rethrow; // مهم: عشان نعرف الخطأ الحقيقي
    }
  }
  Future<void> clearAll() async {
    try {
      await db.clearAllOrders();
      await db.clearAllPlans();
      await db.resetAllOrdersPlanning();
      emit(const OrdersLoaded([]));
    } catch (e) {
      emit(const OrdersError("فشل مسح جميع البيانات"));
    }
  }
}