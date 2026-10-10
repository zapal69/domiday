import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'countries.dart';
import 'errors.dart';
import 'l10n/app_localizations.dart';
import 'trip.dart';

/// Даты на экране: русский интерфейс сохраняет ДД.ММ.ГГГГ, английский —
/// «Sep 13, 2026». Хранение и Day.label не зависят от языка.
extension DayText on Day {
  String text(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ru') return label;
    return DateFormat.yMMMd(locale.toString()).format(localDate);
  }

  /// Без года: «13.09» / «Sep 13».
  String shortText(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ru') return label.substring(0, 5);
    return DateFormat.MMMd(locale.toString()).format(localDate);
  }
}

/// Момент с временем: «13.09.2026 12:05» / «Sep 13, 2026, 12:05 PM».
String dateTimeText(BuildContext context, DateTime at) {
  final local = at.toLocal();
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'ru') {
    return DateFormat('dd.MM.yyyy HH:mm').format(local);
  }
  return DateFormat.yMMMd(locale.toString()).add_jm().format(local);
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Текст пользовательской ошибки модели на языке интерфейса.
String describeError(BuildContext context, JournalError error) {
  final l = context.l10n;
  return switch (error.code) {
    JournalErrorCode.missingId => l.errMissingId,
    JournalErrorCode.countryRequired => l.errCountryRequired,
    JournalErrorCode.textTooLong => l.errTextTooLong,
    JournalErrorCode.departureBeforeArrival => l.errDepartureBeforeArrival,
    JournalErrorCode.futureTrip => l.errFutureTrip,
    JournalErrorCode.invalidTrip => l.errInvalidTrip,
    JournalErrorCode.sameCountry => l.errSameCountry,
    JournalErrorCode.moveDateRange => l.errMoveDateRange(
      error.from!.text(context),
      error.to!.text(context),
    ),
    JournalErrorCode.countryLength => l.errCountryLength,
    JournalErrorCode.yearRange => l.errYearRange,
    JournalErrorCode.previewStale => l.errPreviewStale,
    JournalErrorCode.homeCountryFirst => l.errHomeCountryFirst,
    JournalErrorCode.moveDateRequired => l.errMoveDateRequired,
  };
}

/// Название страны на языке интерфейса по коду; без кода — введённый текст.
String countryName(BuildContext context, String? code, String text) =>
    CountryScope.of(context)
        .display(code, text, Localizations.localeOf(context).languageCode);
