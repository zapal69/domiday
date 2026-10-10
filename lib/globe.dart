import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'borders.dart';
import 'world_map.dart';

/// Ортографическая проекция: видимое полушарие шара, повёрнутого так,
/// что в центре экрана точка ([lon0], [lat0]) в градусах. Единичный
/// радиус; x вправо, y вверх (в экранные координаты переводит [Globe]).
class Orthographic {
  final double lon0, lat0;
  final double _sinLat0, _cosLat0, _lon0Rad;
  Orthographic(this.lon0, this.lat0)
    : _sinLat0 = sin(lat0 * pi / 180),
      _cosLat0 = cos(lat0 * pi / 180),
      _lon0Rad = lon0 * pi / 180;

  /// Косинус углового расстояния от центра: точка видна, если он > 0.
  double cosDistance(double lonDeg, double latDeg) {
    final lat = latDeg * pi / 180;
    final dLon = lonDeg * pi / 180 - _lon0Rad;
    return _sinLat0 * sin(lat) + _cosLat0 * cos(lat) * cos(dLon);
  }

  /// Проекция без проверки видимости: для скрытых точек (x, y) лежит
  /// внутри единичного круга, но на обратной стороне.
  Offset project(double lonDeg, double latDeg) {
    final lat = latDeg * pi / 180;
    final dLon = lonDeg * pi / 180 - _lon0Rad;
    final cosLat = cos(lat);
    return Offset(
      cosLat * sin(dLon),
      _cosLat0 * sin(lat) - _sinLat0 * cosLat * cos(dLon),
    );
  }

  /// Обратная проекция точки единичного круга в (lon, lat) в градусах;
  /// null вне шара.
  (double, double)? inverse(double x, double y) {
    final rho = sqrt(x * x + y * y);
    if (rho > 1) return null;
    if (rho < 1e-12) return (lon0, lat0);
    final c = asin(rho);
    final sinC = sin(c), cosC = cos(c);
    final lat = asin(cosC * _sinLat0 + y * sinC * _cosLat0 / rho);
    final lon =
        _lon0Rad +
        atan2(x * sinC, rho * _cosLat0 * cosC - y * _sinLat0 * sinC);
    var lonDeg = lon * 180 / pi;
    while (lonDeg > 180) {
      lonDeg -= 360;
    }
    while (lonDeg < -180) {
      lonDeg += 360;
    }
    return (lonDeg, lat * 180 / pi);
  }
}

/// Упрощение ломаной по Дугласу–Пекеру с допуском в градусах; концы
/// остаются на месте. Кольцо «lon, lat, lon, lat, …».
Float64List simplifyRing(Float64List ring, double tolerance) {
  final n = ring.length ~/ 2;
  if (n <= 4 || tolerance <= 0) return ring;
  final keep = Uint8List(n)..[0] = 1;
  keep[n - 1] = 1;
  final stack = <(int, int)>[(0, n - 1)];
  while (stack.isNotEmpty) {
    final (a, b) = stack.removeLast();
    if (b - a < 2) continue;
    final ax = ring[2 * a], ay = ring[2 * a + 1];
    final bx = ring[2 * b], by = ring[2 * b + 1];
    final dx = bx - ax, dy = by - ay;
    final len = sqrt(dx * dx + dy * dy);
    var best = -1.0, bi = a;
    for (var i = a + 1; i < b; i++) {
      final px = ring[2 * i], py = ring[2 * i + 1];
      final d = len == 0
          ? sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay))
          : (dx * (ay - py) - (ax - px) * dy).abs() / len;
      if (d > best) {
        best = d;
        bi = i;
      }
    }
    if (best > tolerance) {
      keep[bi] = 1;
      stack.add((a, bi));
      stack.add((bi, b));
    }
  }
  var count = 0;
  for (var i = 0; i < n; i++) {
    if (keep[i] == 1) count++;
  }
  final out = Float64List(count * 2);
  var j = 0;
  for (var i = 0; i < n; i++) {
    if (keep[i] == 1) {
      out[j++] = ring[2 * i];
      out[j++] = ring[2 * i + 1];
    }
  }
  return out;
}

/// Контур на шаре: кольца в градусах на нескольких уровнях детализации
/// (грубый для вращения, полный для крупного плана) и рамка в градусах.
class GlobeShape {
  final String key;
  final List<Float64List> rings;
  final double minLon, minLat, maxLon, maxLat;

