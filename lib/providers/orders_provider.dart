import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/database_helper.dart';

/// Тапсырыстар тарихы. SQLite-тағы `orders` кестесінен оқиды және оған жазады.
class OrdersProvider extends ChangeNotifier {
  OrdersProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;
  final List<OrderRecord> _orders = [];

  /// Ең жаңа тапсырыс бірінші.
  List<OrderRecord> get orders => List.unmodifiable(_orders);

  int get count => _orders.length;

  /// Барлық тапсырыстардың жалпы сомасы.
  int get totalSpent => _orders.fold(0, (sum, o) => sum + o.total);

  /// Қолданба іске қосылғанда бір рет (main.dart).
  Future<void> load() async {
    try {
      final saved = await _db.getOrders();
      _orders
        ..clear()
        ..addAll(saved);
    } catch (e) {
      debugPrint('Тапсырыстарды оқу мүмкін болмады: $e');
    }
    notifyListeners();
  }

  /// Себеттен тапсырыс жасап, дерекқорға жазады.
  /// Тапсырыс маңызды дерек, сондықтан бұл жерде жазуды КҮТЕМІЗ (await):
  /// сақталмаса — қате UI-ға жетеді, себет тазаланбайды.
  Future<OrderRecord> placeOrder(List<CartItem> items) async {
    final order = OrderRecord.fromCart(items);
    final id = await _db.insertOrder(order);
    final saved = order.withId(id);
    _orders.insert(0, saved);
    notifyListeners();
    return saved;
  }
}
