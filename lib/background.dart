import 'dart:ui' show DartPluginRegistrant, PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Day;
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

import 'borders.dart';
import 'countries.dart';
import 'l10n/app_localizations.dart';
import 'locator.dart';
import 'repository.dart';
import 'settings.dart';
import 'trip.dart';

/// Уведомление о кандидате. В тестах подменяется.
abstract interface class Notifier {
  Future<void> show({required String title, required String body});
}

/// Разрешения и планирование фоновых задач. В тестах подменяется.
abstract interface class BackgroundService {
  /// Запросить «геолокация — всегда» и уведомления.
  Future<BackgroundPermissionState> requestPermissions();

  /// То же без запросов — для проверки после возврата из настроек.
  Future<BackgroundPermissionState> checkPermissions();
  Future<void> openAppSettings();
  Future<void> schedule();
  Future<void> cancel();

  /// Диагностика с экрана настроек: одноразовая задача прямо сейчас (та
  /// же проверка, что по расписанию) и тестовое уведомление из
  /// приложения (канал, иконка, разрешение).
  Future<void> runNow();
  Future<void> testNotification({required String title, required String body});

  /// null — неизвестно (не Android); false — система ограничивает фон
  /// («оптимизация батареи»), и задачи могут не запускаться.
  Future<bool?> batteryUnrestricted();
}

enum BackgroundPermissionState { granted, locationNotAlways, notificationsOff }

/// Результат, записываемый при исключении внутри фоновой задачи.
const backgroundErrorOutcome = 'error';

/// Одна фоновая проверка. Чистая логика: читает настройки и дневник,
/// получает координаты, сопоставляет с границами, предлагает кандидата и
/// шлёт уведомление только при другой стране и не чаще раза в 12 часов
/// для того же кода. Ничего в дневник не пишет; время и результат
/// запуска сохраняет в настройках — их показывает экран настроек.
Future<BackgroundOutcome> runBackgroundCheck({
  required SettingsRepository settingsRepository,
  required TripRepository journal,
  required LocationSource location,
  required CountryBorders borders,
  required CountryDirectory directory,
  required Notifier notifier,
  required DateTime Function() now,
  required String languageCode,
}) async {
  final settings = SettingsController(settingsRepository);
  await settings.load();
  if (!settings.settings.backgroundDetect) return BackgroundOutcome.disabled;
  final outcome = await _check(
    settings: settings,
    journal: journal,
    location: location,
    borders: borders,
    directory: directory,
    notifier: notifier,
    now: now,
    languageCode: languageCode,
  );
  await settings.markBackgroundRun(outcome.name, now());
  return outcome;
}

Future<BackgroundOutcome> _check({
  required SettingsController settings,
  required TripRepository journal,
  required LocationSource location,
  required CountryBorders borders,
  required CountryDirectory directory,
  required Notifier notifier,
  required DateTime Function() now,
  required String languageCode,
}) async {
  final snapshot = await journal.load();
  final current = snapshot.current;
  if (current == null) return BackgroundOutcome.noProfile;
  final result = await location.current(silent: true);
  if (result is! Observed) return BackgroundOutcome.noLocation;
  final o = result.observation;
  final located = borders.locate(
    o.latitude,
    o.longitude,
    accuracyM: o.accuracyM,
  );
  final code = located.code;
  if (code == null) return BackgroundOutcome.noCountry;
  final today = Day.fromDateTime(now());
  final outcome = await settings.offer(
    code: code,
    today: today,
    accuracyM: o.accuracyM.round(),
    uncertain: located.uncertain,
    alternatives: located.alternatives,
    currentCode: current.countryCode ?? directory.match(current.country),
  );
  if (outcome != OfferOutcome.pending) return BackgroundOutcome.sameOrSilenced;
  if (!settings.shouldNotify(code, now())) {
    return BackgroundOutcome.alreadyNotified;
  }
  final l10n = lookupAppLocalizations(Locale(languageCode));
  await notifier.show(
    title: l10n.notificationTitle(directory.display(code, code, languageCode)),
    body: l10n.notificationBody,
  );
  await settings.markNotified(code, now());
  return BackgroundOutcome.notified;
}

enum BackgroundOutcome {
  disabled,
  noProfile,
  noLocation,
  noCountry,
  sameOrSilenced,
  alreadyNotified,
  notified,
}

const _periodicTask = 'domiday.periodic';
const _onlineTask = 'domiday.online';
const _nowTask = 'domiday.now';

/// Точка входа фонового изолята WorkManager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      final notifications = LocalNotifier();
      await notifications.initialize();
      await runBackgroundCheck(
        settingsRepository: JsonSettingsRepository(),
        journal: JsonTripRepository(),
        location: const GeolocatorSource(),
        borders: await CountryBorders.load(),
        directory: await CountryDirectory.load(),
        notifier: notifications,
        now: DateTime.now,
        languageCode: await _languageCode(),
      );
    } catch (e) {
      // Фоновая проверка не должна ронять задачу: следующая пройдёт по
      // расписанию. Дневник в любом случае не тронут; в настройках
      // остаётся отметка «ошибка» с текстом, видимая на экране настроек.
      try {
        final settings = SettingsController(JsonSettingsRepository());
        await settings.load();
        await settings.markBackgroundRun(
          backgroundErrorOutcome,
          DateTime.now(),
          error: '$e'.substring(0, '$e'.length.clamp(0, 200)),
        );
      } catch (_) {}
    }
    // «При появлении связи» — одноразовая задача с условием сети,
    // которую перезаводим после каждого срабатывания.
    if (task == _onlineTask) await WorkmanagerService._scheduleOnline();
    return true;
  });
}

