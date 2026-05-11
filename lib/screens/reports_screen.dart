import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../database/database_helper.dart';
import '../models/plan.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<ProductionPlan> _plans = [];
  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await db.getAllProductionPlans();
    setState(() => _plans = plans);
  }

  // ====================== طباعة خطة واحدة ======================
  Future<void> _printPlan(ProductionPlan plan) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicFontBold = await PdfGoogleFonts.notoSansArabicBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
        build: (context) => _buildPlanContent(plan, arabicFont, arabicFontBold),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'خطة_إنتاج_${plan.grams}_${plan.date.toLocal().toString().split(' ')[0]}.pdf',
    );
  }

  // ====================== طباعة كل الخطط ======================
  Future<void> _printAllPlans() async {
    if (_plans.isEmpty) return;

    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicFontBold = await PdfGoogleFonts.notoSansArabicBold();

    for (int i = 0; i < _plans.length; i++) {
      final plan = _plans[i];
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
          header: (context) => _buildHeader(i + 1, _plans.length, arabicFontBold),
          build: (context) => _buildPlanContent(plan, arabicFont, arabicFontBold),
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'جميع_خطط_الإنتاج_${DateTime.now().toString().split(' ')[0]}.pdf',
    );
  }

  // ====================== طباعة التقارير المجمعة ======================
  Future<void> _printGroupedPlans() async {
    if (_plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد خطط للتجميع')),
      );
      return;
    }

    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicFontBold = await PdfGoogleFonts.notoSansArabicBold();

    // تجميع الخطط حسب الجرام + تركيبة العروض
    Map<String, List<ProductionPlan>> grouped = {};

    for (var plan in _plans) {
      // تصليح الخطأ هنا
      List<String> widthsList = plan.items
          .map((e) => e.width.toStringAsFixed(2))
          .toList()
        ..sort();

      String widthsKey = widthsList.join("_");
      String groupKey = '${plan.grams}_$widthsKey';

      grouped.putIfAbsent(groupKey, () => []).add(plan);
    }

    int pageNum = 1;

    for (var group in grouped.values) {
      if (group.isEmpty) continue;

      final firstPlan = group.first;
      int totalRolls = group.fold(0, (sum, p) =>
      sum + p.items.fold(0, (s, i) => s + i.quantity));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
          header: (context) => _buildGroupedHeader(pageNum++, grouped.length, arabicFontBold),
          build: (context) => _buildGroupedContent(
              group, firstPlan, totalRolls, arabicFont, arabicFontBold),
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'خطط_مجمعة_${DateTime.now().toString().split(' ')[0]}.pdf',
    );
  }

  pw.Widget _buildHeader(int current, int total, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Text('جميع خطط الإنتاج', style: pw.TextStyle(font: boldFont, fontSize: 20)),
        pw.Text('صفحة $current من $total', style: pw.TextStyle(fontSize: 12)),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildGroupedHeader(int current, int total, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Text('خطط الإنتاج المجمعة', style: pw.TextStyle(font: boldFont, fontSize: 20)),
        pw.Text('صفحة $current من $total', style: pw.TextStyle(fontSize: 12)),
        pw.Divider(),
      ],
    );
  }

  List<pw.Widget> _buildPlanContent(
      ProductionPlan plan, pw.Font font, pw.Font boldFont) {
    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey700, width: 1.5),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('التاريخ: ${plan.date.toLocal().toString().split(' ')[0]}',
                    style: pw.TextStyle(font: boldFont)),
                pw.Text('الجرام: ${plan.grams}',
                    style: pw.TextStyle(font: boldFont, fontSize: 16)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('إجمالي العرض: ${plan.totalWidth.toStringAsFixed(2)} متر'),
                pw.Text(
                  'الهالك: ${plan.waste.toStringAsFixed(2)} متر',
                  style: pw.TextStyle(
                    font: boldFont,
                    color: plan.waste > 0.25 ? PdfColors.red600 : PdfColors.green700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 25),
      pw.Text('تفاصيل النقلة', style: pw.TextStyle(font: boldFont, fontSize: 16)),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600),
        columnWidths: {
          0: const pw.FlexColumnWidth(3.5),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue100),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('العميل', style: pw.TextStyle(font: boldFont))),
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('العرض (م)', style: pw.TextStyle(font: boldFont))),
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('الكمية', style: pw.TextStyle(font: boldFont))),
            ],
          ),
          ...plan.items.map((item) => pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(item.customerName)),
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(item.width.toStringAsFixed(2))),
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(item.quantity.toString())),
            ],
          )),
        ],
      ),
      pw.SizedBox(height: 30),
      pw.Center(
        child: pw.Text(
          'كفاءة النقلة: ${(plan.totalWidth / 5.0 * 100).toStringAsFixed(1)}%',
          style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blue800),
        ),
      ),
    ];
  }

  List<pw.Widget> _buildGroupedContent(
      List<ProductionPlan> group,
      ProductionPlan firstPlan,
      int totalRolls,
      pw.Font font,
      pw.Font boldFont) {
    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey700),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('الجرام: ${firstPlan.grams}', style: pw.TextStyle(font: boldFont, fontSize: 18)),
            pw.SizedBox(height: 8),
            pw.Text('عدد النقلات: ${group.length}'),
            pw.Text('إجمالي البكرات: $totalRolls بكرة'),
            pw.SizedBox(height: 12),
            pw.Text(
              'إجمالي العرض: ${group.fold(0.0, (sum, p) => sum + p.totalWidth).toStringAsFixed(2)} متر',
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Text('تفاصيل الطقم', style: pw.TextStyle(font: boldFont, fontSize: 16)),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue100),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('العميل', style: pw.TextStyle(font: boldFont))),
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('العرض (م)', style: pw.TextStyle(font: boldFont))),
              pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('الكمية الإجمالية', style: pw.TextStyle(font: boldFont))),
            ],
          ),
          ...firstPlan.items.map((item) {
            int totalQty = group.fold(0, (sum, plan) {
              var found = plan.items.where((i) => i.width == item.width);
              return sum + (found.isNotEmpty ? found.first.quantity : 0);
            });
            return pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(item.customerName)),
                pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(item.width.toStringAsFixed(2))),
                pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(totalQty.toString())),
              ],
            );
          }),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والخطط المخزنة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlans),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة الكل',
            onPressed: _plans.isEmpty ? null : _printAllPlans,
          ),
          IconButton(
            icon: const Icon(Icons.group_work_outlined),
            tooltip: 'طباعة التقارير المجمعة',
            onPressed: _plans.isEmpty ? null : _printGroupedPlans,
          ),
        ],
      ),
      body: _plans.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد خطط محفوظة حتى الآن', style: TextStyle(fontSize: 18)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          final efficiency = (plan.totalWidth / 5.0 * 100);

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: efficiency >= 98
                    ? Colors.green
                    : efficiency >= 94
                    ? Colors.orange
                    : Colors.red,
                child: Text(
                  '${efficiency.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text('جرام ${plan.grams}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تاريخ: ${plan.date.toLocal().toString().split(' ')[0]}'),
                  Text('إجمالي: ${plan.totalWidth.toStringAsFixed(2)} م | هالك: ${plan.waste.toStringAsFixed(2)} م'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.print, color: Colors.blue),
                onPressed: () => _printPlan(plan),
              ),
              onTap: () => _showPlanDetails(plan),
            ),
          );
        },
      ),
    );
  }

  void _showPlanDetails(ProductionPlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفاصيل الخطة'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('التاريخ', plan.date.toLocal().toString().split(' ')[0]),
                _infoRow('الجرام', plan.grams.toString()),
                _infoRow('إجمالي العرض', '${plan.totalWidth.toStringAsFixed(2)} متر'),
                _infoRow('الهالك', '${plan.waste.toStringAsFixed(2)} متر',
                    color: plan.waste > 0.25 ? Colors.red : Colors.green),
                const Divider(height: 25),
                const Text('البنود:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...plan.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• ${item.customerName}\n   عرض ${item.width} م × ${item.quantity} بكرة',
                    style: const TextStyle(fontSize: 15),
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('طباعة'),
            onPressed: () {
              Navigator.pop(ctx);
              _printPlan(plan);
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontWeight: color != null ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}