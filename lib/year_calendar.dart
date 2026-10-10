import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'snapshot.dart';
import 'theme.dart';
import 'trip.dart';

/// Категория клетки календаря. Правило «неизвестно — не значит дома»
/// отражено буквально: неизвестный день не закрашивается.
enum DayKind { home, away, both, unknown, future }

/// Что стоит за днём: страна (ключ и код) и тип записи.
class DayMark {
  final String key;
  final String? code;
  final bool transit;
  const DayMark(this.key, this.code, {this.transit = false});
}

/// Классификация дней выбранного года по наборам YearSummary и, если дан
/// снимок, по записям — для цвета страны и кодов в раскрытом месяце.
/// Никакой собственной календарной логики: только чтение.
class YearCalendarData {
  final int year;
  final Set<int> home;
  final Set<int> away;
  final Set<int> transit;
  final Day today;
  final String homeKey;

  /// Порядок зарубежных стран по убыванию дней — слот цвета.
  final Map<String, int> slots;
  final Map<int, List<DayMark>> _marks;

  /// Планы по дням года (только будущие дни): обводка цветом страны.
  final Map<int, DayMark> _planned;

  /// [slots] — готовое распределение цветов (страница страны красит её
  /// тем же цветом, что дашборд); иначе по убыванию дней за год.
  YearCalendarData(
    YearSummary summary,
    this.today, {
    JournalSnapshot? snapshot,
    Map<String, int>? slots,
  }) : year = summary.year,
       home = summary.home,
       away = summary.away,
       transit = summary.transit,
       homeKey = snapshot?.homeKey ?? '',
       slots = slots ?? _slots(summary, snapshot?.homeKey),
       _marks = snapshot == null
           ? const {}
           : _collect(snapshot, summary, today),
       _planned = snapshot == null
           ? const {}
           : _collectPlans(snapshot, summary.year, today);

  static Map<int, DayMark> _collectPlans(
    JournalSnapshot snapshot,
    int year,
    Day today,
  ) {
    final first = Day(year, 1, 1).ordinal, last = Day(year, 12, 31).ordinal;
    final out = <int, DayMark>{};
    for (final p in snapshot.plans) {
      final start = p.arrival.ordinal < first ? first : p.arrival.ordinal;
      final end = p.departure.ordinal > last ? last : p.departure.ordinal;
      for (var d = start; d <= end; d++) {
        if (d <= today.ordinal) continue;
        out.putIfAbsent(d, () => DayMark(p.countryKey, p.countryCode));
      }
    }
    return out;
  }

  /// План на этот будущий день, если есть.
  DayMark? planOf(int month, int day) => _planned[Day(year, month, day).ordinal];

  bool get hasPlans => _planned.isNotEmpty;

  static Map<String, int> _slots(YearSummary summary, String? homeKey) {
    var i = 0;
    return {
      for (final c in summary.countries)
        if (c.key != homeKey) c.key: i++,
    };
  }

  static Map<int, List<DayMark>> _collect(
    JournalSnapshot snapshot,
    YearSummary summary,
    Day today,
  ) {
    final first = Day(summary.year, 1, 1).ordinal;
    final last = summary.through.ordinal;
    final marks = <int, List<DayMark>>{};
    for (final t in snapshot.knownTrips(today)) {
      final start = t.arrival.ordinal < first ? first : t.arrival.ordinal;
      final end = t.departure.ordinal > last ? last : t.departure.ordinal;
      for (var d = start; d <= end; d++) {
        final list = marks.putIfAbsent(d, () => []);
        if (!list.any(
          (m) => m.key == t.countryKey && m.transit == t.isTransit,
        )) {
          list.add(DayMark(t.countryKey, t.countryCode, transit: t.isTransit));
        }
      }
    }
    return marks;
  }

  int daysInMonth(int month) => DateTime.utc(year, month + 1, 0).day;

  DayKind kindOf(int month, int day) {
    final ordinal = Day(year, month, day).ordinal;
    if (ordinal > today.ordinal) return DayKind.future;
    final h = home.contains(ordinal), a = away.contains(ordinal);
    if (h && a) return DayKind.both;
    if (h) return DayKind.home;
    if (a) return DayKind.away;
    return DayKind.unknown;
  }

