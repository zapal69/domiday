import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'trip.dart';

/// Страна из справочника ISO 3166-1 (assets/countries.json).
class Country {
  final String code;
  final String en;
  final String ru;
  final List<String> aliases;
  const Country({
    required this.code,
    required this.en,
    required this.ru,
    this.aliases = const [],
  });

  String name(String languageCode) => languageCode == 'ru' ? ru : en;

  /// Все написания, по которым текст сопоставляется с этой страной.
  Iterable<String> get spellings => [en, ru, ...aliases];
}

/// Офлайн-справочник: поиск по названию для выбора и однозначное
/// сопоставление старых текстовых записей с кодом.
class CountryDirectory {
  final List<Country> all;
  final Map<String, Country> _byCode;
  final Map<String, String> _byName;

  CountryDirectory(List<Country> countries)
    : all = List.unmodifiable(countries),
      _byCode = {for (final c in countries) c.code: c},
      _byName = {
        for (final c in countries)
          for (final s in c.spellings) normalize(s): c.code,
      };

  factory CountryDirectory.fromJson(String json) {
    final data = jsonDecode(json);
    if (data is! List) throw const FormatException('countries: список');
    return CountryDirectory([
      for (final item in data)
        if (item is Map<String, dynamic>)
          Country(
            code: item['code'] as String,
            en: item['en'] as String,
            ru: item['ru'] as String,
            aliases: [
              for (final a in (item['aliases'] as List?) ?? const []) '$a',
            ],
          ),
    ]);
  }

  static Future<CountryDirectory> load() async =>
      CountryDirectory.fromJson(await rootBundle.loadString(assetPath));

  static const assetPath = 'assets/countries.json';

  /// Пустой справочник: приложение работает, но коды не назначаются.
  static final empty = CountryDirectory(const []);

  Country? operator [](String? code) => code == null ? null : _byCode[code];

  bool contains(String? code) => code != null && _byCode.containsKey(code);

  /// Код только при точном (после нормализации) совпадении с названием
  /// или синонимом; догадок по подстроке нет.
  String? match(String text) {
    final key = normalize(text);
    if (key.isEmpty) return null;
    return _byName[key];
  }

  /// Название на языке интерфейса; без кода — введённый текст как есть.
  String display(String? code, String fallback, String languageCode) =>
      this[code]?.name(languageCode) ?? fallback;

  /// Поиск для выбора: сначала совпадения по началу названия на языке
  /// интерфейса, затем по началу любого написания, затем по подстроке.
  /// Пустой запрос — страны [first] в заданном порядке (свои: текущая,
  /// домашняя, недавние), затем все остальные по алфавиту.
  List<Country> search(
    String query,
    String languageCode, {
    List<String> first = const [],
  }) {
    final q = normalize(query);
    if (q.isEmpty) {
      // Множество: повторы кодов в [first] не дублируют строки.
      final top = {for (final code in first) ?this[code]};
      return [
        ...top,
        ...[
          for (final c in all)
            if (!top.contains(c)) c,
        ]..sort((a, b) => a.name(languageCode).compareTo(b.name(languageCode))),
      ];
    }
    int rank(Country c) {
      if (normalize(c.name(languageCode)).startsWith(q)) return 0;
      if (c.spellings.any((s) => normalize(s).startsWith(q))) return 1;
      if (c.spellings.any((s) => normalize(s).contains(q))) return 2;
      return 3;
    }

    final ranked =
        [
          for (final c in all)
            if (rank(c) < 3) (rank(c), c),
        ]..sort((a, b) {
          final byRank = a.$1.compareTo(b.$1);
          return byRank != 0
              ? byRank
              : a.$2.name(languageCode).compareTo(b.$2.name(languageCode));
        });
    return [for (final r in ranked) r.$2];
  }
}

class CountryScope extends InheritedWidget {
  final CountryDirectory directory;
  const CountryScope({
    super.key,
    required this.directory,
    required super.child,
  });

  static CountryDirectory of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CountryScope>()?.directory ??
      CountryDirectory.empty;

  @override
  bool updateShouldNotify(CountryScope old) => old.directory != directory;
}
