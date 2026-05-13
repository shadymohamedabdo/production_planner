import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../database/database_helper.dart';
import '../../models/plan.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final DatabaseHelper db = DatabaseHelper();

  ReportsCubit() : super(ReportsInitial());

  Future<void> loadReports() async {
    emit(ReportsLoading());
    try {
      final plans = await db.getAllProductionPlans();
      emit(ReportsLoaded(plans: plans));
    } catch (e) {
      emit(const ReportsError("فشل في تحميل التقارير"));
    }
  }

  Future<Map<String, pw.Font>> _loadFonts() async {
    return {
      'regular': await PdfGoogleFonts.notoSansArabicRegular(),
      'bold': await PdfGoogleFonts.notoSansArabicBold(),
    };
  }

  // ====================== طباعة تقرير واحد ======================
  Future<void> printSinglePlan(ProductionPlan plan) async {
    if (state is! ReportsLoaded) return;

    final currentState = state as ReportsLoaded;
    emit(currentState.copyWith(isPrinting: true));

    try {
      final fonts = await _loadFonts();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: fonts['regular'], bold: fonts['bold']),
          build: (context) => _buildPlanPDFContent(plan, fonts['bold']!, index: 1),
        ),
      );

      final bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'خطة_إنتاج_${plan.grams.toInt()}_${DateTime.now().toString().split(' ')[0]}.pdf',
      );
    } catch (e) {
      // يمكنك إضافة SnackBar من الـ UI
      print("خطأ في طباعة التقرير: $e");
    } finally {
      emit(currentState.copyWith(isPrinting: false));
    }
  }

  // ====================== طباعة كل التقارير ======================
  Future<void> printAllPlans() async {
    if (state is! ReportsLoaded) return;
    final currentState = state as ReportsLoaded;
    emit(currentState.copyWith(isPrinting: true));

    try {
      final fonts = await _loadFonts();
      final pdf = pw.Document();

      for (int i = 0; i < currentState.plans.length; i++) {
        final plan = currentState.plans[i];
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            textDirection: pw.TextDirection.rtl,
            theme: pw.ThemeData.withFont(base: fonts['regular'], bold: fonts['bold']),
            build: (context) => _buildPlanPDFContent(plan, fonts['bold']!, index: i + 1),
          ),
        );
      }

      final bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'جميع_خطط_الإنتاج_${DateTime.now().toString().split(' ')[0]}.pdf',
      );
    } catch (e) {
      print("خطأ في طباعة الكل: $e");
    } finally {
      emit(currentState.copyWith(isPrinting: false));
    }
  }

  // ====================== طباعة مجمعة حسب الجرام ======================
  Future<void> printGroupedByGrams() async {
    if (state is! ReportsLoaded) return;
    final currentState = state as ReportsLoaded;
    emit(currentState.copyWith(isPrinting: true));

    try {
      final fonts = await _loadFonts();
      final pdf = pw.Document();

      final Map<double, List<ProductionPlan>> grouped = {};
      for (var plan in currentState.plans) {
        grouped.putIfAbsent(plan.grams, () => []).add(plan);
      }

      int groupIndex = 1;
      for (var entry in grouped.entries) {
        final gram = entry.key;
        final plans = entry.value;

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            textDirection: pw.TextDirection.rtl,
            theme: pw.ThemeData.withFont(base: fonts['regular'], bold: fonts['bold']),
            header: (context) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text(
                "تقرير مجمع - جرام ${gram.toInt()}",
                style: pw.TextStyle(font: fonts['bold'], fontSize: 20, color: PdfColors.blue800),
              ),
            ),
            build: (context) => _buildGroupedPlansContent(plans, fonts['bold']!),
          ),
        );
        groupIndex++;
      }

      final bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'تقارير_مجمعة_${DateTime.now().toString().split(' ')[0]}.pdf',
      );
    } catch (e) {
      print("خطأ في الطباعة المجمعة: $e");
    } finally {
      emit(currentState.copyWith(isPrinting: false));
    }
  }

  List<pw.Widget> _buildGroupedPlansContent(List<ProductionPlan> plans, pw.Font boldFont) {
    return plans.asMap().entries.expand((entry) {
      return [
        ..._buildPlanPDFContent(entry.value, boldFont, index: entry.key + 1),
        pw.SizedBox(height: 25),
        pw.Divider(thickness: 1.5, color: PdfColors.grey300),
        pw.SizedBox(height: 15),
      ];
    }).toList();
  }

  List<pw.Widget> _buildPlanPDFContent(ProductionPlan plan, pw.Font boldFont, {required int index}) {
    final efficiency = (plan.totalWidth / 5.0 * 100).toStringAsFixed(1);

    return [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("نقلة #$index", style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blue700)),
          pw.Text("التاريخ: ${plan.date.toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Text("جرام ${plan.grams.toInt()}", style: pw.TextStyle(font: boldFont, fontSize: 15)),
      pw.SizedBox(height: 15),
      pw.TableHelper.fromTextArray(
        headers: ['م', 'العميل', 'العرض (سم)', 'الكمية'],
        headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        data: plan.items.asMap().entries.map((e) => [
          (e.key + 1).toString(),
          e.value.customerName,
          e.value.width.toInt().toString(),
          e.value.quantity.toString(),
        ]).toList(),
      ),
      pw.SizedBox(height: 20),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("إجمالي: ${plan.totalWidth.toStringAsFixed(2)} م", style: const pw.TextStyle(fontSize: 12)),
          pw.Text("كفاءة: $efficiency%", style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.green700)),
          pw.Text("هالك: ${plan.waste.toStringAsFixed(2)} م", style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.red700)),
        ],
      ),
    ];
  }
}