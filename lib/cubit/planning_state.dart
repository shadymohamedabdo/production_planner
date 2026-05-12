import 'package:equatable/equatable.dart';
import '../../models/order.dart';
import '../../models/plan.dart';

abstract class PlanningState extends Equatable {
  const PlanningState();
  @override
  List<Object?> get props => [];
}

class PlanningInitial extends PlanningState {}

class PlanningLoading extends PlanningState {}

class PlanningLoaded extends PlanningState {
  final List<ProductionPlan> plans;
  final List<ProductionPlan> previousPlans; // للرجوع لو فشل التوليد
  final List<Order> waitingOrders;
  final List<double> availableGrams;
  final double selectedGram;
  final bool isGenerating;

  const PlanningLoaded({
    required this.plans,
    this.previousPlans = const [],
    required this.waitingOrders,
    required this.availableGrams,
    required this.selectedGram,
    this.isGenerating = false,
  });

  @override
  List<Object?> get props => [plans, waitingOrders, availableGrams, selectedGram, isGenerating];

  PlanningLoaded copyWith({
    List<ProductionPlan>? plans,
    List<ProductionPlan>? previousPlans,
    List<Order>? waitingOrders,
    List<double>? availableGrams,
    double? selectedGram,
    bool? isGenerating,
  }) {
    return PlanningLoaded(
      plans: plans ?? this.plans,
      previousPlans: previousPlans ?? this.previousPlans,
      waitingOrders: waitingOrders ?? this.waitingOrders,
      availableGrams: availableGrams ?? this.availableGrams,
      selectedGram: selectedGram ?? this.selectedGram,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

class PlanningError extends PlanningState {
  final String message;
  const PlanningError(this.message);
  @override
  List<Object> get props => [message];
}