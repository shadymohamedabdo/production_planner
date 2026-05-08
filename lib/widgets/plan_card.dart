import 'package:flutter/material.dart';
import '../models/plan.dart';

class PlanCard extends StatelessWidget {
  final ProductionPlan plan;
  final int index;
  const PlanCard({super.key, required this.plan, required this.index});

  @override
  Widget build(BuildContext context) {
    // تأكد من أن هناك عناصر قبل العرض
    if (plan.items.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(8),
        child: ListTile(
          title: Text('النقلة ${index + 1} - لا توجد بكرات! (خطأ)'),
          subtitle: Text('جرام: ${plan.grams} | عرض كلي: ${plan.totalWidth.toStringAsFixed(2)} م | هالك: ${plan.waste.toStringAsFixed(2)} م'),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(
          'النقلة ${index + 1} - جرام: ${plan.grams} | إجمالي العرض: ${plan.totalWidth.toStringAsFixed(2)} م | الهالك: ${plan.waste.toStringAsFixed(2)} م',
        ),
        children: plan.items.map((item) => ListTile(
          leading: const Icon(Icons.inventory),
// داخل ملف widgets/plan_card.dart
// في جزء الـ title بتاع الـ ExpansionTile:

          title: Row(
            children: [
              Text("نقلة ${index + 1} - جرام: ${plan.grams}"),
              const Spacer(),
              if (plan.totalWidth < 4.80)
                const Tooltip(
                  message: "تنبيه: العرض أقل من الحد الأدنى المفضل",
                  child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                ),
              const SizedBox(width: 8),
              Text(
                "العرض: ${plan.totalWidth.toStringAsFixed(2)} م",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: plan.totalWidth < 4.80 ? Colors.orange.shade900 : Colors.green.shade900,
                ),
              ),
            ],
          ),          subtitle: Text('عرض ${item.width.toStringAsFixed(2)} م × ${item.quantity} بكرة'),
        )).toList(),
      ),
    );
  }
}