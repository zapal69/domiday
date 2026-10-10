import 'package:domiday/l10n/app_localizations_en.dart';
import 'package:domiday/l10n/app_localizations_ru.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('russian plural forms for days and records', () {
    final ru = AppLocalizationsRu();
    expect(ru.daysFull(1), '1 день');
    expect(ru.daysFull(2), '2 дня');
    expect(ru.daysFull(5), '5 дней');
    expect(ru.daysFull(11), '11 дней');
    expect(ru.daysFull(21), '21 день');
    expect(ru.daysFull(24), '24 дня');
    expect(ru.daysFull(25), '25 дней');
    expect(ru.recordsCount(1), '1 запись');
    expect(ru.recordsCount(3), '3 записи');
    expect(ru.recordsCount(12), '12 записей');
    expect(ru.daysCompact(37), '37 дн.');
  });

  test('english plural forms', () {
    final en = AppLocalizationsEn();
    expect(en.daysFull(1), '1 day');
    expect(en.daysFull(25), '25 days');
    expect(en.recordsCount(1), '1 record');
    expect(en.recordsCount(2), '2 records');
    expect(en.daysCompact(1), '1 day');
    expect(en.daysCompact(37), '37 days');
  });

  test('every key is translated in both languages', () {
    final en = AppLocalizationsEn();
    final ru = AppLocalizationsRu();
    // Пара маркеров: разные языки дают разные строки, ключи не перепутаны.
    expect(en.byCountry, isNot(ru.byCountry));
    expect(en.aboutTitle, 'About Domiday');
    expect(ru.aboutTitle, 'О дневнике');
    expect(en.monthsShort.split(',').length, 12);
    expect(ru.monthsShort.split(',').length, 12);
  });

  test('settings json round-trip and tolerant parsing', () {
    const en = AppSettings(locale: Locale('en'));
    expect(AppSettings.fromJson(en.toJson()).locale, const Locale('en'));
    expect(AppSettings.fromJson(const AppSettings().toJson()).locale, isNull);
    expect(AppSettings.fromJson({'locale': 'de'}).locale, isNull);
    expect(AppSettings.fromJson('garbage').locale, isNull);
    expect(AppSettings.fromJson(null).locale, isNull);
  });

  test('country suggestions follow the interface language', () {
    expect(countrySuggestions('ru'), contains('Грузия'));
    expect(countrySuggestions('en'), contains('Georgia'));
    expect(countrySuggestions('de'), contains('Georgia'));
    expect(commonCountries.length, commonCountriesEn.length);
  });
}
