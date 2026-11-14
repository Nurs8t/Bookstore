class Book {
  final String id;
  final String title;
  final String author;
  final int price;
  final double rating;
  final int reviewsCount;
  final String imagePath;
  final String synopsis;
  final String category;
  final List<String> tags;

  /// Карусельге арналған суреттер (API-дан келеді). Бос болса — тек мұқаба.
  final List<String> images;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.rating,
    required this.reviewsCount,
    required this.imagePath,
    required this.synopsis,
    required this.category,
    required this.tags,
    this.images = const [],
  });

  bool get isBestseller => rating >= 4.9;

  /// Карусель үшін суреттер тізімі: API бір мұқаба ғана берсе,
  /// ол 3 рет қолданылады (2-3 беттер мұқабаны жақыннан көрсетеді).
  List<String> get gallery => images.isNotEmpty ? images : [imagePath, imagePath, imagePath];

  /// Deep Link: narxoz://store/product/{id}
  String get deepLink => 'narxoz://store/product/$id';

  @override
  bool operator ==(Object other) => other is Book && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
