import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../algorithms/planning_algorithm..dart';
import '../database/database_helper.dart';
import '../models/plan.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final db = DatabaseHelper();
  List<ProductionPlan> _plans = [];

  Future<void> _loadCurrentPlan() async {
    // 1. جلب كل الطلبات غير المخططة أولاً
    final allOrders = await db.getAllOrders(); // تأكد أن هذه الدالة تجلب الطلبات غير المخططة
    if (allOrders.isEmpty) return;

    // 2. جلب قائمة الجرامات المتاحة لعمل ترتيب افتراضي (Priority)
    final gramsList = await db.getDistinctGrams();

    // 3. استدعاء الخوارزمية بالـ 2 arguments المطلوبة
    // نمرر كل الطلبات، وقائمة الجرامات كأولوية
    final generated = PlanningAlgorithm.generatePlans(allOrders, gramsList);

    setState(() => _plans = generated as List<ProductionPlan>);
  }

  Future<void> _printReport() async {
    if (_plans.isEmpty) return;

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      // لإظهار اللغة العربية في الـ PDF ستحتاج لتحميل خط يدعم العربية، هذا مثال بسيط:
      header: (ctx) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Text('تقرير خطة الإنتاج', style: pw.TextStyle(fontSize: 20)),
      ),
      build: (ctx) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: _plans.asMap().entries.map((entry) {
              int idx = entry.key;
              var plan = entry.value;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('نقلة رقم ${idx + 1} - جرام: ${plan.grams}'),
                  pw.Divider(),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(children: [
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('الكمية')),
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('العرض')),
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('العميل')),
                      ]),
                      ...plan.items.map((item) => pw.TableRow(children: [
                        pw.Text('${item.quantity}'),
                        pw.Text('${item.width} م'),
                        pw.Text(item.customerName),
                      ])),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],
              );
            }).toList(),
          ),
        )
      ],
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'production_plan.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('التقارير'), actions: [
        IconButton(onPressed: _printReport, icon: Icon(Icons.print)),
        IconButton(onPressed: _loadCurrentPlan, icon: Icon(Icons.refresh)),
      ]),
      body: _plans.isEmpty
          ? Center(child: ElevatedButton(onPressed: _loadCurrentPlan, child: Text('تحميل الخطة الحالية')))
          : ListView.builder(
        itemCount: _plans.length,
        itemBuilder: (_, i) => ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text('نقلة جرام ${_plans[i].grams}'),
          subtitle: Text('عرض السيخ: ${_plans[i].totalWidth.toStringAsFixed(2)} م'),
        ),
      ),
    );
  }
}