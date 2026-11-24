part of 'catalog_bloc.dart';

/// Сұрыптау тәртібі.
enum BookSort {
  popular('Танымал (әдепкі)', Icons.auto_awesome),
  priceAsc('Арзаннан қымбатқа', Icons.arrow_upward),
  priceDesc('Қымбаттан арзанға', Icons.arrow_downward),
  rating('Рейтинг бойынша', Icons.star_rounded),
  title('Атауы бойынша (А–Я)', Icons.sort_by_alpha);

  const BookSort(this.label, this.icon);

  final String label;
  final IconData icon;
}

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

  /// Іздеу мәтіні және сұрыптау тәртібі.
  final String query;
  final BookSort sort;

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
    this.query = '',
    this.sort = BookSort.popular,
    this.isOffline = false,
    this.cachedAt,
    this.notice,
    this.noticeId = 0,
  });

  /// Сүзгі тізімі: 'Барлығы' + кітаптардағы бар санаттар.
  List<String> get categories => [allCategories, ...books.map((b) => b.category).toSet()];

  /// Экранда көрінетін кітаптар: санат → іздеу → сұрыптау.
  List<Book> get visibleBooks {
    final q = query.trim().toLowerCase();
    final result = books.where((b) {
      final inCategory = selectedCategory == allCategories || b.category == selectedCategory;
      final matches = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q);
      return inCategory && matches;
    }).toList();

    switch (sort) {
      case BookSort.popular:
        break; // API-дағы реті
      case BookSort.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case BookSort.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case BookSort.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case BookSort.title:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return result;
  }

  bool get isSearching => query.trim().isNotEmpty;

  CatalogLoaded copyWith({
    List<Book>? books,
    String? selectedCategory,
    String? query,
    BookSort? sort,
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
      query: query ?? this.query,
      sort: sort ?? this.sort,
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt ?? this.cachedAt,
      notice: notice ?? this.notice,
      noticeId: noticeId ?? this.noticeId,
    );
  }

  @override
  List<Object?> get props =>
      [books, selectedCategory, query, sort, isOffline, cachedAt, notice, noticeId];
}
