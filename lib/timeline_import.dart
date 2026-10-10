import 'dart:convert';

import 'borders.dart';
import 'overlap.dart';
import 'snapshot.dart';
import 'trip.dart';

/// Импорт истории Google Maps («Хронология»). Чистая логика: разбор
/// файла экспорта в точки «дата + координаты», страна по границам офлайн,
/// сборка периодов и сверка с дневником. Координаты живут только в памяти
/// на время разбора; в результат попадают лишь даты и коды стран.

/// Точка истории: локальная дата, минуты от полуночи (для порядка стран
/// внутри дня) и координаты.
class TimelineSample {
  final Day day;
  final int minute;
  final double lat;
  final double lon;
  const TimelineSample(this.day, this.minute, this.lat, this.lon);
}

/// Разбор поддерживает экспорт с телефона (semanticSegments / rawSignals)
/// и старый Google Takeout (Records.json, Semantic Location History).
/// Незнакомые поля пропускаются; не JSON — исключение FormatException.
List<TimelineSample> parseTimeline(String text) {
  final json = jsonDecode(text);
  final out = <TimelineSample>[];
  if (json is! Map) return out;
  final segments = json['semanticSegments'];
  if (segments is List) {
    for (final s in segments) {
      if (s is Map) _segment(s, out);
    }
  }
  final raw = json['rawSignals'];
  if (raw is List) {
    for (final r in raw) {
      if (r is! Map) continue;
      final p = r['position'];
      if (p is! Map) continue;
      _point(p['LatLng'] ?? p['latLng'], p['timestamp'], out);
    }
  }
  final locations = json['locations'];
  if (locations is List) {
    for (final l in locations) {
      if (l is Map) _point(l, l['timestamp'] ?? l['timestampMs'], out);
    }
  }
  final objects = json['timelineObjects'];
  if (objects is List) {
    for (final o in objects) {
      if (o is! Map) continue;
      final visit = o['placeVisit'];
      if (visit is Map) {
        final d = visit['duration'];
        _span(
          visit['location'],
          d is Map ? d['startTimestamp'] ?? d['startTimestampMs'] : null,
          d is Map ? d['endTimestamp'] ?? d['endTimestampMs'] : null,
          out,
        );
      }
      final act = o['activitySegment'];
      if (act is Map) {
        final d = act['duration'];
        _point(
          act['startLocation'],
          d is Map ? d['startTimestamp'] ?? d['startTimestampMs'] : null,
          out,
        );
        _point(
          act['endLocation'],
          d is Map ? d['endTimestamp'] ?? d['endTimestampMs'] : null,
          out,
        );
      }
    }
  }
  return out;
}

void _segment(Map s, List<TimelineSample> out) {
  final start = s['startTime'], end = s['endTime'];
  final visit = s['visit'];
  if (visit is Map) {
    final top = visit['topCandidate'];
    final place = top is Map ? top['placeLocation'] : null;
    _span(place is Map ? place['latLng'] : place, start, end, out);
  }
  final activity = s['activity'];
  if (activity is Map) {
    final a = activity['start'], b = activity['end'];
    _point(a is Map ? a['latLng'] : a, start, out);
    _point(b is Map ? b['latLng'] : b, end, out);
  }
  final path = s['timelinePath'];
  if (path is List) {
    for (final p in path) {
      if (p is! Map) continue;
      Object? time = p['time'];
      final offset = p['durationMinutesOffsetFromStartTime'];
      if (time == null && offset != null && start is String) {
        final minutes = int.tryParse(offset.toString());
        final base = DateTime.tryParse(start);
        if (minutes != null && base != null) {
          time = base.add(Duration(minutes: minutes)).toIso8601String();
          // Смещение зоны потеряно: берём его из startTime.
          time = _withOffsetOf(time as String, start);
        }
      }
      _point(p['point'], time, out);
    }
  }
}