  bool isToday(int month, int day) =>
      today.year == year && today.month == month && today.day == day;

  bool isTransit(int month, int day) =>
      transit.contains(Day(year, month, day).ordinal);

  /// Записи дня; пребывания раньше транзитов.
  List<DayMark> marksOf(int month, int day) {
    final list = List<DayMark>.of(
      _marks[Day(year, month, day).ordinal] ?? const [],
    );
    list.sort((a, b) => (a.transit ? 1 : 0).compareTo(b.transit ? 1 : 0));
    return list;
  }

  /// Уникальные страны дня в порядке записей.
  List<DayMark> countriesOf(int month, int day) {
    final seen = <String>{};
    return [
      for (final m in marksOf(month, day))
        if (seen.add(m.key)) m,
    ];
  }

  /// Сколько клеток закрашено (дома, вне дома или оба) — для проверок.
  int get paintedCount {
    var count = 0;
    for (var m = 1; m <= 12; m++) {
      for (var d = 1; d <= daysInMonth(m); d++) {
        final kind = kindOf(m, d);
        if (kind == DayKind.home ||
            kind == DayKind.away ||
            kind == DayKind.both) {
          count++;
        }
      }
    }
    return count;
  }
}

/// Цвет клетки для страны: дом — бледная «бумага», зарубежная — по слоту.
Color _colorFor(DomidayColors colors, YearCalendarData data, DayMark m) =>
    m.key == data.homeKey
    ? colors.homeCell
    : colors.countryColor(data.slots[m.key] ?? -1);

const _inkOnColor = Color(0xFF272821);

/// Цвет цифры на заливке: тёмный на светлом, кремовый на тёмном.
Color _inkFor(Color fill) =>
    fill.computeLuminance() > 0.4 ? _inkOnColor : kCream;

/// Год как 12 мини-месяцев; нажатие раскрывает месяц с кодами стран,
/// нажатие на день раскрытого месяца — карточка дня. Ничего не пишет.
class YearCalendar extends StatefulWidget {
  final YearSummary summary;
  final Day today;
  final JournalSnapshot? snapshot;
  final ValueChanged<Day>? onDayTap;

  /// Смахивание по сетке месяцев: −1 / +1 к году (родитель меняет год
  /// в пределах [minYear, maxYear]). Смахивание по раскрытому месяцу
  /// листает месяцы и на границе года переходит в соседний.
  final ValueChanged<int>? onYearChange;
  final int minYear;
  final int maxYear;

  /// Цвета стран, если их задаёт родитель (см. [YearCalendarData]).
  final Map<String, int>? slots;
  const YearCalendar({
    super.key,
    required this.summary,
    required this.today,
    this.snapshot,
    this.onDayTap,
    this.onYearChange,
    this.minYear = 1900,
    this.maxYear = 9999,
    this.slots,
  });

  @override
  State<YearCalendar> createState() => _YearCalendarState();
}

class _YearCalendarState extends State<YearCalendar> {
  /// Раскрытый месяц и его год; показывается, пока год совпадает с
  /// выбранным (смена года кнопкой сворачивает месяц).
  int? _expanded;
  int? _expandedYear;

  /// Пейджеры: страница года и страница месяца едут за пальцем, снап с
  /// инерцией, упругий откат на границах (как в Google/Samsung Calendar).
  late PageController _years;
  PageController? _months;
  final _monthPager = GlobalKey();

  /// Измеренные высоты страниц: у PageView фиксированная высота, а месяцы
  /// бывают в 5 и 6 строк — AnimatedSize плавно подстраивает контейнер.
  final Map<int, double> _yearHeights = {};
  final Map<int, double> _monthHeights = {};

  static const _pageDuration = Duration(milliseconds: 320);
  static const _pageCurve = Curves.easeOutCubic;

  bool get _paged => widget.snapshot != null;
  int _yearIndex(int y) => _paged ? y - widget.minYear : 0;
  int _yearAt(int i) => _paged ? widget.minYear + i : widget.summary.year;
  int get _yearCount => _paged ? widget.maxYear - widget.minYear + 1 : 1;
  int _monthIndex(int y, int m) => _yearIndex(y) * 12 + (m - 1);
  (int, int) _monthAt(int i) => (_yearAt(i ~/ 12), i % 12 + 1);
  int get _monthCount => _yearCount * 12;

