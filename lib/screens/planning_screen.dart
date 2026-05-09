// screens/planning_screen.dart

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

  final List<ProductionPlan> _visiblePlans = [];

  final GlobalKey<AnimatedListState> _listKey =
  GlobalKey<AnimatedListState>();

  bool _isGenerating = false;

  late List<double> _availableGrams;

  late double _selectedPriorityGram;

  @override
  void initState() {
    super.initState();

    /// جلب الجرامات المتاحة
    _availableGrams =
        widget.orders.map((o) => o.grams).toSet().toList();

    /// ترتيب الجرامات
    _availableGrams.sort();

    _selectedPriorityGram =
    _availableGrams.isNotEmpty
        ? _availableGrams.first
        : 200.0;
  }

  Future<void> _clearAnimatedList() async {

    for (int i = _visiblePlans.length - 1; i >= 0; i--) {

      final removedItem = _visiblePlans.removeAt(i);

      _listKey.currentState?.removeItem(
        i,
            (context, animation) {
          return SizeTransition(
            sizeFactor: animation,
            child: PlanCard(
              plan: removedItem,
              index: i,
            ),
          );
        },
        duration: const Duration(milliseconds: 250),
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _startProduction() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);
    await _clearAnimatedList();

    List<double> priority = [_selectedPriorityGram];
    priority.addAll(_availableGrams.where((g) => g != _selectedPriorityGram));

    // تشغيل الخوارزمية المحدثة
    final allPlans = PlanningAlgorithm.generatePlans(widget.orders, priority);

    if (allPlans.isEmpty) {
      // لو لسه مفيش خطط، نظهر رسالة تنبيه
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا يوجد طلبات كافية لبدء التشغيل!")),
      );
    } else {
      for (int i = 0; i < allPlans.length; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        _visiblePlans.add(allPlans[i]);
        _listKey.currentState?.insertItem(_visiblePlans.length - 1);
      }
    }

    setState(() => _isGenerating = false);
  }
  Color _getEfficiencyColor(double totalWidth) {

    if (totalWidth >= 4.90) {
      return Colors.green;
    }

    if (totalWidth >= 4.85) {
      return Colors.orange;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'محاكاة خط الإنتاج',
        ),
      ),

      body: Column(

        children: [

          /// شريط التحكم العلوي
          Container(

            padding: const EdgeInsets.all(15),

            color: Colors.blue.shade50,

            child: Column(

              children: [

                Row(

                  children: [

                    const Text(
                      "ابدأ بجرام:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(width: 10),

                    DropdownButton<double>(

                      value: _selectedPriorityGram,

                      items: _availableGrams.map((g) {

                        return DropdownMenuItem<double>(
                          value: g,
                          child: Text(
                            g.toString(),
                          ),
                        );

                      }).toList(),

                      onChanged: _isGenerating
                          ? null
                          : (val) {

                        setState(() {
                          _selectedPriorityGram = val!;
                        });

                      },
                    ),

                    const Spacer(),

                    ElevatedButton.icon(

                      onPressed: _isGenerating
                          ? null
                          : _startProduction,

                      icon: Icon(
                        _isGenerating
                            ? Icons.settings
                            : Icons.play_circle_fill,
                      ),

                      label: Text(
                        _isGenerating
                            ? "جاري التشغيل..."
                            : "تشغيل الماكينة",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// عرض الجرام الحالي
                Container(

                  width: double.infinity,

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Row(

                    children: [

                      const Icon(
                        Icons.factory,
                        color: Colors.blue,
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "الجرام الحالي: $_selectedPriorityGram",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// قائمة النقلات
          Expanded(

            child: _visiblePlans.isEmpty

                ? Center(

              child: Text(
                _isGenerating
                    ? "جاري إنشاء خطة التشغيل..."
                    : "اضغط تشغيل الماكينة",
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            )

                : AnimatedList(

              key: _listKey,

              initialItemCount: _visiblePlans.length,

              padding: const EdgeInsets.all(10),

              itemBuilder:
                  (context, index, animation) {

                final plan =
                _visiblePlans[index];

                return SlideTransition(

                  position: animation.drive(

                    Tween(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ),
                  ),

                  child: Container(

                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),

                    decoration: BoxDecoration(

                      borderRadius:
                      BorderRadius.circular(16),

                      border: Border.all(
                        color: _getEfficiencyColor(
                          plan.totalWidth,
                        ),
                        width: 2,
                      ),
                    ),

                    child: Column(

                      children: [

                        /// بيانات التشغيل
                        Container(

                          padding:
                          const EdgeInsets.all(12),

                          decoration: BoxDecoration(

                            color: _getEfficiencyColor(
                              plan.totalWidth,
                            ).withOpacity(0.08),

                            borderRadius:
                            const BorderRadius.only(
                              topLeft:
                              Radius.circular(16),
                              topRight:
                              Radius.circular(16),
                            ),
                          ),

                          child: Row(

                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                            children: [

                              Text(
                                "نقلة ${index + 1}",
                                style: const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              Column(

                                crossAxisAlignment:
                                CrossAxisAlignment.end,

                                children: [

                                  Text(
                                    "الإجمالي: ${plan.totalWidth.toStringAsFixed(2)} م",
                                  ),

                                  Text(
                                    "الهالك: ${plan.waste.toStringAsFixed(2)} م",
                                    style: TextStyle(
                                      color:
                                      _getEfficiencyColor(
                                        plan.totalWidth,
                                      ),
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        /// تفاصيل النقلة
                        PlanCard(
                          plan: plan,
                          index: index,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}