import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/book_cover.dart';
import '../widgets/empty_state.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Себетті тазалау'),
        content: const Text(
            'Себеттегі барлық кітаптар өшіріледі. Жалғастырасыз ба?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Жоқ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Иә, тазалау')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CartProvider>().clear();
    }
  }

  Future<void> _checkout(BuildContext context, CartProvider cart) async {
    final total = formatPrice(cart.totalPrice);
    final count = cart.totalQuantity;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Тапсырыс қабылданды!'),
        content: Text('$count кітап, жалпы сомасы $total.\nРақмет!'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Жақсы')),
        ],
      ),
    );
    cart.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Себет'),
        actions: [
          if (!cart.isEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Тазалау'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Себет бос',
              message: 'Каталогтан кітап таңдап, себетке қосыңыз.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _CartItemTile(item: cart.items[index]),
                ),
              ),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Жалпы (${cart.totalQuantity} дана)',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatPrice(cart.totalPrice),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => _checkout(context, cart),
                        icon: const Icon(Icons.payment),
                        label: const Text('Рәсімдеу'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final book = item.book;

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(imagePath: book.imagePath, width: 54, height: 78),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '${book.author} · ${formatPrice(book.price)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QuantityStepper(
                        quantity: item.quantity,
                        onDecrement: () => cart.decrement(book),
                        onIncrement: () => cart.add(book),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatPrice(item.subtotal),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Себеттен өшіру',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, color: Colors.red.shade400),
              onPressed: () => cart.remove(book),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.brown.shade100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$quantity',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          _StepButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    );
  }
}
