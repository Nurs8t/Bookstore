/// GPS нәтижесі: координаттар, дәлдік (метр), биіктік және уақыт.
class GeoFix {
  final double latitude;
  final double longitude;
  final double accuracy; // ± метр
  final double altitude; // метр
  final DateTime timestamp;

  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.timestamp,
  });

  /// 43.238949, 76.889709 → «43.2389° N, 76.8897° E»
  String get shortLabel => formatCoordinates(latitude, longitude);
}

/// Екі координатты оқуға ыңғайлы пішінге келтіру (оңтүстік/батыс — S/W).
String formatCoordinates(double lat, double lng, {int digits = 4}) {
  final ns = lat >= 0 ? 'N' : 'S';
  final ew = lng >= 0 ? 'E' : 'W';
  return '${lat.abs().toStringAsFixed(digits)}° $ns, ${lng.abs().toStringAsFixed(digits)}° $ew';
}

/// Оқырман күнделігінің бір жазбасы (SQLite `diary_entries` кестесінің бір жолы).
///
/// [photoFile] — сурет файлының АТЫ ғана (мысалы `diary_1732700000000.jpg`), толық жол емес:
/// iOS-та қолданба жаңарғанда немесе қайта орнатылғанда Documents папкасының жолы өзгереді,
/// сондықтан толық жолды сақтасақ, сурет «жоғалып» кетер еді.
class DiaryEntry {
  final int? id;
  final String photoFile;
  final String caption;
  final String? bookTitle;

  /// Пайдаланушы геолокацияға рұқсат бермесе — null (жазба координатсыз сақталады).
  final GeoFix? location;
  final DateTime createdAt;

  const DiaryEntry({
    this.id,
    required this.photoFile,
    required this.caption,
    this.bookTitle,
    this.location,
    required this.createdAt,
  });

  DiaryEntry withId(int newId) => DiaryEntry(
        id: newId,
        photoFile: photoFile,
        caption: caption,
        bookTitle: bookTitle,
        location: location,
        createdAt: createdAt,
      );

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'photo_file': photoFile,
        'caption': caption,
        'book_title': bookTitle,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'accuracy': location?.accuracy,
        'altitude': location?.altitude,
        'located_at': location?.timestamp.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory DiaryEntry.fromRow(Map<String, Object?> row) {
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    final created = DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int? ?? 0);
    return DiaryEntry(
      id: row['id'] as int?,
      photoFile: row['photo_file'] as String? ?? '',
      caption: row['caption'] as String? ?? '',
      bookTitle: row['book_title'] as String?,
      location: lat == null || lng == null
          ? null
          : GeoFix(
              latitude: lat,
              longitude: lng,
              accuracy: (row['accuracy'] as num?)?.toDouble() ?? 0,
              altitude: (row['altitude'] as num?)?.toDouble() ?? 0,
              timestamp: row['located_at'] == null
                  ? created
                  : DateTime.fromMillisecondsSinceEpoch(row['located_at'] as int),
            ),
      createdAt: created,
    );
  }
}