/// Визит от [startTs] до [endTs] в одной точке: первый и последний день
/// получают реальные минуты, дни между — весь день.
void _span(
  Object? where,
  Object? startTs,
  Object? endTs,
  List<TimelineSample> out,
) {
  final ll = _latLng(where);
  if (ll == null) return;
  final a = _when(startTs, ll.$2), b = _when(endTs, ll.$2);
  if (a == null) {
    if (b != null) out.add(TimelineSample(b.$1, b.$2, ll.$1, ll.$2));
    return;
  }
  if (b == null || b.$1.ordinal <= a.$1.ordinal) {
    out.add(TimelineSample(a.$1, a.$2, ll.$1, ll.$2));
    if (b != null) out.add(TimelineSample(b.$1, b.$2, ll.$1, ll.$2));
    return;
  }
  out.add(TimelineSample(a.$1, a.$2, ll.$1, ll.$2));
  out.add(TimelineSample(a.$1, 1439, ll.$1, ll.$2));
  final span = (b.$1.ordinal - a.$1.ordinal - 1).clamp(0, 4000);
  for (var i = 1; i <= span; i++) {
    final d = _dayAt(a.$1.ordinal + i);
    out.add(TimelineSample(d, 0, ll.$1, ll.$2));
    out.add(TimelineSample(d, 1439, ll.$1, ll.$2));
  }
  out.add(TimelineSample(b.$1, 0, ll.$1, ll.$2));
  out.add(TimelineSample(b.$1, b.$2, ll.$1, ll.$2));
}

void _point(Object? where, Object? ts, List<TimelineSample> out) {
  final ll = _latLng(where);
  if (ll == null) return;
  final t = _when(ts, ll.$2);
  if (t == null) return;
  out.add(TimelineSample(t.$1, t.$2, ll.$1, ll.$2));
}

Day _dayAt(int ordinal) => Day.fromDateTime(
  DateTime.fromMillisecondsSinceEpoch(
    ordinal * Duration.millisecondsPerDay,
    isUtc: true,
  ),
);

final _degrees = RegExp(r'[°\s]');

/// «41.7151°, 44.8271°», «geo:41.7,44.8», {latitudeE7, longitudeE7},
/// {lat, lng}, {latLng: …}.
(double, double)? _latLng(Object? v) {
  if (v is String) {
    var s = v.replaceAll(_degrees, '');
    if (s.startsWith('geo:')) s = s.substring(4);
    final parts = s.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]), lon = double.tryParse(parts[1]);
    return _valid(lat, lon);
  }
  if (v is Map) {
    if (v['latLng'] != null) return _latLng(v['latLng']);
    if (v['LatLng'] != null) return _latLng(v['LatLng']);
    final e7lat = v['latitudeE7'], e7lon = v['longitudeE7'];
    if (e7lat is num && e7lon is num) {
      return _valid(e7lat / 1e7, e7lon / 1e7);
    }
    final lat = v['lat'] ?? v['latitude'], lon = v['lng'] ?? v['longitude'];
    if (lat is num && lon is num) return _valid(lat.toDouble(), lon.toDouble());
  }
  return null;
}

(double, double)? _valid(double? lat, double? lon) {
  if (lat == null || lon == null) return null;
  if (lat.abs() > 90 || lon.abs() > 180 || (lat == 0 && lon == 0)) {
    return null;
  }
  return (lat, lon);
}

final _offsetPattern = RegExp(r'([+-])(\d{2}):?(\d{2})$');

String _withOffsetOf(String isoUtc, String reference) {
  final m = _offsetPattern.firstMatch(reference);
  if (m == null) return isoUtc;
  final sign = m.group(1) == '-' ? -1 : 1;
  final minutes = sign * (int.parse(m.group(2)!) * 60 + int.parse(m.group(3)!));
  final utc = DateTime.parse(isoUtc).toUtc();
  final local = utc.add(Duration(minutes: minutes));
  final hh = (minutes.abs() ~/ 60).toString().padLeft(2, '0');
  final mm = (minutes.abs() % 60).toString().padLeft(2, '0');
  return '${local.toIso8601String().replaceFirst('Z', '')}'
      '${sign < 0 ? '-' : '+'}$hh:$mm';
}

