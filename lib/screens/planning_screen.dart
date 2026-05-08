import 'package:flutter/material.dart';
import '../algorithms/planning_algorithm..dart';
import '../models/order.dart';
import '../models/plan.dart';
import '../widgets/plan_card.dart';

class PlanningScreen extends StatefulWidget {
  final List<Order> orders;

  const PlanningScreen({
    Key? key,
    required this.orders,
  }) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  // قائمة للعرض تشمل الخطط (ProductionPlan) أو الفواضل (LeftoverReport)
  final List<dynamic> _visibleItems = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  bool _isGenerating = false;
  late List<double> _availableGrams;
  late double _selectedPriorityGram;

  @override
  void initState() {
    super.initState();
    _availableGrams = widget.orders.map((o) => o.grams).toSet().toList();
    _availableGrams.sort();
    _selectedPriorityGram = _availableGrams.isNotEmpty ? _availableGrams.first : 200.0;
  }

  Future<void> _clearAnimatedList() async {
    for (int i = _visibleItems.length - 1; i >= 0; i--) {
      final removedItem = _visibleItems.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
            (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: _buildItemByType(removedItem, i, animation),
        ),
        duration: const Duration(milliseconds: 200),
      );
    }
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _startProduction() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);
    await _clearAnimatedList();

    List<double> priority = [_selectedPriorityGram];
    priority.addAll(_availableGrams.where((g) => g != _selectedPriorityGram));

    // تشغيل الخوارزمية والحصول على النتيجة الشاملة
    final result = PlanningAlgorithm.generatePlans(widget.orders, priority);

    // 1. إضافة الخطط (Plans)
    for (int i = 0; i < result.plans.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      _visibleItems.add(result.plans[i]);
      _listKey.currentState?.insertItem(_visibleItems.length - 1);
    }

    // 2. إضافة تقرير الفواضل (Leftovers) في النهاية إذا وُجدت
    if (result.leftoversByGram.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      _visibleItems.add(result.leftoversByGram); // نمرر الخريطة كاملة
      _listKey.currentState?.insertItem(_visibleItems.length - 1);
    }

    setState(() => _isGenerating = false);
  }

  // دالة مساعدة لبناء الـ Widget بناءً على نوع البيانات (خطة أم فواضل)
  Widget _buildItemByType(dynamic item, int index, Animation<double> animation) {
    if (item is ProductionPlan) {
      return _buildPlanContainer(item, index, animation);
    } else {
      return _buildLeftoverCard(item as Map<double, Map<double, int>>, animation);
    }
  }

  // حاوية الخطة العادية
  Widget _buildPlanContainer(ProductionPlan plan, int index, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(Tween(begin: const Offset(0, 0.5), end: Offset.zero)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getEfficiencyColor(plan.totalWidth), width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getEfficiencyColor(plan.totalWidth).withOpacity(0.08),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("نقلة ${index + 1} - جرام ${plan.grams}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("الإجمالي: ${plan.totalWidth.toStringAsFixed(2)} م"),
                      Text("الهالك: ${plan.waste.toStringAsFixed(2)} م",
                          style: TextStyle(color: _getEfficiencyColor(plan.totalWidth), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            PlanCard(plan: plan, index: index),
          ],
        ),
      ),
    );
  }

  // كارت الفواضل (اللمسة الاحترافية)
  Widget _buildLeftoverCard(Map<double, Map<double, int>> leftovers, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400, width: 1, strokeAlign: BorderSide.strokeAlignOutside),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.blueGrey),
                SizedBox(width: 10),
                Text("تقرير الفواضل (المقاسات المتبقية)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
            const Divider(height: 20),
            ...leftovers.entries.map((gramEntry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("جرام ${gramEntry.key}:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    Wrap(
                      spacing: 8,
                      children: gramEntry.value.entries.map((e) => Chip(
                        label: Text("عرض ${e.key} م × ${e.value}"),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                      )).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Center(
              child: Text("هذه المقاسات لم تكتمل لتكوين نقلة صحيحة (أقل من 4.80 م)",
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEfficiencyColor(double totalWidth) {
    if (totalWidth >= 4.90) return Colors.green;
    if (totalWidth >= 4.85) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاكاة خط الإنتاج')),
      body: Column(
        children: [
          // شريط التحكم
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    const Text("ابدأ بجرام:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 10),
                    DropdownButton<double>(
                      value: _selectedPriorityGram,
                      items: _availableGrams.map((g) => DropdownMenuItem(value: g, child: Text(g.toString()))).toList(),
                      onChanged: _isGenerating ? null : (val) => setState(() => _selectedPriorityGram = val!),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _startProduction,
                      icon: Icon(_isGenerating ? Icons.settings : Icons.play_circle_fill),
                      label: Text(_isGenerating ? "جاري التشغيل..." : "تشغيل الماكينة"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // القائمة المتحركة
          Expanded(
            child: _visibleItems.isEmpty
                ? Center(child: Text(_isGenerating ? "جاري الحساب..." : "اضغط تشغيل"))
                : AnimatedList(
              key: _listKey,
              initialItemCount: _visibleItems.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index, animation) => _buildItemByType(_visibleItems[index], index, animation),
            ),
          ),
        ],
      ),
    );
  }
}