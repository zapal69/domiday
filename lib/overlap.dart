import 'snapshot.dart';
import 'trip.dart';

/// Пересечения новой или изменённой записи с дневником и их разрешение.
///
/// Правила (согласованы с владельцем):
/// - один общий день на стыке двух записей — день переезда, допустим и
///   не считается пересечением; пересечение — от двух общих дней;
/// - та же страна на те же даты — тоже пересечение (предупреждение, а не
///   молчаливое объединение);
/// - транзит поверх пребывания и любые пересечения с транзитом не считаются:
///   пересадка внутри поездки — норма;
/// - «Заменить» обрезает старые записи, оставляя общий стыковой день,
///   делит запись, если новая попала в середину, и удаляет полностью
///   перекрытую; текущее пребывание получает новую дату начала. Всё это
///   только после явного подтверждения в диалоге — история не удаляется
///   молча.

/// Что станет с существующей записью при «Заменить».
enum OverlapOutcome { trim, split, remove, moveCurrent, unresolved }

class OverlapItem {
  /// Существующая запись; null — пересечение с текущим пребыванием.
  final Trip? trip;
  final CurrentStay? current;
  final OverlapOutcome outcome;

  /// Чем заменяется запись: одна обрезанная (trim), две (split), ничего
  /// (remove). Для текущего пребывания — пусто, см. [newArrival].
  final List<Trip> pieces;

  /// Новое начало текущего пребывания (moveCurrent).
  final Day? newArrival;
  final bool sameCountry;

  const OverlapItem({
    this.trip,
    this.current,
    required this.outcome,
    this.pieces = const [],
    this.newArrival,
    required this.sameCountry,
  });

  String get country => trip?.country ?? current!.country;
  String? get countryCode => trip?.countryCode ?? current!.countryCode;
}

class OverlapPlan {
  final Trip trip;
  final List<OverlapItem> items;
  const OverlapPlan(this.trip, this.items);

  bool get isEmpty => items.isEmpty;

  /// «Заменить» предлагается, только если каждое пересечение разрешимо:
  /// текущее пребывание без даты приезда или перекрытое до сегодня
  /// сдвинуть нельзя.
  bool get canReplace =>
      items.every((i) => i.outcome != OverlapOutcome.unresolved);
}

int _overlapDays(Day a1, Day a2, Day b1, Day b2) {
  final start = a1.ordinal > b1.ordinal ? a1.ordinal : b1.ordinal;
  final end = a2.ordinal < b2.ordinal ? a2.ordinal : b2.ordinal;
  return end - start + 1;
}

Trip _piece(Trip source, String id, Day arrival, Day departure) => Trip(
  id: id,
  country: source.country,
  countryCode: source.countryCode,
  city: source.city,
  note: source.note,
  arrival: arrival,
  departure: departure,
  kind: source.kind,
);

/// Пересечения [trip] с дневником. Сама запись (по id) не сравнивается с
/// собой — при редактировании это её прежняя версия.
OverlapPlan planOverlap(
  JournalSnapshot snapshot,
  Trip trip,
  Day today, {
  required String Function() newId,
}) {
  final items = <OverlapItem>[];
  if (trip.isTransit) return OverlapPlan(trip, items);
  final a = trip.arrival;
  final b = trip.departure;
  for (final t in snapshot.trips) {
    if (t.id == trip.id || t.isTransit) continue;
    if (_overlapDays(a, b, t.arrival, t.departure) < 2) continue;
    final same = t.countryKey == trip.countryKey;
    final c = t.arrival;
    final d = t.departure;
    final before = c.compareTo(a) < 0;
    final after = d.compareTo(b) > 0;
    if (before && after) {
      items.add(
        OverlapItem(
          trip: t,
          outcome: OverlapOutcome.split,
          pieces: [_piece(t, t.id, c, a), _piece(t, newId(), b, d)],
          sameCountry: same,
        ),
      );
    } else if (before) {
      items.add(
        OverlapItem(
          trip: t,
          outcome: OverlapOutcome.trim,
          pieces: [_piece(t, t.id, c, a)],
          sameCountry: same,
        ),
      );
    } else if (after) {
      items.add(
        OverlapItem(
          trip: t,
          outcome: OverlapOutcome.trim,
          pieces: [_piece(t, t.id, b, d)],
          sameCountry: same,
        ),
      );
    } else {
      items.add(
        OverlapItem(trip: t, outcome: OverlapOutcome.remove, sameCountry: same),
      );
    }
  }
  final current = snapshot.current;
  if (current != null && current.id != trip.id) {
    final since = current.arrival ?? current.confirmedOn;
    if (_overlapDays(a, b, since, today) >= 2) {
      final same = current.countryKey == trip.countryKey;
      final movable = current.arrival != null && b.compareTo(today) < 0;
      items.add(
        OverlapItem(
          current: current,
          outcome: movable
              ? OverlapOutcome.moveCurrent
              : OverlapOutcome.unresolved,
          newArrival: movable ? b : null,
          sameCountry: same,
        ),
      );
    }
  }
  return OverlapPlan(trip, items);
}

/// Снимок с записью [plan.trip] (новая добавляется, существующая — по id
/// заменяется). При [replace] задетые записи обрезаются, делятся или
/// удаляются по плану, текущее пребывание получает новое начало;
/// неразрешимые пересечения остаются как есть.
JournalSnapshot applyOverlap(
  JournalSnapshot snapshot,
  OverlapPlan plan, {
  required bool replace,
}) {
  final trip = plan.trip;
  final replaced = <String, List<Trip>>{};
  CurrentStay? current = snapshot.current;
  if (replace) {
    for (final item in plan.items) {
      if (item.trip != null) {
        replaced[item.trip!.id] = item.pieces;
      } else if (item.outcome == OverlapOutcome.moveCurrent) {
        final c = item.current!;
        current = CurrentStay(
          id: c.id,
          country: c.country,
          countryCode: c.countryCode,
          arrival: item.newArrival,
          confirmedOn: c.confirmedOn,
          notBefore: c.notBefore,
        );
      }
    }
  }
  final trips = <Trip>[
    for (final t in snapshot.trips)
      if (t.id != trip.id) ...(replaced[t.id] ?? [t]),
    trip,
  ];
  return snapshot.copyWith(trips: trips, current: current);
}
