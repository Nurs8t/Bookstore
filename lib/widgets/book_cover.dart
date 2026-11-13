import 'package:flutter/material.dart';

/// Кітап мұқабасы немесе тауар суреті.
/// `imagePath` http(s) сілтемесі болса — желіден (Image.network),
/// әйтпесе assets-тен (Image.asset) жүктеледі.
/// Сурет табылмаса — әдемі placeholder көрсетеді.
class BookCover extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final double borderRadius;
  final double iconSize;

  const BookCover({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.iconSize = 28,
  });

  bool get _isNetwork => imagePath.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final image = _isNetwork
        ? Container(
            width: width,
            height: height,
            color: Colors.white,
            padding: const EdgeInsets.all(4),
            child: Image.network(
              imagePath,
              fit: BoxFit.contain, // тауар суреттері ақ фонда, кесілмесін
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
          )
        : Image.asset(
            imagePath,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.brown.shade300, Colors.brown.shade600],
          ),
        ),
        child: Icon(
          _isNetwork ? Icons.image_not_supported_outlined : Icons.menu_book,
          color: Colors.white,
          size: iconSize,
        ),
      );
}
