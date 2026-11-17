import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kazakh_book_shop/models/user_profile.dart';
import 'package:kazakh_book_shop/providers/user_provider.dart';

/// Қолданушы профилінің shared_preferences-те сақталуы.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = UserProfile(
    fullName: 'Arystanbek Nurseyit',
    email: 'nurs@narxoz.kz',
    role: UserRole.developer,
    subscribed: true,
  );

  Future<UserProvider> reopen() async {
    final user = UserProvider();
    await user.load();
    return user;
  }

  setUp(() => SharedPreferences.setMockInitialValues({})); // әр тест таза қоймадан

  test('«Мені есте сақта» қосулы — профиль қайта ашқанда тұрады', () async {
    final user = await reopen();
    await user.register(profile, remember: true);

    final reopened = await reopen();
    expect(reopened.isRegistered, isTrue);
    expect(reopened.user!.fullName, 'Arystanbek Nurseyit');
    expect(reopened.user!.role, UserRole.developer);
  });

  test('«Мені есте сақта» өшік — профиль сақталмайды', () async {
    final user = await reopen();
    await user.register(profile, remember: false);
    expect(user.isRegistered, isTrue); // осы сеанста бар

    final reopened = await reopen();
    expect(reopened.isRegistered, isFalse);
  });

  test('Шығу профильді қоймадан өшіреді', () async {
    final user = await reopen();
    await user.register(profile);
    await user.logout();

    final reopened = await reopen();
    expect(reopened.isRegistered, isFalse);
  });

  test('toJson / fromJson бір-біріне сәйкес', () {
    final copy = UserProfile.fromJson(profile.toJson());
    expect(copy.email, profile.email);
    expect(copy.role, profile.role);
    expect(copy.subscribed, isTrue);
  });
}
