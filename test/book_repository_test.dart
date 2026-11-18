import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/repositories/book_repository.dart';
import 'package:kazakh_book_shop/services/book_api_service.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';

/// Офлайн кэш: интернет бар → API + кэшке жазу; интернет жоқ → кэштен оқу.
/// Желіні MockClient арқылы "өшіріп-қосамыз".
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = DatabaseHelper.instance..databasePathOverride = inMemoryDatabasePath;

  final booksJson = jsonEncode([
    {'id': 1, 'title': 'Махаббат, қызық мол жылдар', 'price': 3000, 'rating': {'rate': 4.9, 'count': 1420}},
    {'id': 2, 'title': 'Абай жолы (1-том)', 'price': 3500.0, 'rating': {'rate': 5, 'count': 3210}},
  ]);

  /// Интернет бар: сервер 200 және JSON қайтарады.
  BookRepository online() => BookRepository(
        db: db,
        api: BookApiService(
          client: MockClient((_) async => http.Response.bytes(
                utf8.encode(booksJson),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              )),
        ),
      );

  /// Интернет жоқ (ұшақ режимі): байланыс қатесі.
  BookRepository offline() => BookRepository(
        db: db,
        api: BookApiService(
          client: MockClient((_) async => throw http.ClientException('No internet')),
        ),
      );

  setUp(() async => db.deleteDatabaseFile());
  tearDownAll(() async => db.close());

  test('Онлайн: кітаптар API-дан келеді және кэшке жазылады', () async {
    final result = await online().getBooks();

    expect(result.fromCache, isFalse);
    expect(result.books.length, 2);
    expect((await db.getCachedBooks()).length, 2);
  });

  test('Офлайн, кэш бар: кітаптар кэштен көрсетіледі', () async {
    await online().getBooks(); // алдымен интернетпен бір рет жүктелді

    final result = await offline().getBooks();
    expect(result.fromCache, isTrue);
    expect(result.books.map((b) => b.title), ['Махаббат, қызық мол жылдар', 'Абай жолы (1-том)']);
    expect(result.cachedAt, isNotNull);
    expect(result.errorMessage, contains('Интернет'));
  });

  test('Офлайн, кэш бос: ApiException (қате экраны)', () async {
    await expectLater(offline().getBooks(), throwsA(isA<ApiException>()));
  });
}
