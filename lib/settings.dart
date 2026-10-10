import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'trip.dart';

/// Кандидат на смену страны: предположение, ожидающее решения. Не влияет
/// на текущую страну, календарь и итоги, пока пользователь не подтвердит.
@immutable
class Candidate {
  final String code;
  final Day detectedOn;
  final int accuracyM;
  final bool uncertain;
  final List<String> alternatives;

  /// Отклонённый кандидат молчит, пока код не сменится или не пройдёт
  /// [silenceDays] дней.
  final bool dismissed;
  const Candidate({
    required this.code,
    required this.detectedOn,
    required this.accuracyM,
    required this.uncertain,
    this.alternatives = const [],
    this.dismissed = false,
  });

  static const silenceDays = 14;

  Candidate copyWith({
    Day? detectedOn,
    int? accuracyM,
    bool? uncertain,
    List<String>? alternatives,
    bool? dismissed,
  }) => Candidate(
    code: code,
    detectedOn: detectedOn ?? this.detectedOn,
    accuracyM: accuracyM ?? this.accuracyM,
    uncertain: uncertain ?? this.uncertain,
    alternatives: alternatives ?? this.alternatives,
    dismissed: dismissed ?? this.dismissed,
  );

  Map<String, Object?> toJson() => {
    'code': code,
    'detectedOn': detectedOn.iso,
    'accuracyM': accuracyM,
    'uncertain': uncertain,
    'alternatives': alternatives,
    'dismissed': dismissed,
  };

