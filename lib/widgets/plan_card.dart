// widgets/plan_card.dart
import 'package:flutter/material.dart';
import '../models/plan.dart';

class PlanCard extends StatelessWidget {
  final ProductionPlan plan;
  final int index;

  const PlanCard({super.key, required this.plan, required this.index});

  @override
  Widget build(BuildContext context) {
    // تأكد من أن هناك عناصر قبل العرض لمنع أي خطأ غير متوقع
    if (plan.items.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(8),
        color: Colors.red.shade50,
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text('النقلة ${index + 1} - لا توجد بكرات!'),
          subtitle: Text(
            'جرام: ${plan.grams.toInt()} | عرض كلي: ${plan.totalWidth.toStringAsFixed(2)} م | هالك: ${plan.waste.toStringAsFixed(2)} م',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // تحديد حالة العرض (إذا كان أقل من 4.80 متر يعتبر غير مفضل ويظهر تنبيه)
    final bool isWidthWarning = plan.totalWidth < 4.80;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(), // يمنع الخطوط الفاصلة الافتراضية عند الفتح
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: isWidthWarning ? Colors.orange.shade100 : Colors.green.shade100,
          child: Text(
            '${index + 1}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWidthWarning ? Colors.orange.shade900 : Colors.green.shade900
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              "نقلة ${index + 1} - جرام: ${plan.grams.toInt()}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            if (isWidthWarning)
              const Tooltip(
                message: "تنبيه: العرض أقل من الحد الأدنى المفضل (4.80 م)",
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                ),
              ),
            Text(
              "العرض: ${plan.totalWidth.toStringAsFixed(2)} م",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWidthWarning ? Colors.orange.shade900 : Colors.green.shade900,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'الهالك: ${plan.waste.toStringAsFixed(2)} م',
            style: TextStyle(color: plan.waste > 0.15 ? Colors.red : Colors.grey.shade600),
          ),
        ),
        children: plan.items.map((item) {
          return Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              color: Colors.grey.shade50.withValues(alpha: 0.5),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.inventory_2_outlined, color: Colors.indigo, size: 20),
              title: Text(
                item.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              trailing: Text(
                'عرض ${item.width.toInt()} سم × ${item.quantity} بكرة',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}