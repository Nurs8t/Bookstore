import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'screens/root_screen.dart';
import 'utils/app_theme.dart';

/// Қолданба іске қосылмас БҰРЫН сақталған баптауларды оқимыз:
///   1. ensureInitialized() — runApp()-тан бұрын плагиндерді (shared_preferences)
///      шақыру үшін Flutter-дің нативті байланысын іске қосады.
///   2. SharedPreferences.getInstance() — дисктегі мәндерді жадқа жүктейді.
///   3. runApp() — бірінші кадрдан бастап дұрыс тақырып (ақ экран жыпылықтамайды).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Баптауларды оқу мүмкін болмады: $e');
  }

  runApp(BookShopApp(
    settings: SettingsProvider(prefs),
    notes: NotesProvider(prefs),
  ));
}

class BookShopApp extends StatelessWidget {
  const BookShopApp({super.key, this.settings, this.notes});

  /// main() ішінде алдын ала жүктелген баптаулар мен жазбалар.
  /// null болса (виджет тесті) — бос, жадтағы нұсқалар жасалады.
  final SettingsProvider? settings;
  final NotesProvider? notes;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settings ?? SettingsProvider()),
        ChangeNotifierProvider(create: (_) => notes ?? NotesProvider()),
        // Себет іске қосылғанда SQLite-тан жүктеледі.
        ChangeNotifierProvider(create: (_) => CartProvider()..load()),
        // Таңдаулылар — SQLite, қолданушы — shared_preferences.
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
        ChangeNotifierProvider(create: (_) => UserProvider()..load()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()..load()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Қазақ әдебиеті дүкені',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          scrollBehavior: const AppScrollBehavior(),
          home: const RootScreen(),
        ),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
