import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';

import '../models/daily_entry.dart';
import '../models/enums.dart';
import '../utils/date_formatter.dart';

/// سياق صف واحد عند التصدير: الإدخال نفسه، مع بيانات اليومية المرتبطة
/// به عند توفرها (اليوم/التاريخ/حالة اليومية تُستخدم فقط من تبويب
/// السجل، حيث قد تتعدد الأيام في نفس التصدير).
class ExportRowContext {
  final DailyEntry entry;
  final String? dayName;
  final DateTime? date;
  final DailySessionStatus? sessionStatus;

  const ExportRowContext({
    required this.entry,
    this.dayName,
    this.date,
    this.sessionStatus,
  });
}

/// حقل واحد قابل للاختيار عند التصدير إلى Excel: له عنوان عمود، ودالة
/// تستخرج قيمته النصية من صف معيّن.
class ExcelExportField {
  final String key;
  final String label;
  final String Function(ExportRowContext row) valueOf;

  const ExcelExportField({
    required this.key,
    required this.label,
    required this.valueOf,
  });
}

/// يبني ملف Excel (.xlsx) من قائمة حقول اختارها المستخدم وقائمة صفوف،
/// بورقة واحدة باتجاه RTL مطابق لطبيعة البيانات العربية.
class ExcelExportService {
  ExcelExportService._();

  /// الحقول المتاحة من بيانات الإدخال نفسه؛ تظهر في كل من اليومية
  /// والسجل.
  static final List<ExcelExportField> entryFields = [
    ExcelExportField(
      key: 'room_name',
      label: 'اسم الغرفة',
      valueOf: (r) => r.entry.roomNameSnapshot,
    ),
    ExcelExportField(
      key: 'has_specifications',
      label: 'وسم مواصفات',
      valueOf: (r) => r.entry.hasSpecifications ? 'نعم' : 'لا',
    ),
    ExcelExportField(
      key: 'piece_count',
      label: 'عدد القطع',
      valueOf: (r) => '${r.entry.effectivePieceCount}',
    ),
    ExcelExportField(
      key: 'standard_piece_count',
      label: 'عدد القطع القياسي للغرفة',
      valueOf: (r) => '${r.entry.pieceCountSnapshot}',
    ),
    ExcelExportField(
      key: 'specifications_piece_count',
      label: 'عدد قطع المواصفات',
      valueOf: (r) =>
          r.entry.hasSpecifications ? '${r.entry.specialPieceCount}' : '',
    ),
    ExcelExportField(
      key: 'merchant',
      label: 'اسم التاجر',
      valueOf: (r) => r.entry.merchantName,
    ),
    ExcelExportField(
      key: 'is_external',
      label: 'غرفة خارجية',
      valueOf: (r) => r.entry.isExternal ? 'نعم' : 'لا',
    ),
    ExcelExportField(
      key: 'numbering',
      label: 'الترقيم',
      valueOf: (r) => r.entry.numbering,
    ),
    ExcelExportField(
      key: 'carpenter',
      label: 'النجار',
      valueOf: (r) => r.entry.carpenter,
    ),
    ExcelExportField(
      key: 'service',
      label: 'الخدمة',
      valueOf: (r) => r.entry.service,
    ),
    ExcelExportField(
      key: 'installer',
      label: 'الرصيص',
      valueOf: (r) => r.entry.installer,
    ),
    ExcelExportField(
      key: 'supervisor',
      label: 'المشرف',
      valueOf: (r) => r.entry.supervisor,
    ),
    ExcelExportField(
      key: 'repairer',
      label: 'الرميم',
      valueOf: (r) => r.entry.repairer,
    ),
    ExcelExportField(
      key: 'wrap_location',
      label: 'مكان اللف',
      valueOf: (r) => r.entry.wrapLocation,
    ),
    ExcelExportField(
      key: 'specifications_text',
      label: 'نص المواصفات',
      valueOf: (r) =>
          r.entry.hasSpecifications ? r.entry.specificationsText : '',
    ),
    ExcelExportField(
      key: 'deficiencies',
      label: 'النواقص',
      valueOf: (r) => r.entry.currentDeficiencies,
    ),
    ExcelExportField(
      key: 'missing_count',
      label: 'عدد الناقص',
      valueOf: (r) => '${r.entry.currentMissingPiecesCount}',
    ),
    ExcelExportField(
      key: 'status',
      label: 'الحالة',
      valueOf: (r) => r.entry.status.label,
    ),
  ];

  /// حقول إضافية متاحة فقط من تبويب السجل، حيث قد يضم التصدير إدخالات
  /// من أكثر من يومية/يوم.
  static final List<ExcelExportField> recordOnlyFields = [
    ExcelExportField(
      key: 'day_name',
      label: 'اليوم',
      valueOf: (r) => r.dayName ?? '',
    ),
    ExcelExportField(
      key: 'date',
      label: 'التاريخ',
      valueOf: (r) => r.date == null ? '' : AppDateFormatter.date(r.date!),
    ),
    ExcelExportField(
      key: 'session_status',
      label: 'حالة اليومية',
      valueOf: (r) => r.sessionStatus?.label ?? '',
    ),
  ];

  static Uint8List buildBytes({
    required List<ExcelExportField> fields,
    required List<ExportRowContext> rows,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.isRTL = true;

    sheet.appendRow(fields.map((f) => TextCellValue(f.label)).toList());
    for (final row in rows) {
      sheet.appendRow(
        fields.map((f) => TextCellValue(f.valueOf(row))).toList(),
      );
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('تعذر إنشاء ملف Excel.');
    }
    return Uint8List.fromList(bytes);
  }
}
