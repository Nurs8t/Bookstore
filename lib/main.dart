import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/auth/auth_cubit.dart';
import 'blocs/cart/cart_bloc.dart';
import 'blocs/diary/diary_cubit.dart';
import 'blocs/favorites/favorites_cubit.dart';
import 'blocs/orders/orders_cubit.dart';
import 'providers/notes_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart';
import 'screens/root_screen.dart';
import 'services/session_store.dart';
import 'utils/app_theme.dart';

/// Қолданба іске қосылмас БҰРЫН сақталған баптауларды оқимыз:
///   1. ensureInitialized() — runApp()-тан бұрын плагиндерді (shared_preferences)
///      шақыру үшін Flutter-дің нативті байланысын іске қосады.
///   2. SharedPreferences.getInstance() — дисктегі мәндерді жадқа жүктейді.
///   3. Keychain/KeyStore-дан сессия токенін оқимыз — бар болса, кіру экранын өткізіп жібереміз.
///   4. runApp() — бірінші кадрдан бастап дұрыс тақырып пен дұрыс экран.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Баптауларды оқу мүмкін болмады: $e');
  }

  Session? session;
  try {
    session = await SessionStore().read();
  } catch (e) {
    debugPrint('Сессияны оқу мүмкін болмады: $e');
  }

  runApp(BookShopApp(
    settings: SettingsProvider(prefs),
    notes: NotesProvider(prefs),
    session: session,
  ));
}

class BookShopApp extends StatelessWidget {
  const BookShopApp({super.key, this.settings, this.notes, this.session});

  /// main() ішінде алдын ала жүктелген баптаулар мен жазбалар.
  /// null болса (виджет тесті) — бос, жадтағы нұсқалар жасалады.
  final SettingsProvider? settings;
  final NotesProvider? notes;

  /// Шифрланған қоймадан оқылған сессия (null — кірмеген).
  final Session? session;

  @override
  Widget build(BuildContext context) {
    // BLoC: кіру, себет, таңдаулылар, тапсырыстар (каталог — CatalogScreen ішінде).
    // Provider: қолданушы профилі, баптаулар, жазбалар (shared_preferences).
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(restoredSession: session)),
        // Себет іске қосылғанда SQLite-тан жүктеледі (LoadCartEvent).
        BlocProvider(create: (_) => CartBloc()..add(const LoadCartEvent())),
        // Таңдаулылар мен тапсырыстар — SQLite-тан жүктелетін Cubit-тер.
        BlocProvider(create: (_) => FavoritesCubit()..load()),
        BlocProvider(create: (_) => OrdersCubit()..load()),
        // Оқырман күнделігі: суреттер + GPS координаттары (SQLite).
        BlocProvider(create: (_) => DiaryCubit()..load()),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => settings ?? SettingsProvider()),
          ChangeNotifierProvider(create: (_) => notes ?? NotesProvider()),
          // Қолданушы профилі — shared_preferences.
          ChangeNotifierProvider(create: (_) => UserProvider()..load()),
        ],
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Қазақ әдебиеті дүкені',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            scrollBehavior: const AppScrollBehavior(),
            // Баптаулардағы қаріп өлшемі жүйенікіне көбейтіледі (жоғарғы шегі ×1.6).
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final scale = (media.textScaler.scale(1) * settings.textSize.factor).clamp(0.8, 1.6);
              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              );
            },
            home: session == null ? const LoginScreen() : const RootScreen(),
          ),
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
