import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'providers/daily_provider.dart';
import 'providers/people_provider.dart';
import 'providers/records_provider.dart';
import 'providers/rooms_provider.dart';
import 'screens/main_tabs_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlmasnaaApp());
}

/// جذر تطبيق "المصنع"، مسؤول عن تسجيل مزودات الحالة (Providers)
/// وضبط الواجهة بالكامل باللغة العربية واتجاه RTL.
class AlmasnaaApp extends StatelessWidget {
  const AlmasnaaApp({super.key});

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
        supportedLocales: const [Locale('ar')],
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
