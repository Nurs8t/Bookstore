import 'package:equatable/equatable.dart';

import 'book.dart';

/// Себеттегі бір позиция: кітап + саны.
/// Өзгермейтін (immutable): санын өзгерту үшін жаңа объект жасаймыз (copyWith).
/// Equatable — екі CartItem өрістері бірдей болса, тең саналады (BLoC күйлерін салыстыру үшін).
class CartItem extends Equatable {
  final Book book;
  final int quantity;

  const CartItem({required this.book, this.quantity = 1});

  int get subtotal => book.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(book: book, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [book, quantity];
}
