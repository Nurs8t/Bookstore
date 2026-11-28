import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kazakh_book_shop/blocs/auth/auth_cubit.dart';
import 'package:kazakh_book_shop/blocs/cart/cart_bloc.dart';
import 'package:kazakh_book_shop/blocs/catalog/catalog_bloc.dart';
import 'package:kazakh_book_shop/blocs/diary/diary_cubit.dart';
import 'package:kazakh_book_shop/blocs/favorites/favorites_cubit.dart';
import 'package:kazakh_book_shop/blocs/orders/orders_cubit.dart';
import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/models/cart_item.dart';
import 'package:kazakh_book_shop/models/delivery_info.dart';
import 'package:kazakh_book_shop/models/diary_entry.dart';
import 'package:kazakh_book_shop/models/order.dart';
import 'package:kazakh_book_shop/providers/notes_provider.dart';
import 'package:kazakh_book_shop/providers/settings_provider.dart';
import 'package:kazakh_book_shop/providers/user_provider.dart';
import 'package:kazakh_book_shop/screens/book_detail_screen.dart';
import 'package:kazakh_book_shop/screens/cart_screen.dart';
import 'package:kazakh_book_shop/screens/catalog_screen.dart';
import 'package:kazakh_book_shop/screens/checkout_screen.dart';
import 'package:kazakh_book_shop/screens/diary_screen.dart';
import 'package:kazakh_book_shop/screens/favorites_screen.dart';
import 'package:kazakh_book_shop/screens/login_screen.dart';
import 'package:kazakh_book_shop/screens/orders_screen.dart';
import 'package:kazakh_book_shop/screens/profile_screen.dart';
import 'package:kazakh_book_shop/screens/registration_screen.dart';
import 'package:kazakh_book_shop/screens/settings_screen.dart';
import 'package:kazakh_book_shop/services/session_store.dart';
import 'package:kazakh_book_shop/utils/app_theme.dart';

/// Overflow тесті: әр экранды әртүрлі өлшемде және үлкен қаріппен сызамыз.
///
/// Flutter тестінде «RenderFlex overflowed by N pixels» (сары-қара жолақ) —
/// бұл қате, ол тестті бірден құлатады. Яғни бұл тест өтсе, экрандарда
/// overflow жоқ.
///
/// Іске қосу: flutter test test/overflow_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Тексерілетін құрылғылар (логикалық пиксель).
  const devices = <String, Size>{
    'iPhone SE (320×568)': Size(320, 568),
    'iPhone 15 (393×852)': Size(393, 852),
    'Телефон, көлденең (852×393)': Size(852, 393),
    'iPad (1024×1366)': Size(1024, 1366),
  };

  /// Әр экран: атауы → виджет жасайтын функция.
  final screens = <String, Widget Function()>{
    'Кіру': () => const LoginScreen(),
    'Тіркелу': () => const RegistrationScreen(),
    'Каталог (тізім)': () => CatalogScreen(bloc: _SeededCatalogBloc(CatalogLoaded(books: _books))),
    'Каталог (офлайн)': () => CatalogScreen(
          bloc: _SeededCatalogBloc(CatalogLoaded(books: _books, isOffline: true, cachedAt: DateTime(2026, 11, 27))),
        ),
    'Кітап мәліметі': () => BookDetailScreen(book: _books.first),
    'Себет': () => const CartScreen(),
    'Тапсырыс беру': () => const CheckoutScreen(),
    'Тапсырыстар тарихы': () => const OrdersScreen(),
    'Таңдаулылар': () => const FavoritesScreen(),
    'Профиль': () => const ProfileScreen(),
    'Баптаулар': () => const SettingsScreen(),
    'Оқырман күнделігі': () => DiaryScreen(initialBookTitle: _books.first.title),
    'Күнделік жазбасы': () => DiaryEntryScreen(entry: _diary.first, photoPath: '/no/such/photo.jpg'),
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  for (final scale in [1.0, 1.3]) {
    for (final device in devices.entries) {
      group('${device.key}, қаріп ×$scale', () {
        for (final screen in screens.entries) {
          testWidgets(screen.key, (tester) async {
            tester.view
              ..devicePixelRatio = 1.0
              ..physicalSize = device.value;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(_App(textScale: scale, child: screen.value()));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));

            // takeException() жоқ: overflow болса, Flutter толық есепті (қай файл, қай жол)
            // өзі басып шығарады және тест құлайды.
          });
        }
      });
    }
  }

  for (final device in devices.entries) {
    testWidgets('Каталог тор көрінісі: ${device.key}, қаріп ×1.3', (tester) async {
      tester.view
        ..devicePixelRatio = 1.0
        ..physicalSize = device.value;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_App(
        textScale: 1.3,
        child: CatalogScreen(bloc: _SeededCatalogBloc(CatalogLoaded(books: _books))),
      ));
      await tester.pump();
      await tester.tap(find.byTooltip('Тор көрінісі'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byTooltip('Тізім көрінісі'), findsOneWidget);
      // Overflow болса — Flutter толық есеппен тестті өзі құлатады.
    });
  }

  testWidgets('Қараңғы тақырыпта да overflow жоқ (себет, тапсырыс)', (tester) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);

    for (final screen in [const CartScreen(), const CheckoutScreen()]) {
      await tester.pumpWidget(_App(textScale: 1.0, dark: true, child: screen));
      await tester.pump(const Duration(milliseconds: 600));
      // Overflow болса — Flutter толық есеппен тестті өзі құлатады.
    }
  });
}

