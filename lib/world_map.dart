import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'borders.dart';

/// Проекция Equal Earth (Šavrič, Patterson, Jenny, 2018): равновеликая,
/// без раздутых полюсов — как в атласе. Формулы прямого преобразования
/// из d3-geo; обратное не нужно: попадание проверяется по контуру.
class EqualEarth {
  static const _a1 = 1.340264;
  static const _a2 = -0.081106;
  static const _a3 = 0.000893;
  static const _a4 = 0.003796;
  static final _m = sqrt(3) / 2;

  /// Полуширина и полувысота проекции в её единицах.
  static const halfWidth = 2.7066;
  static const halfHeight = 1.3173;

  /// x вправо, y вниз (экранные координаты), центр карты — (0, 0).
  static Offset project(double lonDeg, double latDeg) {
    final lon = lonDeg * pi / 180;
    final lat = latDeg * pi / 180;
    final theta = asin(_m * sin(lat));
    final t2 = theta * theta;
    final t6 = t2 * t2 * t2;
    final x =
        lon *
        cos(theta) /
        (_m * (_a1 + 3 * _a2 * t2 + t6 * (7 * _a3 + 9 * _a4 * t2)));
    final y = theta * (_a1 + _a2 * t2 + t6 * (_a3 + _a4 * t2));
    return Offset(x, -y);
  }
}

/// Контур на карте: код (страны) или имя (спорной территории), путь в
/// координатах холста [WorldMapData.width] × [WorldMapData.height] и его
/// рамка для быстрого попадания.
class MapShape {
  final String key;
  final Path path;
  final Rect bounds;

  /// Рамка самого большого кольца — «материк» страны: туда ставится
  /// подпись (у Франции с заморскими территориями центр общей рамки
  /// пришёлся бы на Атлантику).
  final Rect main;
  MapShape(this.key, this.path, {Rect? main})
    : bounds = path.getBounds(),
      main = main ?? path.getBounds();
}

/// Палитра политической карты: восемь приглушённых атласных цветов.
/// Индекс 0 — красновато-розовый, каким на школьных картах принято
/// красить Россию.
const politicalPalette = [
  Color(0xFFE0837A), // красновато-розовый
  Color(0xFFF0C95C), // жёлтый
  Color(0xFF8CC08A), // зелёный
  Color(0xFF7FAEE6), // голубой
  Color(0xFFEDA55C), // оранжевый
  Color(0xFFB39AE0), // сиреневый
  Color(0xFF6CC4B8), // бирюзовый
  Color(0xFFD1A87A), // песочный
];

/// Закреплённые цвета крупных стран — как на привычной политической
/// карте; остальные раскрашиваются жадно так, чтобы соседи различались.
const _politicalSeeds = {
  'RU': 0,
  'CN': 1,
  'US': 2,
  'CA': 4,
  'BR': 2,
  'AU': 4,
  'IN': 4,
  'KZ': 5,
  'MN': 3,
  'UA': 1,
  'BY': 2,
  'TR': 6,
  'IR': 2,
  'SA': 1,
  'EG': 4,
  'DZ': 3,
  'LY': 1,
  'SD': 2,
  'CD': 4,
  'ZA': 1,
  'AR': 3,
  'MX': 3,
  'GE': 7,
  'AM': 4,
  'AZ': 3,
  'CY': 4,
  'GB': 5,
  'FR': 3,
  'DE': 1,
  'ES': 4,
  'IT': 2,
  'PL': 4,
  'SE': 1,
  'NO': 3,
  'FI': 2,
  'JP': 0,
  'ID': 5,
  'TH': 5,
  'GR': 6,
  'RO': 2,
  'BG': 4,
};

/// Пути всех стран и спорных территорий, построенные один раз из
/// [CountryBorders] (тот же файл, что и определение страны — карта и
/// детектор не расходятся), и раскраска политической карты.
class WorldMapData {
  static const width = 1000.0;
  static const height = width * EqualEarth.halfHeight / EqualEarth.halfWidth;

  final List<MapShape> countries;
  final List<MapShape> disputed;

  /// Индекс цвета [politicalPalette] для каждой страны.
  final Map<String, int> colorIndex;
  WorldMapData._(this.countries, this.disputed, this.colorIndex);

  factory WorldMapData.build(CountryBorders borders) {
    final countries = [
      for (final o in borders.outlines)
        MapShape(o.code, _path(o.rings), main: _mainRing(o.rings)),
    ];
    return WorldMapData._(countries, [
      for (final d in borders.disputed) MapShape(d.name, _path(d.rings)),
    ], _colour(countries));
  }

  /// Цвет страны на политической карте.
  Color politicalColor(String code) =>
      politicalPalette[colorIndex[code] ??
          code.hashCode % politicalPalette.length];

