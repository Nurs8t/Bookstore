import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// 5 жұлдызды рейтинг (толық / жарты / бос).
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 0.75;
        final half = !filled && rating >= i + 0.25;
        return Icon(
          filled
              ? Icons.star_rounded
              : (half ? Icons.star_half_rounded : Icons.star_outline_rounded),
          color: AppTheme.gold,
          size: size,
        );
      }),
    );
  }
}
