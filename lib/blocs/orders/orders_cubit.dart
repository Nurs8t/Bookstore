import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../services/database_helper.dart';

/// Тапсырыстар тарихының күйі (ең жаңасы бірінші).
final class OrdersState extends Equatable {
  final List<OrderRecord> orders;

  const OrdersState([this.orders = const []]);

  int get count => orders.length;

  int get totalSpent => orders.fold(0, (sum, o) => sum + o.total);

  @override
  List<Object?> get props => [orders];
}

/// Тапсырыстар (Cubit). SQLite-тағы `orders` кестесінен оқиды және оған жазады.
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        super(const OrdersState());

  final DatabaseHelper _db;

  /// Қолданба іске қосылғанда бір рет (main.dart).
  Future<void> load() async {
    try {
      emit(OrdersState(List.unmodifiable(await _db.getOrders())));
    } catch (e) {
      debugPrint('Тапсырыстарды оқу мүмкін болмады: $e');
    }
  }

  /// Себеттен тапсырыс жасап, дерекқорға жазады.
  /// Тапсырыс маңызды дерек: жазу сәтсіз болса — қате шақырған жерге жетеді
  /// (себет тазаланбайды). Сондықтан мұнда try-catch жоқ.
  Future<OrderRecord> placeOrder(List<CartItem> items) async {
    final order = OrderRecord.fromCart(items);
    final id = await _db.insertOrder(order);
    final saved = order.withId(id);
    emit(OrdersState(List.unmodifiable([saved, ...state.orders])));
    return saved;
  }
}
