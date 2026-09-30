import 'package:flutter/foundation.dart';

import '../models/daily_entry.dart';
import '../models/daily_session.dart';
import '../models/room.dart';
import '../repositories/daily_entry_repository.dart';
import '../repositories/daily_session_repository.dart';
import 'rooms_provider.dart';

/// يدير حالة تبويب "اليومية": بدء/إنهاء اليومية، وإضافة/تعديل/حذف
/// الغرف المسجّلة فيها أثناء كونها نشطة.
class DailyProvider extends ChangeNotifier {
  final DailySessionRepository _sessionRepository;
  final DailyEntryRepository _entryRepository;

  DailyProvider({
    DailySessionRepository? sessionRepository,
    DailyEntryRepository? entryRepository,
  })  : _sessionRepository = sessionRepository ?? DailySessionRepository(),
        _entryRepository = entryRepository ?? DailyEntryRepository();

  LoadStatus status = LoadStatus.initial;
  String? errorMessage;

  DailySession? activeSession;
  List<DailyEntry> entries = [];

  bool get hasActiveSession => activeSession != null;

  Future<void> load() async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      activeSession = await _sessionRepository.getActiveSession();
      if (activeSession != null) {
        entries = await _entryRepository.getEntriesForSession(activeSession!.id);
      } else {
        entries = [];
      }
      status = LoadStatus.loaded;
    } catch (e) {
      errorMessage = 'تعذر تحميل اليومية: $e';
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<String?> startSession() async {
    try {
      activeSession = await _sessionRepository.startNewSession();
      entries = [];
      notifyListeners();
      return null;
    } catch (e) {
      return 'تعذر بدء يومية جديدة: $e';
    }
  }

  Future<String?> addEntry({
    required Room room,
    required String numbering,
    required String carpenter,
    required String service,
    required String installer,
    required String supervisor,
    required String repairer,
    required String deficiencies,
  }) async {
    if (activeSession == null) return 'لا توجد يومية نشطة حاليًا.';
    if (numbering.trim().isEmpty) return 'حقل الترقيم مطلوب.';
    if (carpenter.trim().isEmpty) return 'اسم النجار مطلوب.';

    try {
      final entry = await _entryRepository.addEntry(
        dailySessionId: activeSession!.id,
        room: room,
        numbering: numbering,
        carpenter: carpenter,
        service: service,
        installer: installer,
        supervisor: supervisor,
        repairer: repairer,
        deficiencies: deficiencies,
      );
      entries = [...entries, entry];
      notifyListeners();
      return null;
    } catch (e) {
      return 'تعذر إضافة الغرفة إلى اليومية: $e';
    }
  }

  Future<String?> updateEntry(DailyEntry updatedFields) async {
    try {
      final updated = await _entryRepository.updateEntryFields(updatedFields);
      entries =
          entries.map((e) => e.id == updated.id ? updated : e).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return 'تعذر تعديل الغرفة: $e';
    }
  }

  Future<String?> updateEntryDeficiencies({
    required String entryId,
    required String newText,
  }) async {
    try {
      final updated = await _entryRepository.updateCurrentDeficiencies(
        entryId: entryId,
        newDeficiencyText: newText,
      );
      entries =
          entries.map((e) => e.id == updated.id ? updated : e).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return 'تعذر تعديل النواقص: $e';
    }
  }

  Future<String?> deleteEntry(String entryId) async {
    try {
      await _entryRepository.deleteEntry(entryId);
      entries = entries.where((e) => e.id != entryId).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return 'تعذر حذف الغرفة: $e';
    }
  }

  /// ينهي اليومية الحالية دون المساس بأي بيانات؛ تصبح بعدها متاحة في
  /// تبويب السجل كسجل تاريخي دائم (قاعدة العمل #15، #16).
  Future<String?> finishSession() async {
    if (activeSession == null) return 'لا توجد يومية نشطة لإنهائها.';
    try {
      await _sessionRepository.closeSession(activeSession!.id);
      activeSession = null;
      entries = [];
      notifyListeners();
      return null;
    } catch (e) {
      return 'تعذر إنهاء اليومية: $e';
    }
  }
}
