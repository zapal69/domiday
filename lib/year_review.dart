part of 'main.dart';

/// Итоги года: несколько экранов, которые листаются как истории —
/// страны и новые страны, дни, карта, города, «Поделиться». Всё считается
/// из дневника теми же функциями, что плитки и страницы стран.
class YearReviewPage extends StatefulWidget {
  final JournalController controller;
  final int year;
  final Map<String, int> slots;
  final WorldMapData? map;
  const YearReviewPage({
    super.key,
    required this.controller,
    required this.year,
    required this.slots,
    this.map,
  });

  @override
  State<YearReviewPage> createState() => _YearReviewPageState();
}

class _YearReviewPageState extends State<YearReviewPage> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Страны с хотя бы одним пребыванием (не только транзитом) в году.
  static List<CountryStat> stays(YearSummary s) =>
      s.countries.where((c) => c.days > 0 && c.trips > c.transits).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = widget.controller.snapshot;
    final today = widget.controller.today();
    final year = widget.year;
    final summary = YearSummary(snapshot, year, today);
    final all = snapshot.knownTrips(today);
    final inYear = all
        .where((t) => t.arrival.year <= year && t.departure.year >= year)
        .toList();
    final visited = stays(summary);
    final earlier = {
      for (final t in all)
        if (!t.isTransit && t.arrival.year < year) t.countryKey,
    };
    // Дом никогда не «новая страна».
    final fresh = visited
        .where((c) => c.key != snapshot.homeKey && !earlier.contains(c.key))
        .length;
    // Самая долгая поездка — не дома: текущее пребывание дома не в счёт.
    final longest = inYear
        .where((t) => !t.isTransit && t.countryKey != snapshot.homeKey)
        .fold<Trip?>(
      null,
      (best, t) => best == null || t.days > best.days ? t : best,
    );
    final cities = {
      for (final t in inYear)
        if (!t.isTransit && t.city.trim().isNotEmpty) t.city.trim(),
    }.toList()..sort();
    final scheme = Theme.of(context).colorScheme;
    final colors = DomidayColors.of(context);
    final muted = TextStyle(fontSize: 15, color: scheme.onSurfaceVariant);
    final through = year == today.year ? l10n.reviewThrough(today.text(context)) : null;

    Widget page(String key, List<Widget> children) => Padding(
      key: Key(key),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(shrinkWrap: true, children: children),
        ),
      ),
    );
    Widget big(String text) => Text(text, style: display(size: 40, height: 1.05));
    Widget title(String text) => Text(text, style: display(size: 24, height: 1.1));

    final pages = <Widget>[
      page('review-countries', [
        big(l10n.reviewCountries(visited.length)),
        const SizedBox(height: 6),
        Text(l10n.reviewCountriesSub, style: muted),
        const SizedBox(height: 20),
        Text(l10n.reviewNewCountries(fresh), style: display(size: 20, height: 1.1)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in visited)
              Chip(
                key: Key('review-country-${c.key}'),
                avatar: c.code == null ? null : CountryFlag(code: c.code, width: 20),
                label: Text(countryName(context, c.code, c.label)),
              ),
          ],
        ),
        if (through != null) ...[const SizedBox(height: 16), Text(through, style: muted)],
      ]),
      page('review-days', [
        title(l10n.reviewDaysTitle),
        const SizedBox(height: 16),
        for (final (label, n, color) in [
          (l10n.tileHome, summary.home.length, colors.homeCell),
          (l10n.tileAway, summary.away.length, colors.away),
          (l10n.tileUnknown, summary.unknown, colors.unknown),
        ]) ...[
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
              Text(l10n.daysFull(n), style: display(size: 22, height: 1)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        title(l10n.reviewLongest),
        const SizedBox(height: 8),
        if (longest == null)
          Text(l10n.reviewNoTrips, style: muted)
        else
          Card(
            child: ListTile(
              key: const Key('review-longest'),
              leading: longest.countryCode == null
                  ? null
                  : CountryFlag(code: longest.countryCode, width: 30),
              title: Text(
                [
                  countryName(context, longest.countryCode, longest.country),
                  if (longest.city.trim().isNotEmpty) longest.city.trim(),
                ].join(', '),
              ),
              subtitle: Text(
                '${longest.arrival.text(context)} — ${longest.departure.text(context)} · ${l10n.daysFull(longest.days)}',
              ),
            ),
          ),
        if (through != null) ...[const SizedBox(height: 16), Text(through, style: muted)],
      ]),
      if (widget.map case final WorldMapData map)
        page('review-map', [
          title(l10n.reviewMapTitle),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: WorldMap(
              data: map,
              style: _mapStyle(
                context,
                MapFills.of(map, snapshot, today, year: year),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.mapNote, style: muted),
        ]),
      if (cities.isNotEmpty)
        page('review-cities', [
          big(l10n.reviewCities(cities.length)),
          const SizedBox(height: 6),
          Text(l10n.reviewCitiesSub, style: muted),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in cities.take(30)) Chip(label: Text(c))],
          ),
        ]),
      page('review-share', [
        title(l10n.reviewShareTitle),
        const SizedBox(height: 8),
        Text(l10n.reviewShareBody, style: muted),
        const SizedBox(height: 20),
        if (ShareScope.of(context) != null)
          FilledButton.icon(
            key: const Key('reviewShare'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => SharePage(
                  controller: widget.controller,
                  year: year,
                  slots: widget.slots,
                ),
              ),
            ),
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(l10n.shareYear),
          ),
      ]),
    ];
    return Scaffold(
      key: const Key('yearReviewPage'),
      appBar: AppBar(title: Text(l10n.reviewTitle(year))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                key: const Key('reviewPages'),
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    GestureDetector(
                      onTap: () => _pages.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      child: Container(
                        width: i == _page ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _page ? scheme.primary : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
