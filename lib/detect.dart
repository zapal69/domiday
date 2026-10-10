import 'package:flutter/material.dart';

import 'borders.dart';
import 'countries.dart';
import 'format.dart';
import 'journal_controller.dart';
import 'locator.dart';
import 'settings.dart';
import 'trip.dart';

enum DetectOutcome { denied, serviceOff, failed, none, same, silenced, pending }

/// Итог определения: что произошло и текст для пользователя (null, когда
/// открыт экран подтверждения).
class DetectResult {
  final DetectOutcome outcome;
  final String? message;

  /// Отказ «больше не спрашивать»: разрешение дают только в настройках.
  final bool forever;
  const DetectResult(this.outcome, this.message, {this.forever = false});
}

/// Одно определение страны по явному действию: координаты → офлайн-границы
/// → кандидат в настройках → экран подтверждения.
Future<DetectResult> detectCountry({
  required BuildContext context,
  required LocationSource location,
  required CountryBorders borders,
  required JournalController journal,
  required SettingsController settings,
  required Day today,
  required Future<void> Function(Candidate candidate) review,
  bool silent = false,
}) async {
  final l10n = context.l10n;
  final result = await location.current(silent: silent);
  switch (result) {
    case PermissionDenied(forever: final forever):
      return DetectResult(
        DetectOutcome.denied,
        l10n.detectDenied,
        forever: forever,
      );
    case ServiceDisabled():
      return DetectResult(DetectOutcome.serviceOff, l10n.detectServiceOff);
    case Unavailable():
      return DetectResult(DetectOutcome.failed, l10n.detectFailed);
    case Observed(observation: final o):
      final located = borders.locate(
        o.latitude,
        o.longitude,
        accuracyM: o.accuracyM,
      );
      final code = located.code;
      if (code == null) {
        return DetectResult(DetectOutcome.none, l10n.detectNone);
      }
      final current = journal.snapshot.current;
      final outcome = await settings.offer(
        code: code,
        today: today,
        accuracyM: o.accuracyM.round(),
        uncertain: located.uncertain,
        alternatives: located.alternatives,
        currentCode: current?.countryCode,
      );
      if (!context.mounted) {
        return const DetectResult(DetectOutcome.pending, null);
      }
      switch (outcome) {
        case OfferOutcome.sameCountry:
          return DetectResult(
            DetectOutcome.same,
            l10n.detectSame(
              countryName(
                context,
                current?.countryCode,
                current?.country ?? '',
              ),
            ),
          );
        case OfferOutcome.silenced:
          return DetectResult(
            DetectOutcome.silenced,
            l10n.detectSilenced(Candidate.silenceDays),
          );
        case OfferOutcome.pending:
          await review(settings.candidate!);
          return const DetectResult(DetectOutcome.pending, null);
      }
  }
}

/// «Похоже, вы сейчас в …»: подтвердить, исправить, транзит, это ошибка.
/// Сам экран ничего не пишет; запись делают только существующие редакторы.
class DetectionPage extends StatelessWidget {
  final Candidate candidate;
  final JournalController controller;
  final SettingsController settings;
  final Day today;

  /// Открыть экран смены страны с предзаполнением; возвращает true, если
  /// смена подтверждена и сохранена.
  final Future<bool> Function(String? country, Day arrival) onChange;

  /// Открыть редактор транзита с черновиком; true, если сохранён.
  final Future<bool> Function(Trip draft) onTransit;

  const DetectionPage({
    super.key,
    required this.candidate,
    required this.controller,
    required this.settings,
    required this.today,
    required this.onChange,
    required this.onTransit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final directory = CountryScope.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final name = directory.display(candidate.code, candidate.code, language);
    final alternatives = candidate.alternatives
        .map((c) => directory.display(c, c, language))
        .join(', ');
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);
    final km = (candidate.accuracyM / 1000)
        .clamp(0.1, 999)
        .toStringAsFixed(candidate.accuracyM < 1000 ? 1 : 0);

    Future<void> finish(bool saved) async {
      if (saved) await settings.clearCandidate();
      if (context.mounted && saved) Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.detectTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const Key('detectionPage'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  l10n.candidateTitle(name),
                  key: const Key('candidateTitle'),
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (candidate.uncertain) ...[
                  const SizedBox(height: 12),
                  Text(
                    alternatives.isEmpty
                        ? l10n.candidateUncertainNoAlt
                        : l10n.candidateUncertain(alternatives),
                    key: const Key('candidateUncertain'),
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  l10n.candidateDetected(
                    candidate.detectedOn.text(context),
                    km,
                  ),
                  style: muted,
                ),
                const SizedBox(height: 8),
                Text(l10n.candidateNoRecord, style: muted),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('candidateConfirm'),
                  onPressed: () async =>
                      finish(await onChange(name, candidate.detectedOn)),
                  icon: const Icon(Icons.public_outlined),
                  label: Text(l10n.candidateConfirm),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('candidateCorrect'),
                  onPressed: () async =>
                      finish(await onChange(null, candidate.detectedOn)),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.candidateCorrect),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('candidateTransit'),
                  onPressed: () async => finish(
                    await onTransit(
                      Trip(
                        id: '',
                        country: name,
                        countryCode: candidate.code,
                        arrival: candidate.detectedOn,
                        departure: candidate.detectedOn,
                        kind: TripKind.transit,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.connecting_airports_outlined),
                  label: Text(l10n.candidateTransit),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  key: const Key('candidateDismiss'),
                  onPressed: () async {
                    await settings.dismissCandidate();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.candidateDismissed(Candidate.silenceDays),
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: Text(l10n.candidateDismiss),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Баннер ожидающего кандидата на дашборде.
class CandidateBanner extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback onReview;
  const CandidateBanner({
    super.key,
    required this.candidate,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final directory = CountryScope.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Card(
      key: const Key('candidateBanner'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              l10n.candidateBanner(
                directory.display(candidate.code, candidate.code, language),
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(
              key: const Key('candidateReview'),
              onPressed: onReview,
              child: Text(l10n.candidateReview),
            ),
          ],
        ),
      ),
    );
  }
}
