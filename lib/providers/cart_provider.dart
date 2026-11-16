import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/cart_item.dart';
import '../services/database_helper.dart';

/// Глобал себет. Күйі жадта (Map) тұрады, ал әр өзгеріс SQLite-қа да жазылады,
/// сондықтан қолданбаны жауып ашқанда себет сақталып тұрады.
///
/// Ағын:  UI → add/remove/clear → жад (бірден) → notifyListeners() → UI
///                                   └──→ SQLite (фонда, await)
class CartProvider extends ChangeNotifier {
  CartProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;
  final Map<String, CartItem> _items = {};

  bool _isLoaded = false;

  /// Дерекқордан жүктеу аяқталды ма (қаласаңыз, UI-да спиннер көрсетуге болады).
  bool get isLoaded => _isLoaded;

  List<CartItem> get items => List.unmodifiable(_items.values);

  bool get isEmpty => _items.isEmpty;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  bool contains(Book book) => _items.containsKey(book.id);

  // ---------- Дерекқордан жүктеу ----------

  /// Қолданба іске қосылғанда бір рет шақырылады (main.dart).
  Future<void> load() async {
    try {
      final saved = await _db.getCartItems();
      for (final item in saved) {
        // Жүктеу кезінде қолданушы бірдеңе қосып үлгерсе — оны басып жазбаймыз.
        _items.putIfAbsent(item.book.id, () => item);
      }
    } catch (e) {
      debugPrint('Себетті дерекқордан жүктеу мүмкін болмады: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  // ---------- Өзгерту әдістері ----------

  void add(Book book) {
    final item = _items.update(
      book.id,
      (item) => item..quantity += 1,
      ifAbsent: () => CartItem(book: book),
    );
    notifyListeners();
    _save(() => _db.upsertCartItem(book, item.quantity));
  }

  void remove(Book book) {
    _items.remove(book.id);
    notifyListeners();
    _save(() => _db.deleteCartItem(book.id));
  }

  void toggle(Book book) => contains(book) ? remove(book) : add(book);

  void decrement(Book book) {
    final item = _items[book.id];
    if (item == null) return;
    if (item.quantity > 1) {
      item.quantity -= 1;
      notifyListeners();
      _save(() => _db.updateCartQuantity(book.id, item.quantity));
    } else {
      remove(book);
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _save(_db.clearCart);
  }

  /// UI-ды күттірмей, өзгерісті дерекқорға жазу.
  /// Қате болса, қолданба құламайды — себет жадта жұмыс істей береді.
  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Себетті дерекқорға сақтау мүмкін болмады: $e');
    }
  }
}
