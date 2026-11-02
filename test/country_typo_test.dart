import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show MemoryRepository, launch, reveal, testDirectory;

/// Опечатка в стране (замечание тестировщика 2.11.2026): «frnace»
/// сохранялась как отдельная страна без кода, журнал и карта расходились.
void main() {
  test(
    'closest: typos and transpositions find the country, junk finds none',
    () {
      expect(testDirectory.closest('frnace').first.code, 'FR');
      expect(testDirectory.closest('Грузя').first.code, 'GE');
      expect(testDirectory.closest('Turkye').first.code, 'TR');
      expect(testDirectory.closest('Абхазия'), isEmpty);
      expect(testDirectory.closest('xx'), isEmpty);
    },
  );

  testWidgets('trip editor: typo offers the country, custom name can stay', (
    tester,
  ) async {
    final repo = MemoryRepository();
    await launch(tester, repo);
    await tester.tap(find.byKey(const Key('addTrip')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country')), 'frnace');
    await reveal(tester, find.byKey(const Key('quickToday')));
    await tester.tap(find.byKey(const Key('quickToday')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('countryNotFound')), findsOneWidget);
    expect(find.textContaining('Вы имели в виду Франция?'), findsOneWidget);
    // Отмена — ничего не записано, форма на месте.
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(repo.records, isEmpty);
    expect(find.byKey(const Key('saveTrip')), findsOneWidget);
    // «Выбрать Франция» подставляет название, запись получает код.
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('countryUse')));
    await tester.pumpAndSettle();
    expect(repo.records.single.country, 'Франция');
    expect(repo.records.single.countryCode, 'FR');
    // Своё название без похожих: диалог без предложения, «Оставить как
    // есть» сохраняет текст без кода.
    // Дождаться, пока уйдёт плашка «Поездка сохранена» над кнопкой.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('addTrip')));
    await tester.tap(find.byKey(const Key('addTrip')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country')), 'Абхазия');
    await reveal(tester, find.byKey(const Key('quickToday')));
    await tester.tap(find.byKey(const Key('quickToday')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('countryNotFound')), findsOneWidget);
    expect(find.byKey(const Key('countryUse')), findsNothing);
    await tester.tap(find.byKey(const Key('countryKeep')));
    await tester.pumpAndSettle();
    expect(repo.records.length, 2);
    expect(repo.records.last.country, 'Абхазия');
    expect(repo.records.last.countryCode, isNull);
  });
}
