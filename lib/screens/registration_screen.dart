import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  UserRole _role = UserRole.student;
  bool _subscribed = true;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _role = user.role;
      _subscribed = user.subscribed;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Аты-жөніңізді енгізіңіз';
    if (value.trim().length < 2) return 'Аты-жөні тым қысқа';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email енгізіңіз';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email))
      return 'Дұрыс email енгізіңіз (мыс. name@narxoz.kz)';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Құпиясөз енгізіңіз';
    if (value.length < 6) return 'Құпиясөз кемінде 6 таңбадан тұруы керек';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Құпиясөзді қайталаңыз';
    if (value != _passwordController.text) return 'Құпиясөздер сәйкес келмейді';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: const Text('Форманы толтыруда қателер бар'),
          ),
        );
      return;
    }

    final profile = UserProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _role,
      subscribed: _subscribed,
    );

    debugPrint('===== ТІРКЕЛУ ДЕРЕКТЕРІ =====');
    debugPrint('Аты-жөні : ${profile.fullName}');
    debugPrint('Email    : ${profile.email}');
    debugPrint('Рөлі     : ${profile.role.label}');
    debugPrint('Жазылым  : ${profile.subscribed}');
    debugPrint('Шарттар  : $_acceptedTerms');

    context.read<UserProvider>().register(profile);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.verified, color: Colors.green, size: 48),
        title: const Text('Сәтті тіркелдіңіз!'),
        content: Text(
            'Қош келдіңіз, ${profile.fullName}!\nРөліңіз: ${profile.role.label}'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Профильге өту'),
          ),
        ],
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тіркелу')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.auto_stories,
                    size: 56, color: AppTheme.primary),
                const SizedBox(height: 8),
                const Text(
                  'Оқырман аккаунтын жасау',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Аты-жөні',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@narxoz.kz',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Құпиясөз',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Құпиясөзді растау',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: _validateConfirm,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Рөліңіз',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: UserRole.values
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.label),
                          ))
                      .toList(),
                  onChanged: (role) {
                    if (role != null) setState(() => _role = role);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Жаңа кітаптар туралы хабарлама алу'),
                  value: _subscribed,
                  onChanged: (value) => setState(() => _subscribed = value),
                ),
                FormField<bool>(
                  initialValue: _acceptedTerms,
                  validator: (value) => value == true
                      ? null
                      : 'Тіркелу үшін шарттарды қабылдауыңыз керек',
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: field.value ?? false,
                        title: const Text('Пайдалану шарттарын қабылдаймын'),
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                          field.didChange(value);
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text(
                    'Тіркелу',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
