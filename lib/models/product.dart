import 'book.dart';

/// API-дан келетін кітап моделі (JSON → Dart). Қолданбада Book-қа айналдырылады.
///
/// API: https://raw.githubusercontent.com/Nurs8t/Bookstore/main/api/books.json
/// JSON мысалы:
/// {
///   "id": 2,
///   "title": "Абай жолы (1-том)",
///   "author": "Мұхтар Әуезов",
///   "price": 3500.0,
///   "description": "...",
///   "category": "Роман-эпопея",
///   "image": "https://raw.githubusercontent.com/.../my_book1.jpeg",
///   "rating": { "rate": 5, "count": 3210 }
/// }
class Product {
  final int id;
  final String title;
  final String author;
  final double price; // теңге
  final String description;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  /// Карусельге арналған суреттер. JSON-да `images` тізімі болмаса,
  /// негізгі мұқаба 3 рет қолданылады (карусель оны 3 түрлі көріністе көрсетеді).
  final List<String> images;
  final List<String> tags;

  const Product({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.images,
    this.tags = const [],
  });

  /// Type-safe deserialization:
  /// * әр өріс null немесе жоқ болса, әдепкі мән қойылады (null-safe fallback);
  /// * сандар `num` арқылы оқылады: API `price: 3000` (int) немесе `1490.5` (double)
  ///   жіберсе де, `as double` сияқты қате болмайды — `(value as num).toDouble()`.
  factory Product.fromJson(Map<String, dynamic> json) {
    final ratingJson = json['rating'];
    final rating =
        ratingJson is Map<String, dynamic> ? ratingJson : const <String, dynamic>{};

    final imageUrl = _asString(json['image']);
    final extraImages = (json['images'] is List)
        ? (json['images'] as List)
            .whereType<String>()
            .where((u) => u.isNotEmpty)
            .toList()
        : <String>[];

    return Product(
      id: _asInt(json['id']),
      title: _asString(json['title'], fallback: 'Атауы жоқ кітап'),
      author: _asString(json['author'], fallback: 'Автор белгісіз'),
      price: _asDouble(json['price']),
      description: _asString(json['description'], fallback: 'Сипаттама жоқ.'),
      category: _asString(json['category'], fallback: 'Басқа'),
      imageUrl: imageUrl,
      rating: _asDouble(rating['rate']),
      reviewCount: _asInt(rating['count']),
      images: extraImages.isNotEmpty ? extraImages : [imageUrl, imageUrl, imageUrl],
      tags: (json['tags'] is List)
          ? (json['tags'] as List).whereType<String>().toList()
          : const [],
    );
  }

  /// Deep Link: narxoz://store/product/{id}
  String get deepLink => 'narxoz://store/product/$id';

  /// API моделін қолданбаның Book моделіне айналдыру
  /// (каталог, таңдаулылар, себет — бәрі Book-пен жұмыс істейді).
  Book toBook() => Book(
        id: '$id',
        title: title,
        author: author,
        price: price.round(),
        rating: rating,
        reviewsCount: reviewCount,
        imagePath: imageUrl,
        synopsis: description,
        category: category,
        tags: tags.isNotEmpty ? tags : [category],
        images: images,
      );

  // ---------- Қауіпсіз түрлендіргіштер ----------

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble(); // = (json['price'] as num).toDouble()
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _asString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }
}
