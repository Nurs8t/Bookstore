import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/providers/favorites_provider.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';

/// Таңдаулылардың SQLite-та сақталуы. "Қайта ашу" = жаңа провайдер + load().
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = DatabaseHelper.instance..databasePathOverride = inMemoryDatabasePath;

  Book book(String id, String title) => Book(
        id: id,
        title: title,
        author: '',
        price: 1000,
        rating: 4.5,
        reviewsCount: 1,
        imagePath: '',
        synopsis: '',
        category: 'Роман',
        tags: const [],
      );

  final abai = book('2', 'Абай жолы (1-том)');
  final ulpan = book('5', 'Ұлпан');

  Future<FavoritesProvider> reopen() async {
    final favorites = FavoritesProvider(db: db);
    await favorites.load();
    return favorites;
  }

  setUp(() async => db.deleteDatabaseFile());
  tearDownAll(() async => db.close());

  test('Таңдаулылар қайта ашқанда сақталып тұрады', () async {
    final favorites = await reopen();
    favorites.toggle(abai);
    favorites.toggle(ulpan);
    await db.getFavorites(); // фондағы жазулардың аяқталуын күту

    final reopened = await reopen();
    expect(reopened.count, 2);
    expect(reopened.isFavorite(abai), isTrue);
    expect(reopened.books.map((b) => b.title), ['Абай жолы (1-том)', 'Ұлпан']);
  });

  test('Қайта басқанда таңдаулыдан алынады және дерекқордан да өшеді', () async {
    final favorites = await reopen();
    favorites.toggle(abai);
    favorites.toggle(abai);
    await db.getFavorites();

    final reopened = await reopen();
    expect(reopened.count, 0);
  });
}