  /// Центр самого большого кольца — куда ставится подпись и куда летит
  /// поиск.
  final double centerLon, centerLat;
  final _levels = <double, List<Float64List>>{};
  GlobeShape(this.key, this.rings)
    : minLon = _min(rings, 0),
      minLat = _min(rings, 1),
      maxLon = _max(rings, 0),
      maxLat = _max(rings, 1),
      centerLon = _center(rings).$1,
      centerLat = _center(rings).$2;

  static double _min(List<Float64List> rings, int k) {
    var v = double.infinity;
    for (final r in rings) {
      for (var i = k; i < r.length; i += 2) {
        if (r[i] < v) v = r[i];
      }
    }
    return v;
  }

  static double _max(List<Float64List> rings, int k) {
    var v = -double.infinity;
    for (final r in rings) {
      for (var i = k; i < r.length; i += 2) {
        if (r[i] > v) v = r[i];
      }
    }
    return v;
  }

  static (double, double) _center(List<Float64List> rings) {
    Float64List? best;
    var bestArea = -1.0;
    for (final r in rings) {
      var minX = double.infinity, minY = double.infinity;
      var maxX = -double.infinity, maxY = -double.infinity;
      for (var i = 0; i + 1 < r.length; i += 2) {
        if (r[i] < minX) minX = r[i];
        if (r[i] > maxX) maxX = r[i];
        if (r[i + 1] < minY) minY = r[i + 1];
        if (r[i + 1] > maxY) maxY = r[i + 1];
      }
      final area = (maxX - minX) * (maxY - minY);
      if (area > bestArea) {
        bestArea = area;
        best = r;
      }
    }
    if (best == null) return (0, 0);
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (var i = 0; i + 1 < best.length; i += 2) {
      if (best[i] < minX) minX = best[i];
      if (best[i] > maxX) maxX = best[i];
      if (best[i + 1] < minY) minY = best[i + 1];
      if (best[i + 1] > maxY) maxY = best[i + 1];
    }
    return ((minX + maxX) / 2, (minY + maxY) / 2);
  }

  /// Кольца, упрощённые с допуском [tolerance] градусов (0 — исходные);
  /// считаются один раз на уровень.
  List<Float64List> at(double tolerance) {
    if (tolerance <= 0) return rings;
    return _levels.putIfAbsent(tolerance, () {
      final out = <Float64List>[];
      for (final r in rings) {
        // Кольцо, которое при таком допуске меньше точки, — пропускаем.
        final s = simplifyRing(r, tolerance);
        if (s.length >= 8) out.add(s);
      }
      return out;
    });
  }

  /// Угловой размер страны в градусах (по «материку»): для подлёта.
  double get extent {
    final lat = centerLat * pi / 180;
    return max(maxLat - minLat, (maxLon - minLon) * cos(lat).abs());
  }
}

/// Данные шара: те же границы, что у плоской карты и определения страны.
class GlobeData {
  final List<GlobeShape> countries;
  final List<GlobeShape> disputed;

  /// Плоская карта — для цветов и попадания (тот же код страны).
  final WorldMapData flat;
  GlobeData._(this.countries, this.disputed, this.flat);

  factory GlobeData.build(CountryBorders borders, WorldMapData flat) =>
      GlobeData._(
        [for (final o in borders.outlines) GlobeShape(o.code, o.rings)],
        [for (final d in borders.disputed) GlobeShape(d.name, d.rings)],
        flat,
      );

  GlobeShape? shape(String code) =>
      countries.where((c) => c.key == code).firstOrNull;

  /// Уровни детализации: допуск в градусах по размеру пикселя в градусах.
  static const levels = [0.6, 0.2, 0.06, 0.0];
  static double levelFor(double degreesPerPixel) {
    for (final l in levels) {
      if (l <= degreesPerPixel * 0.7) return l;
    }
    return 0;
  }
}

/// Положение шара: центр (lon, lat) и зум (1 — шар вписан в область).
class GlobeView {
  final double lon, lat, zoom;
  const GlobeView({this.lon = 20, this.lat = 30, this.zoom = 1});
  GlobeView copyWith({double? lon, double? lat, double? zoom}) => GlobeView(
    lon: lon ?? this.lon,
    lat: lat ?? this.lat,
    zoom: zoom ?? this.zoom,
  );

  static const maxZoom = 40.0;
  static const minZoom = 0.9;

  GlobeView normalized() {
    var l = lon;
    while (l > 180) {
      l -= 360;
    }
    while (l < -180) {
      l += 360;
    }
    return GlobeView(
      lon: l,
      lat: lat.clamp(-89.0, 89.0),
      zoom: zoom.clamp(minZoom, maxZoom),
    );
  }

