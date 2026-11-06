import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'book_cover.dart';
import 'tag_chip.dart';

class BookListTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookListTile({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<FavoritesProvider>().isFavorite(book);
    final inCart = context.watch<CartProvider>().contains(book);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(imagePath: book.imagePath, width: 60, height: 86),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: Colors.brown.shade400, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TagChip(label: book.category, compact: true),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppTheme.gold, size: 16),
                            const SizedBox(width: 2),
                            Text(
                              book.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatPrice(book.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: isFav ? 'Таңдаулыдан алу' : 'Таңдаулыға қосу',
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                    onPressed: () =>
                        context.read<FavoritesProvider>().toggle(book),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: inCart ? 'Себеттен алу' : 'Себетке қосу',
                    icon: Icon(
                      inCart ? Icons.shopping_bag : Icons.add_shopping_cart,
                      color: inCart ? AppTheme.primary : Colors.grey,
                    ),
                    onPressed: () => context.read<CartProvider>().toggle(book),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
