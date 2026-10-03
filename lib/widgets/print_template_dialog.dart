import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/html_print_service.dart';
import '../services/print_template_store.dart';

Future<HtmlPrintTemplate?> showPrintTemplateDialog(
  BuildContext context, {
  required List<HtmlPrintRow> rows,
  required String title,
}) async {
  final custom = await PrintTemplateStore.loadCustom();
  if (!context.mounted) return null;
  return showDialog<HtmlPrintTemplate>(
    context: context,
    builder: (_) => _PrintTemplateDialog(rows: rows, title: title, custom: custom),
  );
}

class _PrintTemplateDialog extends StatefulWidget {
  final List<HtmlPrintRow> rows;
  final String title;
  final List<HtmlPrintTemplate> custom;

  const _PrintTemplateDialog({
    required this.rows,
    required this.title,
    required this.custom,
  });

  @override
  State<_PrintTemplateDialog> createState() => _PrintTemplateDialogState();
}

class _PrintTemplateDialogState extends State<_PrintTemplateDialog> {
  late List<HtmlPrintTemplate> _custom;

  @override
  void initState() {
    super.initState();
    _custom = [...widget.custom];
  }

  Future<void> _customize({HtmlPrintTemplate? initial}) async {
    final result = await showDialog<HtmlPrintTemplate>(
      context: context,
      builder: (_) => _CustomizePrintDialog(initial: initial),
    );
    if (result == null || !mounted) return;
    await PrintTemplateStore.save(result);
    setState(() {
      _custom = [..._custom.where((e) => e.id != result.id), result];
    });
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _delete(HtmlPrintTemplate template) async {
    await PrintTemplateStore.delete(template.id);
    if (mounted) setState(() => _custom.removeWhere((e) => e.id == template.id));
  }

  Widget _tile(HtmlPrintTemplate template, {bool deletable = false}) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(template.name),
      subtitle: Text('${template.fieldKeys.length} حقلاً — ${template.landscape ? 'أفقي' : 'عمودي'}'),
      trailing: Wrap(
        children: [
          IconButton(
            tooltip: 'استخدام القالب',
            icon: const Icon(Icons.play_arrow),
            onPressed: () => Navigator.of(context).pop(template),
          ),
          if (deletable) ...[
            IconButton(
              tooltip: 'تعديل القالب',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _customize(initial: template),
            ),
            IconButton(
              tooltip: 'حذف القالب',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(template),
            ),
          ],
        ],
      ),
      onTap: () => Navigator.of(context).pop(template),
    );
  }

  @override
  Widget build(BuildContext context) {
    final builtIns = HtmlPrintService.builtInTemplates.values.toList();
    return AlertDialog(
      title: const Text('اختر قالب الطباعة'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('قوالب جاهزة', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...builtIns.map(_tile),
              const Divider(height: 28),
              Row(
                children: [
                  const Expanded(child: Text('قوالبي المحفوظة', style: TextStyle(fontWeight: FontWeight.bold))),
                  FilledButton.icon(
                    onPressed: () => _customize(),
                    icon: const Icon(Icons.add),
                    label: const Text('تخصيص قالب'),
                  ),
                ],
              ),
              if (_custom.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: Text('لا توجد قوالب مخصصة محفوظة بعد.')),
                )
              else
                ..._custom.map((e) => _tile(e, deletable: true)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
      ],
    );
  }
}

Future<bool?> showPrintPreviewDialog(
  BuildContext context, {
  required String title,
  required List<HtmlPrintRow> rows,
  required HtmlPrintTemplate template,
}) {
  final selected = template.fieldKeys.map(HtmlPrintService.fieldByKey).toList();
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('معاينة: ${template.name}'),
      content: SizedBox(
        width: 900,
        height: 520,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('عدد السجلات: ${rows.length} — ${template.landscape ? 'A4 أفقي' : 'A4 عمودي'}'),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                      columns: [const DataColumn(label: Text('م')), ...selected.map((f) => DataColumn(label: Text(f.label)))],
                      rows: [
                        for (var i = 0; i < rows.length; i++)
                          DataRow(cells: [
                            DataCell(Text('${i + 1}')),
                            ...selected.map((f) => DataCell(Text(f.valueOf(rows[i])))),
                          ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رجوع')),
        FilledButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.open_in_browser), label: const Text('فتح HTML والطباعة')),
      ],
    ),
  );
}

class _CustomizePrintDialog extends StatefulWidget {
  final HtmlPrintTemplate? initial;

  const _CustomizePrintDialog({this.initial});

  @override
  State<_CustomizePrintDialog> createState() => _CustomizePrintDialogState();
}

class _CustomizePrintDialogState extends State<_CustomizePrintDialog> {
  late final TextEditingController _name;
  late Set<String> _selected;
  late List<String> _order;
  late bool _landscape;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? 'تقرير مخصص');
    _order = HtmlPrintService.fields.map((f) => f.key).toList();
    if (initial != null) {
      final selected = initial.fieldKeys.toSet();
      _order = [...initial.fieldKeys, ..._order.where((k) => !selected.contains(k))];
      _selected = selected;
    } else {
      _selected = {...HtmlPrintService.builtInTemplates['storage']!.fieldKeys};
    }
    _landscape = initial?.landscape ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تخصيص قالب الطباعة'),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم القالب'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('أفقي'), icon: Icon(Icons.crop_landscape)),
                  ButtonSegment(value: false, label: Text('عمودي'), icon: Icon(Icons.crop_portrait)),
                ],
                selected: {_landscape},
                onSelectionChanged: (v) => setState(() => _landscape = v.first),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('اختر البيانات ورتّب الأعمدة بالسحب:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex--;
                    final item = _order.removeAt(oldIndex);
                    _order.insert(newIndex, item);
                  });
                },
                children: [
                  for (final key in _order)
                    Builder(
                      key: ValueKey(key),
                      builder: (_) {
                        final field = HtmlPrintService.fieldByKey(key);
                        final selected = _selected.contains(key);
                        return ListTile(
                          leading: Checkbox(
                            value: selected,
                            onChanged: (_) => setState(() {
                              if (selected) {
                                _selected.remove(key);
                              } else {
                                _selected.add(key);
                              }
                            }),
                          ),
                          title: Text(field.label, style: TextStyle(color: selected ? null : Colors.grey)),
                          trailing: const Icon(Icons.drag_handle),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton.icon(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  final name = _name.text.trim().isEmpty ? 'تقرير مخصص' : _name.text.trim();
                  Navigator.of(context).pop(HtmlPrintTemplate(
                    id: widget.initial?.id ?? const Uuid().v4(),
                    name: name,
                    fieldKeys: _orderedKeys(),
                    landscape: _landscape,
                  ));
                },
          icon: const Icon(Icons.save),
          label: const Text('حفظ واستخدام'),
        ),
      ],
    );
  }

  List<String> _orderedKeys() => _order.where(_selected.contains).toList();
}
