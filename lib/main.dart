import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'background.dart';
import 'backup.dart';
import 'timeline_import.dart';
import 'borders.dart';
import 'countries.dart';
import 'country_field.dart';
import 'detect.dart';
import 'locator.dart';
import 'on_this_day.dart';
import 'overlap.dart';
import 'overlap_dialog.dart';
import 'errors.dart';
import 'flag.dart';
import 'format.dart';
import 'globe.dart';
import 'l10n/app_localizations.dart';
import 'repository.dart';
import 'settings.dart';
import 'share.dart';
import 'trip.dart';
import 'snapshot.dart';
import 'journal_controller.dart';
import 'theme.dart';
import 'world_map.dart';
import 'year_calendar.dart';

part 'dashboard.dart';
part 'import_page.dart';
part 'map_page.dart';
part 'year_review.dart';

/// Код версии из pubspec (versionCode): поднимать вместе с версией.
const appVersionCode = 44;
const appVersion = '$appVersionShort ($appVersionCode)';
const appVersionShort = '1.0.1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Справочник стран — офлайн-ассет; без него приложение работает,
  // но коды не назначаются.
  CountryDirectory directory;
  try {
    directory = await CountryDirectory.load();
  } catch (_) {
    directory = CountryDirectory.empty;
  }
  CountryBorders borders;
  try {
    borders = await CountryBorders.load();
  } catch (_) {
    borders = CountryBorders.empty;
  }
  // Фоновые проверки и уведомления: инициализация не запускает ничего —
  // задачи заводятся только переключателем в настройках.
  final reviewRequests = ValueNotifier<int>(0);
  final notifier = LocalNotifier();
  try {
    await WorkmanagerService.initialize();
    await notifier.initialize(onTap: (_) => reviewRequests.value++);
    if (await notifier.launchedFromNotification()) reviewRequests.value++;
  } catch (_) {
    // Без плагинов (например, на не-Android) фон недоступен, остальное работает.
  }
  runApp(
    DomidayApp(
      repository: JsonTripRepository(),
      settings: JsonSettingsRepository(),
      directory: directory,
      borders: borders,
      location: const GeolocatorSource(),
      background: const WorkmanagerService(),
      reviewRequests: reviewRequests,
      backup: const FilePickerStore(),
      share: const ChannelShareService(),
    ),
  );
}

/// Доступ к системным диалогам резервной копии из настроек.
class BackupScope extends InheritedWidget {
  final BackupStore? store;
  const BackupScope({super.key, required this.store, required super.child});
  static BackupStore? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BackupScope>()?.store;
  @override
  bool updateShouldNotify(BackupScope old) => old.store != store;
}

/// Доступ к системному «Поделиться» (null — кнопка скрыта).
class ShareScope extends InheritedWidget {
  final ShareService? service;
  const ShareScope({super.key, required this.service, required super.child});
  static ShareService? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShareScope>()?.service;
  @override
  bool updateShouldNotify(ShareScope old) => old.service != service;
}

/// Доступ к фоновому сервису из настроек.
class BackgroundScope extends InheritedWidget {
  final BackgroundService? service;
  const BackgroundScope({
    super.key,
    required this.service,
    required super.child,
  });
  static BackgroundService? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BackgroundScope>()?.service;
  @override
  bool updateShouldNotify(BackgroundScope old) => old.service != service;
}

class DomidayApp extends StatefulWidget {
  final TripRepository repository;
  final SettingsRepository? settings;
  final CountryDirectory? directory;
  final CountryBorders? borders;
  final LocationSource? location;
  final Day Function()? today;

  /// Часы для правила «не чаще раза в час» (в тестах подменяются).
  final DateTime Function()? now;

  /// Фоновые проверки (null — недоступны) и запросы «открыть экран
  /// подтверждения» по нажатию на уведомление.
  final BackgroundService? background;
  final ValueNotifier<int>? reviewRequests;

  /// Резервная копия (null — недоступна, раздел в настройках скрыт).
  final BackupStore? backup;

