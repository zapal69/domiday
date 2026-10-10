import 'errors.dart';

/// A calendar date, deliberately independent of time zones and daylight saving.
class Day implements Comparable<Day> {
  final int year;
  final int month;
  final int day;

  Day(this.year, this.month, this.day) {
    final checked = DateTime.utc(year, month, day);
    if (year < 1900 ||
        year > 9999 ||
        checked.year != year ||
        checked.month != month ||
        checked.day != day) {
      throw const FormatException('Некорректная календарная дата');
    }
  }

  factory Day.fromDateTime(DateTime value) =>
      Day(value.year, value.month, value.day);

  factory Day.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Дата должна иметь формат ГГГГ-ММ-ДД');
    }
    final parts = value.split('-').map(int.parse).toList();
    return Day(parts[0], parts[1], parts[2]);
  }

  int get ordinal =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  DateTime get localDate => DateTime(year, month, day);
  String get iso =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
  String get label =>
      '${day.toString().padLeft(2, '0')}.'
      '${month.toString().padLeft(2, '0')}.$year';
  @override
  int compareTo(Day other) => ordinal.compareTo(other.ordinal);
  @override
  bool operator ==(Object other) => other is Day && iso == other.iso;
  @override
  int get hashCode => iso.hashCode;
}

String cleanText(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Код страны ISO 3166-1 alpha-2 (две заглавные латинские буквы) или null:
/// запись без кода — свободный текст. Принадлежность к справочнику модель
/// не проверяет; это делает интерфейс при вводе и сопоставлении.
final _codePattern = RegExp(r'^[A-Z]{2}$');
bool isCountryCode(String? code) => code == null || _codePattern.hasMatch(code);

/// Необязательное поле countryCode из JSON: отсутствие или null — без кода
/// (схемы 1 и 2 его не имели), иное значение обязано быть кодом.
String? codeOf(Map<String, dynamic> map) {
  final value = map['countryCode'];
  if (value == null) return null;
  if (value is String && isCountryCode(value)) return value;
  throw const FormatException('Некорректное поле countryCode');
}

/// Ключ группировки: код, если он есть, иначе нормализованный текст.
String countryKeyOf(String? code, String country) =>
    code?.toLowerCase() ?? normalize(country);

/// Характер записи: обычное пребывание или транзит (пересадка, проезд).
/// Тип описывает поездку, а не налоговый или визовый статус.
enum TripKind { stay, transit }

/// Необязательное поле kind из JSON: отсутствие (схемы 1–3) — пребывание.
/// Старые записи транзитом не становятся.
TripKind kindOf(Map<String, dynamic> map) {
  final value = map['kind'];
  if (value == null) return TripKind.stay;
  if (value is String) {
    for (final kind in TripKind.values) {
      if (kind.name == value) return kind;
    }
  }
  throw const FormatException('Некорректное поле kind');
}

String normalize(String value) =>
    cleanText(value).toLowerCase().replaceAll('ё', 'е');

const commonCountries = [
  'Австрия',
  'Азербайджан',
  'Армения',
  'Беларусь',
  'Болгария',
  'Великобритания',
  'Венгрия',
  'Вьетнам',
  'Германия',
  'Греция',
  'Грузия',
  'Египет',
  'Израиль',
  'Индия',
  'Индонезия',
  'Испания',
  'Италия',
  'Казахстан',
  'Канада',
  'Кипр',
  'Китай',
  'Кыргызстан',
  'Мальдивы',
  'Марокко',
  'Нидерланды',
  'ОАЭ',
  'Польша',
  'Португалия',
  'Россия',
  'Сербия',
  'США',
  'Таиланд',
  'Турция',
  'Узбекистан',
  'Финляндия',
  'Франция',
  'Хорватия',
  'Черногория',
  'Чехия',
  'Швейцария',
  'Швеция',
  'Шри-Ланка',
  'Южная Корея',
  'Япония',
];

/// The same suggestions for the English interface, in the same order
/// of meaning (sorted alphabetically for the picker).
const commonCountriesEn = [
  'Armenia',
  'Austria',
  'Azerbaijan',
  'Belarus',
  'Bulgaria',
  'Canada',
  'China',
  'Croatia',
  'Cyprus',
  'Czechia',
  'Egypt',
  'Finland',
  'France',
  'Georgia',
  'Germany',
  'Greece',
  'Hungary',
  'India',
  'Indonesia',
  'Israel',
  'Italy',
  'Japan',
  'Kazakhstan',
  'Kyrgyzstan',
  'Maldives',
  'Montenegro',
  'Morocco',
  'Netherlands',
  'Poland',
  'Portugal',
  'Russia',
  'Serbia',
  'South Korea',
  'Spain',
  'Sri Lanka',
  'Sweden',
  'Switzerland',
  'Thailand',
  'Turkey',
  'UAE',
  'United Kingdom',
  'United States',
  'Uzbekistan',
  'Vietnam',
];

/// Подсказки стран для языка интерфейса.
List<String> countrySuggestions(String languageCode) =>
    languageCode == 'ru' ? commonCountries : commonCountriesEn;

class Trip {
  final String id;
  final String country;
  final String? countryCode;
  final String city;
  final String note;
  final Day arrival;
  final Day departure;
  final TripKind kind;

  const Trip({
    required this.id,
    required this.country,
    this.countryCode,
    this.city = '',
    this.note = '',
    required this.arrival,
    required this.departure,
    this.kind = TripKind.stay,
  });

  String get countryKey => countryKeyOf(countryCode, country);
  bool get isTransit => kind == TripKind.transit;

  /// Та же запись с кодом; текст и остальные поля не меняются.
  Trip withCode(String? code) => Trip(
    id: id,
    country: country,
    countryCode: code,
    city: city,
    note: note,
    arrival: arrival,
    departure: departure,
    kind: kind,
  );
  int get days => departure.ordinal - arrival.ordinal + 1;

  /// Код ошибки для экрана; текст подбирает интерфейс по языку.
  /// [plan] — запись плана: даты могут быть в будущем (и в прошлом, если
  /// план не подтвердили); остальные правила те же.
  JournalErrorCode? validate(Day today, {bool plan = false}) {
    if (id.trim().isEmpty) return JournalErrorCode.missingId;
    if (cleanText(country).isEmpty) return JournalErrorCode.countryRequired;
    if (country.length > 120 || city.length > 160 || note.length > 4000) {
      return JournalErrorCode.textTooLong;
    }
    if (!isCountryCode(countryCode)) return JournalErrorCode.invalidTrip;
    if (departure.compareTo(arrival) < 0) {
      return JournalErrorCode.departureBeforeArrival;
    }
    if (!plan &&
        (arrival.compareTo(today) > 0 || departure.compareTo(today) > 0)) {
      return JournalErrorCode.futureTrip;
    }
    return null;
  }

  /// Через сколько дней приезд по плану (0 — сегодня, отрицательное —
  /// уже прошёл).
  int daysUntil(Day today) => arrival.ordinal - today.ordinal;

  Map<String, Object?> toJson() => {
    'id': id,
    'country': country,
    'countryCode': countryCode,
    'city': city,
    'note': note,
    'arrival': arrival.iso,
    'departure': departure.iso,
    'kind': kind.name,
  };

  factory Trip.fromJson(Object? data, Day today, {bool plan = false}) {
    if (data is! Map<String, dynamic> ||
        [
          'id',
          'country',
          'city',
          'note',
          'arrival',
          'departure',
        ].any((key) => data[key] is! String)) {
      throw const FormatException('Некорректная запись поездки');
    }
    final trip = Trip(
      id: data['id'] as String,
      country: data['country'] as String,
      countryCode: codeOf(data),
      kind: kindOf(data),
      city: data['city'] as String,
      note: data['note'] as String,
      arrival: Day.parse(data['arrival'] as String),
      departure: Day.parse(data['departure'] as String),
    );
    final error = trip.validate(today, plan: plan);
    if (error != null) throw FormatException('Invalid trip: ${error.name}');
    return trip;
  }
}

/// A year selects trips that touch it; calculations clip their dates to it.
List<Trip> selectTrips(
  Iterable<Trip> trips, {
  String query = '',
  String? country,
  int? year,
  /// Все написания страны по коду (справочник): поиск находит поездку и
  /// по названию на другом языке, а не только по тексту в файле.
  Iterable<String> Function(String code)? spellings,
}) {
  final terms = normalize(query).split(' ').where((t) => t.isNotEmpty);
  final selected = trips.where((trip) {
    if (country != null && trip.countryKey != country) return false;
    if (year != null &&
        (trip.arrival.year > year || trip.departure.year < year)) {
      return false;
    }
    final code = trip.countryCode;
    final names = code == null || spellings == null
        ? ''
        : spellings(code).join(' ');
    final text = normalize(
      '${trip.country} $names ${trip.city} ${trip.note} '
      '${trip.arrival.label} ${trip.departure.label}',
    );
    return terms.every((term) {
      final asYear = RegExp(r'^\d{4}$').hasMatch(term)
          ? int.tryParse(term)
          : null;
      return text.contains(term) ||
          (asYear != null &&
              trip.arrival.year <= asYear &&
              trip.departure.year >= asYear);
    });
  }).toList();
  selected.sort((a, b) {
    final dateOrder = b.arrival.compareTo(a.arrival);
    return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
  });
  return selected;
}

/// Inclusive union of intervals, not a sum of potentially overlapping trips.
int unionDays(Iterable<Trip> trips, {int? year}) {
  final ranges = <(int, int)>[];
  for (final trip in trips) {
    var start = trip.arrival.ordinal;
    var end = trip.departure.ordinal;
    if (year != null) {
      final first = Day(year, 1, 1).ordinal;
      final last = Day(year, 12, 31).ordinal;
      if (start < first) start = first;
      if (end > last) end = last;
    }
    if (start <= end) ranges.add((start, end));
  }
  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  int total = 0;
  int? start;
  int? end;
  for (final range in ranges) {
    if (end == null || range.$1 > end + 1) {
      if (start != null && end != null) total += end - start + 1;
      start = range.$1;
      end = range.$2;
    } else if (range.$2 > end) {
      end = range.$2;
    }
  }
  if (start != null && end != null) total += end - start + 1;
  return total;
}

class CountryStat {
  final String key;
  final String label;
  final int days;
  final int trips;

  /// Код группы, если записи сопоставлены со справочником.
  final String? code;

  /// Сколько из [trips] — транзиты; их дни входят в [days].
  final int transits;
  const CountryStat(
    this.key,
    this.label,
    this.days,
    this.trips, {
    this.code,
    this.transits = 0,
  });
}

List<CountryStat> countryStats(Iterable<Trip> trips, {int? year}) {
  final groups = <String, List<Trip>>{};
  for (final trip in trips) {
    (groups[trip.countryKey] ??= []).add(trip);
  }
  final result = groups.entries.map((entry) {
    return CountryStat(
      entry.key,
      cleanText(entry.value.first.country),
      unionDays(entry.value, year: year),
      entry.value.length,
      code: entry.value.first.countryCode,
      transits: entry.value.where((t) => t.isTransit).length,
    );
  }).toList();
  result.sort((a, b) {
    final days = b.days.compareTo(a.days);
    return days != 0 ? days : a.key.compareTo(b.key);
  });
  return result;
}
