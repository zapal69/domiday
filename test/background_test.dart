import 'package:domiday/background.dart';
import 'package:domiday/locator.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'widget_test.dart'
    show launch, reveal, MemoryRepository, testBorders, testDirectory;

Observed at(double lat, double lon) => Observed(
  Observation(
    latitude: lat,
    longitude: lon,
    accuracyM: 1500,
    at: DateTime(2026, 9, 13, 12),
  ),
);

void main() {
  final yerevan = at(40.1792, 44.4991);
  final tbilisi = at(41.7151, 44.8271);

  Future<BackgroundOutcome> run({
    required MemorySettingsRepository settings,
    required MemoryRepository journal,
    required LocationResult where,
    required FakeNotifier notifier,
    DateTime? now,
  }) => runBackgroundCheck(
    settingsRepository: settings,
    journal: journal,
    location: FakeLocationSource(where),
    borders: testBorders,
    directory: testDirectory,
    notifier: notifier,
    now: () => now ?? DateTime(2026, 9, 13, 12),
    languageCode: 'ru',
  );

  test('background check: off by default, silent when same country', () async {
    final journal = dashboardFixture();
    final notifier = FakeNotifier();
    expect(
      await run(
        settings: MemorySettingsRepository(),
        journal: journal,
        where: yerevan,
        notifier: notifier,
      ),
      BackgroundOutcome.disabled,
    );
    final on = MemorySettingsRepository(
      const AppSettings(backgroundDetect: true),
    );
    expect(
      await run(
        settings: on,
        journal: journal,
        where: tbilisi,
        notifier: notifier,
      ),
      BackgroundOutcome.sameOrSilenced,
    );
    expect(notifier.shown, isEmpty);
    expect(journal.writes, 0);
    // Результат и время записаны — их показывает экран настроек.
    expect(on.settings.lastBackgroundOutcome, 'sameOrSilenced');
    expect(on.settings.backgroundLog, [
      '${DateTime(2026, 9, 13, 12).toUtc().toIso8601String()}|sameOrSilenced',
    ]);
    expect(on.settings.lastBackgroundRun, DateTime(2026, 9, 13, 12));
    final json = on.settings.toJson();
    expect(AppSettings.fromJson(json).lastBackgroundOutcome, 'sameOrSilenced');
    expect(
      AppSettings.fromJson(json).lastBackgroundRun,
      DateTime(2026, 9, 13, 12).toUtc(),
    );
  });

  test(
    'background check: other country → one notification per 12 hours',
    () async {
      final journal = dashboardFixture();
      final notifier = FakeNotifier();
      final settings = MemorySettingsRepository(
        const AppSettings(backgroundDetect: true),
      );
      expect(
        await run(
          settings: settings,
          journal: journal,
          where: yerevan,
          notifier: notifier,
        ),
        BackgroundOutcome.notified,
      );
      expect(notifier.shown.single.$1, 'Похоже, вы здесь: Армения');
      expect(settings.settings.candidate!.code, 'AM');
      expect(settings.settings.notifiedCode, 'AM');
      expect(settings.settings.lastBackgroundOutcome, 'notified');
      // Через час — тот же кандидат, без нового уведомления.
      expect(
        await run(
          settings: settings,
          journal: journal,
          where: yerevan,
          notifier: notifier,
          now: DateTime(2026, 9, 13, 13),
        ),
        BackgroundOutcome.alreadyNotified,
      );
      expect(notifier.shown.length, 1);
      // Через 13 часов — напоминание.
      expect(
        await run(
          settings: settings,
          journal: journal,
          where: yerevan,
          notifier: notifier,
          now: DateTime(2026, 9, 14, 1),
        ),
        BackgroundOutcome.notified,
      );
      expect(notifier.shown.length, 2);
      // Отклонённый кандидат молчит.
      final controller = SettingsController(settings);
      await controller.load();
      await controller.dismissCandidate();
      expect(
        await run(
          settings: settings,
          journal: journal,
          where: yerevan,
          notifier: notifier,
          now: DateTime(2026, 9, 15, 1),
        ),
        BackgroundOutcome.sameOrSilenced,
      );
      expect(notifier.shown.length, 2);
      expect(journal.writes, 0);
    },
  );

  test('background check: no location or sea → nothing', () async {
    final journal = dashboardFixture();
    final notifier = FakeNotifier();
    final settings = MemorySettingsRepository(
      const AppSettings(backgroundDetect: true),
    );
    expect(
      await run(
        settings: settings,
        journal: journal,
        where: const PermissionDenied(forever: false),
        notifier: notifier,
      ),
      BackgroundOutcome.noLocation,
    );
    expect(
      await run(
        settings: settings,
        journal: journal,
        where: at(43.0, 34.0),
        notifier: notifier,
      ),
      BackgroundOutcome.noCountry,
    );
    expect(notifier.shown, isEmpty);
  });

  testWidgets('settings: last background check is shown when on', (
    tester,
  ) async {
    final settings = MemorySettingsRepository(
      AppSettings(
        autoDetect: false,
        backgroundDetect: true,
        lastBackgroundRun: DateTime(2026, 9, 13, 12, 5),
        lastBackgroundOutcome: 'noLocation',
      ),
    );
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      settings: settings,
      location: FakeLocationSource(tbilisi),
      background: FakeBackgroundService(),
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backgroundLastRun')));
    expect(
      find.text(
        'Последняя проверка: 13.09.2026 12:05 — координаты не получены',
      ),
      findsOneWidget,
    );
    // Выключили — строки нет.
    await reveal(tester, find.byKey(const Key('backgroundSetting')));
    await tester.tap(find.byKey(const Key('backgroundSetting')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backgroundLastRun')), findsNothing);
  });

  testWidgets('settings: enabling schedules when permissions are granted', (
    tester,
  ) async {
    final settings = MemorySettingsRepository(
      const AppSettings(autoDetect: false),
    );
    final service = FakeBackgroundService();
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      settings: settings,
      location: FakeLocationSource(tbilisi),
      background: service,
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backgroundSetting')));
    expect(find.text('Фоновая проверка выключена'), findsOneWidget);
    await tester.tap(find.byKey(const Key('backgroundSetting')));
    await tester.pumpAndSettle();
    expect(service.scheduled, 1);
    expect(settings.settings.backgroundDetect, isTrue);
    expect(find.text('Фоновая проверка включена'), findsOneWidget);
    await tester.tap(find.byKey(const Key('backgroundSetting')));
    await tester.pumpAndSettle();
    expect(service.cancelled, 1);
    expect(settings.settings.backgroundDetect, isFalse);
  });

  testWidgets(
    'settings: without “always” permission — explanation, not enabled',
    (tester) async {
      final settings = MemorySettingsRepository(
        const AppSettings(autoDetect: false),
      );
      final service = FakeBackgroundService(
        BackgroundPermissionState.locationNotAlways,
      );
      await launch(
        tester,
        dashboardFixture(),
        journal: false,
        settings: settings,
        location: FakeLocationSource(tbilisi),
        background: service,
      );
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('backgroundSetting')));
      await tester.tap(find.byKey(const Key('backgroundSetting')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Разрешить всегда'), findsWidgets);
      await tester.tap(find.text('Открыть настройки приложения'));
      await tester.pumpAndSettle();
      expect(service.settingsOpened, 1);
      expect(service.scheduled, 0);
      expect(settings.settings.backgroundDetect, isFalse);
      // Намерение сохранено; статус говорит, что ждём разрешений.
      expect(settings.settings.backgroundRequested, isTrue);
      expect(find.textContaining('Ждёт разрешений'), findsOneWidget);
      // Под переключателем — путь к «Разрешить всегда» в настройках Android.
      expect(find.byKey(const Key('backgroundHowTo')), findsOneWidget);
      // Android перезапустил приложение после выдачи «всегда»: режим
      // включается сам, без повторного нажатия.
      service.permissions = BackgroundPermissionState.granted;
      await tester.pumpWidget(const SizedBox());
      await launch(
        tester,
        dashboardFixture(),
        journal: false,
        settings: settings,
        location: FakeLocationSource(tbilisi),
        background: service,
      );
      expect(service.scheduled, 1);
      expect(settings.settings.backgroundDetect, isTrue);
      expect(settings.settings.backgroundRequested, isFalse);
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('backgroundSetting')));
      expect(find.text('Фоновая проверка включена'), findsOneWidget);
    },
  );

  testWidgets(
    'notification tap opens the review screen for a pending candidate',
    (tester) async {
      final settings = MemorySettingsRepository(
        AppSettings(
          autoDetect: false,
          candidate: Candidate(
            code: 'AM',
            detectedOn: Day(2026, 9, 13),
            accuracyM: 1500,
            uncertain: false,
          ),
        ),
      );
      final requests = ValueNotifier<int>(1);
      await launch(
        tester,
        dashboardFixture(),
        journal: false,
        settings: settings,
        location: FakeLocationSource(tbilisi),
        background: FakeBackgroundService(),
        reviewRequests: requests,
      );
      expect(find.byKey(const Key('detectionPage')), findsOneWidget);
      expect(find.text('Похоже, вы сейчас здесь: Армения'), findsOneWidget);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detectionPage')), findsNothing);
      // Повторное нажатие на уведомление — снова экран.
      requests.value++;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detectionPage')), findsOneWidget);
    },
  );

  test('background log keeps the last runs and the error text', () async {
    final repo = MemorySettingsRepository(
      const AppSettings(backgroundDetect: true),
    );
    final c = SettingsController(repo);
    await c.load();
    for (var i = 0; i < 10; i++) {
      await c.markBackgroundRun('noLocation', DateTime.utc(2026, 9, 13, i));
    }
    expect(c.settings.backgroundLog.length, AppSettings.backgroundLogLimit);
    expect(
      c.settings.backgroundLog.first,
      '2026-09-13T02:00:00.000Z|noLocation',
    );
    await c.markBackgroundRun(
      'error',
      DateTime.utc(2026, 9, 14),
      error: 'boom',
    );
    expect(c.settings.lastBackgroundError, 'boom');
    final back = AppSettings.fromJson(c.settings.toJson());
    expect(back.lastBackgroundError, 'boom');
    expect(back.backgroundLog.last, '2026-09-14T00:00:00.000Z|error');
    await c.markBackgroundRun('notified', DateTime.utc(2026, 9, 15));
    expect(c.settings.lastBackgroundError, isNull);
  });

  testWidgets('settings: diagnostics — run now, test notification, battery', (
    tester,
  ) async {
    final settings = MemorySettingsRepository(
      AppSettings(
        autoDetect: false,
        backgroundDetect: true,
        lastBackgroundRun: DateTime(2026, 9, 13, 12, 5),
        lastBackgroundOutcome: 'error',
        lastBackgroundError: 'MissingPluginException',
        backgroundLog: const [
          '2026-09-13T08:00:00.000Z|noLocation',
          '2026-09-13T09:05:00.000Z|error',
        ],
      ),
    );
    final service = FakeBackgroundService()..battery = false;
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      settings: settings,
      location: FakeLocationSource(tbilisi),
      background: service,
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backgroundRunNow')));
    expect(find.text('Ошибка: MissingPluginException'), findsOneWidget);
    expect(find.byKey(const Key('backgroundLog')), findsOneWidget);
    expect(find.textContaining('координаты не получены'), findsWidgets);
    await tester.tap(find.byKey(const Key('backgroundRunNow')));
    await tester.pumpAndSettle();
    expect(service.ranNow, 1);
    expect(find.textContaining('Проверка запущена'), findsOneWidget);
    await tester.tap(find.byKey(const Key('backgroundTestNotification')));
    await tester.pumpAndSettle();
    expect(service.tested.single.$1, 'Уведомления Domiday работают');
    // Батарея ограничена — предупреждение и переход в настройки.
    await reveal(tester, find.byKey(const Key('batterySettings')));
    expect(find.byKey(const Key('batteryRestricted')), findsOneWidget);
    await tester.tap(find.byKey(const Key('batterySettings')));
    await tester.pumpAndSettle();
    expect(service.settingsOpened, 1);
  });

  testWidgets('settings: notifications off — enabled anyway, with a warning', (
    tester,
  ) async {
    final settings = MemorySettingsRepository(
      const AppSettings(autoDetect: false),
    );
    final service = FakeBackgroundService(
      BackgroundPermissionState.notificationsOff,
    );
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      settings: settings,
      location: FakeLocationSource(tbilisi),
      background: service,
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backgroundSetting')));
    await tester.tap(find.byKey(const Key('backgroundSetting')));
    await tester.pumpAndSettle();
    expect(service.scheduled, 1);
    expect(settings.settings.backgroundDetect, isTrue);
    await reveal(tester, find.byKey(const Key('notificationsOff')));
    expect(find.byKey(const Key('permissionSettings')), findsOneWidget);
  });

  testWidgets(
    'return from settings: «always» granted, notifications requested then',
    (tester) async {
      final settings = MemorySettingsRepository(
        const AppSettings(autoDetect: false, backgroundRequested: true),
      );
      // checkPermissions говорит «уведомлений нет», requestPermissions
      // их выдаёт — режим включается без повторного нажатия.
      final service = _RequestingService();
      await launch(
        tester,
        dashboardFixture(),
        journal: false,
        settings: settings,
        location: FakeLocationSource(tbilisi),
        background: service,
      );
      expect(service.requested, 1);
      expect(service.scheduled, 1);
      expect(settings.settings.backgroundDetect, isTrue);
      expect(settings.settings.backgroundRequested, isFalse);
    },
  );
  testWidgets('settings: how-to line and enable error are visible', (
    tester,
  ) async {
    final settings = MemorySettingsRepository(
      const AppSettings(autoDetect: false, backgroundRequested: true),
    );
    final service = _FailingService();
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      settings: settings,
      location: FakeLocationSource(tbilisi),
      background: service,
    );
    // Включение при запуске упало — ошибка записана, режим не включён.
    expect(settings.settings.backgroundDetect, isFalse);
    expect(settings.settings.lastBackgroundError, contains('boom'));
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backgroundHowTo')));
    expect(
      find.textContaining('Как выдать: Настройки Android'),
      findsOneWidget,
    );
    expect(find.textContaining('Ошибка: '), findsOneWidget);
  });
}

/// checkPermissions → уведомлений нет; requestPermissions → всё выдано.
class _RequestingService extends FakeBackgroundService {
  int requested = 0;
  _RequestingService() : super(BackgroundPermissionState.notificationsOff);
  @override
  Future<BackgroundPermissionState> requestPermissions() async {
    requested++;
    return BackgroundPermissionState.granted;
  }
}

/// Разрешения выданы, но планирование падает — как молчаливый сбой на
/// телефоне: теперь он виден.
class _FailingService extends FakeBackgroundService {
  @override
  Future<void> schedule() async => throw StateError('boom');
}
