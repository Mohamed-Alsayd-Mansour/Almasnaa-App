import 'package:intl/intl.dart';

import '../models/daily_entry.dart';
import '../models/enums.dart';
import '../utils/date_formatter.dart';
import '../utils/browser_launcher.dart' as browser;

class HtmlPrintRow {
  final DailyEntry entry;
  final String? dayName;
  final DateTime? date;
  final DailySessionStatus? sessionStatus;

  const HtmlPrintRow({
    required this.entry,
    this.dayName,
    this.date,
    this.sessionStatus,
  });
}

class HtmlPrintField {
  final String key;
  final String label;
  final String Function(HtmlPrintRow row) valueOf;

  const HtmlPrintField({
    required this.key,
    required this.label,
    required this.valueOf,
  });
}

class HtmlPrintTemplate {
  final String id;
  final String name;
  final List<String> fieldKeys;
  final bool landscape;

  const HtmlPrintTemplate({
    required this.id,
    required this.name,
    required this.fieldKeys,
    this.landscape = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fieldKeys': fieldKeys,
        'landscape': landscape,
      };

  factory HtmlPrintTemplate.fromJson(Map<String, dynamic> json) {
    return HtmlPrintTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      fieldKeys: (json['fieldKeys'] as List).cast<String>(),
      landscape: json['landscape'] as bool? ?? true,
    );
  }
}

class HtmlPrintService {
  HtmlPrintService._();

  static final List<HtmlPrintField> fields = [
    HtmlPrintField(key: 'room_name', label: 'الغرفة (القطع)', valueOf: (r) => r.entry.displayName),
    HtmlPrintField(key: 'has_specifications', label: 'مواصفات', valueOf: (r) => r.entry.hasSpecifications ? 'نعم' : 'لا'),
    HtmlPrintField(key: 'piece_count', label: 'عدد القطع', valueOf: (r) => '${r.entry.effectivePieceCount}'),
    HtmlPrintField(key: 'standard_piece_count', label: 'العدد القياسي', valueOf: (r) => '${r.entry.pieceCountSnapshot}'),
    HtmlPrintField(key: 'specifications_piece_count', label: 'عدد قطع المواصفات', valueOf: (r) => r.entry.hasSpecifications ? '${r.entry.specialPieceCount}' : ''),
    HtmlPrintField(key: 'numbering', label: 'الترقيم', valueOf: (r) => r.entry.numbering),
    HtmlPrintField(key: 'carpenter', label: 'النجار', valueOf: (r) => r.entry.carpenter),
    HtmlPrintField(key: 'service', label: 'الخدمة', valueOf: (r) => r.entry.service),
    HtmlPrintField(key: 'installer', label: 'الرصيص', valueOf: (r) => r.entry.installer),
    HtmlPrintField(key: 'supervisor', label: 'المشرف', valueOf: (r) => r.entry.supervisor),
    HtmlPrintField(key: 'repairer', label: 'الرميم', valueOf: (r) => r.entry.repairer),
    HtmlPrintField(key: 'wrap_location', label: 'مكان اللف', valueOf: (r) => r.entry.wrapLocation),
    HtmlPrintField(key: 'specifications_text', label: 'نص المواصفات', valueOf: (r) => r.entry.hasSpecifications ? r.entry.specificationsText : ''),
    HtmlPrintField(key: 'deficiencies', label: 'النواقص', valueOf: (r) => r.entry.currentDeficiencies),
    HtmlPrintField(key: 'missing_count', label: 'عدد الناقص', valueOf: (r) => '${r.entry.currentMissingPiecesCount}'),
    HtmlPrintField(key: 'status', label: 'الحالة', valueOf: (r) => r.entry.status.label),
    HtmlPrintField(key: 'day_name', label: 'اليوم', valueOf: (r) => r.dayName ?? ''),
    HtmlPrintField(key: 'date', label: 'التاريخ', valueOf: (r) => r.date == null ? '' : AppDateFormatter.date(r.date!)),
    HtmlPrintField(key: 'session_status', label: 'حالة اليومية', valueOf: (r) => r.sessionStatus?.label ?? ''),
  ];

