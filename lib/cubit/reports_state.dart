// logic/reports_cubit/reports_state.dart
import 'package:equatable/equatable.dart';
import '../../models/plan.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}
class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final List<ProductionPlan> plans;
  final bool isPrinting; // عشان نعرف لو في ملف PDF بيتحضر حالياً

  const ReportsLoaded({required this.plans, this.isPrinting = false});

  @override
  List<Object?> get props => [plans, isPrinting];

  ReportsLoaded copyWith({List<ProductionPlan>? plans, bool? isPrinting}) {
    return ReportsLoaded(
      plans: plans ?? this.plans,
      isPrinting: isPrinting ?? this.isPrinting,
    );
  }
}

class ReportsError extends ReportsState {
  final String message;
  const ReportsError(this.message);
}