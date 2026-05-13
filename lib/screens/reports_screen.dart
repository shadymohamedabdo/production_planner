import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/plan.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double? _selectedGramFilter; // null = الكل

  @override
  Widget build(BuildContext context) {
    context.read<ReportsCubit>().loadReports();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('أرشيف التقارير والخطط'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ReportsCubit>().loadReports(),
          ),
        ],
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReportsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  ElevatedButton.icon(
                    onPressed: () => context.read<ReportsCubit>().loadReports(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is ReportsLoaded) {
            if (state.plans.isEmpty) return _buildEmptyState();

            // فلترة الخطط حسب الجرام المختار
            final filteredPlans = _selectedGramFilter == null
                ? state.plans
                : state.plans.where((p) => p.grams == _selectedGramFilter).toList();

            return Column(
              children: [
                _buildSummaryHeader(state.plans, filteredPlans.length),
                Expanded(
                  child: filteredPlans.isEmpty
                      ? const Center(child: Text("لا توجد نقلات لهذا الجرام"))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: filteredPlans.length,
                    itemBuilder: (context, index) => _buildEnhancedPlanCard(
                      context,
                      filteredPlans[index],
                      index + 1,
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text("جاري تحميل التقارير..."));
        },
      ),

      // أزرار الطباعة
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'all',
            onPressed: () => context.read<ReportsCubit>().printAllPlans(),
            icon: const Icon(Icons.print),
            label: const Text('طباعة الكل'),
            backgroundColor: Colors.green,
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'grouped',
            onPressed: () => context.read<ReportsCubit>().printGroupedByGrams(),
            icon: const Icon(Icons.layers),
            label: const Text('مجمعة'),
            backgroundColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  // ====================== Header مع فلتر الجرام ======================
  Widget _buildSummaryHeader(List<ProductionPlan> allPlans, int filteredCount) {
    final grams = allPlans.map((p) => p.grams).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("إجمالي النقلات", "${allPlans.length}", Icons.list_alt, Colors.blue),
              _buildStatItem("النقلات المعروضة", "$filteredCount", Icons.filter_list, Colors.indigo),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("فلتر الجرام: ", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<double?>(
                  isExpanded: true,
                  value: _selectedGramFilter,
                  hint: const Text("الكل"),
                  items: [
                    const DropdownMenuItem<double?>(value: null, child: Text("جميع الجرامات")),
                    ...grams.map((gram) => DropdownMenuItem(
                      value: gram,
                      child: Text("جرام ${gram.toInt()}"),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedGramFilter = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildEnhancedPlanCard(BuildContext context, ProductionPlan plan, int index) {
    final efficiency = (plan.totalWidth / 5.0 * 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: efficiency > 96 ? Colors.green : efficiency > 92 ? Colors.orange : Colors.red,
          child: Text("$index", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        title: Text(
          "جرام ${plan.grams.toInt()}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "${plan.date.toString().split(' ')[0]} • كفاءة ${efficiency.toStringAsFixed(1)}%",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.print, color: Colors.blueGrey),
          onPressed: () => context.read<ReportsCubit>().printSinglePlan(plan),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("تفاصيل النقلة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                ...plan.items.map((item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_right, color: Colors.indigo),
                  title: Text(item.customerName),
                  trailing: Text("${item.width.toInt()} سم × ${item.quantity}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("إجمالي العرض: ${plan.totalWidth.toStringAsFixed(2)} م",
                        style: const TextStyle(fontSize: 15)),
                    Text("الهالك: ${plan.waste.toStringAsFixed(2)} م",
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 90, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text("لا توجد تقارير محفوظة حتى الآن", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          const Text("سيتم حفظ الخطط تلقائياً بعد توليدها", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}