Future<String> _languageCode() async {
  final settings = await JsonSettingsRepository().load();
  final code =
      settings.locale?.languageCode ??
      PlatformDispatcher.instance.locale.languageCode;
  return code == 'ru' ? 'ru' : 'en';
}

/// Настоящие фоновые задачи через WorkManager.
class WorkmanagerService implements BackgroundService {
  const WorkmanagerService();

  static Future<void> initialize() =>
      Workmanager().initialize(callbackDispatcher);

  @override
  Future<BackgroundPermissionState> requestPermissions() async {
    // Сначала уведомления (Android 13+: обычный диалог), потом геолокация:
    // за «всегда» владелец уходит в системные настройки, и к возвращению
    // уведомления уже должны быть разрешены — иначе включение шло по кругу.
    final notifications = await LocalNotifier().requestPermission();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always) {
      // Android 11+: «всегда» выдаётся только в системных настройках;
      // запрос лишь открывает подсказку. Пусть пользователь дойдёт сам.
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        return BackgroundPermissionState.locationNotAlways;
      }
    }
    return notifications
        ? BackgroundPermissionState.granted
        : BackgroundPermissionState.notificationsOff;
  }

  @override
  Future<BackgroundPermissionState> checkPermissions() async {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      return BackgroundPermissionState.locationNotAlways;
    }
    final enabled = await LocalNotifier().notificationsEnabled();
    return enabled
        ? BackgroundPermissionState.granted
        : BackgroundPermissionState.notificationsOff;
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> schedule() async {
    await Workmanager().registerPeriodicTask(
      _periodicTask,
      _periodicTask,
      frequency: const Duration(hours: 2),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
    await _scheduleOnline();
  }

  static Future<void> _scheduleOnline() => Workmanager().registerOneOffTask(
    _onlineTask,
    _onlineTask,
    initialDelay: const Duration(minutes: 30),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  @override
  Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(_periodicTask);
    await Workmanager().cancelByUniqueName(_onlineTask);
    await Workmanager().cancelByUniqueName(_nowTask);
  }

  @override
  Future<void> runNow() => Workmanager().registerOneOffTask(
    _nowTask,
    _nowTask,
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  @override
  Future<void> testNotification({
    required String title,
    required String body,
  }) async {
    final notifier = LocalNotifier();
    await notifier.initialize();
    await notifier.show(title: title, body: body);
  }

  static const _battery = MethodChannel('domiday/battery');

  @override
  Future<bool?> batteryUnrestricted() async {
    try {
      return await _battery.invokeMethod<bool>('isIgnoring');
    } catch (_) {
      return null;
    }
  }
}

/// Локальные уведомления Android.
class LocalNotifier implements Notifier {
  static const _channel = 'domiday.detection';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize({void Function(String? payload)? onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: onTap == null
          ? null
          : (response) => onTap(response.payload),
    );
  }

  /// Открыто ли приложение нажатием на уведомление.
  Future<bool> launchedFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? true;
  }

  Future<bool> notificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.areNotificationsEnabled() ?? true;
  }

  @override
  Future<void> show({required String title, required String body}) =>
      _plugin.show(
        id: 1,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channel,
            'Domiday',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.recommendation,
          ),
        ),
        payload: 'candidate',
      );
}

/// Для тестов: запоминает показанные уведомления.
class FakeNotifier implements Notifier {
  final List<(String, String)> shown = [];
  @override
  Future<void> show({required String title, required String body}) async {
    shown.add((title, body));
  }
}

/// Для тестов: заданный ответ на запрос разрешений, счётчики планирования.
class FakeBackgroundService implements BackgroundService {
  BackgroundPermissionState permissions;
  int scheduled = 0;
  int cancelled = 0;
  int settingsOpened = 0;
  int ranNow = 0;
  final List<(String, String)> tested = [];
  bool? battery = true;
  FakeBackgroundService([this.permissions = BackgroundPermissionState.granted]);
  @override
  Future<void> runNow() async => ranNow++;
  @override
  Future<void> testNotification({
    required String title,
    required String body,
  }) async => tested.add((title, body));
  @override
  Future<bool?> batteryUnrestricted() async => battery;
  @override
  Future<BackgroundPermissionState> requestPermissions() async => permissions;
  @override
  Future<BackgroundPermissionState> checkPermissions() async => permissions;
  @override
  Future<void> openAppSettings() async => settingsOpened++;
  @override
  Future<void> schedule() async => scheduled++;
  @override
  Future<void> cancel() async => cancelled++;
}
