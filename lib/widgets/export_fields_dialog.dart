import 'package:flutter/material.dart';

import '../services/excel_export_service.dart';

/// نافذة اختيار الحقول قبل التصدير إلى Excel. تُرجع قائمة الحقول
/// المختارة (بترتيبها الأصلي الثابت)، أو null عند الإلغاء.
Future<List<ExcelExportField>?> showExportFieldsDialog(
  BuildContext context, {
  required List<ExcelExportField> availableFields,
  required Set<String> initiallySelectedKeys,
}) {
  return showDialog<List<ExcelExportField>>(
    context: context,
    builder: (_) => _ExportFieldsDialog(
      availableFields: availableFields,
      initiallySelectedKeys: initiallySelectedKeys,
    ),
  );
}

class _ExportFieldsDialog extends StatefulWidget {
  final List<ExcelExportField> availableFields;
  final Set<String> initiallySelectedKeys;

  const _ExportFieldsDialog({
    required this.availableFields,
    required this.initiallySelectedKeys,
  });

  @override
  State<_ExportFieldsDialog> createState() => _ExportFieldsDialogState();
}

class _ExportFieldsDialogState extends State<_ExportFieldsDialog> {
  late final Set<String> _selected = {...widget.initiallySelectedKeys};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختر الحقول المطلوب تصديرها'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selected
                      .addAll(widget.availableFields.map((f) => f.key))),
                  child: const Text('تحديد الكل'),
                ),
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  child: const Text('إلغاء التحديد'),
                ),
              ],
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final f in widget.availableFields)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _selected.contains(f.key),
                        title: Text(f.label),
                        onChanged: (v) => setState(() {
                          if (v ?? false) {
                            _selected.add(f.key);
                          } else {
                            _selected.remove(f.key);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  final ordered = widget.availableFields
                      .where((f) => _selected.contains(f.key))
                      .toList();
                  Navigator.of(context).pop(ordered);
                },
          child: const Text('تصدير'),
        ),
      ],
    );
  }
}
