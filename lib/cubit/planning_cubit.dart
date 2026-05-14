import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/database_helper.dart';
import '../../models/order.dart';
import '../../models/plan.dart';
import '../algorithms/planning_algorithm..dart';
import 'planning_state.dart';

class PlanningCubit extends Cubit<PlanningState> {
  final DatabaseHelper db = DatabaseHelper();

  PlanningCubit() : super(PlanningInitial()) {
    loadData();
  }

  Future<void> loadData() async {
    emit(PlanningLoading());
    try {
      final plans = await db.getSavedPlans();
      final allOrders = await db.getAllOrders();
      _processData(plans, allOrders);
    } catch (e) {
      emit(const PlanningError("خطأ في تحميل بيانات التخطيط"));
    }
  }

  void _processData(List<ProductionPlan> plans, List<Order> allOrders, {double? selectedGram}) {
    // التعديل: الطلب يظل في قائمة "الانتظار" طالما أن المجدول أقل من الكلي
    final waiting = allOrders.where((o) {
      int planned = o.plannedQuantity ?? 0;
      int total = o.quantity;
      return o.status == 'انتظار' && planned < total;
    }).toList();

    final grams = waiting.map((o) => o.grams).toSet().toList()..sort();
    double priorityGram = selectedGram ?? (grams.isNotEmpty ? grams.first : 0.0);

    emit(PlanningLoaded(
      plans: plans,
      previousPlans: plans,
      waitingOrders: waiting,
      availableGrams: grams,
      selectedGram: priorityGram,
    ));
  }

  void changeSelectedGram(double gram) {
    if (state is PlanningLoaded) {
      emit((state as PlanningLoaded).copyWith(selectedGram: gram));
    }
  }

  Future<void> startGeneration() async {
    final current = state;
    if (current is! PlanningLoaded || current.isGenerating) return;

    emit(current.copyWith(isGenerating: true));

    try {
      final priority = [
        current.selectedGram,
        ...current.availableGrams.where((g) => g != current.selectedGram)
      ];

      // توليد الخطة بناءً على المتبقي الفعلي
      final newPlans = PlanningAlgorithm.generatePlans(current.waitingOrders, priority);

      if (newPlans.isEmpty) {
        emit(current.copyWith(isGenerating: false));
        emit(PlanningError("لا توجد توليفة مناسبة للمقاسات الحالية"));
        return;
      }

      // حفظ واستهلاك الكميات المحددة في كل أوردر
      for (var plan in newPlans) {
        for (var item in plan.items) {
          if (item.orderId != 0) {
            // نحدث الكمية المجدولة بمقدار ما تم استهلاكه في هذه النقلة
            await db.consumeOrder(item.orderId, item.quantity);
          }
        }
      }

      await db.saveProductionPlans(newPlans);

      final allPlansFromDb = await db.getSavedPlans();
      final updatedOrders = await db.getAllOrders();

      _processData(allPlansFromDb, updatedOrders, selectedGram: current.selectedGram);

    } catch (e) {
      emit(current.copyWith(isGenerating: false));
      emit(const PlanningError("حدث خطأ أثناء التوليد"));
    }
  }

  Future<void> clearHistory() async {
    await db.clearAllPlans();
    await loadData();
  }
}