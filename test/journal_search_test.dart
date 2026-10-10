import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show MemoryRepository, fixture, launch, reveal;

void main() {
  testWidgets('journal search: other-language names and country suggestions', (
    tester,
  ) async {
    final repo = MemoryRepository([
      fixture(id: 'ge', country: 'Грузия'),
      fixture(id: 'tr', country: 'Турция'),
    ]);
    await launch(tester, repo);
    await reveal(tester, find.byKey(const Key('trip-ge')));
    expect(find.byKey(const Key('trip-ge')), findsOneWidget);
    await reveal(tester, find.byKey(const Key('trip-tr')));
    expect(find.byKey(const Key('trip-tr')), findsOneWidget);
    // В файле «Грузия», интерфейс русский, а ищут по-английски: находит
    // через справочник.
    await reveal(tester, find.byKey(const Key('search')));
    await tester.enterText(find.byKey(const Key('search')), 'Georgia');
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('trip-ge')));
    expect(find.byKey(const Key('trip-ge')), findsOneWidget);
    expect(find.byKey(const Key('trip-tr')), findsNothing);
    // Подсказки стран, как в редакторе: только страны из дневника.
    await reveal(tester, find.byKey(const Key('search')));
    await tester.enterText(find.byKey(const Key('search')), 'Гру');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('journalSuggest-GE')), findsOneWidget);
    expect(find.byKey(const Key('journalSuggest-GR')), findsNothing);
    await tester.tap(find.byKey(const Key('journalSuggest-GE')));
    await tester.pumpAndSettle();
    // Выбор подсказки — фильтр по стране, поле очищено.
    await reveal(tester, find.byKey(const Key('search')));
    expect(
      tester.widget<TextField>(find.byKey(const Key('search'))).controller!.text,
      '',
    );
    await reveal(tester, find.byKey(const Key('trip-ge')));
    expect(find.byKey(const Key('trip-ge')), findsOneWidget);
    expect(find.byKey(const Key('trip-tr')), findsNothing);
    expect(find.byKey(const Key('journalSuggestions')), findsNothing);
  });
}
