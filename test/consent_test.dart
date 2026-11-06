import 'package:domiday/background.dart';
import 'package:domiday/locator.dart';
import 'package:domiday/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture, tapDialog, tapVisible;
import 'widget_test.dart' show launch, reveal;

/// Раскрытие и согласие до системного запроса геолокации (требование
/// Google Play; отказ в публикации 1.0.5 от 5.11.2026).
void main() {
  final tbilisi = Observed(
    Observation(
      latitude: 41.7151,
      longitude: 44.8271,
      accuracyM: 1500,
      at: DateTime(2026, 9, 13, 12),
    ),
  );

  test('settings: locationConsent round-trip, off by default', () {
    expect(const AppSettings().locationConsent, isFalse);
    expect(
      AppSettings.fromJson({'locationConsent': 'yes'}).locationConsent,
      isFalse,
    );
    final back = AppSettings.fromJson(
      const AppSettings(locationConsent: true).toJson(),
    );
    expect(back.locationConsent, isTrue);
  });

  testWidgets(
    'detect: disclosure first; decline asks nothing; accept is remembered',
    (tester) async {
      final repo = dashboardFixture();
      final settings = MemorySettingsRepository(
        const AppSettings(autoDetect: false),
      );
      final source = FakeLocationSource(tbilisi);
      await launch(
        tester,
        repo,
        journal: false,
        settings: settings,
        location: source,
      );
      await tapVisible(tester, 'detectNow');
      expect(find.byKey(const Key('consentLocation')), findsOneWidget);
      expect(
        find.textContaining('данные о приблизительном местоположении'),
        findsOneWidget,
      );
      expect(find.textContaining('не сохраняются'), findsOneWidget);
      // Отказ: ни запроса, ни определения, согласие не записано.
      await tapDialog(tester, 'consentDecline');
      expect(source.calls, 0);
      expect(settings.settings.locationConsent, isFalse);
      // Закрытие окна мимо кнопок — тоже отказ.
      await tapVisible(tester, 'detectNow');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consentLocation')), findsNothing);
      expect(source.calls, 0);
      expect(settings.settings.locationConsent, isFalse);
      // Согласие: определение идёт, окно больше не показывается.
      await tapVisible(tester, 'detectNow');
      await tapDialog(tester, 'consentAccept');
      expect(source.calls, 1);
      expect(settings.settings.locationConsent, isTrue);
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'detectNow');
      expect(find.byKey(const Key('consentLocation')), findsNothing);
      expect(source.calls, 2);
      expect(repo.writes, 0);
    },
  );

  testWidgets(
    'background: disclosure before any permission request, every time',
    (tester) async {
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
      await tester.tap(find.byKey(const Key('backgroundSetting')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consentBackground')), findsOneWidget);
      expect(
        find.textContaining(
          'даже когда приложение закрыто или не используется',
        ),
        findsOneWidget,
      );
      // Отказ: системные запросы не вызывались, режим не включён.
      await tapDialog(tester, 'consentDecline');
      expect(service.requested, 0);
      expect(service.scheduled, 0);
      expect(settings.settings.backgroundDetect, isFalse);
      expect(settings.settings.backgroundRequested, isFalse);
      expect(settings.settings.locationConsent, isFalse);
      // Согласие: запросы, включение; согласие покрывает и обычное
      // определение.
      await tester.tap(find.byKey(const Key('backgroundSetting')));
      await tester.pumpAndSettle();
      await tapDialog(tester, 'consentAccept');
      expect(service.requested, 1);
      expect(service.scheduled, 1);
      expect(settings.settings.backgroundDetect, isTrue);
      expect(settings.settings.locationConsent, isTrue);
      // Выключили и включили снова — окно показывается опять.
      await tester.tap(find.byKey(const Key('backgroundSetting')));
      await tester.pumpAndSettle();
      expect(settings.settings.backgroundDetect, isFalse);
      await tester.tap(find.byKey(const Key('backgroundSetting')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consentBackground')), findsOneWidget);
      expect(service.requested, 1);
    },
  );

  testWidgets('disclosure in English uses the wording Google looks for', (
    tester,
  ) async {
    final settings = MemorySettingsRepository(
      const AppSettings(autoDetect: false),
    );
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      settings: settings,
      location: FakeLocationSource(tbilisi),
      background: FakeBackgroundService(),
      locale: const Locale('en'),
    );
    await tapVisible(tester, 'detectNow');
    expect(find.textContaining('approximate location data'), findsOneWidget);
    await tapDialog(tester, 'consentDecline');
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backgroundSetting')));
    await tester.tap(find.byKey(const Key('backgroundSetting')));
    await tester.pumpAndSettle();
    expect(find.text('Location in the background'), findsOneWidget);
    expect(
      find.textContaining('collects approximate location data'),
      findsOneWidget,
    );
    expect(
      find.textContaining('even when the app is closed or not in use'),
      findsOneWidget,
    );
  });

  testWidgets('disclosure fits 320 px with 180% text in the dark theme', (
    tester,
  ) async {
    final settings = MemorySettingsRepository(
      const AppSettings(autoDetect: false, themeMode: ThemeMode.dark),
    );
    final source = FakeLocationSource(tbilisi);
    await launch(
      tester,
      dashboardFixture(),
      width: 320,
      height: 640,
      scale: 1.8,
      journal: false,
      settings: settings,
      location: source,
      background: FakeBackgroundService(),
    );
    await tapVisible(tester, 'detectNow');
    expect(find.byKey(const Key('consentLocation')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Кнопки достижимы прокруткой окна.
    await tester.ensureVisible(find.byKey(const Key('consentAccept')));
    await tester.pumpAndSettle();
    await tapDialog(tester, 'consentAccept');
    expect(source.calls, 1);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    // Фоновое окно длиннее — та же проверка.
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backgroundSetting')));
    await tester.tap(find.byKey(const Key('backgroundSetting')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consentBackground')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('consentDecline')));
    await tester.pumpAndSettle();
    await tapDialog(tester, 'consentDecline');
    expect(settings.settings.backgroundDetect, isFalse);
  });
}
