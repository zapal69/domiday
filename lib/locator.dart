import 'package:geolocator/geolocator.dart';

/// Наблюдение: координаты, точность и момент получения. Живёт только в
/// памяти на время одного определения; на диск не пишется.
class Observation {
  final double latitude;
  final double longitude;
  final double accuracyM;
  final DateTime at;
  const Observation({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.at,
  });
}

sealed class LocationResult {
  const LocationResult();
}

class Observed extends LocationResult {
  final Observation observation;
  const Observed(this.observation);
}

/// Разрешение не дано (в том числе «больше не спрашивать»).
class PermissionDenied extends LocationResult {
  final bool forever;
  const PermissionDenied({required this.forever});
}

/// Геолокация на устройстве выключена.
class ServiceDisabled extends LocationResult {
  const ServiceDisabled();
}

/// Координаты не получены: нет сигнала, истекло время, ошибка платформы.
class Unavailable extends LocationResult {
  const Unavailable();
}

abstract interface class LocationSource {
  /// [silent] — не спрашивать разрешение: только если оно уже дано
  /// (автопроверка при открытии приложения).
  Future<LocationResult> current({bool silent = false});

  /// Системные настройки: геолокации телефона ([service]) или разрешений
  /// приложения — когда включить определение можно только там.
  Future<void> openSettings({required bool service});
}

/// Одно приблизительное определение по явному действию пользователя.
/// Fused Location при наличии Google Play, иначе LocationManager
/// (поведение плагина geolocator). Ни фоновых обновлений, ни потока.
class GeolocatorSource implements LocationSource {
  const GeolocatorSource();

  @override
  Future<LocationResult> current({bool silent = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const ServiceDisabled();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && !silent) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const PermissionDenied(forever: true);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const PermissionDenied(forever: false);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 25),
        ),
      );
      return Observed(
        Observation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyM: position.accuracy,
          at: DateTime.now(),
        ),
      );
    } catch (_) {
      return const Unavailable();
    }
  }

  @override
  Future<void> openSettings({required bool service}) async {
    service
        ? await Geolocator.openLocationSettings()
        : await Geolocator.openAppSettings();
  }
}

/// Для тестов и предпросмотра: заранее заданный ответ.
class FakeLocationSource implements LocationSource {
  LocationResult result;
  int calls = 0;
  int silentCalls = 0;

  /// Открытые настройки: true — геолокации телефона, false — приложения.
  final List<bool> settingsOpened = [];
  FakeLocationSource(this.result);
  @override
  Future<void> openSettings({required bool service}) async =>
      settingsOpened.add(service);
  @override
  Future<LocationResult> current({bool silent = false}) async {
    calls++;
    if (silent) silentCalls++;
    return result;
  }
}
