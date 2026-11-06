import 'package:flutter/material.dart';

/// Кітап мұқабасы. Сурет табылмаса — әдемі placeholder көрсетеді.
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
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
        ),
      ),
    );
  }
}
