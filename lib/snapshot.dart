import 'errors.dart';
import 'trip.dart';

/// Explicit user-reported present, never inferred from historical records.
class CurrentStay {
  final String id;
  final String country;
  final String? countryCode;
  final Day? arrival;
  final Day confirmedOn;
  final Day? notBefore;
  const CurrentStay({
    required this.id,
    required this.country,
    this.countryCode,
    required this.arrival,
    required this.confirmedOn,
    this.notBefore,
  });

  String get countryKey => countryKeyOf(countryCode, country);

  CurrentStay withCode(String? code) => CurrentStay(
    id: id,
    country: country,
    countryCode: code,
    arrival: arrival,
    confirmedOn: confirmedOn,
    notBefore: notBefore,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'country': country,
    'countryCode': countryCode,
    'arrival': arrival?.iso,
    'confirmedOn': confirmedOn.iso,
    'notBefore': notBefore?.iso,
  };

  factory CurrentStay.fromJson(Object? value) {
    final map = objectMap(value);
    return CurrentStay(
      id: requiredString(map, 'id'),
      country: requiredString(map, 'country'),
      countryCode: codeOf(map),
      arrival: optionalDay(map, 'arrival'),
      confirmedOn: Day.parse(requiredString(map, 'confirmedOn')),
      notBefore: optionalDay(map, 'notBefore'),
    );
  }

  Trip? asTrip(Day today) => arrival == null
      ? null
      : Trip(
          id: id,
          country: country,
          countryCode: countryCode,
          arrival: arrival!,
          departure: today,
        );
}

/// A past country with an unknown arrival has no countable interval.
class UndatedStay {
  final String id;
  final String country;
  final String? countryCode;
  final Day departure;
  const UndatedStay({
    required this.id,
    required this.country,
    this.countryCode,
    required this.departure,
  });

  String get countryKey => countryKeyOf(countryCode, country);

  UndatedStay withCode(String? code) => UndatedStay(
    id: id,
    country: country,
    countryCode: code,
    departure: departure,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'country': country,
    'countryCode': countryCode,
    'departure': departure.iso,
  };
  factory UndatedStay.fromJson(Object? value) {
    final map = objectMap(value);
    return UndatedStay(
      id: requiredString(map, 'id'),
      country: requiredString(map, 'country'),
      countryCode: codeOf(map),
      departure: Day.parse(requiredString(map, 'departure')),
    );
  }
}

Map<String, dynamic> objectMap(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Ожидался объект');
  }
  return value;
}

String requiredString(Map<String, dynamic> map, String key) {
  if (map[key] is! String) throw FormatException('Некорректное поле $key');
  return map[key] as String;
}

Day? optionalDay(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) throw FormatException('Отсутствует поле $key');
  return map[key] == null ? null : Day.parse(requiredString(map, key));
}

class JournalSnapshot {
  final List<Trip> trips;
  final String? homeCountry;
  final String? homeCountryCode;
  final CurrentStay? current;
  final List<UndatedStay> undated;

  /// Планы поездок (схема 5): те же поля, что у поездки, даты любые.
  /// Не факты: в днях, итогах, календарных наборах и на карте не
  /// участвуют, пока владелец не подтвердит план как запись.
  final List<Trip> plans;
  JournalSnapshot({
    Iterable<Trip> trips = const [],
    this.homeCountry,
    this.homeCountryCode,
    this.current,
    Iterable<UndatedStay> undated = const [],
    Iterable<Trip> plans = const [],
  }) : trips = List.unmodifiable(trips),
       undated = List.unmodifiable(undated),
       plans = List.unmodifiable(plans);

  bool get needsOnboarding => homeCountry == null;

  /// Коды стран для начала списка выбора страны: определённая сейчас
  /// ([detected]), текущая, домашняя, затем страны последних поездок —
  /// новые сначала. Без повторов, не больше [limit].
  List<String> suggestedCodes({String? detected, int limit = 8}) {
    final codes = <String>[];
    void add(String? code) {
      if (code != null && codes.length < limit && !codes.contains(code)) {
        codes.add(code);
      }
    }

    add(detected);
    add(current?.countryCode);
    add(homeCountryCode);
    final recent = [...trips]
      ..sort((a, b) => b.departure.compareTo(a.departure));
    for (final t in recent) {
      add(t.countryCode);
    }
    return codes;
  }

