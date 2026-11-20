import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/cart/cart_bloc.dart';
import '../providers/favorites_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'registration_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final favCount = context.watch<FavoritesProvider>().count;
    final ordersCount = context.watch<OrdersProvider>().count;
    final cart = context.watch<CartBloc>().state;
    // AuthCubit күйі: AuthSuccess болса — кірген аккаунт.
    final authState = context.watch<AuthCubit>().state;
    final account = authState is AuthSuccess ? authState : null;
    final isSignedIn = user != null || account != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.brown.shade300,
                  foregroundImage: const AssetImage('assets/123.jpeg'),
                  onForegroundImageError: (_, __) {},
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.fullName ?? account?.username ?? 'Қонақ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? account?.email ?? 'Тіркелмеген қолданушы',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (user != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Chip(
                    avatar:
                        Icon(user.role.icon, size: 18, color: context.accent),
                    label: Text(user.role.label),
                    backgroundColor: Colors.brown.shade50,
                    side: BorderSide.none,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite,
                      value: '$favCount',
                      label: 'Таңдаулы',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shopping_bag,
                      value: '${cart.count}',
                      label: 'Себетте',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.payments,
                      value: formatPrice(cart.totalPrice),
                      label: 'Сомасы',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (user == null)
                FilledButton.icon(
                  onPressed: () => _openRegistration(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Тіркелу'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 8),
              Card(
                color: context.surfaceCard,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    if (user != null)
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Профильді өңдеу'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openRegistration(context),
                      ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Тапсырыстар тарихы'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ordersCount > 0)
                            Badge(
                              label: Text('$ordersCount'),
                              backgroundColor: AppTheme.primary,
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrdersScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Баптаулар мен жазбалар'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    if (account == null)
                      ListTile(
                        leading: const Icon(Icons.login),
                        title: const Text('Аккаунтқа кіру'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                      ),
                    if (isSignedIn)
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.red.shade400),
                        title: Text('Шығу',
                            style: TextStyle(color: Colors.red.shade400)),
                        onTap: () {
                          context.read<UserProvider>().logout();
                          context.read<AuthCubit>().logout();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: context.accent),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