  /// Вид, при котором страна занимает примерно [fraction] меньшей
  /// стороны области [size].
  static GlobeView fit(GlobeShape s, Size size, {double fraction = .55}) {
    final radius = min(size.width, size.height) / 2 * 0.96;
    final px = radius * pi / 180; // пикселей на градус при зуме 1
    final extent = max(s.extent, 0.4);
    final zoom = fraction * min(size.width, size.height) / (px * extent);
    return GlobeView(lon: s.centerLon, lat: s.centerLat, zoom: zoom)
        .normalized();
  }

  static GlobeView lerp(GlobeView a, GlobeView b, double t) {
    var dLon = b.lon - a.lon;
    if (dLon > 180) dLon -= 360;
    if (dLon < -180) dLon += 360;
    return GlobeView(
      lon: a.lon + dLon * t,
      lat: a.lat + (b.lat - a.lat) * t,
      // Зум по логарифму: подлёт равномерный на глаз.
      zoom: exp(log(a.zoom) + (log(b.zoom) - log(a.zoom)) * t),
    );
  }
}

/// Управление шаром снаружи: подлёт к стране.
class GlobeController extends ValueNotifier<GlobeView> {
  GlobeController([super.view = const GlobeView()]);
  String? _pending;
  String? get pending => _pending;

  /// Повернуть шар к стране и приблизить; выполняется виджетом, который
  /// знает размер области.
  void focus(String code) {
    _pending = code;
    notifyListeners();
  }

  void _clearPending() => _pending = null;
}

/// Геометрия шара в области [size] при виде [view].
class Globe {
  final Size size;
  final GlobeView view;
  final Orthographic proj;
  final double radius;
  final Offset center;
  Globe(this.size, this.view)
    : proj = Orthographic(view.lon, view.lat),
      radius = min(size.width, size.height) / 2 * 0.96 * view.zoom,
      center = Offset(size.width / 2, size.height / 2);

  /// Градусов в одном экранном пикселе у центра.
  double get degreesPerPixel => 180 / pi / radius;

  Offset toScreen(double lon, double lat) {
    final p = proj.project(lon, lat);
    return Offset(center.dx + p.dx * radius, center.dy - p.dy * radius);
  }

  (double, double)? toGeo(Offset screen) => proj.inverse(
    (screen.dx - center.dx) / radius,
    -(screen.dy - center.dy) / radius,
  );

  /// Экранная область, в которой вообще есть шар.
  Rect get visibleRect => Rect.fromLTWH(0, 0, size.width, size.height);

  /// Может ли контур быть виден: хотя бы один из углов или центр рамки
  /// на ближней стороне (широкие страны считаются видимыми всегда).
  bool mayBeVisible(GlobeShape s) {
    if (s.maxLon - s.minLon > 150) return true;
    for (final (lon, lat) in [
      (s.minLon, s.minLat),
      (s.minLon, s.maxLat),
      (s.maxLon, s.minLat),
      (s.maxLon, s.maxLat),
      ((s.minLon + s.maxLon) / 2, (s.minLat + s.maxLat) / 2),
    ]) {
      if (proj.cosDistance(lon, lat) > -0.05) return true;
    }
    return false;
  }

  /// Путь контура на экране. Скрытые точки прижимаются к лимбу (краю
  /// диска) по своему направлению: у контуров, уходящих за горизонт,
  /// край проходит по хорде вдоль лимба, как в d3 без полного отсечения.
  /// Кольцо, скрытое целиком, не рисуется; вернёт null, если скрыт весь
  /// контур или он меньше пикселя.
  Path? path(GlobeShape s, double tolerance) {
    Path? path;
    for (final r in s.at(tolerance)) {
      final n = r.length ~/ 2;
      if (n < 3) continue;
      var anyVisible = false;
      var minX = double.infinity, minY = double.infinity;
      var maxX = -double.infinity, maxY = -double.infinity;
      final pts = Float64List(n * 2);
      for (var i = 0; i < n; i++) {
        final lon = r[2 * i], lat = r[2 * i + 1];
        var p = proj.project(lon, lat);
        if (proj.cosDistance(lon, lat) > 0) {
          anyVisible = true;
        } else {
          final d = p.distance;
          p = d < 1e-9 ? const Offset(1, 0) : p / d;
        }
        final x = center.dx + p.dx * radius, y = center.dy - p.dy * radius;
        pts[2 * i] = x;
        pts[2 * i + 1] = y;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
      if (!anyVisible) continue;
      if (maxX - minX < 0.8 && maxY - minY < 0.8) continue;
      if (maxX < -20 ||
          maxY < -20 ||
          minX > size.width + 20 ||
          minY > size.height + 20) {
        continue;
      }
      path ??= Path()..fillType = PathFillType.evenOdd;
      path.moveTo(pts[0], pts[1]);
      for (var i = 1; i < n; i++) {
        path.lineTo(pts[2 * i], pts[2 * i + 1]);
      }
      path.close();
    }
    return path;
  }
}

/// Рисует шар: воду, сетку, страны в цветах плоской карты, транзит
/// штриховкой, спорные территории пунктиром, подписи при увеличении.
class GlobePainter extends CustomPainter {
  final GlobeData data;
  final WorldMapStyle style;
  final GlobeView view;