  /// Жадная раскраска: соседи — те, чьи рамки (чуть расширенные)
  /// пересекаются; крупные страны с закреплёнными цветами идут первыми,
  /// остальные по убыванию размера получают первый цвет, свободный у
  /// соседей. Детерминировано: один и тот же результат на каждом запуске.
  static Map<String, int> _colour(List<MapShape> countries) {
    final byArea = [...countries]
      ..sort((a, b) => _area(b.bounds).compareTo(_area(a.bounds)));
    final result = <String, int>{..._politicalSeeds};
    final n = politicalPalette.length;
    for (final s in byArea) {
      if (result.containsKey(s.key) && _politicalSeeds.containsKey(s.key)) {
        continue;
      }
      final box = s.bounds.inflate(3);
      final taken = <int>{};
      for (final o in countries) {
        if (o.key == s.key || !o.bounds.inflate(3).overlaps(box)) continue;
        final c = result[o.key];
        if (c != null) taken.add(c);
      }
      var pick = s.key.hashCode % n;
      for (var i = 0; i < n; i++) {
        final c = (pick + i) % n;
        if (!taken.contains(c)) {
          pick = c;
          break;
        }
      }
      result[s.key] = pick;
    }
    return result;
  }

  static Offset toCanvas(double lon, double lat) {
    final p = EqualEarth.project(lon, lat);
    final s = width / (2 * EqualEarth.halfWidth);
    return Offset(width / 2 + p.dx * s, height / 2 + p.dy * s);
  }

  /// Рамка самого большого по площади кольца в координатах холста.
  static Rect? _mainRing(List<Float64List> rings) {
    Rect? best;
    for (final r in rings) {
      final n = r.length ~/ 2;
      if (n < 3) continue;
      var minX = double.infinity, minY = double.infinity;
      var maxX = -double.infinity, maxY = -double.infinity;
      for (var i = 0; i < n; i++) {
        final p = toCanvas(r[2 * i], r[2 * i + 1]);
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
      final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
      if (best == null || _area(rect) > _area(best)) best = rect;
    }
    return best;
  }

  static Path _path(List<Float64List> rings) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final r in rings) {
      final n = r.length ~/ 2;
      if (n < 3) continue;
      var prevLon = r[0];
      path.moveTo(toCanvas(r[0], r[1]).dx, toCanvas(r[0], r[1]).dy);
      for (var i = 1; i < n; i++) {
        final lon = r[2 * i], lat = r[2 * i + 1];
        final p = toCanvas(lon, lat);
        // Скачок через антимеридиан — новая подкривая, а не линия через
        // всю карту (контуры Natural Earth уже разрезаны по 180°, это
        // страховка).
        if ((lon - prevLon).abs() > 180) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
        prevLon = lon;
      }
      path.close();
    }
    return path;
  }

  /// Страна под точкой холста; при вложенности побеждает меньшая рамка
  /// (Лесото внутри ЮАР).
  String? hitTest(Offset p) {
    MapShape? best;
    for (final s in countries) {
      if (!s.bounds.contains(p) || !s.path.contains(p)) continue;
      if (best == null || _area(s.bounds) < _area(best.bounds)) best = s;
    }
    return best?.key;
  }

  /// Мелкие страны (короче полутора [radius] по обеим сторонам), чья рамка
  /// попадает в круг радиуса [radius] вокруг точки, ближние первыми:
  /// уточняющий список для тех, в кого трудно попасть пальцем.
  List<String> near(Offset p, double radius) {
    final box = Rect.fromCircle(center: p, radius: radius);
    final hits =
        [
          for (final s in countries)
            if (s.bounds.overlaps(box) && isTiny(s, radius)) s,
        ]..sort(
          (a, b) => (a.bounds.center - p).distance.compareTo(
            (b.bounds.center - p).distance,
          ),
        );
    return [for (final s in hits) s.key];
  }

  /// Контур, в который не попасть пальцем радиуса [radius] без зума.
  bool isTiny(MapShape s, double radius) =>
      max(s.bounds.width, s.bounds.height) < 1.5 * radius;

  MapShape? shape(String code) =>
      countries.where((c) => c.key == code).firstOrNull;

  static double _area(Rect r) => r.width * r.height;
}

/// Раскраска карты: заливки посещённых стран по коду, транзитные страны
/// (штриховка), цвета суши, линий и спорных территорий.
class WorldMapStyle {
  final Map<String, Color> fills;
  final Set<String> transit;

  /// Домашняя страна: свой цвет, как у всех, плюс жирная обводка.
  final String? home;
  final Color land;
  final Color line;
  final Color disputedLine;
  final Color background;

  /// Названия стран по коду для подписей и текущий зум просмотра:
  /// подписи появляются при зуме больше 1,2 у тех стран, где помещаются.
  final Map<String, String> names;
  final double zoom;
  final Color labelInk;
  const WorldMapStyle({
    required this.fills,
    this.transit = const {},
    this.home,
    required this.land,
    required this.line,
    required this.disputedLine,
    required this.background,
    this.names = const {},
    this.zoom = 1,
    this.labelInk = const Color(0xFF272821),
  });
}

class WorldMapPainter extends CustomPainter {
  final WorldMapData data;
  final WorldMapStyle style;
  WorldMapPainter(this.data, this.style);

