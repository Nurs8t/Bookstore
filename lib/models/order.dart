import 'dart:convert';

import 'cart_item.dart';
import 'delivery_info.dart';

/// Рәсімделген тапсырыс (SQLite `orders` кестесінің бір жолы).
class OrderRecord {
  final int? id; // дерекқор өзі береді (AUTOINCREMENT)
  final DateTime createdAt;
  final int total; // теңге, жеткізу ақысымен бірге
  final int itemCount;
  final List<OrderLine> lines;

  /// Тапсырыс формасынан: аты, телефон, мекенжай, төлем тәсілі.
  /// Ескі (v1) тапсырыстарда null.
  final DeliveryInfo? delivery;
  final int deliveryFee;

  const OrderRecord({
    this.id,
    required this.createdAt,
    required this.total,
    required this.itemCount,
    required this.lines,
    this.delivery,
    this.deliveryFee = 0,
  });

  /// Кітаптардың өз сомасы (жеткізусіз).
  int get itemsTotal => total - deliveryFee;

  /// Дерекқор берген id-мен көшірмесі.
  OrderRecord withId(int newId) => OrderRecord(
        id: newId,
        createdAt: createdAt,
        total: total,
        itemCount: itemCount,
        lines: lines,
        delivery: delivery,
        deliveryFee: deliveryFee,
      );

  /// Себеттегі позициялардан жаңа тапсырыс жасау.
  /// [delivery] берілсе — жеткізу ақысы сомаға қосылады.
  factory OrderRecord.fromCart(List<CartItem> items, {DeliveryInfo? delivery}) {
    final itemsTotal = items.fold(0, (sum, i) => sum + i.subtotal);
    final fee = delivery == null ? 0 : DeliveryInfo.feeFor(delivery.method, itemsTotal);
    return OrderRecord(
        createdAt: DateTime.now(),
        total: itemsTotal + fee,
        itemCount: items.fold(0, (sum, i) => sum + i.quantity),
        delivery: delivery,
        deliveryFee: fee,
        lines: items
            .map((i) => OrderLine(
                  bookId: i.book.id,
                  title: i.book.title,
                  price: i.book.price,
                  quantity: i.quantity,
                ))
            .toList(),
      );
  }

  /// Dart объектісі → кестедегі жол.
  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'created_at': createdAt.millisecondsSinceEpoch,
        'total': total,
        'item_count': itemCount,
        'items_json': jsonEncode(lines.map((l) => l.toMap()).toList()),
        'delivery_json': delivery == null ? null : jsonEncode(delivery!.toMap()),
        'delivery_fee': deliveryFee,
      };

  /// Кестедегі жол → Dart объектісі.
  factory OrderRecord.fromRow(Map<String, Object?> row) {
    final decoded = jsonDecode(row['items_json'] as String? ?? '[]');
    final deliveryRaw = row['delivery_json'] as String?;
    final deliveryMap = deliveryRaw == null ? null : jsonDecode(deliveryRaw);
    return OrderRecord(
      id: row['id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int? ?? 0),
      total: row['total'] as int? ?? 0,
      itemCount: row['item_count'] as int? ?? 0,
      lines: (decoded is List ? decoded : const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderLine.fromMap)
          .toList(),
      delivery: deliveryMap is Map<String, dynamic> ? DeliveryInfo.fromMap(deliveryMap) : null,
      deliveryFee: row['delivery_fee'] as int? ?? 0,
    );
  }
}

/// Тапсырыстағы бір кітап.
class OrderLine {
  final String bookId;
  final String title;
  final int price;
  final int quantity;

  int get subtotal => price * quantity;

  const OrderLine({
    required this.bookId,
    required this.title,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'title': title,
        'price': price,
        'quantity': quantity,
      };

  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
        bookId: map['bookId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        price: (map['price'] as num? ?? 0).toInt(),
        quantity: (map['quantity'] as num? ?? 1).toInt(),
      );
}
