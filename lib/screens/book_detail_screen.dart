import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/favorites/favorites_cubit.dart';
import '../models/book.dart';
import '../blocs/cart/cart_bloc.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/book_cover.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/share_link_sheet.dart';
import '../widgets/tag_chip.dart';
import 'cart_screen.dart';
import 'diary_screen.dart';

/// Кітап мәліметтері (Master-Detail): толық Book объектісі конструктор арқылы беріледі.
/// Hero анимациясы, фото-карусель, бөлісу (Deep Link) және sticky «Себетке қосу».
class BookDetailScreen extends StatelessWidget {
  final Book book;

  /// Каталогтан ашылғанда беріледі: мұқаба тізімнен "ұшып" келеді.
  final String? heroTag;

  const BookDetailScreen({super.key, required this.book, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кітап мәліметтері'),
        leading: IconButton(
          tooltip: 'Артқа',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Күнделікке жазу',
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DiaryScreen(initialBookTitle: book.title)),
            ),
          ),
          IconButton(
            tooltip: 'Бөлісу',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ShareLinkSheet.show(context, book),
          ),
          const CartBadgeButton(),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 720) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 380,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _CoverHeader(book: book, height: 440, heroTag: heroTag),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 24, 24, 24),
                        child: _BookInfo(book: book),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoverHeader(book: book, height: 320, heroTag: heroTag),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _BookInfo(book: book),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _BottomActionBar(book: book),
    );
  }
}

/// Мұқаба аймағы: фото-карусель (PageView.builder) + бет санағышы (1 / 3)
/// + анимацияланған нүктелер + «Бестселлер» баннері + бетбелгі.
class _CoverHeader extends StatefulWidget {
  final Book book;
  final double height;
  final String? heroTag;

  const _CoverHeader({required this.book, required this.height, this.heroTag});

  @override
  State<_CoverHeader> createState() => _CoverHeaderState();
}

class _CoverHeaderState extends State<_CoverHeader> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Бір беттегі мұқаба. API бір ғана сурет берсе, 2-3 беттер оны жақыннан көрсетеді.
  Widget _buildPage(List<String> images, bool sameImage, int index) {
    final coverHeight = widget.height * 0.72;
    final coverWidth = coverHeight * 0.66;

    final cover = BookCover(
      imagePath: images[index],
      height: coverHeight,
      width: coverWidth,
      borderRadius: 12,
      iconSize: 64,
    );

    final Widget content = (!sameImage || index == 0)
        ? cover
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Transform.scale(
              scale: 1.8,
              alignment: index == 1 ? Alignment.topCenter : Alignment.bottomCenter,
              child: cover,
            ),
          );

    final framed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: content,
    );

    // Тек 1-бет Hero: каталогтағы мұқаба осы жерге "ұшып" келеді.
    final page = index == 0 && widget.heroTag != null
        ? Hero(tag: widget.heroTag!, child: framed)
        : framed;

    return Align(
      alignment: const Alignment(0, -0.35),
      child: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final isFav = context.select((FavoritesCubit c) => c.state.isFavorite(book));
    final images = book.gallery;
    final sameImage = images.length > 1 && images.toSet().length == 1;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.brown.shade200, Theme.of(context).scaffoldBackgroundColor],
                ),
              ),
            ),
          ),
          // Фото-карусель
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => _buildPage(images, sameImage, index),
            ),
          ),
          if (book.isBestseller)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department,
                        color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Бестселлер',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: RoundIconButton(
              tooltip: isFav ? 'Таңдаулыдан алу' : 'Таңдаулыға сақтау',
              icon: isFav ? Icons.bookmark : Icons.bookmark_border,
              color: isFav ? context.accent : Colors.grey,
              size: 22,
              onPressed: () {
                context.read<FavoritesCubit>().toggle(book);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                    content: Text(isFav
                        ? 'Таңдаулылардан алынды'
                        : 'Таңдаулыларға сақталды'),
                    duration: const Duration(seconds: 2),
                  ));
              },
            ),
          ),
          // Бет санағышы: 1 / 3
          Positioned(
            right: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1} / ${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Анимацияланған нүктелер: белсенді нүкте ұзарады
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final isActive = index == _currentPage;
                return GestureDetector(
                  onTap: () => _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? context.accent : Colors.brown.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookInfo extends StatelessWidget {
  final Book book;

  const _BookInfo({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                book.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Үлкен баға тар экранда атауды ығыстырмай, кішірейеді.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topRight,
                child: Text(
                  formatPrice(book.price),
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: context.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Авторы: ${book.author}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...List.generate(5, (i) {
              final filled = book.rating >= i + 0.75;
              final half = !filled && book.rating >= i + 0.25;
              return Icon(
                filled
                    ? Icons.star_rounded
                    : (half
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded),
                color: AppTheme.gold,
                size: 20,
              );
            }),
            const SizedBox(width: 6),
            Text(
              book.rating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '(${formatReviews(book.reviewsCount)})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            TagChip(
              label: book.category,
              background: Colors.brown.shade100,
              foreground: AppTheme.textDark,
            ),
            TagChip(
              label: 'Қоймада бар',
              background: Colors.green.shade50,
              foreground: Colors.green.shade800,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Негізгі тақырыптар'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: book.tags.map((tag) => TagChip(label: '#$tag')).toList(),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Кітап туралы'),
        const SizedBox(height: 8),
        Text(
          book.synopsis,
          style: TextStyle(
              color: Colors.grey.shade600, height: 1.55, fontSize: 14.5),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Тізімге кері қайту'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Book book;

  const _BottomActionBar({required this.book});

  @override
  Widget build(BuildContext context) {
    final inCart = context.select((CartBloc bloc) => bloc.state.contains(book));

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Бағасы',
                        style:
                            TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatPrice(book.price),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    // Оқиға жібереміз; күйді BLoC өзі өзгертеді.
                    final added = !inCart;
                    context.read<CartBloc>().add(
                        added ? AddProductEvent(book) : RemoveProductEvent(book.id));
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        content: Text(added
                            ? '«${book.title}» себетке қосылды!'
                            : '«${book.title}» себеттен алынды'),
                        action: added
                            ? SnackBarAction(
                                label: 'Себет',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const CartScreen()),
                                ),
                              )
                            : null,
                      ));
                  },
                  icon: Icon(inCart
                      ? Icons.check_circle
                      : Icons.shopping_bag_outlined),
                  label: Text(
                    inCart ? 'Себетте' : 'Себетке қосу',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        inCart ? Colors.green.shade700 : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