/// Нағыз қолданбадағыдай провайдерлер, бірақ күйлер алдын ала толтырылған
/// (дерекқор мен желіге шықпайды).
class _App extends StatelessWidget {
  const _App({required this.child, required this.textScale, this.dark = false});

  final Widget child;
  final double textScale;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(
            restoredSession: Session(
              token: 'test-token-1234567890abcdef',
              email: 'arystanbek.nurseyit@narxoz.kz',
              username: 'Арыстанбек Нұрсейіт Ерланұлы',
              createdAt: DateTime(2026, 11, 27),
            ),
          ),
        ),
        BlocProvider<CartBloc>(create: (_) => _SeededCartBloc(CartState.fromItems(_cartItems))),
        BlocProvider<FavoritesCubit>(create: (_) => _SeededFavoritesCubit(FavoritesState(_books))),
        BlocProvider<OrdersCubit>(create: (_) => _SeededOrdersCubit(OrdersState(_orders))),
        BlocProvider<DiaryCubit>(
          create: (_) => _SeededDiaryCubit(DiaryState(entries: _diary, photosDir: '/no/such/dir')),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => NotesProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: app!,
          ),
          home: child,
        ),
      ),
    );
  }
}

// ---- Күйі алдын ала берілген BLoC/Cubit-тер (тек тест үшін) ----

class _SeededCartBloc extends CartBloc {
  _SeededCartBloc(CartState seed) {
    emit(seed);
  }
}

class _SeededCatalogBloc extends CatalogBloc {
  _SeededCatalogBloc(CatalogState seed) {
    emit(seed);
  }
}

class _SeededFavoritesCubit extends FavoritesCubit {
  _SeededFavoritesCubit(FavoritesState seed) {
    emit(seed);
  }
}

class _SeededOrdersCubit extends OrdersCubit {
  _SeededOrdersCubit(OrdersState seed) {
    emit(seed);
  }
}

class _SeededDiaryCubit extends DiaryCubit {
  _SeededDiaryCubit(DiaryState seed) {
    emit(seed);
  }
}

// ---- Әдейі «ауыр» деректер: ұзын атаулар, үлкен бағалар ----

Book _book(String id, String title, String author, int price) => Book(
      id: id,
      title: title,
      author: author,
      price: price,
      rating: 4.9,
      reviewsCount: 123456,
      imagePath: '', // сурет орнына placeholder (тестте желі жоқ)
      synopsis: 'Қазақ әдебиетінің классикалық шығармасы. ' * 12,
      category: 'Роман-эпопея',
      tags: const ['Классика', 'Тарихи роман', 'Мектеп бағдарламасы', 'Бестселлер'],
    );

final _books = [
  _book('1', 'Абай жолы. Роман-эпопея. Бірінші кітап: Абай (толықтырылған басылым)',
      'Мұхтар Омарханұлы Әуезов', 1250000),
  _book('2', 'Көшпенділер', 'Ілияс Есенберлин', 4200),
  _book('3', 'Ұлпан', 'Ғабит Мүсірепов', 2800),
  _book('4', 'Махаббат, қызық мол жылдар', 'Әзілхан Нұршайықов', 3000),
];

final _cartItems = [
  CartItem(book: _books[0], quantity: 99),
  CartItem(book: _books[1], quantity: 2),
  CartItem(book: _books[2]),
];

final _orders = [
  OrderRecord.fromCart(
    _cartItems,
    delivery: const DeliveryInfo(
      fullName: 'Арыстанбек Нұрсейіт Ерланұлы',
      phone: '+77011234567',
      method: DeliveryMethod.courier,
      city: 'Алматы',
      address: 'Әл-Фараби даңғылы, 71, 5-корпус, 123-пәтер, 4-подъезд',
      payment: PaymentMethod.cardOnDelivery,
      comment: 'Келер алдында 30 минут бұрын қоңырау шалыңыз, домофон істемейді.',
    ),
  ).withId(1024),
  OrderRecord.fromCart([CartItem(book: _books[3])]).withId(7),
];

final _diary = [
  DiaryEntry(
    id: 1,
    photoFile: 'missing.jpg', // файл жоқ — белгіше көрінуі керек, қате емес
    caption: 'Narxoz кітапханасында «Абай жолының» бірінші томын бастадым, өте әсерлі басталады',
    bookTitle: _books.first.title,
    location: GeoFix(
      latitude: 43.238949,
      longitude: 76.889709,
      accuracy: 12.4,
      altitude: 812,
      timestamp: DateTime(2026, 11, 24, 14, 30, 15),
    ),
    createdAt: DateTime(2026, 11, 24, 14, 30, 15),
  ),
  DiaryEntry(id: 2, photoFile: 'missing2.jpg', caption: 'Үйде', createdAt: DateTime(2026, 11, 20)),
];
