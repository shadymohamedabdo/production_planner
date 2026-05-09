import 'package:flutter/material.dart';
import '../algorithms/planning_algorithm..dart';
import '../models/order.dart';
import '../models/plan.dart';

class PlanningScreen extends StatefulWidget {
  final List<Order> orders;
  const PlanningScreen({Key? key, required this.orders}) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  List<ProductionPlan> _allPlans = [];
  bool _isGenerating = false;
  late List<double> _availableGrams;
  late double _selectedPriorityGram;

  @override
  void initState() {
    super.initState();
    _availableGrams = widget.orders.map((o) => o.grams).toSet().toList()..sort();
    _selectedPriorityGram = _availableGrams.isNotEmpty ? _availableGrams.first : 0.0;
  }

  void _startProduction() {
    setState(() => _isGenerating = true);
    final results = PlanningAlgorithm.generatePlans(widget.orders, [_selectedPriorityGram, ..._availableGrams.where((g) => g != _selectedPriorityGram)]);
    setState(() {
      _allPlans = results;
      _isGenerating = false;
    });
  }

  // دالة لتقسيم النقلات لمجموعات (كل ما المقاسات تتغير يعمل جدول جديد)
  List<List<dynamic>> _groupPlans() {
    if (_allPlans.isEmpty) return [];

    List<List<dynamic>> groups = [];
    List<int> currentGroupIndices = [0];

    for (int i = 1; i < _allPlans.length; i++) {
      // بنقارن المقاسات في النقلة الحالية بالنقلة اللي قبلها
      var currentItems = _allPlans[i].items.map((e) => e.width).toSet();
      var prevItems = _allPlans[i-1].items.map((e) => e.width).toSet();

      if (currentItems.length == prevItems.length && currentItems.containsAll(prevItems)) {
        currentGroupIndices.add(i);
      } else {
        groups.add(currentGroupIndices);
        currentGroupIndices = [i];
      }
    }
    groups.add(currentGroupIndices);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    var groupedIndices = _groupPlans();

    return Scaffold(
      appBar: AppBar(title: const Text('جداول تشغيل الماكينة')),
      body: Column(
        children: [
          _buildHeaderControl(),
          Expanded(
            child: _allPlans.isEmpty
                ? const Center(child: Text("اضغط توليد الجداول لبدء التقسيم"))
                : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: groupedIndices.length,
              itemBuilder: (context, gIndex) {
                return _buildBatchTable(groupedIndices[gIndex] as List<int>);
              },
            ),
          ),
        ],
      ),
    );
  }

  // بناء الجدول المنفصل لكل مجموعة مقاسات
  Widget _buildBatchTable(List<int> indices) {
    // أول نقلة عشان نعرف البيانات المشتركة للمجموعة
    var firstPlan = _allPlans[indices.first];

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2), // حدود سوداء واضحة
      ),
      child: Column(
        children: [
          // صف عناوين الجدول (Header) - نفس ترتيب الصورة
          Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: const [
                Expanded(flex: 1, child: Text("م", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("اسم العميل", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("الجرام", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("المقاسات", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("عدد البكر", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("الإجمالي", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("هالك", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black), // خط فاصل أسود

          // عرض النقلات (الأسطر)
          ...indices.map((idx) {
            var plan = _allPlans[idx];

            // تجميع أسماء العملاء لو النقلة فيها أكتر من عميل
            String customerNames = plan.items.map((e) => e.customerName).toSet().join(" / ");
            // تجميع المقاسات (مثلاً 1.5 + 1.8)
            String detailedSizes = plan.items.map((e) => e.width).join(" + ");

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // رقم النقلة
                      Expanded(flex: 1, child: Text("${idx + 1}", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500))),

                      // اسم العميل
                      Expanded(flex: 3, child: Text(customerNames, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),

                      // الجرام
                      Expanded(flex: 2, child: Text("${plan.grams.toInt()}", textAlign: TextAlign.center)),

                      // المقاسات (السكاكين)
                      Expanded(flex: 3, child: Text(detailedSizes, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),

                      // عدد البكر في النقلة
                      Expanded(flex: 2, child: Text("${plan.items.length}", textAlign: TextAlign.center)),

                      // إجمالي عرض النقلة
                      Expanded(flex: 2, child: Text("${plan.totalWidth.toStringAsFixed(2)}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),

                      // الهالك
                      Expanded(flex: 1, child: Text("${plan.waste.toStringAsFixed(2)}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                // خط فاصل بين كل نقلة والتانية
                if (idx != indices.last) const Divider(height: 1, color: Colors.black12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
  Widget _buildHeaderControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("الجرام: $_selectedPriorityGram", style: const TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            onPressed: _startProduction,
            icon: const Icon(Icons.bolt),
            label: Text(_isGenerating ? "جاري الحساب..." : "توليد الجداول"),
          ),
        ],
      ),
    );
  }
}