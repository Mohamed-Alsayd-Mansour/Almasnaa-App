import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../repositories/daily_entry_repository.dart';
import '../../utils/date_formatter.dart';

/// يفتح ورقة سفلية (Bottom Sheet) لضبط فلاتر البحث المتقدم في السجل،
/// ويعيد الفلاتر الجديدة عند الضغط على "تطبيق"، أو null عند الإلغاء.
Future<RecordSearchFilters?> showAdvancedFiltersSheet(
  BuildContext context,
  RecordSearchFilters current,
) {
  return showModalBottomSheet<RecordSearchFilters>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AdvancedFiltersSheet(current: current),
  );
}

class _AdvancedFiltersSheet extends StatefulWidget {
  final RecordSearchFilters current;
  const _AdvancedFiltersSheet({required this.current});

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  DateTime? _from;
  DateTime? _to;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _carpenterCtrl;
  late final TextEditingController _installerCtrl;
  late final TextEditingController _supervisorCtrl;
  late final TextEditingController _wrapLocationCtrl;
  RoomEntryStatus? _status;

  @override
  void initState() {
    super.initState();
    _from = widget.current.dateFrom;
    _to = widget.current.dateTo;
    _roomCtrl = TextEditingController(text: widget.current.roomName ?? '');
    _carpenterCtrl = TextEditingController(text: widget.current.carpenter ?? '');
    _installerCtrl = TextEditingController(text: widget.current.installer ?? '');
    _supervisorCtrl = TextEditingController(text: widget.current.supervisor ?? '');
    _wrapLocationCtrl =
        TextEditingController(text: widget.current.wrapLocation ?? '');
    _status = widget.current.status;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('بحث متقدم',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFrom: true),
                    icon: const Icon(Icons.date_range),
                    label: Text(_from == null
                        ? 'من تاريخ'
                        : AppDateFormatter.date(_from!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFrom: false),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                        _to == null ? 'إلى تاريخ' : AppDateFormatter.date(_to!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _roomCtrl,
              decoration: const InputDecoration(labelText: 'اسم الغرفة'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _carpenterCtrl,
              decoration: const InputDecoration(labelText: 'النجار'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _installerCtrl,
              decoration: const InputDecoration(labelText: 'الرصيص'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _supervisorCtrl,
              decoration: const InputDecoration(labelText: 'المشرف'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _wrapLocationCtrl,
              decoration: const InputDecoration(labelText: 'مكان اللف'),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('حالة الغرفة', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('الكل'),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                ChoiceChip(
                  label: const Text('مكتملة'),
                  selected: _status == RoomEntryStatus.completed,
                  onSelected: (_) =>
                      setState(() => _status = RoomEntryStatus.completed),
                ),
                ChoiceChip(
                  label: const Text('بها نواقص'),
                  selected: _status == RoomEntryStatus.pending,
                  onSelected: (_) =>
                      setState(() => _status = RoomEntryStatus.pending),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(const RecordSearchFilters());
                    },
                    child: const Text('مسح الفلاتر'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(RecordSearchFilters(
                        keyword: widget.current.keyword,
                        dateFrom: _from,
                        dateTo: _to,
                        roomName: _roomCtrl.text.trim(),
                        carpenter: _carpenterCtrl.text.trim(),
                        installer: _installerCtrl.text.trim(),
                        supervisor: _supervisorCtrl.text.trim(),
                        wrapLocation: _wrapLocationCtrl.text.trim(),
                        status: _status,
                      ));
                    },
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
