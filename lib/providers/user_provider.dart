import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Тіркелген қолданушы. «Мені есте сақта» қосулы болса, профиль
/// shared_preferences-ке (кілт–мән қоймасы) JSON түрінде жазылады.
///
/// Неге SQLite емес? Профиль — бір ғана шағын объект. Кесте, сұраныс керек емес:
/// бір кілт → бір мән жеткілікті. Тізімдер мен қатынастар үшін — SQLite.
class UserProvider extends ChangeNotifier {
  static const String _key = 'user_profile';

  UserProfile? _user;
  bool _isLoaded = false;

  UserProfile? get user => _user;
  bool get isRegistered => _user != null;
  bool get isLoaded => _isLoaded;

  /// Қолданба іске қосылғанда сақталған профильді оқу (main.dart).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null && _user == null) {
        _user = UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Профильді оқу мүмкін болмады: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// [remember] = true болса, профиль келесі жолы да ашық тұрады.
  Future<void> register(UserProfile profile, {bool remember = true}) async {
    _user = profile;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (remember) {
        await prefs.setString(_key, jsonEncode(profile.toJson()));
      } else {
        await prefs.remove(_key);
      }
    } catch (e) {
      debugPrint('Профильді сақтау мүмкін болмады: $e');
    }
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('Профильді өшіру мүмкін болмады: $e');
    }
  }
}
