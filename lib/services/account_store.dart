import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Тіркелген аккаунттар. Құпиясөздің ӨЗІ ешқашан сақталмайды —
/// тек оның тұзды хэші (salt + SHA-256).
///
/// Сақталу түрі (`accounts` кілті, JSON):
/// {
///   "nurs@narxoz.kz": {
///     "name": "Arystanbek Nurseyit",
///     "salt": "x9Kq...==",
///     "hash": "3f7a...c1"      ← sha256(salt + ":" + құпиясөз)
///   }
/// }
///
/// Неге тұз (salt)? Екі адамның құпиясөзі бірдей болса да, хэштері әртүрлі
/// болады, және дайын «хэш кестелерімен» (rainbow tables) табу мүмкін болмайды.
class AccountStore {
  static const String _key = 'accounts';

  /// Тесттерде SharedPreferences-ті алмастыру үшін.
  AccountStore({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  /// Аккаунт жасау немесе жаңарту (сол email қайта тіркелсе — құпиясөз ауысады).
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final prefs = await _prefs();
    final accounts = _read(prefs);
    final salt = _newSalt();
    accounts[_normalize(email)] = {
      'name': fullName.trim(),
      'salt': salt,
      'hash': hashPassword(password, salt),
    };
    await prefs.setString(_key, jsonEncode(accounts));
  }

  /// Email мен құпиясөз дұрыс болса — аккаунт иесінің аты, әйтпесе null.
  Future<String?> verify(String email, String password) async {
    final prefs = await _prefs();
    final account = _read(prefs)[_normalize(email)];
    if (account is! Map) return null;

    final salt = account['salt'] as String? ?? '';
    final savedHash = account['hash'] as String? ?? '';
    if (hashPassword(password, salt) != savedHash) return null;

    final name = account['name'] as String? ?? '';
    return name.isEmpty ? null : name;
  }

  Future<bool> exists(String email) async {
    final prefs = await _prefs();
    return _read(prefs).containsKey(_normalize(email));
  }

  /// sha256(salt + ":" + құпиясөз) → 64 таңбалы hex жол.
  static String hashPassword(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _normalize(String email) => email.trim().toLowerCase();

  static Map<String, dynamic> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}
