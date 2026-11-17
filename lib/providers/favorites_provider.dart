import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/database_helper.dart';

/// Таңдаулы кітаптар. Жадта тұрады және SQLite-тағы `favorites` кестесіне жазылады,
/// сондықтан қолданбаны жауып ашқанда сақталып тұрады.
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;
  final List<Book> _books = [];

  List<Book> get books => List.unmodifiable(_books);

  int get count => _books.length;

  bool isFavorite(Book book) => _books.contains(book);

  /// Қолданба іске қосылғанда бір рет шақырылады (main.dart).
  Future<void> load() async {
    try {
      final saved = await _db.getFavorites();
      for (final book in saved) {
        if (!_books.contains(book)) _books.add(book);
      }
    } catch (e) {
      debugPrint('Таңдаулыларды дерекқордан жүктеу мүмкін болмады: $e');
    }
    notifyListeners();
  }

  void toggle(Book book) {
    if (_books.contains(book)) {
      _books.remove(book);
      notifyListeners();
      _save(() => _db.deleteFavorite(book.id));
    } else {
      _books.add(book);
      notifyListeners();
      _save(() => _db.insertFavorite(book));
    }
  }

  /// UI-ды күттірмей жазу. Қате болса — тізім жадта жұмыс істей береді.
  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Таңдаулыларды дерекқорға сақтау мүмкін болмады: $e');
    }
  }
}