  @override
  void initState() {
    super.initState();
    _years = PageController(initialPage: _yearIndex(widget.summary.year));
  }

  @override
  void didUpdateWidget(YearCalendar old) {
    super.didUpdateWidget(old);
    if (old.summary.year == widget.summary.year &&
        old.minYear == widget.minYear) {
      return;
    }
    if (old.minYear != widget.minYear) {
      _years.dispose();
      _years = PageController(initialPage: _yearIndex(widget.summary.year));
      return;
    }
    // Год сменили снаружи (кнопкой или месячным пейджером) — довезти
    // страницу года; если она уже там, ничего не делать.
    final target = _yearIndex(widget.summary.year);
    if (_years.hasClients && (_years.page ?? target).round() != target) {
      _years.animateToPage(target, duration: _pageDuration, curve: _pageCurve);
    }
  }

  @override
  void dispose() {
    _years.dispose();
    _months?.dispose();
    super.dispose();
  }

  YearSummary _summaryFor(int year) => year == widget.summary.year
      ? widget.summary
      : YearSummary(widget.snapshot!, year, widget.today);

  YearCalendarData _dataFor(int year) => YearCalendarData(
    _summaryFor(year),
    widget.today,
    snapshot: widget.snapshot,
    slots: widget.slots,
  );

  void _onYearPage(int index) {
    final year = _yearAt(index);
    if (year == widget.summary.year) return;
    HapticFeedback.selectionClick();
    widget.onYearChange?.call(year - widget.summary.year);
  }

  void _onMonthPage(int index) {
    final (year, month) = _monthAt(index);
    HapticFeedback.selectionClick();
    setState(() {
      _expanded = month;
      _expandedYear = year;
    });
    if (year != widget.summary.year) {
      widget.onYearChange?.call(year - widget.summary.year);
    }
  }

