import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../models/room.dart';
import '../../providers/daily_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../utils/deficiency_calculator.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/person_dropdown.dart';

/// نافذة Form احترافية لإضافة غرفة إلى اليومية النشطة. تعرض عدد القطع
/// تلقائيًا فور اختيار الغرفة من القائمة (قاعدة العمل #3)، وتحسب عدد
/// القطع الناقصة تلقائيًا من نص النواقص (قاعدة العمل #6، #7).
Future<bool?> showAddEntryDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const AddEntryDialog(),
  );
}

class AddEntryDialog extends StatefulWidget {
  const AddEntryDialog({super.key});

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  Room? _selectedRoom;

  final _numberingCtrl = TextEditingController();
  String? _carpenter;
  String? _service;
  String? _installer;
  String? _supervisor;
  String? _repairer;
  final _deficienciesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _numberingCtrl.dispose();
    _deficienciesCtrl.dispose();
    super.dispose();
  }

  int get _liveMissingCount =>
      calculateMissingPiecesCount(_deficienciesCtrl.text);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoom == null) {
      showErrorSnackBar(context, 'يرجى اختيار اسم الغرفة أولًا.');
      return;
    }
    setState(() => _saving = true);

    final error = await context.read<DailyProvider>().addEntry(
          room: _selectedRoom!,
          numbering: _numberingCtrl.text,
          carpenter: _carpenter ?? '',
          service: _service ?? '',
          installer: _installer ?? '',
          supervisor: _supervisor ?? '',
          repairer: _repairer ?? '',
          deficiencies: _deficienciesCtrl.text,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      showErrorSnackBar(context, error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomsProvider>().rooms;

    return AlertDialog(
      title: const Text('إضافة غرفة إلى اليومية'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Room>(
                  value: _selectedRoom,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'اسم الغرفة *'),
                  items: rooms
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.name),
                          ))
                      .toList(),
                  onChanged: (r) => setState(() => _selectedRoom = r),
                  validator: (v) => v == null ? 'اختر اسم الغرفة' : null,
                ),
                const SizedBox(height: 14),
                _ReadonlyPieceCount(room: _selectedRoom),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _numberingCtrl,
                  decoration: const InputDecoration(labelText: 'ترقيمها *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الترقيم مطلوب' : null,
                ),
                const SizedBox(height: 14),
                PersonDropdownField(
                  role: PersonRole.carpenter,
                  required: true,
                  value: _carpenter,
                  onChanged: (v) => setState(() => _carpenter = v),
                ),
                const SizedBox(height: 14),
                PersonDropdownField(
                  role: PersonRole.service,
                  value: _service,
                  onChanged: (v) => setState(() => _service = v),
                ),
                const SizedBox(height: 14),
                PersonDropdownField(
                  role: PersonRole.installer,
                  value: _installer,
                  onChanged: (v) => setState(() => _installer = v),
                ),
                const SizedBox(height: 14),
                PersonDropdownField(
                  role: PersonRole.supervisor,
                  value: _supervisor,
                  onChanged: (v) => setState(() => _supervisor = v),
                ),
                const SizedBox(height: 14),
                PersonDropdownField(
                  role: PersonRole.repairer,
                  value: _repairer,
                  onChanged: (v) => setState(() => _repairer = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _deficienciesCtrl,
                  maxLines: 5,
                  minLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'نواقص الغرفة',
                    hintText: 'مثال: باب - رف علوي - ضلفة يمين',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calculate_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text('عدد القطع الناقصة (محسوب تلقائيًا): $_liveMissingCount',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

class _ReadonlyPieceCount extends StatelessWidget {
  final Room? room;
  const _ReadonlyPieceCount({required this.room});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      initialValue: room == null ? '' : '${room!.pieceCount}',
      key: ValueKey(room?.id),
      decoration: const InputDecoration(
        labelText: 'عدد القطع (تلقائي من بيانات الغرفة)',
      ),
    );
  }
}
