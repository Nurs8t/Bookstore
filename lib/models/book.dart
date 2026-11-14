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

  // ---------- SQLite үшін сериализация ----------

  /// Book → Map (дерекқорға JSON мәтін ретінде сақтау үшін).
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'price': price,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'imagePath': imagePath,
        'synopsis': synopsis,
        'category': category,
        'tags': tags,
        'images': images,
      };

  /// Map → Book (дерекқордан оқығанда). Сандар `num` арқылы қауіпсіз оқылады.
  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        author: map['author'] as String? ?? '',
        price: (map['price'] as num? ?? 0).toInt(),
        rating: (map['rating'] as num? ?? 0).toDouble(),
        reviewsCount: (map['reviewsCount'] as num? ?? 0).toInt(),
        imagePath: map['imagePath'] as String? ?? '',
        synopsis: map['synopsis'] as String? ?? '',
        category: map['category'] as String? ?? '',
        tags: (map['tags'] as List? ?? const []).whereType<String>().toList(),
        images: (map['images'] as List? ?? const []).whereType<String>().toList(),
      );

  @override
  bool operator ==(Object other) => other is Book && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
