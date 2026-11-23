import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/blocs/favorites/favorites_cubit.dart';
import 'package:kazakh_book_shop/blocs/orders/orders_cubit.dart';
import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/models/cart_item.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';

/// FavoritesCubit және OrdersCubit: күйлер және SQLite-та сақталуы.
/// "Қайта ашу" = жаңа Cubit жасап, load() шақыру.
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

  setUp(() async => db.deleteDatabaseFile());
  tearDownAll(() async => db.close());

  group('FavoritesCubit', () {
    blocTest<FavoritesCubit, FavoritesState>(
      'toggle: қосу → қосу → алып тастау',
      build: () => FavoritesCubit(db: db),
      act: (cubit) async {
        await cubit.toggle(abai);
        await cubit.toggle(ulpan);
        await cubit.toggle(abai);
      },
      expect: () => [
        FavoritesState([abai]),
        FavoritesState([abai, ulpan]),
        FavoritesState([ulpan]),
      ],
    );

    test('Таңдаулылар қайта ашқанда сақталып тұрады', () async {
      final first = FavoritesCubit(db: db);
      await first.toggle(abai);
      await first.toggle(ulpan);
      await first.close();

      final reopened = FavoritesCubit(db: db);
      await reopened.load();
      expect(reopened.state.count, 2);
      expect(reopened.state.isFavorite(abai), isTrue);
      await reopened.close();
    });
  });

  group('OrdersCubit', () {
    test('Тапсырыс сақталады, id алады және қайта ашқанда тұрады', () async {
      final orders = OrdersCubit(db: db);
      final order = await orders.placeOrder([
        CartItem(book: abai, quantity: 2),
        CartItem(book: ulpan),
      ]);

      expect(order.id, isNotNull);
      expect(order.total, 3500 * 2 + 2800);
      expect(orders.state.count, 1);
      await orders.close();

      final reopened = OrdersCubit(db: db);
      await reopened.load();
      expect(reopened.state.count, 1);
      expect(reopened.state.orders.first.itemCount, 3);
      await reopened.close();
    });

    test('Ең жаңа тапсырыс бірінші, жалпы сома есептеледі', () async {
      final orders = OrdersCubit(db: db);
      await orders.placeOrder([CartItem(book: abai)]);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await orders.placeOrder([CartItem(book: ulpan)]);

      expect(orders.state.orders.map((o) => o.lines.first.title).toList(), ['Ұлпан', 'Абай жолы (1-том)']);
      expect(orders.state.totalSpent, 3500 + 2800);
      await orders.close();
    });
  });
}
