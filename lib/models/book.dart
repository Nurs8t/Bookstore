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
  });

  bool get isBestseller => rating >= 4.9;

  @override
  bool operator ==(Object other) => other is Book && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
