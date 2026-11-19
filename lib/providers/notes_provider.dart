import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_item.dart';

/// Оқу жазбалары. Бүкіл тізім бір JSON мәтін болып `notes_list` кілтіне жазылады:
///   List<NoteItem> → toJson() → jsonEncode() → setString()
///   getString() → jsonDecode() → fromJson() → List<NoteItem>
class NotesProvider extends ChangeNotifier {
  static const String notesKey = 'notes_list';

  NotesProvider([this._prefs]) {
    _notes.addAll(_decode(_prefs?.getString(notesKey)));
  }

  final SharedPreferences? _prefs;
  final List<NoteItem> _notes = [];

  List<NoteItem> get notes => List.unmodifiable(_notes);
  int get doneCount => _notes.where((n) => n.isCompleted).length;

  /// CREATE: жаңа жазба тізімнің БАСЫНА қосылады.
  Future<void> add(String title) async {
    if (title.trim().isEmpty) return;
    _notes.insert(0, NoteItem.create(title));
    await _changed();
  }

  /// UPDATE: орындалды / орындалмады.
  Future<void> toggle(String id) async {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i == -1) return;
    _notes[i] = _notes[i].copyWith(isCompleted: !_notes[i].isCompleted);
    await _changed();
  }

  /// DELETE: жазбаны өшіру. Қайтаратыны — UNDO үшін өшірілген жазба мен оның орны.
  Future<(NoteItem, int)?> delete(String id) async {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i == -1) return null;
    final removed = _notes.removeAt(i);
    await _changed();
    return (removed, i);
  }

  Future<void> restore(NoteItem note, int index) async {
    _notes.insert(index.clamp(0, _notes.length), note);
    await _changed();
  }

  /// Әр өзгерістен кейін: UI-ды жаңарту және бүкіл тізімді дискке жазу.
  Future<void> _changed() async {
    notifyListeners();
    final json = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await _prefs?.setString(notesKey, json);
  }

  static List<NoteItem> _decode(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return [];
      return decoded.whereType<Map<String, dynamic>>().map(NoteItem.fromJson).toList();
    } catch (e) {
      debugPrint('Жазбаларды оқу мүмкін болмады: $e');
      return [];
    }
  }
}
