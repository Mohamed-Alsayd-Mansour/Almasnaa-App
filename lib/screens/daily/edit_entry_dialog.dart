import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/daily_entry.dart';
import '../../models/person.dart';
import '../../providers/daily_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/person_dropdown.dart';

/// نافذة تعديل الحقول التشغيلية لإدخال قائم في اليومية (لا تتضمن
/// النواقص، التي تُعدَّل من خلية النواقص مباشرة أو من تبويب السجل).
Future<bool?> showEditEntryDialog(BuildContext context, DailyEntry entry) {
  return showDialog<bool>(
    context: context,
    builder: (_) => EditEntryDialog(entry: entry),
  );
}

class EditEntryDialog extends StatefulWidget {
  final DailyEntry entry;
  const EditEntryDialog({super.key, required this.entry});

  @override
  State<EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<EditEntryDialog> {
  late final TextEditingController _numberingCtrl =
      TextEditingController(text: widget.entry.numbering);
  late String? _carpenter = _nullIfEmpty(widget.entry.carpenter);
  late String? _service = _nullIfEmpty(widget.entry.service);
  late String? _installer = _nullIfEmpty(widget.entry.installer);
  late String? _supervisor = _nullIfEmpty(widget.entry.supervisor);
  late String? _repairer = _nullIfEmpty(widget.entry.repairer);
  late String? _wrapLocation = _nullIfEmpty(widget.entry.wrapLocation);

  late bool _hasSpecifications = widget.entry.hasSpecifications;
  late final TextEditingController _specificationsCtrl =
      TextEditingController(text: widget.entry.specificationsText);
  late final TextEditingController _specialPieceCountCtrl =
      TextEditingController(
          text: widget.entry.hasSpecifications
              ? widget.entry.specialPieceCount.toString()
              : '');

  late bool _isPartial = widget.entry.isPartial;
  late final TextEditingController _partNameCtrl =
      TextEditingController(text: widget.entry.partName);
  late final TextEditingController _partCountCtrl = TextEditingController(
      text: widget.entry.isPartial
          ? widget.entry.partialPieceCount.toString()
          : '');

  bool _saving = false;

  static String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v;

  @override
  void dispose() {
    _numberingCtrl.dispose();
    _specificationsCtrl.dispose();
    _specialPieceCountCtrl.dispose();
    _partNameCtrl.dispose();
    _partCountCtrl.dispose();
    super.dispose();
  }

  void _onToggleSpecifications(bool value) {
    setState(() {
      _hasSpecifications = value;
      if (value && _specialPieceCountCtrl.text.trim().isEmpty) {
        _specialPieceCountCtrl.text = widget.entry.pieceCountSnapshot.toString();
      }
    });
  }

  Future<void> _submit() async {
    final partName = _partNameCtrl.text.trim();
    final partCount = int.tryParse(_partCountCtrl.text.trim()) ?? 0;
    if (_isPartial && (partName.isEmpty || partCount <= 0)) {
      showErrorSnackBar(
          context, 'أدخل اسم الجزء وعدد القطع الموجودة (أكبر من صفر).');
      return;
    }
    setState(() => _saving = true);
    // اسم الغرفة المسجّل: "[اسم الجزء] [اسم الغرفة]".
    final baseName = widget.entry.baseRoomName;
    final updated = widget.entry.copyWithFields(
      roomNameSnapshot: _isPartial ? '$partName $baseName' : baseName,
      isPartial: _isPartial,
      partName: _isPartial ? partName : '',
      partialPieceCount: _isPartial ? partCount : 0,
      numbering: _numberingCtrl.text.trim(),
      carpenter: _carpenter ?? '',
      service: _service ?? '',
      installer: _installer ?? '',
      supervisor: _supervisor ?? '',
      repairer: _repairer ?? '',
      wrapLocation: _wrapLocation ?? '',
      hasSpecifications: _hasSpecifications,
      specificationsText: _specificationsCtrl.text.trim(),
      specialPieceCount: _hasSpecifications
          ? (int.tryParse(_specialPieceCountCtrl.text.trim()) ?? 0)
          : widget.entry.specialPieceCount,
    );
    final error = await context.read<DailyProvider>().updateEntry(updated);
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
    return AlertDialog(
      title: Text('تعديل: ${widget.entry.displayName}'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _numberingCtrl,
                decoration: const InputDecoration(labelText: 'ترقيمها'),
              ),
              const SizedBox(height: 14),
              PersonDropdownField(
                role: PersonRole.carpenter,
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
              PersonDropdownField(
                role: PersonRole.wrapLocation,
                value: _wrapLocation,
                onChanged: (v) => setState(() => _wrapLocation = v),
              ),
              const SizedBox(height: 14),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('جزء من غرفة',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text(
                    'تسجيل جزء أو أكثر من الغرفة بدل الغرفة كاملة.'),
                value: _isPartial,
                onChanged: (v) => setState(() => _isPartial = v),
              ),
              if (_isPartial) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _partNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'اسم الجزء أو الأجزاء'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _partCountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'عدد القطع الموجودة'),
                ),
              ],
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وسم "مواصفات"',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text(
                    'غرفة بمواصفات وتعديلات شكلية خاصة، وعدد قطع مستقل تمامًا عن العدد القياسي للغرفة.'),
                value: _hasSpecifications,
                onChanged: _onToggleSpecifications,
              ),
              if (_hasSpecifications) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _specificationsCtrl,
                  maxLines: 4,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'المواصفات والتعديلات الشكلية',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _specialPieceCountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'عدد قطع غرفة المواصفات',
                    helperText:
                        'مستقل تمامًا عن عدد القطع القياسي للغرفة العادية.',
                  ),
                ),
              ],
            ],
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
