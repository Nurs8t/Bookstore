import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'registration_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  void _comingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
          SnackBar(content: Text('«$title» келесі нұсқада қосылады')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final favCount = context.watch<FavoritesProvider>().count;
    final cart = context.watch<CartProvider>();

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
                user?.fullName ?? 'Қонақ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Тіркелмеген қолданушы',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (user != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Chip(
                    avatar:
                        Icon(user.role.icon, size: 18, color: AppTheme.primary),
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
                      value: '${cart.totalQuantity}',
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
                color: Colors.white,
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
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _comingSoon(context, 'Тапсырыстар тарихы'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Баптаулар'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _comingSoon(context, 'Баптаулар'),
                    ),
                    if (user != null)
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.red.shade400),
                        title: Text('Шығу',
                            style: TextStyle(color: Colors.red.shade400)),
                        onTap: () => context.read<UserProvider>().logout(),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary),
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
