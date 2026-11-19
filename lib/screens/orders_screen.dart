import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

/// Тапсырыстар тарихы: SQLite-та сақталған барлық тапсырыстар, ең жаңасы жоғарыда.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();
    final orders = provider.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Тапсырыстар тарихы')),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Тапсырыс әлі жоқ',
              message: 'Себетке кітап қосып, «Рәсімдеу» батырмасын басыңыз — тапсырыс осында сақталады.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => index == 0
                      ? _Summary(count: provider.count, total: provider.totalSpent)
                      : _OrderCard(order: orders[index - 1]),
                ),
              ),
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int count;
  final int total;

  const _Summary({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count тапсырыс',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text('Барлығы', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatPrice(total),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderRecord order;

  const _OrderCard({required this.order});

  String _date(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}.${t.year}, ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: Colors.brown.shade50,
          child: Text(
            '№${order.id ?? '-'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
        ),
        title: Text(
          '${order.itemCount} кітап',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_date(order.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
        trailing: Text(
          formatPrice(order.total),
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...order.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${line.quantity} × ${formatPrice(line.price)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Text(formatPrice(line.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
