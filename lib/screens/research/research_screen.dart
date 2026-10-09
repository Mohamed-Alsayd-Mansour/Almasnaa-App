import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/enums.dart';
import '../../services/html_print_service.dart';
import '../../services/research_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/platform_utils.dart';
import '../../widgets/app_data_grid.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/print_template_dialog.dart';

/// التبويب الخامس: بحوث واستعلامات تفصيلية عن كل البيانات المحفوظة في
/// ملف JSON (الغرف، اليوميات، السجلات، الأسماء) مع ترتيب بالضغط على
/// العناوين وطباعة مخصصة بنفس منطق طباعة البرنامج.
class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  ResearchData? _data;
  String? _error;
  bool _loading = true;

  ResearchView _view = ResearchView.overview;
  ResearchGroup _group = ResearchGroup.room;
  ResearchFilters _filters = const ResearchFilters();

  ResearchTable? _table;
  List<ResearchRow> _rows = [];
  String? _sortKey;
  bool _sortAsc = true;

  final _keywordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await ResearchData.load();
      _recompute(resetSort: false);
    } catch (e) {
      _error = 'تعذر تحميل البيانات: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _recompute({bool resetSort = true}) {
    final data = _data;
    if (data == null) return;
    final table =
        ResearchService.build(_view, data, _filters, group: _group);
    if (resetSort) _sortKey = null;
    _table = table;
    _rows = _sorted(table.rows);
  }

  List<ResearchRow> _sorted(List<ResearchRow> rows) {
    final key = _sortKey;
    if (key == null) return rows;
    final copy = [...rows];
    copy.sort((a, b) {
      final na = a.sort[key];
      final nb = b.sort[key];
      final int c = (na != null && nb != null)
          ? na.compareTo(nb)
          : a.value(key).compareTo(b.value(key));
      return _sortAsc ? c : -c;
    });
    return copy;
  }

  void _onSort(int columnIndex) {
    final table = _table;
    if (table == null) return;
    final key = table.columns[columnIndex].key;
    setState(() {
      if (_sortKey == key) {
        _sortAsc = !_sortAsc;
      } else {
        _sortKey = key;
        _sortAsc = true;
      }
      _rows = _sorted(table.rows);
    });
  }

  void _update(void Function() change) {
    setState(() {
      change();
      _recompute();
    });
  }

  Future<void> _pickDate({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _filters.dateFrom : _filters.dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _update(() {
      _filters = from
          ? _filters.copyWith(dateFrom: picked)
          : _filters.copyWith(dateTo: picked);
    });
  }

  void _clearFilters() {
    _keywordCtrl.clear();
    _update(() => _filters = const ResearchFilters());
  }

  PrintSpec<ResearchRow> _specFor(ResearchTable table) {
    final fields = [
      for (final c in table.columns)
        HtmlPrintField<ResearchRow>(
          key: c.key,
          label: c.label,
          valueOf: (r) => r.value(c.key),
        ),
    ];
    return PrintSpec<ResearchRow>(
      storageKey: 'html_print_templates_research_${table.view.name}_v1',
      fields: fields,
      defaultCustomBaseTemplateId: 'full',
      builtInTemplates: {
        'full': HtmlPrintTemplate(
          id: 'full',
          name: 'تقرير ${table.view.label}',
          fieldKeys: fields.map((f) => f.key).toList(),
        ),
      },
    );
  }

  Future<void> _print() async {
    final table = _table;
    if (table == null || _rows.isEmpty) {
      showErrorSnackBar(context, 'لا توجد نتائج لطباعتها.');
      return;
    }
    final parts = <String>[_view.label];
    if (_view == ResearchView.grouped) parts.add('حسب ${_group.label}');
    final filterText = _filters.describe();
    if (filterText.isNotEmpty) parts.add(filterText);

    await runHtmlPrintFlow<ResearchRow>(
      context,
      spec: _specFor(table),
      rows: _rows,
      subtitle: parts.join(' — '),
      fileNamePrefix:
          'استعلام-${_view.label}-${AppDateFormatter.date(DateTime.now()).replaceAll('/', '-')}',
    );
  }

  Widget _statCard(ResearchStat s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            Text(s.label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _filtersBar() {
    final f = _filters;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: AppSearchField(
            controller: _keywordCtrl,
            label: 'بحث',
            hint: 'اكتب أي كلمة...',
            onChanged: (v) => _update(() => _filters = _filters.copyWith(keyword: v)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _pickDate(from: true),
          icon: const Icon(Icons.event),
          label: Text(f.dateFrom == null
              ? 'من تاريخ'
              : 'من ${AppDateFormatter.date(f.dateFrom!)}'),
        ),
        OutlinedButton.icon(
          onPressed: () => _pickDate(from: false),
          icon: const Icon(Icons.event),
          label: Text(f.dateTo == null
              ? 'إلى تاريخ'
              : 'إلى ${AppDateFormatter.date(f.dateTo!)}'),
        ),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<RoomEntryStatus?>(
            value: f.status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'الحالة'),
            items: [
              const DropdownMenuItem<RoomEntryStatus?>(value: null, child: Text('الكل')),
              for (final s in RoomEntryStatus.values)
                DropdownMenuItem<RoomEntryStatus?>(value: s, child: Text(s.label)),
            ],
            onChanged: (v) => _update(() => _filters = v == null
                ? _filters.copyWith(clearStatus: true)
                : _filters.copyWith(status: v)),
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<ResearchShape?>(
            value: f.shape,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'الشكل'),
            items: [
              const DropdownMenuItem<ResearchShape?>(value: null, child: Text('الكل')),
              for (final s in ResearchShape.values)
                DropdownMenuItem<ResearchShape?>(value: s, child: Text(s.label)),
            ],
            onChanged: (v) => _update(() => _filters = v == null
                ? _filters.copyWith(clearShape: true)
                : _filters.copyWith(shape: v)),
          ),
        ),
        if (_view == ResearchView.grouped)
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<ResearchGroup>(
              value: _group,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'التجميع حسب'),
              items: [
                for (final g in ResearchGroup.values)
                  DropdownMenuItem<ResearchGroup>(value: g, child: Text(g.label)),
              ],
              onChanged: (v) {
                if (v != null) _update(() => _group = v);
              },
            ),
          ),
        IconButton(
          tooltip: 'مسح الفلاتر',
          onPressed: _clearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
        ),
        IconButton(
          tooltip: 'تحديث البيانات',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
        // زر الطباعة لا يظهر في تطبيق أندرويد (مثل بقية الجداول).
        if (!isAndroidApp)
          OutlinedButton.icon(
            onPressed: _print,
            icon: const Icon(Icons.print_outlined),
            label: const Text('طباعة النتائج'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _table == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'حدث خطأ',
        subtitle: _error,
        action: ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
      );
    }
    final table = _table;
    if (table == null) return const SizedBox.shrink();

    final sortIndex =
        table.columns.indexWhere((c) => c.key == _sortKey);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final v in ResearchView.values)
                ChoiceChip(
                  label: Text(v.label),
                  selected: _view == v,
                  onSelected: (_) => _update(() => _view = v),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _filtersBar(),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final s in table.stats) _statCard(s)],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _rows.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'لا توجد نتائج مطابقة',
                    subtitle: 'جرّب تعديل البحث أو الفلاتر.',
                  )
                : Card(
                    clipBehavior: Clip.antiAlias,
                    child: AppDataGrid(
                      columns: [
                        const AppGridColumn('م', width: 56, numeric: true),
                        for (final c in table.columns)
                          AppGridColumn(c.label, width: c.width, numeric: c.numeric),
                      ],
                      rowCount: _rows.length,
                      rowHeight: 56,
                      // العمود الأول (م) ليس قابلًا للترتيب: نزيح الفهرس.
                      sortColumnIndex: sortIndex < 0 ? null : sortIndex + 1,
                      sortAscending: _sortAsc,
                      onSort: (i) {
                        if (i > 0) _onSort(i - 1);
                      },
                      rowBuilder: (i) {
                        final row = _rows[i];
                        return AppGridRow(
                          color: row.tint,
                          cells: [
                            gridText('${i + 1}'),
                            for (final c in table.columns)
                              gridText(row.value(c.key)),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
