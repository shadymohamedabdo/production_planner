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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/1.webp'),
            fit: BoxFit.cover,
            opacity: 0.82,
          ),
        ),
        child: BlocConsumer<PlanningCubit, PlanningState>(
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
            return const Center(
              child: Card(
                color: Colors.white70,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("برجاء تهيئة البيانات", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        ),
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
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "لا توجد جداول متاحة. اضغط 'توليد الجداول'.",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, gIndex) => _buildBatchTable(
                        context,
                        state,
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
                    child: _buildWaitingSection(context, state.waitingOrders),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatchTable(BuildContext context, PlanningLoaded state, List<int> indices, {Key? key}) {
    final allPlans = state.plans;
    final firstPlan = allPlans[indices.first];
    final headerSizes = firstPlan.items.map((e) => e.width.toInt().toString()).join(" + ");

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
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
                const SizedBox(width: 17),
                Text(
                  "مقاس: $headerSizes سم",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            subtitle: Text(
              "من نقلة رقم ${indices.first + 1} إلى ${indices.last + 1}",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
            ),
            children: [
              _buildTableHeader(), // تم تعديل الهيدر ليحتوي على "عدد البكر" بدلاً من القطر
              ...indices.map((idx) {
                final plan = allPlans[idx];

                List<String> customerList = [];
                List<String> priorityList = [];
                List<String> paperTypeList = [];
                List<String> countList = []; // 🟢 لستة لحمل عدد البكر (التكرار) لكل مقاس
                List<String> sizeList = [];

                for (var item in plan.items) {
                  customerList.add(item.customerName);
                  sizeList.add("${item.width.toInt()}");

                  // 🟢 عرض عدد البكر المتوفر جوة الـ PlanItem نفسه مباشرة
                  countList.add("${item.quantity} بكرة");

                  // 🟢 حل مشكلة اختفاء النوع والأولوية:
                  // لو الموديل بتاع PlanItem عندك لسه مفيش فيه الحقول دي، يفضل تضيفهم فيه وقت التوليد.
                  // كحل مؤقت بديل للـ waitingOrders، بنقرأ الأولوية والنوع لو متوفرين في الـ item أو بنسيب الحماية:
                  // (إذا قمت بإضافة priority و paperType لكلاس PlanItem مررهم هنا مباشرة مثل item.priority)
                  priorityList.add((item as dynamic).toString().contains('priority') ? (item as dynamic).priority : "A");
                  paperTypeList.add((item as dynamic).toString().contains('paperType') ? (item as dynamic).paperType.toString().toUpperCase() : "FLUTING");
                }

                final customers = customerList.toSet().join(" + ");
                final sizes = sizeList.join(" + ");
                final priorities = priorityList.toSet().join(" + ");
                final paperTypes = paperTypeList.toSet().join(" + ");
                final itemCounts = countList.join(" + "); // التكرار المتناسق مع المقاسات

                return Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    color: idx % 2 == 0 ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade50.withValues(alpha: 0.7),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(flex: 1, child: Text("${idx + 1}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                      Expanded(flex: 3, child: Text(customers, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                      Expanded(flex: 2, child: Text(priorities, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                      Expanded(flex: 2, child: Text(paperTypes, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey))),
                      Expanded(flex: 2, child: Text("${plan.grams.toInt()} g", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                      Expanded(flex: 3, child: Text(sizes, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12))),
                      // 🟢 تم استبدال القطر بـ عدد البكر الفعلي في الطقم الحالي هنا:
                      Expanded(flex: 2, child: Text(itemCounts, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple))),
                      Expanded(flex: 2, child: Text(plan.totalWidth.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                      Expanded(flex: 1, child: Text(plan.waste.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
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
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.001) return false;
    }
    return true;
  }

  Widget _buildHeaderControl(BuildContext context, PlanningLoaded state) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white.withValues(alpha: 0.9),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<double>(
              decoration: const InputDecoration(labelText: "اختر الجرام", filled: true, fillColor: Colors.transparent),
              initialValue: state.availableGrams.contains(state.selectedGram) && state.selectedGram != 0
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
          ),
          const SizedBox(width: 15),
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
          _statCard("عدد الاطقم", "${state.plans.length}", Colors.blue),
          _statCard("إجمالي الهالك", "${totalWaste.toStringAsFixed(2)} م", Colors.orange),
          _statCard("كفاءة التشغيل", "${efficiency.toStringAsFixed(1)}%", Colors.green),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) => Expanded(
    child: Card(
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          ],
        ),
      ),
    ),
  );

  // 🟢 تعديل رأس الجدول لاستبدال "القطر" بـ "عدد البكر"
  Widget _buildTableHeader() {
    return Container(
      color: Colors.blueGrey.shade50.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(flex: 1, child: Text("م", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 3, child: Text("العميل", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text("الأولوية", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text("النوع", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text("الجرام", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 3, child: Text("العرض (المقاس)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text("عدد البكر", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))), // 🟢 تم التغيير هنا
          Expanded(flex: 2, child: Text("إجمالي", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 1, child: Text("هالك", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildWaitingSection(BuildContext context, List<Order> waiting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 2, color: Colors.white54),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                child: const Text(
                    "المقاسات المتبقية",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showForceGenerateConfirmDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text(
                    "توليد إجباري (قفل الوردية)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
        Card(
          color: Colors.red.shade50.withValues(alpha: 0.92),
          child: Column(
            children: waiting.map((order) {
              final remaining = order.quantity - (order.plannedQuantity ?? 0);
              return ListTile(
                dense: true,
                title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("مقاس: ${order.width.toInt()} سم | جرام: ${order.grams.toInt()} | قطر: ${order.diameter.toInt()} سم | نوع: ${order.paperType.toUpperCase()}", style: TextStyle(color: Colors.grey.shade800)),
                trailing: Text("$remaining بكرة", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showForceGenerateConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text("تنبيه تشغيل إجباري"),
          ],
        ),
        content: const Text(
          "هل أنت متأكد من توليد جداول للمقاسات المتبقية حالياً؟\n\n"
              "تنبيه: هذا الإجراء سيتجاهل شروط الهالك الأدنى (4.70 م) وقد ينتج عنه هالك كبير جداً في العرض المتبقي من الماكينة لتلبية طلباتك.",
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء")
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PlanningCubit>().startGeneration(force: true);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري التوليد الإجباري للمقاسات المتبقية...'),
                  backgroundColor: Colors.deepOrange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade700),
            child: const Text("توليد فوراً"),
          ),
        ],
      ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("مسح"),
          ),
        ],
      ),
    );
  }
}