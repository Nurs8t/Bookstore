part of 'catalog_bloc.dart';

/// Каталогтың 3 күйі: Loading → Loaded / Error.
sealed class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

/// 1) Жүктелу: ортада спиннер.
final class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

/// 3) Қате: интернет жоқ ЖӘНЕ кэш бос → «Қайта қосылу».
final class CatalogError extends CatalogState {
  final String message;

  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 2) Кітаптар жүктелді (серверден немесе офлайн кэштен).
final class CatalogLoaded extends CatalogState {
  static const String allCategories = 'Барлығы';

  final List<Book> books;
  final String selectedCategory;

  /// true — кітаптар SQLite кэшінен (офлайн режим).
  final bool isOffline;
  final DateTime? cachedAt;

  /// Бір реттік хабар (SnackBar) және оның нөмірі.
  /// Нөмір өзгергенде ғана BlocListener хабарды көрсетеді.
  final String? notice;
  final int noticeId;

  const CatalogLoaded({
    required this.books,
    this.selectedCategory = allCategories,
    this.isOffline = false,
    this.cachedAt,
    this.notice,
    this.noticeId = 0,
  });

  /// Сүзгі тізімі: 'Барлығы' + кітаптардағы бар санаттар.
  List<String> get categories => [allCategories, ...books.map((b) => b.category).toSet()];

  /// Таңдалған санаттағы кітаптар.
  List<Book> get visibleBooks => selectedCategory == allCategories
      ? books
      : books.where((b) => b.category == selectedCategory).toList();

  CatalogLoaded copyWith({
    List<Book>? books,
    String? selectedCategory,
    bool? isOffline,
    DateTime? cachedAt,
    String? notice,
    int? noticeId,
  }) {
    final newBooks = books ?? this.books;
    var category = selectedCategory ?? this.selectedCategory;
    // Санат кітаптармен бірге жоғалса — 'Барлығы'-ға ораламыз.
    if (category != allCategories && !newBooks.any((b) => b.category == category)) {
      category = allCategories;
    }
    return CatalogLoaded(
      books: List.unmodifiable(newBooks),
      selectedCategory: category,
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt ?? this.cachedAt,
      notice: notice ?? this.notice,
      noticeId: noticeId ?? this.noticeId,
    );
  }

  @override
  List<Object?> get props => [books, selectedCategory, isOffline, cachedAt, notice, noticeId];
}
