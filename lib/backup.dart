import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'snapshot.dart';
import 'trip.dart';

/// Формат файла резервной копии: обёртка над снимком дневника в его
/// текущей схеме. Файл создаётся и читается только по действию владельца
/// через системный выбор файла; на телефоне копия не хранится.
const backupFormat = 'domiday-backup';
const backupVersion = 1;

String backupFileName(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'domiday-backup-${now.year}-${two(now.month)}-${two(now.day)}.json';
}

String encodeBackup(
  JournalSnapshot snapshot, {
  required DateTime now,
  required String appVersion,
}) => const JsonEncoder.withIndent('  ').convert({
  'format': backupFormat,
  'backupVersion': backupVersion,
  'createdAt': now.toUtc().toIso8601String(),
  'appVersion': appVersion,
  'journal': snapshot.toJson(),
});

class BackupInfo {
  final JournalSnapshot snapshot;
  final DateTime? createdAt;
  final String? appVersion;
  const BackupInfo({
    required this.snapshot,
    required this.createdAt,
    required this.appVersion,
  });
}

enum BackupErrorCode {
  /// Не JSON или не наш формат.
  notBackup,

  /// Копия или дневник в ней сделаны более новой версией приложения:
  /// не читаем и ничего не перезаписываем.
  newer,

  /// Наш формат, но содержимое дневника невалидно.
  corrupt,
}

class BackupError implements Exception {
  final BackupErrorCode code;
  const BackupError(this.code);
  @override
  String toString() => 'BackupError(${code.name})';
}

/// Разбор файла копии. Дневник проходит те же проверки, что при чтении
/// trips.json (включая отказ от неизвестной схемы).
BackupInfo decodeBackup(String text, Day today) {
  Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw const BackupError(BackupErrorCode.notBackup);
  }
  if (json is! Map<String, Object?> || json['format'] != backupFormat) {
    throw const BackupError(BackupErrorCode.notBackup);
  }
  final version = json['backupVersion'];
  if (version is! int || version < 1) {
    throw const BackupError(BackupErrorCode.notBackup);
  }
  if (version > backupVersion) throw const BackupError(BackupErrorCode.newer);
  final journal = json['journal'];
  if (journal is! Map<String, Object?>) {
    throw const BackupError(BackupErrorCode.corrupt);
  }
  final schema = journal['schemaVersion'];
  if (schema is int && schema > 5) {
    throw const BackupError(BackupErrorCode.newer);
  }
  final JournalSnapshot snapshot;
  try {
    snapshot = JournalSnapshot.fromJson(journal, today);
  } catch (_) {
    throw const BackupError(BackupErrorCode.corrupt);
  }
  final created = json['createdAt'];
  return BackupInfo(
    snapshot: snapshot,
    createdAt: created is String ? DateTime.tryParse(created) : null,
    appVersion: json['appVersion'] is String
        ? json['appVersion'] as String
        : null,
  );
}

/// Выбранный владельцем файл для восстановления.
class BackupPick {
  final String name;
  final String contents;
  const BackupPick(this.name, this.contents);
}

/// Системные диалоги «сохранить файл» / «открыть файл». В тестах
/// подменяется.
abstract interface class BackupStore {
  /// true — записан; false — владелец отменил диалог.
  Future<bool> save(String fileName, String contents);

  /// null — владелец отменил диалог. [jsonOnly] — системный выбор
  /// показывает только JSON (экспорт Хронологии), а не недавние фото.
  Future<BackupPick?> open({bool jsonOnly = false});
}

/// Storage Access Framework через file_picker: без разрешений на
/// хранилище, файл кладётся туда, куда указал владелец (Google Drive,
/// «Файлы» и т. д.).
/// Выбранный файл: имя и чтение содержимого. Свой тип, чтобы не зависеть
/// от классов плагина в тестах.
class PickedFile {
  final String name;
  final Future<Uint8List> Function() read;
  const PickedFile(this.name, this.read);
}

class FilePickerStore implements BackupStore {
  /// Выбор файла и очистка временных копий; подменяются в тестах.
  final Future<List<PickedFile>> Function() pick;
  final Future<List<PickedFile>> Function() pickJson;
  final Future<void> Function() clear;
  const FilePickerStore({
    this.pick = pickWithPlugin,
    this.pickJson = pickJsonWithPlugin,
    this.clear = FilePicker.clearTemporaryFiles,
  });

  static Future<List<PickedFile>> pickWithPlugin() async => [
    for (final f in await FilePicker.pickFiles()) PickedFile(f.name, f.readAsBytes),
  ];

  /// Фильтр по типу application/json. Если система не знает тип файла,
  /// он может не попасть в список — для этого на экране импорта есть
  /// «Показать все файлы».
  static Future<List<PickedFile>> pickJsonWithPlugin() async => [
    for (final f in await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    ))
      PickedFile(f.name, f.readAsBytes),
  ];

  @override
  Future<bool> save(String fileName, String contents) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: 'application/json',
    );
    return uri != null;
  }

  /// Плагин на Android копирует выбранный файл в кэш приложения. Копия
  /// экспорта Хронологии содержит координаты, поэтому после чтения (и при
  /// отмене, и при ошибке) временные файлы удаляются.
  @override
  Future<BackupPick?> open({bool jsonOnly = false}) async {
    try {
      final files = await (jsonOnly ? pickJson : pick)();
      if (files.isEmpty) return null;
      final file = files.first;
      return BackupPick(file.name, utf8.decode(await file.read()));
    } finally {
      try {
        await clear();
      } catch (_) {
        // Нет временных файлов или платформа без кэша — не ошибка.
      }
    }
  }
}

/// Для тестов: запоминает сохранённое, отдаёт заданный файл.
class FakeBackupStore implements BackupStore {
  String? savedName;
  String? saved;
  BackupPick? toOpen;
  bool cancelSave = false;

  /// Как был открыт последний выбор файла: null — не открывался.
  bool? lastJsonOnly;
  @override
  Future<bool> save(String fileName, String contents) async {
    if (cancelSave) return false;
    savedName = fileName;
    saved = contents;
    return true;
  }

  @override
  Future<BackupPick?> open({bool jsonOnly = false}) async {
    lastJsonOnly = jsonOnly;
    return toOpen;
  }
}
