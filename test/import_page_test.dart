import 'package:domiday/backup.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'timeline_import_test.dart' show export, visit, moscow, tbilisi, yerevan;
import 'widget_test.dart' show MemoryRepository, launch, reveal, testBorders;

/// Разбор идёт в изоляте: ждём его под runAsync, качая кадры.
Future<void> waitFor(WidgetTester tester, Finder target) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 200 && target.evaluate().isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
}

String timeline() => export([
  // Уже есть в дневнике (Россия 1–12 января).
  visit(moscow, '2026-01-01T09:00:00+03:00', '2026-01-12T18:00:00+03:00'),
  // Новое: Армения 1–10 марта.
  visit(yerevan, '2026-03-01T09:00:00+04:00', '2026-03-10T18:00:00+04:00'),
  // Текущее пребывание в Грузии с 20 августа — уже есть.
  visit(tbilisi, '2026-08-20T14:00:00+04:00', '2026-09-13T10:00:00+04:00'),
]);

void main() {
  testWidgets('import: preview from settings, apply adds only new periods', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final before = (await repo.load()).trips.length;
    final store = FakeBackupStore()
      ..toOpen = BackupPick('Timeline.json', timeline());
    await launch(
      tester,
      repo,
      journal: false,
      backup: store,
      borders: testBorders,
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('importPick')));
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    // Сначала инструкция: откуда взять файл; выбор — только JSON.
    expect(find.byKey(const Key('importIntro')), findsOneWidget);
    expect(find.textContaining('Timeline.json'), findsOneWidget);
    expect(store.lastJsonOnly, isNull);
    await reveal(tester, find.byKey(const Key('importChoose')));
    await tester.tap(find.byKey(const Key('importChoose')));
    await tester.pump();
    expect(store.lastJsonOnly, isTrue);
    await waitFor(tester, find.byKey(const Key('importApply')));
    expect(
      find.textContaining('Россия · 01.01.2026 — 12.01.2026'),
      findsOneWidget,
    );
    expect(find.textContaining('уже есть в дневнике'), findsNWidgets(2));
    expect(
      find.textContaining('Армения · 01.03.2026 — 10.03.2026'),
      findsOneWidget,
    );
    expect(find.text('Добавить: 1 запись'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importApply')));
    await tester.pumpAndSettle();
    expect(find.text('Добавить в дневник?'), findsOneWidget);
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    final after = await repo.load();
    expect(after.trips.length, before + 1);
    final added = after.trips.last;
    expect(added.countryCode, 'AM');
    expect(added.country, 'Армения');
    expect(added.arrival.iso, '2026-03-01');
    expect(added.departure.iso, '2026-03-10');
    expect(find.text('Добавлено: 1 запись'), findsOneWidget);
    // Вернулись в настройки.
    expect(find.byKey(const Key('importPick')), findsOneWidget);
  });

  testWidgets('import: unchecked rows are skipped; foreign file is reported', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final store = FakeBackupStore()
      ..toOpen = BackupPick('Timeline.json', timeline());
    await launch(
      tester,
      repo,
      journal: false,
      backup: store,
      borders: testBorders,
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('importPick')));
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('importChoose')));
    await tester.tap(find.byKey(const Key('importChoose')));
    await tester.pump();
    await waitFor(tester, find.byKey(const Key('importApply')));
    await tester.tap(find.byKey(const Key('import-1')));
    await tester.pumpAndSettle();
    expect(find.text('Добавить: 0 записей'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('importApply')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    // «Назад» из предпросмотра — в настройки, а не на инструкцию.
    expect(find.byKey(const Key('importIntro')), findsNothing);
    store.toOpen = const BackupPick('notes.txt', 'hello');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    // «Показать все файлы» — выбор без фильтра.
    await reveal(tester, find.byKey(const Key('importAnyFile')));
    await tester.tap(find.byKey(const Key('importAnyFile')));
    await tester.pump();
    expect(store.lastJsonOnly, isFalse);
    await waitFor(
      tester,
      find.textContaining('Это не файл Хронологии Google Maps'),
    );
    expect(repo.writes, 0);
    // С ошибки — обратно к инструкции и выбору другого файла.
    await tester.tap(find.byKey(const Key('importOtherFile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importIntro')), findsOneWidget);
  });

  testWidgets('onboarding: import fills home, current stay and records', (
    tester,
  ) async {
    final repo = MemoryRepository()..snapshot = JournalSnapshot();
    final store = FakeBackupStore()
      ..toOpen = BackupPick('Timeline.json', timeline());
    await launch(
      tester,
      repo,
      journal: false,
      backup: store,
      borders: testBorders,
    );
    expect(find.text('Уже есть история?'), findsOneWidget);
    expect(find.byKey(const Key('onboardingRestore')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboardingImport')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('importChoose')));
    await tester.tap(find.byKey(const Key('importChoose')));
    await tester.pump();
    await waitFor(tester, find.byKey(const Key('importApply')));
    // Дом — самая частая страна (Грузия по дням), текущее — открытый период.
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('importHome')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      'Грузия',
    );
    expect(find.byKey(const Key('importCurrent')), findsNothing);
    expect(find.textContaining('станет текущим пребыванием'), findsOneWidget);
    expect(find.text('Добавить: 3 записи'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importApply')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    final s = await repo.load();
    expect(s.homeCountry, 'Грузия');
    expect(s.homeCountryCode, 'GE');
    expect(s.current!.countryCode, 'GE');
    expect(s.current!.arrival!.iso, '2026-08-20');
    expect(s.trips.map((t) => t.countryCode), ['RU', 'AM']);
    // Онбординг закончен — главный экран.
    expect(find.text('Уже есть история?'), findsNothing);
    expect(find.byKey(const Key('navBar')), findsOneWidget);
    expect(find.byKey(const Key('dashboardScroll')), findsOneWidget);
  });

  testWidgets('empty journal and empty recent trips offer the import', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..snapshot = JournalSnapshot(
        homeCountry: 'Кипр',
        homeCountryCode: 'CY',
        current: CurrentStay(
          id: 'now',
          country: 'Кипр',
          countryCode: 'CY',
          arrival: Day(2026, 1, 1),
          confirmedOn: Day(2026, 9, 13),
        ),
      );
    await launch(
      tester,
      repo,
      journal: false,
      backup: FakeBackupStore(),
      borders: testBorders,
    );
    // «Сегодня»: дни идут сами; поездок нет — можно импортировать.
    expect(find.byKey(const Key('countsItself')), findsOneWidget);
    await reveal(tester, find.byKey(const Key('todayImport')));
    expect(find.byKey(const Key('todayImport')), findsOneWidget);
    await tester.tap(find.byKey(const Key('openJournal')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('journalImport')));
    await tester.tap(find.byKey(const Key('journalImport')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importIntro')), findsOneWidget);
  });
}
