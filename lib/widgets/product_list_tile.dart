import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'book_cover.dart';
import 'rating_stars.dart';
import 'tag_chip.dart';

/// Онлайн кітапхананың жолы: мұқаба (Hero), атауы, автор, санат, рейтинг, баға.
class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListTile({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero tag деталь экранындағы карусельдің 1-суретімен бірдей.
              Hero(
                tag: 'product_image_${product.id}',
                child: BookCover(
                  imagePath: product.imageUrl,
                  width: 76,
                  height: 92,
                  borderRadius: 10,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.brown.shade400, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TagChip(label: product.category, compact: true),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RatingStars(rating: product.rating, size: 15),
                        Text(
                          '${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(product.price.round()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
