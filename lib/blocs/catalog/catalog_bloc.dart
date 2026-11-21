import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/book.dart';
import '../../repositories/book_repository.dart';
import '../../services/book_api_service.dart';

part 'catalog_event.dart';
part 'catalog_state.dart';

/// Каталог BLoC (Clean Architecture үшбұрышы):
///
///   UI ──Event──▶ CatalogBloc ──getBooks()──▶ BookRepository ──▶ API / SQLite кэш
///    ▲                 │
///    └────State────────┘   CatalogLoading / CatalogLoaded / CatalogError
///
/// Экранда бизнес-логика жоқ: ол тек оқиға жібереді және күйді сызады.
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({BookRepository? repository})
      : _repository = repository ?? BookRepository(),
        super(const CatalogLoading()) {
    on<FetchBooksEvent>(_onFetch);
    on<RefreshBooksEvent>(_onRefresh);
    on<FilterCategoryEvent>(_onFilter);
    on<RemoveBookEvent>(_onRemove);
    on<RestoreBookEvent>(_onRestore);
  }

  final BookRepository _repository;

  /// Алғашқы жүктеу / «Қайта қосылу»: Loading → Loaded / Error.
  Future<void> _onFetch(FetchBooksEvent event, Emitter<CatalogState> emit) async {
    emit(const CatalogLoading());
    try {
      final result = await _repository.getBooks();
      emit(CatalogLoaded(
        books: List.unmodifiable(result.books),
        isOffline: result.fromCache,
        cachedAt: result.cachedAt,
      ));
    } on ApiException catch (e) {
      emit(CatalogError(e.message)); // интернет жоқ және кэш бос
    }
  }

  /// Pull-to-Refresh: спиннерсіз; сәтсіз болса — тізім қалады, SnackBar хабары шығады.
  Future<void> _onRefresh(RefreshBooksEvent event, Emitter<CatalogState> emit) async {
    final current = state;
    try {
      final result = await _repository.getBooks();
      final previous = current is CatalogLoaded ? current : null;
      final next = (previous ?? const CatalogLoaded(books: [])).copyWith(
        books: result.books,
        isOffline: result.fromCache,
        cachedAt: result.cachedAt,
        notice: result.fromCache ? (result.errorMessage ?? 'Интернет жоқ.') : null,
        noticeId: result.fromCache ? (previous?.noticeId ?? 0) + 1 : null,
      );
      emit(next);
    } on ApiException catch (e) {
      if (current is CatalogLoaded) {
        emit(current.copyWith(notice: e.message, noticeId: current.noticeId + 1));
      } else {
        emit(CatalogError(e.message));
      }
    } finally {
      event.completer?.complete();
    }
  }

  void _onFilter(FilterCategoryEvent event, Emitter<CatalogState> emit) {
    final current = state;
    if (current is! CatalogLoaded) return;
    emit(current.copyWith(selectedCategory: event.category));
  }

  void _onRemove(RemoveBookEvent event, Emitter<CatalogState> emit) {
    final current = state;
    if (current is! CatalogLoaded) return;
    emit(current.copyWith(
      books: current.books.where((b) => b.id != event.bookId).toList(),
    ));
  }

  void _onRestore(RestoreBookEvent event, Emitter<CatalogState> emit) {
    final current = state;
    if (current is! CatalogLoaded) return;
    if (current.books.any((b) => b.id == event.book.id)) return;
    final books = [...current.books]
      ..insert(math.min(event.index, current.books.length), event.book);
    emit(current.copyWith(books: books));
  }

  @override
  Future<void> close() {
    _repository.dispose();
    return super.close();
  }
}
