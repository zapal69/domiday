import 'dart:async';

import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domiday/settings.dart';

import 'trip_test.dart' show trip;
import 'widget_test.dart'
    show
        MemoryRepository,
        fixture,
        launch,
        reveal,
        chooseToday,
        openCalendar,
        goToday;

/// Заголовок года на дашборде: крупный год внутри кнопки `dashboardYear`.
Finder yearHeader(String year) => find.descendant(
  of: find.byKey(const Key('dashboardYear')),
  matching: find.text(year),
);

Future<void> tapVisible(WidgetTester tester, String key) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await reveal(tester, find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

MemoryRepository dashboardFixture() =>
    MemoryRepository([
        trip('2026-01-01', '2026-01-12', id: 'home', country: 'Россия'),
        trip(
          '2026-06-01',
          '2026-06-12',
          id: 'georgia',
          country: 'Грузия',
          city: 'Тбилиси',
        ),
        trip(
          '2026-07-01',
          '2026-07-20',
          id: 'turkey',
          country: 'Турция',
          city: 'Стамбул',
        ),
      ])
      ..snapshot = JournalSnapshot(
        trips: [
          trip('2026-01-01', '2026-01-12', id: 'home', country: 'Россия'),
          trip(
            '2026-06-01',
            '2026-06-12',
            id: 'georgia',
            country: 'Грузия',
            city: 'Тбилиси',
          ),
          trip(
            '2026-07-01',
            '2026-07-20',
            id: 'turkey',
            country: 'Турция',
            city: 'Стамбул',
          ),
        ],
        homeCountry: 'Россия',
        current: CurrentStay(
          id: 'now',
          country: 'Грузия',
          arrival: Day(2026, 8, 20),
          confirmedOn: Day(2026, 9, 13),
        ),
      );

/// Коды стран назначаются при загрузке; сравниваем историю без них.
Map<String, Object?> noCode(Map<String, Object?> json) =>
    Map.of(json)..remove('countryCode');

void main() {
  testWidgets(
    'v1 onboarding, home default editable, unknown arrival, failure/gate/restart',
    (tester) async {
      final repo = MemoryRepository([fixture()])
        ..snapshot = JournalSnapshot(trips: [fixture()])
        ..failSave = true;
      await launch(tester, repo, journal: false);
      expect(find.text('Начнём с вас'), findsOneWidget);
      expect(find.text('Ваши прежние поездки сохранены: 1.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('homeCountry')), 'Россия');
      final currentField = tester.widget<TextFormField>(
        find.byKey(const Key('statusCountry')),
      );
      expect(currentField.controller!.text, 'Россия');
      await tester.enterText(find.byKey(const Key('statusCountry')), 'Грузия');
      await tester.enterText(find.byKey(const Key('homeCountry')), 'Армения');
      expect(currentField.controller!.text, 'Грузия');
      await tapVisible(tester, 'saveStatus');
      expect(find.byKey(const Key('statusError')), findsOneWidget);
      expect(repo.snapshot.homeCountry, isNull);
      expect(noCode(repo.records.single.toJson()), noCode(fixture().toJson()));
      repo.failSave = false;
      repo.saveGate = Completer<void>();
      await tester.tap(find.byKey(const Key('saveStatus')));
      await tester.pump();
      expect(find.text('Сохраняем…'), findsOneWidget);
      expect(repo.snapshot.homeCountry, isNull);
      await tester.tap(find.byKey(const Key('saveStatus')));
      expect(repo.writes, 2);
      repo.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(repo.snapshot.current!.arrival, isNull);
      expect(repo.snapshot.current!.country, 'Грузия');
      expect(repo.snapshot.homeCountry, 'Армения');
      expect(noCode(repo.records.single.toJson()), noCode(fixture().toJson()));
      expect(find.text('Дата приезда неизвестна'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('unknownTotal')));
      expect(
        find.descendant(
          of: find.byKey(const Key('unknownTotal')),
          matching: find.text('256 дн.'),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await launch(tester, repo, journal: false);
      expect(find.text('Начнём с вас'), findsNothing);
      expect(find.text('Дата приезда неизвестна'), findsOneWidget);
    },
  );

  testWidgets(
    'onboarding known arrival, required country and accessible old archive before profile',
    (tester) async {
      final repo = MemoryRepository()
        ..snapshot = JournalSnapshot(trips: [fixture()]);
      await launch(tester, repo, journal: false);
      await tapVisible(tester, 'onboardingJournal');
      await reveal(tester, find.byKey(const Key('trip-fixture')));
      expect(repo.writes, 0);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'saveStatus');
      expect(repo.writes, 0);
      await reveal(tester, find.byKey(const Key('homeCountry')));
      await tester.enterText(find.byKey(const Key('homeCountry')), 'Россия');
      await chooseToday(tester, 'statusArrival');
      await tapVisible(tester, 'saveStatus');
      expect(repo.snapshot.current!.arrival, Day(2026, 9, 13));
      expect(find.text('1 день'), findsOneWidget);
      expect(
        find.text('С 13.09.2026, включая день приезда и сегодня.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'dashboard country/year drill-down includes current editor, never persists synthetic trip',
    (tester) async {
      final repo = dashboardFixture();
      await launch(tester, repo, journal: false);
      await openCalendar(tester);
      expect(yearHeader('2026'), findsOneWidget);
      await tapVisible(tester, 'country-stat-ge');
      // Страница страны: дни за год и за всё время, записи ниже календаря.
      expect(find.byKey(const Key('countryTitle')), findsOneWidget);
      expect(find.textContaining('в 2026 ·'), findsOneWidget);
      // Текущее пребывание — в записях; нажатие ведёт к дате.
      await reveal(tester, find.byKey(const Key('trip-now')));
      await tapVisible(tester, 'trip-now');
      expect(find.text('Дата приезда'), findsOneWidget);
      expect(find.byKey(const Key('saveTrip')), findsNothing);
      await tapVisible(tester, 'unknownArrival');
      await chooseToday(tester, 'statusArrival');
      await tapVisible(tester, 'saveStatus');
      expect(repo.snapshot.current!.arrival, Day(2026, 9, 13));
      expect(repo.records.where((t) => t.id == 'now'), isEmpty);
      expect(repo.records, hasLength(3));
    },
  );

  testWidgets(
    'year selector has no future years, past year unknown and current full duration unchanged',
    (tester) async {
      final repo = dashboardFixture();
      await launch(tester, repo, journal: false);
      await reveal(tester, find.byKey(const Key('country-stat-ru')));
      expect(
        find.descendant(
          of: find.byKey(const Key('country-stat-ru')),
          matching: find.text('Домашняя страна'),
        ),
        findsOneWidget,
      );
      await tapVisible(tester, 'dashboardYear');
      expect(find.text('2027'), findsNothing);
      await tester.tap(find.widgetWithText(ListTile, '2024'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('unknownTotal')));
      expect(
        find.descendant(
          of: find.byKey(const Key('unknownTotal')),
          matching: find.text('366 дн.'),
        ),
        findsOneWidget,
      );
      // Карточка «Сейчас» — на вкладке «Сегодня».
      await goToday(tester);
      await reveal(
        tester,
        find.text('С 20.08.2026, включая день приезда и сегодня.'),
      );
      expect(
        find.text('С 20.08.2026, включая день приезда и сегодня.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'change preview cancel, same country validation, same-day transition atomic failure then confirm',
    (tester) async {
      final repo = dashboardFixture();
      await launch(tester, repo, journal: false);
      await tapVisible(tester, 'changeCountry');
      await tester.enterText(find.byKey(const Key('statusCountry')), 'Грузия');
      await tapVisible(tester, 'saveStatus');
      expect(find.text('Выберите другую страну'), findsOneWidget);
      expect(repo.writes, 0);
      await reveal(tester, find.byKey(const Key('statusCountry')));
      await tester.enterText(find.byKey(const Key('statusCountry')), 'Армения');
      await tapVisible(tester, 'saveStatus');
      expect(find.textContaining('Завершится: Грузия'), findsOneWidget);
      expect(find.textContaining('Начнётся: Армения'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      repo.failSave = true;
      await tapVisible(tester, 'saveStatus');
      await tester.tap(find.text('Подтвердить переезд'));
      await tester.pumpAndSettle();
      expect(repo.records, hasLength(3));
      expect(repo.snapshot.current!.country, 'Грузия');
      expect(find.byKey(const Key('statusError')), findsOneWidget);
      repo.failSave = false;
      await tapVisible(tester, 'saveStatus');
      await tester.tap(find.text('Подтвердить переезд'));
      await tester.pumpAndSettle();
      expect(repo.records, hasLength(4));
      expect(repo.records.last.departure, Day(2026, 9, 13));
      expect(repo.snapshot.current!.arrival, Day(2026, 9, 13));
      expect(repo.snapshot.current!.country, 'Армения');
      await tester.pumpWidget(const SizedBox());
      await launch(tester, repo, journal: false);
      expect(find.text('Армения'), findsWidgets);
      expect(repo.records.last.id, 'now');
    },
  );

  testWidgets(
    'unknown prior stay remains accessible archive; date correction creates editable dated entry',
    (tester) async {
      final repo = MemoryRepository();
      await launch(tester, repo, journal: false);
      await tapVisible(tester, 'changeCountry');
      await tester.enterText(find.byKey(const Key('statusCountry')), 'Турция');
      await tapVisible(tester, 'saveStatus');
      expect(find.textContaining('Приезд неизвестен'), findsOneWidget);
      await tester.tap(find.text('Подтвердить переезд'));
      await tester.pumpAndSettle();
      expect(repo.records, isEmpty);
      expect(repo.snapshot.undated, hasLength(1));
      await tester.tap(find.byKey(const Key('openJournal')));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'undated-current');
      await chooseToday(tester, 'statusArrival');
      await tapVisible(tester, 'saveStatus');
      expect(repo.snapshot.undated, isEmpty);
      expect(repo.records.single.id, 'current');
      expect(repo.records.single.days, 1);
      await tapVisible(tester, 'trip-current');
      await reveal(tester, find.byKey(const Key('deleteTrip')));
      expect(find.byKey(const Key('deleteTrip')), findsOneWidget);
    },
  );

  testWidgets(
    'home setting failure retains draft; success reclassifies without rewriting history',
    (tester) async {
      final repo = dashboardFixture()..failSave = true;
      final old = repo.records.map((t) => noCode(t.toJson())).toList();
      await launch(tester, repo, journal: false);
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('homeCountry')), 'Грузия');
      await tapVisible(tester, 'saveStatus');
      expect(repo.snapshot.homeCountry, 'Россия');
      expect(find.byKey(const Key('statusError')), findsOneWidget);
      repo.failSave = false;
      await tapVisible(tester, 'saveStatus');
      expect(repo.snapshot.homeCountry, 'Грузия');
      expect(repo.records.map((t) => noCode(t.toJson())).toList(), old);
      await reveal(tester, find.byKey(const Key('homeTotal')));
      expect(
        find.descendant(
          of: find.byKey(const Key('homeTotal')),
          matching: find.text('37 дн.'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'gap preview cancellation, actual dates, failure, confirm, repeated fill idempotent',
    (tester) async {
      final repo = MemoryRepository([
        trip('2026-01-01', '2026-01-01', id: 'a', country: 'Грузия'),
        trip('2026-01-03', '2026-01-03', id: 'b', country: 'Грузия'),
      ]);
      await launch(tester, repo, journal: false);
      await tapVisible(tester, 'previewGaps');
      expect(find.text('02.01.2026 — 02.01.2026\n1 дн.'), findsOneWidget);
      expect(find.text('Всего: 1 дн. · записей: 1'), findsOneWidget);
      await reveal(tester, find.text('Отмена — ничего не добавлять'));
      await tester.tap(find.text('Отмена — ничего не добавлять'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      await tapVisible(tester, 'previewGaps');
      repo.failSave = true;
      await tapVisible(tester, 'confirmGaps');
      expect(find.byKey(const Key('gapError')), findsOneWidget);
      expect(repo.records, hasLength(2));
      repo.failSave = false;
      await tapVisible(tester, 'confirmGaps');
      expect(repo.records, hasLength(3));
      expect(repo.records.last.country, 'Россия');
      expect(find.byKey(const Key('confirmGaps')), findsNothing);
      await reveal(tester, find.text('Готово'));
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'previewGaps');
      expect(find.byKey(const Key('confirmGaps')), findsNothing);
      expect(repo.writes, 2);
    },
  );

  testWidgets(
    'resume and calendar timer refresh full duration and year without persistence',
    (tester) async {
      var now = Day(2026, 12, 31);
      final repo = dashboardFixture();
      await launch(tester, repo, journal: false, today: () => now);
      await openCalendar(tester);
      expect(yearHeader('2026'), findsOneWidget);
      now = Day(2027, 1, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(yearHeader('2027'), findsOneWidget);
      await goToday(tester);
      expect(find.text('135 дней'), findsOneWidget);
      now = Day(2027, 1, 2);
      await tester.pump(const Duration(seconds: 31));
      expect(find.text('136 дней'), findsOneWidget);
      expect(repo.writes, 0);
    },
  );

  testWidgets(
    'dark 320px 180% onboarding/dashboard/settings/change/preview no overflow',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final repo = MemoryRepository()..snapshot = JournalSnapshot();
      await launch(tester, repo, journal: false, width: 320, scale: 1.8);
      await reveal(tester, find.byKey(const Key('homeCountry')));
      await tester.enterText(
        find.byKey(const Key('homeCountry')),
        'Очень длинное название домашней страны',
      );
      await tapVisible(tester, 'saveStatus');
      expect(tester.takeException(), isNull);
      await tapVisible(tester, 'previewGaps');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'saveStatus');
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byKey(const Key('dashboardScroll')),
        const Offset(0, 10000),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, 'changeCountry');
      await tester.enterText(find.byKey(const Key('statusCountry')), 'Грузия');
      await tapVisible(tester, 'saveStatus');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(repo.records, isEmpty);
    },
  );

  testWidgets(
    'language setting: system by default, English applies at once, persists',
    (tester) async {
      final settings = MemorySettingsRepository();
      final repo = dashboardFixture();
      await launch(tester, repo, journal: false, settings: settings);
      await openCalendar(tester);
      expect(yearHeader('2026'), findsOneWidget);
      await goToday(tester);
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      expect(find.text('Настройки'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('languageSetting')));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(settings.writes, 1);
      expect(settings.settings.locale, const Locale('en'));
      expect(find.text('Settings'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('homeCountry')));
      expect(find.text('Home country'), findsOneWidget);
      // Дневник не тронут: смена языка не пишет trips.json.
      expect(repo.writes, 0);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Sep 13, 2026'), findsNothing);
      expect(find.text('Today · Sep 13, 2026'), findsOneWidget);
      await openCalendar(tester);
      expect(yearHeader('2026'), findsOneWidget);
      // Перезапуск с сохранённой настройкой: сразу английский.
      await tester.pumpWidget(const SizedBox());
      await launch(tester, repo, journal: false, settings: settings);
      expect(find.text('Today · Sep 13, 2026'), findsOneWidget);
      await openCalendar(tester);
      expect(yearHeader('2026'), findsOneWidget);
      // Возврат к системному языку (в тестах — русский).
      await goToday(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('languageSetting')));
      // «System» есть и у темы — берём чип внутри блока языка.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('languageSetting')),
          matching: find.text('System'),
        ),
      );
      await tester.pumpAndSettle();
      expect(settings.settings.locale, isNull);
      expect(find.text('Настройки'), findsOneWidget);
    },
  );

  testWidgets('english dashboard has no overflow at 320px 180%', (
    tester,
  ) async {
    await launch(
      tester,
      dashboardFixture(),
      journal: false,
      width: 320,
      scale: 1.8,
      locale: const Locale('en'),
    );
    await reveal(tester, find.byKey(const Key('unknownTotal')));
    await reveal(tester, find.byKey(const Key('allJournal')));
    await tapVisible(tester, 'allJournal');
    await reveal(tester, find.byKey(const Key('addTrip')));
    await tapVisible(tester, 'addTrip');
    expect(find.text('New trip'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('country field: empty list starts with own countries', (
    tester,
  ) async {
    final repo = dashboardFixture();
    await launch(tester, repo, journal: false);
    await tapVisible(tester, 'changeCountry');
    await tester.tap(find.byKey(const Key('statusCountry')));
    await tester.pumpAndSettle();
    final options = find.byKey(const Key('countryOptions'));
    expect(options, findsOneWidget);
    final tiles = find.descendant(of: options, matching: find.byType(ListTile));
    String codeAt(int i) =>
        (tester.widget<ListTile>(tiles.at(i)).trailing! as Text).data!;
    // Прежняя страна (Грузия) при смене не нужна: сначала дом (Россия),
    // затем страны недавних поездок, затем алфавит с черты.
    const current = 'RU';
    expect(codeAt(0), current);
    expect(codeAt(1), 'TR');
    expect(
      find.descendant(of: options, matching: find.byType(Divider)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tiles.first,
        matching: find.byKey(const Key('flag-$current')),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'country field: list by prefix, chosen name gets a code, free text stays',
    (tester) async {
      final repo = dashboardFixture();
      await launch(tester, repo, journal: false);
      await tapVisible(tester, 'changeCountry');
      await tester.enterText(find.byKey(const Key('statusCountry')), 'арм');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('countryOptions')), findsOneWidget);
      await tester.tap(find.text('Армения'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('countryResolved')), findsOneWidget);
      expect(find.text('Армения · AM'), findsOneWidget);
      await chooseToday(tester, 'statusArrival');
      await tapVisible(tester, 'saveStatus');
      await tester.tap(find.text('Подтвердить переезд'));
      await tester.pumpAndSettle();
      expect(repo.snapshot.current!.country, 'Армения');
      expect(repo.snapshot.current!.countryCode, 'AM');
      // Прежнее пребывание ушло в историю с кодом, текст не тронут.
      final closed = repo.records.firstWhere((t) => t.id == 'now');
      expect(closed.country, 'Грузия');
      expect(closed.countryCode, 'GE');
      // Свободный текст: без кода, с предупреждением, но сохраняется.
      await tapVisible(tester, 'changeCountry');
      await tester.enterText(find.byKey(const Key('statusCountry')), 'Абхазия');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('countryNoCode')), findsOneWidget);
      await chooseToday(tester, 'statusArrival');
      await tapVisible(tester, 'saveStatus');
      await tester.tap(find.text('Подтвердить переезд'));
      await tester.pumpAndSettle();
      expect(repo.snapshot.current!.country, 'Абхазия');
      expect(repo.snapshot.current!.countryCode, isNull);
      expect(repo.snapshot.toJson()['schemaVersion'], 5);
    },
  );

  testWidgets('names follow the interface language once coded', (tester) async {
    final settings = MemorySettingsRepository();
    final repo = dashboardFixture();
    await launch(tester, repo, journal: false, settings: settings);
    // Русские тексты фикстуры сопоставлены с кодами при загрузке.
    await reveal(tester, find.byKey(const Key('country-stat-ge')));
    expect(find.text('Грузия'), findsWidgets);
    await goToday(tester);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('languageSetting')));
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Georgia'));
    expect(find.text('Georgia'), findsWidgets);
    expect(find.text('Грузия'), findsNothing);
    // Тексты в файле не переведены: это только отображение.
    expect(repo.snapshot.current!.country, 'Грузия');
    expect(repo.writes, 0);
  });
}
