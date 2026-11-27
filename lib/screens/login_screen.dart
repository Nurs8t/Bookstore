import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_cubit.dart';
import '../utils/app_theme.dart';
import 'registration_screen.dart';
import 'root_screen.dart';

/// Кіру экраны. BlocConsumer екі жұмысты бөледі:
///   listener — бір реттік әрекеттер (SnackBar, навигация); экранды сызбайды;
///   builder  — күйге қарай виджет сызады (батырма немесе спиннер).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(_emailController.text, _passwordController.text);
  }

  void _openCatalog() {
    // Артқа қайтқанда кіру экранына оралмау үшін бүкіл стекті ауыстырамыз.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootScreen()),
      (_) => false,
    );
  }

  /// Тіркелу экраны. Тіркелген соң AuthSuccess болады → каталогқа өтеміз.
  Future<void> _openRegistration() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
    if (!mounted) return;
    if (context.read<AuthCubit>().state is AuthSuccess) _openCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<AuthCubit, AuthState>(
                // ---------- LISTENER: бір реттік әрекеттер ----------
                // Тек осы экран көрініп тұрғанда әрекет етеміз
                // (тіркелу экраны ашық болса, ол өз диалогын көрсетеді).
                listenWhen: (_, __) => ModalRoute.of(context)?.isCurrent ?? true,
                listener: (context, state) {
                  if (state is AuthError) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red.shade700,
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(child: Text(state.message)),
                          ],
                        ),
                      ));
                  } else if (state is AuthSuccess) {
                    _openCatalog();
                  }
                },
                // ---------- BUILDER: экранды сызу ----------
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.auto_stories, size: 64, color: context.accent),
                        const SizedBox(height: 12),
                        const Text(
                          'Қазақ әдебиеті дүкені',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Аккаунтыңызға кіріңіз',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'name@narxoz.kz',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Email енгізіңіз' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Құпиясөз',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Құпиясөзді енгізіңіз' : null,
                        ),
                        const SizedBox(height: 24),
                        // AuthLoading кезінде батырманың орнына спиннер.
                        SizedBox(
                          height: 52,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : FilledButton.icon(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.login),
                                  label: const Text(
                                    'Кіру',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: isLoading ? null : _openCatalog,
                          child: const Text('Қонақ ретінде жалғастыру'),
                        ),
                        const Divider(height: 24),
                        // Wrap: тар экранда немесе үлкен қаріпте батырма келесі жолға түседі.
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Аккаунтыңыз жоқ па?',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            TextButton(
                              onPressed: isLoading ? null : _openRegistration,
                              child: const Text(
                                'Тіркелу',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