  /// Ключ домашней страны для сравнения с записями.
  String get homeKey => countryKeyOf(homeCountryCode, homeCountry ?? '');

  /// Новый текст домашней страны без явного кода сбрасывает код: текст
  /// изменился, прежнее сопоставление больше не верно.
  JournalSnapshot copyWith({
    Iterable<Trip>? trips,
    String? homeCountry,
    String? homeCountryCode,
    CurrentStay? current,
    Iterable<UndatedStay>? undated,
    Iterable<Trip>? plans,
  }) => JournalSnapshot(
    trips: trips ?? this.trips,
    homeCountry: homeCountry ?? this.homeCountry,
    homeCountryCode: homeCountry == null
        ? this.homeCountryCode
        : homeCountryCode,
    current: current ?? this.current,
    undated: undated ?? this.undated,
    plans: plans ?? this.plans,
  );

  /// Проставляет коды записям без кода по точному совпадению текста.
  /// Тексты и остальные поля не меняются; на диск попадёт только при
  /// следующем успешном сохранении. Без изменений возвращает тот же объект.
  JournalSnapshot assignCodes(String? Function(String text) match) {
    var changed = false;
    String? codeFor(String? code, String text) {
      if (code != null) return code;
      final found = match(text);
      if (found != null) changed = true;
      return found;
    }

    final next = JournalSnapshot(
      trips: [
        for (final t in trips)
          t.countryCode == null ? t.withCode(codeFor(null, t.country)) : t,
      ],
      homeCountry: homeCountry,
      homeCountryCode: homeCountry == null
          ? null
          : codeFor(homeCountryCode, homeCountry!),
      current: current == null || current!.countryCode != null
          ? current
          : current!.withCode(codeFor(null, current!.country)),
      undated: [
        for (final u in undated)
          u.countryCode == null ? u.withCode(codeFor(null, u.country)) : u,
      ],
      plans: [
        for (final t in plans)
          t.countryCode == null ? t.withCode(codeFor(null, t.country)) : t,
      ],
    );
    return changed ? next : this;
  }

  List<Trip> knownTrips(Day today) => [
    ...trips,
    if (current?.asTrip(today) case final Trip trip) trip,
  ];

  void validate(Day today) {
    final ids = <String>{};
    void identity(String id, String country, String? code) {
      if (id.trim().isEmpty || !ids.add(id)) {
        throw const FormatException('Некорректный или повторный идентификатор');
      }
      validateCountry(country);
      if (!isCountryCode(code)) {
        throw const FormatException('Некорректный код страны');
      }
    }

    for (final trip in trips) {
      identity(trip.id, trip.country, trip.countryCode);
      final error = trip.validate(today);
      if (error != null) throw FormatException('Invalid trip: ${error.name}');
    }
    if ((homeCountry == null) != (current == null)) {
      throw const FormatException('Неполный профиль');
    }
    if (homeCountry != null) validateCountry(homeCountry!);
    if (!isCountryCode(homeCountryCode)) {
      throw const FormatException('Некорректный код домашней страны');
    }
    final stay = current;
    if (stay != null) {
      identity(stay.id, stay.country, stay.countryCode);
      if (stay.confirmedOn.compareTo(today) > 0 ||
          (stay.arrival != null && stay.arrival!.compareTo(today) > 0) ||
          (stay.notBefore != null &&
              (stay.notBefore!.compareTo(stay.confirmedOn) > 0 ||
                  (stay.arrival != null &&
                      stay.arrival!.compareTo(stay.notBefore!) < 0)))) {
        throw const FormatException('Некорректная дата текущего пребывания');
      }
    }
    for (final stay in undated) {
      identity(stay.id, stay.country, stay.countryCode);
      if (stay.departure.compareTo(today) > 0) {
        throw const FormatException('Будущая дата в архиве');
      }
    }
    for (final plan in plans) {
      identity(plan.id, plan.country, plan.countryCode);
      final error = plan.validate(today, plan: true);
      if (error != null) throw FormatException('Invalid plan: ${error.name}');
    }
  }

