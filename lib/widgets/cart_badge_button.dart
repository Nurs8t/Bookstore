import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../screens/cart_screen.dart';

class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().totalQuantity;

    return IconButton(
      tooltip: 'Себет',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}
