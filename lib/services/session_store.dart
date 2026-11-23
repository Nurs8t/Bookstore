import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Кіру сессиясы: токен + кім кірді.
class Session {
  final String token;
  final String email;
  final String username;
  final DateTime createdAt;

  const Session({
    required this.token,
    required this.email,
    required this.username,
    required this.createdAt,
  });

  /// Экранда толық көрсетпеу үшін: a9f3K2••••••••x7Q
  String get maskedToken =>
      token.length <= 10 ? '••••••' : '${token.substring(0, 6)}••••••••${token.substring(token.length - 3)}';

  Map<String, dynamic> toJson() => {
        'token': token,
        'email': email,
        'username': username,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: json['token'] as String? ?? '',
        email: json['email'] as String? ?? '',
        username: json['username'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      );
}

/// Secure Vault: сессия токені ШИФРЛАНҒАН қоймада сақталады.
///
///   iOS     → Keychain (Secure Enclave)
///   Android → KeyStore (AES-256, TEE чипі)
///
/// SharedPreferences-тен айырмасы: ол ашық .plist / .xml файл, оны root/jailbreak
/// жасалған телефонда немесе бэкап арқылы оқуға болады. Токен, құпиясөз,
/// API кілттері сияқты құпия деректер ТЕК осындай қоймада сақталуы керек.
class SessionStore {
  static const String _key = 'auth_session';

  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Жаңа сессия: кездейсоқ 32 байттық токен жасап, шифрланған қоймаға жазады.
  Future<Session> create({required String email, required String username}) async {
    final session = Session(
      token: _newToken(),
      email: email,
      username: username,
      createdAt: DateTime.now(),
    );
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    return session;
  }

  /// Сақталған сессия (жоқ болса — null).
  Future<Session?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return session.token.isEmpty ? null : session;
    } catch (_) {
      return null;
    }
  }

  /// Шығу: токенді өшіру.
  Future<void> clear() => _storage.delete(key: _key);

  static String _newToken() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256))).replaceAll('=', '');
  }
}
