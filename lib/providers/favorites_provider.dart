import 'package:flutter/foundation.dart';

import '../models/book.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<Book> _books = [];

  List<Book> get books => List.unmodifiable(_books);

  int get count => _books.length;

  bool isFavorite(Book book) => _books.contains(book);

  void toggle(Book book) {
    if (_books.contains(book)) {
      _books.remove(book);
    } else {
      _books.add(book);
    }
    notifyListeners();
  }
}
