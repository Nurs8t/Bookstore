part of 'catalog_bloc.dart';

/// Каталогқа келетін оқиғалар. UI тек «не болды» дейді.
sealed class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

/// Алғашқы жүктеу және «Қайта қосылу» (толық экранды спиннер).
final class FetchBooksEvent extends CatalogEvent {
  const FetchBooksEvent();
}

/// Pull-to-Refresh: тізім экранда қалады.
/// [completer] — RefreshIndicator-дың дөңгелегін жүктеу біткенде тоқтату үшін.
final class RefreshBooksEvent extends CatalogEvent {
  final Completer<void>? completer;

  const RefreshBooksEvent({this.completer});
}

/// Санат бойынша сүзгі ('Барлығы' — сүзгісіз).
final class FilterCategoryEvent extends CatalogEvent {
  final String category;

  const FilterCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

/// Іздеу: атауы немесе авторы бойынша. Debounce: теріп болғаннан кейін 300 мс күтеді.
final class SearchBooksEvent extends CatalogEvent {
  final String query;

  const SearchBooksEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Сұрыптау тәртібін өзгерту.
final class SortBooksEvent extends CatalogEvent {
  final BookSort sort;

  const SortBooksEvent(this.sort);

  @override
  List<Object?> get props => [sort];
}

/// Swipe-to-Delete: кітапты каталогтан алып тастау.
final class RemoveBookEvent extends CatalogEvent {
  final String bookId;

  const RemoveBookEvent(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

/// UNDO: өшірілген кітапты бұрынғы орнына қайтару.
final class RestoreBookEvent extends CatalogEvent {
  final Book book;
  final int index;

  const RestoreBookEvent(this.book, this.index);

  @override
  List<Object?> get props => [book, index];
}
