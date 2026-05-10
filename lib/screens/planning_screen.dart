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

  // حساب إجمالي الهالك
  double get _totalWaste => _allPlans.fold(0, (sum, plan) => sum + plan.waste);

  // حساب الكفاءة (الإجمالي المستخدم / الحد الأقصى للماكينة)
  String get _efficiency {
    if (_allPlans.isEmpty) return "0%";
    double totalWidthUsed = _allPlans.fold(0, (sum, plan) => sum + plan.totalWidth);
    double maxPotential = _allPlans.length * 4.95; // 4.95 هو أقصى عرض للماكينة
    return "${((totalWidthUsed / maxPotential) * 100).toStringAsFixed(1)}%";
  }

  List<List<dynamic>> _groupPlans() {
    if (_allPlans.isEmpty) return [];
    List<List<dynamic>> groups = [];
    List<int> currentGroupIndices = [0];
    for (int i = 1; i < _allPlans.length; i++) {
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('جداول تشغيل الماكينة')),
      body: Column(
        children: [
          _buildHeaderControl(),
          if (_allPlans.isNotEmpty) _buildStatisticsCards(), // إضافة الكروت هنا
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

  // بناء كروت الإحصائيات (نفس شكل الصورة ss.jfif)
  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Row(
        children: [
          _buildStatCard("عدد النقلات", "${_allPlans.length}", Colors.blue),
          _buildStatCard("إجمالي الهالك", "${_totalWaste.toStringAsFixed(2)} م", Colors.orange),
          _buildStatCard("كفاءة التشغيل", _efficiency, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 5),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            ],
          ),
        ),
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
          Text("الجرام الحالي: $_selectedPriorityGram", style: const TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            onPressed: _startProduction,
            icon: const Icon(Icons.bolt),
            label: Text(_isGenerating ? "جاري الحساب..." : "توليد الجداول"),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTable(List<int> indices) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Column(
        children: [
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
          const Divider(height: 1, color: Colors.black),
          ...indices.map((idx) {
            var plan = _allPlans[idx];
            String customerNames = plan.items.map((e) => e.customerName).toSet().join(" / ");
            String detailedSizes = plan.items.map((e) => e.width).join(" + ");
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text("${idx + 1}", textAlign: TextAlign.center)),
                      Expanded(flex: 3, child: Text(customerNames, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 2, child: Text("${plan.grams.toInt()}", textAlign: TextAlign.center)),
                      Expanded(flex: 3, child: Text(detailedSizes, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text("${plan.items.length}", textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text("${plan.totalWidth.toStringAsFixed(2)}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text("${plan.waste.toStringAsFixed(2)}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
                if (idx != indices.last) const Divider(height: 1, color: Colors.black12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}