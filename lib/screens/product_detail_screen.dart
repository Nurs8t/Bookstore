import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/book_cover.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/rating_stars.dart';
import '../widgets/share_link_sheet.dart';
import '../widgets/tag_chip.dart';

/// Онлайн кітап мәліметтері — Hero, фото-карусель, бөлісу, "Себетке қосу".
/// Толық Product объектісі конструктор арқылы беріледі (Master-Detail).
class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кітап мәліметтері'),
        actions: [
          IconButton(
            tooltip: 'Бөлісу',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ShareLinkSheet.show(context, product),
          ),
          const CartBadgeButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoCarousel(product: product),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ProductInfo(product: product),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _AddToCartBar(product: product),
    );
  }
}

// ---------------------------------------------------------------------------
// Фото-карусель: PageView.builder + бет санағышы (1 / 3) + анимацияланған нүктелер
// ---------------------------------------------------------------------------
class _PhotoCarousel extends StatefulWidget {
  final Product product;

  const _PhotoCarousel({required this.product});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _viewLabels = ['Мұқаба', 'Жақыннан: жоғарғы бөлігі', 'Жақыннан: төменгі бөлігі'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isEmpty ? [product.imageUrl] : product.images;
    final sameImage = images.length > 1 && images.toSet().length == 1;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final cover = BookCover(
                      imagePath: images[index],
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 16,
                      iconSize: 64,
                    );
                    // API бір ғана мұқаба берсе, 2-3 беттер оны жақыннан көрсетеді.
                    final Widget content = (!sameImage || index == 0)
                        ? cover
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Transform.scale(
                              scale: 1.9,
                              alignment: index == 1
                                  ? Alignment.topCenter
                                  : Alignment.bottomCenter,
                              child: cover,
                            ),
                          );
                    final image = Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: content,
                    );
                    // Тек 1-сурет Hero: тізімдегі thumbnail осы жерге "ұшып" келеді.
                    return index == 0
                        ? Hero(tag: 'product_image_${product.id}', child: image)
                        : image;
                  },
                ),
                // Беттің атауы (бір мұқаба болса): Мұқаба / Жақыннан
                if (sameImage && _currentPage < _viewLabels.length)
                  Positioned(
                    left: 16,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.brown.shade100),
                      ),
                      child: Text(
                        _viewLabels[_currentPage],
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                // Бет санағышы: 1 / 3
                Positioned(
                  top: 12,
                  right: 16,
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
              ],
            ),
          ),
          // Анимацияланған нүктелер: белсенді нүкте ұзарады
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
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
                      color: isActive ? AppTheme.primary : Colors.brown.shade100,
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

// ---------------------------------------------------------------------------
// Атауы, баға, санат белгісі, рейтинг, толық сипаттама
// ---------------------------------------------------------------------------
class _ProductInfo extends StatelessWidget {
  final Product product;

  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            TagChip(
              label: product.category,
              background: Colors.brown.shade100,
              foreground: AppTheme.textDark,
            ),
            TagChip(
              label: 'ID: ${product.id}',
              background: Colors.grey.shade200,
              foreground: Colors.grey.shade800,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Авторы: ${product.author}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            RatingStars(rating: product.rating, size: 20),
            const SizedBox(width: 6),
            Text(
              product.rating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '(${product.reviewCount} пікір)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          formatPrice(product.price.round()),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Сипаттама',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: TextStyle(color: Colors.grey.shade800, height: 1.55, fontSize: 14.5),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Тізімге кері қайту'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky "Себетке қосу" панелі — LAB 9 CartProvider-мен синхронды
// ---------------------------------------------------------------------------
class _AddToCartBar extends StatelessWidget {
  final Product product;

  const _AddToCartBar({required this.product});

  @override
  Widget build(BuildContext context) {
    final book = product.toBook();
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
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<CartProvider>().toggle(book);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        content: Text(inCart
                            ? 'Себеттен алынды'
                            : 'Себетке қосылды!'),
                        duration: const Duration(seconds: 2),
                      ));
                  },
                  icon: Icon(inCart ? Icons.check_circle : Icons.add_shopping_cart),
                  label: Text(
                    inCart ? 'Себетте' : 'Себетке қосу',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: inCart ? Colors.green.shade700 : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
