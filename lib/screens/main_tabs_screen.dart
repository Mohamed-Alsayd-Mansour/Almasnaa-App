import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/daily_provider.dart';
import '../providers/people_provider.dart';
import '../providers/records_provider.dart';
import '../providers/rooms_provider.dart';
import '../services/live_sync_service.dart';

import 'daily/daily_screen.dart';
import 'records/records_screen.dart';
import 'research/research_screen.dart';
import 'rooms/rooms_screen.dart';
import 'settings/settings_screen.dart';
import '../utils/platform_utils.dart';

/// نقطة الدخول لواجهة التطبيق: تبويبات الغرف / اليومية / السجل / الإعدادات / الاستعلامات.
class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen>
    with SingleTickerProviderStateMixin {
  /// الاستعلامات للويب وويندوز فقط.
  final bool _withResearch = showResearchTab;

  late final TabController _tabController =
      TabController(length: _withResearch ? 5 : 4, vsync: this);

  @override
  void initState() {
    super.initState();
    // المزامنة اللحظية: إعادة تحميل الشاشات بعد وصول بيانات من السحابة.
    LiveSyncService.instance.onRemoteApplied = () async {
      if (!mounted) return;
      await Future.wait([
        context.read<RoomsProvider>().loadRooms(),
        context.read<DailyProvider>().load(),
        context.read<RecordsProvider>().load(),
        context.read<PeopleProvider>().load(),
      ]);
    };
  }

  @override
  void dispose() {
    LiveSyncService.instance.onRemoteApplied = null;
    _tabController.dispose();
    super.dispose();
  }

  Tab _tab(IconData icon, String label) => Tab(
        height: isMobileApp ? 58 : null,
        iconMargin: EdgeInsets.only(bottom: isMobileApp ? 3 : 10),
        icon: Icon(icon, size: isMobileApp ? 22 : null),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1, softWrap: false),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصنع'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          // على الهاتف: عناوين أصغر وحشو أقل ليتسع النص كاملًا تحت الأيقونة.
          labelPadding: isMobileApp
              ? const EdgeInsets.symmetric(horizontal: 2)
              : null,
          labelStyle: TextStyle(
              fontWeight: FontWeight.w800, fontSize: isMobileApp ? 12.5 : null),
          unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w800, fontSize: isMobileApp ? 12.5 : null),
          tabs: [
            _tab(Icons.meeting_room_outlined, 'الغرف'),
            _tab(Icons.event_note_outlined, 'اليومية'),
            _tab(Icons.fact_check_outlined, 'السجل'),
            _tab(Icons.settings_outlined, 'الإعدادات'),
            if (_withResearch) _tab(Icons.query_stats_outlined, 'الاستعلامات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const RoomsScreen(),
          const DailyScreen(),
          const RecordsScreen(),
          const SettingsScreen(),
          if (_withResearch) const ResearchScreen(),
        ],
      ),
    );
  }
}
