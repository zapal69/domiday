import 'package:flutter/material.dart';

import 'format.dart';
import 'settings.dart';

/// Раскрытие и согласие до системного запроса геолокации (требование
/// Google Play «Prominent Disclosure and Consent»): что за данные, зачем
/// и в каком режиме. Согласие — только явная кнопка «Принять»; закрытие
/// окна, «Назад» и «Не нужно» означают отказ, запрос не вызывается.
Future<bool> showLocationDisclosure(
  BuildContext context, {
  required bool background,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return AlertDialog(
        key: Key(background ? 'consentBackground' : 'consentLocation'),
        scrollable: true,
        icon: const Icon(Icons.location_on_outlined),
        title: Text(
          background ? l10n.consentBackgroundTitle : l10n.consentLocationTitle,
        ),
        content: Text(
          background ? l10n.consentBackgroundBody : l10n.consentLocationBody,
        ),
        actions: [
          TextButton(
            key: const Key('consentDecline'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.consentDecline),
          ),
          FilledButton(
            key: const Key('consentAccept'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.consentAccept),
          ),
        ],
      );
    },
  );
  return accepted == true;
}

/// Перед определением по действию пользователя: окно показывается один
/// раз, согласие хранится в настройках. Без согласия определение не идёт.
Future<bool> ensureLocationConsent(
  BuildContext context,
  SettingsController settings,
) async {
  if (settings.settings.locationConsent) return true;
  final accepted = await showLocationDisclosure(context, background: false);
  if (accepted) await settings.setLocationConsent(true);
  return accepted;
}
