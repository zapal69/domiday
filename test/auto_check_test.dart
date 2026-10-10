import 'package:domiday/locator.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture, tapVisible;
import 'widget_test.dart' show launch, reveal, MemoryRepository, fixture;

Observed at(double lat, double lon) => Observed(
  Observation(
    latitude: lat,
    longitude: lon,
    accuracyM: 1500,
    at: DateTime(2026, 9, 13, 12),
  ),
);

void main() {
  test('settings: theme, autoDetect and lastAutoCheck round-trip', () {
    final s = AppSettings(
      themeMode: ThemeMode.dark,
      autoDetect: false,
      lastAutoCheck: DateTime.utc(2026, 9, 13, 10),
    );
    final back = AppSettings.fromJson(s.toJson());
    expect(back.themeMode, ThemeMode.dark);
    expect(back.autoDetect, isFalse);
    expect(back.lastAutoCheck, DateTime.utc(2026, 9, 13, 10));
    // Умолчания и мусор.
    final d = AppSettings.fromJson({'themeMode': 'neon', 'lastAutoCheck': 7});
    expect(d.themeMode, ThemeMode.system);
    expect(d.autoDetect, isTrue);
    expect(d.lastAutoCheck, isNull);
  });

  testWidgets('auto-check on open: silent detection, banner, once an hour', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final settings = MemorySettingsRepository();
    final source = FakeLocationSource(at(40.1792, 44.4991)); // Ереван
    var now = DateTime(2026, 9, 13, 12);
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      location: source,
      now: () => now,
    );
    expect(source.calls, 1);
    expect(source.silentCalls, 1);
    expect(find.byKey(const Key('candidateBanner')), findsOneWidget);
    expect(find.byKey(const Key('detectionPage')), findsNothing);
    expect(find.byKey(const Key('detectMessage')), findsNothing);
    expect(repo.writes, 0);
    // Повторный запуск через 10 минут — без новой проверки.
    now = now.add(const Duration(minutes: 10));
    await tester.pumpWidget(const SizedBox());
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      location: source,
      now: () => now,
    );
    expect(source.calls, 1);
    expect(find.byKey(const Key('candidateBanner')), findsOneWidget);
    // Через 15 минут — снова.
    now = now.add(const Duration(minutes: 6));
    await tester.pumpWidget(const SizedBox());
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      location: source,
      now: () => now,
    );
    expect(source.calls, 2);
    // Индикатор результата под карточкой.
    expect(find.byKey(const Key('autoStatus')), findsOneWidget);
    expect(find.textContaining('есть предложение'), findsOneWidget);
  });

  testWidgets(
    'auto-check: changed country forces a re-check (Cyprus → restart)',
    (tester) async {
      final repo = dashboardFixture(); // текущая — Грузия
      final settings = MemorySettingsRepository();
      final source = FakeLocationSource(at(41.7151, 44.8271)); // Тбилиси
      var now = DateTime(2026, 9, 13, 12);
      await launch(
        tester,
        repo,
        journal: false,
        settings: settings,
        location: source,
        now: () => now,
      );
      expect(source.calls, 1);
      expect(find.textContaining('страна совпадает'), findsOneWidget);
      expect(find.byKey(const Key('candidateBanner')), findsNothing);
      // Меняем страну на Кипр вручную и перезапускаем через 2 минуты.
      await tapVisible(tester, 'changeCountry');
      await tester.enterText(find.byKey(const Key('statusCountry')), 'Кипр');
      await tester.pumpAndSettle();
      await tapVisible(tester, 'saveStatus');
      await tester.tap(find.text('Подтвердить переезд'));
      await tester.pumpAndSettle();
      expect(repo.snapshot.current!.countryCode, 'CY');
      now = now.add(const Duration(minutes: 2));
      await tester.pumpWidget(const SizedBox());
      await launch(
        tester,
        repo,
        journal: false,
        settings: settings,
        location: source,
        now: () => now,
      );
      expect(source.calls, 2);
      expect(find.byKey(const Key('candidateBanner')), findsOneWidget);
      expect(find.text('Похоже, вы здесь: Грузия'), findsOneWidget);
      expect(find.textContaining('есть предложение'), findsOneWidget);
    },
  );

  testWidgets(
    'auto-check: denied silently and switched off — no calls, no dialogs',
    (tester) async {
      final repo = dashboardFixture();
      final settings = MemorySettingsRepository();
      final source = FakeLocationSource(const PermissionDenied(forever: false));
      await launch(
        tester,
        repo,
        journal: false,
        settings: settings,
        location: source,
      );
      expect(source.silentCalls, 1);
      expect(find.byKey(const Key('detectMessage')), findsNothing);
      expect(find.byKey(const Key('candidateBanner')), findsNothing);
      // Выключаем в настройках → следующий запуск не проверяет.
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('autoDetectSetting')));
      await tester.tap(find.byKey(const Key('autoDetectSetting')));
      await tester.pumpAndSettle();
      expect(settings.settings.autoDetect, isFalse);
      source.result = at(40.1792, 44.4991);
      await tester.pumpWidget(const SizedBox());
      await launch(
        tester,
        repo,
        journal: false,
        settings: settings,
        location: source,
        now: () => DateTime(2026, 9, 13, 15),
      );
      expect(source.calls, 1);
      expect(find.byKey(const Key('candidateBanner')), findsNothing);
      // Кнопка по-прежнему работает вручную.
      await tapVisible(tester, 'detectNow');
      expect(find.byKey(const Key('detectionPage')), findsOneWidget);
    },
  );

  testWidgets(
    'auto-check denied: visible card, Turn on asks, then the status line',
    (tester) async {
      final repo = dashboardFixture(); // текущая — Грузия
      final settings = MemorySettingsRepository();
      final source = FakeLocationSource(const PermissionDenied(forever: false));
      await launch(
        tester,
        repo,
        journal: false,
        settings: settings,
        location: source,
      );
      expect(find.byKey(const Key('detectOff')), findsOneWidget);
      expect(find.text('Определение страны выключено'), findsOneWidget);
      expect(
        find.textContaining('нет доступа к местоположению'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('detectNow')), findsNothing);
      // «Включить» — обычный запрос разрешения; владелец разрешил.
      source.result = at(41.7151, 44.8271); // Тбилиси
      await tapVisible(tester, 'detectEnable');
      expect(source.calls, 2);
      expect(source.silentCalls, 1);
      expect(source.settingsOpened, isEmpty);
      await reveal(tester, find.byKey(const Key('detectOff')));
      expect(find.byKey(const Key('detectOff')), findsNothing);
      await reveal(tester, find.textContaining('страна совпадает'));
      expect(find.textContaining('страна совпадает'), findsOneWidget);
      expect(repo.writes, 0);
    },
  );

  testWidgets(
    'auto-check denied forever or location off: Turn on opens settings, '
    'recheck on return; Not needed switches the check off',
    (tester) async {
      final repo = dashboardFixture();
      final settings = MemorySettingsRepository();
      final source = FakeLocationSource(const PermissionDenied(forever: true));
      final now = DateTime(2026, 9, 13, 12);
      await launch(
        tester,
        repo,
        journal: false,
        settings: settings,
        location: source,
        now: () => now,
      );
      await tapVisible(tester, 'detectEnable');
      // Android больше не спрашивает — настройки приложения.
      expect(source.settingsOpened, [false]);
      expect(find.byKey(const Key('detectOff')), findsOneWidget);
      // Вернулся с разрешением: проверка сразу, без часового интервала.
      source.result = at(41.7151, 44.8271);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(source.calls, 3);
      await reveal(tester, find.byKey(const Key('detectOff')));
      expect(find.byKey(const Key('detectOff')), findsNothing);

      // Геолокация на телефоне выключена — её настройки, без запроса.
      final off = FakeLocationSource(const ServiceDisabled());
      final settings2 = MemorySettingsRepository();
      await tester.pumpWidget(const SizedBox());
      await launch(
        tester,
        dashboardFixture(),
        journal: false,
        settings: settings2,
        location: off,
      );
      expect(
        find.textContaining('Геолокация на телефоне выключена'),
        findsOneWidget,
      );
      await tapVisible(tester, 'detectEnable');
      expect(off.settingsOpened, [true]);
      expect(off.calls, 1);
      // «Не нужно» — автопроверка выключена, карточки нет, кнопка на месте.
      await tapVisible(tester, 'detectOffDismiss');
      expect(settings2.settings.autoDetect, isFalse);
      await reveal(tester, find.byKey(const Key('detectOff')));
      expect(find.byKey(const Key('detectOff')), findsNothing);
      await reveal(tester, find.byKey(const Key('detectNow')));
      expect(find.byKey(const Key('detectNow')), findsOneWidget);
    },
  );

  testWidgets('auto-check skips onboarding and same country', (tester) async {
    final settings = MemorySettingsRepository();
    final source = FakeLocationSource(at(40.1792, 44.4991));
    final repo = MemoryRepository()
      ..snapshot = JournalSnapshot(trips: [fixture()]);
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      location: source,
    );
    expect(find.text('Начнём с вас'), findsOneWidget);
    expect(source.calls, 0);
    // Та же страна: кандидата нет, баннера нет.
    final repo2 = dashboardFixture();
    final tbilisi = FakeLocationSource(at(41.7151, 44.8271));
    await tester.pumpWidget(const SizedBox());
    await launch(
      tester,
      repo2,
      journal: false,
      settings: MemorySettingsRepository(),
      location: tbilisi,
    );
    expect(tbilisi.silentCalls, 1);
    expect(find.byKey(const Key('candidateBanner')), findsNothing);
    expect(repo2.writes, 0);
  });

  testWidgets('theme setting switches MaterialApp themeMode', (tester) async {
    final settings = MemorySettingsRepository();
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      settings: settings,
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('themeSetting')));
    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();
    expect(settings.settings.themeMode, ThemeMode.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Тема'))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Тема'))).brightness,
      Brightness.light,
    );
  });
}
