import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Қолданбадағы қаріп өлшемі (жүйе баптауына көбейтіледі).
enum AppTextSize {
  small('Кіші', 0.9),
  normal('Қалыпты', 1.0),
  large('Үлкен', 1.15),
  extraLarge('Өте үлкен', 1.3);

  const AppTextSize(this.label, this.factor);

  final String label;
  final double factor;
}

/// Баптаулар: қараңғы тақырып (bool), көрсетілетін ат (String), қаріп өлшемі (enum → String).
///
/// `SharedPreferences` дананы main() ішінде runApp()-тан БҰРЫН алады,
/// сондықтан мәндер конструкторда синхронды оқылады — қолданба бірінші
/// кадрдан бастап дұрыс тақырыппен ашылады (ақ экран жыпылықтамайды).
class SettingsProvider extends ChangeNotifier {
  static const String darkModeKey = 'app_theme_dark_mode';
  static const String displayNameKey = 'user_display_name';
  static const String textSizeKey = 'app_text_size';
  static const String defaultName = 'Guest User';

  SettingsProvider([this._prefs])
      : _isDarkMode = _prefs?.getBool(darkModeKey) ?? false,
        _displayName = _prefs?.getString(displayNameKey) ?? defaultName,
        // enum атымен сақталады ('large'); белгісіз мән болса — қалыпты.
        _textSize = AppTextSize.values.asNameMap()[_prefs?.getString(textSizeKey)] ??
            AppTextSize.normal;

  /// null болса (мысалы, виджет тестінде) — мәндер тек жадта тұрады.
  final SharedPreferences? _prefs;

  bool _isDarkMode;
  String _displayName;
  AppTextSize _textSize;

  bool get isDarkMode => _isDarkMode;
  String get displayName => _displayName;
  AppTextSize get textSize => _textSize;

  Future<void> setTextSize(AppTextSize value) async {
    if (value == _textSize) return;
    _textSize = value;
    notifyListeners(); // бүкіл қолданбаның қаріпі бірден өзгереді
    await _prefs?.setString(textSizeKey, value.name);
  }

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
