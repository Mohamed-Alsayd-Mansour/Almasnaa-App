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
///
/// وسم "مواصفات" ([hasSpecifications]): يمثل نسخة/حالة خاصة من الغرفة
/// لها مواصفات وتعديلات شكلية خاصة بها ([specificationsText])، وعدد قطع
/// مستقل تمامًا ([specialPieceCount]) عن العدد القياسي المحفوظ للغرفة
/// الأساسية ([pieceCountSnapshot]). تعديل [specialPieceCount] لا يغيّر
/// [pieceCountSnapshot] بأي شكل، والعكس صحيح — وهذا الاستقلال التام
/// مطلوب بشكل صريح في المواصفات ويجب عدم كسره في أي تعديل مستقبلي.
class DailyEntry {
  final String id;
  final String dailySessionId;

  /// قد تكون null إذا حُذفت الغرفة الأساسية لاحقًا؛ الـ Snapshot يبقى قائمًا.
  final String? roomId;
  final String roomNameSnapshot;

  /// العدد القياسي للغرفة العادية كما كان محفوظًا وقت الإضافة إلى
  /// اليومية. لا يتأثر أبدًا بتفعيل وسم "مواصفات" أو بتعديل
  /// [specialPieceCount].
  final int pieceCountSnapshot;

  /// قطع القواطيع + الزجاج + الرخام للغرفة وقت الإضافة (null في السجلات
  /// القديمة قبل إضافة الحقل، وتُستكمل من بيانات الغرفة عند القراءة).
  /// تُستخدم فقط لعرض العدد الكلي في حقل «الغرفة (القطع)»، ولا تؤثر على
  /// [pieceCountSnapshot] ولا [effectivePieceCount].
  final int? extraPieceCountSnapshot;

  /// غرفة خارجية (غير موجودة في قاعدة الغرف): اسمها وعدد قطعها يُدخلان
  /// يدويًا، ولها [merchantName] بدل أسماء النجار والخدمة وغيرهم.
  final bool isExternal;

  /// اسم التاجر (للغرف الخارجية فقط).
  final String merchantName;

  final String numbering;
  final String carpenter; // النجار
  final String service; // الخدمة
  final String installer; // الرصيص
  final String supervisor; // المشرف
  final String repairer; // الرميم

  /// مكان اللف.
  final String wrapLocation;

  /// وسم "مواصفات": يشير إلى أن هذا الإدخال هو نسخة/حالة خاصة من
  /// الغرفة لها مواصفات وعدد قطع مستقلين.
  final bool hasSpecifications;

  /// المواصفات والتعديلات الشكلية الخاصة بغرفة المواصفات. لا معنى لها
  /// إلا عندما يكون [hasSpecifications] مفعّلًا.
  final String specificationsText;

  /// عدد قطع غرفة المواصفات، مستقل تمامًا عن [pieceCountSnapshot].
  /// لا معنى له إلا عندما يكون [hasSpecifications] مفعّلًا.
  final int specialPieceCount;

  /// المشكلة: سبب القطع الناقصة (نص حر يُسجَّل بعد النواقص مباشرة).
  final String problem;

  /// وسم "جزء من غرفة": يعني أن المسجَّل جزء أو أكثر من الغرفة وليس الغرفة
  /// كاملة. عند تفعيله يُكتب اسم الجزء قبل اسم الغرفة داخل
  /// [roomNameSnapshot]، ويُستخدم [partialPieceCount] كعدد قطع موجودة.
  final bool isPartial;

  /// اسم الجزء أو الأجزاء (مثال: "2سرير وكمود"). لا معنى له إلا عند [isPartial].
  final String partName;

  /// عدد القطع الموجودة فعليًا من الجزء/الأجزاء المسجّلة.
  final int partialPieceCount;

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
    this.extraPieceCountSnapshot,
    this.isExternal = false,
    this.merchantName = '',
    required this.numbering,
    required this.carpenter,
    required this.service,
    required this.installer,
    required this.supervisor,
    required this.repairer,
    required this.wrapLocation,
    required this.hasSpecifications,
    required this.specificationsText,
    required this.specialPieceCount,
    this.problem = '',
    this.isPartial = false,
    this.partName = '',
    this.partialPieceCount = 0,
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

  /// عدد القطع المستخدم فعليًا في اليومية والسجل والطباعة: العدد الخاص
  /// بغرفة المواصفات عند تفعيل الوسم، وإلا العدد القياسي للغرفة العادية.
  int get effectivePieceCount => isPartial
      ? partialPieceCount
      : (hasSpecifications ? specialPieceCount : pieceCountSnapshot);

  /// اسم الغرفة الأساسي دون اسم الجزء المكتوب قبله (إن وُجد).
  String get baseRoomName {
    if (isPartial && partName.trim().isNotEmpty) {
      final prefix = '${partName.trim()} ';
      if (roomNameSnapshot.startsWith(prefix)) {
        return roomNameSnapshot.substring(prefix.length);
      }
    }
    return roomNameSnapshot;
  }

