part of 'auth_cubit.dart';

/// Кіру процесінің күйлері. Барлығы өзгермейтін (immutable) және Equatable:
/// бірдей өрістері бар екі күй тең саналады, сондықтан BLoC артық қайта сызбайды.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Бастапқы күй: форма бос, ешкім кірмеген.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Сервер жауабын күтіп тұрмыз (батырма орнында спиннер).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Сәтті кірді.
final class AuthSuccess extends AuthState {
  final String username;
  final String email;

  const AuthSuccess({required this.username, required this.email});

  @override
  List<Object?> get props => [username, email];
}

/// Қате: email немесе құпиясөз дұрыс емес.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
