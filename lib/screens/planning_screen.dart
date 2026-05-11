import 'package:flutter/material.dart';
import '../algorithms/planning_algorithm..dart';
import '../models/order.dart';
import '../models/plan.dart';
import '../database/database_helper.dart';

class PlanningScreen extends StatefulWidget {
  final List<Order> orders;
  final VoidCallback onDataChanged;

  const PlanningScreen({super.key, required this.orders, required this.onDataChanged});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  List<ProductionPlan> _allPlans = [];
  bool _isGenerating = false;
  late List<double> _availableGrams;
  late double _selectedPriorityGram;
  List<Order> _currentOrders = [];

  static const double machineMaxWidth = 5.00;
  static const double machineMinWidth = 4.70;

  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _currentOrders = List.from(widget.orders);
    _updateAvailableGrams();
  }

// داخل _updateAvailableGrams بعد الفرز
  void _updateAvailableGrams() {
    _availableGrams = _currentOrders
        .where((o) => o.status == 'انتظار' && o.quantity > 0)
        .map((o) => o.grams)
        .toSet()
        .toList()
      ..sort();
    if (_availableGrams.isNotEmpty) {
      _selectedPriorityGram = _availableGrams.first;
    } else {
      _selectedPriorityGram = 0.0; // قيمة افتراضية آمنة
    }
  }
  Future<void> _startProduction() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    // أولويات الجرامات
    List<double> priority = [
      _selectedPriorityGram,
      ..._availableGrams.where((g) => g != _selectedPriorityGram)
    ];

    // الطلبات المتبقية (حالة انتظار وكمية > 0)
    final ordersToPlan = _currentOrders
        .where((o) => o.status == 'انتظار' && o.quantity > 0)
        .toList();

    final plans = PlanningAlgorithm.generatePlans(ordersToPlan, priority);

    // استهلاك كل بكرة تم استخدامها في الخطة
    for (var plan in plans) {
      for (var item in plan.items) {
        if (item.orderId != 0) {
          await db.consumeOrder(item.orderId);
        }
      }
    }

    // إعادة تحميل الطلبات بعد التحديث
    final updatedOrders = await db.getAllOrders();
    setState(() {
      _currentOrders = updatedOrders;
      _updateAvailableGrams();
      _allPlans = plans;
      _isGenerating = false;
    });

    widget.onDataChanged();
  }

  List<Order> _getWaitingOrders() {
    return _currentOrders.where((o) => o.status == 'انتظار' && o.quantity > 0).toList();
  }

  double get _totalWaste => _allPlans.fold(0, (sum, plan) => sum + (machineMaxWidth - plan.totalWidth));

  String get _efficiency {
    if (_allPlans.isEmpty) return "0%";
    double totalWidthUsed = _allPlans.fold(0, (sum, plan) => sum + plan.totalWidth);
    double maxPotential = _allPlans.length * machineMaxWidth;
    return "${((totalWidthUsed / maxPotential) * 100).toStringAsFixed(1)}%";
  }

  List<List<int>> _groupPlans() {
    if (_allPlans.isEmpty) return [];
    List<List<int>> groups = [];
    List<int> currentGroupIndices = [0];

    for (int i = 1; i < _allPlans.length; i++) {
      var currentItems = _allPlans[i].items.map((e) => e.width).toList()..sort();
      var prevItems = _allPlans[i - 1].items.map((e) => e.width).toList()..sort();

      if (currentItems.length == prevItems.length &&
          _compareLists(currentItems, prevItems) &&
          _allPlans[i].grams == _allPlans[i - 1].grams) {
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
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    var groupedIndices = _groupPlans();
    var waitingOrders = _getWaitingOrders();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('جداول تشغيل الماكينة')),
      body: Column(
        children: [
          _buildHeaderControl(),
          if (_allPlans.isNotEmpty) _buildStatisticsCards(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  if (_allPlans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Text("لا توجد جداول متاحة في النطاق المطلوب (4.70 - 5.00)"),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupedIndices.length,
                      itemBuilder: (context, gIndex) {
                        return _buildBatchTable(groupedIndices[gIndex]);
                      },
                    ),
                  if (waitingOrders.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    const Divider(thickness: 2, color: Colors.redAccent),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            "بواقي المقاسات (في الانتظار)",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    _buildWaitingOrdersList(waitingOrders),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingOrdersList(List<Order> waiting) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade100),
      ),
      child: Column(
        children: waiting.map((order) {
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: Text("${order.width.toInt()}", style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
            title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("المقاس: ${order.width} سم | الجرام: ${order.grams.toInt()}"),
            trailing: Text("باقي: ${order.quantity} بكرة", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              const SizedBox(height: 5),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
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
        children: [
          Expanded(
            child: DropdownButton<double>(
              value: _selectedPriorityGram,
              isExpanded: true,
              items: _availableGrams.map((g) => DropdownMenuItem(value: g, child: Text("جرام: ${g.toInt()}"))).toList(),
              onChanged: (val) => setState(() => _selectedPriorityGram = val!),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _startProduction,
            icon: const Icon(Icons.bolt),
            label: Text(_isGenerating ? "جاري الحساب..." : "توليد الجداول"),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTable(List<int> indices) {
    var firstPlanInBatch = _allPlans[indices.first];
    String headerSizes = firstPlanInBatch.items.map((e) => (e.width / 100).toStringAsFixed(1)).join(" + ");

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: ExpansionTile(
        controlAffinity: ListTileControlAffinity.leading,
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Text("${indices.length} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
              Text(
                "طقم | جرام: ${firstPlanInBatch.grams.toInt()} | عرض: $headerSizes م",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900, fontSize: 15),
              ),
            ],
          ),
        ),
        subtitle: Directionality(
          textDirection: TextDirection.rtl,
          child: Text("إجمالي الاطقم من ${indices.first + 1} إلى ${indices.last + 1}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
        children: [
          _buildTableHeader(),
          ...indices.map((idx) {
            var plan = _allPlans[idx];
            String allCustomerNames = plan.items.map((e) => e.customerName).toSet().join(" + ");
            String detailedSizes = plan.items.map((e) => e.width.toInt().toString()).join(" + ");

            return Container(
              color: idx % 2 == 0 ? Colors.white : Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text("${idx + 1}", textAlign: TextAlign.center)),
                  Expanded(flex: 3, child: Text(allCustomerNames, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500))),
                  Expanded(flex: 2, child: Text("${plan.grams.toInt()}", textAlign: TextAlign.center)),
                  Expanded(flex: 4, child: Text(detailedSizes, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                  Expanded(flex: 2, child: Text("${plan.totalWidth.toStringAsFixed(2)} م", textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text("${(machineMaxWidth - plan.totalWidth).toStringAsFixed(2)}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: const [
          Expanded(flex: 1, child: Text("م", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 3, child: Text("العميل", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text("جرام", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 4, child: Text("الرصة (سم)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text("الإجمالي", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 1, child: Text("هالك", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }
}