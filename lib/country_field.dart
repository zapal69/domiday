import 'package:flutter/material.dart';

import 'countries.dart';
import 'flag.dart';
import 'format.dart';
import 'trip.dart';

/// Поле страны: текстовый ввод со списком стран из справочника.
/// Выбор из списка подставляет название на языке интерфейса; оно всегда
/// сопоставляется с кодом. Свободный текст допустим — тогда запись
/// сохраняется без кода, и строка под полем об этом говорит.
class CountryField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final bool enabled;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final int maxLines;

  /// Коды своих стран (текущая, домашняя, недавние) — в начале списка,
  /// пока в поле ничего не введено; дальше алфавит.
  final List<String> suggested;

  const CountryField({
    super.key,
    required this.controller,
    required this.label,
    required this.fieldKey,
    this.enabled = true,
    this.helperText,
    this.onChanged,
    this.focusNode,
    this.maxLines = 1,
    this.suggested = const [],
  });

  @override
  Widget build(BuildContext context) {
    final directory = CountryScope.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final ownCount = suggested
        .where((c) => directory[c] != null)
        .toSet()
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<Country>(
          textEditingController: controller,
          focusNode: focusNode ?? FocusNode(),
          displayStringForOption: (c) => c.name(language),
          optionsBuilder: (value) {
            if (directory.all.isEmpty) return const Iterable<Country>.empty();
            // Точное совпадение уже выбрано — список не нужен.
            if (directory.match(value.text) != null &&
                normalize(value.text) ==
                    normalize(
                      directory[directory.match(value.text)]!.name(language),
                    )) {
              return const Iterable<Country>.empty();
            }
            // Пустое поле — свои страны сверху и весь алфавит (≈250).
            return directory.search(value.text, language, first: suggested);
          },
          onSelected: (c) => onChanged?.call(c.name(language)),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: (MediaQuery.sizeOf(context).width - 40).clamp(
                  0.0,
                  680.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: Builder(
                    builder: (context) {
                      final list = options.toList();
                      final muted = TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      );
                      // Черта между своими странами и алфавитом.
                      final divideAfter = cleanText(controller.text).isEmpty
                          ? ownCount - 1
                          : -1;
                      return ListView.builder(
                        key: const Key('countryOptions'),
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final option = list[i];
                          final tile = ListTile(
                            dense: true,
                            leading: CountryFlag(code: option.code, width: 28),
                            title: Text(option.name(language)),
                            trailing: Text(option.code, style: muted),
                            onTap: () => onSelected(option),
                          );
                          return i == divideAfter
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [tile, const Divider(height: 1)],
                                )
                              : tile;
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          fieldViewBuilder: (context, textController, focus, submit) =>
              TextFormField(
                key: fieldKey,
                controller: textController,
                focusNode: focus,
                enabled: enabled,
                maxLength: 120,
                minLines: 1,
                maxLines: maxLines,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: label,
                  helperText: helperText,
                  helperMaxLines: 3,
                  errorMaxLines: 3,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                validator: (value) => cleanText(value ?? '').isEmpty
                    ? l10n.countryRequired
                    : null,
                onChanged: onChanged,
              ),
        ),
        // Статус сопоставления: ListenableBuilder следит за текстом.
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final text = cleanText(controller.text);
            if (text.isEmpty || directory.all.isEmpty) {
              return const SizedBox.shrink();
            }
            final code = directory.match(text);
            final muted = TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            );
            return Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: code == null
                  ? Text(
                      l10n.countryNoCode,
                      key: const Key('countryNoCode'),
                      style: muted,
                    )
                  : Text(
                      l10n.countryResolved(
                        directory[code]!.name(language),
                        code,
                      ),
                      key: const Key('countryResolved'),
                      style: muted,
                    ),
            );
          },
        ),
      ],
    );
  }
}
