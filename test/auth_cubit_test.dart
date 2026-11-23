import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kazakh_book_shop/blocs/auth/auth_cubit.dart';
import 'package:kazakh_book_shop/services/account_store.dart';
import 'package:kazakh_book_shop/services/session_store.dart';

/// AuthCubit күйлер машинасы: Initial → Loading → Success / Error.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({}); // әр тест таза қоймадан
    FlutterSecureStorage.setMockInitialValues({}); // Keychain/KeyStore орнына
  });

  AuthCubit build() => AuthCubit(delay: Duration.zero);

  test('Бастапқы күй — AuthInitial', () {
    expect(build().state, const AuthInitial());
  });

  /// Тест алдында аккаунт тіркеп қоямыз (демо аккаунт жоқ).
  Future<void> seedAccount() => AccountStore().register(
        email: 'student@narxoz.kz',
        password: '123456',
        fullName: 'Student',
      );

  blocTest<AuthCubit, AuthState>(
    'Тіркелген аккаунт, дұрыс құпиясөз: Loading → Success',
    build: build,
    setUp: seedAccount,
    act: (cubit) => cubit.login('student@narxoz.kz', '123456'),
    expect: () => const [
      AuthLoading(),
      AuthSuccess(username: 'Student', email: 'student@narxoz.kz'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'Email бос орын мен бас әріпке сезімтал емес',
    build: build,
    setUp: seedAccount,
    act: (cubit) => cubit.login('  Student@Narxoz.kz ', '123456'),
    expect: () => const [
      AuthLoading(),
      AuthSuccess(username: 'Student', email: 'student@narxoz.kz'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'Қате құпиясөз: Loading → Error',
    build: build,
    setUp: seedAccount,
    act: (cubit) => cubit.login('student@narxoz.kz', 'wrong'),
    expect: () => const [
      AuthLoading(),
      AuthError('Email немесе құпиясөз қате'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'Тіркелмеген email: Loading → Error',
    build: build,
    act: (cubit) => cubit.login('nobody@narxoz.kz', '123456'),
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

  group('Тіркелген аккаунтпен кіру', () {
    blocTest<AuthCubit, AuthState>(
      'register() сақтайды және бірден AuthSuccess шығарады',
      build: build,
      act: (cubit) => cubit.register(
        email: 'Nurs@Narxoz.kz',
        password: 'qwerty1',
        fullName: 'Arystanbek Nurseyit',
      ),
      expect: () => const [
        AuthSuccess(username: 'Arystanbek Nurseyit', email: 'nurs@narxoz.kz'),
      ],
    );

    test('Шығып, сол email және құпиясөзбен қайта кіруге болады', () async {
      final cubit = build();
      await cubit.register(email: 'nurs@narxoz.kz', password: 'qwerty1', fullName: 'Нұрсейіт');
      cubit.logout();

      await cubit.login('nurs@narxoz.kz', 'qwerty1');
      expect(cubit.state, const AuthSuccess(username: 'Нұрсейіт', email: 'nurs@narxoz.kz'));

      await cubit.login('nurs@narxoz.kz', 'wrong');
      expect(cubit.state, const AuthError('Email немесе құпиясөз қате'));
      await cubit.close();
    });

    test('Құпиясөздің өзі сақталмайды — тек хэш', () async {
      await AccountStore().register(email: 'a@b.kz', password: 'secret123', fullName: 'A');
      final raw = (await SharedPreferences.getInstance()).getString('accounts')!;

      expect(raw.contains('secret123'), isFalse);
      expect(raw.contains('"hash"'), isTrue);
      expect(raw.contains('"salt"'), isTrue);
    });

    test('Бірдей құпиясөз — тұз арқасында әртүрлі хэш', () {
      expect(
        AccountStore.hashPassword('123456', 'saltA') == AccountStore.hashPassword('123456', 'saltB'),
        isFalse,
      );
    });
  });

  group('Secure Vault: сессия токені', () {
    test('Кіргенде токен шифрланған қоймаға жазылады, шыққанда өшеді', () async {
      final cubit = build();
      await cubit.register(email: 'nurs@narxoz.kz', password: 'qwerty1', fullName: 'Нұрсейіт');

      final session = await SessionStore().read();
      expect(session, isNotNull);
      expect(session!.email, 'nurs@narxoz.kz');
      expect(session.token.length, greaterThan(20));

      await cubit.logout();
      expect(await SessionStore().read(), isNull);
      expect(cubit.state, const AuthInitial());
      await cubit.close();
    });

    test('Сақталған сессиямен ашылса — бірден AuthSuccess (кіру экраны жоқ)', () async {
      final saved = await SessionStore().create(email: 'nurs@narxoz.kz', username: 'Нұрсейіт');
      final cubit = AuthCubit(restoredSession: saved);
      expect(cubit.state, const AuthSuccess(username: 'Нұрсейіт', email: 'nurs@narxoz.kz'));
      await cubit.close();
    });

    test('Токен экранда толық көрсетілмейді', () {
      final session = Session(
        token: 'abcdefghijklmnopqrstuvwxyz123',
        email: 'a@b.kz',
        username: 'A',
        createdAt: DateTime(2026),
      );
      expect(session.maskedToken, 'abcdef••••••••123');
    });
  });
}
