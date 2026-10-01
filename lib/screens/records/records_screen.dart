import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/records_provider.dart';
import '../../providers/rooms_provider.dart' show LoadStatus;
import '../../repositories/daily_entry_repository.dart' show RecordSearchFilters;
import '../../utils/date_formatter.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/deficiency_cell.dart';
import '../../widgets/scrollable_table.dart';
import '../../widgets/status_badge.dart';
import 'advanced_filters_sheet.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _keywordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().load();
    });
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final provider = context.read<RecordsProvider>();
    final result = await showAdvancedFiltersSheet(context, provider.filters);
    if (result == null) return;
    await provider.applyFilters(RecordSearchFilters(
      keyword: _keywordCtrl.text,
      dateFrom: result.dateFrom,
      dateTo: result.dateTo,
      roomName: result.roomName,
      carpenter: result.carpenter,
      installer: result.installer,
      supervisor: result.supervisor,
      wrapLocation: result.wrapLocation,
      status: result.status,
    ));
  }

  Future<void> _clearAll() async {
    _keywordCtrl.clear();
    await context.read<RecordsProvider>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: _keywordCtrl,
                  label: 'بحث شامل في السجل',
                  hint: 'ابحث بأي كلمة: اسم، غرفة، ترقيم، نواقص...',
                  onChanged: (v) =>
                      context.read<RecordsProvider>().searchWithKeyword(v),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                tooltip: 'بحث متقدم',
                onPressed: _openFilters,
                icon: const Icon(Icons.tune),
              ),
              IconButton(
                tooltip: 'مسح الفلاتر',
                onPressed: _clearAll,
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Consumer<RecordsProvider>(
            builder: (context, provider, _) {
              if (provider.filters.isEmpty) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (provider.filters.dateFrom != null)
                      Chip(label: Text('من ${AppDateFormatter.date(provider.filters.dateFrom!)}')),
                    if (provider.filters.dateTo != null)
                      Chip(label: Text('إلى ${AppDateFormatter.date(provider.filters.dateTo!)}')),
                    if ((provider.filters.roomName ?? '').isNotEmpty)
                      Chip(label: Text('الغرفة: ${provider.filters.roomName}')),
                    if ((provider.filters.carpenter ?? '').isNotEmpty)
                      Chip(label: Text('النجار: ${provider.filters.carpenter}')),
                    if ((provider.filters.installer ?? '').isNotEmpty)
                      Chip(label: Text('الرصيص: ${provider.filters.installer}')),
                    if ((provider.filters.supervisor ?? '').isNotEmpty)
                      Chip(label: Text('المشرف: ${provider.filters.supervisor}')),
                    if ((provider.filters.wrapLocation ?? '').isNotEmpty)
                      Chip(label: Text('مكان اللف: ${provider.filters.wrapLocation}')),
                    if (provider.filters.status != null)
                      Chip(label: Text('الحالة: ${provider.filters.status!.label}')),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Consumer<RecordsProvider>(
              builder: (context, provider, _) {
                if (provider.status == LoadStatus.loading &&
                    provider.results.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.status == LoadStatus.error) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'حدث خطأ',
                    subtitle: provider.errorMessage,
                  );
                }
                if (provider.results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_toggle_off,
                    title: 'لا توجد سجلات مطابقة',
                    subtitle: 'جرّب تعديل كلمة البحث أو الفلاتر المطبّقة.',
                  );
                }

                final rows = provider.results;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: AppScrollableTable(
                    child: DataTable(
                        columns: const [
                          DataColumn(label: Text('م')),
                          DataColumn(label: Text('اليوم')),
                          DataColumn(label: Text('التاريخ')),
                          DataColumn(label: Text('الغرفة (القطع)')),
                          DataColumn(label: Text('الترقيم')),
                          DataColumn(label: Text('النجار')),
                          DataColumn(label: Text('الخدمة')),
                          DataColumn(label: Text('الرصيص')),
                          DataColumn(label: Text('المشرف')),
                          DataColumn(label: Text('الرميم')),
                          DataColumn(label: Text('مكان اللف')),
                          DataColumn(label: Text('المواصفات')),
                          DataColumn(label: Text('النواقص')),
                          DataColumn(label: Text('عدد الناقص'), numeric: true),
                          DataColumn(label: Text('الحالة')),
                        ],
                        rows: [
                          for (var i = 0; i < rows.length; i++)
                            DataRow(
                              color: WidgetStateProperty.all(
                                  rowColorForStatus(rows[i].entry.status)),
                              cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(rows[i].dayName)),
                                DataCell(Text(AppDateFormatter.date(rows[i].date))),
                                DataCell(Text(rows[i].entry.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text(rows[i].entry.numbering)),
                                DataCell(Text(rows[i].entry.carpenter)),
                                DataCell(Text(rows[i].entry.service)),
                                DataCell(Text(rows[i].entry.installer)),
                                DataCell(Text(rows[i].entry.supervisor)),
                                DataCell(Text(rows[i].entry.repairer)),
                                DataCell(Text(rows[i].entry.wrapLocation)),
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      rows[i].entry.hasSpecifications
                                          ? rows[i].entry.specificationsText
                                          : '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: DeficiencyCell(
                                      text: rows[i].entry.currentDeficiencies,
                                      missingCount:
                                          rows[i].entry.currentMissingPiecesCount,
                                      editable: true,
                                      onSave: (newText) => context
                                          .read<RecordsProvider>()
                                          .updateDeficiencies(
                                            entryId: rows[i].entry.id,
                                            newText: newText,
                                          ),
                                    ),
                                  ),
                                ),
                                DataCell(Text('${rows[i].entry.currentMissingPiecesCount}')),
                                DataCell(StatusBadge(status: rows[i].entry.status)),
                              ],
                            ),
                        ],
                      ),
                    ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