  static Candidate? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    try {
      final code = json['code'];
      if (code is! String || !isCountryCode(code)) return null;
      return Candidate(
        code: code,
        detectedOn: Day.parse(json['detectedOn'] as String),
        accuracyM: (json['accuracyM'] as num?)?.toInt() ?? 0,
        uncertain: json['uncertain'] == true,
        alternatives: [
          for (final a in (json['alternatives'] as List?) ?? const [])
            if (a is String && isCountryCode(a)) a,
        ],
        dismissed: json['dismissed'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Итог предложения кандидата контроллеру.
enum OfferOutcome { sameCountry, pending, silenced }

/// Настройки приложения, не относящиеся к дневнику: сейчас только язык.
/// Хранятся отдельно от trips.json, чтобы не менять схему данных.
@immutable
class AppSettings {
  /// null — язык системы.
  final Locale? locale;
  final Candidate? candidate;

  /// Тема: system по умолчанию, light или dark принудительно.
  final ThemeMode themeMode;

  /// Проверять страну при открытии приложения (одно определение, не чаще
  /// раза в час, без диалогов).
  final bool autoDetect;
  final DateTime? lastAutoCheck;

  /// Ключ текущей страны на момент последней автопроверки: смена страны
  /// делает проверку обязательной независимо от интервала.
  final String? lastAutoCheckKey;

  /// Фоновая проверка (WorkManager) — только по явному включению.
  final bool backgroundDetect;

  /// Владелец нажал «Проверять в фоне», но разрешений ещё нет: Android
  /// перезапускает приложение при смене разрешений, поэтому намерение
  /// хранится на диске и доводится до конца после возврата.
  final bool backgroundRequested;

  /// О каком кандидате уже уведомляли и когда: повторные срабатывания
  /// не создают поток уведомлений.
  final String? notifiedCode;
  final DateTime? notifiedAt;

  /// Когда и чем закончилась последняя фоновая проверка (имя
  /// BackgroundOutcome или «error») — чтобы фон не был чёрным ящиком.
  final DateTime? lastBackgroundRun;
  final String? lastBackgroundOutcome;

  /// Текст исключения последней фоновой ошибки (для экрана настроек).
  final String? lastBackgroundError;

  /// Последние запуски фоновой проверки, новые в конце: «ISO|outcome».
  final List<String> backgroundLog;

  /// Когда владелец в последний раз сохранял резервную копию (по кнопке).
  final DateTime? lastBackupAt;

  /// До какого момента не напоминать о копии на дашборде («Позже»).
  final DateTime? backupNudgeUntil;
  const AppSettings({
    this.locale,
    this.candidate,
    this.themeMode = ThemeMode.system,
    this.autoDetect = true,
    this.lastAutoCheck,
    this.lastAutoCheckKey,
    this.backgroundDetect = false,
    this.backgroundRequested = false,
    this.notifiedCode,
    this.notifiedAt,
    this.lastBackgroundRun,
    this.lastBackgroundOutcome,
    this.lastBackgroundError,
    this.backgroundLog = const [],
    this.lastBackupAt,
    this.backupNudgeUntil,
  });

  static const backgroundLogLimit = 8;

  /// Напоминать о копии: записей уже несколько, а копии не было или она
  /// старше месяца, и владелец не нажимал «Позже».
  static const backupNudgeAfter = Duration(days: 30);
  static const backupNudgeMinTrips = 3;
  bool backupNudgeDue(DateTime now, int trips) {
    if (trips < backupNudgeMinTrips) return false;
    if (backupNudgeUntil != null && now.isBefore(backupNudgeUntil!)) {
      return false;
    }
    final last = lastBackupAt;
    return last == null || now.difference(last) > backupNudgeAfter;
  }

  static const schemaVersion = 1;
  static const supported = [Locale('en'), Locale('ru')];

  AppSettings copyWith({
    Locale? locale,
    bool clearLocale = false,
    Candidate? candidate,
    bool clearCandidate = false,
    ThemeMode? themeMode,
    bool? autoDetect,
    DateTime? lastAutoCheck,
    String? lastAutoCheckKey,
    bool? backgroundDetect,
    bool? backgroundRequested,
    String? notifiedCode,
    DateTime? notifiedAt,
    bool clearNotified = false,
    DateTime? lastBackgroundRun,
    String? lastBackgroundOutcome,
    String? lastBackgroundError,
    bool clearBackgroundError = false,
    List<String>? backgroundLog,
    DateTime? lastBackupAt,
    DateTime? backupNudgeUntil,
    bool clearBackupNudge = false,
  }) => AppSettings(
    locale: clearLocale ? null : (locale ?? this.locale),
    candidate: clearCandidate ? null : (candidate ?? this.candidate),
    themeMode: themeMode ?? this.themeMode,
    autoDetect: autoDetect ?? this.autoDetect,
    lastAutoCheck: lastAutoCheck ?? this.lastAutoCheck,
    lastAutoCheckKey: lastAutoCheckKey ?? this.lastAutoCheckKey,
    backgroundDetect: backgroundDetect ?? this.backgroundDetect,
    backgroundRequested: backgroundRequested ?? this.backgroundRequested,
    notifiedCode: clearNotified ? null : (notifiedCode ?? this.notifiedCode),
    notifiedAt: clearNotified ? null : (notifiedAt ?? this.notifiedAt),
    lastBackgroundRun: lastBackgroundRun ?? this.lastBackgroundRun,
    lastBackgroundOutcome: lastBackgroundOutcome ?? this.lastBackgroundOutcome,
    lastBackgroundError: clearBackgroundError
        ? null
        : (lastBackgroundError ?? this.lastBackgroundError),
    backgroundLog: backgroundLog ?? this.backgroundLog,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    backupNudgeUntil: clearBackupNudge
        ? null
        : (backupNudgeUntil ?? this.backupNudgeUntil),
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'locale': locale?.languageCode,
    'candidate': candidate?.toJson(),
    'themeMode': themeMode.name,
    'autoDetect': autoDetect,
    'lastAutoCheck': lastAutoCheck?.toUtc().toIso8601String(),
    'lastAutoCheckKey': lastAutoCheckKey,
    'backgroundDetect': backgroundDetect,
    'backgroundRequested': backgroundRequested,
    'notifiedCode': notifiedCode,
    'notifiedAt': notifiedAt?.toUtc().toIso8601String(),
    'lastBackgroundRun': lastBackgroundRun?.toUtc().toIso8601String(),
    'lastBackgroundOutcome': lastBackgroundOutcome,
    'lastBackgroundError': lastBackgroundError,
    'backgroundLog': backgroundLog,
    'lastBackupAt': lastBackupAt?.toUtc().toIso8601String(),
    'backupNudgeUntil': backupNudgeUntil?.toUtc().toIso8601String(),
  };

  /// Незнакомое или повреждённое содержимое даёт настройки по умолчанию:
  /// потеря выбора языка не стоит блокировки приложения.
  factory AppSettings.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const AppSettings();
    final candidate = Candidate.fromJson(json['candidate']);
    final code = json['locale'];
    Locale? locale;
    if (code is String) {
      for (final l in supported) {
        if (l.languageCode == code) locale = l;
      }
    }
    var themeMode = ThemeMode.system;
    for (final m in ThemeMode.values) {
      if (m.name == json['themeMode']) themeMode = m;
    }
    DateTime? last;
    if (json['lastAutoCheck'] is String) {
      last = DateTime.tryParse(json['lastAutoCheck'] as String);
    }
    return AppSettings(
      locale: locale,
      candidate: candidate,
      themeMode: themeMode,
      autoDetect: json['autoDetect'] != false,
      lastAutoCheck: last,
      lastAutoCheckKey: json['lastAutoCheckKey'] is String
          ? json['lastAutoCheckKey'] as String
          : null,
      backgroundDetect: json['backgroundDetect'] == true,
      backgroundRequested: json['backgroundRequested'] == true,
      notifiedCode: json['notifiedCode'] is String
          ? json['notifiedCode'] as String
          : null,
      notifiedAt: json['notifiedAt'] is String
          ? DateTime.tryParse(json['notifiedAt'] as String)
          : null,
      lastBackgroundRun: json['lastBackgroundRun'] is String
          ? DateTime.tryParse(json['lastBackgroundRun'] as String)
          : null,
      lastBackgroundOutcome: json['lastBackgroundOutcome'] is String
          ? json['lastBackgroundOutcome'] as String
          : null,
      lastBackgroundError: json['lastBackgroundError'] is String
          ? json['lastBackgroundError'] as String
          : null,
      backgroundLog: json['backgroundLog'] is List
          ? (json['backgroundLog'] as List).whereType<String>().toList()
          : const [],
      lastBackupAt: json['lastBackupAt'] is String
          ? DateTime.tryParse(json['lastBackupAt'] as String)
          : null,
      backupNudgeUntil: json['backupNudgeUntil'] is String
          ? DateTime.tryParse(json['backupNudgeUntil'] as String)
          : null,
    );
  }
}

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

/// settings.json рядом с trips.json; та же атомарная запись через
/// временный файл, но без проверки baseline — настройки неконфликтны.
class JsonSettingsRepository implements SettingsRepository {
  final Future<Directory> Function() directory;
  JsonSettingsRepository({Future<Directory> Function()? directory})
    : directory = directory ?? getApplicationSupportDirectory;

  Future<File> _file() async =>
      File('${(await directory()).path}/settings.json');

  @override
  Future<AppSettings> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const AppSettings();
      return AppSettings.fromJson(jsonDecode(await file.readAsString()));
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _queue = Future.value();
  int _serial = 0;

  /// Записи идут строго по очереди, каждая через свой временный файл:
  /// две одновременные записи (например, переключатель фоновой проверки
  /// и отметка о её запуске) раньше делили один `settings.json.tmp`, и
  /// вторая падала на переименовании уже исчезнувшего файла.
  @override
  Future<void> save(AppSettings settings) {
    final encoded = jsonEncode(settings.toJson());
    final run = _queue.then((_) async {
      final file = await _file();
      final temporary = File('${file.path}.${_serial++}.tmp');
      await temporary.writeAsString(encoded, flush: true);
      await temporary.rename(file.path);
    });
    _queue = run.catchError((_) {});
    return run;
  }
}

class MemorySettingsRepository implements SettingsRepository {
  AppSettings settings;
  int writes = 0;
  MemorySettingsRepository([this.settings = const AppSettings()]);
  @override
  Future<AppSettings> load() async => settings;
  @override
  Future<void> save(AppSettings next) async {
    writes++;
    settings = next;
  }
}

/// Владелец настроек: публикует изменение только после успешной записи.
class SettingsController extends ChangeNotifier {
  final SettingsRepository repository;
  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  SettingsController(this.repository);

  final _ready = Completer<void>();

  /// Завершается после первого чтения settings.json (или его отсутствия).
  Future<void> get ready => _ready.future;

  Future<void> load() async {
    _settings = await repository.load();
    if (!_ready.isCompleted) _ready.complete();
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    final next = locale == null
        ? _settings.copyWith(clearLocale: true)
        : _settings.copyWith(locale: locale);
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  Candidate? get candidate => _settings.candidate;

  Future<void> setThemeMode(ThemeMode mode) async {
    final next = _settings.copyWith(themeMode: mode);
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  Future<void> setAutoDetect(bool enabled) async {
    final next = _settings.copyWith(autoDetect: enabled);
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  Future<void> setBackgroundDetect(bool enabled) async {
    final next = _settings.copyWith(
      backgroundDetect: enabled,
      backgroundRequested: false,
    );
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  Future<void> setBackgroundRequested(bool requested) async {
    final next = _settings.copyWith(backgroundRequested: requested);
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  /// Уведомлять ли о кандидате: новый код — да; тот же — не чаще раза в
  /// [notifyInterval].
  static const notifyInterval = Duration(hours: 12);
  bool shouldNotify(String code, DateTime now) {
    final s = _settings;
    if (s.notifiedCode != code || s.notifiedAt == null) return true;
    return now.difference(s.notifiedAt!) >= notifyInterval;
  }

  Future<void> markBackgroundRun(
    String outcome,
    DateTime now, {
    String? error,
  }) async {
    final log = [
      ..._settings.backgroundLog,
      '${now.toUtc().toIso8601String()}|$outcome',
    ];
    final next = _settings.copyWith(
      lastBackgroundRun: now,
      lastBackgroundOutcome: outcome,
      lastBackgroundError: error,
      clearBackgroundError: error == null,
      backgroundLog: log.length > AppSettings.backgroundLogLimit
          ? log.sublist(log.length - AppSettings.backgroundLogLimit)
          : log,
    );
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  Future<void> markNotified(String code, DateTime now) async {
    final next = _settings.copyWith(notifiedCode: code, notifiedAt: now);
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  /// Автопроверка нужна, если включена и либо прошёл интервал, либо
  /// текущая страна изменилась с прошлой проверки.
  static const autoCheckInterval = Duration(minutes: 15);
  bool autoCheckDue(DateTime now, String? currentKey) {
    if (!_settings.autoDetect) return false;
    final last = _settings.lastAutoCheck;
    if (last == null) return true;
    if (currentKey != _settings.lastAutoCheckKey) return true;
    return now.difference(last) >= autoCheckInterval;
  }

  Future<void> markAutoCheck(DateTime now, String? currentKey) async {
    final next = _settings.copyWith(
      lastAutoCheck: now,
      lastAutoCheckKey: currentKey,
    );
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  /// Предложить кандидата по результату определения. Та же страна, что и
  /// текущая, — кандидата нет; повтор ожидающего — только обновление даты;
  /// отклонённый молчит до смены кода или истечения silenceDays.
  Future<OfferOutcome> offer({
    required String code,
    required Day today,
    required int accuracyM,
    required bool uncertain,
    required List<String> alternatives,
    required String? currentCode,
  }) async {
    if (currentCode != null && code == currentCode) {
      if (_settings.candidate != null) await _write(clearCandidate: true);
      return OfferOutcome.sameCountry;
    }
    final existing = _settings.candidate;
    if (existing != null && existing.code == code && existing.dismissed) {
      final age = today.ordinal - existing.detectedOn.ordinal;
      if (age < Candidate.silenceDays) return OfferOutcome.silenced;
    }
    await _write(
      candidate: Candidate(
        code: code,
        detectedOn: today,
        accuracyM: accuracyM,
        uncertain: uncertain,
        alternatives: alternatives,
      ),
    );
    return OfferOutcome.pending;
  }

  Future<void> dismissCandidate() async {
    final c = _settings.candidate;
    if (c == null) return;
    await _write(candidate: c.copyWith(dismissed: true));
  }

  Future<void> clearCandidate() => _write(clearCandidate: true);

  /// Копия сохранена: напоминание снимается.
  Future<void> markBackup(DateTime now) async {
    final next = _settings.copyWith(lastBackupAt: now, clearBackupNudge: true);
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  /// «Позже»: не напоминать о копии до [until].
  Future<void> snoozeBackupNudge(DateTime until) async {
    final next = _settings.copyWith(backupNudgeUntil: until);
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  /// «Очистить всё»: настройки по умолчанию, как при первом запуске.
  Future<void> reset() async {
    const next = AppSettings();
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  Future<void> _write({
    Candidate? candidate,
    bool clearCandidate = false,
  }) async {
    final next = _settings.copyWith(
      candidate: candidate,
      clearCandidate: clearCandidate,
    );
    await repository.save(next);
    _settings = next;
    notifyListeners();
  }

  static SettingsController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);
}
