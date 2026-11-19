import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kazakh_book_shop/models/note_item.dart';
import 'package:kazakh_book_shop/providers/notes_provider.dart';
import 'package:kazakh_book_shop/providers/settings_provider.dart';

/// LW11: баптаулар мен жазбалардың shared_preferences-те сақталуы.
/// "Cold restart" = SharedPreferences-тен жаңа провайдер жасау (main() сияқты).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  group('SettingsProvider', () {
    test('Әдепкі мәндер: жарық тақырып және «Guest User»', () async {
      final settings = SettingsProvider(await prefs());
      expect(settings.isDarkMode, isFalse);
      expect(settings.displayName, 'Guest User');
    });

    test('Қараңғы тақырып пен ат қайта ашқанда қалпына келеді', () async {
      final settings = SettingsProvider(await prefs());
      await settings.setDarkMode(true);
      await settings.setDisplayName('Нұрсейіт');

      final p = await prefs();
      expect(p.getBool('app_theme_dark_mode'), isTrue);
      expect(p.getString('user_display_name'), 'Нұрсейіт');

      final reopened = SettingsProvider(p);
      expect(reopened.isDarkMode, isTrue);
      expect(reopened.displayName, 'Нұрсейіт');
    });

    test('Бос ат сақталмайды — «Guest User» қайтарылады', () async {
      final settings = SettingsProvider(await prefs());
      await settings.setDisplayName('   ');
      expect(settings.displayName, 'Guest User');
      expect((await prefs()).containsKey('user_display_name'), isFalse);
    });
  });

  group('NotesProvider', () {
    test('Жаңа жазба тізімнің басына қосылады және JSON болып сақталады', () async {
      final notes = NotesProvider(await prefs());
      await notes.add('Абай жолын оқу');
      await notes.add('Көшпенділерді бастау');

      expect(notes.notes.first.title, 'Көшпенділерді бастау');

      final raw = (await prefs()).getString('notes_list')!;
      final decoded = jsonDecode(raw) as List;
      expect(decoded.length, 2);
      expect(decoded.first['title'], 'Көшпенділерді бастау');
    });

    test('Toggle және Delete дискке бірден жазылады', () async {
      final notes = NotesProvider(await prefs());
      await notes.add('Ұлпан');
      await notes.add('Гаухартас');
      await notes.toggle(notes.notes.last.id); // Ұлпан → орындалды
      await notes.delete(notes.notes.first.id); // Гаухартас өшірілді

      final reopened = NotesProvider(await prefs());
      expect(reopened.notes.length, 1);
      expect(reopened.notes.single.title, 'Ұлпан');
      expect(reopened.notes.single.isCompleted, isTrue);
    });

    test('Бұзылған JSON қолданбаны құлатпайды', () async {
      SharedPreferences.setMockInitialValues({'notes_list': '{not json'});
      final notes = NotesProvider(await prefs());
      expect(notes.notes, isEmpty);
    });
  });

  test('NoteItem: toJson → fromJson бірдей нәтиже береді', () {
    const note = NoteItem(id: '1', title: 'Қан мен тер', dateText: '19.11.2026, 17:00', isCompleted: true);
    final copy = NoteItem.fromJson(note.toJson());
    expect(copy.id, note.id);
    expect(copy.title, note.title);
    expect(copy.dateText, note.dateText);
    expect(copy.isCompleted, isTrue);
  });
}
