import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/book_api_service.dart';
import '../services/database_helper.dart';

/// Кітаптарды алу нәтижесі: кітаптар + олар қайдан келді.
class BooksResult {
  final List<Book> books;

  /// true — интернет жоқ, кітаптар SQLite кэшінен алынды.
  final bool fromCache;

  /// Кэш соңғы рет қашан жаңартылды (офлайн белгісінде көрсетіледі).
  final DateTime? cachedAt;

  /// Желі қатесінің хабары (тек fromCache == true болғанда).
  final String? errorMessage;

  const BooksResult({
    required this.books,
    this.fromCache = false,
    this.cachedAt,
    this.errorMessage,
  });
}

/// Repository — деректердің жалғыз кіру нүктесі.
/// UI кітаптардың қайдан келетінін (API немесе SQLite) білмейді.
///
///   1. API-дан жүктеуге тырысады → сәтті болса, кэшке жазып, қайтарады.
///   2. Желі қатесі болса → SQLite кэшінен оқиды (офлайн режим).
///   3. Кэш те бос болса → қатені UI-ға жібереді (қате экраны + «Қайта қосылу»).
class BookRepository {
  BookRepository({BookApiService? api, DatabaseHelper? db})
      : _api = api ?? BookApiService(),
        _db = db ?? DatabaseHelper.instance;

  final BookApiService _api;
  final DatabaseHelper _db;

  Future<BooksResult> getBooks() async {
    try {
      final books = await _api.fetchBooks();
      await _saveToCache(books);
      return BooksResult(books: books);
    } on ApiException catch (e) {
      final cached = await _readCache();
      if (cached.isEmpty) rethrow; // кэш бос — көрсететін ештеңе жоқ
      return BooksResult(
        books: cached,
        fromCache: true,
        cachedAt: await _safe(_db.lastCacheTime, null),
        errorMessage: e.message,
      );
    }
  }

  Future<void> _saveToCache(List<Book> books) async {
    try {
      await _db.replaceBooksCache(books);
    } catch (e) {
      // Кэшке жаза алмасақ та, API-дан келген кітаптарды көрсете береміз.
      debugPrint('Кэшке жазу мүмкін болмады: $e');
    }
  }

  Future<List<Book>> _readCache() => _safe(_db.getCachedBooks, const <Book>[]);

  /// Дерекқор қатесі қолданбаны құлатпауы үшін.
  Future<T> _safe<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('Кэшті оқу мүмкін болмады: $e');
      return fallback;
    }
  }

  void dispose() => _api.dispose();
}