  /// العدد المعروض في حقل «الغرفة (القطع)»: العدد الكلي (خشب + قواطيع +
  /// زجاج + رخام) للغرفة العادية، أما المواصفات والجزء فيبقى عددهما
  /// المستقل كما هو.
  int get displayPieceCount => (isPartial || hasSpecifications)
      ? effectivePieceCount
      : pieceCountSnapshot + (extraPieceCountSnapshot ?? 0);

  /// اسم الغرفة كما يُعرض في الجداول: "أطفال جودي (25)"، أو
  /// "أطفال جودي - مواصفات (7)" عند تفعيل وسم المواصفات.
  String get displayName {
    final tag = '${isExternal ? ' - خارجية' : ''}'
        '${hasSpecifications ? ' - مواصفات' : ''}';
    return '$roomNameSnapshot$tag ($displayPieceCount)';
  }

  /// ينشئ نسخة جديدة محدَّثة بعد تعديل نص النواقص الحالي، مع إعادة
  /// حساب العدد تلقائيًا. هذا هو المسار الوحيد المسموح لتغيير النواقص
  /// من الجداول (أما التعديل الشامل فيستخدم [copyWith]).
  DailyEntry withUpdatedCurrentDeficiencies(String newText) {
    return copyWith(
      currentDeficiencies: newText,
      markDeficiencyUpdated: true,
    );
  }

  /// نسخة جديدة بعد تعديل نص المشكلة فقط.
  DailyEntry withUpdatedProblem(String newText) {
    return copyWith(problem: newText);
  }

  /// تعديل الحقول التشغيلية (بدون النواقص).
  DailyEntry copyWithFields({
    String? roomNameSnapshot,
    int? pieceCountSnapshot,
    String? merchantName,
    String? numbering,
    String? carpenter,
    String? service,
    String? installer,
    String? supervisor,
    String? repairer,
    String? wrapLocation,
    bool? hasSpecifications,
    String? specificationsText,
    int? specialPieceCount,
    bool? isPartial,
    String? partName,
    int? partialPieceCount,
  }) {
    return copyWith(
      roomNameSnapshot: roomNameSnapshot,
      pieceCountSnapshot: pieceCountSnapshot,
      merchantName: merchantName,
      numbering: numbering,
      carpenter: carpenter,
      service: service,
      installer: installer,
      supervisor: supervisor,
      repairer: repairer,
      wrapLocation: wrapLocation,
      hasSpecifications: hasSpecifications,
      specificationsText: specificationsText,
      specialPieceCount: specialPieceCount,
      isPartial: isPartial,
      partName: partName,
      partialPieceCount: partialPieceCount,
    );
  }

  /// نسخة شاملة: أي حقل لا يُمرَّر يبقى كما هو. عند تمرير نص النواقص
  /// (الأصلي أو الحالي) يُعاد حساب عدد القطع الناقصة المقابل تلقائيًا.
  /// [markDeficiencyUpdated] يسجّل وقت آخر تعديل للنواقص.
  DailyEntry copyWith({
    String? roomNameSnapshot,
    int? pieceCountSnapshot,
    int? extraPieceCountSnapshot,
    String? merchantName,
    String? numbering,
    String? carpenter,
    String? service,
    String? installer,
    String? supervisor,
    String? repairer,
    String? wrapLocation,
    bool? hasSpecifications,
    String? specificationsText,
    int? specialPieceCount,
    String? problem,
    bool? isPartial,
    String? partName,
    int? partialPieceCount,
    String? originalDeficiencies,
    String? currentDeficiencies,
    bool markDeficiencyUpdated = false,
  }) {
    final now = DateTime.now();
    final newOriginal = originalDeficiencies?.trim();
    final newCurrent = currentDeficiencies?.trim();
    return DailyEntry(
      id: id,
      dailySessionId: dailySessionId,
      roomId: roomId,
      roomNameSnapshot: roomNameSnapshot ?? this.roomNameSnapshot,
      pieceCountSnapshot: pieceCountSnapshot ?? this.pieceCountSnapshot,
      extraPieceCountSnapshot:
          extraPieceCountSnapshot ?? this.extraPieceCountSnapshot,
      isExternal: isExternal,
      merchantName: merchantName ?? this.merchantName,
      numbering: numbering ?? this.numbering,
      carpenter: carpenter ?? this.carpenter,
      service: service ?? this.service,
      installer: installer ?? this.installer,
      supervisor: supervisor ?? this.supervisor,
      repairer: repairer ?? this.repairer,
      wrapLocation: wrapLocation ?? this.wrapLocation,
      hasSpecifications: hasSpecifications ?? this.hasSpecifications,
      specificationsText: specificationsText ?? this.specificationsText,
      specialPieceCount: specialPieceCount ?? this.specialPieceCount,
      problem: problem ?? this.problem,
      isPartial: isPartial ?? this.isPartial,
      partName: partName ?? this.partName,
      partialPieceCount: partialPieceCount ?? this.partialPieceCount,
      originalDeficiencies: newOriginal ?? this.originalDeficiencies,
      currentDeficiencies: newCurrent ?? this.currentDeficiencies,
      originalMissingPiecesCount: newOriginal == null
          ? originalMissingPiecesCount
          : calculateMissingPiecesCount(newOriginal),
      currentMissingPiecesCount: newCurrent == null
          ? currentMissingPiecesCount
          : calculateMissingPiecesCount(newCurrent),
      createdAt: createdAt,
      updatedAt: now,
      lastDeficiencyUpdateAt:
          markDeficiencyUpdated ? now : lastDeficiencyUpdateAt,
    );
  }

