import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/providers/cart_provider.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';

/// Себеттің SQLite-та сақталуын тексеру.
/// "Қолданбаны қайта ашу" = жаңа CartProvider жасап, load() шақыру.
void main() {
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
    imagePath: '',
    synopsis: '',
    category: 'Роман-эпопея',
    tags: [],
  );
  const ulpan = Book(
    id: '5',
    title: 'Ұлпан',
    author: 'Ғабит Мүсірепов',
    price: 2800,
    rating: 4.8,
    reviewsCount: 860,
    imagePath: '',
    synopsis: '',
    category: 'Роман',
    tags: [],
  );

  /// Фондағы жазулар аяқталуын күту: дерекқор сұраныстарды кезекпен орындайды,
  /// сондықтан кез келген оқу сұранысы алдыңғы жазулардан кейін орындалады.
  Future<void> flush() => db.getCartItems();

  /// Қолданбаны "жауып-ашу".
  Future<CartProvider> reopen() async {
    final cart = CartProvider(db: db);
    await cart.load();
    return cart;
  }

  setUp(() async => db.deleteDatabaseFile());
  tearDownAll(() async => db.close());

  test('Қосылған кітаптар қайта ашқанда сақталып тұрады', () async {
    final cart = CartProvider(db: db);
    await cart.load();
    cart.add(abai);
    cart.add(abai); // саны 2
    cart.add(ulpan);
    await flush();

    final reopened = await reopen();
    expect(reopened.totalQuantity, 3);
    expect(reopened.totalPrice, 3500 * 2 + 2800);
    expect(reopened.contains(abai), isTrue);
  });

  test('remove және decrement дерекқорға да жазылады', () async {
    final cart = await reopen();
    cart.add(abai);
    cart.add(abai);
    cart.add(ulpan);
    cart.decrement(abai); // 2 → 1
    cart.remove(ulpan);
    await flush();

    final reopened = await reopen();
    expect(reopened.items.length, 1);
    expect(reopened.items.first.quantity, 1);
    expect(reopened.contains(ulpan), isFalse);
  });

  test('clear() кейін себет бос болып ашылады', () async {
    final cart = await reopen();
    cart.add(abai);
    cart.add(ulpan);
    cart.clear();
    await flush();

    final reopened = await reopen();
    expect(reopened.isEmpty, isTrue);
  });
}
