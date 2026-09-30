/// بيانات الغرفة الأساسية كما هي مسجلة في تبويب "الغرف".
///
/// ملاحظة مهمة: هذا الكيان قابل للتعديل بحرية، لكن تعديله لاحقًا
/// لا يجب أن يغيّر أي Snapshot محفوظ مسبقًا داخل [DailyEntry].
class Room {
  final String id;
  final String name;
  final int pieceCount;
  final int glassPieceCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Room({
    required this.id,
    required this.name,
    required this.pieceCount,
    required this.glassPieceCount,
    required this.createdAt,
    required this.updatedAt,
  });

  Room copyWith({
    String? name,
    int? pieceCount,
    int? glassPieceCount,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      pieceCount: pieceCount ?? this.pieceCount,
      glassPieceCount: glassPieceCount ?? this.glassPieceCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'piece_count': pieceCount,
      'glass_piece_count': glassPieceCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Room.fromMap(Map<String, Object?> map) {
    return Room(
      id: map['id'] as String,
      name: map['name'] as String,
      pieceCount: map['piece_count'] as int,
      glassPieceCount: map['glass_piece_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
