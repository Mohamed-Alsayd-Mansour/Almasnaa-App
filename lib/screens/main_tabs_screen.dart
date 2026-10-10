import 'package:flutter/material.dart';

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصنع'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: [
            const Tab(icon: Icon(Icons.meeting_room_outlined), text: 'الغرف'),
            const Tab(icon: Icon(Icons.event_note_outlined), text: 'اليومية'),
            const Tab(icon: Icon(Icons.fact_check_outlined), text: 'السجل'),
            const Tab(icon: Icon(Icons.settings_outlined), text: 'الإعدادات'),
            if (_withResearch)
              const Tab(icon: Icon(Icons.query_stats_outlined), text: 'الاستعلامات'),
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
