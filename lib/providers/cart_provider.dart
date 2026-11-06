import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);

  bool get isEmpty => _items.isEmpty;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  bool contains(Book book) => _items.containsKey(book.id);

  void add(Book book) {
    _items.update(
      book.id,
      (item) => item..quantity += 1,
      ifAbsent: () => CartItem(book: book),
    );
    notifyListeners();
  }

  void remove(Book book) {
    _items.remove(book.id);
    notifyListeners();
  }

  void toggle(Book book) => contains(book) ? remove(book) : add(book);

  void decrement(Book book) {
    final item = _items[book.id];
    if (item == null) return;
    if (item.quantity > 1) {
      item.quantity -= 1;
    } else {
      _items.remove(book.id);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
