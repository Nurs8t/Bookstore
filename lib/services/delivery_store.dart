import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/delivery_info.dart';

/// Соңғы тапсырыстың байланыс мәліметтері (аты, телефон, мекенжай, төлем тәсілі).
///
/// Телефон мен мекенжай — жеке деректер (PII), сондықтан SharedPreferences-те
/// (ашық файл) емес, шифрланған қоймада сақталады: Keychain / KeyStore.
/// Пікір сақталмайды — ол тек бір тапсырысқа қатысты.
class DeliveryStore {
  static const String _key = 'last_delivery';

  DeliveryStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> save(DeliveryInfo info) {
    final map = info.toMap()..remove('comment');
    return _storage.write(key: _key, value: jsonEncode(map));
  }

  /// Сақталған мәлімет (жоқ немесе бүлінген болса — null).
  Future<DeliveryInfo?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return DeliveryInfo.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _key);
}
