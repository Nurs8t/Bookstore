import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/book_api_service.dart';
import '../widgets/book_grid_card.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'book_detail_screen.dart';

/// UI-дың 3 күйі: жүктелу → кітаптар → қате + «Қайта қосылу».
enum LoadStatus { loading, success, error }

/// Кітаптар каталогы. Кітаптар REST API-дан жүктеледі (api/books.json).
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const String _allCategories = 'Барлығы';

  final BookApiService _api = BookApiService();

  LoadStatus _status = LoadStatus.loading;
  String _errorMessage = '';
  List<Book> _books = [];
  bool _isGridView = false;
  String _selectedCategory = _allCategories;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  List<String> get _categories => [
        _allCategories,
        ..._books.map((b) => b.category).toSet(),
      ];

  List<Book> get _visibleBooks => _selectedCategory == _allCategories
      ? _books
      : _books.where((b) => b.category == _selectedCategory).toList();

  // ---------- Әрекеттер ----------

  void _removeBook(Book book) {
    final index =
        _books.indexOf(book); // нақты каталогтағы орны (фильтрге тәуелсіз)
    if (index == -1) return;

    setState(() => _books.removeAt(index));

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('«${book.title}» өшірілді'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amberAccent,
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _books.insert(math.min(index, _books.length), book);
            });
          },
        ),
      ),
    );
  }

  /// Алғашқы жүктеу және «Қайта қосылу»: толық экранды спиннер.
  Future<void> _loadBooks() async {
    // initState кезінде күй бұрыннан loading — setState қажет емес (әрі рұқсат етілмейді).
    if (_status != LoadStatus.loading) {
      setState(() => _status = LoadStatus.loading);
    }
    try {
      final books = await _api.fetchBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _selectedCategory = _allCategories;
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _status = LoadStatus.error;
      });
    }
  }

  /// Pull-to-Refresh: API-дан қайта жүктейді. Тізім экранда қала береді;
  /// жаңарту сәтсіз болса, ескі тізім жоғалмайды — тек SnackBar шығады.
  Future<void> _handleRefresh() async {
    try {
      final books = await _api.fetchBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_status != LoadStatus.success) {
        setState(() {
          _errorMessage = e.message;
          _status = LoadStatus.error;
        });
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Қайталау',
            textColor: Colors.white,
            onPressed: _handleRefresh,
          ),
        ));
    }
  }

  void _openDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book, heroTag: _heroTag(book)),
      ),
    );
  }

  /// Hero тегі тізімдегі мұқаба мен деталь экранындағы 1-суретте бірдей.
  String _heroTag(Book book) => 'product_image_${book.id}';

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Қазақ әдебиеті дүкені'),
        actions: [
          IconButton(
            tooltip: _isGridView ? 'Тізім көрінісі' : 'Тор көрінісі',
            icon: Icon(_isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          const CartBadgeButton(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              if (_status == LoadStatus.success && _books.isNotEmpty)
                _buildCategoryBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar() {
    final categories = _categories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = _allCategories;
    }

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: category == _selectedCategory,
            showCheckmark: false,
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    // 1) Loading
    if (_status == LoadStatus.loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Кітаптар жүктелуде...'),
          ],
        ),
      );
    }

    // 2) Error with Retry
    if (_status == LoadStatus.error) {
      return ErrorState(message: _errorMessage, onRetry: _loadBooks);
    }

    // 3) Success
    if (_books.isEmpty) {
      return EmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'Каталог бос',
        message:
            'Барлық кітаптар өшірілді. Каталогты серверден қайта жүктеу үшін '
            'түймені басыңыз немесе экранды төмен тартыңыз.',
        actionLabel: 'Каталогты қалпына келтіру',
        onAction: _loadBooks,
      );
    }

    final books = _visibleBooks;
    if (books.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Бұл санатта кітап жоқ',
        message: 'Басқа санатты таңдап көріңіз.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => _isGridView
          ? _buildGrid(books, constraints.maxWidth)
          : _buildList(books, constraints.maxWidth),
    );
  }

  Widget _buildList(List<Book> books, double width) {
    final horizontal = width > 720 ? (width - 700) / 2 : 12.0;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 16),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = books[index];
        return Dismissible(
          key: ValueKey(book.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(alignment: Alignment.centerRight),
          onDismissed: (_) => _removeBook(book),
          child: BookListTile(
            book: book,
            heroTag: _heroTag(book),
            onTap: () => _openDetail(book),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<Book> books, double width) {
    final crossAxisCount = width >= 1000 ? 4 : (width >= 600 ? 3 : 2);

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Dismissible(
          key: ValueKey(book.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(alignment: Alignment.centerRight),
          onDismissed: (_) => _removeBook(book),
          child: BookGridCard(
            book: book,
            heroTag: _heroTag(book),
            onTap: () => _openDetail(book),
          ),
        );
      },
    );
  }
}

/// Swipe кезінде көрінетін қызыл фон.
class _DeleteBackground extends StatelessWidget {
  final Alignment alignment;

  const _DeleteBackground({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text('Өшіру',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
