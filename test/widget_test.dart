import 'dart:async';
import 'dart:io';

import 'package:domiday/background.dart';
import 'package:domiday/backup.dart';
import 'package:domiday/borders.dart';
import 'package:domiday/countries.dart';
import 'package:domiday/locator.dart';
import 'package:domiday/main.dart';
import 'package:domiday/repository.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/share.dart';
import 'package:domiday/trip.dart';
import 'package:domiday/snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryRepository implements TripRepository {
  JournalSnapshot snapshot;
  List<Trip> get records => snapshot.trips;
  int writes = 0;
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? saveGate;
  MemoryRepository([List<Trip> initial = const []])
    : snapshot = JournalSnapshot(
        trips: initial,
        homeCountry: 'Россия',
        current: CurrentStay(
          id: 'current',
          country: 'Россия',
          arrival: null,
          confirmedOn: Day(2026, 9, 13),
        ),
      );

  @override
  Future<JournalSnapshot> load() async {
    if (failLoad) throw StateError('test load error');
    return snapshot;
  }

  @override
  Future<void> save(JournalSnapshot next) async {
    writes++;
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw StateError('test write error');
    snapshot = next;
  }
}

/// Настоящий справочник: коды назначаются как в приложении.
final testDirectory = CountryDirectory.fromJson(
  File('assets/countries.json').readAsStringSync(),
);

/// Настоящие границы для тестов определения страны.
final testBorders = CountryBorders.fromJson(
  File('assets/borders.json').readAsStringSync(),
);

Trip fixture({String id = 'fixture', String country = 'Грузия'}) => Trip(
  id: id,
  country: country,
  city: country == 'Турция' ? 'Анталья' : 'Тбилиси',
  note: country == 'Турция'
      ? 'Прогулка по набережной'
      : 'Улочки старого города',
  arrival: Day(2024, 5, 1),
  departure: Day(2024, 5, 8),
);

Future<void> launch(
  WidgetTester tester,
  MemoryRepository repository, {
  double width = 390,
  double height = 844,
  double scale = 1,
  bool journal = true,
  Day Function()? today,
  // Тесты написаны на русском интерфейсе; язык системы в них — русский.
  Locale locale = const Locale('ru'),
  MemorySettingsRepository? settings,
  LocationSource? location,
  DateTime Function()? now,
  BackgroundService? background,
  ValueNotifier<int>? reviewRequests,
  BackupStore? backup,
  CountryBorders? borders,
  ShareService? share,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    DomidayApp(
      repository: repository,
      settings: settings ?? MemorySettingsRepository(),
      directory: testDirectory,
      borders: borders ?? (location == null ? null : testBorders),
      location: location,
      today: today ?? () => Day(2026, 9, 13),
      now: now ?? () => DateTime(2026, 9, 13, 12),
      background: background,
      reviewRequests: reviewRequests,
      backup: backup,
      share: share,
    ),
  );
  await tester.pumpAndSettle();
  // Флаги — PNG-ассеты: в тестах декодирование асинхронно, без прогрева
  // они не попадут в кадр и в golden. Прогреваем флаги фикстур.
  final element = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final code in ['ru', 'ge', 'tr', 'am', 'qa']) {
      await precacheImage(AssetImage('assets/flags/$code.png'), element);
    }
  });
  await tester.pumpAndSettle();
  if (journal && find.byKey(const Key('openJournal')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('openJournal')));
    await tester.pumpAndSettle();
  }
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await _scrollTo(tester, target);
  if (target.evaluate().isNotEmpty) return;
  // Главный экран разложен по вкладкам («Сегодня», «Календарь», «Карта»,
  // «Журнал»): цели нет на текущей — ищем на остальных.
  final bar = find.byKey(const Key('navBar'));
  if (bar.evaluate().isEmpty) return;
  final destinations = find.descendant(
    of: bar,
    matching: find.byType(NavigationDestination),
  );
  for (var i = 0; i < destinations.evaluate().length; i++) {
    await tester.tap(destinations.at(i));
    await tester.pumpAndSettle();
    await _scrollTo(tester, target);
    if (target.evaluate().isNotEmpty) return;
  }
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  if (find.byType(ListView).evaluate().isEmpty) return;
  final root = find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  final position = tester.state<ScrollableState>(root).position;
  // Scroll the page, not a multiline TextField under the gesture's midpoint.
  // Reset also reveals lazily disposed items above the viewport.
  if (target.evaluate().isEmpty) {
    position.jumpTo(0);
    await tester.pump();
  }
  for (var i = 0; target.evaluate().isEmpty && i < 100; i++) {
    position.jumpTo((position.pixels + 220).clamp(0, position.maxScrollExtent));
    await tester.pump();
  }
  // Довести до видимости только вертикальной прокруткой списка: общий
  // ensureVisible подкручивал бы и горизонтальный PageView календаря.
  // Как ensureVisible с выравниванием 0: цель к верхнему краю списка, чтобы
  // элементы ниже неё были построены и видны.
  if (target.evaluate().isEmpty) return;
  final viewport = tester.getRect(find.byType(ListView).first);
  final delta = tester.getRect(target).top - viewport.top;
  if (delta.abs() > 0.5) {
    position.jumpTo(
      (position.pixels + delta).clamp(0, position.maxScrollExtent),
    );
  }
  await tester.pumpAndSettle();
}

