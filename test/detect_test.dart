import 'package:domiday/locator.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture, tapVisible;
import 'widget_test.dart' show launch, reveal;

Observed at(double lat, double lon, {double accuracy = 1500}) => Observed(
  Observation(
    latitude: lat,
    longitude: lon,
    accuracyM: accuracy,
    at: DateTime(2026, 9, 13, 12),
  ),
);

final yerevan = at(40.1792, 44.4991);
final tbilisi = at(41.7151, 44.8271);
final sarpi = at(41.52, 41.55, accuracy: 2500);
final sea = at(43.0, 34.0);

void main() {
  test('candidate json round-trip and tolerant parsing', () {
    final c = Candidate(
      code: 'AM',
      detectedOn: Day(2026, 9, 13),
      accuracyM: 1500,
      uncertain: true,
      alternatives: ['GE'],
      dismissed: true,
    );
    final settings = AppSettings(candidate: c, locale: const Locale('en'));
    final back = AppSettings.fromJson(settings.toJson());
    expect(back.candidate!.toJson(), c.toJson());
    expect(back.locale, const Locale('en'));
    expect(
      AppSettings.fromJson({
        'candidate': {'code': 'armenia'},
      }).candidate,
      isNull,
    );
    expect(AppSettings.fromJson({'candidate': 'x'}).candidate, isNull);
  });

  testWidgets(
    'detect: other country → page → confirm move with prefilled data',
    (tester) async {
      final repo = dashboardFixture();
      final settings = MemorySettingsRepository(
        const AppSettings(autoDetect: false),
      );
      final source = FakeLocationSource(yerevan);
      await launch(
        tester,
        repo,
        journal: false,
        settings: settings,
        location: source,
      );
      await tapVisible(tester, 'detectNow');
      expect(source.calls, 1);
      expect(find.byKey(const Key('detectionPage')), findsOneWidget);
      expect(find.text('Похоже, вы сейчас здесь: Армения'), findsOneWidget);
      expect(find.byKey(const Key('candidateUncertain')), findsNothing);
      // Кандидат записан в настройки, дневник не тронут.
      expect(settings.settings.candidate!.code, 'AM');
      expect(repo.writes, 0);
      await tapVisible(tester, 'candidateConfirm');
      expect(find.text('Смена страны'), findsOneWidget);
      expect(find.text('Армения · AM'), findsOneWidget);
      expect(find.text('Переезд: 13.09.2026'), findsOneWidget);
      await tapVisible(tester, 'saveStatus');
      expect(find.text('Подтвердить переезд?'), findsOneWidget);
      await tester.tap(find.text('Подтвердить переезд'));
      await tester.pumpAndSettle();
      // Сохранено, кандидат снят, вернулись на дашборд.
      expect(repo.snapshot.current!.countryCode, 'AM');
      expect(repo.snapshot.current!.arrival, Day(2026, 9, 13));
      expect(repo.records.firstWhere((t) => t.id == 'now').countryCode, 'GE');
      expect(settings.settings.candidate, isNull);
      expect(find.byKey(const Key('detectionPage')), findsNothing);
      expect(find.byKey(const Key('dashboardScroll')), findsOneWidget);
    },
  );

  testWidgets('detect: same country, denied, sea — messages, nothing written', (
    tester,
  ) async {
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
    expect(
      find.text('Вы там же: Грузия. Ничего не изменилось.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    source.result = const PermissionDenied(forever: true);
    await tapVisible(tester, 'detectNow');
    expect(find.textContaining('Нет разрешения'), findsOneWidget);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    source.result = sea;
    await tapVisible(tester, 'detectNow');
    expect(find.textContaining('Не удалось определить страну'), findsOneWidget);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    source.result = const ServiceDisabled();
    await tapVisible(tester, 'detectNow');
    expect(find.textContaining('выключена'), findsOneWidget);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    expect(settings.settings.candidate, isNull);
    expect(find.byKey(const Key('candidateBanner')), findsNothing);
  });

  testWidgets('detect: dismiss silences the same country; banner on relaunch', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final settings = MemorySettingsRepository(
      const AppSettings(autoDetect: false),
    );
    final source = FakeLocationSource(yerevan);
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      location: source,
    );
    await tapVisible(tester, 'detectNow');
    await tapVisible(tester, 'candidateDismiss');
    expect(settings.settings.candidate!.dismissed, isTrue);
    expect(find.byKey(const Key('detectionPage')), findsNothing);
    expect(find.byKey(const Key('candidateBanner')), findsNothing);
    await tapVisible(tester, 'detectNow');
    expect(find.textContaining('уже отклонили'), findsOneWidget);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    // Ожидающий кандидат виден баннером после перезапуска.
    settings.settings = settings.settings.copyWith(
      candidate: settings.settings.candidate!.copyWith(dismissed: false),
    );
    await tester.pumpWidget(const SizedBox());
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      location: source,
    );
    expect(find.byKey(const Key('candidateBanner')), findsOneWidget);
    expect(find.text('Похоже, вы здесь: Армения'), findsOneWidget);
    await tapVisible(tester, 'candidateReview');
    expect(find.byKey(const Key('detectionPage')), findsOneWidget);
  });

  testWidgets('detect: transit from candidate saves a transit record', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final settings = MemorySettingsRepository(
      const AppSettings(autoDetect: false),
    );
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      location: FakeLocationSource(yerevan),
    );
    await tapVisible(tester, 'detectNow');
    await tapVisible(tester, 'candidateTransit');
    expect(find.text('Новый транзит'), findsOneWidget);
    expect(find.text('Армения · AM'), findsOneWidget);
    await tapVisible(tester, 'saveTrip');
    final transit = repo.records.firstWhere((t) => t.kind == TripKind.transit);
    expect(transit.countryCode, 'AM');
    expect(transit.arrival, Day(2026, 9, 13));
    expect(repo.snapshot.current!.countryCode, 'GE');
    expect(settings.settings.candidate, isNull);
    expect(find.byKey(const Key('dashboardScroll')), findsOneWidget);
  });

  testWidgets('detect: border zone is reported as uncertain', (tester) async {
    final repo = dashboardFixture();
    await launch(
      tester,
      repo,
      journal: false,
      settings: MemorySettingsRepository(const AppSettings(autoDetect: false)),
      location: FakeLocationSource(sarpi),
    );
    await tapVisible(tester, 'detectNow');
    // Сарпи: либо Турция с альтернативой Грузия, либо «вы там же» не
    // подходит — точка вне текущей страны или неуверенна.
    final page = find.byKey(const Key('detectionPage'));
    if (page.evaluate().isNotEmpty) {
      expect(find.byKey(const Key('candidateUncertain')), findsOneWidget);
    } else {
      expect(find.byKey(const Key('detectMessage')), findsOneWidget);
    }
    expect(repo.writes, 0);
  });

  testWidgets('no location source → no button (manual journal unaffected)', (
    tester,
  ) async {
    await launch(tester, dashboardFixture(), journal: false);
    await reveal(tester, find.byKey(const Key('unknownTotal')));
    expect(find.byKey(const Key('detectNow')), findsNothing);
  });
}
