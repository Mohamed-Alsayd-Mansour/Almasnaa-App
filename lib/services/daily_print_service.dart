import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/daily_entry.dart';

/// يبني نسخة طباعة بتنسيق RTL منظّم ويعرض حوار الطباعة/الحفظ كـ PDF
/// الخاص بالنظام. الأعمدة والترتيب ثابتان تمامًا وفق المواصفات:
/// اسم الغرفة | القطع | ترقيمها | الخدمة | النواقص | المواصفات | وصف الأوردر
/// ولا تتم إضافة أي عمود آخر غير هذه السبعة، سواء لطباعة اليومية أو
/// لطباعة السجل.
class DailyPrintService {
  DailyPrintService._();

  static const _headers = [
    'اسم الغرفة',
    'القطع',
    'ترقيمها',
    'الخدمة',
    'النواقص',
    'المواصفات',
    'وصف الأوردر',
  ];

  /// نِسَب عرض الأعمدة بترتيبها المنطقي (قبل انعكاس tableDirection).
  /// محدّدة صراحةً بدل الاعتماد على العرض التلقائي (IntrinsicColumnWidth)
  /// الذي كان يجعل أعمدة الأرقام القصيرة أضيق من عناوينها فيتكسر النص.
  static final _columnWidths = <int, pw.TableColumnWidth>{
    0: const pw.FlexColumnWidth(2.4), // اسم الغرفة
    1: const pw.FlexColumnWidth(0.8), // القطع
    2: const pw.FlexColumnWidth(1.0), // ترقيمها
    3: const pw.FlexColumnWidth(1.3), // الخدمة
    4: const pw.FlexColumnWidth(1.9), // النواقص
    5: const pw.FlexColumnWidth(1.6), // المواصفات
    6: const pw.FlexColumnWidth(1.6), // وصف الأوردر
  };

  static List<String> _rowOf(DailyEntry e) {
    final roomName = e.isOrder
        ? (e.orderParty.isEmpty ? 'أوردر' : 'أوردر - ${e.orderParty}')
        : (e.hasSpecifications
            ? '${e.roomNameSnapshot} - مواصفات'
            : e.roomNameSnapshot);
    final specifications = e.hasSpecifications ? e.specificationsText : '';
    return [
      roomName,
      '${e.effectivePieceCount}',
      e.numbering,
      e.service,
      e.currentDeficiencies,
      specifications,
      e.orderDescription,
    ];
  }

  /// يطبع قائمة إدخالات بعنوان مخصص (يُستخدم لليومية وللسجل معًا).
  static Future<void> printEntries({
    required String title,
    required List<DailyEntry> entries,
    required String documentName,
  }) async {
    // نستخدم خط Cairo نفسه المستخدم في واجهة التطبيق، لضمان دعم كامل
    // للعربية واتجاه RTL في نسخة الطباعة.
    final regularFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    final rows = entries.map(_rowOf).toList();

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
              pw.Text(title,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.TableHelper.fromTextArray(
              headers: _headers,
              data: rows,
              // ترتيب الأعمدة هنا منطقي (اسم الغرفة أولًا)؛ tableDirection
              // هو ما يعكس عرضها بصريًا بحيث يبدأ "اسم الغرفة" من أقصى
              // اليمين، وهو الترتيب الصحيح للقراءة بالعربية.
              tableDirection: pw.TextDirection.rtl,
              headerDirection: pw.TextDirection.rtl,
              columnWidths: _columnWidths,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xffe0e4e5)),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xff9aa5a7), width: 0.6),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: documentName,
    );
  }
}
