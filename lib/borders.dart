import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Результат определения страны по координатам. Только предположение:
/// в журнал ничего не пишется без подтверждения пользователя.
class Located {
  /// Код страны или null, если точка вне всех границ (море, пробел карты).
  final String? code;

  /// Рядом граница или побережье: в круге точности есть другая страна,
  /// либо точка вне границ и страна найдена только по соседству.
  final bool uncertain;
  final List<String> alternatives;
  const Located({
    required this.code,
    required this.uncertain,
    this.alternatives = const [],
  });

  static const none = Located(code: null, uncertain: true);
}

/// Контур страны для карты: код и кольца «lon, lat, lon, lat, …» в
/// градусах (внешние и дырки вместе, правило чётности).
class CountryOutline {
  final String code;
  final List<Float64List> rings;
  const CountryOutline(this.code, this.rings);
}

/// Спорная территория (Natural Earth, слой breakaway/disputed areas):
/// на карте не приписывается никому и обводится пунктиром, при
/// определении страны предлагаются обе стороны — как на картах Google
/// для «нейтрального» зрителя. [admin] — кто фактически управляет (null —
/// самопровозглашённая), [claims] — кто претендует.
class DisputedArea {
  final String name;
  final String? admin;
  final List<String> claims;
  final _Region _region;
  DisputedArea._(this.name, this.admin, this.claims, this._region);
  List<Float64List> get rings => _region.rings;

  /// Стороны спора в порядке: управляющая, затем претенденты.
  List<String> get parties => [
    ?admin,
    for (final c in claims)
      if (c != admin) c,
  ];
}

class _Region {
  final String code;
  final double minLon, minLat, maxLon, maxLat;
  final List<Float64List> rings;
  _Region(this.code, List<num> bbox, this.rings)
    : minLon = bbox[0].toDouble(),
      minLat = bbox[1].toDouble(),
      maxLon = bbox[2].toDouble(),
      maxLat = bbox[3].toDouble();

  bool inBox(double lat, double lon, double pad) =>
      lon >= minLon - pad &&
      lon <= maxLon + pad &&
      lat >= minLat - pad &&
      lat <= maxLat + pad;

  /// Правило чётности по всем кольцам: дырки (Лесото в ЮАР) учитываются.
  bool contains(double lat, double lon) {
    var inside = false;
    for (final r in rings) {
      final n = r.length ~/ 2;
      for (var i = 0, j = n - 1; i < n; j = i++) {
        final xi = r[2 * i], yi = r[2 * i + 1];
        final xj = r[2 * j], yj = r[2 * j + 1];
        if ((yi > lat) != (yj > lat) &&
            lon < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
          inside = !inside;
        }
      }
    }
    return inside;
  }
}

/// Офлайн-границы стран (assets/borders.json, Natural Earth 1:50m).
class CountryBorders {
  final List<_Region> _regions;
  final List<DisputedArea> disputed;
  CountryBorders._(this._regions, [this.disputed = const []]);

  static const assetPath = 'assets/borders.json';
  static const disputedPath = 'assets/disputed.json';

  /// Границы плюс, если есть, слой спорных территорий (без него карта и
  /// определение работают как раньше).
  static Future<CountryBorders> load() async {
    final borders = await rootBundle.loadString(assetPath);
    String? disputed;
    try {
      disputed = await rootBundle.loadString(disputedPath);
    } catch (_) {
      disputed = null;
    }
    return CountryBorders.fromJson(borders, disputedJson: disputed);
  }

  static List<Float64List> _rings(List raw) => [
    for (final r in raw)
      Float64List.fromList(
        (r as List).cast<num>().map((v) => v.toDouble()).toList(),
      ),
  ];