  /// Схема 5 = схема 4 плюс список plans (планы поездок). Схема 4 = схема
  /// 3 плюс поле kind у поездок (stay | transit). Файл схемы 5 прежние
  /// версии приложения отклоняют, не перезаписывая.
  Map<String, Object?> toJson() => {
    'schemaVersion': 5,
    'trips': trips.map((t) => t.toJson()).toList(),
    'homeCountry': homeCountry,
    'homeCountryCode': homeCountryCode,
    'current': current?.toJson(),
    'undated': undated.map((s) => s.toJson()).toList(),
    'plans': plans.map((t) => t.toJson()).toList(),
  };

  factory JournalSnapshot.fromJson(Object? value, Day today) {
    final map = objectMap(value);
    final version = map['schemaVersion'];
    if (version is! int ||
        version < 1 ||
        version > 5 ||
        map['trips'] is! List) {
      throw const FormatException('Формат дневника не поддерживается');
    }
    final trips = (map['trips'] as List).map((t) => Trip.fromJson(t, today));
    // Планы появились в схеме 5; в 5 список обязателен.
    if (version >= 5 && map['plans'] is! List) {
      throw const FormatException('Неполный снимок дневника');
    }
    final plans = version >= 5
        ? (map['plans'] as List).map((t) => Trip.fromJson(t, today, plan: true))
        : const <Trip>[];
    // Migration never normalizes, sorts, renames or rewrites historical trips.
    final JournalSnapshot snapshot;
    if (version == 1) {
      snapshot = JournalSnapshot(trips: trips);
    } else {
      if (!map.containsKey('homeCountry') ||
          !map.containsKey('current') ||
          map['undated'] is! List) {
        throw const FormatException('Неполный снимок дневника');
      }
      final homeCode = map['homeCountryCode'];
      if (homeCode != null &&
          !(homeCode is String && isCountryCode(homeCode))) {
        throw const FormatException('Некорректное поле homeCountryCode');
      }
      snapshot = JournalSnapshot(
        trips: trips,
        homeCountry: map['homeCountry'] == null
            ? null
            : requiredString(map, 'homeCountry'),
        homeCountryCode: homeCode as String?,
        current: map['current'] == null
            ? null
            : CurrentStay.fromJson(map['current']),
        undated: (map['undated'] as List).map(UndatedStay.fromJson),
        plans: plans,
      );
    }
    snapshot.validate(today);
    return snapshot;
  }

  JournalSnapshot transition(
    String country,
    Day date,
    Day today,
    String id, {
    String? countryCode,
  }) {
    validateCountry(country);
    final previous = current!;
    final earliest = previous.arrival ?? previous.confirmedOn;
    if (countryKeyOf(countryCode, country) == previous.countryKey ||
        normalize(country) == normalize(previous.country)) {
      throw const JournalError(JournalErrorCode.sameCountry);
    }
    if (date.compareTo(earliest) < 0 || date.compareTo(today) > 0) {
      throw JournalError(
        JournalErrorCode.moveDateRange,
        from: earliest,
        to: today,
      );
    }
    final next = copyWith(
      trips: [
        ...trips,
        if (previous.arrival != null)
          Trip(
            id: previous.id,
            country: previous.country,
            countryCode: previous.countryCode,
            arrival: previous.arrival!,
            departure: date,
          ),
      ],
      undated: [
        ...undated,
        if (previous.arrival == null)
          UndatedStay(
            id: previous.id,
            country: previous.country,
            countryCode: previous.countryCode,
            departure: date,
          ),
      ],
      current: CurrentStay(
        id: id,
        country: cleanText(country),
        countryCode: countryCode,
        arrival: date,
        confirmedOn: today,
        notBefore: date,
      ),
    );
    next.validate(today);
    return next;
  }
}

void validateCountry(String value) {
  if (cleanText(value).isEmpty || value.length > 120) {
    throw const JournalError(JournalErrorCode.countryLength);
  }
}

Day dayAt(int ordinal) => Day.fromDateTime(
  DateTime.fromMillisecondsSinceEpoch(
    ordinal * Duration.millisecondsPerDay,
    isUtc: true,
  ),
);

