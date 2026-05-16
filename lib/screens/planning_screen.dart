import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/planning_cubit.dart';
import '../cubit/planning_state.dart';

import '../models/plan.dart';
import '../models/order.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('جداول تشغيل الماكينة'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmDialog(context),
            tooltip: 'مسح السجل',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PlanningCubit>().loadData(),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: BlocConsumer<PlanningCubit, PlanningState>(
        buildWhen: (previous, current) => current is PlanningLoading || current is PlanningLoaded,
        listener: (context, state) {
          if (state is PlanningError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is PlanningLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PlanningLoaded) {
            return _buildContent(context, state);
          }
          return const Center(child: Text("برجاء تهيئة البيانات"));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlanningLoaded state) {
    final groupedIndices = _groupPlans(state.plans);
    return Column(
      children: [
        _buildHeaderControl(context, state),
        if (state.plans.isNotEmpty) _buildStatisticsCards(state),
        Expanded(
          child: CustomScrollView(
            slivers: [
              if (state.plans.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("لا توجد جداول متاحة. اضغط 'توليد الجداول'.")),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, gIndex) => _buildBatchTable(
                        context,
                        state.plans,
                        groupedIndices[gIndex],
                        key: PageStorageKey('group_${groupedIndices[gIndex].first}'),
                      ),
                      childCount: groupedIndices.length,
                    ),
                  ),
                ),
              if (state.waitingOrders.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                    child: _buildWaitingSection(state.waitingOrders),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatchTable(BuildContext context, List<ProductionPlan> allPlans, List<int> indices, {Key? key}) {
    final firstPlan = allPlans[indices.first];
    final headerSizes = firstPlan.items.map((e) => e.width.toInt().toString()).join(" + ");

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          controlAffinity: ListTileControlAffinity.trailing,
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text("${indices.length} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 18)),
              const Text("طقم", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              const Text("|", style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 12),
              Text("${firstPlan.grams.toInt()} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const Text("جرام", style: TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              const Text("|", style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "رصة: $headerSizes سم",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Text(
            "من نقلة رقم ${indices.first + 1} إلى ${indices.last + 1}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          children: [
            _buildTableHeader(),
            ...indices.map((idx) {
              final plan = allPlans[idx];
              final customers = plan.items.map((e) => e.customerName).toSet().join(" + ");
              final sizes = plan.items.map((e) => e.width.toInt().toString()).join(" + ");
              return Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  color: idx % 2 == 0 ? Colors.white : Colors.grey.shade50,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text("${idx + 1}", textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text(customers, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                    Expanded(flex: 4, child: Text(sizes, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    Expanded(flex: 2, child: Text(plan.totalWidth.toStringAsFixed(2), textAlign: TextAlign.center)),
                    Expanded(flex: 1, child: Text(plan.waste.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<List<int>> _groupPlans(List<ProductionPlan> plans) {
    if (plans.isEmpty) return [];
    List<List<int>> groups = [];
    List<int> currentGroupIndices = [0];
    for (int i = 1; i < plans.length; i++) {
      final currentItems = plans[i].items.map((e) => e.width).toList()..sort();
      final prevItems = plans[i - 1].items.map((e) => e.width).toList()..sort();
      if (currentItems.length == prevItems.length && _compareLists(currentItems, prevItems) && plans[i].grams == plans[i - 1].grams) {
        currentGroupIndices.add(i);
      } else {
        groups.add(currentGroupIndices);
        currentGroupIndices = [i];
      }
    }
    groups.add(currentGroupIndices);
    return groups;
  }

  bool _compareLists(List<double> a, List<double> b) {
    for (int i = 0; i < a.length; i++) if ((a[i] - b[i]).abs() > 0.001) return false;
    return true;
  }

  Widget _buildHeaderControl(BuildContext context, PlanningLoaded state) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<double>(
              decoration: const InputDecoration(labelText: "اختر الجرام"),
              // 🔴 التعديل السحري والآمن هنا:
              value: state.availableGrams.contains(state.selectedGram) && state.selectedGram != 0
                  ? state.selectedGram
                  : (state.availableGrams.isNotEmpty ? state.availableGrams.first : null),

              items: state.availableGrams.map((g) => DropdownMenuItem(
                value: g,
                child: Text("جرام: ${g.toInt()}"),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  context.read<PlanningCubit>().changeSelectedGram(val);
                }
              },
            ),
          ),          const SizedBox(width: 15),
          ElevatedButton.icon(
            onPressed: state.isGenerating ? null : () => context.read<PlanningCubit>().startGeneration(),
            icon: state.isGenerating ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bolt),
            label: Text(state.isGenerating ? "جاري الحساب..." : "توليد الجداول"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(PlanningLoaded state) {
    final totalWaste = state.plans.fold(0.0, (sum, p) => sum + p.waste);
    final efficiency = state.plans.isEmpty ? 0.0 : (state.plans.fold(0.0, (sum, p) => sum + p.totalWidth) / (state.plans.length * 5.0)) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _statCard("عدد النقلات", "${state.plans.length}", Colors.blue),
          _statCard("إجمالي الهالك", "${totalWaste.toStringAsFixed(2)} م", Colors.orange),
          _statCard("كفاءة التشغيل", "${efficiency.toStringAsFixed(1)}%", Colors.green),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 10)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          ],
        ),
      ),
    ),
  );

  Widget _buildTableHeader() {
    return Container(
      color: Colors.blueGrey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        children: [
          Expanded(flex: 1, child: Text("م", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 3, child: Text("العميل", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 4, child: Text("الرصة", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text("إجمالي", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 1, child: Text("هالك", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildWaitingSection(List<Order> waiting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 2),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("المقاسات المتبقية", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16)),
        ),
        Card(
          color: Colors.red.shade50,
          child: Column(
            children: waiting.map((order) {
              final remaining = order.quantity - (order.plannedQuantity ?? 0);
              return ListTile(
                dense: true,
                title: Text(order.customerName),
                subtitle: Text("مقاس: ${order.width.toInt()} سم | جرام: ${order.grams.toInt()}"),
                trailing: Text("$remaining بكرة", style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("مسح السجل"),
        content: const Text("هل أنت متأكد؟ سيتم مسح جميع الخطط المحفوظة."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              context.read<PlanningCubit>().clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text("مسح"),
          ),
        ],
      ),
    );
  }
}