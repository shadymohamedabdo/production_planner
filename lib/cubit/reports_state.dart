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
  final bool isPrinting;
  final double? selectedGram;

  const ReportsLoaded({
    required this.plans,
    this.isPrinting = false,
    this.selectedGram,
  });

  @override
  List<Object?> get props => [plans, isPrinting, selectedGram];

  ReportsLoaded copyWith({
    List<ProductionPlan>? plans,
    bool? isPrinting,
    double? selectedGram,
  }) {
    return ReportsLoaded(
      plans: plans ?? this.plans,
      isPrinting: isPrinting ?? this.isPrinting,
      selectedGram: selectedGram,   // نسمح بـ null عشان "جميع الجرامات"
    );
  }
}

// حالة خاصة بالفلتر (مهمة جداً للـ BlocBuilder)
class ReportsFilterUpdated extends ReportsState {
  final List<ProductionPlan> plans;
  final double? selectedGram;

  const ReportsFilterUpdated({
    required this.plans,
    this.selectedGram,
  });

  @override
  List<Object?> get props => [plans, selectedGram];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}