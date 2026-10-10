import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'widget_test.dart' show launch, reveal;

Future<void> fling(
  WidgetTester tester,
  Finder target, {
  required bool left,
}) async {
  await tester.fling(target, Offset(left ? -260 : 260, 0), 1200);
  await tester.pumpAndSettle();
}

/// Кнопка года стоит выше календаря и может быть не построена ListView:
/// поднимаемся к ней перед проверкой и возвращаемся к сетке.
Future<void> expectYear(WidgetTester tester, int year, Finder back) async {
  await reveal(tester, find.byKey(const Key('dashboardYear')));
  expect(
    find.descendant(
      of: find.byKey(const Key('dashboardYear')),
      matching: find.text('$year'),
    ),
    findsOneWidget,
  );
  await reveal(tester, back);
}

void main() {
  testWidgets('swipe on the month grid changes the year, not into the future', (
    tester,
  ) async {
    final repo = dashboardFixture();
    await launch(tester, repo, journal: false);
    final grid = find.byKey(const Key('month-5'));
    await expectYear(tester, 2026, grid);
    // Влево — вперёд: 2027 в будущем, ничего не меняется.
    await fling(tester, grid, left: true);
    await expectYear(tester, 2026, grid);
    // Вправо — назад.
    await fling(tester, grid, left: false);
    await expectYear(tester, 2025, grid);
    await fling(tester, grid, left: false);
    await expectYear(tester, 2024, grid);
    await fling(tester, grid, left: true);
    await expectYear(tester, 2025, grid);
    expect(repo.writes, 0);
  });

  testWidgets('swipe on the expanded month pages months and crosses years', (
    tester,
  ) async {
    await launch(tester, dashboardFixture(), journal: false);
    await reveal(tester, find.byKey(const Key('month-3')));
    await tester.tap(find.byKey(const Key('month-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expanded-3')), findsOneWidget);
    await fling(tester, find.byKey(const Key('expanded-3')), left: true);
    expect(find.byKey(const Key('expanded-4')), findsOneWidget);
    await fling(tester, find.byKey(const Key('expanded-4')), left: false);
    await fling(tester, find.byKey(const Key('expanded-3')), left: false);
    await fling(tester, find.byKey(const Key('expanded-2')), left: false);
    expect(find.byKey(const Key('expanded-1')), findsOneWidget);
    // Январь → назад: декабрь предыдущего года, год сменился.
    await fling(tester, find.byKey(const Key('expanded-1')), left: false);
    expect(find.byKey(const Key('expanded-12')), findsOneWidget);
    await expectYear(tester, 2025, find.byKey(const Key('expanded-12')));
    // Декабрь 2025 → вперёд: январь 2026.
    await fling(tester, find.byKey(const Key('expanded-12')), left: true);
    expect(find.byKey(const Key('expanded-1')), findsOneWidget);
    await expectYear(tester, 2026, find.byKey(const Key('expanded-1')));
    // Декабрь текущего года → вперёд: будущего нет, остаёмся.
    for (var i = 0; i < 11; i++) {
      await fling(tester, find.byKey(Key('expanded-${i + 1}')), left: true);
    }
    expect(find.byKey(const Key('expanded-12')), findsOneWidget);
    await fling(tester, find.byKey(const Key('expanded-12')), left: true);
    expect(find.byKey(const Key('expanded-12')), findsOneWidget);
    await expectYear(tester, 2026, find.byKey(const Key('expanded-12')));
  });
}