  static final Map<String, HtmlPrintTemplate> builtInTemplates = {
    'full': HtmlPrintTemplate(
      id: 'full',
      name: 'التقرير الكامل',
      fieldKeys: fields.map((e) => e.key).toList(),
    ),
    'storage': HtmlPrintTemplate(
      id: 'storage',
      name: 'تقرير التخزين',
      fieldKeys: const [
        'day_name',
        'date',
        'room_name',
        'numbering',
        'piece_count',
        'service',
        'wrap_location',
        'deficiencies',
        'missing_count',
        'status',
      ],
    ),
    'factory': HtmlPrintTemplate(
      id: 'factory',
      name: 'تقرير المصنع',
      fieldKeys: const [
        'day_name',
        'date',
        'room_name',
        'numbering',
        'carpenter',
        'service',
        'installer',
        'supervisor',
        'repairer',
        'wrap_location',
        'specifications_text',
        'deficiencies',
        'missing_count',
        'status',
      ],
    ),
  };

  static HtmlPrintField fieldByKey(String key) =>
      fields.firstWhere((field) => field.key == key);

  static String buildHtml({
    required String title,
    required List<HtmlPrintRow> rows,
    required List<String> fieldKeys,
    bool landscape = true,
  }) {
    final selected = fieldKeys.map(fieldByKey).toList();
    final generatedAt = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
    final safeTitle = _escape(title);

    final header = selected.map((f) => '<th>${_escape(f.label)}</th>').join();
    final body = StringBuffer();
    for (var i = 0; i < rows.length; i++) {
      body.write('<tr><td class="index">${i + 1}</td>');
      for (final field in selected) {
        body.write('<td>${_escape(field.valueOf(rows[i]))}</td>');
      }
      body.write('</tr>');
    }

    return '''<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$safeTitle</title>
<style>
@page { size: A4 ${landscape ? 'landscape' : 'portrait'}; margin: 10mm; }
* { box-sizing: border-box; }
body { margin: 0; font-family: Tahoma, Arial, sans-serif; color: #111; direction: rtl; background: #fff; }
.toolbar { display:flex; gap:8px; justify-content:flex-start; margin-bottom:16px; }
button { border:0; border-radius:6px; padding:10px 18px; font-size:15px; cursor:pointer; background:#222; color:#fff; }
.header { text-align:center; margin-bottom:14px; }
h1 { margin:0 0 5px; font-size:23px; }
.meta { color:#555; font-size:12px; }
table { width:100%; border-collapse:collapse; table-layout:auto; font-size:11px; }
thead { display:table-header-group; }
tr { page-break-inside:avoid; }
th, td { border:1px solid #777; padding:6px 5px; text-align:center; vertical-align:middle; overflow-wrap:anywhere; }
th { background:#e9ecef; font-weight:700; }
.index { width:32px; }
.footer { margin-top:12px; font-size:10px; color:#666; text-align:left; }
@media print { .toolbar { display:none; } body { background:#fff; } }
</style>
</head>
<body>
<div class="toolbar">
  <button onclick="window.print()">🖨️ طباعة</button>
  <button onclick="window.close()">إغلاق</button>
</div>
<div class="header">
  <h1>$safeTitle</h1>
  <div class="meta">تم إنشاء التقرير: ${_escape(generatedAt)} — عدد السجلات: ${rows.length}</div>
</div>
<table>
<thead><tr><th>م</th>$header</tr></thead>
<tbody>$body</tbody>
</table>
<div class="footer">نظام المصنع — تقرير HTML قابل للطباعة</div>
</body>
</html>''';

  static Future<void> openHtmlInBrowser({
    required String html,
    required String suggestedFileName,
  }) async {
    await browser.openHtmlInBrowser(
      html: html,
      fileName: suggestedFileName,
    );
  }

  static String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('\n', '<br>');
  }
}
