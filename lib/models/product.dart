import 'book.dart';

/// LAB 10: fakestoreapi.com/products жауабынан келетін тауар моделі.
///
/// JSON мысалы:
/// {
///   "id": 1,
///   "title": "Fjallraven - Foldsack No. 1 Backpack",
///   "price": 109.95,
///   "description": "...",
///   "category": "men's clothing",
///   "image": "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg",
///   "rating": { "rate": 3.9, "count": 120 }
/// }
class Product {
  final int id;
  final String title;
  final double price; // USD
  final String description;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  /// Карусельге арналған суреттер. API бір ғана сурет береді, сондықтан
  /// `images` өрісі жоқ болса, негізгі сурет 3 рет қайталанады.
  final List<String> images;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.images,
  });

  /// Type-safe deserialization:
  /// * әр өріс null болса, әдепкі мән қойылады (null-safe fallback);
  /// * сандар `num` арқылы оқылады: API `price: 22` (int) немесе `22.3` (double)
  ///   жіберсе де, `as double` сияқты қате болмайды.
  factory Product.fromJson(Map<String, dynamic> json) {
    final ratingJson = json['rating'];
    final rating = ratingJson is Map<String, dynamic> ? ratingJson : const <String, dynamic>{};

    final imageUrl = _asString(json['image']);
    final extraImages = (json['images'] is List)
        ? (json['images'] as List).whereType<String>().where((u) => u.isNotEmpty).toList()
        : <String>[];

    return Product(
      id: _asInt(json['id']),
      title: _asString(json['title'], fallback: 'Атауы жоқ тауар'),
      price: _asDouble(json['price']),
      description: _asString(json['description'], fallback: 'Сипаттама жоқ.'),
      category: _asString(json['category'], fallback: 'Басқа'),
      imageUrl: imageUrl,
      rating: _asDouble(rating['rate']),
      reviewCount: _asInt(rating['count']),
      images: extraImages.isNotEmpty
          ? extraImages
          : (imageUrl.isEmpty ? const [] : [imageUrl, imageUrl, imageUrl]),
    );
  }

  /// Deep Link: narxoz://store/product/{id}
  String get deepLink => 'narxoz://store/product/$id';

  /// Себетке салу үшін Book-қа айналдыру (LAB 9 CartProvider-мен үйлесімді).
  /// Бағасы теңгеге шамамен ауыстырылады.
  Book toBook() => Book(
        id: 'api-$id',
        title: title,
        author: category,
        price: (price * usdToKzt).round(),
        rating: rating,
        reviewsCount: reviewCount,
        imagePath: imageUrl,
        synopsis: description,
        category: category,
        tags: [category],
      );

  /// Шамамен алынған бағам (демо үшін тұрақты мән).
  static const int usdToKzt = 500;

  // ---------- Қауіпсіз түрлендіргіштер ----------

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble(); // int те, double да жарайды
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _asString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }
}
