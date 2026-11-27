import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Суретті таңдау нәтижесі.
sealed class MediaResult {
  const MediaResult();
}

/// [path] — уақытша файл (image_picker кэші). Сақтағанда тұрақты папкаға көшіріледі.
final class MediaPicked extends MediaResult {
  final String path;
  const MediaPicked(this.path);
}

/// Пайдаланушы камераны/галереяны жауып шықты — қате емес.
final class MediaCancelled extends MediaResult {
  const MediaCancelled();
}

/// Камераға рұқсат жоқ. [permanently] — «Қайта сұрамау», тек баптаулардан қосылады.
final class MediaPermissionDenied extends MediaResult {
  final bool permanently;
  const MediaPermissionDenied({required this.permanently});
}

/// Камера жоқ (мысалы, iOS симуляторы) немесе басқа қате.
final class MediaUnavailable extends MediaResult {
  final String message;
  const MediaUnavailable(this.message);
}

/// Камера / галерея және суреттерді қолданба папкасында сақтау.
class MediaService {
  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const String folderName = 'diary_photos';

  /// [source] — ImageSource.camera немесе ImageSource.gallery.
  /// Сығымдау: imageQuality 80 (JPEG сапасы) және maxWidth 1080 px —
  /// 12 МП (≈4 МБ) сурет ≈200–400 КБ болады, тізім жылдам айналады.
  Future<MediaResult> pick(ImageSource source) async {
    // Android: камера рұқсатын permission_handler арқылы өзіміз тексереміз —
    // «Қайта сұрамау» (permanently denied) жағдайын ажырату үшін.
    // iOS: image_picker жүйелік терезені өзі шығарады (NSCameraUsageDescription мәтінімен).
    if (source == ImageSource.camera && defaultTargetPlatform == TargetPlatform.android) {
      final status = await ph.Permission.camera.request();
      if (status.isPermanentlyDenied) return const MediaPermissionDenied(permanently: true);
      if (!status.isGranted) return const MediaPermissionDenied(permanently: false);
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      return file == null ? const MediaCancelled() : MediaPicked(file.path);
    } on PlatformException catch (e) {
      // iOS: бұрын бас тартқан болса — 'camera_access_denied' / 'photo_access_denied'.
      if (e.code.contains('access_denied')) return const MediaPermissionDenied(permanently: true);
      if (e.code == 'no_available_camera') {
        return const MediaUnavailable('Бұл құрылғыда камера жоқ (симулятор?). Галереяны қолданыңыз.');
      }
      return MediaUnavailable(e.message ?? e.code);
    } catch (e) {
      return MediaUnavailable('$e');
    }
  }

  /// Суреттер тұрақты сақталатын папка (Documents/diary_photos).
  /// image_picker-дің уақытша файлын жүйе кез келген уақытта өшіре алады.
  static Future<String> photosDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, folderName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Уақытша суретті тұрақты папкаға көшіреді. Қайтаратыны — файл АТЫ.
  static Future<String> persist(String tempPath, String photosDir) async {
    final ext = p.extension(tempPath).isEmpty ? '.jpg' : p.extension(tempPath);
    final name = 'diary_${DateTime.now().microsecondsSinceEpoch}$ext';
    await File(tempPath).copy(p.join(photosDir, name));
    return name;
  }

  /// Ашық баптаулар (камераға «Қайта сұрамау» болса).
  static Future<bool> openAppSettings() => ph.openAppSettings();
}
