// screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

import '../models/plan.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والخطط'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ReportsCubit>().loadReports(),
          ),
        ],
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) return const Center(child: CircularProgressIndicator());

          if (state is ReportsLoaded) {
            if (state.plans.isEmpty) return _buildEmptyState();

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.plans.length,
              itemBuilder: (context, index) => _buildPlanCard(context, state.plans[index], state.isPrinting),
            );
          }

          return const Center(child: Text("حدث خطأ ما"));
        },
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, ProductionPlan plan, bool isPrinting) {
    final efficiency = (plan.totalWidth / 5.0 * 100);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: efficiency > 95 ? Colors.green : Colors.orange,
          child: Text("${efficiency.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 10, color: Colors.white)),
        ),
        title: Text("جرام ${plan.grams.toInt()} - ${plan.date.toString().split(' ')[0]}"),
        subtitle: Text("عرض: ${plan.totalWidth.toStringAsFixed(2)} | هالك: ${plan.waste.toStringAsFixed(2)}"),
        trailing: isPrinting
            ? const CircularProgressIndicator()
            : IconButton(
          icon: const Icon(Icons.print, color: Colors.blue),
          onPressed: () => context.read<ReportsCubit>().printSinglePlan(plan),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
          Text("لا توجد خطط مؤرشفة"),
        ],
      ),
    );
  }
}