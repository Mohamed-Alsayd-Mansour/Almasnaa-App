import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/room.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/scrollable_table.dart';
import 'add_edit_room_dialog.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomsProvider>().loadRooms();
    });
  }

  Future<void> _handleAdd() async {
    final ok = await showAddEditRoomDialog(context);
    if (ok == true && mounted) {
      showSuccessSnackBar(context, 'تمت إضافة الغرفة بنجاح.');
    }
  }

  Future<void> _handleEdit(Room room) async {
    final ok = await showAddEditRoomDialog(context, room: room);
    if (ok == true && mounted) {
      showSuccessSnackBar(context, 'تم تعديل بيانات الغرفة بنجاح.');
    }
  }

  Future<void> _handleDelete(Room room) async {
    final provider = context.read<RoomsProvider>();
    final confirmed = await confirmDelete(
      context,
      title: 'حذف الغرفة',
      message:
          'هل أنت متأكد من حذف "${room.name}"؟ لن يؤثر هذا على السجلات التاريخية المحفوظة سابقًا.',
    );
    if (!confirmed) return;
    final error = await provider.deleteRoom(room.id);
    if (!mounted) return;
    if (error != null) {
      showErrorSnackBar(context, error);
    } else {
      showSuccessSnackBar(context, 'تم حذف الغرفة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Consumer<RoomsProvider>(
                  builder: (context, provider, _) => AppSearchField(
                    label: 'البحث في الغرف',
                    hint: 'اكتب اسم الغرفة...',
                    onChanged: provider.search,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _handleAdd,
                icon: const Icon(Icons.add),
                label: const Text('إضافة غرفة'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Consumer<RoomsProvider>(
              builder: (context, provider, _) {
                if (provider.status == LoadStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.status == LoadStatus.error) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'حدث خطأ',
                    subtitle: provider.errorMessage,
                  );
                }
                final rooms = provider.rooms;
                if (rooms.isEmpty) {
                  return EmptyState(
                    icon: Icons.meeting_room_outlined,
                    title: provider.query.isEmpty
                        ? 'لا توجد غرف مسجّلة بعد'
                        : 'لا توجد نتائج مطابقة',
                    subtitle: provider.query.isEmpty
                        ? 'ابدأ بإضافة أول غرفة من زر "إضافة غرفة".'
                        : null,
                  );
                }
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: AppScrollableTable(
                    child: DataTable(
                      columns: const [
                            DataColumn(label: Text('م')),
                            DataColumn(label: Text('الغرفة')),
                            DataColumn(label: Text('عدد القطع'), numeric: true),
                            DataColumn(label: Text('قطع الزجاج'), numeric: true),
                            DataColumn(label: Text('قطع القواطيع'), numeric: true),
                            DataColumn(label: Text('تعديل')),
                          ],
                          rows: [
                            for (var i = 0; i < rooms.length; i++)
                              DataRow(cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(Text(rooms[i].name,
                                    style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text('${rooms[i].pieceCount}')),
                                DataCell(Text('${rooms[i].glassPieceCount}')),
                                DataCell(Text('${rooms[i].partitionPieceCount}')),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'تعديل',
                                      icon: const Icon(Icons.edit, color: AppColors.primary),
                                      onPressed: () => _handleEdit(rooms[i]),
                                    ),
                                    IconButton(
                                      tooltip: 'حذف',
                                      icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                                      onPressed: () => _handleDelete(rooms[i]),
                                    ),
                                  ],
                                )),
                              ]),
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