/// Локальная дата и минуты: со смещением зоны в строке — по нему; для
/// «Z» и миллисекунд — по долготе (±30 мин к реальной зоне, для даты
/// достаточно).
(Day, int)? _when(Object? ts, double lon) {
  DateTime? utc;
  int? offset;
  if (ts is String) {
    utc = DateTime.tryParse(ts)?.toUtc();
    if (utc == null) {
      final ms = int.tryParse(ts);
      if (ms == null) return null;
      utc = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    } else {
      final m = _offsetPattern.firstMatch(ts);
      if (m != null) {
        final sign = m.group(1) == '-' ? -1 : 1;
        offset = sign * (int.parse(m.group(2)!) * 60 + int.parse(m.group(3)!));
      }
    }
  } else if (ts is num) {
    utc = DateTime.fromMillisecondsSinceEpoch(ts.toInt(), isUtc: true);
  } else {
    return null;
  }
  offset ??= (lon / 15).round() * 60;
  final local = utc.add(Duration(minutes: offset));
  if (local.year < 1900 || local.year > 2200) return null;
  return (
    Day(local.year, local.month, local.day),
    local.hour * 60 + local.minute,
  );
}

/// Страны одного дня: первая и последняя по времени, все встреченные,
/// число точек.
class DayCountries {
  String? first;
  int _firstMinute = 1 << 20;
  String? last;
  int _lastMinute = -1;
  final Set<String> codes = {};
  int points = 0;

  void add(String code, int minute) {
    codes.add(code);
    points++;
    if (minute < _firstMinute) {
      _firstMinute = minute;
      first = code;
    }
    if (minute > _lastMinute) {
      _lastMinute = minute;
      last = code;
    }
  }
}

/// Страна каждой точки по границам; сетка ~1 км кэширует ответы, так что
/// тысячи точек одного места считаются один раз.
Map<Day, DayCountries> countriesByDay(
  Iterable<TimelineSample> samples,
  CountryBorders borders,
) {
  final cache = <int, String?>{};
  final days = <Day, DayCountries>{};
  for (final s in samples) {
    final key =
        ((s.lat * 100).round() + 9000) * 40000 +
        ((s.lon * 100).round() + 18000);
    final code = cache.putIfAbsent(key, () => borders.containing(s.lat, s.lon));
    if (code == null) continue;
    days.putIfAbsent(s.day, DayCountries.new).add(code, s.minute);
  }
  return days;
}

/// Период пребывания в одной стране по данным истории.
class ImportPeriod {
  final String code;
  final Day start;
  final Day end;

  /// Точек истории за период.
  final int points;

  /// Дней без данных внутри периода (пробелы короче [bridgeGapDays]).
  final int gapDays;

  /// Один день между двумя другими странами: пересадка или проезд.
  final bool transit;
  const ImportPeriod({
    required this.code,
    required this.start,
    required this.end,
    required this.points,
    required this.gapDays,
    this.transit = false,
  });
  int get days => end.ordinal - start.ordinal + 1;

  ImportPeriod copyWith({Day? end, bool? transit, int? points, int? gapDays}) =>
      ImportPeriod(
        code: code,
        start: start,
        end: end ?? this.end,
        points: points ?? this.points,
        gapDays: gapDays ?? this.gapDays,
        transit: transit ?? this.transit,
      );
}

/// Пробел без данных не длиннее этого внутри одной страны считается
/// той же поездкой (телефон выключен, нет сигнала). Длиннее — период
/// делится, дни между остаются неизвестными.
const bridgeGapDays = 7;

