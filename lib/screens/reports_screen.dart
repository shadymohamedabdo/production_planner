import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  bool isLoading = false;

  /// ================= تحميل الخطط =================
  Future<void> _loadCurrentPlan() async {

    try {

      setState(() {
        isLoading = true;
      });

      final allOrders = await db.getAllOrders();

      if (allOrders.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد طلبات حالياً'),
          ),
        );

        return;
      }

      final gramsList = await db.getDistinctGrams();

      final generated =
      PlanningAlgorithm.generatePlans(
        allOrders,
        gramsList,
      );

      setState(() {
        _plans = generated as List<ProductionPlan>;
      });

      debugPrint("عدد النقلات = ${_plans.length}");

    } catch (e) {

      debugPrint("ERROR => $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
        ),
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= طباعة التقرير =================
  Future<void> _printReport() async {

    if (_plans.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد خطط للطباعة'),
        ),
      );

      return;
    }

    final pdf = pw.Document();

    final font = await PdfGoogleFonts.cairoRegular();

    pdf.addPage(

      pw.MultiPage(

        pageFormat: PdfPageFormat.a4,

        theme: pw.ThemeData.withFont(
          base: font,
        ),

        build: (context) {

          return [

            pw.Directionality(

              textDirection: pw.TextDirection.rtl,

              child: pw.Column(

                crossAxisAlignment:
                pw.CrossAxisAlignment.start,

                children: [

                  pw.Center(

                    child: pw.Text(
                      'تقرير خطة الإنتاج',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  ..._plans.asMap().entries.map((entry) {

                    final index = entry.key;
                    final plan = entry.value;

                    return pw.Container(

                      margin: const pw.EdgeInsets.only(
                        bottom: 20,
                      ),

                      padding: const pw.EdgeInsets.all(10),

                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                        borderRadius:
                        pw.BorderRadius.circular(8),
                      ),

                      child: pw.Column(

                        crossAxisAlignment:
                        pw.CrossAxisAlignment.start,

                        children: [

                          pw.Text(
                            'نقلة رقم ${index + 1}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight:
                              pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(height: 5),

                          pw.Text(
                            'الجرام: ${plan.grams}',
                          ),

                          pw.Text(
                            'إجمالي العرض: '
                                '${plan.totalWidth.toStringAsFixed(2)} م',
                          ),

                          pw.Text(
                            'الهالك: '
                                '${(4.95 - plan.totalWidth).toStringAsFixed(2)} م',
                          ),

                          pw.SizedBox(height: 10),

                          pw.Table(

                            border:
                            pw.TableBorder.all(),

                            children: [

                              /// Header
                              pw.TableRow(

                                decoration:
                                const pw.BoxDecoration(),

                                children: [

                                  _tableCell(
                                    'العميل',
                                    isHeader: true,
                                  ),

                                  _tableCell(
                                    'العرض',
                                    isHeader: true,
                                  ),

                                  _tableCell(
                                    'الكمية',
                                    isHeader: true,
                                  ),
                                ],
                              ),

                              /// Rows
                              ...plan.items.map(

                                    (item) => pw.TableRow(

                                  children: [

                                    _tableCell(
                                      item.customerName,
                                    ),

                                    _tableCell(
                                      '${item.width} م',
                                    ),

                                    _tableCell(
                                      '${item.quantity}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'production_plan.pdf',
    );
  }

  /// ================= Cell Widget =================
  pw.Widget _tableCell(
      String text, {
        bool isHeader = false,
      }) {

    return pw.Padding(

      padding: const pw.EdgeInsets.all(6),

      child: pw.Text(

        text,

        textAlign: pw.TextAlign.center,

        style: pw.TextStyle(

          fontSize: isHeader ? 14 : 12,

          fontWeight:
          isHeader
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('التقارير'),

        actions: [

          IconButton(
            onPressed: _printReport,
            icon: const Icon(Icons.print),
          ),

          IconButton(
            onPressed: _loadCurrentPlan,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body:

      isLoading

          ? const Center(
        child: CircularProgressIndicator(),
      )

          : _plans.isEmpty

          ? Center(

        child: ElevatedButton(

          onPressed: _loadCurrentPlan,

          child: const Text(
            'تحميل الخطة الحالية',
          ),
        ),
      )

          : ListView.builder(

        padding: const EdgeInsets.all(12),

        itemCount: _plans.length,

        itemBuilder: (_, i) {

          final plan = _plans[i];

          return Card(

            elevation: 3,

            margin: const EdgeInsets.only(
              bottom: 12,
            ),

            child: ListTile(

              leading: CircleAvatar(
                child: Text('${i + 1}'),
              ),

              title: Text(
                'نقلة جرام ${plan.grams}',
              ),

              subtitle: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    'إجمالي العرض: '
                        '${plan.totalWidth.toStringAsFixed(2)} م',
                  ),

                  Text(
                    'عدد المقاسات: '
                        '${plan.items.length}',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}