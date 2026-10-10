part of 'main.dart';

/// Границы стран для импорта истории (null — импорт недоступен).
class ImportScope extends InheritedWidget {
  final CountryBorders? borders;
  const ImportScope({super.key, required this.borders, required super.child});
  static CountryBorders? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ImportScope>()?.borders;
  @override
  bool updateShouldNotify(ImportScope old) => old.borders != borders;
}

/// Импорт Хронологии Google Maps: сначала экран-инструкция (откуда взять
/// файл), с него — выбор файла и предпросмотр.
Future<void> startTimelineImport(
  BuildContext context,
  JournalController controller,
) async {
  if (BackupScope.of(context) == null || ImportScope.of(context) == null) {
    return;
  }
  await Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => ImportIntroPage(controller: controller)),
  );
}

/// Три шага: выгрузить Хронологию, сохранить файл, выбрать его здесь.
/// Выбор показывает только JSON; «Показать все файлы» — на случай, если
/// система не знает тип файла. Предпросмотр заменяет этот экран, так что
/// «Назад» из него ведёт туда, откуда начали.
class ImportIntroPage extends StatefulWidget {
  final JournalController controller;
  const ImportIntroPage({super.key, required this.controller});
  @override
  State<ImportIntroPage> createState() => _ImportIntroPageState();
}

class _ImportIntroPageState extends State<ImportIntroPage> {
  bool _busy = false;