  void _toggleMonth(int year, int month) {
    setState(() {
      if (_expanded == month && _expandedYear == year) {
        _expanded = null;
        return;
      }
      _expanded = month;
      _expandedYear = year;
      final index = _monthIndex(year, month);
      final months = _months;
      if (months != null && months.hasClients) {
        // Пейджер на экране: PageView хранит позицию и проигнорировал бы
        // initialPage нового контроллера — прыгаем на страницу.
        months.jumpToPage(index);
      } else {
        // Старый контроллер освобождается после кадра: AnimatedBuilder ещё
        // снимает с него слушателей при перестроении.
        if (months != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => months.dispose());
        }
        _months = PageController(initialPage: index);
        _monthHeights.clear();
      }
    });
    // Раскрытый месяц стоит под сеткой года — довезти его в кадр (только
    // вертикальный список: горизонтальные пейджеры не предки).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _monthPager.currentContext;
      if (context == null || !mounted) return;
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Все [names] умещаются в [maxWidth] стилем заголовка мини-месяца.
  static bool _fitsAll(
    BuildContext context,
    List<String> names,
    double maxWidth,
  ) {
    final style = DefaultTextStyle.of(context).style
        .merge(_MiniMonth.titleStyle);
    final scaler = MediaQuery.textScalerOf(context);
    for (final name in names) {
      final painter = TextPainter(
        text: TextSpan(text: name, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > maxWidth) return false;
    }
    return true;
  }

  /// Высота страницы года до измерения: 6 недель в каждом ряду месяцев.
  double _estimateYear(double width, double scale, int perRow) {
    final monthWidth = (width - (perRow - 1) * 10) / perRow;
    final cell = (monthWidth - 8 - 9) / 7;
    final month = 13 + 15 * scale + 5 + 9 * scale + 6 * (cell + 1.5);
    final rows = (12 / perRow).ceil();
    return rows * month + (rows - 1) * 12;
  }

  @override
  Widget build(BuildContext context) {
    final data = _dataFor(widget.summary.year);
    final expanded = _expandedYear == widget.summary.year ? _expanded : null;
    final l10n = context.l10n;
    final months = l10n.monthsShort.split(',');
    final full = l10n.monthsFull.split(',');
    final weekdays = l10n.weekdaysShort.split(',');
    final colors = DomidayColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      key: const Key('yearCalendar'),
      label: l10n.calendarSemantics(
        widget.summary.year,
        widget.summary.home.length,
        widget.summary.away.length,
        widget.summary.unknown,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // На узком экране с крупным текстом — два месяца в ряд.
              final perRow = constraints.maxWidth / scale < 300 ? 2 : 3;
              final estimate = _estimateYear(
                constraints.maxWidth,
                scale,
                perRow,
              );
              // Полные названия месяцев, если самое длинное умещается в
              // заголовок мини-месяца (ширина клетки минус отступы);
              // иначе сокращения — измерение тем же стилем и шрифтом.
              final monthWidth =
                  (constraints.maxWidth - (perRow - 1) * 10) / perRow - 8;
              final names = _fitsAll(context, full, monthWidth) ? full : months;
              return _Pager(
                key: const Key('yearSwipe'),
                controller: _years,
                count: _yearCount,
                heights: _yearHeights,
                estimate: estimate,
                onPageChanged: _onYearPage,
                builder: (context, index) {
                  final year = _yearAt(index);
                  final d = year == widget.summary.year ? data : _dataFor(year);
                  return _YearGrid(
                    data: d,
                    perRow: perRow,
                    months: names,
                    weekdays: weekdays,
                    colors: colors,
                    expanded: year == widget.summary.year ? expanded : null,
                    onMonthTap: (m) => _toggleMonth(year, m),
                  );
                },
              );
            },
          ),
          if (expanded != null && _months != null) ...[
            const SizedBox(height: 4),
            _MonthHeader(
              controller: _months!,
              monthAt: (i) => _monthAt(i),
              full: full,
              onCollapse: () => setState(() => _expanded = null),
            ),
            _Pager(
              key: _monthPager,
              controller: _months!,
              count: _monthCount,
              heights: _monthHeights,
              estimate: 6 * 48 + 24,
              onPageChanged: _onMonthPage,
              builder: (context, index) {
                final (year, month) = _monthAt(index);
                return _ExpandedMonth(
                  data: year == widget.summary.year ? data : _dataFor(year),
                  month: month,
                  weekdays: weekdays,
                  colors: colors,
                  onDayTap: widget.onDayTap,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          _Legend(colors: colors),
        ],
      ),
    );
  }
}

/// PageView с высотой текущей страницы: страницы измеряют себя
/// (_SizeReporter), контейнер плавно меняет высоту при смене страницы.
class _Pager extends StatefulWidget {
  final PageController controller;
  final int count;
  final Map<int, double> heights;
  final double estimate;
  final ValueChanged<int> onPageChanged;
  final IndexedWidgetBuilder builder;
  const _Pager({
    super.key,
    required this.controller,
    required this.count,
    required this.heights,
    required this.estimate,
    required this.onPageChanged,
    required this.builder,
  });
  @override
  State<_Pager> createState() => _PagerState();
}

class _PagerState extends State<_Pager> {
  /// Сигнал «страница измерена» — отдельно от контроллера, чтобы не
  /// дёргать его после освобождения.
  final _measured = ValueNotifier<int>(0);

  @override
  void dispose() {
    _measured.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.controller, _measured]),
    builder: (context, child) {
      final controller = widget.controller;
      final heights = widget.heights;
      final page = controller.hasClients
          ? (controller.page ?? controller.initialPage.toDouble())
          : controller.initialPage.toDouble();
      final height = heights[page.round()] ?? widget.estimate;
      return AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: SizedBox(height: height, child: child),
      );
    },
    child: PageView.builder(
      controller: widget.controller,
      itemCount: widget.count,
      physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
      onPageChanged: widget.onPageChanged,
      itemBuilder: (context, index) => _MeasuredPage(
        onSize: (size) {
          if (!mounted || widget.heights[index] == size.height) return;
          widget.heights[index] = size.height;
          _measured.value++;
        },
        child: widget.builder(context, index),
      ),
    ),
  );
}