  /// Базовый слой (суша и границы) рисуется один раз на цвета темы.
  static final _base = <String, ui.Picture>{};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / WorldMapData.width;
    canvas.save();
    canvas.scale(scale, scale);
    canvas.drawPicture(_basePicture());
    final fill = Paint()..style = PaintingStyle.fill;
    for (final s in data.countries) {
      final color = style.fills[s.key];
      if (color != null) {
        canvas.drawPath(s.path, fill..color = color);
      } else if (style.transit.contains(s.key)) {
        _hatch(canvas, s.path, style.line, spacing: 6 / scale);
      }
    }
    if (style.zoom > 1.2 && style.names.isNotEmpty) _labels(canvas, scale);
    // Спорные территории: нейтральная суша поверх любой заливки и
    // пунктирная граница — как на нейтральной карте Google.
    final px = 1 / scale;
    for (final s in data.disputed) {
      canvas.drawPath(s.path, fill..color = style.land);
      // Совсем мелкие (меньше 8 px на экране) — только нейтральная
      // заливка: пунктир на них превращается в пятно.
      if (s.bounds.width < 8 * px && s.bounds.height < 8 * px) continue;
      _dash(canvas, s.path, style.disputedLine, width: 0.8 * px);
    }
    canvas.restore();
  }

  /// Подписи стран при зуме: размер шрифта постоянный на экране (11 px),
  /// подпись ставится на «материк» и только если помещается в его ширину.
  void _labels(Canvas canvas, double scale) {
    final screen = scale * style.zoom;
    final fontSize = 11 / screen;
    final pad = 3 / screen;
    for (final s in data.countries) {
      final name = style.names[s.key];
      if (name == null) continue;
      if (s.main.width * screen < 44) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: style.labelInk,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > s.main.width + 16 / screen) continue;
      final c = s.main.center;
      final rect = Rect.fromCenter(
        center: c,
        width: tp.width + 2 * pad,
        height: tp.height + pad,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(3 / screen)),
        Paint()..color = style.background.withValues(alpha: .72),
      );
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    }
  }

  ui.Picture _basePicture() {
    final key = '${style.land.toARGB32()}-${style.line.toARGB32()}';
    return _base.putIfAbsent(key, () {
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      final land = Paint()..color = style.land;
      final line = Paint()
        ..color = style.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      for (final s in data.countries) {
        c.drawPath(s.path, land);
        c.drawPath(s.path, line);
      }
      return recorder.endRecording();
    });
  }

  void _hatch(
    Canvas canvas,
    Path path,
    Color color, {
    required double spacing,
  }) {
    final b = path.getBounds();
    canvas.save();
    canvas.clipPath(path);
    final paint = Paint()
      ..color = color.withValues(alpha: .55)
      ..strokeWidth = spacing / 4;
    for (var x = b.left - b.height; x < b.right; x += spacing) {
      canvas.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), paint);
    }
    canvas.restore();
  }

  void _dash(Canvas canvas, Path path, Color color, {required double width}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final dash = width * 5, gap = width * 4;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = min(d + dash, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(WorldMapPainter old) =>
      old.data != data ||
      old.style.fills != style.fills ||
      old.style.home != style.home ||
      old.style.zoom != style.zoom ||
      old.style.names != style.names ||
      old.style.land != style.land;
}

/// Что открыть по нажатию в точке холста [p] с радиусом пальца [radius]
/// (в единицах холста): код страны или список ближних мелких стран.
/// Попали внутрь мелкой — открываем её; попали в крупную рядом с мелкими
/// или в море — список; иначе крупную.
({String? open, List<String> pick}) resolveTap(
  WorldMapData data,
  Offset p,
  double radius,
) {
  final hit = data.hitTest(p);
  final hitShape = hit == null ? null : data.shape(hit);
  final small = data.near(p, radius)..remove(hit);
  final hitTiny = hitShape != null && data.isTiny(hitShape, radius);
  if (hit != null && (hitTiny || small.isEmpty)) {
    return (open: hit, pick: const []);
  }
  if (small.isNotEmpty) return (open: null, pick: [?hit, ...small.take(5)]);
  return (open: hit, pick: const []);
}

/// Карта мира с заливками; [onTap] получает код страны под пальцем, а
/// [onAmbiguous] — список ближних мелких стран, если под пальцем пусто
/// или несколько кандидатов рядом.
class WorldMap extends StatelessWidget {
  final WorldMapData data;
  final WorldMapStyle style;
  final ValueChanged<String>? onTap;
  final ValueChanged<List<String>>? onAmbiguous;
  const WorldMap({
    super.key,
    required this.data,
    required this.style,
    this.onTap,
    this.onAmbiguous,
  });

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: WorldMapData.width / WorldMapData.height,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scale = WorldMapData.width / constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTap == null
              ? null
              : (d) {
                  final r = resolveTap(data, d.localPosition * scale, 12 * scale);
                  if (r.open != null) {
                    onTap!(r.open!);
                  } else if (r.pick.isNotEmpty && onAmbiguous != null) {
                    onAmbiguous!(r.pick);
                  }
                },
          child: CustomPaint(
            key: const Key('worldMap'),
            painter: WorldMapPainter(data, style),
            size: Size.infinite,
          ),
        );
      },
    ),
  );
}
