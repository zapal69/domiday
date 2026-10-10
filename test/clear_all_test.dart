import 'package:domiday/backup.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'widget_test.dart' show MemoryRepository, launch, reveal;

void main() {
  final now = DateTime(2026, 9, 13, 12);

  testWidgets('clear all: dialog, backup first, then everything is reset', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final settings = MemorySettingsRepository(
      const AppSettings(autoDetect: false, themeMode: ThemeMode.dark),
    );
    final store = FakeBackupStore();
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      backup: store,
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('clearAll')));
    await tester.tap(find.byKey(const Key('clearAll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clearAllDialog')), findsOneWidget);
    expect(find.textContaining('будут удалены'), findsOneWidget);
    // Отмена — ничего не изменилось.
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect((await repo.load()).trips, isNotEmpty);
    // Снова: сначала копия, потом удаление.
    await tester.tap(find.byKey(const Key('clearAll')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clearAllBackup')));
    await tester.pumpAndSettle();
    expect(store.savedName, startsWith('domiday-backup-'));
    expect(find.byKey(const Key('clearAllSaved')), findsOneWidget);
    expect(find.byKey(const Key('clearAllBackup')), findsNothing);
    await tester.tap(find.byKey(const Key('clearAllConfirm')));
    await tester.pumpAndSettle();
    final cleared = await repo.load();
    expect(cleared.trips, isEmpty);
    expect(cleared.undated, isEmpty);
    expect(cleared.homeCountry, isNull);
    expect(cleared.current, isNull);
    expect(cleared.needsOnboarding, isTrue);
    // Настройки — по умолчанию, как при первом запуске.
    expect(settings.settings.autoDetect, isTrue);
    expect(settings.settings.themeMode, ThemeMode.system);
    expect(settings.settings.lastBackupAt, isNull);
    // Экран настроек закрыт, показан онбординг.
    expect(find.byKey(const Key('clearAll')), findsNothing);
    expect(find.byKey(const Key('homeCountry')), findsOneWidget);
  });

  JournalSnapshot three() => JournalSnapshot(
    homeCountry: 'Россия',
    homeCountryCode: 'RU',
    current: CurrentStay(
      id: 'cur',
      country: 'Россия',
      countryCode: 'RU',
      arrival: Day(2026, 8, 20),
      confirmedOn: Day(2026, 9, 13),
    ),
    trips: [
      for (var i = 1; i <= 3; i++)
        Trip(
          id: 't$i',
          country: 'Грузия',
          countryCode: 'GE',
          arrival: Day(2026, i, 1),
          departure: Day(2026, i, 5),
        ),
    ],
  );

  testWidgets('backup nudge: shown without a copy, saving hides it', (
    tester,
  ) async {
    final repo = MemoryRepository()..snapshot = three();
    final settings = MemorySettingsRepository();
    final store = FakeBackupStore();
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      backup: store,
      now: () => now,
    );
    expect(find.byKey(const Key('backupNudge')), findsOneWidget);
    await tester.tap(find.byKey(const Key('backupNudgeSave')));
    await tester.pumpAndSettle();
    expect(store.savedName, startsWith('domiday-backup-'));
    expect(settings.settings.lastBackupAt, isNotNull);
    expect(find.byKey(const Key('backupNudge')), findsNothing);
    // В настройках — дата последней копии.
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backupLast')));
    expect(find.textContaining('Последняя копия:'), findsOneWidget);
  });

  testWidgets('backup nudge: later snoozes; fresh copy or few trips hide it', (
    tester,
  ) async {
    final repo = MemoryRepository()..snapshot = three();
    final settings = MemorySettingsRepository();
    await launch(
      tester,
      repo,
      journal: false,
      settings: settings,
      backup: FakeBackupStore(),
      now: () => now,
    );
    await tester.tap(find.byKey(const Key('backupNudgeLater')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backupNudge')), findsNothing);
    expect(settings.settings.backupNudgeUntil, DateTime(2026, 10, 13, 12));
    // Чистая логика: свежая копия и мало записей — без напоминания,
    // старая копия — напоминание.
    final fresh = AppSettings(
      lastBackupAt: now.subtract(const Duration(days: 3)),
    );
    expect(fresh.backupNudgeDue(now, 10), isFalse);
    final stale = AppSettings(
      lastBackupAt: now.subtract(const Duration(days: 40)),
    );
    expect(stale.backupNudgeDue(now, 10), isTrue);
    expect(const AppSettings().backupNudgeDue(now, 2), isFalse);
    // Настройки переживают JSON.
    final json = stale.copyWith(backupNudgeUntil: now).toJson();
    final back = AppSettings.fromJson(json);
    expect(back.lastBackupAt, stale.lastBackupAt!.toUtc());
    expect(back.backupNudgeUntil, now.toUtc());
  });

  testWidgets('one-day trips show a single date in journal and recent rows', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..snapshot = JournalSnapshot(
        homeCountry: 'Россия',
        homeCountryCode: 'RU',
        current: CurrentStay(
          id: 'cur',
          country: 'Россия',
          countryCode: 'RU',
          arrival: Day(2026, 8, 20),
          confirmedOn: Day(2026, 9, 13),
        ),
        trips: [
          Trip(
            id: 'one',
            country: 'Андорра',
            countryCode: 'AD',
            arrival: Day(2026, 6, 17),
            departure: Day(2026, 6, 17),
          ),
        ],
      );
    await launch(tester, repo, journal: false);
    await reveal(tester, find.byKey(const Key('trip-one')));
    expect(find.textContaining('17.06.2026 — 17.06.2026'), findsNothing);
    expect(find.textContaining('17.06.2026'), findsWidgets);
    await tester.tap(find.byKey(const Key('trip-one')));
    await tester.pumpAndSettle();
  });
}
