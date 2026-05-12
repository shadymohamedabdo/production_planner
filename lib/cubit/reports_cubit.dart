// logic/reports_cubit/reports_cubit.dart
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

  // ميثود مساعدة لتوليد الخطوط العربية (عشان منكررهاش)
  Future<Map<String, pw.Font>> _loadFonts() async {
    return {
      'regular': await PdfGoogleFonts.notoSansArabicRegular(),
      'bold': await PdfGoogleFonts.notoSansArabicBold(),
    };
  }

  // --- منطق الطباعة (نفس اللي كان في الشاشة بس منظم) ---

  Future<void> printSinglePlan(ProductionPlan plan) async {
    final currentState = state as ReportsLoaded;
    emit(currentState.copyWith(isPrinting: true));

    final fonts = await _loadFonts();
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: fonts['regular'], bold: fonts['bold']),
      build: (context) => _buildPlanPDFContent(plan, fonts['bold']!),
    ));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'plan_${plan.id}.pdf');
    emit(currentState.copyWith(isPrinting: false));
  }

  // دالة بناء محتوى الـ PDF (نفس المنطق القديم بس كـ Helper داخل الكيوبيت)
  List<pw.Widget> _buildPlanPDFContent(ProductionPlan plan, pw.Font boldFont) {
    return [
      pw.Header(level: 0, child: pw.Text("خطة إنتاج - جرام ${plan.grams}", style: pw.TextStyle(font: boldFont))),
      pw.Text("التاريخ: ${plan.date.toString().split(' ')[0]}"),
      pw.Divider(),
      pw.TableHelper.fromTextArray(
        headers: ['العميل', 'العرض (سم)', 'الكمية'],
        data: plan.items.map((i) => [i.customerName, i.width.toString(), i.quantity.toString()]).toList(),
      ),
      pw.SizedBox(height: 20),
      pw.Text("إجمالي العرض: ${plan.totalWidth.toStringAsFixed(2)} م"),
      pw.Text("الهالك: ${plan.waste.toStringAsFixed(2)} م"),
    ];
  }
}