  Future<void> _choose({required bool jsonOnly}) async {
    final store = BackupScope.of(context);
    final borders = ImportScope.of(context);
    if (store == null || borders == null || _busy) return;
    setState(() => _busy = true);
    final BackupPick? pick;
    try {
      pick = await store.open(jsonOnly: jsonOnly);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (pick == null || !mounted) return;
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => ImportPage(
          controller: widget.controller,
          file: pick!,
          borders: borders,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget step(int n, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: Text(
            '$n',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const Key('importIntro'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(l10n.importIntroLead),
                const SizedBox(height: 20),
                step(1, l10n.importStep1),
                const SizedBox(height: 16),
                step(2, l10n.importStep2),
                const SizedBox(height: 16),
                step(3, l10n.importStep3),
                const SizedBox(height: 20),
                Text(
                  l10n.importNoTimeline,
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('importChoose'),
                  onPressed: _busy ? null : () => _choose(jsonOnly: true),
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(l10n.importChoose),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('importAnyFile'),
                  onPressed: _busy ? null : () => _choose(jsonOnly: false),
                  child: Text(l10n.importAnyFile, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ImportAnalysis _analyzeInIsolate((String, CountryBorders) input) =>
    analyzeTimeline(input.$1, input.$2);

/// Предпросмотр импорта: периоды по странам с галочками, сверка с
/// дневником; при онбординге — домашняя и текущая страна. Запись — одной
/// операцией после подтверждения.
class ImportPage extends StatefulWidget {
  final JournalController controller;
  final BackupPick file;
  final CountryBorders borders;
  const ImportPage({
    super.key,
    required this.controller,
    required this.file,
    required this.borders,
  });
  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  ImportAnalysis? _analysis;
  List<ImportRow> _rows = const [];
  bool _failed = false;
  bool _busy = false;
  final _home = TextEditingController();
  final _current = TextEditingController();

  bool get _onboarding => widget.controller.snapshot.needsOnboarding;

  /// Страны из файла для начала списка: самая частая, затем последние.
  List<String> get _fileCodes => [
    ?_analysis?.frequentCode,
    for (final p in (_analysis?.periods ?? const []).reversed) p.code,
  ];
  bool get _hasCurrentRow => _rows.any((r) => r.status == ImportStatus.current);
  int get _selected =>
      _rows.where((r) => r.selected && r.status != ImportStatus.exists).length;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  @override
  void dispose() {
    _home.dispose();
    _current.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    try {
      final analysis = await compute(_analyzeInIsolate, (
        widget.file.contents,
        widget.borders,
      ));
      if (!mounted) return;
      final directory = CountryScope.of(context);
      final rows = planImport(
        analysis.periods,
        widget.controller.snapshot,
        widget.controller.today(),
        match: directory.match,
      );
      if (_onboarding) {
        final lang = Localizations.localeOf(context).languageCode;
        final home = analysis.frequentCode;
        if (home != null) _home.text = directory.display(home, home, lang);
        final last = analysis.periods.isEmpty
            ? null
            : analysis.periods.last.code;
        if (last != null) _current.text = directory.display(last, last, lang);
      }
      setState(() {
        _analysis = analysis;
        _rows = rows;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final controller = widget.controller;
    final directory = CountryScope.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);
    final count = _selected;
    if (_onboarding) {
      if (cleanText(_home.text).isEmpty) {
        await _notice(context, l10n.importTitle, l10n.errCountryRequired);
        return;
      }
      if (!_hasCurrentRow && cleanText(_current.text).isEmpty) {
        await _notice(context, l10n.importTitle, l10n.errCountryRequired);
        return;
      }
    }
    if (!mounted) return;
    final ok = await _confirm(
      context,
      l10n.importConfirmTitle,
      l10n.importConfirmText(l10n.recordsCount(count)),
      l10n.importConfirmAction,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = applyImport(
        controller.snapshot,
        _rows,
        today: controller.today(),
        newId: _newId,
        nameOf: (code) => directory.display(code, code, lang),
        homeCountry: _onboarding ? cleanText(_home.text) : null,
        homeCountryCode: _onboarding ? directory.match(_home.text) : null,
        currentCountry: _onboarding && !_hasCurrentRow
            ? cleanText(_current.text)
            : null,
        currentCountryCode: _onboarding && !_hasCurrentRow
            ? directory.match(_current.text)
            : null,
      );
      await controller.commit(next);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importDone(l10n.recordsCount(count)))),
      );
      Navigator.pop(context);
    } on JournalError catch (e) {
      if (mounted) {
        await _notice(context, l10n.importTitle, describeError(context, e));
      }
    } catch (_) {
      if (mounted) {
        await _notice(context, l10n.importTitle, l10n.importInvalid);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _details(ImportRow row) {
    final l10n = context.l10n;
    final p = row.period;
    final parts = <String>[
      l10n.daysFull(p.days),
      if (p.transit) l10n.importTransit,
      if (p.gapDays > 0) l10n.importGap(l10n.daysFull(p.gapDays)),
      switch (row.status) {
        ImportStatus.exists => l10n.importStatusExists,
        ImportStatus.conflict => l10n.importStatusConflict(
          countryName(context, row.overlaps, row.overlaps ?? ''),
        ),
        ImportStatus.current => l10n.importStatusCurrent,
        ImportStatus.add => '',
      },
    ].where((s) => s.isNotEmpty);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final analysis = _analysis;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _failed
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        widget.file.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.importFailed),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          key: const Key('importOtherFile'),
                          onPressed: () =>
                              Navigator.pushReplacement<void, void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImportIntroPage(
                                    controller: widget.controller,
                                  ),
                                ),
                              ),
                          icon: const Icon(Icons.file_open_outlined),
                          label: Text(l10n.importOtherFile),
                        ),
                      ),
                    ],
                  )
                : analysis == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l10n.importAnalyzing),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Text(
                        widget.file.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        analysis.periods.isEmpty
                            ? l10n.importNothing
                            : l10n.importSummary(
                                analysis.samples,
                                analysis.daysWithData,
                                analysis.first!.text(context),
                                analysis.last!.text(context),
                              ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_onboarding && analysis.periods.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        CountryField(
                          controller: _home,
                          fieldKey: const Key('importHome'),
                          suggested: _fileCodes,
                          label: l10n.homeCountry,
                          helperText: l10n.importHomeHelper,
                          enabled: !_busy,
                        ),
                        if (!_hasCurrentRow) ...[
                          const SizedBox(height: 12),
                          CountryField(
                            controller: _current,
                            fieldKey: const Key('importCurrent'),
                            suggested: _fileCodes,
                            label: l10n.currentCountry,
                            helperText: l10n.importCurrentHelper,
                            enabled: !_busy,
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      for (var i = 0; i < _rows.length; i++)
                        CheckboxListTile(
                          key: Key('import-$i'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _rows[i].selected,
                          enabled:
                              !_busy && _rows[i].status != ImportStatus.exists,
                          onChanged: (v) =>
                              setState(() => _rows[i].selected = v ?? false),
                          title: Text(
                            '${countryName(context, _rows[i].period.code, _rows[i].period.code)}'
                            ' · ${_rows[i].period.start.text(context)}'
                            ' — ${_rows[i].period.end.text(context)}',
                          ),
                          subtitle: Text(_details(_rows[i])),
                        ),
                      const SizedBox(height: 20),
                      if (analysis.periods.isNotEmpty)
                        FilledButton(
                          key: const Key('importApply'),
                          onPressed: _busy || (_selected == 0 && !_onboarding)
                              ? null
                              : _apply,
                          child: Text(
                            l10n.importApply(l10n.recordsCount(_selected)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.importFootnote,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
