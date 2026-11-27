import 'package:geolocator/geolocator.dart';

import '../models/diary_entry.dart';

/// GPS сұрауының нәтижесі. Sealed: UI әр жағдайды `switch` арқылы міндетті түрде өңдейді.
sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  final GeoFix fix;
  const LocationFound(this.fix);
}

/// Құрылғыда GPS (Location Services) өшірулі.
final class LocationServiceDisabled extends LocationResult {
  const LocationServiceDisabled();
}

/// Пайдаланушы «Рұқсат бермеу» басты — келесі жолы қайта сұрауға болады.
final class LocationPermissionDenied extends LocationResult {
  const LocationPermissionDenied();
}

/// «Қайта сұрамау» (Android) немесе iOS-та бір рет бас тартқан — енді тек баптаулардан.
final class LocationPermissionDeniedForever extends LocationResult {
  const LocationPermissionDeniedForever();
}

final class LocationFailed extends LocationResult {
  final String message;
  const LocationFailed(this.message);
}

/// Geolocator-ге жұқа қабат. Интерфейс болғандықтан тестте жалған (fake) нұсқасын береміз —
/// нағыз GPS-сіз барлық тармақты тексеруге болады.
abstract interface class LocationGateway {
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<GeoFix> currentPosition();
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
}

class GeolocatorGateway implements LocationGateway {
  const GeolocatorGateway();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  @override
  Future<GeoFix> currentPosition() async {
    // `desiredAccuracy: LocationAccuracy.high` параметрінің жаңа түрі:
    // geolocator 10+ нұсқасында ол LocationSettings ішіне көшті.
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20), // ғимарат ішінде GPS ұзақ іздеуі мүмкін
      ),
    );
    return GeoFix(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      altitude: p.altitude,
      timestamp: p.timestamp,
    );
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

/// Ағымдағы орынды алу: GPS қосулы ма → рұқсат бар ма (жоқ болса сұраймыз) → координаттар.
class LocationService {
  LocationService({LocationGateway? gateway}) : _gw = gateway ?? const GeolocatorGateway();

  final LocationGateway _gw;

  Future<LocationResult> getCurrent() async {
    try {
      // 1) Құрылғыда геолокация мүлде өшірулі болса — рұқсат сұраудың мағынасы жоқ.
      if (!await _gw.isServiceEnabled()) return const LocationServiceDisabled();

      // 2) Рұқсатты тексеріп, қажет болса жүйелік терезе арқылы сұраймыз.
      var permission = await _gw.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _gw.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const LocationPermissionDenied();
        case LocationPermission.deniedForever:
          return const LocationPermissionDeniedForever();
        case LocationPermission.unableToDetermine:
          return const LocationFailed('Рұқсат күйін анықтау мүмкін болмады');
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }

      // 3) Координаттар.
      return LocationFound(await _gw.currentPosition());
    } catch (e) {
      // TimeoutException, PlatformException т.б. — қолданба құламайды.
      return LocationFailed('Координаттарды алу мүмкін болмады: $e');
    }
  }

  Future<bool> openLocationSettings() => _gw.openLocationSettings();

  Future<bool> openAppSettings() => _gw.openAppSettings();
}
