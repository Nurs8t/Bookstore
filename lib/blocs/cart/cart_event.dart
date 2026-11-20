part of 'cart_bloc.dart';

/// Себетке келетін оқиғалар (events). UI тек «не болды» дейді,
/// «қалай өзгерту керек» — CartBloc-тың ісі.
sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Қолданба ашылғанда сақталған себетті SQLite-тан жүктеу.
final class LoadCartEvent extends CartEvent {
  const LoadCartEvent();
}

/// Кітапты қосу (бар болса — саны +1).
final class AddProductEvent extends CartEvent {
  final Book product;

  const AddProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

/// Кітапты себеттен толық алып тастау.
final class RemoveProductEvent extends CartEvent {
  final String productId;

  const RemoveProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Санын 1-ге азайту (1 болса — алып тастау).
final class DecrementProductEvent extends CartEvent {
  final String productId;

  const DecrementProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Себетті толық тазалау.
final class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}
