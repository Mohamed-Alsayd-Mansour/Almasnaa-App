import '../utils/deficiency_calculator.dart';
import 'enums.dart';

/// تمثل وحدة إنتاج مستقلة (غرفة واحدة) داخل يومية معينة.
///
/// يُسمح بوجود أكثر من [DailyEntry] لنفس [roomId] داخل نفس اليومية،
/// فكل إدخال هو وحدة إنتاج مستقلة تمامًا (انظر القاعدة رقم 5 في المواصفات).
///
/// نحتفظ بنسختين من النواقص:
/// - [originalDeficiencies]: كما سُجّلت وقت الإدخال في اليومية (لا تتغير أبدًا).
/// - [currentDeficiencies]: الحالة الحالية القابلة للتعديل من تبويب السجل.
class DailyEntry {
  final String id;
  final String dailySessionId;

  /// قد تكون null إذا حُذفت الغرفة الأساسية لاحقًا؛ الـ Snapshot يبقى قائمًا.
  final String? roomId;
  final String roomNameSnapshot;
  final int pieceCountSnapshot;

  final String numbering;
  final String carpenter; // النجار
  final String service; // الخدمة
  final String installer; // الرصيص
  final String supervisor; // المشرف
  final String repairer; // الرميم

  final String originalDeficiencies;
  final String currentDeficiencies;
  final int originalMissingPiecesCount;
  final int currentMissingPiecesCount;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastDeficiencyUpdateAt;

  const DailyEntry({
    required this.id,
    required this.dailySessionId,
    required this.roomId,
    required this.roomNameSnapshot,
    required this.pieceCountSnapshot,
    required this.numbering,
    required this.carpenter,
    required this.service,
    required this.installer,
    required this.supervisor,
    required this.repairer,
    required this.originalDeficiencies,
    required this.currentDeficiencies,
    required this.originalMissingPiecesCount,
    required this.currentMissingPiecesCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastDeficiencyUpdateAt,
  });

  /// الحالة مشتقة دائمًا من قيمة النواقص الحالية، وليست حقلًا منفصلًا.
  RoomEntryStatus get status => currentDeficiencies.trim().isEmpty
      ? RoomEntryStatus.completed
      : RoomEntryStatus.pending;

  bool get wasEverModified => lastDeficiencyUpdateAt != null;

  /// اسم الغرفة كما يُعرض في الجداول: "أطفال جودي (25)".
  String get displayName => '$roomNameSnapshot ($pieceCountSnapshot)';

  /// ينشئ نسخة جديدة محدَّثة بعد تعديل نص النواقص الحالي، مع إعادة
  /// حساب العدد تلقائيًا. هذا هو المسار الوحيد المسموح لتغيير النواقص.
  DailyEntry withUpdatedCurrentDeficiencies(String newText) {
    final trimmed = newText.trim();
    return DailyEntry(
      id: id,
      dailySessionId: dailySessionId,
      roomId: roomId,
      roomNameSnapshot: roomNameSnapshot,
      pieceCountSnapshot: pieceCountSnapshot,
      numbering: numbering,
      carpenter: carpenter,
      service: service,
      installer: installer,
      supervisor: supervisor,
      repairer: repairer,
      originalDeficiencies: originalDeficiencies,
      currentDeficiencies: trimmed,
      originalMissingPiecesCount: originalMissingPiecesCount,
      currentMissingPiecesCount: calculateMissingPiecesCount(trimmed),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastDeficiencyUpdateAt: DateTime.now(),
    );
  }

  DailyEntry copyWithFields({
    String? numbering,
    String? carpenter,
    String? service,
    String? installer,
    String? supervisor,
    String? repairer,
  }) {
    return DailyEntry(
      id: id,
      dailySessionId: dailySessionId,
      roomId: roomId,
      roomNameSnapshot: roomNameSnapshot,
      pieceCountSnapshot: pieceCountSnapshot,
      numbering: numbering ?? this.numbering,
      carpenter: carpenter ?? this.carpenter,
      service: service ?? this.service,
      installer: installer ?? this.installer,
      supervisor: supervisor ?? this.supervisor,
      repairer: repairer ?? this.repairer,
      originalDeficiencies: originalDeficiencies,
      currentDeficiencies: currentDeficiencies,
      originalMissingPiecesCount: originalMissingPiecesCount,
      currentMissingPiecesCount: currentMissingPiecesCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastDeficiencyUpdateAt: lastDeficiencyUpdateAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'daily_session_id': dailySessionId,
      'room_id': roomId,
      'room_name_snapshot': roomNameSnapshot,
      'piece_count_snapshot': pieceCountSnapshot,
      'numbering': numbering,
      'carpenter': carpenter,
      'service': service,
      'installer': installer,
      'supervisor': supervisor,
      'repairer': repairer,
      'original_deficiencies': originalDeficiencies,
      'current_deficiencies': currentDeficiencies,
      'original_missing_count': originalMissingPiecesCount,
      'current_missing_count': currentMissingPiecesCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_deficiency_update_at': lastDeficiencyUpdateAt?.toIso8601String(),
    };
  }

  factory DailyEntry.fromMap(Map<String, Object?> map) {
    return DailyEntry(
      id: map['id'] as String,
      dailySessionId: map['daily_session_id'] as String,
      roomId: map['room_id'] as String?,
      roomNameSnapshot: map['room_name_snapshot'] as String,
      pieceCountSnapshot: map['piece_count_snapshot'] as int,
      numbering: map['numbering'] as String? ?? '',
      carpenter: map['carpenter'] as String? ?? '',
      service: map['service'] as String? ?? '',
      installer: map['installer'] as String? ?? '',
      supervisor: map['supervisor'] as String? ?? '',
      repairer: map['repairer'] as String? ?? '',
      originalDeficiencies: map['original_deficiencies'] as String? ?? '',
      currentDeficiencies: map['current_deficiencies'] as String? ?? '',
      originalMissingPiecesCount: map['original_missing_count'] as int? ?? 0,
      currentMissingPiecesCount: map['current_missing_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastDeficiencyUpdateAt: map['last_deficiency_update_at'] == null
          ? null
          : DateTime.parse(map['last_deficiency_update_at'] as String),
    );
  }
}

/// نتيجة بحث مركّبة تجمع بيانات الإدخال مع اليومية التي ينتمي إليها،
/// مفيدة لعرض تبويب السجل دون الحاجة لعدة استعلامات في الواجهة.
class RecordRow {
  final DailyEntry entry;
  final String dayName;
  final DateTime date;
  final DailySessionStatus sessionStatus;

  const RecordRow({
    required this.entry,
    required this.dayName,
    required this.date,
    required this.sessionStatus,
  });
}
