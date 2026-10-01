import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/daily_entry.dart';
import '../models/daily_session.dart';
import '../utils/date_formatter.dart';

/// يبني نسخة طباعة يومية العمل ويعرض حوار الطباعة/الحفظ كـ PDF الخاص
/// بالنظام. الأعمدة والترتيب ثابتان تمامًا وفق المواصفات:
/// اسم الغرفة | القطع | ترقيمها | الخدمة | النواقص | المواصفات
/// ولا تتم إضافة أي عمود آخر غير هذه الستة.
class DailyPrintService {
  DailyPrintService._();

  static Future<void> printSession({
    required DailySession session,
    required List<DailyEntry> entries,
  }) async {
    // نستخدم خط Cairo نفسه المستخدم في واجهة التطبيق، لضمان دعم كامل
    // للعربية واتجاه RTL في نسخة الطباعة.
    final regularFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    const headers = ['اسم الغرفة', 'القطع', 'ترقيمها', 'الخدمة', 'النواقص', 'المواصفات'];

    final rows = entries.map((e) {
      final roomName = e.hasSpecifications
          ? '${e.roomNameSnapshot} - مواصفات'
          : e.roomNameSnapshot;
      final specifications = e.hasSpecifications ? e.specificationsText : '';
      return [
        roomName,
        '${e.effectivePieceCount}',
        e.numbering,
        e.service,
        e.currentDeficiencies,
        specifications,
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('يومية ${session.dayName} - ${AppDateFormatter.date(session.date)}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              // ترتيب الأعمدة هنا منطقي (اسم الغرفة أولًا)؛ tableDirection
              // هو ما يعكس عرضها بصريًا بحيث يبدأ "اسم الغرفة" من أقصى
              // اليمين، وهو الترتيب الصحيح للقراءة بالعربية.
              tableDirection: pw.TextDirection.rtl,
              headerDirection: pw.TextDirection.rtl,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xffe0e4e5)),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              cellHeight: 26,
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xff9aa5a7), width: 0.6),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'يومية-${AppDateFormatter.date(session.date)}',
    );
  }
}
