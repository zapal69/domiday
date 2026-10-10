import 'snapshot.dart';
import 'trip.dart';

/// Запись «в этот день»: поездка [trip] в году [year]. [exact] — дата
/// попадает в поездку; иначе поездка была в окне ±[onThisDay.window]
/// дней («в эти дни»). [dayIndex] — какой это день поездки (с 1) при
/// точном попадании.
class OnThisDayEntry {
  final int year;
  final Trip trip;
  final bool exact;
  final int dayIndex;
  const OnThisDayEntry(this.year, this.trip, {required this.exact, this.dayIndex = 0});
}

/// Что было в этот день (и около него) в прошлые годы: только чтение
/// дневника. Дни дома не показываются — показывать нечего. Годы по
/// убыванию, внутри года точные попадания раньше окна; 29 февраля в
/// невисокосный год считается как 28-е.
List<OnThisDayEntry> onThisDay(
  JournalSnapshot snapshot,
  Day today, {
  int window = 3,
}) {
  final trips = snapshot
      .knownTrips(today)
      .where((t) => t.countryKey != snapshot.homeKey)
      .toList();
  if (trips.isEmpty) return const [];
  final firstYear = trips.map((t) => t.arrival.year).reduce((a, b) => a < b ? a : b);
  final out = <OnThisDayEntry>[];
  for (var year = today.year - 1; year >= firstYear; year--) {
    final leap = DateTime.utc(year, 2, 29).month == 2;
    final day = Day(
      year,
      today.month,
      today.month == 2 && today.day == 29 && !leap ? 28 : today.day,
    );
    final exact = <OnThisDayEntry>[];
    final around = <OnThisDayEntry>[];
    for (final t in trips) {
      if (t.arrival.ordinal <= day.ordinal && t.departure.ordinal >= day.ordinal) {
        exact.add(
          OnThisDayEntry(year, t, exact: true, dayIndex: day.ordinal - t.arrival.ordinal + 1),
        );
      } else if (t.arrival.ordinal <= day.ordinal + window &&
          t.departure.ordinal >= day.ordinal - window) {
        around.add(OnThisDayEntry(year, t, exact: false));
      }
    }
    int order(OnThisDayEntry a, OnThisDayEntry b) {
      final byTransit = (a.trip.isTransit ? 1 : 0).compareTo(b.trip.isTransit ? 1 : 0);
      return byTransit != 0 ? byTransit : a.trip.arrival.compareTo(b.trip.arrival);
    }
    exact.sort(order);
    around.sort(order);
    out.addAll(exact.isNotEmpty ? exact : around);
  }
  return out;
}