/// Вкладки нижней панели: «Сегодня» и «Календарь».
Future<void> goToday(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('navToday')));
  await tester.pumpAndSettle();
}

Future<void> openCalendar(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('navCalendar')));
  await tester.pumpAndSettle();
}

Future<void> chooseToday(WidgetTester tester, String key) async {
  await reveal(tester, find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  expect(find.text('Выбрать'), findsOneWidget);
  await tester.tap(find.text('Выбрать'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'empty -> add -> edit -> search -> cancel delete -> confirmed delete',
    (tester) async {
      final repo = MemoryRepository();
      await launch(tester, repo);
      expect(find.text('С какой поездки начнём?'), findsOneWidget);
      expect(repo.records, isEmpty);
      await tester.tap(find.byKey(const Key('addTrip')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('country')), 'Грузия');
      await tester.enterText(find.byKey(const Key('city')), 'Тбилиси');
      await reveal(tester, find.byKey(const Key('quickToday')));
      await tester.tap(find.byKey(const Key('quickToday')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('saveTrip')));
      await tester.tap(find.byKey(const Key('saveTrip')));
      await tester.pumpAndSettle();
      expect(repo.records, hasLength(1));
      expect(repo.records.single.days, 1);
      expect(find.text('Поездка сохранена'), findsOneWidget);
      final id = repo.records.single.id;
      await reveal(tester, find.byKey(Key('trip-$id')));
      await tester.tap(find.byKey(Key('trip-$id')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('city')), 'Батуми');
      await reveal(tester, find.byKey(const Key('saveTrip')));
      await tester.tap(find.byKey(const Key('saveTrip')));
      await tester.pumpAndSettle();
      expect(repo.records.single.city, 'Батуми');
      await tester.drag(find.byType(ListView).first, const Offset(0, 1600));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('search')), 'нет такого');
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Таких записей пока нет.'));
      expect(find.text('Найдено поездок: 0'), findsOneWidget);
      await tester.tap(find.text('Сбросить фильтры'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(Key('trip-$id')));
      await tester.tap(find.byKey(Key('trip-$id')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('deleteTrip')));
      await tester.tap(find.byKey(const Key('deleteTrip')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(repo.records, hasLength(1));
      expect(repo.writes, 2);
      await tester.tap(find.byKey(const Key('deleteTrip')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(repo.records, isEmpty);
      expect(find.text('С какой поездки начнём?'), findsOneWidget);
    },
  );

  testWidgets(
    'unreadable journal blocks edits; retry opens without replacing data',
    (tester) async {
      final repo = MemoryRepository([fixture()])..failLoad = true;
      await launch(tester, repo);
      expect(find.text('Не удалось открыть дневник'), findsOneWidget);
      expect(find.byKey(const Key('addTrip')), findsNothing);
      expect(repo.writes, 0);
      repo.failLoad = false;
      await tester.tap(find.text('Повторить открытие'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('openJournal')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addTrip')), findsOneWidget);
      expect(repo.records, hasLength(1));
    },
  );

  testWidgets('save error retains form and retry awaits disk success', (
    tester,
  ) async {
    final repo = MemoryRepository([fixture()])..failSave = true;
    await launch(tester, repo);
    await reveal(tester, find.byKey(const Key('trip-fixture')));
    await tester.tap(find.byKey(const Key('trip-fixture')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('city')), 'Батуми');
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('formError')), findsOneWidget);
    expect(repo.records.single.city, 'Тбилиси');
    expect(find.text('Поездка сохранена'), findsNothing);
    repo.failSave = false;
    repo.saveGate = Completer<void>();
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pump();
    expect(find.text('Сохраняем…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saveTrip')));
    expect(repo.writes, 2);
    repo.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(repo.records.single.city, 'Батуми');
    expect(find.text('Поездка сохранена'), findsOneWidget);
  });

  testWidgets('missing dates are explained and not written', (tester) async {
    final repo = MemoryRepository();
    await launch(tester, repo);
    await tester.tap(find.byKey(const Key('addTrip')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country')), 'Любая страна');
    await tester.enterText(find.byKey(const Key('city')), '');
    await reveal(tester, find.byKey(const Key('saveTrip')));
    await tester.tap(find.byKey(const Key('saveTrip')));
    await tester.pumpAndSettle();
    expect(find.text('Выберите дату приезда и дату выезда'), findsOneWidget);
    expect(repo.writes, 0);
  });

  testWidgets('country and year filters combine, clip days, and reset', (
    tester,
  ) async {
    final repo = MemoryRepository([
      Trip(
        id: 'cross-year',
        country: 'Грузия',
        arrival: Day(2023, 12, 30),
        departure: Day(2024, 1, 2),
      ),
      fixture(id: 'other', country: 'Турция'),
    ]);
    await launch(tester, repo);
    await tester.tap(find.text('Все страны'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Грузия'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Все годы'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '2024'));
    await tester.pumpAndSettle();
    expect(find.text('Поездок: 1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('Дни — только в 2024 году.'), findsOneWidget);
    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();
    expect(find.text('Поездок: 2'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('failed delete does not remove record', (tester) async {
    final repo = MemoryRepository([fixture()])..failSave = true;
    await launch(tester, repo);
    await reveal(tester, find.byKey(const Key('trip-fixture')));
    await tester.tap(find.byKey(const Key('trip-fixture')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('deleteTrip')));
    await tester.tap(find.byKey(const Key('deleteTrip')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(repo.records, hasLength(1));
    expect(find.textContaining('Не удалось удалить запись.'), findsOneWidget);
    expect(find.text('Поездка удалена'), findsNothing);
  });

  testWidgets('320px large text: filled summary and long country filter', (
    tester,
  ) async {
    final longName = 'Очень длинное название страны для проверки интерфейса';
    await launch(
      tester,
      MemoryRepository([fixture(country: longName)]),
      width: 320,
      scale: 1.8,
    );
    await reveal(tester, find.text('Все страны'));
    await tester.tap(find.text('Все страны'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, longName));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await reveal(tester, find.byKey(const Key('trip-fixture')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px and 180% text: empty, form and about have no overflow', (
    tester,
  ) async {
    await launch(tester, MemoryRepository(), width: 320, scale: 1.8);
    expect(tester.takeException(), isNull);
    await reveal(tester, find.byKey(const Key('addTrip')));
    await tester.tap(find.byKey(const Key('addTrip')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await reveal(tester, find.byKey(const Key('saveTrip')));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('О дневнике'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
