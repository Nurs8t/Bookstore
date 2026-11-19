import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/models/cart_item.dart';
import 'package:kazakh_book_shop/providers/orders_provider.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';

/// Тапсырыстар тарихының SQLite-та сақталуы.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = DatabaseHelper.instance..databasePathOverride = inMemoryDatabasePath;

  Book book(String id, String title, int price) => Book(
        id: id,
        title: title,
        author: '',
        price: price,
        rating: 4.5,
        reviewsCount: 1,
        imagePath: '',
        synopsis: '',
        category: 'Роман',
        tags: const [],
      );

  final abai = book('2', 'Абай жолы (1-том)', 3500);
  final ulpan = book('5', 'Ұлпан', 2800);

  Future<OrdersProvider> reopen() async {
    final orders = OrdersProvider(db: db);
    await orders.load();
    return orders;
  }

  setUp(() async => db.deleteDatabaseFile());
  tearDownAll(() async => db.close());

  test('Тапсырыс сақталады, id алады және қайта ашқанда тұрады', () async {
    final orders = await reopen();
    final order = await orders.placeOrder([
      CartItem(book: abai, quantity: 2),
      CartItem(book: ulpan),
    ]);

    expect(order.id, isNotNull);
    expect(order.total, 3500 * 2 + 2800);
    expect(orders.count, 1);

    final reopened = await reopen();
    expect(reopened.count, 1);
    expect(reopened.orders.first.itemCount, 3);
    expect(reopened.orders.first.lines.first.subtotal, 7000);
  });

  test('Ең жаңа тапсырыс бірінші тұрады, жалпы сома есептеледі', () async {
    final orders = await reopen();
    await orders.placeOrder([CartItem(book: abai)]);
    await Future<void>.delayed(const Duration(milliseconds: 5)); // уақыт белгісі әртүрлі болсын
    await orders.placeOrder([CartItem(book: ulpan)]);

    final reopened = await reopen();
    expect(reopened.orders.map((o) => o.lines.first.title), ['Ұлпан', 'Абай жолы (1-том)']);
    expect(reopened.totalSpent, 3500 + 2800);
  });
}
