import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/book_cover.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/tag_chip.dart';
import 'cart_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

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
        actions: const [CartBadgeButton()],
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
                          child: _CoverHeader(book: book, height: 440),
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
                _CoverHeader(book: book, height: 290),
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

class _CoverHeader extends StatelessWidget {
  final Book book;
  final double height;

  const _CoverHeader({required this.book, required this.height});

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<FavoritesProvider>().isFavorite(book);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.brown.shade200, AppTheme.background],
                ),
              ),
            ),
          ),
          Center(
            child: DecoratedBox(
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
              child: BookCover(
                imagePath: book.imagePath,
                height: height * 0.78,
                width: height * 0.78 * 0.66,
                borderRadius: 12,
                iconSize: 64,
              ),
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
              color: isFav ? AppTheme.primary : Colors.grey,
              size: 22,
              onPressed: () {
                context.read<FavoritesProvider>().toggle(book);
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
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatPrice(book.price),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Авторы: ${book.author}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
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
              color: Colors.grey.shade800, height: 1.55, fontSize: 14.5),
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
        color: AppTheme.textDark,
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Book book;

  const _BottomActionBar({required this.book});

  @override
  Widget build(BuildContext context) {
    final inCart = context.watch<CartProvider>().contains(book);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Бағасы',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(
                    formatPrice(book.price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final cart = context.read<CartProvider>();
                    cart.toggle(book);
                    final added = cart.contains(book);
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
