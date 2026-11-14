import 'package:flutter/material.dart';

/// Кітап мұқабасы.
/// `imagePath` http(s) сілтемесі болса — желіден (Image.network),
/// әйтпесе assets-тен (Image.asset) жүктеледі.
/// Сурет жоқ немесе жүктелмесе — әдемі placeholder көрсетеді.
class BookCover extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final double borderRadius;
  final double iconSize;
  final BoxFit fit;

  const BookCover({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.iconSize = 28,
    this.fit = BoxFit.cover,
  });

  bool get _isNetwork => imagePath.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (imagePath.isEmpty) {
      image = _placeholder();
    } else if (_isNetwork) {
      image = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                width: width,
                height: height,
                color: Colors.brown.shade50,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else {
      image = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

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
        child: Icon(Icons.menu_book, color: Colors.white, size: iconSize),
      );
}
