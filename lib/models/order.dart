import 'dart:convert';

import 'cart_item.dart';

/// Рәсімделген тапсырыс (SQLite `orders` кестесінің бір жолы).
class OrderRecord {
  final int? id; // дерекқор өзі береді (AUTOINCREMENT)
  final DateTime createdAt;
  final int total; // теңге
  final int itemCount;
  final List<OrderLine> lines;

  const OrderRecord({
    this.id,
    required this.createdAt,
    required this.total,
    required this.itemCount,
    required this.lines,
  });

  /// Дерекқор берген id-мен көшірмесі.
  OrderRecord withId(int newId) => OrderRecord(
        id: newId,
        createdAt: createdAt,
        total: total,
        itemCount: itemCount,
        lines: lines,
      );

  /// Себеттегі позициялардан жаңа тапсырыс жасау.
  factory OrderRecord.fromCart(List<CartItem> items) => OrderRecord(
        createdAt: DateTime.now(),
        total: items.fold(0, (sum, i) => sum + i.subtotal),
        itemCount: items.fold(0, (sum, i) => sum + i.quantity),
        lines: items
            .map((i) => OrderLine(
                  bookId: i.book.id,
                  title: i.book.title,
                  price: i.book.price,
                  quantity: i.quantity,
                ))
            .toList(),
      );

  /// Dart объектісі → кестедегі жол.
  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'created_at': createdAt.millisecondsSinceEpoch,
        'total': total,
        'item_count': itemCount,
        'items_json': jsonEncode(lines.map((l) => l.toMap()).toList()),
      };

  /// Кестедегі жол → Dart объектісі.
  factory OrderRecord.fromRow(Map<String, Object?> row) {
    final decoded = jsonDecode(row['items_json'] as String? ?? '[]');
    return OrderRecord(
      id: row['id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int? ?? 0),
      total: row['total'] as int? ?? 0,
      itemCount: row['item_count'] as int? ?? 0,
      lines: (decoded is List ? decoded : const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderLine.fromMap)
          .toList(),
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
