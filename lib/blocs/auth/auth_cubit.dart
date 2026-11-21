import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/account_store.dart';

part 'auth_state.dart';

/// Кіру күйінің машинасы (Cubit):
///
///   AuthInitial ──login()──▶ AuthLoading ──┬──▶ AuthSuccess(username, email)
///                                          └──▶ AuthError(message)
///   AuthSuccess ──logout()──▶ AuthInitial
///
/// Кіруге болатын аккаунттар:
///   • демо: student@narxoz.kz / 123456
///   • тіркелу формасында жасалған аккаунттар (AccountStore, құпиясөз хэші)
///
/// Cubit — оқиғасыз (event) жеңіл BLoC: UI әдісті тікелей шақырады,
/// Cubit emit() арқылы жаңа күй шығарады.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    this.delay = const Duration(milliseconds: 1500),
    AccountStore? accounts,
  })  : _accounts = accounts ?? AccountStore(),
        super(const AuthInitial());

  final AccountStore _accounts;

  /// Сервер сұранысының симуляциясы (тесттерде қысқартуға болады).
  final Duration delay;

  /// Демо тіркелгі.
  static const String demoEmail = 'student@narxoz.kz';
  static const String demoPassword = '123456';

  Future<void> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // Бос өрістерді форма өзі тексереді (validator). Мұнда әрқашан
    // Loading → Success/Error реті: екі бірдей AuthError қатар келсе,
    // Equatable оларды тең санап, екіншісін шығармас еді (SnackBar көрінбейді).
    emit(const AuthLoading());
    await Future<void>.delayed(delay); // "желі" кідірісі

    // 1) Демо аккаунт
    if (cleanEmail == demoEmail && password == demoPassword) {
      emit(AuthSuccess(username: _usernameFrom(cleanEmail), email: cleanEmail));
      return;
    }

    // 2) Тіркелген аккаунт: құпиясөздің хэшін сақталған хэшпен салыстырамыз
    String? name;
    try {
      name = await _accounts.verify(cleanEmail, password);
    } catch (e) {
      debugPrint('Аккаунтты тексеру мүмкін болмады: $e');
    }

    if (name != null) {
      emit(AuthSuccess(username: name, email: cleanEmail));
    } else {
      emit(const AuthError('Email немесе құпиясөз қате'));
    }
  }

  /// Тіркелу: аккаунтты сақтап, бірден кірген күйге өтеміз.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await _accounts.register(email: cleanEmail, password: password, fullName: fullName);
    emit(AuthSuccess(username: fullName.trim(), email: cleanEmail));
  }

  void logout() => emit(const AuthInitial());

  /// student@narxoz.kz → Student
  static String _usernameFrom(String email) {
    final name = email.split('@').first;
    return name.isEmpty ? email : name[0].toUpperCase() + name.substring(1);
  }
}
