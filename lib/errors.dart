import 'trip.dart';

/// Ошибки проверки, которые видит пользователь. Модель не знает языка
/// интерфейса: она отдаёт код и данные, а экран переводит их через l10n.
enum JournalErrorCode {
  missingId,
  countryRequired,
  textTooLong,
  departureBeforeArrival,
  futureTrip,
  invalidTrip,
  sameCountry,
  moveDateRange,
  countryLength,
  yearRange,
  previewStale,
  homeCountryFirst,
  moveDateRequired,
}

class JournalError implements Exception {
  final JournalErrorCode code;

  /// Границы допустимого диапазона для [JournalErrorCode.moveDateRange].
  final Day? from;
  final Day? to;

  const JournalError(this.code, {this.from, this.to});

  @override
  String toString() => 'JournalError($code)';
}
