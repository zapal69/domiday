import 'package:domiday/year_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'widget_test.dart' show launch, openCalendar, reveal;

void main() {
  testWidgets('calendar tab: country filter paints only that country', (tester) async {
    await launch(tester, dashboardFixture(), journal: false);
    await openCalendar(tester);
    YearCalendar calendar() => tester.widget<YearCalendar>(find.byType(YearCalendar));
    final all = calendar().summary.countries.length;
    expect(all, greaterThan(1));
    await reveal(tester, find.byKey(const Key('calendarCountry')));
    await tester.tap(find.byKey(const Key('calendarCountry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendarCountry-ge')));
    await tester.pumpAndSettle();
    expect(calendar().summary.countries.map((c) => c.key), ['ge']);
    expect(find.text('Грузия'), findsWidgets);
    // Плитки года по-прежнему за весь год, фильтр только на календаре.
    expect(find.byKey(const Key('knownTotal')), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendarCountryClear')));
    await tester.pumpAndSettle();
    expect(calendar().summary.countries.length, all);
  });
}
