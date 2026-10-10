part of 'main.dart';

/// Заливки карты по дневнику: посещённые страны (пребывания) — цветом
/// политической карты ([WorldMapData.politicalColor]), страны только с
/// транзитом — штриховкой, дом — тем же цветом с жирной обводкой.
/// [year] ограничивает выбранным годом, null — за всё время.
class MapFills {
  final Map<String, Color> fills;
  final Set<String> transit;

  /// Коды посещённых стран (с пребыванием), включая дом.
  final List<String> visited;
  final String? home;

  /// Дни по коду страны (пребывания) — для подписей в поиске.
  final Map<String, int> days;
  const MapFills(
    this.fills,
    this.transit,
    this.visited,
    this.home, {
    this.days = const {},
  });

  static MapFills of(
    WorldMapData data,
    JournalSnapshot snapshot,
    Day today, {
    int? year,
  }) {
    var trips = snapshot.knownTrips(today);
    if (year != null) {
      trips = trips
          .where((t) => t.arrival.year <= year && t.departure.year >= year)
          .toList();
    }
    final stats = countryStats(trips, year: year).where((s) => s.days > 0);
    final fills = <String, Color>{};
    final transit = <String>{};
    final visited = <String>[];
    final days = <String, int>{};
    String? home;
    for (final s in stats) {
      final code = s.code;
      if (code == null) continue;
      if (s.transits == s.trips) {
        transit.add(code);
        continue;
      }
      visited.add(code);
      days[code] = s.days;
      fills[code] = data.politicalColor(code);
      if (s.key == snapshot.homeKey) home = code;
    }
    return MapFills(fills, transit, visited, home, days: days);
  }
}

WorldMapStyle _mapStyle(
  BuildContext context,
  MapFills f, {
  Map<String, String> names = const {},
  double zoom = 1,
}) {
  final colors = DomidayColors.of(context);
  final scheme = Theme.of(context).colorScheme;
  return WorldMapStyle(
    fills: f.fills,
    transit: f.transit,
    home: f.home,
    land: colors.track,
    line: colors.unknown,
    disputedLine: scheme.onSurface,
    background: scheme.surface,
    names: names,
    zoom: zoom,
    labelInk: scheme.onSurface,
  );
}

/// Названия всех стран карты на языке интерфейса — для подписей при зуме.
Map<String, String> _mapNames(BuildContext context, WorldMapData data) {
  final directory = CountryScope.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  return {
    for (final s in data.countries)
      s.key: directory.display(s.key, s.key, lang),
  };
}

/// Запрос «показать страну» для плоской карты: поиск ставит код, карта
/// увеличивает и центрирует его.
class MapFocus extends ChangeNotifier {
  String? code;
  void request(String c) {
    code = c;
    notifyListeners();
  }
}

/// Плоская карта на вкладке: внутри прокручиваемой страницы, поэтому
/// жест забирается сразу ([EagerScaleGestureRecognizer]), а не через
/// InteractiveViewer, который проигрывал спор списку. Щипок до 12×, сдвиг
/// в пределах карты, нажатие — страна, поиск ([MapFocus]) — плавный
/// подлёт.
class _CardMap extends StatefulWidget {
  final WorldMapData data;
  final MapFills fills;
  final Map<String, String> names;
  final ValueChanged<String> onTap;
  final ValueChanged<List<String>> onAmbiguous;
  final MapFocus focus;
  const _CardMap({
    required this.data,
    required this.fills,
    required this.names,
    required this.onTap,
    required this.onAmbiguous,
    required this.focus,
  });
  @override
  State<_CardMap> createState() => _CardMapState();
}

