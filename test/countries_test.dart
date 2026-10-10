import 'dart:io';

import 'package:domiday/countries.dart';
import 'package:domiday/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CountryDirectory directory;
  setUpAll(() {
    directory = CountryDirectory.fromJson(
      File('assets/countries.json').readAsStringSync(),
    );
  });

  test('directory covers ISO 3166-1 with both languages', () {
    expect(directory.all.length, greaterThanOrEqualTo(249));
    for (final c in directory.all) {
      expect(c.code, matches(RegExp(r'^[A-Z]{2}$')));
      expect(c.en, isNotEmpty);
      expect(c.ru, isNotEmpty);
    }
    expect(directory['GE']!.ru, 'Грузия');
    expect(directory['GE']!.en, 'Georgia');
    expect(directory['US']!.ru, 'США');
    expect(directory['KR']!.ru, 'Южная Корея');
    expect(directory['XK']!.en, 'Kosovo');
    expect(directory.contains('ZZ'), isFalse);
    expect(directory[null], isNull);
  });

  test('every built-in suggestion resolves to a code', () {
    for (final name in [...commonCountries, ...commonCountriesEn]) {
      expect(directory.match(name), isNotNull, reason: name);
    }
  });

  test('matching is exact after normalisation, never by substring', () {
    expect(directory.match('  россия '), 'RU');
    expect(directory.match('РОССИЯ'), 'RU');
    expect(directory.match('Russia'), 'RU');
    expect(directory.match('РФ'), 'RU');
    expect(directory.match('USA'), 'US');
    expect(directory.match('Соединенные Штаты'), 'US');
    expect(directory.match('Соединённые Штаты'), 'US');
    expect(directory.match('Киргизия'), 'KG');
    expect(directory.match('Кыргызстан'), 'KG');
    expect(directory.match('Holland'), 'NL');
    expect(directory.match('Абхазия'), isNull);
    expect(directory.match('Росс'), isNull);
    expect(directory.match(''), isNull);
  });

  test('search ranks prefix in interface language first', () {
    final ru = directory.search('гру', 'ru');
    expect(ru.first.code, 'GE');
    final en = directory.search('geo', 'en');
    expect(en.first.code, 'GE');
    // Синоним находит страну, хотя показанное название другое.
    expect(directory.search('holl', 'en').map((c) => c.code), contains('NL'));
    expect(directory.search('', 'ru').length, directory.all.length);
    expect(directory.search('zzzz', 'ru'), isEmpty);
  });

  test('empty search puts own countries first, then the alphabet', () {
    final list = directory.search(
      '',
      'ru',
      first: const ['CY', 'GE', 'ZZ', 'CY'],
    );
    expect(list.take(2).map((c) => c.code), ['CY', 'GE']);
    // Неизвестный код и повтор пропущены; остальные — по алфавиту, без
    // дублей своих стран.
    expect(list.length, directory.all.length);
    expect(list[2].code, directory.search('', 'ru').first.code);
    expect(list.where((c) => c.code == 'CY').length, 1);
    // Непустой запрос не зависит от своих стран.
    expect(directory.search('гру', 'ru', first: const ['CY']).first.code, 'GE');
  });

  test('display falls back to the entered text without a code', () {
    expect(directory.display('GE', 'Грузия', 'en'), 'Georgia');
    expect(directory.display(null, 'Абхазия', 'en'), 'Абхазия');
    expect(directory.display('ZZ', 'Нигде', 'ru'), 'Нигде');
  });
}