  /// Во время жеста — грубый уровень детализации.
  final bool interacting;
  final Color water;
  final Color grid;
  GlobePainter({
    required this.data,
    required this.style,
    required this.view,
    required this.water,
    required this.grid,
    this.interacting = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final g = Globe(size, view);
    final disc = Path()
      ..addOval(Rect.fromCircle(center: g.center, radius: g.radius));
    canvas.save();
    canvas.clipPath(disc);
    canvas.drawPath(disc, Paint()..color = water);
    _graticule(canvas, g);
    var tolerance = GlobeData.levelFor(g.degreesPerPixel);
    if (interacting) {
      final i = GlobeData.levels.indexOf(tolerance);
      tolerance = GlobeData.levels[max(0, i - 1)];
    }
    final land = Paint()..color = style.land;
    final line = Paint()
      ..color = style.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final fill = Paint()..style = PaintingStyle.fill;
    final drawn = <GlobeShape, Path>{};
    for (final s in data.countries) {
      if (!g.mayBeVisible(s)) continue;
      final p = g.path(s, tolerance);
      if (p == null) continue;
      drawn[s] = p;
      final color = style.fills[s.key];
      canvas.drawPath(p, color == null ? land : (fill..color = color));
      if (color == null && style.transit.contains(s.key)) {
        _hatch(canvas, p, style.line);
      }
      canvas.drawPath(p, line);
    }
    for (final s in data.disputed) {
      if (!g.mayBeVisible(s)) continue;
      final p = g.path(s, tolerance);
      if (p == null) continue;
      canvas.drawPath(p, fill..color = style.land);
      final b = p.getBounds();
      if (b.width < 8 && b.height < 8) continue;
      _dash(canvas, p, style.disputedLine);
    }
    if (style.names.isNotEmpty && view.zoom > 1.6) _labels(canvas, g, drawn);
    // Тень у края: шар, а не круг.
    canvas.drawPath(
      disc,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.05,
          colors: [
            Colors.white.withValues(alpha: .10),
            Colors.transparent,
            Colors.black.withValues(alpha: .18),
          ],
          stops: const [0, .6, 1],
        ).createShader(Rect.fromCircle(center: g.center, radius: g.radius)),
    );
    canvas.restore();
    canvas.drawPath(
      disc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = style.line,
    );
  }

  void _graticule(Canvas canvas, Globe g) {
    final paint = Paint()
      ..color = grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final step = view.zoom > 8 ? 5 : (view.zoom > 3 ? 10 : 30);
    for (var lon = -180; lon < 180; lon += step) {
      _arc(canvas, g, paint, (t) => (lon.toDouble(), -90 + 180 * t));
    }
    for (var lat = -90 + step; lat < 90; lat += step) {
      _arc(canvas, g, paint, (t) => (-180 + 360 * t, lat.toDouble()));
    }
  }

  void _arc(
    Canvas canvas,
    Globe g,
    Paint paint,
    (double, double) Function(double t) at,
  ) {
    final path = Path();
    var pen = false;
    const n = 72;
    for (var i = 0; i <= n; i++) {
      final (lon, lat) = at(i / n);
      if (g.proj.cosDistance(lon, lat) <= 0) {
        pen = false;
        continue;
      }
      final p = g.toScreen(lon, lat);
      if (pen) {
        path.lineTo(p.dx, p.dy);
      } else {
        path.moveTo(p.dx, p.dy);
        pen = true;
      }
    }
    canvas.drawPath(path, paint);
  }