class _CardMapState extends State<_CardMap>
    with SingleTickerProviderStateMixin {
  static const maxScale = 12.0;
  final _transform = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  Matrix4? _from, _to;
  Matrix4 _gestureStart = Matrix4.identity();
  Offset _focalStart = Offset.zero;
  final _tapper = TapWithinScale();
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_focus);
    _anim.addListener(() {
      final from = _from, to = _to;
      if (from == null || to == null) return;
      _transform.value = Matrix4Tween(begin: from, end: to).transform(
        Curves.easeInOutCubic.transform(_anim.value),
      );
    });
  }

  @override
  void didUpdateWidget(_CardMap old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus) {
      old.focus.removeListener(_focus);
      widget.focus.addListener(_focus);
    }
  }

  @override
  void dispose() {
    widget.focus.removeListener(_focus);
    _anim.dispose();
    _transform.dispose();
    super.dispose();
  }

  double get _k => _viewport.width / WorldMapData.width;

  /// Сдвиг в пределах карты: за края не уводим.
  Matrix4 _clamped(Matrix4 m) {
    final k = m.storage[0];
    final tx = m.storage[12]
        .clamp(min(0.0, _viewport.width - _viewport.width * k), 0.0)
        .toDouble();
    final ty = m.storage[13]
        .clamp(min(0.0, _viewport.height - _viewport.height * k), 0.0)
        .toDouble();
    return m.clone()
      ..storage[12] = tx
      ..storage[13] = ty;
  }

  void _focus() {
    final shape = widget.data.shape(widget.focus.code ?? '');
    if (shape == null || _viewport == Size.zero) return;
    final r = shape.main;
    final target = Rect.fromLTWH(
      r.left * _k,
      r.top * _k,
      max(r.width * _k, 1),
      max(r.height * _k, 1),
    );
    final scale =
        (0.5 *
                min(_viewport.width, _viewport.height) /
                max(target.width, target.height))
            .clamp(1.0, maxScale);
    final m = Matrix4.identity()
      ..translateByDouble(
        _viewport.width / 2 - target.center.dx * scale,
        _viewport.height / 2 - target.center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    _from = _transform.value.clone();
    _to = _clamped(m);
    _anim.forward(from: 0);
  }

  void _start(ScaleStartDetails d) {
    _anim.stop();
    _tapper.start(d);
    _gestureStart = _transform.value.clone();
    _focalStart = d.localFocalPoint;
  }

  void _update(ScaleUpdateDetails d) {
    _tapper.update(d);
    final startScale = _gestureStart.storage[0];
    final scale = (startScale * d.scale).clamp(1.0, maxScale) / startScale;
    final f = d.localFocalPoint;
    // Точка карты под пальцами в начале жеста остаётся под ними,
    // масштаб вокруг неё.
    final m = Matrix4.identity()
      ..translateByDouble(f.dx, f.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-_focalStart.dx, -_focalStart.dy, 0, 1);
    _transform.value = _clamped(m.multiplied(_gestureStart));
  }

  void _end(ScaleEndDetails d) {
    final tap = _tapper.end(d);
    if (tap == null) return;
    final m = Matrix4.inverted(_transform.value);
    final child = MatrixUtils.transformPoint(m, tap);
    final zoom = _transform.value.storage[0];
    final r = resolveTap(widget.data, child / _k, 12 / _k / zoom);
    if (r.open != null) {
      widget.onTap(r.open!);
    } else if (r.pick.isNotEmpty) {
      widget.onAmbiguous(r.pick);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      _viewport = Size(width, width * WorldMapData.height / WorldMapData.width);
      return SizedBox(
        width: _viewport.width,
        height: _viewport.height,
        child: ClipRect(
          child: RawGestureDetector(
            key: const Key('cardMap'),
            behavior: HitTestBehavior.opaque,
            gestures: {
              EagerScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    EagerScaleGestureRecognizer
                  >(EagerScaleGestureRecognizer.new, (r) {
                    r
                      ..onStart = _start
                      ..onUpdate = _update
                      ..onEnd = _end;
                  }),
            },
            child: ValueListenableBuilder<Matrix4>(
              valueListenable: _transform,
              builder: (context, m, _) => Transform(
                transform: m,
                child: WorldMap(
                  data: widget.data,
                  style: _mapStyle(
                    context,
                    widget.fills,
                    names: widget.names,
                    zoom: m.storage[0],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Карта в InteractiveViewer на весь экран: знает текущий зум и передаёт
/// его в стиль, подписи стран появляются при увеличении.
class _ZoomableMap extends StatefulWidget {
  final WorldMapData data;
  final MapFills fills;
  final Map<String, String> names;
  final double maxScale;
  final bool constrained;
  final double? width;
  final double? height;

  /// Ширина самой карты внутри области [width] × [height].
  final double? mapWidth;
  final ValueChanged<String> onTap;
  final ValueChanged<List<String>> onAmbiguous;
  final MapFocus? focus;
  const _ZoomableMap({
    required this.data,
    required this.fills,
    required this.names,
    required this.onTap,
    required this.onAmbiguous,
    this.maxScale = 8,
    this.constrained = true,
    this.width,
    this.height,
    this.mapWidth,
    this.focus,
  });
  @override
  State<_ZoomableMap> createState() => _ZoomableMapState();
}

class _ZoomableMapState extends State<_ZoomableMap> {
  final _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    widget.focus?.addListener(_focus);
  }

  @override
  void didUpdateWidget(_ZoomableMap old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus) {
      old.focus?.removeListener(_focus);
      widget.focus?.addListener(_focus);
    }
  }

  @override
  void dispose() {
    widget.focus?.removeListener(_focus);
    _transform.dispose();
    super.dispose();
  }

  /// Страна в центр области и увеличить так, чтобы она заняла около
  /// половины; в ограниченном режиме карта не уходит за края.
  void _focus() {
    final code = widget.focus?.code;
    final shape = code == null ? null : widget.data.shape(code);
    final box = context.findRenderObject() as RenderBox?;
    if (shape == null || box == null || !box.hasSize) return;
    final viewport = box.size;
    final mapWidth = widget.mapWidth ?? viewport.width;
    final k = mapWidth / WorldMapData.width;
    final mapHeight = WorldMapData.height * k;
    final childSize = widget.width == null
        ? Size(mapWidth, mapHeight)
        : Size(widget.width!, widget.height!);
    final origin = Offset(
      (childSize.width - mapWidth) / 2,
      (childSize.height - mapHeight) / 2,
    );
    final r = shape.main;
    final target = Rect.fromLTWH(
      origin.dx + r.left * k,
      origin.dy + r.top * k,
      max(r.width * k, 1),
      max(r.height * k, 1),
    );
    final scale = (0.5 * min(viewport.width, viewport.height) /
            max(target.width, target.height))
        .clamp(1.0, widget.maxScale);
    var tx = viewport.width / 2 - target.center.dx * scale;
    var ty = viewport.height / 2 - target.center.dy * scale;
    if (widget.constrained) {
      tx = tx.clamp(min(0.0, viewport.width - childSize.width * scale), 0.0);
      ty = ty.clamp(min(0.0, viewport.height - childSize.height * scale), 0.0);
    }
    _transform.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    transformationController: _transform,
    minScale: 0.8,
    maxScale: widget.maxScale,
    // Во весь экран можно уводить карту за края, на странице — нет.
    boundaryMargin: widget.constrained
        ? EdgeInsets.zero
        : const EdgeInsets.all(400),
    child: ValueListenableBuilder<Matrix4>(
      valueListenable: _transform,
      builder: (context, m, _) {
        final map = WorldMap(
          data: widget.data,
          style: _mapStyle(
            context,
            widget.fills,
            names: widget.names,
            zoom: m.getMaxScaleOnAxis(),
          ),
          onTap: widget.onTap,
          onAmbiguous: widget.onAmbiguous,
        );
        if (widget.width == null) return map;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(
            child: SizedBox(width: widget.mapWidth ?? widget.width, child: map),
          ),
        );
      },
    ),
  );
}

/// Карта на весь экран: за всё время или за год, зум, нажатие на страну,
/// список стран под картой и «Поделиться».
class MapPage extends StatefulWidget {
  final JournalController controller;
  final WorldMapData data;
  final CountryBorders borders;
  final int year;
  final Map<String, int> yearSlots;
  const MapPage({
    super.key,
    required this.controller,
    required this.data,
    required this.borders,
    required this.year,
    required this.yearSlots,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

/// Стиль воды и сетки шара: лёгкий синий оттенок поверх фона темы, чтобы
/// не спорить с политическими цветами.
Color _water(BuildContext context) => Color.alphaBlend(
  const Color(0xFF4F86C6).withValues(alpha: .20),
  Theme.of(context).colorScheme.surface,
);
Color _grid(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: .10);

class _MapPageState extends State<MapPage> {
  bool _allTime = true;
  bool _globe = false;
  final _card = GlobalKey();
  bool _busy = false;
  final _globeController = GlobeController();
  final _flatFocus = MapFocus();
  GlobeData? _globeData;
  GlobeData get globeData =>
      _globeData ??= GlobeData.build(widget.borders, widget.data);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _globeController.dispose();
    _flatFocus.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  /// Поиск страны: список справочника с флагами и днями; выбранная
  /// страна — в центр шара или плоской карты.
  Future<void> _search(BuildContext context, {required bool globe}) async {
    final fills = MapFills.of(
      widget.data,
      widget.controller.snapshot,
      widget.controller.today(),
    );
    final code = await showMapSearch(context, widget.data, fills);
    if (code == null) return;
    if (globe) {
      _globeController.focus(code);
    } else {
      _flatFocus.request(code);
    }
  }

  void _open(String code) {
    final snapshot = widget.controller.snapshot;
    final trip = snapshot
        .knownTrips(widget.controller.today())
        .where((t) => t.countryCode == code)
        .firstOrNull;
    if (trip == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CountryPage(
          controller: widget.controller,
          countryKey: trip.countryKey,
          year: widget.year,
          slot: widget.yearSlots[trip.countryKey],
        ),
      ),
    );
  }

  /// Под пальцем несколько мелких стран — короткий список на выбор.
  Future<void> _pick(List<String> codes) async {
    final l10n = context.l10n;
    final directory = CountryScope.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final visited = MapFills.of(
      widget.data,
      widget.controller.snapshot,
      widget.controller.today(),
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.mapPick,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final code in codes.take(6))
              ListTile(
                key: Key('mapPick-$code'),
                leading: CountryFlag(code: code, width: 28),
                title: Text(directory.display(code, code, lang)),
                subtitle: visited.visited.contains(code)
                    ? null
                    : Text(l10n.mapNotVisited),
                enabled:
                    visited.visited.contains(code) ||
                    visited.transit.contains(code),
                onTap: () {
                  Navigator.pop(sheet);
                  _open(code);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _share() async {
    final l10n = context.l10n;
    final service = ShareScope.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final boundary =
          _card.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final title = _allTime
          ? l10n.mapShareTitleAll
          : l10n.mapShareTitleYear(widget.year);
      await service.shareImage(
        bytes!.buffer.asUint8List(),
        _allTime ? 'domiday-map.png' : 'domiday-map-${widget.year}.png',
        title,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed('$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = widget.controller.snapshot;
    final today = widget.controller.today();
    final fills = MapFills.of(
      widget.data,
      snapshot,
      today,
      year: _allTime ? null : widget.year,
    );
    final total = CountryScope.of(context).all.length;
    final empty = fills.visited.isEmpty && fills.transit.isEmpty;
    final colors = DomidayColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);
    final directory = CountryScope.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    Widget legend(Widget swatch, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(text, style: muted),
      ],
    );
    Widget box(Color color) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: [
          IconButton(
            key: const Key('mapSearch'),
            tooltip: l10n.mapSearch,
            onPressed: () => _search(context, globe: _globe),
            icon: const Icon(Icons.search_rounded),
          ),
          if (ShareScope.of(context) != null)
            IconButton(
              key: const Key('mapShare'),
              tooltip: l10n.mapShare,
              onPressed: _busy ? null : _share,
              icon: const Icon(Icons.ios_share_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('mapScroll'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SegmentedButton<bool>(
                  key: const Key('mapRange'),
                  segments: [
                    ButtonSegment(value: true, label: Text(l10n.mapAllTime)),
                    ButtonSegment(value: false, label: Text('${widget.year}')),
                  ],
                  selected: {_allTime},
                  onSelectionChanged: (s) =>
                      setState(() => _allTime = s.first),
                ),
                SegmentedButton<bool>(
                  key: const Key('mapView'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.map_outlined),
                      tooltip: l10n.mapViewFlat,
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.public_outlined),
                      tooltip: l10n.mapViewGlobe,
                    ),
                  ],
                  selected: {_globe},
                  onSelectionChanged: (s) => setState(() => _globe = s.first),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Что показывает экран — одной фразой; без записей — подсказка,
            // откуда взять страны.
            Text(
              empty
                  ? l10n.mapEmpty
                  : _allTime
                  ? l10n.mapHintAll
                  : l10n.mapHintYear(widget.year),
              key: const Key('mapHint'),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (empty &&
                BackupScope.of(context) != null &&
                ImportScope.of(context) != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('mapImport'),
                  onPressed: () =>
                      startTimelineImport(context, widget.controller),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.importTitle),
                ),
              ),
            const SizedBox(height: 10),
            // Карта и заголовок в одной границе перерисовки — это и есть
            // картинка для «Поделиться».
            RepaintBoundary(
              key: _card,
              child: Container(
                color: scheme.surface,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const DomidayLogo(size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _allTime
                                ? l10n.mapShareTitleAll
                                : l10n.mapShareTitleYear(widget.year),
                            style: display(size: 18, height: 1.1),
                          ),
                        ),
                        Text(
                          l10n.mapCount(fills.visited.length, total),
                          key: const Key('mapCount'),
                          style: display(size: 18, height: 1.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _globe
                              ? AspectRatio(
                                  aspectRatio: 1,
                                  child: GlobeWidget(
                                    data: globeData,
                                    style: _mapStyle(
                                      context,
                                      fills,
                                      names: _mapNames(context, widget.data),
                                    ),
                                    water: _water(context),
                                    grid: _grid(context),
                                    controller: _globeController,
                                    onTap: _open,
                                    onAmbiguous: _pick,
                                  ),
                                )
                              : _CardMap(
                                  data: widget.data,
                                  fills: fills,
                                  names: _mapNames(context, widget.data),
                                  onTap: _open,
                                  onAmbiguous: _pick,
                                  focus: _flatFocus,
                                ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton.filledTonal(
                            key: const Key('mapFullscreen'),
                            tooltip: l10n.mapFullscreen,
                            onPressed: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => MapFullscreenPage(
                                  data: widget.data,
                                  globeData: globeData,
                                  globe: _globe,
                                  globeController: _globeController,
                                  fills: fills,
                                  title: _allTime
                                      ? l10n.mapShareTitleAll
                                      : l10n.mapShareTitleYear(widget.year),
                                  count: l10n.mapCount(
                                    fills.visited.length,
                                    total,
                                  ),
                                  onTap: _open,
                                  onAmbiguous: _pick,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.fullscreen_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        legend(box(politicalPalette[2]), l10n.mapLegendVisited),
                        legend(
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: const [0, .5, .5, 1],
                                colors: [
                                  colors.track,
                                  colors.track,
                                  colors.unknown,
                                  colors.unknown,
                                ],
                              ),
                            ),
                          ),
                          l10n.mapLegendTransit,
                        ),
                        legend(
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors.track,
                              border: Border.all(color: scheme.onSurface),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          l10n.mapLegendDisputed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.mapNote, style: muted),
            const SizedBox(height: 20),
            _SectionHeader(
              title: l10n.mapCountries,
              meta: l10n.mapCount(fills.visited.length, total),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in fills.visited)
                  ActionChip(
                    key: Key('mapChip-$code'),
                    avatar: CountryFlag(code: code, width: 20),
                    label: Text(directory.display(code, code, lang)),
                    onPressed: () => _open(code),
                  ),
                for (final code in fills.transit)
                  ActionChip(
                    key: Key('mapChip-$code'),
                    avatar: const Icon(Icons.flight, size: 16),
                    label: Text(directory.display(code, code, lang)),
                    onPressed: () => _open(code),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Карта на весь экран: только карта или шар, зум до 12× (шар — до 40×)
/// и панорамирование за края, кнопки закрытия, поиска и переключения
/// вида, счётчик. Нажатия на страны — те же, что на экране карты
/// (страницы открываются поверх).
class MapFullscreenPage extends StatefulWidget {
  final WorldMapData data;
  final GlobeData globeData;
  final bool globe;
  final GlobeController globeController;
  final MapFills fills;
  final String title;
  final String count;
  final ValueChanged<String> onTap;
  final ValueChanged<List<String>> onAmbiguous;
  const MapFullscreenPage({
    super.key,
    required this.data,
    required this.globeData,
    required this.globe,
    required this.globeController,
    required this.fills,
    required this.title,
    required this.count,
    required this.onTap,
    required this.onAmbiguous,
  });

  @override
  State<MapFullscreenPage> createState() => _MapFullscreenPageState();
}

class _MapFullscreenPageState extends State<MapFullscreenPage> {
  late bool _globe = widget.globe;
  final _flatFocus = MapFocus();

  @override
  void dispose() {
    _flatFocus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = await showMapSearch(context, widget.data, widget.fills);
    if (code == null) return;
    if (_globe) {
      widget.globeController.focus(code);
    } else {
      _flatFocus.request(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    // При открытии карта целиком вписана в экран (в альбомной ориентации —
    // по высоте), дальше масштаб задаёт пользователь, до 12×.
    final width = min(
      size.width,
      size.height * WorldMapData.width / WorldMapData.height,
    );
    return Scaffold(
      key: const Key('mapFullscreenPage'),
      backgroundColor: scheme.surface,
      // Stack без fit сжался бы до верхней панели, и карта за его
      // границами не получала бы нажатий.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _globe
                ? GlobeWidget(
                    key: const Key('globeFullscreen'),
                    data: widget.globeData,
                    style: _mapStyle(
                      context,
                      widget.fills,
                      names: _mapNames(context, widget.data),
                    ),
                    water: _water(context),
                    grid: _grid(context),
                    controller: widget.globeController,
                    onTap: widget.onTap,
                    onAmbiguous: widget.onAmbiguous,
                  )
                : _ZoomableMap(
                    data: widget.data,
                    fills: widget.fills,
                    names: _mapNames(context, widget.data),
                    onTap: widget.onTap,
                    onAmbiguous: widget.onAmbiguous,
                    maxScale: 12,
                    constrained: false,
                    width: size.width,
                    height: size.height,
                    mapWidth: width,
                    focus: _flatFocus,
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        key: const Key('mapFullscreenClose'),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        key: const Key('mapFullscreenSearch'),
                        tooltip: l10n.mapSearch,
                        onPressed: _search,
                        icon: const Icon(Icons.search_rounded),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        key: const Key('mapFullscreenView'),
                        tooltip: _globe ? l10n.mapViewFlat : l10n.mapViewGlobe,
                        onPressed: () => setState(() => _globe = !_globe),
                        icon: Icon(
                          _globe ? Icons.map_outlined : Icons.public_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: .85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.title} · ${widget.count}',
                      style: display(size: 15, height: 1.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Поиск страны: поле и список справочника на языке интерфейса с флагами;
/// у посещённых — дни, у остальных «записей нет». Возвращает код или null.
/// Страны без контура на карте (13 микрогосударств) не предлагаются.
Future<String?> showMapSearch(
  BuildContext context,
  WorldMapData data,
  MapFills fills,
) {
  final directory = CountryScope.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final l10n = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => _MapSearchSheet(
      directory: directory,
      lang: lang,
      data: data,
      fills: fills,
      hint: l10n.mapSearchHint,
      notVisited: l10n.mapNotVisited,
      days: (n) => l10n.daysFull(n),
    ),
  );
}

class _MapSearchSheet extends StatefulWidget {
  final CountryDirectory directory;
  final String lang;
  final WorldMapData data;
  final MapFills fills;
  final String hint;
  final String notVisited;
  final String Function(int) days;
  const _MapSearchSheet({
    required this.directory,
    required this.lang,
    required this.data,
    required this.fills,
    required this.hint,
    required this.notVisited,
    required this.days,
  });

  @override
  State<_MapSearchSheet> createState() => _MapSearchSheetState();
}

class _MapSearchSheetState extends State<_MapSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = widget.directory
        .search(_query, widget.lang)
        .where((c) => widget.data.shape(c.code) != null)
        .toList();
    // Посещённые страны первыми при пустом запросе: обычно ищут их.
    if (_query.isEmpty) {
      results.sort((a, b) {
        final va = widget.fills.days.containsKey(a.code) ? 0 : 1;
        final vb = widget.fills.days.containsKey(b.code) ? 0 : 1;
        return va != vb
            ? va.compareTo(vb)
            : a.name(widget.lang).compareTo(b.name(widget.lang));
      });
    }
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                key: const Key('mapSearchField'),
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: widget.hint,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final c = results[i];
                  final days = widget.fills.days[c.code];
                  return ListTile(
                    key: Key('mapFind-${c.code}'),
                    leading: CountryFlag(code: c.code, width: 28),
                    title: Text(c.name(widget.lang)),
                    subtitle: Text(
                      days == null ? widget.notVisited : widget.days(days),
                    ),
                    onTap: () => Navigator.pop(context, c.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