  /// نسخة بنفس البيانات مع ضبط القطع الإضافية فقط (دون تغيير وقت التعديل).
  DailyEntry withExtraPieceCount(int extra) => DailyEntry(
        id: id,
        dailySessionId: dailySessionId,
        roomId: roomId,
        roomNameSnapshot: roomNameSnapshot,
        pieceCountSnapshot: pieceCountSnapshot,
        extraPieceCountSnapshot: extra,
        isExternal: isExternal,
        merchantName: merchantName,
        numbering: numbering,
        carpenter: carpenter,
        service: service,
        installer: installer,
        supervisor: supervisor,
        repairer: repairer,
        wrapLocation: wrapLocation,
        hasSpecifications: hasSpecifications,
        specificationsText: specificationsText,
        specialPieceCount: specialPieceCount,
        problem: problem,
        isPartial: isPartial,
        partName: partName,
        partialPieceCount: partialPieceCount,
        originalDeficiencies: originalDeficiencies,
        currentDeficiencies: currentDeficiencies,
        originalMissingPiecesCount: originalMissingPiecesCount,
        currentMissingPiecesCount: currentMissingPiecesCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastDeficiencyUpdateAt: lastDeficiencyUpdateAt,
      );

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'daily_session_id': dailySessionId,
      'room_id': roomId,
      'room_name_snapshot': roomNameSnapshot,
      'piece_count_snapshot': pieceCountSnapshot,
      'extra_piece_count_snapshot': extraPieceCountSnapshot,
      'is_external': isExternal,
      'merchant_name': merchantName,
      'numbering': numbering,
      'carpenter': carpenter,
      'service': service,
      'installer': installer,
      'supervisor': supervisor,
      'repairer': repairer,
      'wrap_location': wrapLocation,
      'has_specifications': hasSpecifications,
      'specifications_text': specificationsText,
      'special_piece_count': specialPieceCount,
      'problem': problem,
      'is_partial': isPartial,
      'part_name': partName,
      'partial_piece_count': partialPieceCount,
      'original_deficiencies': originalDeficiencies,
      'current_deficiencies': currentDeficiencies,
      'original_missing_count': originalMissingPiecesCount,
      'current_missing_count': currentMissingPiecesCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_deficiency_update_at': lastDeficiencyUpdateAt?.toIso8601String(),
    };
  }

  /// آمن تمامًا مع السجلات القديمة التي أُنشئت قبل إضافة "مكان اللف"
  /// و"مواصفات": كل حقل جديد له قيمة افتراضية محايدة عند غيابه من
  /// البيانات المخزّنة، فلا تُفقد أي بيانات قديمة ولا يتعطل أي سجل.
  factory DailyEntry.fromMap(Map<String, Object?> map) {
    return DailyEntry(
      id: map['id'] as String,
      dailySessionId: map['daily_session_id'] as String,
      roomId: map['room_id'] as String?,
      roomNameSnapshot: map['room_name_snapshot'] as String,
      pieceCountSnapshot: map['piece_count_snapshot'] as int,
      extraPieceCountSnapshot: map['extra_piece_count_snapshot'] as int?,
      isExternal: map['is_external'] as bool? ?? false,
      merchantName: map['merchant_name'] as String? ?? '',
      numbering: map['numbering'] as String? ?? '',
      carpenter: map['carpenter'] as String? ?? '',
      service: map['service'] as String? ?? '',
      installer: map['installer'] as String? ?? '',
      supervisor: map['supervisor'] as String? ?? '',
      repairer: map['repairer'] as String? ?? '',
      wrapLocation: map['wrap_location'] as String? ?? '',
      hasSpecifications: map['has_specifications'] as bool? ?? false,
      specificationsText: map['specifications_text'] as String? ?? '',
      specialPieceCount: map['special_piece_count'] as int? ?? 0,
      problem: map['problem'] as String? ?? '',
      isPartial: map['is_partial'] as bool? ?? false,
      partName: map['part_name'] as String? ?? '',
      partialPieceCount: map['partial_piece_count'] as int? ?? 0,
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
