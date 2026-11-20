part of 'cart_bloc.dart';

/// Себеттің күйі — өзгермейтін (immutable). Әр өзгерісте жаңа CartState жасалады.
/// totalPrice мен count тізімнен бір рет есептеледі (CartState.fromItems).
final class CartState extends Equatable {
  final List<CartItem> items;
  final int totalPrice;
  final int count;

  const CartState._({required this.items, required this.totalPrice, required this.count});

  /// Бос себет.
  const CartState.empty() : this._(items: const [], totalPrice: 0, count: 0);

  /// Тізімнен күй жасау: сома мен дана саны осында есептеледі.
  factory CartState.fromItems(List<CartItem> items) => CartState._(
        items: List.unmodifiable(items),
        totalPrice: items.fold(0, (sum, i) => sum + i.subtotal),
        count: items.fold(0, (sum, i) => sum + i.quantity),
      );

  bool get isEmpty => items.isEmpty;

  bool contains(Book book) => items.any((i) => i.book.id == book.id);

  /// Equatable: items, totalPrice, count бірдей болса — күй өзгермеген,
  /// BlocBuilder қайта сызбайды.
  @override
  List<Object?> get props => [items, totalPrice, count];
}
