import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/blocs/catalog/catalog_bloc.dart';
import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/repositories/book_repository.dart';
import 'package:kazakh_book_shop/services/book_api_service.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';

/// CatalogBloc: Fetch / Refresh / Filter / Remove / Restore оқиғалары.
/// Интернетті MockClient арқылы "қосып-өшіреміз".
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = DatabaseHelper.instance..databasePathOverride = inMemoryDatabasePath;

  final booksJson = jsonEncode([
    {'id': 1, 'title': 'Махаббат, қызық мол жылдар', 'price': 3000, 'category': 'Роман'},
    {'id': 2, 'title': 'Абай жолы (1-том)', 'price': 3500, 'category': 'Роман-эпопея'},
    {'id': 5, 'title': 'Ұлпан', 'price': 2800, 'category': 'Роман'},
  ]);

  BookRepository online() => BookRepository(
        db: db,
        api: BookApiService(
          client: MockClient((_) async => http.Response.bytes(utf8.encode(booksJson), 200)),
        ),
      );

  BookRepository offline() => BookRepository(
        db: db,
        api: BookApiService(
          client: MockClient((_) async => throw http.ClientException('No internet')),
        ),
      );

  setUp(() async => db.deleteDatabaseFile());
  tearDownAll(() async => db.close());

  test('Бастапқы күй — CatalogLoading', () {
    expect(CatalogBloc(repository: online()).state, const CatalogLoading());
  });

  blocTest<CatalogBloc, CatalogState>(
    'Fetch, интернет бар: Loading → Loaded (3 кітап)',
    build: () => CatalogBloc(repository: online()),
    act: (bloc) => bloc.add(const FetchBooksEvent()),
    wait: const Duration(milliseconds: 300),
    expect: () => [
      const CatalogLoading(),
      isA<CatalogLoaded>()
          .having((s) => s.books.length, 'кітаптар саны', 3)
          .having((s) => s.isOffline, 'офлайн', false),
    ],
  );

  blocTest<CatalogBloc, CatalogState>(
    'Fetch, интернет жоқ және кэш бос: Loading → Error',
    build: () => CatalogBloc(repository: offline()),
    act: (bloc) => bloc.add(const FetchBooksEvent()),
    wait: const Duration(milliseconds: 300),
    expect: () => [
      const CatalogLoading(),
      isA<CatalogError>().having((s) => s.message, 'хабар', contains('Интернет')),
    ],
  );

  test('Fetch, интернет жоқ, бірақ кэш бар: офлайн режимде Loaded', () async {
    await online().getBooks(); // бір рет интернетпен жүктеліп, кэшке жазылды

    final bloc = CatalogBloc(repository: offline())..add(const FetchBooksEvent());
    final loaded = await bloc.stream.firstWhere((s) => s is CatalogLoaded) as CatalogLoaded;

    expect(loaded.isOffline, isTrue);
    expect(loaded.books.length, 3);
    expect(loaded.cachedAt, isNotNull);
    await bloc.close();
  });

  test('Refresh сәтсіз: тізім қалады, бір реттік хабар (notice) шығады', () async {
    await online().getBooks();
    final bloc = CatalogBloc(repository: offline())..add(const FetchBooksEvent());
    final first = await bloc.stream.firstWhere((s) => s is CatalogLoaded) as CatalogLoaded;

    final completer = Completer<void>();
    bloc.add(RefreshBooksEvent(completer: completer));
    await completer.future; // RefreshIndicator дәл осылай күтеді

    final after = bloc.state as CatalogLoaded;
    expect(after.books.length, 3);
    expect(after.notice, isNotNull);
    expect(after.noticeId, first.noticeId + 1);
    await bloc.close();
  });

  blocTest<CatalogBloc, CatalogState>(
    'FilterCategoryEvent: тек «Роман» санатындағы кітаптар',
    build: () => CatalogBloc(repository: online()),
    seed: () => CatalogLoaded(books: _books()),
    act: (bloc) => bloc.add(const FilterCategoryEvent('Роман')),
    expect: () => [
      isA<CatalogLoaded>()
          .having((s) => s.selectedCategory, 'санат', 'Роман')
          .having((s) => s.visibleBooks.length, 'көрінетін', 2)
          .having((s) => s.categories, 'санаттар', ['Барлығы', 'Роман', 'Роман-эпопея']),
    ],
  );

  blocTest<CatalogBloc, CatalogState>(
    'RemoveBookEvent → RestoreBookEvent: кітап өз орнына қайтады (UNDO)',
    build: () => CatalogBloc(repository: online()),
    seed: () => CatalogLoaded(books: _books()),
    act: (bloc) {
      final abai = _books()[1];
      bloc
        ..add(const RemoveBookEvent('2'))
        ..add(RestoreBookEvent(abai, 1));
    },
    expect: () => [
      isA<CatalogLoaded>().having((s) => s.books.map((b) => b.id).toList(), 'id', ['1', '5']),
      isA<CatalogLoaded>().having((s) => s.books.map((b) => b.id).toList(), 'id', ['1', '2', '5']),
    ],
  );

  blocTest<CatalogBloc, CatalogState>(
    'Сүзгідегі санаттың соңғы кітабы өшсе — «Барлығы»-ға оралады',
    build: () => CatalogBloc(repository: online()),
    seed: () => CatalogLoaded(books: _books(), selectedCategory: 'Роман-эпопея'),
    act: (bloc) => bloc.add(const RemoveBookEvent('2')),
    expect: () => [
      isA<CatalogLoaded>().having((s) => s.selectedCategory, 'санат', 'Барлығы'),
    ],
  );

  group('Іздеу және сұрыптау', () {
    CatalogBloc build() => CatalogBloc(repository: online(), searchDebounce: Duration.zero);

    blocTest<CatalogBloc, CatalogState>(
      'Атауы бойынша іздеу (бас әріпке сезімтал емес)',
      build: build,
      seed: () => CatalogLoaded(books: _shelf()),
      act: (bloc) => bloc.add(const SearchBooksEvent('АБАЙ')),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<CatalogLoaded>()
            .having((s) => s.isSearching, 'іздеу', true)
            .having((s) => s.visibleBooks.map((b) => b.id).toList(), 'id', ['2']),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'Автор бойынша іздеу',
      build: build,
      seed: () => CatalogLoaded(books: _shelf()),
      act: (bloc) => bloc.add(const SearchBooksEvent('мүсірепов')),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<CatalogLoaded>().having((s) => s.visibleBooks.map((b) => b.id).toList(), 'id', ['5']),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'Debounce: тез терілген 4 әріп → тек 1 күй (соңғы мәтін)',
      build: () => CatalogBloc(repository: online(), searchDebounce: const Duration(milliseconds: 100)),
      seed: () => CatalogLoaded(books: _shelf()),
      act: (bloc) {
        for (final q in ['А', 'Аб', 'Аба', 'Абай']) {
          bloc.add(SearchBooksEvent(q));
        }
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<CatalogLoaded>().having((s) => s.query, 'query', 'Абай'),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'Ештеңе табылмаса — visibleBooks бос, кітаптардың өзі жоғалмайды',
      build: build,
      seed: () => CatalogLoaded(books: _shelf()),
      act: (bloc) => bloc.add(const SearchBooksEvent('гарри поттер')),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<CatalogLoaded>()
            .having((s) => s.visibleBooks, 'көрінетін', isEmpty)
            .having((s) => s.books.length, 'барлығы', 3),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'Бағасы бойынша: арзаннан қымбатқа және керісінше',
      build: build,
      seed: () => CatalogLoaded(books: _shelf()),
      act: (bloc) => bloc
        ..add(const SortBooksEvent(BookSort.priceAsc))
        ..add(const SortBooksEvent(BookSort.priceDesc)),
      expect: () => [
        isA<CatalogLoaded>().having((s) => s.visibleBooks.map((b) => b.id).toList(), 'id', ['5', '1', '2']),
        isA<CatalogLoaded>().having((s) => s.visibleBooks.map((b) => b.id).toList(), 'id', ['2', '1', '5']),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'Рейтинг бойынша (жоғарыдан төменге)',
      build: build,
      seed: () => CatalogLoaded(books: _shelf()),
      act: (bloc) => bloc.add(const SortBooksEvent(BookSort.rating)),
      expect: () => [
        isA<CatalogLoaded>().having((s) => s.visibleBooks.map((b) => b.id).toList(), 'id', ['2', '5', '1']),
      ],
    );

    test('Санат + іздеу + сұрыптау бірге жұмыс істейді', () {
      final state = CatalogLoaded(
        books: _shelf(),
        selectedCategory: 'Роман',
        query: 'а',
        sort: BookSort.priceAsc,
      );
      expect(state.visibleBooks.map((b) => b.id).toList(), ['5', '1']);
    });
  });
}

List<Book> _books() => [
      _book('1', 'Махаббат, қызық мол жылдар', 'Роман'),
      _book('2', 'Абай жолы (1-том)', 'Роман-эпопея'),
      _book('5', 'Ұлпан', 'Роман'),
    ];

Book _book(String id, String title, String category) => Book(
      id: id,
      title: title,
      author: '',
      price: 1000,
      rating: 4.5,
      reviewsCount: 1,
      imagePath: '',
      synopsis: '',
      category: category,
      tags: const [],
    );

/// Іздеу/сұрыптау тесттері үшін: әртүрлі автор, баға, рейтинг.
List<Book> _shelf() => [
      const Book(
        id: '1', title: 'Махаббат, қызық мол жылдар', author: 'Әзілхан Нұршайықов',
        price: 3000, rating: 4.6, reviewsCount: 1, imagePath: '', synopsis: '',
        category: 'Роман', tags: const [],
      ),
      const Book(
        id: '2', title: 'Абай жолы (1-том)', author: 'Мұхтар Әуезов',
        price: 3500, rating: 5.0, reviewsCount: 1, imagePath: '', synopsis: '',
        category: 'Роман-эпопея', tags: const [],
      ),
      const Book(
        id: '5', title: 'Ұлпан', author: 'Ғабит Мүсірепов',
        price: 2800, rating: 4.8, reviewsCount: 1, imagePath: '', synopsis: '',
        category: 'Роман', tags: const [],
      ),
    ];
