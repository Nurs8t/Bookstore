import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/account_store.dart';
import '../../services/session_store.dart';

part 'auth_state.dart';

/// Кіру күйінің машинасы (Cubit):
///
///   AuthInitial ──login()──▶ AuthLoading ──┬──▶ AuthSuccess(username, email)
///                                          └──▶ AuthError(message)
///   AuthSuccess ──logout()──▶ AuthInitial
///
/// Кіруге тек тіркелу формасында жасалған аккаунттармен болады
/// (AccountStore: құпиясөздің тұзды хэші).
///
/// Cubit — оқиғасыз (event) жеңіл BLoC: UI әдісті тікелей шақырады,
/// Cubit emit() арқылы жаңа күй шығарады.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    this.delay = const Duration(milliseconds: 1500),
    AccountStore? accounts,
    SessionStore? sessions,
    Session? restoredSession,
  })  : _accounts = accounts ?? AccountStore(),
        _sessions = sessions ?? SessionStore(),
        // main() ішінде Keychain/KeyStore-дан оқылған сессия болса — бірден кірген күйде.
        super(restoredSession == null
            ? const AuthInitial()
            : AuthSuccess(username: restoredSession.username, email: restoredSession.email));

  final AccountStore _accounts;
  final SessionStore _sessions;

  /// Сервер сұранысының симуляциясы (тесттерде қысқартуға болады).
  final Duration delay;

  Future<void> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // Бос өрістерді форма өзі тексереді (validator). Мұнда әрқашан
    // Loading → Success/Error реті: екі бірдей AuthError қатар келсе,
    // Equatable оларды тең санап, екіншісін шығармас еді (SnackBar көрінбейді).
    emit(const AuthLoading());
    await Future<void>.delayed(delay); // "желі" кідірісі

    // Тіркелген аккаунт: құпиясөздің хэшін сақталған хэшпен салыстырамыз
    String? name;
    try {
      name = await _accounts.verify(cleanEmail, password);
    } catch (e) {
      debugPrint('Аккаунтты тексеру мүмкін болмады: $e');
    }

    if (name != null) {
      await _saveSession(cleanEmail, name);
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
    await _saveSession(cleanEmail, fullName.trim());
    emit(AuthSuccess(username: fullName.trim(), email: cleanEmail));
  }

  /// Шығу: шифрланған қоймадағы токенді өшіреміз.
  Future<void> logout() async {
    try {
      await _sessions.clear();
    } catch (e) {
      debugPrint('Сессияны өшіру мүмкін болмады: $e');
    }
    emit(const AuthInitial());
  }

  /// Сессия токенін Keychain/KeyStore-ға жазу. Қойма қолжетімсіз болса,
  /// кіру бәрібір сәтті — тек келесі жолы қайта кіру керек болады.
  Future<void> _saveSession(String email, String username) async {
    try {
      await _sessions.create(email: email, username: username);
    } catch (e) {
      debugPrint('Сессияны сақтау мүмкін болмады: $e');
    }
  }
}
