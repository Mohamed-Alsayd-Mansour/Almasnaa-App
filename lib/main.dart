import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app_theme.dart';
import 'providers/daily_provider.dart';
import 'providers/people_provider.dart';
import 'providers/records_provider.dart';
import 'providers/rooms_provider.dart';
import 'screens/main_tabs_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة window_manager
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    center: true,
    title: 'المصنع',
  );

  await windowManager.waitUntilReadyToShow(
    windowOptions,
    () async {
      await windowManager.setFullScreen(true);
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(const AlmasnaaApp());
}

/// جذر تطبيق "المصنع"
class AlmasnaaApp extends StatefulWidget {
  const AlmasnaaApp({super.key});

  @override
  State<AlmasnaaApp> createState() => _AlmasnaaAppState();
}

class _AlmasnaaAppState extends State<AlmasnaaApp> {
  @override
  void initState() {
    super.initState();

    // التقاط زر ESC من لوحة المفاتيح
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _exitFullscreen();
      return true;
    }

    return false;
  }

  Future<void> _exitFullscreen() async {
    final isFullscreen = await windowManager.isFullScreen();

    if (isFullscreen) {
      await windowManager.setFullScreen(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoomsProvider()),
        ChangeNotifierProvider(create: (_) => DailyProvider()),
        ChangeNotifierProvider(create: (_) => RecordsProvider()),
        ChangeNotifierProvider(create: (_) => PeopleProvider()..load()),
      ],
      child: MaterialApp(
        title: 'المصنع',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const MainTabsScreen(),
      ),
    );
  }
}