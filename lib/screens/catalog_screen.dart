import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/catalog/catalog_bloc.dart';
import '../models/book.dart';
import '../widgets/book_grid_card.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'book_detail_screen.dart';

/// Кітаптар каталогы. Бүкіл логика CatalogBloc-та:
/// экран тек оқиға жібереді (Fetch, Refresh, Filter, Remove, Restore) және күйді сызады.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, this.bloc});

  /// Тесттер үшін: дайын күйдегі BLoC беруге болады (желіге шықпайды).
  /// null болса — экран өз BLoC-ын жасап, кітаптарды жүктейді.
  final CatalogBloc? bloc;

  @override
  Widget build(BuildContext context) {
    final given = bloc;
    if (given != null) {
      return BlocProvider.value(value: given, child: const _CatalogView());
    }
    return BlocProvider(
      create: (_) => CatalogBloc()..add(const FetchBooksEvent()),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatefulWidget {
  const _CatalogView();

  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  /// Тек UI-ға қатысты жергілікті күй (ephemeral) — setState жеткілікті.
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _bloc.add(const SearchBooksEvent(''));
    FocusScope.of(context).unfocus();
  }

  CatalogBloc get _bloc => context.read<CatalogBloc>();

  // ---------- Оқиғалар ----------

  /// Pull-to-Refresh: BLoC жүктеп біткенше RefreshIndicator дөңгелегі айналады.
  Future<void> _refresh() {
    final completer = Completer<void>();
    _bloc.add(RefreshBooksEvent(completer: completer));
    return completer.future;
  }

  void _removeBook(CatalogLoaded state, Book book) {
    final index = state.books.indexOf(book); // нақты каталогтағы орны (сүзгіге тәуелсіз)
    if (index == -1) return;
    _bloc.add(RemoveBookEvent(book.id));

    final bloc = _bloc;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('«${book.title}» өшірілді'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amberAccent,
          onPressed: () => bloc.add(RestoreBookEvent(book, index)),
        ),
      ));
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Қайталау',
          textColor: Colors.white,
          onPressed: _refresh,
        ),
      ));
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
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          // Сұрыптау мәзірі: таңдалған тәртіп ✓ белгісімен.
          BlocBuilder<CatalogBloc, CatalogState>(
            buildWhen: (p, c) => (p is CatalogLoaded ? p.sort : null) != (c is CatalogLoaded ? c.sort : null),
            builder: (context, state) {
              if (state is! CatalogLoaded) return const SizedBox.shrink();
              return PopupMenuButton<BookSort>(
                tooltip: 'Сұрыптау',
                icon: Badge(
                  isLabelVisible: state.sort != BookSort.popular,
                  smallSize: 8,
                  child: const Icon(Icons.sort_rounded),
                ),
                initialValue: state.sort,
                onSelected: (sort) => _bloc.add(SortBooksEvent(sort)),
                itemBuilder: (_) => [
                  for (final sort in BookSort.values)
                    PopupMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(sort.icon, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(sort.label)),
                          if (sort == state.sort) const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const CartBadgeButton(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: BlocConsumer<CatalogBloc, CatalogState>(
            // LISTENER: бір реттік хабар (жаңарту сәтсіз болғанда SnackBar).
            listenWhen: (previous, current) =>
                current is CatalogLoaded &&
                current.notice != null &&
                (previous is! CatalogLoaded || previous.noticeId != current.noticeId),
            listener: (context, state) => _showNotice((state as CatalogLoaded).notice!),
            // BUILDER: күйге қарай экранды сызу.
            builder: (context, state) => Column(
              children: [
                if (state is CatalogLoaded && state.books.isNotEmpty) _buildSearchField(),
                if (state is CatalogLoaded && state.isOffline) _buildOfflineBanner(state.cachedAt),
                if (state is CatalogLoaded && state.books.isNotEmpty) _buildCategoryBar(state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildBody(state),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// «Офлайн режим» белгісі: кітаптар соңғы сақталған кэштен көрсетіліп тұр.
  Widget _buildOfflineBanner(DateTime? time) {
    final subtitle = time == null ? 'Соңғы сақталған кітаптар' : 'Соңғы жаңарту: ${_formatTime(time)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Офлайн режим',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _refresh,
            child: const Text('Қайта қосылу'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}, ${two(t.hour)}:${two(t.minute)}';
  }

  /// Іздеу өрісі: әр әріп SearchBooksEvent жібереді, BLoC 300 мс debounce жасайды.
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, _) => TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (text) => _bloc.add(SearchBooksEvent(text)),
          decoration: InputDecoration(
            hintText: 'Кітап немесе автор іздеу',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Тазалау',
                    icon: const Icon(Icons.close),
                    onPressed: _clearSearch,
                  ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(CatalogLoaded state) {
    final categories = state.categories;

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
            selected: category == state.selectedCategory,
            showCheckmark: false,
            onSelected: (_) => _bloc.add(FilterCategoryEvent(category)),
          );
        },
      ),
    );
  }

  Widget _buildBody(CatalogState state) {
    switch (state) {
      // 1) Loading
      case CatalogLoading():
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

      // 2) Error with Retry
      case CatalogError(:final message):
        return ErrorState(
          message: message,
          onRetry: () => _bloc.add(const FetchBooksEvent()),
        );

      // 3) Loaded
      case CatalogLoaded():
        if (state.books.isEmpty) {
          return EmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'Каталог бос',
            message: 'Барлық кітаптар өшірілді. Каталогты серверден қайта жүктеу үшін '
                'түймені басыңыз немесе экранды төмен тартыңыз.',
            actionLabel: 'Каталогты қалпына келтіру',
            onAction: () => _bloc.add(const FetchBooksEvent()),
          );
        }
        final books = state.visibleBooks;
        if (books.isEmpty && state.isSearching) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Ештеңе табылмады',
            message: '«${state.query.trim()}» бойынша кітап жоқ. Басқа сөзбен іздеп көріңіз.',
            actionLabel: 'Іздеуді тазалау',
            actionIcon: Icons.close,
            onAction: _clearSearch,
          );
        }
        if (books.isEmpty) {
          return const EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'Бұл санатта кітап жоқ',
            message: 'Басқа санатты таңдап көріңіз.',
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) => _isGridView
              ? _buildGrid(state, books, constraints.maxWidth)
              : _buildList(state, books, constraints.maxWidth),
        );
    }
  }

  Widget _buildList(CatalogLoaded state, List<Book> books, double width) {
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
          onDismissed: (_) => _removeBook(state, book),
          child: BookListTile(
            book: book,
            heroTag: _heroTag(book),
            onTap: () => _openDetail(book),
          ),
        );
      },
    );
  }

  Widget _buildGrid(CatalogLoaded state, List<Book> books, double width) {
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
          onDismissed: (_) => _removeBook(state, book),
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
