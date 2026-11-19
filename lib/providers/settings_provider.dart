import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Баптаулар: қараңғы тақырып (bool) және көрсетілетін ат (String).
///
/// `SharedPreferences` дананы main() ішінде runApp()-тан БҰРЫН алады,
/// сондықтан мәндер конструкторда синхронды оқылады — қолданба бірінші
/// кадрдан бастап дұрыс тақырыппен ашылады (ақ экран жыпылықтамайды).
class SettingsProvider extends ChangeNotifier {
  static const String darkModeKey = 'app_theme_dark_mode';
  static const String displayNameKey = 'user_display_name';
  static const String defaultName = 'Guest User';

  SettingsProvider([this._prefs])
      : _isDarkMode = _prefs?.getBool(darkModeKey) ?? false,
        _displayName = _prefs?.getString(displayNameKey) ?? defaultName;

  /// null болса (мысалы, виджет тестінде) — мәндер тек жадта тұрады.
  final SharedPreferences? _prefs;

  bool _isDarkMode;
  String _displayName;

  bool get isDarkMode => _isDarkMode;
  String get displayName => _displayName;

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners(); // тақырып бірден ауысады
    await _prefs?.setBool(darkModeKey, value);
  }

  /// Бос ат сақталмайды — әдепкі «Guest User» қайтарылады.
  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    _displayName = trimmed.isEmpty ? defaultName : trimmed;
    notifyListeners();
    if (trimmed.isEmpty) {
      await _prefs?.remove(displayNameKey);
    } else {
      await _prefs?.setString(displayNameKey, trimmed);
    }
  }
}
