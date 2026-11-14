import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/models/cart_item.dart';
import 'package:kazakh_book_shop/models/order.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';

/// DatabaseHelper CRUD тесттері.
/// Іске қосу: flutter test test/database_helper_test.dart
void main() {
  // Тест телефонда емес, компьютерде жүреді — SQLite-ты FFI арқылы қосамыз.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = DatabaseHelper.instance;

  const abai = Book(
    id: '2',
    title: 'Абай жолы (1-том)',
    author: 'Мұхтар Әуезов',
    price: 3500,
    rating: 5.0,
    reviewsCount: 3210,
    imagePath: 'https://example.com/abai.jpg',
    synopsis: 'Роман-эпопея',
    category: 'Роман-эпопея',
    tags: ['Классика', 'Абайтану'],
  );

  const ulpan = Book(
    id: '5',
    title: 'Ұлпан',
    author: 'Ғабит Мүсірепов',
    price: 2800,
    rating: 4.8,
    reviewsCount: 860,
    imagePath: '',
    synopsis: 'Роман',
    category: 'Роман',
    tags: ['Классика'],
  );

  setUp(() async => db.deleteDatabaseFile()); // әр тест таза дерекқордан басталады
  tearDownAll(() async => db.close());

  test('4 кесте жасалады және бос болады', () async {
    final counts = await db.tableCounts();
    expect(counts, {
      'cart_items': 0,
      'favorites': 0,
      'orders': 0,
      'products_cache': 0,
    });
  });

  test('Singleton: instance әрқашан бір объект', () {
    expect(identical(DatabaseHelper.instance, DatabaseHelper.instance), isTrue);
  });

  test('Себет: Create → Read → Update → Delete', () async {
    // CREATE
    await db.upsertCartItem(abai, 1);
    await db.upsertCartItem(ulpan, 2);

    // READ
    var items = await db.getCartItems();
    expect(items.length, 2);
    expect(items.first.book.title, 'Абай жолы (1-том)');
    expect(items.first.book.tags, ['Классика', 'Абайтану']);

    // UPDATE
    await db.updateCartQuantity('2', 5);
    items = await db.getCartItems();
    expect(items.firstWhere((i) => i.book.id == '2').quantity, 5);

    // DELETE
    await db.deleteCartItem('5');
    expect((await db.getCartItems()).length, 1);

    await db.clearCart();
    expect(await db.getCartItems(), isEmpty);
  });

  test('Таңдаулылар: қайталап қосу дубликат жасамайды', () async {
    await db.insertFavorite(abai);
    await db.insertFavorite(abai);
    expect((await db.getFavorites()).length, 1);

    await db.deleteFavorite('2');
    expect(await db.getFavorites(), isEmpty);
  });

  test('Тапсырыс: себеттен жасалады және сақталады', () async {
    final order = OrderRecord.fromCart([
      CartItem(book: abai, quantity: 2),
      CartItem(book: ulpan),
    ]);
    final id = await db.insertOrder(order);
    expect(id, greaterThan(0));

    final orders = await db.getOrders();
    expect(orders.length, 1);
    expect(orders.first.total, 3500 * 2 + 2800);
    expect(orders.first.itemCount, 3);
    expect(orders.first.lines.map((l) => l.title), ['Абай жолы (1-том)', 'Ұлпан']);
  });

  test('Кэш: тізім толық ауыстырылады және реті сақталады', () async {
    await db.replaceBooksCache([abai, ulpan]);
    await db.replaceBooksCache([ulpan, abai]); // екінші жүктеу ескісін алмастырады

    final cached = await db.getCachedBooks();
    expect(cached.map((b) => b.id), ['5', '2']);
  });
}
