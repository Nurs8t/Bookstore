import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/book.dart';
import '../../services/database_helper.dart';

/// Таңдаулылардың күйі — өзгермейтін тізім.
final class FavoritesState extends Equatable {
  final List<Book> books;

  const FavoritesState([this.books = const []]);

  int get count => books.length;

  bool isFavorite(Book book) => books.any((b) => b.id == book.id);

  @override
  List<Object?> get props => [books];
}

/// Таңдаулы кітаптар (Cubit). SQLite-тағы `favorites` кестесіне жазылады,
/// сондықтан қолданбаны жауып ашқанда сақталып тұрады.
///
///   UI ──toggle(book)──▶ FavoritesCubit ──emit(FavoritesState)──▶ ♡ белгілері, badge
///                              └──▶ SQLite (favorites)
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance,
        super(const FavoritesState());

  final DatabaseHelper _db;

  /// Қолданба іске қосылғанда бір рет (main.dart).
  Future<void> load() async {
    try {
      final saved = await _db.getFavorites();
      // Жүктеу кезінде қосылғандарды жоғалтпаймыз.
      final merged = [
        ...state.books,
        ...saved.where((s) => !state.books.any((b) => b.id == s.id)),
      ];
      emit(FavoritesState(List.unmodifiable(merged)));
    } catch (e) {
      debugPrint('Таңдаулыларды жүктеу мүмкін болмады: $e');
    }
  }

  /// ♡ басылды: бар болса — алып тастаймыз, жоқ болса — қосамыз.
  Future<void> toggle(Book book) async {
    if (state.isFavorite(book)) {
      emit(FavoritesState(List.unmodifiable(state.books.where((b) => b.id != book.id))));
      await _save(() => _db.deleteFavorite(book.id));
    } else {
      emit(FavoritesState(List.unmodifiable([...state.books, book])));
      await _save(() => _db.insertFavorite(book));
    }
  }

  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Таңдаулыларды сақтау мүмкін болмады: $e');
    }
  }
}