  /// «Поделиться итогами года» (null — кнопка скрыта).
  final ShareService? share;
  const DomidayApp({
    super.key,
    required this.repository,
    this.settings,
    this.directory,
    this.borders,
    this.location,
    this.today,
    this.now,
    this.background,
    this.reviewRequests,
    this.backup,
    this.share,
  });

  @override
  State<DomidayApp> createState() => _DomidayAppState();
}

class _DomidayAppState extends State<DomidayApp> {
  late final SettingsController _settings;

  @override
  void initState() {
    super.initState();
    _settings = SettingsController(
      widget.settings ?? MemorySettingsRepository(),
    );
    _settings.load();
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CountryScope(
    directory: widget.directory ?? CountryDirectory.empty,
    child: BackgroundScope(
      service: widget.background,
      child: BackupScope(
        store: widget.backup,
        child: ShareScope(
          service: widget.share,
          child: ImportScope(
            borders: widget.borders,
            child: SettingsScope(
              controller: _settings,
              child: ListenableBuilder(
                listenable: _settings,
                builder: (context, _) => MaterialApp(
                  title: 'Domiday',
                  debugShowCheckedModeBanner: false,
                  // null — язык системы; неподдерживаемый язык даёт первый из списка.
                  locale: _settings.settings.locale,
                  supportedLocales: AppSettings.supported,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: domidayTheme(Brightness.light),
                  darkTheme: domidayTheme(Brightness.dark),
                  themeMode: _settings.settings.themeMode,
                  home: HomePage(
                    repository: widget.repository,
                    directory: widget.directory ?? CountryDirectory.empty,
                    borders: widget.borders ?? CountryBorders.empty,
                    location: widget.location,
                    today:
                        widget.today ??
                        (() => Day.fromDateTime(DateTime.now())),
                    now: widget.now ?? DateTime.now,
                    reviewRequests: widget.reviewRequests,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class JournalPage extends StatefulWidget {
  final JournalController controller;
  final String? initialCountry;
  final int? initialYear;
  Day Function() get today => controller.today;
  const JournalPage({
    super.key,
    required this.controller,
    this.initialCountry,
    this.initialYear,
  });

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Trip> get _trips =>
      widget.controller.snapshot.knownTrips(widget.today());
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String? _country;
  int? _year;

  @override
  void initState() {
    super.initState();
    _country = widget.initialCountry;
    _year = widget.initialYear;
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _reset() => setState(() {
    _search.clear();
    _country = null;
    _year = null;
  });

  Future<void> _editPlan(Trip plan) =>
      openPlanEditor(context, widget.controller, plan: plan);

  Future<void> _edit([Trip? original]) async {
    if (original?.id == widget.controller.snapshot.current?.id &&
        original != null) {
      await _openStatus(context, widget.controller, StatusMode.date);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TripEditor(
          trip: original,
          today: widget.today,
          snapshot: () => widget.controller.snapshot,
          onSave: widget.controller.commit,
          onDelete: original == null
              ? null
              : () async {
                  final next = widget.controller.snapshot.trips
                      .where((trip) => trip.id != original.id)
                      .toList();
                  await widget.controller.commit(
                    widget.controller.snapshot.copyWith(trips: next),
                  );
                  if (mounted) {
                    setState(() {
                      if (!_trips.any((t) => t.countryKey == _country)) {
                        _country = null;
                      }
                      if (_year != null &&
                          !_trips.any(
                            (t) =>
                                t.arrival.year <= _year! &&
                                t.departure.year >= _year!,
                          )) {
                        _year = null;
                      }
                    });
                  }
                },
        ),
      ),
    );
  }

  Future<void> _chooseFilter({required bool countries}) async {
    final stats = countryStats(selectTrips(_trips));
    final years = <int>{};
    for (final trip in _trips) {
      for (int y = trip.arrival.year; y <= trip.departure.year; y++) {
        years.add(y);
      }
    }
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  countries
                      ? context.l10n.chooseCountry
                      : context.l10n.chooseYear,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(
                        countries
                            ? context.l10n.allCountries
                            : context.l10n.allYears,
                      ),
                      selected: countries ? _country == null : _year == null,
                      onTap: () {
                        setState(() {
                          if (countries) {
                            _country = null;
                          } else {
                            _year = null;
                          }
                        });
                        Navigator.pop(sheetContext);
                      },
                    ),
                    if (countries)
                      for (final stat in stats)
                        ListTile(
                          title: Text(
                            countryName(context, stat.code, stat.label),
                          ),
                          selected: _country == stat.key,
                          onTap: () {
                            setState(() => _country = stat.key);
                            Navigator.pop(sheetContext);
                          },
                        )
                    else
                      for (final year in sortedYears)
                        ListTile(
                          title: Text('$year'),
                          selected: _year == year,
                          onTap: () {
                            setState(() => _year = year);
                            Navigator.pop(sheetContext);
                          },
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Группы по году отъезда, новые сверху; внутри — порядок списка.
  static List<(int, List<Trip>)> _byYear(List<Trip> trips) {
    final map = <int, List<Trip>>{};
    for (final t in trips) {
      map.putIfAbsent(t.departure.year, () => []).add(t);
    }
    final years = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final y in years) (y, map[y]!)];
  }

  @override
  Widget build(BuildContext context) {
    final directory = CountryScope.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final today = widget.today();
    final plans = selectTrips(
      widget.controller.snapshot.plans,
      query: _search.text,
      country: _country,
      year: _year,
      spellings: (code) => directory[code]?.spellings ?? const [],
    )..sort((a, b) => a.arrival.compareTo(b.arrival));
    final selected = selectTrips(
      _trips,
      query: _search.text,
      country: _country,
      year: _year,
      spellings: (code) => directory[code]?.spellings ?? const [],
    );
    final filtered =
        _country != null || _year != null || _search.text.isNotEmpty;
    final stats = countryStats(selected, year: _year);
    final allStats = countryStats(selectTrips(_trips));
    final countryLabel = allStats
        .where((s) => s.key == _country)
        .map((s) => countryName(context, s.code, s.label))
        .firstOrNull;
    final l10n = context.l10n;
    return Scaffold(
      floatingActionButton: _trips.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('addTrip'),
              onPressed: () => _edit(),
              backgroundColor: kYellow,
              foregroundColor: kCharcoal,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addTrip),
            ),
      appBar: AppBar(
        title: const AppTitle(),
        actions: [
          IconButton(
            tooltip: l10n.aboutTooltip,
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
            icon: const Icon(Icons.info_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              // Снизу — место под плавающую кнопку.
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                _trips.isEmpty ? 32 : 96,
              ),
              children: [
                Text(
                  l10n.journalTitle,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(l10n.journalSubtitle),
                const SizedBox(height: 24),
                if (_trips.isEmpty && plans.isEmpty)
                  _emptyState()
                else ...[
                  // Прошлых поездок ещё нет (только текущее пребывание) —
                  // историю можно взять из Google Maps.
                  if (widget.controller.snapshot.trips.isEmpty &&
                      BackupScope.of(context) != null &&
                      ImportScope.of(context) != null) ...[
                    OutlinedButton.icon(
                      key: const Key('journalImport'),
                      onPressed: () =>
                          startTimelineImport(context, widget.controller),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l10n.importTitle),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Поиск с подсказками стран, как поле страны в редакторе
                  // поездки: выбор подсказки ставит фильтр по стране.
                  RawAutocomplete<Country>(
                    textEditingController: _search,
                    focusNode: _searchFocus,
                    displayStringForOption: (c) => c.name(language),
                    optionsBuilder: (value) {
                      if (value.text.trim().isEmpty) {
                        return const Iterable<Country>.empty();
                      }
                      final present = {
                        for (final s in allStats)
                          if (s.code != null) s.code!,
                      };
                      return directory
                          .search(value.text, language)
                          .where((c) => present.contains(c.code))
                          .take(8);
                    },
                    onSelected: (c) {
                      final key = allStats
                          .where((s) => s.code == c.code)
                          .map((s) => s.key)
                          .firstOrNull;
                      setState(() {
                        _country = key;
                        _search.clear();
                      });
                      _searchFocus.unfocus();
                    },
                    fieldViewBuilder: (context, controller, focusNode, _) =>
                        TextField(
                          key: const Key('search'),
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: l10n.searchLabel,
                            hintText: l10n.searchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: controller.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l10n.clearSearch,
                                    onPressed: () =>
                                        setState(controller.clear),
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                    optionsViewBuilder: (context, onSelected, options) =>
                        Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: SizedBox(
                              width: (MediaQuery.sizeOf(context).width - 40)
                                  .clamp(0.0, 680.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 280,
                                ),
                                child: ListView(
                                  key: const Key('journalSuggestions'),
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  children: [
                                    for (final c in options)
                                      ListTile(
                                        key: Key('journalSuggest-${c.code}'),
                                        dense: true,
                                        leading: CountryFlag(
                                          code: c.code,
                                          width: 24,
                                        ),
                                        title: Text(c.name(language)),
                                        onTap: () => onSelected(c),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width - 40,
                        ),
                        child: ActionChip(
                          avatar: const Icon(Icons.public, size: 18),
                          label: Text(
                            countryLabel ?? l10n.allCountries,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => _chooseFilter(countries: true),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_year?.toString() ?? l10n.allYears),
                        onPressed: () => _chooseFilter(countries: false),
                      ),
                      if (filtered)
                        ActionChip(label: Text(l10n.reset), onPressed: _reset),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Summary(
                    trips: selected.length,
                    countries: stats.length,
                    days: unionDays(selected, year: _year),
                    filtered: filtered,
                    year: _year,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    filtered
                        ? l10n.foundTrips(selected.length)
                        : l10n.tripHistory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  if (selected.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.noSuchRecords),
                            const SizedBox(height: 8),
                            Text(l10n.tryAnotherWord),
                            TextButton(
                              onPressed: _reset,
                              child: Text(l10n.resetFilters),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Планы — сверху, по дате приезда; не факты.
                  if (plans.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Text(
                        l10n.plansSection,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Card(
                      key: const Key('plansSection'),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < plans.length; i++)
                            PlanRow(
                              plan: plans[i],
                              today: today,
                              divider: i > 0,
                              onTap: () => _editPlan(plans[i]),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Компактные строки по годам: флаг, страна · город, даты,
                  // справа дни. Текущее пребывание — строкой «— сейчас».
                  for (final group in _byYear(selected)) ...[
                    _YearHead(
                      year: group.$1,
                      meta:
                          '${l10n.recordsCount(group.$2.length)} · '
                          '${l10n.daysFull(unionDays(group.$2, year: group.$1))}',
                    ),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < group.$2.length; i++)
                            _TripRow(
                              trip: group.$2[i],
                              current:
                                  group.$2[i].id ==
                                  widget.controller.snapshot.current?.id,
                              divider: i > 0,
                              onTap: () => _edit(group.$2[i]),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.byCountry,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      filtered ? l10n.bySelectedTrips : l10n.byYourRecordsOnly,
                    ),
                    const SizedBox(height: 12),
                    // Те же строки, что на дашборде; нажатие ставит фильтр.
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < stats.length; i++)
                            _CountryRow(
                              stat: stats[i],
                              isHome:
                                  stats[i].key ==
                                  widget.controller.snapshot.homeKey,
                              share: unionDays(selected, year: _year) == 0
                                  ? 0
                                  : stats[i].days /
                                        unionDays(selected, year: _year),
                              divider: i > 0,
                              onTap: () =>
                                  setState(() => _country = stats[i].key),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.moveDayNotVisa,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
                if (widget.controller.snapshot.current
                    case final CurrentStay stay)
                  if (stay.arrival == null &&
                      (_country == null ||
                          _country == normalize(stay.country)) &&
                      normalize(stay.country).contains(normalize(_search.text)))
                    _CurrentCard(
                      stay: stay,
                      today: widget.today(),
                      onDate: () => _openStatus(
                        context,
                        widget.controller,
                        StatusMode.date,
                      ),
                    ),
                for (final stay in widget.controller.snapshot.undated)
                  if ((_country == null ||
                          _country == normalize(stay.country)) &&
                      normalize('${stay.country} ${stay.departure.label}')
                          .contains(normalize(_search.text)))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _UndatedCard(
                        stay: stay,
                        controller: widget.controller,
                      ),
                    ),
                const SizedBox(height: 28),
                Text(
                  l10n.journalFooter(appVersionShort),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.luggage_outlined, size: 40),
          const SizedBox(height: 20),
          Text(
            context.l10n.emptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.emptyBody),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('addTrip'),
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.addTrip),
          ),
          if (BackupScope.of(context) != null &&
              ImportScope.of(context) != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('journalEmptyImport'),
              onPressed: () => startTimelineImport(context, widget.controller),
              icon: const Icon(Icons.map_outlined),
              label: Text(context.l10n.importTitle),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            context.l10n.emptyNote,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        ],
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  final int trips;
  final int countries;
  final int days;
  final bool filtered;
  final int? year;
  const _Summary({
    required this.trips,
    required this.countries,
    required this.days,
    required this.filtered,
    this.year,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DomidayColors.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.hero,
        borderRadius: BorderRadius.circular(kRadiusHero),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Roboto',
          color: colors.heroInk,
          fontSize: 16,
          height: 1.4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(filtered ? l10n.bySelectedTrips : l10n.yourJournalInNumbers),
            const SizedBox(height: 16),
            Text(
              '$days',
              style: display(size: 48, color: kYellow, height: 1.1),
            ),
            const SizedBox(height: 6),
            Text(l10n.daysInRecordedTrips),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                Text(l10n.tripsCount(trips)),
                Text(l10n.countriesCount(countries)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.bothDatesIncluded}'
              '${year == null ? '' : ' ${l10n.daysOnlyInYear(year!)}'}',
              style: TextStyle(fontSize: 14, color: colors.heroMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок группы года в журнале: год и «N записей · M дней».
class _YearHead extends StatelessWidget {
  final int year;
  final String meta;
  const _YearHead({required this.year, required this.meta});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$year', style: display(size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            meta,
            style: TextStyle(
              fontSize: 13.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Строка поездки: флаг, страна · город, даты; справа дни.
class _TripRow extends StatelessWidget {
  final Trip trip;
  final bool current;
  final bool divider;
  final VoidCallback onTap;
  const _TripRow({
    required this.trip,
    required this.current,
    required this.divider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final muted = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);
    final compact = isCompact(context);
    // Однодневная запись — одна дата, а не «19.06 — 19.06».
    final dates = current
        ? '${trip.arrival.text(context)} — ${l10n.journalNow}'
        : trip.arrival == trip.departure
        ? trip.arrival.text(context)
        : '${trip.arrival.text(context)} — ${trip.departure.text(context)}';
    return InkWell(
      key: Key('trip-${trip.id}'),
      onTap: onTap,
      child: Container(
        decoration: divider
            ? BoxDecoration(
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant, width: 1),
                ),
              )
            : null,
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            if (trip.countryCode != null) ...[
              CountryFlag(code: trip.countryCode, width: 30),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: countryName(
                              context,
                              trip.countryCode,
                              trip.country,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            children: [
                              if (trip.city.isNotEmpty)
                                TextSpan(
                                  text: ' · ${trip.city}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trip.isTransit) ...[
                        const SizedBox(width: 8),
                        _KindChip(kind: trip.kind),
                      ],
                    ],
                  ),
                  Text(
                    compact ? '$dates · ${l10n.daysCompact(trip.days)}' : dates,
                    style: muted,
                  ),
                  if (trip.note.isNotEmpty)
                    Text(
                      trip.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 12),
              Text(
                l10n.daysCompact(trip.days),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок шапки: знак Domiday и название.
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const DomidayLogo(size: 30),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          'Domiday',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: display(size: 22, letterSpacing: -0.6),
        ),
      ),
    ],
  );
}

/// Подпись типа записи: только для транзита, пребывание — по умолчанию.
class _KindChip extends StatelessWidget {
  final TripKind kind;
  const _KindChip({required this.kind});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        kind == TripKind.transit
            ? context.l10n.kindTransit
            : context.l10n.kindStay,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class TripEditor extends StatefulWidget {
  final Trip? trip;

  /// Черновик для новой записи (предзаполнение из определения страны);
  /// запись считается новой, id выдаётся при сохранении.
  final Trip? draft;
  final Day Function() today;

  /// Дневник на момент сохранения: по нему ищутся пересечения дат.
  final JournalSnapshot Function() snapshot;

  /// Получает готовый снимок: запись добавлена или заменена по id, а при
  /// подтверждённом «Заменить» задетые записи уже обрезаны.
  final Future<void> Function(JournalSnapshot next) onSave;
  final Future<void> Function()? onDelete;

  /// План поездки: даты любые, в дни и итоги не попадает. Для новой
  /// записи переключатель «Поездка / План» показывается в форме.
  final bool plan;
  const TripEditor({
    super.key,
    this.trip,
    this.draft,
    required this.today,
    required this.snapshot,
    required this.onSave,
    this.onDelete,
    this.plan = false,
  });

  @override
  State<TripEditor> createState() => _TripEditorState();
}

class _TripEditorState extends State<TripEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _note;
  final _countryFocus = FocusNode();
  late final String _id;
  Day? _arrival;
  Day? _departure;
  TripKind _kind = TripKind.stay;
  late bool _plan = widget.plan;
  bool _busy = false;
  bool _dirty = false;
  bool _allowPop = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final seed = widget.trip ?? widget.draft;
    _country = TextEditingController(text: seed?.country ?? '');
    _city = TextEditingController(text: seed?.city ?? '');
    _note = TextEditingController(text: seed?.note ?? '');
    _arrival = seed?.arrival;
    _departure = seed?.departure;
    _kind = seed?.kind ?? TripKind.stay;
    _dirty = widget.draft != null;
    _id = widget.trip?.id ?? _newId();
    for (final controller in [_country, _city, _note]) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() => _dirty = true;

  @override
  void dispose() {
    _country.dispose();
    _city.dispose();
    _note.dispose();
    _countryFocus.dispose();
    super.dispose();
  }

  /// Обе даты одним выбором: диапазон в календаре (день приезда — день
  /// отъезда), для однодневной записи — один и тот же день дважды.
  Future<void> _pickRange() async {
    FocusScope.of(context).unfocus();
    final today = widget.today();
    final l10n = context.l10n;
    final start = _arrival;
    final end = _departure ?? _arrival;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: start == null
          ? null
          : DateTimeRange(start: start.localDate, end: end!.localDate),
      currentDate: today.localDate,
      firstDate: DateTime(1900),
      // План можно ставить на будущее.
      lastDate: _plan ? DateTime(today.year + 5, 12, 31) : today.localDate,
      helpText: l10n.pickerDates,
      cancelText: l10n.cancel,
      confirmText: l10n.choose,
      saveText: l10n.choose,
      fieldStartLabelText: l10n.pickerArrival,
      fieldEndLabelText: l10n.pickerDeparture,
    );
    if (picked != null && mounted) {
      _setDates(Day.fromDateTime(picked.start), Day.fromDateTime(picked.end));
    }
  }

  void _setDates(Day arrival, Day departure) => setState(() {
    _arrival = arrival;
    _departure = departure;
    _dirty = true;
    _error = null;
  });

  /// Быстрые кнопки: сегодня, вчера, один день (отъезд = приезд).
  Widget _quickChip(Key key, String label, VoidCallback onTap) =>
      ActionChip(key: key, label: Text(label), onPressed: _busy ? null : onTap);

  Future<void> _finish(String message) async {
    setState(() {
      _allowPop = true;
      _busy = false;
    });
    // PopScope must rebuild with canPop=true before Navigator.pop.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    if (_arrival == null || _departure == null) {
      setState(() => _error = context.l10n.errorPickBothDates);
      return;
    }
    final trip = Trip(
      id: _id,
      country: cleanText(_country.text),
      countryCode: CountryScope.of(context).match(_country.text),
      city: cleanText(_city.text),
      note: _note.text.trim(),
      arrival: _arrival!,
      departure: _departure!,
      kind: _kind,
    );
    final error = trip.validate(widget.today(), plan: _plan);
    if (error != null) {
      setState(() => _error = describeError(context, JournalError(error)));
      return;
    }
    final snapshot = widget.snapshot();
    if (_plan) {
      // План — не факт: без проверки пересечений, отдельным списком.
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        await widget.onSave(
          snapshot.copyWith(
            plans: [...snapshot.plans.where((p) => p.id != _id), trip],
          ),
        );
        if (mounted) await _finish(context.l10n.tripSaved);
      } catch (_) {
        if (mounted) {
          setState(() {
            _busy = false;
            _error = context.l10n.tripSaveFailed;
          });
        }
      }
      return;
    }
    // Занятые дни: предупреждение с точным списком того, что изменится.
    // Без выбора владельца ничего не записывается.
    final plan = planOverlap(snapshot, trip, widget.today(), newId: _newId);
    var replace = false;
    if (!plan.isEmpty) {
      final choice = await showOverlapDialog(context, plan);
      if (choice == null || !mounted) return;
      replace = choice;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(applyOverlap(snapshot, plan, replace: replace));
      if (mounted) await _finish(context.l10n.tripSaved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.l10n.tripSaveFailed;
        });
      }
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.deleteTripTitle),
        content: Text(
          '${countryName(context, widget.trip!.countryCode, widget.trip!.country)}\n'
          '${widget.trip!.arrival.text(context)} — ${widget.trip!.departure.text(context)}\n\n'
          '${l10n.deleteTripBody}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete!();
      if (mounted) await _finish(context.l10n.tripDeleted);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.l10n.tripDeleteFailed;
        });
      }
    }
  }

  Future<void> _back() async {
    if (_busy || _allowPop) return;
    if (_dirty) {
      final l10n = context.l10n;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(l10n.leaveWithoutSaving),
          content: Text(l10n.unsavedChanges),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.stay),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.leave),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.back,
            onPressed: _busy ? null : _back,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            _plan
                ? (widget.trip == null ? l10n.planNew : l10n.planYour)
                : _kind == TripKind.transit
                ? (widget.trip == null ? l10n.newTransit : l10n.yourTransit)
                : (widget.trip == null ? l10n.newTrip : l10n.yourTrip),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    if (widget.trip == null) ...[
                      // Новая запись: факт или план.
                      Wrap(
                        key: const Key('planMode'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (plan, label) in [
                            (false, l10n.planTripToggle),
                            (true, l10n.planToggle),
                          ])
                            ChoiceChip(
                              key: Key(plan ? 'modePlan' : 'modeTrip'),
                              label: Text(label),
                              selected: _plan == plan,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() {
                                      _plan = plan;
                                      _dirty = true;
                                    }),
                            ),
                        ],
                      ),
                      if (_plan) ...[
                        const SizedBox(height: 8),
                        Text(l10n.planHint, style: const TextStyle(fontSize: 14)),
                      ],
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      key: const Key('tripKind'),
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (kind, label) in [
                          (TripKind.stay, l10n.kindStay),
                          (TripKind.transit, l10n.kindTransit),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _kind == kind,
                            onSelected: _busy
                                ? null
                                : (_) => setState(() {
                                    _kind = kind;
                                    _dirty = true;
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _kind == TripKind.transit
                          ? l10n.transitFormIntro
                          : l10n.tripFormIntro,
                    ),
                    const SizedBox(height: 24),
                    CountryField(
                      controller: _country,
                      focusNode: _countryFocus,
                      suggested: widget.snapshot().suggestedCodes(),
                      fieldKey: const Key('country'),
                      label: l10n.countryFieldLabel,
                      helperText: l10n.countryFieldHelper,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('city'),
                      controller: _city,
                      enabled: !_busy,
                      maxLength: 160,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: l10n.cityLabel),
                    ),
                    const SizedBox(height: 12),
                    _dateButton(
                      key: const Key('dates'),
                      label: l10n.datesFieldLabel,
                      value: _arrival == null
                          ? null
                          : _departure == null || _arrival == _departure
                          ? _arrival!.text(context)
                          : '${_arrival!.text(context)} — '
                                '${_departure!.text(context)}',
                      onTap: _pickRange,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _quickChip(
                          const Key('quickToday'),
                          l10n.quickToday,
                          () => _setDates(widget.today(), widget.today()),
                        ),
                        _quickChip(
                          const Key('quickYesterday'),
                          l10n.quickYesterday,
                          () {
                            final y = Day.fromDateTime(
                              widget.today().localDate.subtract(
                                const Duration(days: 1),
                              ),
                            );
                            _setDates(y, y);
                          },
                        ),
                        _quickChip(
                          const Key('quickOneDay'),
                          l10n.quickOneDay,
                          () => _setDates(
                            _arrival ?? widget.today(),
                            _arrival ?? widget.today(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const Key('note'),
                      controller: _note,
                      enabled: !_busy,
                      maxLength: 4000,
                      minLines: 3,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.noteLabel,
                        hintText: l10n.noteHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          key: const Key('formError'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      key: const Key('saveTrip'),
                      onPressed: _busy ? null : _save,
                      child: Text(
                        _busy
                            ? l10n.saving
                            : _plan
                            ? l10n.savePlan
                            : l10n.saveTrip,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.localOnlyNoBackup,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (widget.onDelete != null) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        key: const Key('deleteTrip'),
                        onPressed: _busy ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(_plan ? l10n.deletePlan : l10n.deleteTrip),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateButton({
    required Key key,
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) => OutlinedButton(
    key: key,
    onPressed: _busy ? null : onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(18),
      alignment: Alignment.centerLeft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.calendar_month_outlined),
        Text(
          '$label  ${value ?? context.l10n.chooseDate}',
          style: const TextStyle(fontSize: 17),
        ),
      ],
    ),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const email = 'info@domiday.com';
  static const site = 'https://www.domiday.com';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final share = ShareScope.of(context);
    final muted = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);
    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7, right: 10),
            child: Icon(Icons.circle, size: 6),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
    Future<void> open(String url) async {
      final ok = await share?.openUrl(url) ?? false;
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.aboutOpenFailed(url))));
      }
    }

    return Scaffold(
      key: const Key('aboutPage'),
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    const DomidayLogo(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Domiday', style: display(size: 28, height: 1.1)),
                          Text(
                            l10n.aboutVersion(appVersion),
                            key: const Key('aboutVersion'),
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.aboutTagline, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 28),
                _section(context, l10n.aboutPlaceTitle, l10n.aboutPlaceBody),
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aboutFeaturesTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      for (final f in [
                        l10n.aboutFeatCalendar,
                        l10n.aboutFeatMap,
                        l10n.aboutFeatJournal,
                        l10n.aboutFeatPlans,
                        l10n.aboutFeatReview,
                        l10n.aboutFeatOnThisDay,
                        l10n.aboutFeatImport,
                        l10n.aboutFeatDetect,
                        l10n.aboutFeatBackup,
                      ])
                        bullet(f),
                    ],
                  ),
                ),
                _section(context, l10n.aboutDetectTitle, l10n.aboutDetectBody),
                _section(context, l10n.aboutDeviceTitle, l10n.aboutDeviceBody),
                _section(context, l10n.aboutUnknownTitle, l10n.aboutUnknownBody),
                _section(context, l10n.aboutCountingTitle, l10n.aboutCountingBody),
                _section(context, l10n.aboutNotVisaTitle, l10n.aboutNotVisaBody),
                Text(
                  l10n.aboutContactTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        key: const Key('aboutEmail'),
                        leading: const Icon(Icons.mail_outline_rounded),
                        title: Text(l10n.aboutContactEmail),
                        subtitle: const Text(email),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => open('mailto:$email'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: const Key('aboutSite'),
                        leading: const Icon(Icons.language_rounded),
                        title: Text(l10n.aboutContactSite),
                        subtitle: const Text('www.domiday.com'),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => open(site),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.aboutContactNote, style: muted),
                const SizedBox(height: 28),
                _section(context, l10n.aboutCreditsTitle, l10n.aboutCreditsBody),
                Text(l10n.aboutCopyright, style: muted),
                const SizedBox(height: 4),
                Text(l10n.aboutNoWarranty, style: muted),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(body),
      ],
    ),
  );
}
