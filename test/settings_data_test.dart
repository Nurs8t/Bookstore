import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/blocs/orders/orders_cubit.dart';
import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/models/cart_item.dart';
import 'package:kazakh_book_shop/models/delivery_info.dart';
import 'package:kazakh_book_shop/providers/settings_provider.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';
import 'package:kazakh_book_shop/services/delivery_store.dart';

/// Кеңейтілген баптаулар: қаріп өлшемі, сақталған мекенжай, деректерді тазалау.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = DatabaseHelper.instance..databasePathOverride = inMemoryDatabasePath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await db.deleteDatabaseFile();
  });
  tearDownAll(db.close);

  group('Қаріп өлшемі', () {
    test('Әдепкі — қалыпты (×1.0)', () async {
      final settings = SettingsProvider(await SharedPreferences.getInstance());
      expect(settings.textSize, AppTextSize.normal);
      expect(settings.textSize.factor, 1.0);
    });

    test('Таңдалған өлшем қайта ашқанда қалпына келеді', () async {
      final prefs = await SharedPreferences.getInstance();
      await SettingsProvider(prefs).setTextSize(AppTextSize.large);

      expect(prefs.getString('app_text_size'), 'large');
      expect(SettingsProvider(prefs).textSize, AppTextSize.large);
    });

    test('Бүлінген мән — қалыпты өлшемге оралады', () async {
      SharedPreferences.setMockInitialValues({'app_text_size': 'huge???'});
      final settings = SettingsProvider(await SharedPreferences.getInstance());
      expect(settings.textSize, AppTextSize.normal);
    });

    test('Өзгергенде тыңдаушылар хабардар болады (тек мән өзгерсе)', () async {
      final settings = SettingsProvider();
      var calls = 0;
      settings.addListener(() => calls++);
      await settings.setTextSize(AppTextSize.extraLarge);
      await settings.setTextSize(AppTextSize.extraLarge);
      expect(calls, 1);
    });
  });

  group('DeliveryStore (Keychain / KeyStore)', () {
    const info = DeliveryInfo(
      fullName: 'Нұрсейіт',
      phone: '+77011234567',
      method: DeliveryMethod.courier,
      city: 'Алматы',
      address: 'Абай даңғылы, 10',
      payment: PaymentMethod.cash,
      comment: 'Домофон 15',
    );

    test('Сақталады, оқылады, өшіріледі', () async {
      final store = DeliveryStore();
      expect(await store.read(), isNull);

      await store.save(info);
      final saved = await store.read();
      expect(saved!.phone, '+77011234567');
      expect(saved.destination, 'Алматы, Абай даңғылы, 10');
      expect(saved.payment, PaymentMethod.cash);

      await store.clear();
      expect(await store.read(), isNull);
    });

    test('Пікір сақталмайды — ол тек бір тапсырысқа қатысты', () async {
      final store = DeliveryStore();
      await store.save(info);
      expect((await store.read())!.comment, isEmpty);
    });
  });

  group('Деректерді тазалау', () {
    const book = Book(
      id: '2',
      title: 'Абай жолы',
      author: 'Мұхтар Әуезов',
      price: 3500,
      rating: 5,
      reviewsCount: 1,
      imagePath: '',
      synopsis: '',
      category: 'Роман-эпопея',
      tags: [],
    );

    test('Тапсырыстар тарихын тазалау: дерекқор да, күй де бос', () async {
      final orders = OrdersCubit(db: db);
      await orders.placeOrder(const [CartItem(book: book)]);
      await orders.placeOrder(const [CartItem(book: book, quantity: 2)]);
      expect(orders.state.count, 2);

      await orders.clearHistory();
      expect(orders.state.count, 0);
      expect(await db.getOrders(), isEmpty);
      await orders.close();
    });

    test('Офлайн кэшті тазалау', () async {
      await db.replaceBooksCache([book]);
      expect(await db.getCachedBooks(), hasLength(1));

      expect(await db.clearBooksCache(), 1);
      expect(await db.getCachedBooks(), isEmpty);
      expect(await db.lastCacheTime(), isNull);
    });
  });
}
