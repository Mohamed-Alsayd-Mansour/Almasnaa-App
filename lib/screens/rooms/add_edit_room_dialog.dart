import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/common_widgets.dart';

/// يفتح نافذة Form احترافية لإضافة غرفة جديدة أو تعديل غرفة موجودة.
/// يعيد true إذا تمت العملية بنجاح.
Future<bool?> showAddEditRoomDialog(BuildContext context, {Room? room}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AddEditRoomDialog(room: room),
  );
}

class AddEditRoomDialog extends StatefulWidget {
  final Room? room;
  const AddEditRoomDialog({super.key, this.room});

  @override
  State<AddEditRoomDialog> createState() => _AddEditRoomDialogState();
}

class _AddEditRoomDialogState extends State<AddEditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pieceCtrl;
  late final TextEditingController _glassCtrl;
  late final TextEditingController _partitionCtrl;
  bool _saving = false;

  bool get isEditing => widget.room != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.room?.name ?? '');
    _pieceCtrl =
        TextEditingController(text: widget.room?.pieceCount.toString() ?? '');
    _glassCtrl = TextEditingController(
        text: widget.room?.glassPieceCount.toString() ?? '');
    _partitionCtrl = TextEditingController(
        text: widget.room?.partitionPieceCount.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pieceCtrl.dispose();
    _glassCtrl.dispose();
    _partitionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<RoomsProvider>();
    final name = _nameCtrl.text.trim();
    final pieces = int.parse(_pieceCtrl.text.trim());
    final glass = int.parse(_glassCtrl.text.trim());
    final partitions = int.parse(_partitionCtrl.text.trim());

    final error = isEditing
        ? await provider.updateRoom(
            original: widget.room!,
            name: name,
            pieceCount: pieces,
            glassPieceCount: glass,
            partitionPieceCount: partitions,
          )
        : await provider.addRoom(
            name: name,
            pieceCount: pieces,
            glassPieceCount: glass,
            partitionPieceCount: partitions,
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
    return AlertDialog(
      title: Text(isEditing ? 'تعديل غرفة' : 'إضافة غرفة'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الغرفة *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'اسم الغرفة مطلوب' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pieceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'عدد القطع *'),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'يرجى إدخال رقم صحيح';
                  if (n <= 0) return 'يجب أن يكون أكبر من صفر';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _glassCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'عدد قطع الزجاج *'),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'يرجى إدخال رقم صحيح';
                  if (n < 0) return 'لا يمكن أن يكون سالبًا';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _partitionCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'عدد قطع القواطيع *'),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'يرجى إدخال رقم صحيح';
                  if (n < 0) return 'لا يمكن أن يكون سالبًا';
                  return null;
                },
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
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
