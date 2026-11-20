import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/book.dart';
import '../../models/cart_item.dart';
import '../../services/database_helper.dart';

part 'cart_event.dart';
part 'cart_state.dart';

/// Оқиғаға негізделген себет (Event-driven BLoC):
///
///   UI ──add(AddProductEvent)──▶ CartBloc ──on<AddProductEvent>──▶ emit(CartState)
///                                     └──▶ SQLite (cart_items)
///   BlocBuilder<CartBloc, CartState> ◀── жаңа күй ── барлық экрандар бірден жаңарады
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        super(const CartState.empty()) {
    on<LoadCartEvent>(_onLoad);
    on<AddProductEvent>(_onAdd);
    on<RemoveProductEvent>(_onRemove);
    on<DecrementProductEvent>(_onDecrement);
    on<ClearCartEvent>(_onClear);
  }

  final DatabaseHelper _db;

  Future<void> _onLoad(LoadCartEvent event, Emitter<CartState> emit) async {
    try {
      final saved = await _db.getCartItems();
      // Жүктеу кезінде қолданушы бірдеңе қосып үлгерсе — оны жоғалтпаймыз.
      final merged = [
        ...state.items,
        ...saved.where((s) => !state.items.any((i) => i.book.id == s.book.id)),
      ];
      emit(CartState.fromItems(merged));
    } catch (e) {
      debugPrint('Себетті жүктеу мүмкін болмады: $e');
    }
  }

  Future<void> _onAdd(AddProductEvent event, Emitter<CartState> emit) async {
    final book = event.product;
    final items = [...state.items];
    final index = items.indexWhere((i) => i.book.id == book.id);
    final CartItem updated;
    if (index == -1) {
      updated = CartItem(book: book);
      items.add(updated);
    } else {
      updated = items[index].copyWith(quantity: items[index].quantity + 1);
      items[index] = updated;
    }
    emit(CartState.fromItems(items)); // UI бірден жаңарады
    await _save(() => _db.upsertCartItem(book, updated.quantity));
  }

  Future<void> _onRemove(RemoveProductEvent event, Emitter<CartState> emit) async {
    emit(CartState.fromItems(
      state.items.where((i) => i.book.id != event.productId).toList(),
    ));
    await _save(() => _db.deleteCartItem(event.productId));
  }

  Future<void> _onDecrement(DecrementProductEvent event, Emitter<CartState> emit) async {
    final index = state.items.indexWhere((i) => i.book.id == event.productId);
    if (index == -1) return;
    final item = state.items[index];
    if (item.quantity <= 1) {
      return _onRemove(RemoveProductEvent(event.productId), emit);
    }
    final items = [...state.items];
    items[index] = item.copyWith(quantity: item.quantity - 1);
    emit(CartState.fromItems(items));
    await _save(() => _db.updateCartQuantity(event.productId, item.quantity - 1));
  }

  Future<void> _onClear(ClearCartEvent event, Emitter<CartState> emit) async {
    emit(const CartState.empty());
    await _save(_db.clearCart);
  }

  /// Дерекқор қатесі себетті бұзбайды — күй жадта жұмыс істей береді.
  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Себетті сақтау мүмкін болмады: $e');
    }
  }
}
