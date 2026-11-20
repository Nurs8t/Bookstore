import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/blocs/cart/cart_bloc.dart';
import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/models/cart_item.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';

/// Event-driven CartBloc: оқиғалар → күйлер, және SQLite-та сақталуы.
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

  CartBloc build() => CartBloc(db: db);

  test('Бастапқы күй — бос себет', () {
    final state = build().state;
    expect(state.items, isEmpty);
    expect(state.totalPrice, 0);
    expect(state.count, 0);
  });

  blocTest<CartBloc, CartState>(
    'AddProductEvent: жаңа кітап қосылады, қайта қосса — саны артады',
    build: build,
    act: (bloc) => bloc
      ..add(AddProductEvent(abai))
      ..add(AddProductEvent(ulpan))
      ..add(AddProductEvent(abai)),
    expect: () => [
      CartState.fromItems([CartItem(book: abai)]),
      CartState.fromItems([CartItem(book: abai), CartItem(book: ulpan)]),
      CartState.fromItems([CartItem(book: abai, quantity: 2), CartItem(book: ulpan)]),
    ],
    verify: (bloc) {
      expect(bloc.state.totalPrice, 3500 * 2 + 2800);
      expect(bloc.state.count, 3);
    },
  );

  blocTest<CartBloc, CartState>(
    'RemoveProductEvent: тек сол кітап өшеді',
    build: build,
    seed: () => CartState.fromItems([CartItem(book: abai), CartItem(book: ulpan)]),
    act: (bloc) => bloc.add(const RemoveProductEvent('2')),
    expect: () => [
      CartState.fromItems([CartItem(book: ulpan)]),
    ],
  );

  blocTest<CartBloc, CartState>(
    'DecrementProductEvent: 2 → 1 → себеттен шығады',
    build: build,
    seed: () => CartState.fromItems([CartItem(book: abai, quantity: 2)]),
    act: (bloc) => bloc
      ..add(const DecrementProductEvent('2'))
      ..add(const DecrementProductEvent('2')),
    expect: () => [
      CartState.fromItems([CartItem(book: abai)]),
      const CartState.empty(),
    ],
  );

  blocTest<CartBloc, CartState>(
    'ClearCartEvent: себет босайды',
    build: build,
    seed: () => CartState.fromItems([CartItem(book: abai), CartItem(book: ulpan)]),
    act: (bloc) => bloc.add(const ClearCartEvent()),
    expect: () => [const CartState.empty()],
  );

  test('Себет SQLite-та сақталады: жаңа CartBloc LoadCartEvent арқылы қалпына келтіреді', () async {
    final first = build()
      ..add(AddProductEvent(abai))
      ..add(AddProductEvent(abai))
      ..add(AddProductEvent(ulpan));
    await first.stream.take(3).last; // 3 оқиға өңделгенше күтеміз
    await db.getCartItems(); // фондағы SQLite жазулары аяқталсын
    await first.close();

    final reopened = build()..add(const LoadCartEvent());
    await reopened.stream.first;
    expect(reopened.state.count, 3);
    expect(reopened.state.totalPrice, 3500 * 2 + 2800);
    await reopened.close();
  });
}