/// Страница пейджера естественной высоты: выходит за фиксированную высоту
/// PageView (обрезается) и сообщает свой размер.
class _MeasuredPage extends StatelessWidget {
  final ValueChanged<Size> onSize;
  final Widget child;
  const _MeasuredPage({required this.onSize, required this.child});
  @override
  Widget build(BuildContext context) => OverflowBox(
    alignment: Alignment.topCenter,
    minHeight: 0,
    maxHeight: double.infinity,
    child: _SizeReporter(onSize: onSize, child: child),
  );
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;
  const _SizeReporter({required this.onSize, required Widget super.child});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);
  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter r) =>
      r.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  ValueChanged<Size> onSize;
  Size? _reported;
  _RenderSizeReporter(this.onSize);
  @override
  void performLayout() {
    super.performLayout();
    if (_reported != size) {
      _reported = size;
      final reported = size;
      WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
    }
  }
}

/// Сетка 12 мини-месяцев одного года.
class _YearGrid extends StatelessWidget {
  final YearCalendarData data;
  final int perRow;
  final List<String> months;
  final List<String> weekdays;
  final DomidayColors colors;
  final int? expanded;
  final ValueChanged<int> onMonthTap;
  const _YearGrid({
    required this.data,
    required this.perRow,
    required this.months,
    required this.weekdays,
    required this.colors,
    required this.expanded,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var m = 1; m <= 12; m += perRow) ...[
        if (m > 1) const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var k = m; k < m + perRow; k++) ...[
              if (k > m) const SizedBox(width: 10),
              Expanded(
                child: k <= 12
                    ? _MiniMonth(
                        data: data,
                        month: k,
                        name: months[k - 1],
                        weekdays: weekdays,
                        colors: colors,
                        selected: expanded == k,
                        onTap: () => onMonthTap(k),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ],
    ],
  );
}

/// Заголовок раскрытого месяца: название с кроссфейдом, точки 12 месяцев,
/// бегущие вместе с прокруткой страницы, кнопка «Свернуть».
class _MonthHeader extends StatelessWidget {
  final PageController controller;
  final (int, int) Function(int index) monthAt;
  final List<String> full;
  final VoidCallback onCollapse;
  const _MonthHeader({
    required this.controller,
    required this.monthAt,
    required this.full,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();
        final (year, month) = monthAt(page.round());
        final position = page % 12;
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        '${full[month - 1]} $year',
                        key: ValueKey('$year-$month'),
                        style: display(size: 18),
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('collapseMonth'),
                    onPressed: onCollapse,
                    child: Text(context.l10n.calendarCollapse),
                  ),
                ],
              ),
              Row(
                children: [
                  for (var m = 0; m < 12; m++)
                    Container(
                      width: 5 + 6 * (1 - (position - m).abs().clamp(0.0, 1.0)),
                      height: 5,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          scheme.onSurfaceVariant.withValues(alpha: .35),
                          scheme.onSurface,
                          1 - (position - m).abs().clamp(0.0, 1.0),
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Мини-месяц как в годовом виде Google Calendar: буквы дней недели и
/// номера дней в клетках; размер цифр — от ширины клетки.
class _MiniMonth extends StatelessWidget {
  final YearCalendarData data;
  final int month;
  final String name;
  final List<String> weekdays;
  final DomidayColors colors;
  final bool selected;
  final VoidCallback onTap;
  const _MiniMonth({
    required this.data,
    required this.month,
    required this.name,
    required this.weekdays,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  static const titleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = (DateTime(data.year, month, 1).weekday + 6) % 7; // пн = 0
    final days = data.daysInMonth(month);
    return InkWell(
      key: Key('month-$month'),
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? scheme.onSurface : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final cell = (c.maxWidth - 6 * 1.5) / 7;
            final digit = (cell * 0.6).clamp(6.0, 10.0);
            final cells = <Widget>[
              for (var i = 0; i < first; i++) const SizedBox.shrink(),
              for (var d = 1; d <= days; d++)
                _DayBox(
                  data: data,
                  month: month,
                  day: d,
                  colors: colors,
                  fontSize: digit,
                ),
            ];
            while (cells.length % 7 != 0) {
              cells.add(const SizedBox.shrink());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  key: Key('monthName-$month'),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: _MiniMonth.titleStyle.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: 1.5),
                      Expanded(
                        child: Text(
                          weekdays[i].substring(0, 1).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: (digit - 0.5).clamp(5.0, 9.0),
                            height: 1,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                for (var r = 0; r < cells.length ~/ 7; r++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1.5),
                    child: Row(
                      children: [
                        for (var col = 0; col < 7; col++) ...[
                          if (col > 0) const SizedBox(width: 1.5),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: cells[r * 7 + col],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Клетка мини-месяца: номер дня на цвете страны; диагональ для двух
/// стран, самолёт для транзита, контур для неизвестного, приглушённая
/// плитка с рамкой для будущего, обводка сегодня.
class _DayBox extends StatelessWidget {
  final YearCalendarData data;
  final int month;
  final int day;
  final DomidayColors colors;
  final double fontSize;
  const _DayBox({
    required this.data,
    required this.month,
    required this.day,
    required this.colors,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kind = data.kindOf(month, day);
    final countries = data.countriesOf(month, day);
    final transit = data.isTransit(month, day);
    final today = data.isToday(month, day);
    Widget digit(Color color, {FontWeight weight = FontWeight.w600}) => Center(
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          fontWeight: weight,
          color: color,
        ),
      ),
    );
    Widget box;
    if (kind == DayKind.future) {
      final plan = data.planOf(month, day);
      box = DecoratedBox(
        decoration: BoxDecoration(
          color: colors.future,
          border: Border.all(
            color: plan == null
                ? colors.futureLine
                : _colorFor(colors, data, plan),
            width: plan == null ? 0.8 : 1.6,
          ),
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: digit(
          scheme.onSurfaceVariant.withValues(alpha: .55),
          weight: FontWeight.w400,
        ),
      );
    } else if (kind == DayKind.unknown) {
      box = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.unknown, width: 1),
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: digit(scheme.onSurfaceVariant, weight: FontWeight.w400),
      );
    } else {
      final fills = countries.isEmpty
          ? [kind == DayKind.home ? colors.homeCell : colors.otherCountry]
          : [for (final m in countries) _colorFor(colors, data, m)];
      final ink = _inkFor(fills.first);
      box = CustomPaint(
        painter: _CellPainter(fills.take(2).toList()),
        child: transit
            ? LayoutBuilder(
                builder: (context, c) =>
                    Icon(Icons.flight, size: c.maxWidth * 0.8, color: ink),
              )
            : digit(ink),
      );
    }
    if (today) {
      box = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.onSurface, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        position: DecorationPosition.foreground,
        child: box,
      );
    }
    return box;
  }
}

class _CellPainter extends CustomPainter {
  final List<Color> fills;
  const _CellPainter(this.fills);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width > 24 ? 10 : 2.5);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(rrect, Paint()..color = fills.first);
    if (fills.length > 1) {
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawPath(
        Path()
          ..moveTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close(),
        Paint()..color = fills[1],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CellPainter old) =>
      old.fills.length != fills.length ||
      old.fills.asMap().entries.any((e) => e.value != fills[e.key]);
}

/// Раскрытый месяц: дни недели и крупные клетки с номером и кодами стран
/// (самолёт — транзит). Нажатие на день — карточка дня.
class _ExpandedMonth extends StatelessWidget {
  final YearCalendarData data;
  final int month;
  final List<String> weekdays;
  final DomidayColors colors;
  final ValueChanged<Day>? onDayTap;
  const _ExpandedMonth({
    required this.data,
    required this.month,
    required this.weekdays,
    required this.colors,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = (DateTime(data.year, month, 1).weekday + 6) % 7;
    final days = data.daysInMonth(month);
    final cells = <Widget>[];
    for (var i = 0; i < first; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= days; d++) {
      cells.add(
        _BigCell(
          data: data,
          month: month,
          day: d,
          colors: colors,
          onTap: onDayTap == null || data.kindOf(month, d) == DayKind.future
              ? null
              : () => onDayTap!(Day(data.year, month, d)),
        ),
      );
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }
    return Container(
      key: Key('expanded-$month'),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var c = 0; c < 7; c++) ...[
                if (c > 0) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    weekdays[c],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < cells.length ~/ 7; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var c = 0; c < 7; c++) ...[
                    if (c > 0) const SizedBox(width: 4),
                    Expanded(child: cells[r * 7 + c]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BigCell extends StatelessWidget {
  final YearCalendarData data;
  final int month;
  final int day;
  final DomidayColors colors;
  final VoidCallback? onTap;
  const _BigCell({
    required this.data,
    required this.month,
    required this.day,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kind = data.kindOf(month, day);
    final countries = data.countriesOf(month, day);
    final transit = data.isTransit(month, day);
    final today = data.isToday(month, day);
    final fills = kind == DayKind.future || kind == DayKind.unknown
        ? const <Color>[]
        : countries.isEmpty
        ? [kind == DayKind.home ? colors.homeCell : colors.otherCountry]
        : [for (final m in countries) _colorFor(colors, data, m)];
    final onCell = fills.isEmpty
        ? scheme.onSurfaceVariant
        : _inkFor(fills.first);
    final stays = [
      for (final m in data.marksOf(month, day))
        if (!m.transit) m,
    ];
    final transits = [
      for (final m in data.marksOf(month, day))
        if (m.transit) m,
    ];
    final plan = kind == DayKind.future ? data.planOf(month, day) : null;
    final codes = [
      for (final m in countries) m.code ?? '—',
      if (plan != null) plan.code ?? '—',
    ];
    // Коды стран буквами (по замечанию владельца флаги в клетках убраны:
    // 0.12.1); без кода — «—» тем же цветом, что цифра.
    Widget marks(List<DayMark> list, double size) => Text(
      list.take(2).map((m) => m.code ?? '—').join(' '),
      style: TextStyle(
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: .4,
        color: onCell.withValues(alpha: list.first.transit ? 1 : .85),
      ),
    );
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: kind == DayKind.future
                ? scheme.onSurfaceVariant.withValues(alpha: .5)
                : onCell,
          ),
        ),
        // План на будущий день: код страны её цветом (замечание владельца).
        if (plan != null) ...[
          const SizedBox(height: 1),
          Text(
            plan.code ?? '—',
            style: TextStyle(
              fontSize: 9.5,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: .4,
              color: _colorFor(colors, data, plan),
            ),
          ),
        ],
        if (fills.isNotEmpty) ...[
          if (stays.isNotEmpty) ...[
            const SizedBox(height: 1),
            marks(stays, 9.5),
          ],
          if (transit) ...[
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flight, size: 10, color: onCell),
                const SizedBox(width: 2),
                marks(transits, stays.isEmpty ? 9.5 : 8.5),
              ],
            ),
          ],
        ],
      ],
    );
    Widget cell = Container(
      key: Key('day-${data.year}-$month-$day'),
      height: 44,
      decoration: kind == DayKind.unknown
          ? BoxDecoration(
              border: Border.all(color: colors.unknown, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            )
          : kind == DayKind.future
          ? BoxDecoration(
              color: colors.future,
              border: Border.all(
                color: data.planOf(month, day) == null
                    ? colors.futureLine
                    : _colorFor(colors, data, data.planOf(month, day)!),
                width: data.planOf(month, day) == null ? 1 : 2,
              ),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: fills.isEmpty
          ? FittedBox(fit: BoxFit.scaleDown, child: content)
          : CustomPaint(
              painter: _CellPainter(fills.take(2).toList()),
              child: FittedBox(fit: BoxFit.scaleDown, child: content),
            ),
    );
    if (today) {
      cell = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.onSurface, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: cell,
      );
    }
    return Semantics(
      button: onTap != null,
      label: '${Day(data.year, month, day).text(context)}: ${codes.join(', ')}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: cell,
      ),
    );
  }
}

/// Легенда только служебных обозначений в одну-две строки: страны с
/// цветами показаны в разделе «По странам».
class _Legend extends StatelessWidget {
  final DomidayColors colors;
  const _Legend({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget item(Widget swatch, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 14, height: 14, child: swatch),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
    return Wrap(
      key: const Key('calendarLegend'),
      spacing: 14,
      runSpacing: 6,
      children: [
        item(
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.unknown, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          l10n.legendUnknown,
        ),
        item(
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.future,
              border: Border.all(color: colors.futureLine),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          l10n.legendFuture,
        ),
        item(
          Icon(Icons.flight, size: 14, color: scheme.onSurface),
          l10n.legendTransit,
        ),
        item(
          CustomPaint(
            painter: _CellPainter([
              colors.countryColor(0),
              colors.countryColor(1),
            ]),
          ),
          l10n.legendBoth,
        ),
      ],
    );
  }
}
