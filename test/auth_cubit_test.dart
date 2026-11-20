import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kazakh_book_shop/blocs/auth/auth_cubit.dart';

/// AuthCubit күйлер машинасы: Initial → Loading → Success / Error.
void main() {
  AuthCubit build() => AuthCubit(delay: Duration.zero);

  test('Бастапқы күй — AuthInitial', () {
    expect(build().state, const AuthInitial());
  });

  blocTest<AuthCubit, AuthState>(
    'Дұрыс email/құпиясөз: Loading → Success',
    build: build,
    act: (cubit) => cubit.login('student@narxoz.kz', '123456'),
    expect: () => const [
      AuthLoading(),
      AuthSuccess(username: 'Student', email: 'student@narxoz.kz'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'Email бос орын мен бас әріпке сезімтал емес',
    build: build,
    act: (cubit) => cubit.login('  Student@Narxoz.kz ', '123456'),
    expect: () => const [
      AuthLoading(),
      AuthSuccess(username: 'Student', email: 'student@narxoz.kz'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'Қате құпиясөз: Loading → Error',
    build: build,
    act: (cubit) => cubit.login('student@narxoz.kz', 'wrong'),
    expect: () => const [
      AuthLoading(),
      AuthError('Email немесе құпиясөз қате'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'Қатарынан екі рет қате: SnackBar екі рет шығуы үшін әр жолы Loading арқылы өтеді',
    build: build,
    act: (cubit) async {
      await cubit.login('a@b.kz', '1');
      await cubit.login('a@b.kz', '1');
    },
    expect: () => const [
      AuthLoading(),
      AuthError('Email немесе құпиясөз қате'),
      AuthLoading(),
      AuthError('Email немесе құпиясөз қате'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'logout() → AuthInitial',
    build: build,
    seed: () => const AuthSuccess(username: 'Student', email: 'student@narxoz.kz'),
    act: (cubit) => cubit.logout(),
    expect: () => const [AuthInitial()],
  );

  test('Equatable: өрістері бірдей күйлер тең', () {
    expect(const AuthError('x'), const AuthError('x'));
    expect(const AuthError('x') == const AuthError('y'), isFalse);
  });
}
