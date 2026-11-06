import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/user_provider.dart';
import 'screens/root_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const BookShopApp());
}

class BookShopApp extends StatelessWidget {
  const BookShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Қазақ әдебиеті дүкені',
        theme: AppTheme.light,
        scrollBehavior: const AppScrollBehavior(),
        home: const RootScreen(),
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
