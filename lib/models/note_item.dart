/// Оқу жазбасы (мысалы: «Абай жолының 1-томын оқып шығу»).
/// Тізім JSON мәтінге айналдырылып, shared_preferences-ке бір кілтпен жазылады.
class NoteItem {
  final String id;
  final String title;
  final String dateText;
  final bool isCompleted;

  const NoteItem({
    required this.id,
    required this.title,
    required this.dateText,
    this.isCompleted = false,
  });

  /// Жаңа жазба: id — уақыт белгісі, күні — бүгінгі күн мен уақыт.
  factory NoteItem.create(String title) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return NoteItem(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      dateText: '${two(now.day)}.${two(now.month)}.${now.year}, ${two(now.hour)}:${two(now.minute)}',
    );
  }

  NoteItem copyWith({bool? isCompleted}) => NoteItem(
        id: id,
        title: title,
        dateText: dateText,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  /// Dart объектісі → Map (jsonEncode-қа дайын).
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateText': dateText,
        'isCompleted': isCompleted,
      };

  /// Map → Dart объектісі. Өріс жоқ болса — қауіпсіз әдепкі мән.
  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        dateText: json['dateText'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
