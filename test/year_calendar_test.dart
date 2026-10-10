import 'package:domiday/l10n/app_localizations.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/theme.dart';
import 'package:domiday/trip.dart';
import 'package:domiday/year_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'widget_test.dart' show launch, reveal;

void main() {
  final today = Day(2026, 9, 13);

  test('calendar classifies days strictly from YearSummary sets', () {
    final summary = YearSummary(dashboardFixture().snapshot, 2026, today);
    final data = YearCalendarData(summary, today);
    // Fixture: home 01–12 Jan; away 01–12 Jun, 01–20 Jul, 20 Aug → today.
    expect(data.kindOf(1, 1), DayKind.home);
    expect(data.kindOf(1, 12), DayKind.home);
    expect(data.kindOf(1, 13), DayKind.unknown);
    expect(data.kindOf(6, 1), DayKind.away);
    expect(data.kindOf(7, 20), DayKind.away);
    expect(data.kindOf(8, 19), DayKind.unknown);
    expect(data.kindOf(9, 13), DayKind.away);
    expect(data.kindOf(9, 14), DayKind.future);
    expect(data.kindOf(12, 31), DayKind.future);
    expect(data.isToday(9, 13), isTrue);
    expect(data.isToday(9, 12), isFalse);
    // Unknown days are never painted: painted == known exactly.
    expect(data.paintedCount, summary.known.length);
    expect(data.paintedCount, 69);
  });

  test('border day belongs to both countries and paints as both', () {
    final snapshot = JournalSnapshot(
      trips: [
        Trip(
          id: 'h',
          country: 'Россия',
          arrival: Day(2026, 3, 1),
          departure: Day(2026, 3, 10),
        ),
        Trip(
          id: 'a',
          country: 'Грузия',
          arrival: Day(2026, 3, 10),
          departure: Day(2026, 3, 15),
        ),
      ],
      homeCountry: 'Россия',
      current: CurrentStay(
        id: 'now',
        country: 'Россия',
        arrival: null,
        confirmedOn: today,
      ),
    );
    final summary = YearSummary(snapshot, 2026, today);
    final data = YearCalendarData(summary, today);
    expect(data.kindOf(3, 9), DayKind.home);
    expect(data.kindOf(3, 10), DayKind.both);
    expect(data.kindOf(3, 11), DayKind.away);
    expect(data.paintedCount, summary.known.length);
    expect(summary.overlap, 1);
  });

  test('past year has no future cells and leap February', () {
    final summary = YearSummary(dashboardFixture().snapshot, 2024, today);
    final data = YearCalendarData(summary, today);
    expect(data.daysInMonth(2), 29);
    expect(data.kindOf(12, 31), DayKind.unknown);
    expect(data.paintedCount, 0);
  });

  for (final variant in [
    (width: 390.0, scale: 1.0, dark: false),
    (width: 320.0, scale: 1.8, dark: true),
  ]) {
    testWidgets(
      'renders ${variant.width}px ×${variant.scale} without exceptions',
      (tester) async {
        tester.view.physicalSize = Size(variant.width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final summary = YearSummary(dashboardFixture().snapshot, 2026, today);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppSettings.supported,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: domidayTheme(
              variant.dark ? Brightness.dark : Brightness.light,
            ),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(variant.width, 844),
                textScaler: TextScaler.linear(variant.scale),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: YearCalendar(summary: summary, today: today),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('yearCalendar')), findsOneWidget);
        expect(find.text('день в двух странах'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'mini months show weekday letters and day numbers; swipes animate',
    (tester) async {
      await launch(tester, dashboardFixture(), journal: false);
      final january = find.byKey(const Key('month-1'));
      await reveal(tester, january);
      expect(
        find.descendant(of: january, matching: find.text('15')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: january, matching: find.text('П')),
        findsNWidgets(2),
      );
      // Год — пейджер; раскрытый месяц — второй пейджер под сеткой.
      expect(find.byType(PageView), findsOneWidget);
      await tester.tap(january);
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsNWidgets(2));
      expect(find.byKey(const Key('expanded-1')), findsOneWidget);
    },
  );
}
