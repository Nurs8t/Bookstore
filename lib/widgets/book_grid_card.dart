import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'book_cover.dart';
import 'round_icon_button.dart';

class BookGridCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookGridCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<FavoritesProvider>().isFavorite(book);
    final inCart = context.watch<CartProvider>().contains(book);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BookCover(
                      imagePath: book.imagePath, borderRadius: 0, iconSize: 40),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _RatingPill(rating: book.rating),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: RoundIconButton(
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                      size: 18,
                      onPressed: () =>
                          context.read<FavoritesProvider>().toggle(book),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: Colors.brown.shade400, fontSize: 11.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatPrice(book.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: inCart ? 'Себеттен алу' : 'Себетке қосу',
                        constraints: const BoxConstraints.tightFor(
                            width: 34, height: 34),
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              inCart ? AppTheme.primary : Colors.brown.shade50,
                          foregroundColor:
                              inCart ? Colors.white : AppTheme.primary,
                        ),
                        icon: Icon(
                            inCart ? Icons.check : Icons.add_shopping_cart),
                        onPressed: () =>
                            context.read<CartProvider>().toggle(book),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppTheme.gold, size: 14),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
