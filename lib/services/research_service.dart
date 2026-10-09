import 'package:flutter/painting.dart' show Color;

import '../database/app_database.dart';
import '../models/daily_entry.dart';
import '../models/daily_session.dart';
import '../models/enums.dart';
import '../models/person.dart';
import '../models/room.dart';
import '../utils/date_formatter.dart';

/// كل بيانات التطبيق المحفوظة (نفس محتوى ملف JSON): الغرف واليوميات
/// والإدخالات وقوائم الأسماء.
class ResearchData {
  final List<Room> rooms;
  final List<DailySession> sessions;
  final List<DailyEntry> entries;
  final List<Person> people;

  final Map<String, DailySession> _sessionsById;
  final Map<String, Room> _roomsById;

  ResearchData({
    required this.rooms,
    required this.sessions,
    required this.entries,
    required this.people,
  })  : _sessionsById = {for (final s in sessions) s.id: s},
        _roomsById = {for (final r in rooms) r.id: r};

  DailySession? sessionOf(DailyEntry e) => _sessionsById[e.dailySessionId];
  Room? roomOf(DailyEntry e) => e.roomId == null ? null : _roomsById[e.roomId];

  DateTime dateOf(DailyEntry e) => sessionOf(e)?.date ?? e.createdAt;
  String dayNameOf(DailyEntry e) => sessionOf(e)?.dayName ?? '';

  static Future<ResearchData> load() async {
    final db = AppDatabase.instance;
    final rooms =
        (await db.readList(AppDatabase.roomsKey)).map(Room.fromMap).toList();
    final sessions = (await db.readList(AppDatabase.sessionsKey))
        .map(DailySession.fromMap)
        .toList();
    final entries = (await db.readList(AppDatabase.entriesKey))
        .map(DailyEntry.fromMap)
        .toList();
    final people =
        (await db.readList(AppDatabase.peopleKey)).map(Person.fromMap).toList();
    return ResearchData(
        rooms: rooms, sessions: sessions, entries: entries, people: people);
  }
}

enum ResearchView {
  overview('ملخص عام'),
  rooms('الغرف'),
  sessions('اليوميات'),
  entries('السجلات'),
  grouped('تجميع الإنتاج'),
  deficiencies('النواقص المتكررة'),
  people('الأسماء');

  final String label;
  const ResearchView(this.label);
}

enum ResearchGroup {
  room('الغرفة'),
  carpenter('النجار'),
  service('الخدمة'),
  installer('الرصيص'),
  supervisor('المشرف'),
  repairer('الرميم'),
  wrapLocation('مكان اللف'),
  dayName('اليوم'),
  date('التاريخ');

  final String label;
  const ResearchGroup(this.label);
}

enum ResearchShape {
  regular('عادية'),
  specs('مواصفات'),
  partial('جزء من غرفة');

  final String label;
  const ResearchShape(this.label);
}

class ResearchFilters {
  final String keyword;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final RoomEntryStatus? status;
  final ResearchShape? shape;

  const ResearchFilters({
    this.keyword = '',
    this.dateFrom,
    this.dateTo,
    this.status,
    this.shape,
  });

  ResearchFilters copyWith({
    String? keyword,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearFrom = false,
    bool clearTo = false,
    RoomEntryStatus? status,
    bool clearStatus = false,
    ResearchShape? shape,
    bool clearShape = false,
  }) {
    return ResearchFilters(
      keyword: keyword ?? this.keyword,
      dateFrom: clearFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearTo ? null : (dateTo ?? this.dateTo),
      status: clearStatus ? null : (status ?? this.status),
      shape: clearShape ? null : (shape ?? this.shape),
    );
  }

  bool get isEmpty =>
      keyword.trim().isEmpty &&
      dateFrom == null &&
      dateTo == null &&
      status == null &&
      shape == null;

