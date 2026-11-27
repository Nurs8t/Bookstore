import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../blocs/diary/diary_cubit.dart';
import '../blocs/favorites/favorites_cubit.dart';
import '../blocs/orders/orders_cubit.dart';
import '../models/diary_entry.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Оқырман күнделігі: кітаптың / оқыған жердің суреті + GPS координаттары + жазба.
///
///   [Сурет алаңы]  ← камера (ImageSource.camera) немесе галерея (ImageSource.gallery)
///   [GPS панелі]   ← Geolocator: ендік, бойлық, дәлдік, биіктік, уақыт
///   [Жазба + кітап] → «Күнделікке сақтау» → DiaryCubit → SQLite + Documents/diary_photos
///   [Жазбалар тізімі]
///
/// Жаңа жазбаның жобасы (сурет, координаттар, мәтін) — ephemeral state, сондықтан
/// StatefulWidget. Сақталған жазбалар — app state, DiaryCubit-те.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key, this.initialBookTitle, this.media, this.location});

  /// Кітап бетінен ашылса — сол кітап алдын ала таңдалады.
  final String? initialBookTitle;

  /// Тесттерде ауыстыру үшін.
  final MediaService? media;
  final LocationService? location;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late final MediaService _media = widget.media ?? MediaService();
  late final LocationService _location = widget.location ?? LocationService();
  final _captionController = TextEditingController();

  String? _photoPath; // уақытша файл (image_picker)
  GeoFix? _fix;
  bool _locating = false;
  String? _locationNote; // рұқсат берілмесе — панельде түсіндірме
  late String? _bookTitle = widget.initialBookTitle;
  String? _captionError;
  bool _saving = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- сурет

  /// Модальды төменгі парақ: Камера немесе Галерея.
  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Камерамен түсіру'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Галереядан таңдау'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    final result = await _media.pick(source);
    if (!mounted) return;
    switch (result) {
      case MediaPicked(:final path):
        setState(() => _photoPath = path);
        // Сурет түскен соң координаттарды автоматты түрде аламыз.
        if (_fix == null && !_locating) await _fetchLocation();
      case MediaCancelled():
        break;
      case MediaPermissionDenied(:final permanently):
        if (permanently) {
          await _openSettingsDialog(
            title: 'Камераға рұқсат жоқ',
            message: 'Сіз бұрын камераға рұқсат бермедіңіз. Қосу үшін қолданба баптауларын ашыңыз.',
            onOpen: MediaService.openAppSettings,
          );
        } else {
          _snack('Камераға рұқсат берілмеді. Галереяны қолдануға болады.');
        }
      case MediaUnavailable(:final message):
        _snack(message);
    }
  }

  // ---------------------------------------------------------------- GPS

  Future<void> _fetchLocation() async {
    setState(() {
      _locating = true;
      _locationNote = null;
    });
    final result = await _location.getCurrent();
    if (!mounted) return;
    setState(() => _locating = false);

    switch (result) {
      case LocationFound(:final fix):
        setState(() => _fix = fix);
      case LocationServiceDisabled():
        setState(() => _locationNote = 'Құрылғыда геолокация өшірулі');
        await _openSettingsDialog(
          title: 'GPS өшірулі',
          message: 'Координаттарды алу үшін құрылғыда геолокацияны (Location Services) қосыңыз.',
          onOpen: _location.openLocationSettings,
          openLabel: 'GPS баптаулары',
        );
      case LocationPermissionDenied():
        setState(() => _locationNote = 'Геолокацияға рұқсат берілмеді — жазба координатсыз сақталады');
      case LocationPermissionDeniedForever():
        setState(() => _locationNote = 'Геолокацияға рұқсат біржола жабық');
        await _openSettingsDialog(
          title: 'Геолокацияға рұқсат жоқ',
          message: '«Қайта сұрамау» таңдалған. Рұқсатты тек қолданба баптауларынан қосуға болады.',
          onOpen: _location.openAppSettings,
        );
      case LocationFailed(:final message):
        setState(() => _locationNote = 'Координаттар алынбады');
        _snack(message);
    }
  }

  // ---------------------------------------------------------------- сақтау

  Future<void> _save() async {
    final photo = _photoPath;
    if (photo == null) return;
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      setState(() => _captionError = 'Жазба мәтінін енгізіңіз');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _captionError = null;
    });
    try {
      await context.read<DiaryCubit>().add(
            tempPhotoPath: photo,
            caption: caption,
            bookTitle: _bookTitle,
            location: _fix,
          );
      if (!mounted) return;
      _captionController.clear();
      setState(() {
        _photoPath = null;
        _fix = null;
        _locationNote = null;
        _saving = false;
      });
      _snack('Жазба күнделікке сақталды ✓');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Жазбаны сақтау мүмкін болмады: $e', error: true);
    }
  }

  // ---------------------------------------------------------------- көмекшілер

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : null,
      ));
  }

  Future<void> _openSettingsDialog({
    required String title,
    required String message,
    required Future<bool> Function() onOpen,
    String openLabel = 'Баптауларды ашу',
  }) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Кейін')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(openLabel)),
        ],
      ),
    );
    if (open == true) await onOpen();
  }

  /// Таңдаулылар мен сатып алынған кітаптар атаулары (қайталанбайды).
  List<String> _bookOptions(BuildContext context) {
    final titles = <String>{
      if (widget.initialBookTitle != null) widget.initialBookTitle!,
      ...context.watch<FavoritesCubit>().state.books.map((b) => b.title),
      for (final order in context.watch<OrdersCubit>().state.orders) ...order.lines.map((l) => l.title),
    };
    return titles.toList();
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryCubit>().state;
    final books = _bookOptions(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Оқырман күнделігі')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _PhotoPreview(
                path: _photoPath,
                onTap: _saving ? null : _chooseSource,
                onClear: _photoPath == null || _saving ? null : () => setState(() => _photoPath = null),
              ),
              const SizedBox(height: 12),
              _GpsPanel(fix: _fix, locating: _locating, note: _locationNote),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _saving ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Камера'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Галерея'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _locating || _saving ? null : _fetchLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Ағымдағы GPS орнын алу'),
              ),
              const Divider(height: 32),
              DropdownButtonFormField<String?>(
                initialValue: _bookTitle,
                isExpanded: true, // ұзын атау тар экранда сыймаса — «…»
                decoration: const InputDecoration(
                  labelText: 'Кітап (міндетті емес)',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Кітапсыз')),
                  for (final title in books)
                    DropdownMenuItem<String?>(
                      value: title,
                      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _saving ? null : (v) => setState(() => _bookTitle = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _captionController,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_captionError != null) setState(() => _captionError = null);
                },
                decoration: InputDecoration(
                  labelText: 'Жазба',
                  hintText: 'Мысалы: Narxoz кітапханасында «Абай жолын» бастадым',
                  prefixIcon: const Icon(Icons.edit_note),
                  errorText: _captionError,
                ),
              ),
              const SizedBox(height: 4),
              FilledButton.icon(
                onPressed: _photoPath == null || _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_photoPath == null ? 'Алдымен сурет таңдаңыз' : 'Күнделікке сақтау'),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Icon(Icons.auto_stories_outlined, color: context.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Күнделік жазбалары (${diary.count})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (diary.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Әзірге жазба жоқ. Кітабыңызды суретке түсіріп, алғашқы жазбаны қалдырыңыз.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                for (final entry in diary.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DiaryEntryCard(entry: entry, photoPath: diary.photoPathOf(entry)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Сурет алаңы: таңдалса — `Image.file`, әйтпесе камера белгішесі.
class _PhotoPreview extends StatelessWidget {
  final String? path;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _PhotoPreview({required this.path, this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    final photo = path;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: context.surfaceCard,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  Image.file(
                    File(photo),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PhotoPlaceholder(text: 'Суретті ашу мүмкін болмады'),
                  )
                else
                  const _PhotoPlaceholder(text: 'Сурет таңдалмаған\nБасыңыз: камера немесе галерея'),
                if (photo != null && onClear != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Суретті алып тастау',
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final String text;

  const _PhotoPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 56, color: Colors.brown.shade300),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

/// GPS панелі: іздеу кезінде спиннер, табылса — ендік, бойлық, дәлдік, биіктік, уақыт.
class _GpsPanel extends StatelessWidget {
  final GeoFix? fix;
  final bool locating;
  final String? note;

  const _GpsPanel({required this.fix, required this.locating, this.note});

  @override
  Widget build(BuildContext context) {
    final f = fix;
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Icon(icon, size: 18, color: context.accent),
              const SizedBox(width: 8),
              Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
              Expanded(
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    final Widget content;
    if (locating) {
      content = const Row(
        children: [
          SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6)),
          SizedBox(width: 12),
          Expanded(child: Text('GPS сигналын іздеуде…')),
        ],
      );
    } else if (f == null) {
      content = Row(
        children: [
          Icon(Icons.location_off_outlined, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note ?? 'Координаттар әлі алынбаған',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      );
    } else {
      content = Column(
        children: [
          row(Icons.place_outlined, 'Ендік', f.latitude.toStringAsFixed(6)),
          row(Icons.place_outlined, 'Бойлық', f.longitude.toStringAsFixed(6)),
          row(Icons.gps_fixed, 'Дәлдік', '± ${f.accuracy.toStringAsFixed(1)} м'),
          row(Icons.terrain_outlined, 'Биіктік', '${f.altitude.toStringAsFixed(0)} м'),
          row(Icons.schedule, 'Уақыт', formatTimestamp(f.timestamp)),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: context.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(14), child: content),
    );
  }
}

/// Тізімдегі бір жазба: шағын сурет, мәтін, кітап, координаттар, уақыт.
/// Солға сырғытса — растаумен өшіріледі.
class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final String? photoPath;

  const _DiaryEntryCard({required this.entry, required this.photoPath});

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Жазбаны өшіру'),
        content: Text('«${entry.caption}» және оның суреті біржола өшіріледі.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Жоқ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Иә, өшіру')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final grey = TextStyle(color: Colors.grey.shade600, fontSize: 12.5);
    final location = entry.location;

    return Dismissible(
      key: ValueKey('diary-${entry.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => context.read<DiaryCubit>().delete(entry),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: context.surfaceCard,
        elevation: 1.5,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DiaryEntryScreen(entry: entry, photoPath: photoPath)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'diary-photo-${entry.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: _EntryPhoto(path: photoPath, cacheWidth: 216),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (entry.bookTitle != null)
                        Text(
                          '📖 ${entry.bookTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: context.accent),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        location == null ? '📍 Координатсыз' : '📍 ${location.shortLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: grey,
                      ),
                      Text(formatTimestamp(entry.createdAt), style: grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Сурет файлы: жоқ болса (өшірілген / тест) — белгіше.
class _EntryPhoto extends StatelessWidget {
  final String? path;
  final int? cacheWidth;

  const _EntryPhoto({required this.path, this.cacheWidth});

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Colors.brown.shade50,
      child: Icon(Icons.image_not_supported_outlined, color: Colors.brown.shade300),
    );
    final p = path;
    if (p == null) return fallback;
    return Image.file(
      File(p),
      fit: BoxFit.cover,
      // Тізімде 72 px сурет үшін 1080 px-ті толық декодтамаймыз — жад үнемделеді.
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// Жазбаның толық беті: үлкен сурет және барлық координаттар.
class DiaryEntryScreen extends StatelessWidget {
  final DiaryEntry entry;
  final String? photoPath;

  const DiaryEntryScreen({super.key, required this.entry, required this.photoPath});

  @override
  Widget build(BuildContext context) {
    final location = entry.location;
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: context.accent),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Күнделік жазбасы')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Hero(
                tag: 'diary-photo-${entry.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(aspectRatio: 4 / 3, child: _EntryPhoto(path: photoPath)),
                ),
              ),
              const SizedBox(height: 16),
              Text(entry.caption, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (entry.bookTitle != null) line(Icons.menu_book_outlined, entry.bookTitle!),
              line(Icons.schedule, formatTimestamp(entry.createdAt)),
              if (location == null)
                line(Icons.location_off_outlined, 'Координаттар жоқ (рұқсат берілмеген)')
              else ...[
                line(Icons.place_outlined, location.shortLabel),
                line(Icons.gps_fixed, 'Дәлдік: ± ${location.accuracy.toStringAsFixed(1)} м'),
                line(Icons.terrain_outlined, 'Биіктік: ${location.altitude.toStringAsFixed(0)} м'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
