import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

/// Кіру күйінің машинасы (Cubit):
///
///   AuthInitial ──login()──▶ AuthLoading ──┬──▶ AuthSuccess(username, email)
///                                          └──▶ AuthError(message)
///   AuthSuccess ──logout()──▶ AuthInitial
///
/// Cubit — оқиғасыз (event) жеңіл BLoC: UI әдісті тікелей шақырады,
/// Cubit emit() арқылы жаңа күй шығарады.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({this.delay = const Duration(milliseconds: 1500)}) : super(const AuthInitial());

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

    if (cleanEmail == demoEmail && password == demoPassword) {
      emit(AuthSuccess(username: _usernameFrom(cleanEmail), email: cleanEmail));
    } else {
      emit(const AuthError('Email немесе құпиясөз қате'));
    }
  }

  void logout() => emit(const AuthInitial());

  /// student@narxoz.kz → Student
  static String _usernameFrom(String email) {
    final name = email.split('@').first;
    return name.isEmpty ? email : name[0].toUpperCase() + name.substring(1);
  }
}
