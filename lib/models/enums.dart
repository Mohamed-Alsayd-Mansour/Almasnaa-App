/// حالة اليومية: نشطة أو مغلقة.
enum DailySessionStatus {
  active,
  closed;

  String get dbValue => name;

  static DailySessionStatus fromDb(String value) =>
      DailySessionStatus.values.firstWhere((e) => e.name == value);

  String get label => switch (this) {
        DailySessionStatus.active => 'نشطة',
        DailySessionStatus.closed => 'مغلقة',
      };
}

/// حالة الغرفة داخل السجل: مشتقة دائمًا من قيمة النواقص الحالية،
/// وليست قيمة مخزّنة يتم التلاعب بها يدويًا.
enum RoomEntryStatus {
  completed,
  pending;

  String get label => switch (this) {
        RoomEntryStatus.completed => 'مكتملة',
        RoomEntryStatus.pending => 'بها نواقص',
      };
}