/// Периоды из стран по дням. День с двумя странами закрывает одну и
/// открывает другую — обе включают этот день, как принято в дневнике.
List<ImportPeriod> buildPeriods(Map<Day, DayCountries> byDay) {
  final days = byDay.keys.toList()..sort();
  final periods = <ImportPeriod>[];
  String? code;
  Day? start, end;
  var points = 0, gaps = 0;
  Day? countedDay;

  void close() {
    if (code != null) {
      periods.add(
        ImportPeriod(
          code: code!,
          start: start!,
          end: end!,
          points: points,
          gapDays: gaps,
        ),
      );
    }
    code = null;
    points = 0;
    gaps = 0;
    countedDay = null;
  }

  for (final day in days) {
    final dc = byDay[day]!;
    // Первая страна дня, остальные, последняя: день «дом → соседи →
    // дом» даёт [A, B, A], чтобы пребывание A не рвалось.
    final tokens = <String>[
      dc.first!,
      ...(dc.codes.toList()..sort()).where(
        (c) => c != dc.first && c != dc.last,
      ),
    ];
    if (tokens.last != dc.last) tokens.add(dc.last!);
    for (final token in tokens) {
      if (code == token) {
        final gap = day.ordinal - end!.ordinal - 1;
        if (gap > bridgeGapDays) {
          close();
        } else {
          gaps += gap;
        }
      }
      if (code != token) {
        close();
        code = token;
        start = day;
      }
      end = day;
      if (countedDay != day) {
        points += dc.points;
        countedDay = day;
      }
    }
  }
  close();
  return _mergeDayTrips(periods);
}

/// A, однодневная B, снова A в те же дни → одна поездка A и транзит B.
List<ImportPeriod> _mergeDayTrips(List<ImportPeriod> periods) {
  final out = List<ImportPeriod>.of(periods);
  var i = 0;
  while (i + 2 < out.length) {
    final a = out[i], b = out[i + 1], c = out[i + 2];
    if (a.code == c.code &&
        b.days == 1 &&
        b.start == a.end &&
        b.end == c.start) {
      out[i] = a.copyWith(
        end: c.end,
        points: a.points + c.points,
        gapDays: a.gapDays + c.gapDays,
      );
      out[i + 1] = b.copyWith(transit: true);
      out.removeAt(i + 2);
    } else {
      i++;
    }
  }
  for (var i = 1; i + 1 < out.length; i++) {
    if (out[i].days == 1 && !out[i].transit) {
      out[i] = out[i].copyWith(transit: true);
    }
  }
  return out;
}

/// Итог разбора файла.
class ImportAnalysis {
  final List<ImportPeriod> periods;
  final int samples;
  final int daysWithData;

  /// Самая частая страна по дням — предположение о доме при онбординге.
  final String? frequentCode;
  const ImportAnalysis({
    required this.periods,
    required this.samples,
    required this.daysWithData,
    required this.frequentCode,
  });
  Day? get first => periods.isEmpty ? null : periods.first.start;
  Day? get last => periods.isEmpty ? null : periods.last.end;
}

ImportAnalysis analyzeTimeline(String text, CountryBorders borders) {
  final samples = parseTimeline(text);
  final byDay = countriesByDay(samples, borders);
  final count = <String, int>{};
  for (final dc in byDay.values) {
    for (final c in dc.codes) {
      count[c] = (count[c] ?? 0) + 1;
    }
  }
  String? frequent;
  var best = 0;
  for (final e in count.entries) {
    if (e.value > best || (e.value == best && e.key.compareTo(frequent!) < 0)) {
      best = e.value;
      frequent = e.key;
    }
  }
  return ImportAnalysis(
    periods: buildPeriods(byDay),
    samples: samples.length,
    daysWithData: byDay.length,
    frequentCode: frequent,
  );
}

/// Как период соотносится с дневником.
enum ImportStatus {
  /// Нового пересечения нет — добавляется как запись.
  add,

  /// Та же страна уже записана на эти даты (или это текущее пребывание).
  exists,

  /// Пересекается на 2+ дня с записью другой страны — решает владелец.
  conflict,

  /// Открытый период до сегодня при пустом «сейчас» — станет текущим
  /// пребыванием.
  current,
}

class ImportRow {
  final ImportPeriod period;
  final ImportStatus status;

  /// Код страны записи, с которой пересекается (для conflict).
  final String? overlaps;
  bool selected;
  ImportRow(this.period, this.status, {this.overlaps})
    : selected = status == ImportStatus.add || status == ImportStatus.current;
}

