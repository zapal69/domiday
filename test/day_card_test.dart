import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture, tapVisible;
import 'widget_test.dart'
    show launch, reveal, MemoryRepository, goToday;

/// Раскрыть месяц и нажать на день в раскрытом виде.
Future<void> tapDay(WidgetTester tester, int month, int day) async {
  await reveal(tester, find.byKey(Key('month-$month')));
  if (find.byKey(Key('expanded-$month')).evaluate().isEmpty) {
    await tester.tap(find.byKey(Key('month-$month')));
    await tester.pumpAndSettle();
  }
  await reveal(tester, find.byKey(Key('day-2026-$month-$day')));
  await tester.tap(find.byKey(Key('day-2026-$month-$day')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'day card: tap opens sheet, row opens record, back returns to sheet',
    (tester) async {
      final repo = dashboardFixture();
      await launch(tester, repo, journal: false);
      // 5 июня — поездка в Грузию: раскрыть июнь, нажать на день.
      await tapDay(tester, 6, 5);
      expect(find.byKey(const Key('dayCard')), findsOneWidget);
      expect(find.text('05.06.2026'), findsOneWidget);
      expect(find.byKey(const Key('dayEvent-georgia')), findsOneWidget);
      expect(find.textContaining('Пребывание'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dayEvent-georgia')));
      await tester.pumpAndSettle();
      expect(find.text('Ваша поездка'), findsOneWidget);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      // Сначала карточка дня, затем календарь; ничего не записано.
      expect(find.byKey(const Key('dayCard')), findsOneWidget);
      expect(find.text('Ваша поездка'), findsNothing);
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dayCard')), findsNothing);
      // Раскрытый месяц и год сохранены.
      expect(find.byKey(const Key('expanded-6')), findsOneWidget);
      expect(repo.writes, 0);
    },
  );

  testWidgets('day card: empty day, current stay, future day', (tester) async {
    final repo = dashboardFixture();
    await launch(tester, repo, journal: false);
    await tapDay(tester, 5, 5);
    expect(find.text('Нет данных за этот день'), findsOneWidget);
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    // 1 сентября — текущее пребывание (приезд 20.08).
    await tapDay(tester, 9, 1);
    expect(find.byKey(const Key('dayEvent-now')), findsOneWidget);
    expect(find.textContaining('Текущее пребывание'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dayEvent-now')));
    await tester.pumpAndSettle();
    expect(find.text('Дата приезда'), findsWidgets);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    // Будущий день не открывает карточку.
    await tapDay(tester, 12, 25);
    expect(find.byKey(const Key('dayCard')), findsNothing);
    expect(repo.writes, 0);
  });

  testWidgets('transit: manual add via editor, shown in lists and calendar', (
    tester,
  ) async {
    final repo = dashboardFixture();
    await launch(tester, repo, journal: false);
    await tapVisible(tester, 'allJournal');
    await tapVisible(tester, 'addTrip');
    expect(find.text('Новая поездка'), findsOneWidget);
    await tester.tap(find.text('Транзит'));
    await tester.pumpAndSettle();
    expect(find.text('Новый транзит'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('country')), 'Катар');
    await tester.enterText(find.byKey(const Key('city')), 'Доха');
    await tapVisible(tester, 'quickToday');
    await tapVisible(tester, 'saveTrip');
    final saved = repo.records.firstWhere((t) => t.city == 'Доха');
    expect(saved.kind, TripKind.transit);
    expect(saved.countryCode, 'QA');
    expect(repo.snapshot.toJson()['schemaVersion'], 5);
    // В журнале подпись «Транзит», в статистике — отдельный счётчик.
    await reveal(tester, find.text('Транзит'));
    expect(find.text('Транзит'), findsWidgets);
    final summary = YearSummary(repo.snapshot, 2026, Day(2026, 9, 13));
    expect(summary.transit, contains(Day(2026, 9, 13).ordinal));
    expect(summary.countries.firstWhere((c) => c.key == 'qa').transits, 1);
    // На вкладке «Сегодня»: строка «Транзит сегодня» и карточка дня с
    // двумя записями.
    await goToday(tester);
    // Дашборд остался прокрученным вниз: поднимаемся к карточке «Сейчас».
    await reveal(tester, find.byKey(const Key('currentStay')));
    expect(find.byKey(const Key('transitToday')), findsOneWidget);
    expect(find.textContaining('Катар'), findsWidgets);
    await tapDay(tester, 9, 13);
    expect(find.byKey(const Key('dayEvent-now')), findsOneWidget);
    expect(find.byKey(Key('dayEvent-${saved.id}')), findsOneWidget);
  });

  testWidgets('day card in English on 320px 180% has no overflow', (
    tester,
  ) async {
    final repo = MemoryRepository()..snapshot = dashboardFixture().snapshot;
    await launch(
      tester,
      repo,
      journal: false,
      width: 320,
      scale: 1.8,
      locale: const Locale('en'),
    );
    await tapDay(tester, 7, 10);
    expect(find.byKey(const Key('dayEvent-turkey')), findsOneWidget);
    expect(find.textContaining('Stay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