  void _labels(Canvas canvas, Globe g, Map<GlobeShape, Path> drawn) {
    for (final entry in drawn.entries) {
      final s = entry.key;
      final name = style.names[s.key];
      if (name == null) continue;
      if (g.proj.cosDistance(s.centerLon, s.centerLat) <= 0.05) continue;
      final width = s.extent * g.radius * pi / 180;
      if (width < 44) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: style.labelInk,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > width + 16) continue;
      final c = g.toScreen(s.centerLon, s.centerLat);
      if (!g.visibleRect.contains(c)) continue;
      final rect = Rect.fromCenter(
        center: c,
        width: tp.width + 6,
        height: tp.height + 3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = style.background.withValues(alpha: .72),
      );
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    }
  }

  void _hatch(Canvas canvas, Path path, Color color) {
    final b = path.getBounds();
    canvas.save();
    canvas.clipPath(path);
    final paint = Paint()
      ..color = color.withValues(alpha: .55)
      ..strokeWidth = 1.5;
    for (var x = b.left - b.height; x < b.right; x += 6) {
      canvas.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), paint);
    }
    canvas.restore();
  }

  void _dash(Canvas canvas, Path path, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const dash = 4.0, gap = 3.0;
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
  bool shouldRepaint(GlobePainter old) =>
      old.data != data ||
      old.view != view ||
      old.interacting != interacting ||
      old.style.fills != style.fills ||
      old.style.names != style.names ||
      old.style.land != style.land ||
      old.water != water;
}

/// Масштаб и сдвиг, которые забирают касание себе сразу, не споря с
/// прокруткой страницы: карта внутри списка иначе «замирает», когда
/// список выигрывает спор за палец. Страница прокручивается пальцем вне
/// карты. Нажатие распознаётся самим виджетом: короткое касание без
/// движения.
class EagerScaleGestureRecognizer extends ScaleGestureRecognizer {
  EagerScaleGestureRecognizer({super.debugOwner, super.supportedDevices});
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// Нажатие внутри жеста масштаба: один палец, сдвиг меньше 12 px, короче
/// 400 мс.
class TapWithinScale {
  Offset? _down;
  DateTime? _at;
  bool _alive = false;
  void start(ScaleStartDetails d) {
    _alive = d.pointerCount <= 1;
    _down = d.localFocalPoint;
    _at = DateTime.now();
  }

  void update(ScaleUpdateDetails d) {
    if (!_alive) return;
    if (d.pointerCount > 1 || (d.localFocalPoint - _down!).distance > 12) {
      _alive = false;
    }
  }

  /// Точка нажатия, если жест оказался нажатием, иначе null. Конец
  /// жеста при смене числа пальцев (второй палец лёг для щипка) —
  /// не нажатие: [d.pointerCount] тогда больше нуля.
  Offset? end(ScaleEndDetails d) {
    final tap =
        _alive &&
        d.pointerCount == 0 &&
        DateTime.now().difference(_at!).inMilliseconds < 400;
    _alive = false;
    return tap ? _down : null;
  }
}

/// Шар с жестами: один палец вращает (с инерцией), щипок увеличивает,
/// нажатие — страна, как на плоской карте (двойного нажатия нет, чтобы
/// одиночное срабатывало без задержки). Жест забирается сразу
/// ([EagerScaleGestureRecognizer]), поэтому шар работает и внутри
/// прокручиваемой страницы. [controller] позволяет подлететь к стране снаружи.
class GlobeWidget extends StatefulWidget {
  final GlobeData data;
  final WorldMapStyle style;
  final Color water;
  final Color grid;
  final GlobeController? controller;
  final ValueChanged<String>? onTap;
  final ValueChanged<List<String>>? onAmbiguous;
  final ValueChanged<double>? onZoom;
  const GlobeWidget({
    super.key,
    required this.data,
    required this.style,
    required this.water,
    required this.grid,
    this.controller,
    this.onTap,
    this.onAmbiguous,
    this.onZoom,
  });