  /// وصف نصي للفلاتر المطبّقة (للعنوان الفرعي في الطباعة).
  String describe() {
    final parts = <String>[];
    if (keyword.trim().isNotEmpty) parts.add('بحث: ${keyword.trim()}');
    if (dateFrom != null) parts.add('من ${AppDateFormatter.date(dateFrom!)}');
    if (dateTo != null) parts.add('إلى ${AppDateFormatter.date(dateTo!)}');
    if (status != null) parts.add('الحالة: ${status!.label}');
    if (shape != null) parts.add('الشكل: ${shape!.label}');
    return parts.join(' — ');
  }
}

class ResearchColumn {
  final String key;
  final String label;
  final double width;
  final bool numeric;

  const ResearchColumn(this.key, this.label,
      {this.width = 120, this.numeric = false});
}

/// صف نتيجة: نص العرض لكل عمود، وقيمة رقمية اختيارية للترتيب.
class ResearchRow {
  final Map<String, String> text;
  final Map<String, num> sort;
  final Color? tint;

  const ResearchRow({
    required this.text,
    this.sort = const {},
    this.tint,
  });

  String value(String key) => text[key] ?? '';
}

class ResearchStat {
  final String label;
  final String value;
  const ResearchStat(this.label, this.value);
}

class ResearchTable {
  final ResearchView view;
  final List<ResearchColumn> columns;
  final List<ResearchRow> rows;
  final List<ResearchStat> stats;

  const ResearchTable({
    required this.view,
    required this.columns,
    required this.rows,
    required this.stats,
  });
}

class ResearchService {
  ResearchService._();

  static const Color _greenTint = Color(0x332E7D32);
  static const Color _redTint = Color(0x33C62828);

  // ------------------------------------------------------------------
  // الفلترة
  // ------------------------------------------------------------------

  static bool _inDateRange(DateTime d, ResearchFilters f) {
    final day = DateTime(d.year, d.month, d.day);
    if (f.dateFrom != null) {
      final from = DateTime(f.dateFrom!.year, f.dateFrom!.month, f.dateFrom!.day);
      if (day.isBefore(from)) return false;
    }
    if (f.dateTo != null) {
      final to = DateTime(f.dateTo!.year, f.dateTo!.month, f.dateTo!.day);
      if (day.isAfter(to)) return false;
    }
    return true;
  }

