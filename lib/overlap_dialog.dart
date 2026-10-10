import 'package:flutter/material.dart';

import 'countries.dart';
import 'format.dart';
import 'overlap.dart';
import 'trip.dart';

/// Диалог «Дни уже заняты»: список задетых записей и того, что с ними
/// станет. Возвращает true — «Заменить», false — «Оставить обе»,
/// null — «Отмена» (ничего не записывается).
Future<bool?> showOverlapDialog(BuildContext context, OverlapPlan plan) {
  final l10n = context.l10n;
  final directory = CountryScope.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  String name(OverlapItem item) {
    final code = item.countryCode;
    final label = code == null
        ? item.country
        : directory.display(code, item.country, lang);
    return item.sameCountry ? l10n.overlapSameCountry(label) : label;
  }

  String range(Day from, Day to) =>
      '${from.text(context)} — ${to.text(context)}';
  String line(OverlapItem item) => switch (item.outcome) {
    OverlapOutcome.trim => l10n.overlapTrim(
      name(item),
      range(item.trip!.arrival, item.trip!.departure),
      range(item.pieces.single.arrival, item.pieces.single.departure),
    ),
    OverlapOutcome.split => l10n.overlapSplit(
      name(item),
      range(item.trip!.arrival, item.trip!.departure),
      range(item.pieces.first.arrival, item.pieces.first.departure),
      range(item.pieces.last.arrival, item.pieces.last.departure),
    ),
    OverlapOutcome.remove => l10n.overlapRemove(
      name(item),
      range(item.trip!.arrival, item.trip!.departure),
    ),
    OverlapOutcome.moveCurrent => l10n.overlapCurrent(
      name(item),
      item.newArrival!.text(context),
    ),
    OverlapOutcome.unresolved => l10n.overlapCurrentFixed(name(item)),
  };

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('overlapDialog'),
      scrollable: true,
      title: Text(l10n.overlapTitle),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.overlapIntro(range(plan.trip.arrival, plan.trip.departure)),
          ),
          const SizedBox(height: 12),
          for (final item in plan.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• ${line(item)}'),
            ),
          const SizedBox(height: 4),
          Text(
            plan.canReplace ? l10n.overlapHint : l10n.overlapHintKeepOnly,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('overlapKeep'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.overlapKeep),
        ),
        if (plan.canReplace)
          FilledButton(
            key: const Key('overlapReplace'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.overlapReplace),
          ),
      ],
    ),
  );
}