  @override
  State<GlobeWidget> createState() => _GlobeWidgetState();
}

class _GlobeWidgetState extends State<GlobeWidget>
    with SingleTickerProviderStateMixin {
  late GlobeController _controller;
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  GlobeView? _from, _to;
  bool _interacting = false;
  GlobeView _gestureStart = const GlobeView();
  Offset _focalStart = Offset.zero;
  Size _size = Size.zero;
  Offset _velocity = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GlobeController();
    _controller.addListener(_external);
    _anim.addListener(() {
      final from = _from, to = _to;
      if (from == null || to == null) return;
      _controller.value = GlobeView.lerp(
        from,
        to,
        Curves.easeInOutCubic.transform(_anim.value),
      );
    });
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() {});
    });
  }

  @override
  void didUpdateWidget(GlobeWidget old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _controller.removeListener(_external);
      _controller = widget.controller ?? GlobeController();
      _controller.addListener(_external);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.removeListener(_external);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _external() {
    // Шар под другой страницей (вкладка под полным экраном) команду не
    // выполняет: его анимация заморожена, и она доиграла бы только после
    // возврата. Команду берёт тот шар, который виден.
    if (!TickerMode.valuesOf(context).enabled) return;
    final code = _controller.pending;
    if (code != null) {
      _controller._clearPending();
      final s = widget.data.shape(code);
      if (s != null && _size != Size.zero) {
        _flyTo(GlobeView.fit(s, _size));
        return;
      }
    }
    if (mounted) setState(() {});
  }

  void _flyTo(GlobeView target) {
    _from = _controller.value;
    _to = target;
    _anim.forward(from: 0);
    widget.onZoom?.call(target.zoom);
  }

  void _set(GlobeView v) {
    _controller.value = v.normalized();
  }

  final _tapper = TapWithinScale();

  void _scaleStart(ScaleStartDetails d) {
    _anim.stop();
    _tapper.start(d);
    _gestureStart = _controller.value;
    _focalStart = d.localFocalPoint;
    _velocity = Offset.zero;
    setState(() => _interacting = true);
  }

  void _scaleUpdate(ScaleUpdateDetails d) {
    _tapper.update(d);
    final zoom = (_gestureStart.zoom * d.scale).clamp(
      GlobeView.minZoom,
      GlobeView.maxZoom,
    );
    final g = Globe(_size, _gestureStart.copyWith(zoom: zoom));
    final delta = d.localFocalPoint - _focalStart;
    // Сдвиг пальца на радиус — поворот на радиан.
    final degPerPx = 180 / pi / g.radius;
    _set(
      _gestureStart.copyWith(
        lon: _gestureStart.lon - delta.dx * degPerPx,
        lat: _gestureStart.lat + delta.dy * degPerPx,
        zoom: zoom,
      ),
    );
    if (zoom != _gestureStart.zoom) widget.onZoom?.call(zoom);
  }

  void _scaleEnd(ScaleEndDetails d) {
    setState(() => _interacting = false);
    final tap = _tapper.end(d);
    if (tap != null) {
      _tap(tap);
      return;
    }
    _velocity = d.velocity.pixelsPerSecond;
    if (_velocity.distance < 80 || d.pointerCount > 1) return;
    // Инерция: докрутить шар в направлении свайпа с затуханием.
    final start = _controller.value;
    final g = Globe(_size, start);
    final degPerPx = 180 / pi / g.radius;
    final travel = _velocity * 0.18; // путь до остановки в пикселях
    _flyTo(
      start
          .copyWith(
            lon: start.lon - travel.dx * degPerPx,
            lat: start.lat + travel.dy * degPerPx,
          )
          .normalized(),
    );
  }

  void _tap(Offset local) {
    if (widget.onTap == null) return;
    final g = Globe(_size, _controller.value);
    final geo = g.toGeo(local);
    if (geo == null) return;
    // Радиус пальца (12 px экрана) в единицах плоского холста.
    final radius = 12 * g.degreesPerPixel * WorldMapData.width / 360 * 1.3;
    final r = resolveTap(
      widget.data.flat,
      WorldMapData.toCanvas(geo.$1, geo.$2),
      radius,
    );
    if (r.open != null) {
      widget.onTap!(r.open!);
    } else if (r.pick.isNotEmpty && widget.onAmbiguous != null) {
      widget.onAmbiguous!(r.pick);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          EagerScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                EagerScaleGestureRecognizer
              >(EagerScaleGestureRecognizer.new, (r) {
                r
                  ..onStart = _scaleStart
                  ..onUpdate = _scaleUpdate
                  ..onEnd = _scaleEnd;
              }),
        },
        child: ValueListenableBuilder<GlobeView>(
          valueListenable: _controller,
          builder: (context, view, _) => CustomPaint(
            key: const Key('globe'),
            painter: GlobePainter(
              data: widget.data,
              style: widget.style,
              view: view,
              water: widget.water,
              grid: widget.grid,
              interacting: _interacting || _anim.isAnimating,
            ),
            size: Size.infinite,
          ),
        ),
      );
    },
  );
}
