import 'book.dart';

/// Себеттегі бір позиция: кітап + саны.
class CartItem {
  final Book book;
  int quantity;

  CartItem({required this.book, this.quantity = 1});

  int get subtotal => book.price * quantity;
}