/// Сверка периодов с дневником: будущее отрезается по [today], периоды
/// с той же страной на те же даты помечаются как существующие. Записи
/// без кода сравниваются по коду из справочника ([match]).
List<ImportRow> planImport(
  List<ImportPeriod> periods,
  JournalSnapshot snapshot,
  Day today, {
  String? Function(String text)? match,
}) {
  final rows = <ImportRow>[];
  final current = snapshot.current;
  String keyOf(String? code, String text) =>
      countryKeyOf(code ?? match?.call(text), text);
  String labelOf(String? code, String text) =>
      code ?? match?.call(text) ?? text;
  for (var i = 0; i < periods.length; i++) {
    var p = periods[i];
    if (p.start.compareTo(today) > 0) continue;
    if (p.end.compareTo(today) > 0) p = p.copyWith(end: today);
    final key = countryKeyOf(p.code, '');
    String? overlaps;
    var exists = false;
    for (final t in snapshot.trips) {
      final overlap =
          _min(t.departure.ordinal, p.end.ordinal) -
          _max(t.arrival.ordinal, p.start.ordinal) +
          1;
      if (overlap <= 0) continue;
      if (keyOf(t.countryCode, t.country) == key) {
        exists = true;
      } else if (overlap >= 2 && !t.isTransit) {
        overlaps ??= labelOf(t.countryCode, t.country);
      }
    }
    final open = i == periods.length - 1 && today.ordinal - p.end.ordinal <= 1;
    if (current != null) {
      final since = current.arrival ?? current.confirmedOn;
      if (p.end.ordinal >= since.ordinal) {
        if (keyOf(current.countryCode, current.country) == key) {
          exists = true;
        } else if (open ||
            p.end.ordinal - _max(since.ordinal, p.start.ordinal) >= 1) {
          overlaps ??= labelOf(current.countryCode, current.country);
        }
      }
    }
    final ImportStatus status;
    if (exists) {
      status = ImportStatus.exists;
    } else if (overlaps != null) {
      status = ImportStatus.conflict;
    } else if (open && current == null) {
      status = ImportStatus.current;
    } else {
      status = ImportStatus.add;
    }
    rows.add(ImportRow(p, status, overlaps: overlaps));
  }
  return rows;
}

int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;

/// Новый снимок: выбранные строки становятся записями (транзит — с
/// признаком), строка «текущее» — текущим пребыванием. При онбординге
/// задаются дом и, если открытого периода нет, текущая страна.
JournalSnapshot applyImport(
  JournalSnapshot snapshot,
  List<ImportRow> rows, {
  required Day today,
  required String Function() newId,
  required String Function(String code) nameOf,
  String? homeCountry,
  String? homeCountryCode,
  String? currentCountry,
  String? currentCountryCode,
}) {
  var working = snapshot;
  CurrentStay? current = snapshot.current;
  for (final row in rows) {
    if (!row.selected || row.status == ImportStatus.exists) continue;
    final p = row.period;
    if (row.status == ImportStatus.current && current == null) {
      current = CurrentStay(
        id: newId(),
        country: nameOf(p.code),
        countryCode: p.code,
        arrival: p.start,
        confirmedOn: today,
      );
      working = working.copyWith(current: current);
      continue;
    }
    final trip = Trip(
      id: newId(),
      country: nameOf(p.code),
      countryCode: p.code,
      arrival: p.start,
      departure: p.end,
      kind: p.transit ? TripKind.transit : TripKind.stay,
    );
    // Строка «пересекается» выбрана владельцем осознанно: задетые записи
    // обрезаются по общим правилам (см. overlap.dart), как в редакторе.
    final plan = planOverlap(working, trip, today, newId: newId);
    working = applyOverlap(
      working,
      plan,
      replace: row.status == ImportStatus.conflict,
    );
    current = working.current;
  }
  final trips = working.trips;
  if (homeCountry != null && current == null && currentCountry != null) {
    current = CurrentStay(
      id: newId(),
      country: currentCountry,
      countryCode: currentCountryCode,
      arrival: null,
      confirmedOn: today,
    );
  }
  return snapshot.copyWith(
    trips: trips,
    homeCountry: homeCountry,
    homeCountryCode: homeCountryCode,
    current: current,
  );
}