  static bool _matchesKeyword(ResearchData data, DailyEntry e, String keyword) {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) return true;
    final fields = <String>[
      e.roomNameSnapshot,
      e.numbering,
      e.carpenter,
      e.service,
      e.installer,
      e.supervisor,
      e.repairer,
      e.wrapLocation,
      e.specificationsText,
      e.partName,
      e.originalDeficiencies,
      e.currentDeficiencies,
      e.problem,
      data.dayNameOf(e),
      '${e.effectivePieceCount}',
    ];
    return fields.any((v) => v.toLowerCase().contains(q));
  }

  /// الإدخالات بعد تطبيق التاريخ والحالة والشكل (والكلمة المفتاحية اختياريًا).
  static List<DailyEntry> filterEntries(
    ResearchData data,
    ResearchFilters f, {
    bool useKeyword = true,
  }) {
    return data.entries.where((e) {
      if (!_inDateRange(data.dateOf(e), f)) return false;
      if (f.status != null && e.status != f.status) return false;
      switch (f.shape) {
        case ResearchShape.regular:
          if (e.hasSpecifications || e.isPartial) return false;
        case ResearchShape.specs:
          if (!e.hasSpecifications) return false;
        case ResearchShape.partial:
          if (!e.isPartial) return false;
        case null:
          break;
      }
      if (useKeyword && !_matchesKeyword(data, e, f.keyword)) return false;
      return true;
    }).toList();
  }

  // ------------------------------------------------------------------
  // أدوات مساعدة
  // ------------------------------------------------------------------

  static String _pct(int part, int whole) =>
      whole == 0 ? '0%' : '${(part * 100 / whole).toStringAsFixed(1)}%';

  static ResearchRow _row(Map<String, String> text,
          {Map<String, num> sort = const {}, Color? tint}) =>
      ResearchRow(text: text, sort: sort, tint: tint);

  static Color _tintOf(RoomEntryStatus s) =>
      s == RoomEntryStatus.completed ? _greenTint : _redTint;

  static int _sumPieces(Iterable<DailyEntry> es) =>
      es.fold<int>(0, (a, e) => a + e.effectivePieceCount);
  static int _sumMissing(Iterable<DailyEntry> es) =>
      es.fold<int>(0, (a, e) => a + e.currentMissingPiecesCount);
  static int _sumOriginalMissing(Iterable<DailyEntry> es) =>
      es.fold<int>(0, (a, e) => a + e.originalMissingPiecesCount);
  static int _completed(Iterable<DailyEntry> es) =>
      es.where((e) => e.status == RoomEntryStatus.completed).length;

  // ------------------------------------------------------------------
  // بناء الجداول
  // ------------------------------------------------------------------

  static ResearchTable build(
    ResearchView view,
    ResearchData data,
    ResearchFilters filters, {
    ResearchGroup group = ResearchGroup.room,
  }) {
    switch (view) {
      case ResearchView.overview:
        return _overview(data);
      case ResearchView.rooms:
        return _rooms(data, filters);
      case ResearchView.sessions:
        return _sessions(data, filters);
      case ResearchView.entries:
        return _entries(data, filters);
      case ResearchView.grouped:
        return _grouped(data, filters, group);
      case ResearchView.deficiencies:
        return _deficiencies(data, filters);
      case ResearchView.people:
        return _people(data, filters);
    }
  }

  static ResearchTable _overview(ResearchData d) {
    final es = d.entries;
    final completed = _completed(es);
    final closed =
        d.sessions.where((s) => s.status == DailySessionStatus.closed).length;
    final active = d.sessions.length - closed;
    final dates = es.map(d.dateOf).toList()..sort();
    int sumRooms(int Function(Room r) f) => d.rooms.fold<int>(0, (a, r) => a + f(r));

    final items = <List<String>>[
      ['الغرف المسجلة', '${d.rooms.length}', 'عدد الغرف في قاعدة الغرف'],
      ['إجمالي قطع الخشب', '${sumRooms((r) => r.pieceCount)}', 'مجموع قطع الخشب لكل الغرف'],
      ['إجمالي قطع القواطيع', '${sumRooms((r) => r.partitionPieceCount)}', ''],
      ['إجمالي قطع الزجاج', '${sumRooms((r) => r.glassPieceCount)}', ''],
      ['إجمالي قطع الرخام', '${sumRooms((r) => r.marblePieceCount)}', ''],
      ['إجمالي القطع الكلي', '${sumRooms((r) => r.totalPieceCount)}', 'خشب + قواطيع + زجاج + رخام'],
      ['إجمالي ورق الطباعة', '${sumRooms((r) => r.printPaperCount)}', 'خشب + قواطيع'],
      ['اليوميات', '${d.sessions.length}', 'مغلقة: $closed — نشطة: $active'],
      [
        'فترة الإنتاج',
        dates.isEmpty ? '-' : '${AppDateFormatter.date(dates.first)}',
        dates.isEmpty ? '' : 'إلى ${AppDateFormatter.date(dates.last)}',
      ],
      [
        'متوسط الغرف في اليومية',
        d.sessions.isEmpty ? '0' : (es.length / d.sessions.length).toStringAsFixed(1),
        '',
      ],
      ['إدخالات الإنتاج', '${es.length}', 'إجمالي الغرف المسجلة في اليوميات'],
      ['المكتملة', '$completed', 'نسبة الاكتمال ${_pct(completed, es.length)}'],
      ['التي بها نواقص', '${es.length - completed}', ''],
      ['القطع الناقصة (الحالية)', '${_sumMissing(es)}', 'الأصلية وقت الإنتاج: ${_sumOriginalMissing(es)}'],
      ['إدخالات بمشكلة مسجلة', '${es.where((e) => e.problem.trim().isNotEmpty).length}', ''],
      ['إدخالات بمواصفات', '${es.where((e) => e.hasSpecifications).length}', ''],
      ['إدخالات جزء من غرفة', '${es.where((e) => e.isPartial).length}', ''],
      [
        'الأسماء المسجلة',
        '${d.people.length}',
        PersonRole.values
            .map((r) => '${r.label}: ${d.people.where((p) => p.role == r).length}')
            .join(' — '),
      ],
    ];

    return ResearchTable(
      view: ResearchView.overview,
      columns: const [
        ResearchColumn('item', 'البند', width: 240),
        ResearchColumn('value', 'القيمة', width: 150, numeric: true),
        ResearchColumn('details', 'تفاصيل', width: 420),
      ],
      rows: [
        for (final i in items)
          _row({'item': i[0], 'value': i[1], 'details': i[2]}),
      ],
      stats: [
        ResearchStat('الغرف', '${d.rooms.length}'),
        ResearchStat('اليوميات', '${d.sessions.length}'),
        ResearchStat('الإدخالات', '${es.length}'),
        ResearchStat('نسبة الاكتمال', _pct(completed, es.length)),
      ],
    );
  }

  static ResearchTable _rooms(ResearchData d, ResearchFilters f) {
    final used = filterEntries(d, f, useKeyword: false);
    final byRoom = <String, List<DailyEntry>>{};
    for (final e in used) {
      if (e.roomId != null) byRoom.putIfAbsent(e.roomId!, () => []).add(e);
    }
    final kw = f.keyword.trim().toLowerCase();
    final rooms = d.rooms
        .where((r) => kw.isEmpty || r.name.toLowerCase().contains(kw))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final rows = <ResearchRow>[];
    for (final r in rooms) {
      final es = byRoom[r.id] ?? const <DailyEntry>[];
      DateTime? last;
      for (final e in es) {
        final dt = d.dateOf(e);
        if (last == null || dt.isAfter(last)) last = dt;
      }
      rows.add(_row({
        'name': r.name,
        'wood': '${r.pieceCount}',
        'partition': '${r.partitionPieceCount}',
        'glass': '${r.glassPieceCount}',
        'marble': '${r.marblePieceCount}',
        'total': '${r.totalPieceCount}',
        'paper': '${r.printPaperCount}',
        'times': '${es.length}',
        'full': '${es.where((e) => !e.isPartial).length}',
        'partial': '${es.where((e) => e.isPartial).length}',
        'last': last == null ? '' : AppDateFormatter.date(last),
        'missing': '${_sumMissing(es)}',
      }, sort: {
        'wood': r.pieceCount,
        'partition': r.partitionPieceCount,
        'glass': r.glassPieceCount,
        'marble': r.marblePieceCount,
        'total': r.totalPieceCount,
        'paper': r.printPaperCount,
        'times': es.length,
        'full': es.where((e) => !e.isPartial).length,
        'partial': es.where((e) => e.isPartial).length,
        'last': last?.millisecondsSinceEpoch ?? 0,
        'missing': _sumMissing(es),
      }));
    }

    return ResearchTable(
      view: ResearchView.rooms,
      columns: const [
        ResearchColumn('name', 'الغرفة', width: 230),
        ResearchColumn('wood', 'قطع الخشب', width: 100, numeric: true),
        ResearchColumn('partition', 'قطع القواطيع', width: 110, numeric: true),
        ResearchColumn('glass', 'قطع الزجاج', width: 100, numeric: true),
        ResearchColumn('marble', 'قطع الرخام', width: 100, numeric: true),
        ResearchColumn('total', 'عدد القطع الكلي', width: 120, numeric: true),
        ResearchColumn('paper', 'عدد ورق الطباعة', width: 130, numeric: true),
        ResearchColumn('times', 'مرات الإنتاج', width: 110, numeric: true),
        ResearchColumn('full', 'كاملة', width: 80, numeric: true),
        ResearchColumn('partial', 'أجزاء', width: 80, numeric: true),
        ResearchColumn('last', 'آخر إنتاج', width: 110),
        ResearchColumn('missing', 'الناقص الحالي', width: 110, numeric: true),
      ],
      rows: rows,
      stats: [
        ResearchStat('عدد الغرف', '${rows.length}'),
        ResearchStat('إجمالي القطع',
            '${rooms.fold<int>(0, (a, r) => a + r.totalPieceCount)}'),
        ResearchStat('إجمالي ورق الطباعة',
            '${rooms.fold<int>(0, (a, r) => a + r.printPaperCount)}'),
      ],
    );
  }

  static ResearchTable _sessions(ResearchData d, ResearchFilters f) {
    final kw = f.keyword.trim().toLowerCase();
    final sessions = d.sessions.where((s) {
      if (!_inDateRange(s.date, f)) return false;
      if (kw.isEmpty) return true;
      return s.dayName.toLowerCase().contains(kw) ||
          AppDateFormatter.date(s.date).contains(kw) ||
          s.status.label.contains(kw);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final rows = <ResearchRow>[];
    for (final s in sessions) {
      final es = d.entries.where((e) => e.dailySessionId == s.id).toList();
      final done = _completed(es);
      rows.add(_row({
        'day': s.dayName,
        'date': AppDateFormatter.date(s.date),
        'start': AppDateFormatter.time(s.startTime),
        'end': AppDateFormatter.endTimeOrPending(s.endTime),
        'status': s.status.label,
        'rooms': '${es.length}',
        'done': '$done',
        'pending': '${es.length - done}',
        'pieces': '${_sumPieces(es)}',
        'missing': '${_sumMissing(es)}',
        'original': '${_sumOriginalMissing(es)}',
      }, sort: {
        'date': s.date.millisecondsSinceEpoch,
        'rooms': es.length,
        'done': done,
        'pending': es.length - done,
        'pieces': _sumPieces(es),
        'missing': _sumMissing(es),
        'original': _sumOriginalMissing(es),
      }));
    }

    return ResearchTable(
      view: ResearchView.sessions,
      columns: const [
        ResearchColumn('day', 'اليوم', width: 100),
        ResearchColumn('date', 'التاريخ', width: 110),
        ResearchColumn('start', 'بدء اليومية', width: 110),
        ResearchColumn('end', 'انتهاء اليومية', width: 120),
        ResearchColumn('status', 'الحالة', width: 90),
        ResearchColumn('rooms', 'عدد الغرف', width: 100, numeric: true),
        ResearchColumn('done', 'مكتملة', width: 90, numeric: true),
        ResearchColumn('pending', 'بها نواقص', width: 100, numeric: true),
        ResearchColumn('pieces', 'مجموع القطع', width: 110, numeric: true),
        ResearchColumn('missing', 'الناقص الحالي', width: 110, numeric: true),
        ResearchColumn('original', 'الناقص الأصلي', width: 110, numeric: true),
      ],
      rows: rows,
      stats: [
        ResearchStat('عدد اليوميات', '${rows.length}'),
        ResearchStat('الغرف المنتجة',
            '${sessions.fold<int>(0, (a, s) => a + d.entries.where((e) => e.dailySessionId == s.id).length)}'),
      ],
    );
  }

  static ResearchTable _entries(ResearchData d, ResearchFilters f) {
    final es = filterEntries(d, f)
      ..sort((a, b) {
        final byDate = d.dateOf(b).compareTo(d.dateOf(a));
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });

    final rows = [
      for (final e in es)
        _row({
          'day': d.dayNameOf(e),
          'date': AppDateFormatter.date(d.dateOf(e)),
          'room': e.displayName,
          'numbering': e.numbering,
          'carpenter': e.carpenter,
          'service': e.service,
          'installer': e.installer,
          'supervisor': e.supervisor,
          'repairer': e.repairer,
          'wrap': e.wrapLocation,
          'pieces': '${e.effectivePieceCount}',
          'standard': '${e.pieceCountSnapshot}',
          'specs': e.hasSpecifications ? e.specificationsText : '',
          'partial': e.isPartial ? e.partName : '',
          'original_def': e.originalDeficiencies,
          'current_def': e.currentDeficiencies,
          'problem': e.problem,
          'original_missing': '${e.originalMissingPiecesCount}',
          'missing': '${e.currentMissingPiecesCount}',
          'status': e.status.label,
          'created': AppDateFormatter.dateTime(e.createdAt),
          'def_updated': e.lastDeficiencyUpdateAt == null
              ? ''
              : AppDateFormatter.dateTime(e.lastDeficiencyUpdateAt!),
        }, sort: {
          'date': d.dateOf(e).millisecondsSinceEpoch,
          'pieces': e.effectivePieceCount,
          'standard': e.pieceCountSnapshot,
          'original_missing': e.originalMissingPiecesCount,
          'missing': e.currentMissingPiecesCount,
          'created': e.createdAt.millisecondsSinceEpoch,
        }, tint: _tintOf(e.status)),
    ];

    return ResearchTable(
      view: ResearchView.entries,
      columns: const [
        ResearchColumn('day', 'اليوم', width: 90),
        ResearchColumn('date', 'التاريخ', width: 105),
        ResearchColumn('room', 'الغرفة (القطع)', width: 250),
        ResearchColumn('numbering', 'الترقيم', width: 90),
        ResearchColumn('carpenter', 'النجار', width: 110),
        ResearchColumn('service', 'الخدمة', width: 110),
        ResearchColumn('installer', 'الرصيص', width: 110),
        ResearchColumn('supervisor', 'المشرف', width: 110),
        ResearchColumn('repairer', 'الرميم', width: 110),
        ResearchColumn('wrap', 'مكان اللف', width: 110),
        ResearchColumn('pieces', 'عدد القطع', width: 95, numeric: true),
        ResearchColumn('standard', 'العدد القياسي', width: 110, numeric: true),
        ResearchColumn('specs', 'المواصفات', width: 170),
        ResearchColumn('partial', 'اسم الجزء', width: 140),
        ResearchColumn('original_def', 'النواقص الأصلية', width: 200),
        ResearchColumn('current_def', 'النواقص الحالية', width: 200),
        ResearchColumn('problem', 'المشكلة', width: 200),
        ResearchColumn('original_missing', 'الناقص الأصلي', width: 110, numeric: true),
        ResearchColumn('missing', 'الناقص الحالي', width: 110, numeric: true),
        ResearchColumn('status', 'الحالة', width: 100),
        ResearchColumn('created', 'وقت التسجيل', width: 170),
        ResearchColumn('def_updated', 'آخر تعديل للنواقص', width: 170),
      ],
      rows: rows,
      stats: _entryStats(es),
    );
  }

  static List<ResearchStat> _entryStats(List<DailyEntry> es) {
    final done = _completed(es);
    return [
      ResearchStat('الإدخالات', '${es.length}'),
      ResearchStat('مكتملة', '$done'),
      ResearchStat('بها نواقص', '${es.length - done}'),
      ResearchStat('نسبة الاكتمال', _pct(done, es.length)),
      ResearchStat('مجموع القطع', '${_sumPieces(es)}'),
      ResearchStat('الناقص الحالي', '${_sumMissing(es)}'),
    ];
  }

  static String _groupKey(ResearchData d, DailyEntry e, ResearchGroup g) {
    String clean(String v) => v.trim().isEmpty ? '(غير محدد)' : v.trim();
    switch (g) {
      case ResearchGroup.room:
        return clean(d.roomOf(e)?.name ?? e.baseRoomName);
      case ResearchGroup.carpenter:
        return clean(e.carpenter);
      case ResearchGroup.service:
        return clean(e.service);
      case ResearchGroup.installer:
        return clean(e.installer);
      case ResearchGroup.supervisor:
        return clean(e.supervisor);
      case ResearchGroup.repairer:
        return clean(e.repairer);
      case ResearchGroup.wrapLocation:
        return clean(e.wrapLocation);
      case ResearchGroup.dayName:
        return clean(d.dayNameOf(e));
      case ResearchGroup.date:
        return AppDateFormatter.date(d.dateOf(e));
    }
  }

  static ResearchTable _grouped(
      ResearchData d, ResearchFilters f, ResearchGroup g) {
    final es = filterEntries(d, f);
    final groups = <String, List<DailyEntry>>{};
    for (final e in es) {
      groups.putIfAbsent(_groupKey(d, e, g), () => []).add(e);
    }
    final keys = groups.keys.toList()..sort();

    final rows = [
      for (final k in keys)
        () {
          final list = groups[k]!;
          final done = _completed(list);
          return _row({
            'group': k,
            'count': '${list.length}',
            'done': '$done',
            'pending': '${list.length - done}',
            'rate': _pct(done, list.length),
            'pieces': '${_sumPieces(list)}',
            'missing': '${_sumMissing(list)}',
            'original': '${_sumOriginalMissing(list)}',
            'problems': '${list.where((e) => e.problem.trim().isNotEmpty).length}',
            'specs': '${list.where((e) => e.hasSpecifications).length}',
            'partial': '${list.where((e) => e.isPartial).length}',
          }, sort: {
            'count': list.length,
            'done': done,
            'pending': list.length - done,
            'rate': list.isEmpty ? 0 : done / list.length,
            'pieces': _sumPieces(list),
            'missing': _sumMissing(list),
            'original': _sumOriginalMissing(list),
            'problems': list.where((e) => e.problem.trim().isNotEmpty).length,
            'specs': list.where((e) => e.hasSpecifications).length,
            'partial': list.where((e) => e.isPartial).length,
          });
        }(),
    ];

    return ResearchTable(
      view: ResearchView.grouped,
      columns: [
        ResearchColumn('group', g.label, width: 230),
        const ResearchColumn('count', 'عدد الإدخالات', width: 120, numeric: true),
        const ResearchColumn('done', 'مكتملة', width: 90, numeric: true),
        const ResearchColumn('pending', 'بها نواقص', width: 100, numeric: true),
        const ResearchColumn('rate', 'نسبة الاكتمال', width: 120, numeric: true),
        const ResearchColumn('pieces', 'مجموع القطع', width: 110, numeric: true),
        const ResearchColumn('missing', 'الناقص الحالي', width: 110, numeric: true),
        const ResearchColumn('original', 'الناقص الأصلي', width: 110, numeric: true),
        const ResearchColumn('problems', 'بمشكلة', width: 90, numeric: true),
        const ResearchColumn('specs', 'مواصفات', width: 90, numeric: true),
        const ResearchColumn('partial', 'أجزاء', width: 80, numeric: true),
      ],
      rows: rows,
      stats: [ResearchStat('عدد المجموعات', '${rows.length}'), ..._entryStats(es)],
    );
  }

  static ResearchTable _deficiencies(ResearchData d, ResearchFilters f) {
    final es = filterEntries(d, f)
        .where((e) => e.currentDeficiencies.trim().isNotEmpty)
        .toList();

    final counts = <String, int>{};
    final rooms = <String, Set<String>>{};
    final last = <String, DateTime>{};
    final problems = <String, Set<String>>{};
    for (final e in es) {
      final seen = <String>{};
      for (final raw in e.currentDeficiencies.split('-')) {
        final item = raw.trim();
        if (item.isEmpty) continue;
        counts[item] = (counts[item] ?? 0) + 1;
        rooms.putIfAbsent(item, () => {}).add(e.baseRoomName);
        final dt = d.dateOf(e);
        if (!last.containsKey(item) || dt.isAfter(last[item]!)) last[item] = dt;
        if (e.problem.trim().isNotEmpty && seen.add(item)) {
          problems.putIfAbsent(item, () => {}).add(e.problem.trim());
        }
      }
    }
    final items = counts.keys.toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : a.compareTo(b);
      });

    final rows = [
      for (final item in items)
        _row({
          'item': item,
          'count': '${counts[item]}',
          'rooms': '${rooms[item]!.length}',
          'last': AppDateFormatter.date(last[item]!),
          'problems': (problems[item] ?? const <String>{}).take(3).join(' | '),
        }, sort: {
          'count': counts[item]!,
          'rooms': rooms[item]!.length,
          'last': last[item]!.millisecondsSinceEpoch,
        }),
    ];

    return ResearchTable(
      view: ResearchView.deficiencies,
      columns: const [
        ResearchColumn('item', 'القطعة الناقصة', width: 260),
        ResearchColumn('count', 'التكرار', width: 90, numeric: true),
        ResearchColumn('rooms', 'عدد الغرف', width: 100, numeric: true),
        ResearchColumn('last', 'آخر ظهور', width: 110),
        ResearchColumn('problems', 'المشاكل المسجلة', width: 360),
      ],
      rows: rows,
      stats: [
        ResearchStat('أنواع النواقص', '${rows.length}'),
        ResearchStat('إدخالات بنواقص', '${es.length}'),
        ResearchStat('إجمالي القطع الناقصة', '${_sumMissing(es)}'),
      ],
    );
  }

  static ResearchTable _people(ResearchData d, ResearchFilters f) {
    final kw = f.keyword.trim().toLowerCase();
    String field(DailyEntry e, PersonRole r) => switch (r) {
          PersonRole.service => e.service,
          PersonRole.carpenter => e.carpenter,
          PersonRole.installer => e.installer,
          PersonRole.supervisor => e.supervisor,
          PersonRole.repairer => e.repairer,
          PersonRole.wrapLocation => e.wrapLocation,
        };

    final people = d.people.where((p) {
      if (kw.isEmpty) return true;
      return p.name.toLowerCase().contains(kw) || p.role.label.contains(kw);
    }).toList()
      ..sort((a, b) {
        final c = a.role.index.compareTo(b.role.index);
        return c != 0 ? c : a.name.compareTo(b.name);
      });

    final rows = <ResearchRow>[];
    for (final p in people) {
      final es = d.entries.where((e) => field(e, p.role).trim() == p.name.trim()).toList();
      final done = _completed(es);
      rows.add(_row({
        'role': p.role.label,
        'name': p.name,
        'count': '${es.length}',
        'done': '$done',
        'pending': '${es.length - done}',
        'missing': '${_sumMissing(es)}',
        'added': AppDateFormatter.date(p.createdAt),
      }, sort: {
        'count': es.length,
        'done': done,
        'pending': es.length - done,
        'missing': _sumMissing(es),
        'added': p.createdAt.millisecondsSinceEpoch,
      }));
    }

    return ResearchTable(
      view: ResearchView.people,
      columns: const [
        ResearchColumn('role', 'الدور', width: 110),
        ResearchColumn('name', 'الاسم', width: 220),
        ResearchColumn('count', 'عدد الإدخالات', width: 120, numeric: true),
        ResearchColumn('done', 'مكتملة', width: 90, numeric: true),
        ResearchColumn('pending', 'بها نواقص', width: 100, numeric: true),
        ResearchColumn('missing', 'الناقص الحالي', width: 110, numeric: true),
        ResearchColumn('added', 'تاريخ الإضافة', width: 120),
      ],
      rows: rows,
      stats: [ResearchStat('عدد الأسماء', '${rows.length}')],
    );
  }
}
