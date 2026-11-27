import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/blocs/diary/diary_cubit.dart';
import 'package:kazakh_book_shop/models/diary_entry.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';
import 'package:kazakh_book_shop/services/location_service.dart';

/// Оқырман күнделігі: модель, GPS логикасы (нағыз GPS-сіз), Cubit + SQLite + файлдар.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = DatabaseHelper.instance..databasePathOverride = inMemoryDatabasePath;

  final narxoz = GeoFix(
    latitude: 43.238949,
    longitude: 76.889709,
    accuracy: 12.4,
    altitude: 812,
    timestamp: DateTime(2026, 11, 24, 14, 30, 15),
  );

  group('Модель', () {
    test('Координаттар пішімі: N/E және S/W', () {
      expect(narxoz.shortLabel, '43.2389° N, 76.8897° E');
      expect(formatCoordinates(-33.8688, -151.2093), '33.8688° S, 151.2093° W');
    });

    test('toRow → fromRow: барлық өріс сақталады', () {
      final entry = DiaryEntry(
        id: 5,
        photoFile: 'diary_1.jpg',
        caption: 'Кампуста',
        bookTitle: 'Абай жолы',
        location: narxoz,
        createdAt: DateTime(2026, 11, 24, 14, 31),
      );
      final back = DiaryEntry.fromRow(entry.toRow());
      expect(back.id, 5);
      expect(back.photoFile, 'diary_1.jpg');
      expect(back.bookTitle, 'Абай жолы');
      expect(back.location!.latitude, 43.238949);
      expect(back.location!.accuracy, 12.4);
      expect(back.location!.timestamp, DateTime(2026, 11, 24, 14, 30, 15));
      expect(back.createdAt, DateTime(2026, 11, 24, 14, 31));
    });

    test('Координатсыз жазба (рұқсат берілмеген)', () {
      final entry = DiaryEntry(photoFile: 'a.jpg', caption: 'Үйде', createdAt: DateTime(2026));
      expect(DiaryEntry.fromRow(entry.toRow()).location, isNull);
    });
  });

  group('LocationService (жалған GPS)', () {
    test('Бәрі дұрыс: рұқсат бар → координаттар', () async {
      final gw = _FakeGateway(permission: LocationPermission.whileInUse, fix: narxoz);
      final result = await LocationService(gateway: gw).getCurrent();
      expect(result, isA<LocationFound>().having((r) => r.fix.latitude, 'lat', 43.238949));
      expect(gw.requested, isFalse); // рұқсат бұрыннан бар — қайта сұралмайды
    });

    test('GPS өшірулі → LocationServiceDisabled, рұқсат сұралмайды', () async {
      final gw = _FakeGateway(serviceEnabled: false);
      expect(await LocationService(gateway: gw).getCurrent(), isA<LocationServiceDisabled>());
      expect(gw.requested, isFalse);
    });

    test('Алғаш рет: denied → сұраймыз → рұқсат берді', () async {
      final gw = _FakeGateway(
        permission: LocationPermission.denied,
        afterRequest: LocationPermission.whileInUse,
        fix: narxoz,
      );
      expect(await LocationService(gateway: gw).getCurrent(), isA<LocationFound>());
      expect(gw.requested, isTrue);
    });

    test('Сұрағанда бас тартты → LocationPermissionDenied (құламайды)', () async {
      final gw = _FakeGateway(permission: LocationPermission.denied, afterRequest: LocationPermission.denied);
      expect(await LocationService(gateway: gw).getCurrent(), isA<LocationPermissionDenied>());
    });

    test('«Қайта сұрамау» → LocationPermissionDeniedForever', () async {
      final gw = _FakeGateway(permission: LocationPermission.deniedForever);
      expect(await LocationService(gateway: gw).getCurrent(), isA<LocationPermissionDeniedForever>());
      expect(gw.requested, isFalse); // жүйе бәрібір терезе шығармайды
    });

    test('GPS уақыты өтті / қате → LocationFailed, exception сыртқа шықпайды', () async {
      final gw = _FakeGateway(permission: LocationPermission.always, error: Exception('timeout'));
      expect(await LocationService(gateway: gw).getCurrent(), isA<LocationFailed>());
    });
  });

  group('DiaryCubit (SQLite + файлдар)', () {
    late Directory tmp;
    late Directory photos;

    setUp(() async {
      await db.deleteDatabaseFile();
      tmp = Directory.systemTemp.createTempSync('diary_test_');
      photos = Directory(p.join(tmp.path, 'diary_photos'))..createSync();
    });
    tearDown(() => tmp.deleteSync(recursive: true));
    tearDownAll(db.close);

    /// image_picker қайтаратын уақытша файлдың орнына.
    String fakePickedPhoto() {
      final f = File(p.join(tmp.path, 'image_picker_123.jpg'))..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
      return f.path;
    }

    DiaryCubit build() => DiaryCubit(db: db, photosDirectory: () async => photos.path);

    test('add(): сурет тұрақты папкаға көшіріледі, жазба SQLite-та', () async {
      final cubit = build();
      await cubit.load();
      final saved = await cubit.add(
        tempPhotoPath: fakePickedPhoto(),
        caption: '  Кампуста  ',
        bookTitle: 'Ұлпан',
        location: narxoz,
      );

      expect(saved.id, isNotNull);
      expect(saved.caption, 'Кампуста');
      expect(File(cubit.state.photoPathOf(saved)!).existsSync(), isTrue);
      expect(cubit.state.count, 1);
      expect(cubit.state.geotaggedCount, 1);

      // «Қолданбаны қайта ашу»
      final reopened = build();
      await reopened.load();
      expect(reopened.state.entries.single.bookTitle, 'Ұлпан');
      expect(reopened.state.entries.single.location!.shortLabel, '43.2389° N, 76.8897° E');
      await cubit.close();
      await reopened.close();
    });

    test('Жаңа жазба тізімнің басында', () async {
      final cubit = build();
      await cubit.load();
      await cubit.add(tempPhotoPath: fakePickedPhoto(), caption: 'Бірінші');
      await cubit.add(tempPhotoPath: fakePickedPhoto(), caption: 'Екінші');
      expect(cubit.state.entries.map((e) => e.caption), ['Екінші', 'Бірінші']);
      await cubit.close();
    });

    test('delete(): жазба да, сурет файлы да өшеді', () async {
      final cubit = build();
      await cubit.load();
      final saved = await cubit.add(tempPhotoPath: fakePickedPhoto(), caption: 'Өшіріледі');
      final file = File(cubit.state.photoPathOf(saved)!);

      await cubit.delete(saved);
      expect(cubit.state.entries, isEmpty);
      expect(file.existsSync(), isFalse);
      expect(await db.getDiaryEntries(), isEmpty);
      await cubit.close();
    });
  });
}

/// Нағыз Geolocator-дің орнына: әр сценарийді қолмен береміз.
class _FakeGateway implements LocationGateway {
  _FakeGateway({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    LocationPermission? afterRequest,
    this.fix,
    this.error,
  }) : afterRequest = afterRequest ?? permission;

  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission afterRequest;
  final GeoFix? fix;
  final Object? error;
  bool requested = false;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requested = true;
    return afterRequest;
  }

  @override
  Future<GeoFix> currentPosition() async {
    if (error != null) throw error!;
    return fix!;
  }

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<bool> openAppSettings() async => true;
}
