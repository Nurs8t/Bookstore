import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../models/diary_entry.dart';
import '../../services/database_helper.dart';
import '../../services/media_service.dart';

/// Күнделік күйі: жазбалар (ең жаңасы бірінші) және суреттер папкасы.
final class DiaryState extends Equatable {
  final List<DiaryEntry> entries;

  /// Суреттер жатқан папканың толық жолы (null — әлі анықталмады).
  final String? photosDir;

  const DiaryState({this.entries = const [], this.photosDir});

  int get count => entries.length;

  int get geotaggedCount => entries.where((e) => e.location != null).length;

  /// Жазба суретінің толық жолы (экранда `Image.file(File(...))`).
  String? photoPathOf(DiaryEntry entry) =>
      photosDir == null ? null : p.join(photosDir!, entry.photoFile);

  @override
  List<Object?> get props => [entries, photosDir];
}

/// Оқырман күнделігі (Cubit): SQLite `diary_entries` кестесі + Documents/diary_photos папкасы.
class DiaryCubit extends Cubit<DiaryState> {
  DiaryCubit({DatabaseHelper? db, Future<String> Function()? photosDirectory})
      : _db = db ?? DatabaseHelper.instance,
        _photosDirectory = photosDirectory ?? MediaService.photosDirectory,
        super(const DiaryState());

  final DatabaseHelper _db;
  final Future<String> Function() _photosDirectory;

  Future<void> load() async {
    try {
      final dir = await _photosDirectory();
      final entries = await _db.getDiaryEntries();
      emit(DiaryState(entries: List.unmodifiable(entries), photosDir: dir));
    } catch (e) {
      debugPrint('Күнделікті оқу мүмкін болмады: $e');
    }
  }

  /// Жаңа жазба: уақытша суретті тұрақты папкаға көшіріп, дерекқорға жазады.
  /// Қате болса — шақырған экранға жетеді (жазба сақталмады деп көрсету үшін).
  Future<DiaryEntry> add({
    required String tempPhotoPath,
    required String caption,
    String? bookTitle,
    GeoFix? location,
  }) async {
    final dir = state.photosDir ?? await _photosDirectory();
    final fileName = await MediaService.persist(tempPhotoPath, dir);
    try {
      final entry = DiaryEntry(
        photoFile: fileName,
        caption: caption.trim(),
        bookTitle: bookTitle,
        location: location,
        createdAt: DateTime.now(),
      );
      final saved = entry.withId(await _db.insertDiaryEntry(entry));
      emit(DiaryState(entries: List.unmodifiable([saved, ...state.entries]), photosDir: dir));
      return saved;
    } catch (_) {
      // Дерекқорға жазылмаса — көшірілген сурет «жетім» қалмасын.
      _deleteFile(p.join(dir, fileName));
      rethrow;
    }
  }

  /// Жазбаны және оның суретін өшіру.
  Future<void> delete(DiaryEntry entry) async {
    final id = entry.id;
    if (id == null) return;
    await _db.deleteDiaryEntry(id);
    final path = state.photoPathOf(entry);
    if (path != null) _deleteFile(path);
    emit(DiaryState(
      entries: List.unmodifiable(state.entries.where((e) => e.id != id)),
      photosDir: state.photosDir,
    ));
  }

  void _deleteFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint('Суретті өшіру мүмкін болмады: $e');
    }
  }
}
