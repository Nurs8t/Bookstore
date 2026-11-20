import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_bloc.dart';
import '../screens/cart_screen.dart';

/// AppBar-дағы тірі себет белгісі. BlocBuilder тек себет күйі өзгергенде қайта сызады;
/// buildWhen — тек дана саны өзгергенде (баға өзгерсе — қажет емес).
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) => previous.count != current.count,
      builder: (context, cart) => IconButton(
        tooltip: 'Себет',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
        icon: Badge(
          isLabelVisible: cart.count > 0,
          label: Text('${cart.count}'),
          child: const Icon(Icons.shopping_bag_outlined),
        ),
      ),
    );
  }
}