  factory CountryBorders.fromJson(String json, {String? disputedJson}) {
    final data = jsonDecode(json);
    if (data is! Map || data['countries'] is! List) {
      throw const FormatException('borders: неверный формат');
    }
    final regions = [
      for (final c in data['countries'] as List)
        _Region(
          c['code'] as String,
          (c['bbox'] as List).cast<num>(),
          _rings(c['rings'] as List),
        ),
    ];
    final disputed = <DisputedArea>[];
    if (disputedJson != null) {
      final d = jsonDecode(disputedJson);
      if (d is! Map || d['areas'] is! List) {
        throw const FormatException('disputed: неверный формат');
      }
      for (final a in d['areas'] as List) {
        disputed.add(
          DisputedArea._(
            a['name'] as String,
            a['admin'] as String?,
            (a['claims'] as List).cast<String>(),
            _Region(
              a['name'] as String,
              (a['bbox'] as List).cast<num>(),
              _rings(a['rings'] as List),
            ),
          ),
        );
      }
    }
    return CountryBorders._(regions, disputed);
  }

  static final empty = CountryBorders._(const []);

  int get count => _regions.length;

  /// Контуры всех стран для карты.
  List<CountryOutline> get outlines => [
    for (final r in _regions) CountryOutline(r.code, r.rings),
  ];

  /// Спорная территория, содержащая точку, или null.
  DisputedArea? disputedAt(double lat, double lon) {
    for (final d in disputed) {
      if (d._region.inBox(lat, lon, 0) && d._region.contains(lat, lon)) {
        return d;
      }
    }
    return null;
  }

  /// Код страны, содержащей точку, или null. Если точку содержат
  /// несколько стран (анклав без дырки в соседе на карте 1:50m —
  /// Ватикан в Италии), побеждает меньшая по охвату.
  String? containing(double lat, double lon) {
    _Region? best;
    double bestArea = double.infinity;
    for (final r in _regions) {
      if (!r.inBox(lat, lon, 0) || !r.contains(lat, lon)) continue;
      final area = (r.maxLon - r.minLon) * (r.maxLat - r.minLat);
      if (area < bestArea) {
        best = r;
        bestArea = area;
      }
    }
    return best?.code;
  }

  /// Страна по координатам с учётом точности: вокруг точки проверяются
  /// 8 направлений на радиусе max(точность, 3 км). Другая страна в этом
  /// круге — «неуверенно». Точка вне границ ищет соседей в радиусе 10 км.
  Located locate(double lat, double lon, {double accuracyM = 0}) {
    if (_regions.isEmpty) return Located.none;
    final here = containing(lat, lon);
    final radius = accuracyM.clamp(3000.0, 50000.0);
    final around = _around(lat, lon, radius);
    // Спорная территория: страну не выбираем за пользователя — первой
    // идёт та, что есть в базовых границах (или управляющая), остальные
    // стороны спора и соседи — альтернативами, отметка «неуверенно».
    final area = disputedAt(lat, lon);
    if (area != null) {
      final parties = area.parties;
      final first = here ?? (parties.isNotEmpty ? parties.first : null);
      if (first != null) {
        final others = <String>{...parties, ...around}..remove(first);
        return Located(
          code: first,
          uncertain: true,
          alternatives: others.toList()..sort(),
        );
      }
    }
    if (here != null) {
      final others = around.where((c) => c != here).toList()..sort();
      return Located(
        code: here,
        uncertain: others.isNotEmpty,
        alternatives: others,
      );
    }
    final near = _around(lat, lon, max(radius, 10000.0)).toList()..sort();
    if (near.isEmpty) return Located.none;
    return Located(
      code: near.first,
      uncertain: true,
      alternatives: near.skip(1).toList(),
    );
  }

  Set<String> _around(double lat, double lon, double radiusM) {
    final found = <String>{};
    final dLat = radiusM / 111320.0;
    final cosLat = cos(lat * pi / 180).abs().clamp(0.01, 1.0);
    final dLon = radiusM / (111320.0 * cosLat);
    for (var b = 0; b < 360; b += 45) {
      final rad = b * pi / 180;
      final c = containing(lat + dLat * cos(rad), lon + dLon * sin(rad));
      if (c != null) found.add(c);
    }
    return found;
  }
}
