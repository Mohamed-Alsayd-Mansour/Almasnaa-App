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
  bool _saving = false;

  static String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v;

  @override
  void dispose() {
    _numberingCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final updated = widget.entry.copyWithFields(
      numbering: _numberingCtrl.text.trim(),
      carpenter: _carpenter ?? '',
      service: _service ?? '',
      installer: _installer ?? '',
      supervisor: _supervisor ?? '',
      repairer: _repairer ?? '',
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