class DateGap {
  final Day start;
  final Day end;
  const DateGap(this.start, this.end);
  int get days => end.ordinal - start.ordinal + 1;
  String get label => '${start.label} — ${end.label}';
}

/// Bounded year sets are at most 366 values each. Border dates intentionally
/// belong to both home and away; known/unknown use their union exactly once.
class YearSummary {
  final int year;
  final Day through;
  final Set<int> home;
  final Set<int> away;
  final Set<int> known;

  /// Дни, на которые приходится хотя бы один транзит (для маркера).
  /// Входят в known и в дни своей страны; отдельно не суммируются.
  final Set<int> transit;
  final List<CountryStat> countries;
  final int total;
  int get unknown => total - known.length;
  int get overlap => home.intersection(away).length;

  YearSummary._(
    this.year,
    this.through,
    this.home,
    this.away,
    this.known,
    this.transit,
    this.countries,
    this.total,
  );

  factory YearSummary(JournalSnapshot snapshot, int year, Day today) {
    if (year < 1900 || year > today.year) {
      throw const JournalError(JournalErrorCode.yearRange);
    }
    final first = Day(year, 1, 1);
    final through = year == today.year ? today : Day(year, 12, 31);
    final groups = <String, Set<int>>{};
    final labels = <String, String>{};
    final codes = <String, String?>{};
    final counts = <String, int>{};
    final transits = <String, int>{};
    final transitDays = <int>{};
    for (final trip in snapshot.knownTrips(today)) {
      final start = trip.arrival.ordinal < first.ordinal
          ? first.ordinal
          : trip.arrival.ordinal;
      final end = trip.departure.ordinal > through.ordinal
          ? through.ordinal
          : trip.departure.ordinal;
      if (start > end) continue;
      final days = groups.putIfAbsent(trip.countryKey, () => <int>{});
      for (var d = start; d <= end; d++) {
        days.add(d);
        if (trip.isTransit) transitDays.add(d);
      }
      labels[trip.countryKey] = cleanText(trip.country);
      codes[trip.countryKey] ??= trip.countryCode;
      counts.update(trip.countryKey, (v) => v + 1, ifAbsent: () => 1);
      if (trip.isTransit) {
        transits.update(trip.countryKey, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final homeKey = snapshot.homeKey;
    final home = groups[homeKey] ?? <int>{};
    final away = <int>{};
    for (final entry in groups.entries) {
      if (entry.key != homeKey) away.addAll(entry.value);
    }
    final countries =
        [
          for (final entry in groups.entries)
            CountryStat(
              entry.key,
              labels[entry.key]!,
              entry.value.length,
              counts[entry.key]!,
              code: codes[entry.key],
              transits: transits[entry.key] ?? 0,
            ),
        ]..sort((a, b) {
          final byDays = b.days.compareTo(a.days);
          return byDays == 0 ? a.key.compareTo(b.key) : byDays;
        });
    return YearSummary._(
      year,
      through,
      home,
      away,
      {...home, ...away},
      transitDays,
      countries,
      through.ordinal - first.ordinal + 1,
    );
  }
}

/// Only gaps *between* known ranges, clipped to the requested year/today.
/// The leading and trailing unknown periods are never suggested as home.
List<DateGap> missingGaps(JournalSnapshot snapshot, int year, Day today) {
  final summary = YearSummary(snapshot, year, today);
  final ranges =
      snapshot
          .knownTrips(today)
          .map((t) => (t.arrival.ordinal, t.departure.ordinal))
          .toList()
        ..sort((a, b) => a.$1.compareTo(b.$1));
  final gaps = <DateGap>[];
  int? end;
  for (final range in ranges) {
    if (end != null && range.$1 > end + 1) {
      final start = (end + 1).clamp(Day(year, 1, 1).ordinal, 99999999);
      final last = (range.$1 - 1).clamp(-99999999, summary.through.ordinal);
      if (start <= last) gaps.add(DateGap(dayAt(start), dayAt(last)));
    }
    if (end == null || range.$2 > end) end = range.$2;
  }
  return gaps;
}

/// A preview token captures both state identity and calendar day. Confirmation
/// cannot silently apply a different proposal after edits or midnight.
class HomeFillPreview {
  final JournalSnapshot source;
  final int year;
  final Day today;
  final List<DateGap> gaps;
  HomeFillPreview(this.source, this.year, this.today)
    : gaps = List.unmodifiable(missingGaps(source, year, today));
  int get days => gaps.fold(0, (sum, gap) => sum + gap.days);

  /// [note] — текст заметки на языке интерфейса; он сохраняется в записи.
  JournalSnapshot confirm(
    JournalSnapshot latest,
    Day now,
    String Function() newId, {
    required String note,
  }) {
    if (!identical(source, latest) || now != today) {
      throw const JournalError(JournalErrorCode.previewStale);
    }
    if (source.homeCountry == null) {
      throw const JournalError(JournalErrorCode.homeCountryFirst);
    }
    return source.copyWith(
      trips: [
        ...source.trips,
        for (final gap in gaps)
          Trip(
            id: newId(),
            country: source.homeCountry!,
            countryCode: source.homeCountryCode,
            arrival: gap.start,
            departure: gap.end,
            note: note,
          ),
      ],
    );
  }
}

/// Событие календарного дня для карточки дня: запись журнала или текущее
/// пребывание, покрывающее дату. Только просмотр, ничего не пишет.
class DayEvent {
  final String id;
  final String country;
  final String? countryCode;
  final String city;
  final TripKind kind;
  final Day start;

  /// null — текущее пребывание, конца нет.
  final Day? end;
  final bool isCurrent;
  const DayEvent({
    required this.id,
    required this.country,
    required this.countryCode,
    required this.city,
    required this.kind,
    required this.start,
    required this.end,
    required this.isCurrent,
  });
}

/// Все записи на [day]: завершённые поездки и транзиты, чьи даты включают
/// день, плюс текущее пребывание, если приезд известен и день не позже
/// сегодня. Неполный архив без даты приезда не распределяется по дням;
/// будущие дни пусты. Порядок: по началу, транзиты после пребываний.
List<DayEvent> eventsOn(JournalSnapshot snapshot, Day day, Day today) {
  if (day.compareTo(today) > 0) return const [];
  final o = day.ordinal;
  final events = <DayEvent>[
    for (final t in snapshot.trips)
      if (t.arrival.ordinal <= o && o <= t.departure.ordinal)
        DayEvent(
          id: t.id,
          country: t.country,
          countryCode: t.countryCode,
          city: t.city,
          kind: t.kind,
          start: t.arrival,
          end: t.departure,
          isCurrent: false,
        ),
    if (snapshot.current case final stay?)
      if (stay.arrival != null && stay.arrival!.ordinal <= o)
        DayEvent(
          id: stay.id,
          country: stay.country,
          countryCode: stay.countryCode,
          city: '',
          kind: TripKind.stay,
          start: stay.arrival!,
          end: null,
          isCurrent: true,
        ),
  ];
  events.sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    if (byStart != 0) return byStart;
    final byKind = a.kind.index.compareTo(b.kind.index);
    return byKind != 0 ? byKind : a.id.compareTo(b.id);
  });
  return events;
}

/// Непрерывная серия дней в текущей стране, считая назад от сегодня через
/// все записи журнала (пребывания и транзиты той же страны). Возврат в ту
/// же страну после короткой отлучки не обнуляет счётчик: дни берутся из
/// истории, ничего не переписывается. Неизвестный день прерывает серию.
/// null — дата приезда текущего пребывания неизвестна.
({Day start, int days})? continuousStay(JournalSnapshot snapshot, Day today) {
  final stay = snapshot.current;
  if (stay == null || stay.arrival == null) return null;
  final key = stay.countryKey;
  final covered = <int>{};
  for (var d = stay.arrival!.ordinal; d <= today.ordinal; d++) {
    covered.add(d);
  }
  for (final t in snapshot.trips) {
    if (t.countryKey != key) continue;
    for (var d = t.arrival.ordinal; d <= t.departure.ordinal; d++) {
      if (d <= today.ordinal) covered.add(d);
    }
  }
  var cursor = today.ordinal;
  while (covered.contains(cursor - 1)) {
    cursor--;
  }
  return (start: dayAt(cursor), days: today.ordinal - cursor + 1);
}
