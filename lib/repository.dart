import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'trip.dart';
import 'snapshot.dart';

abstract interface class TripRepository {
  Future<JournalSnapshot> load();
  Future<void> save(JournalSnapshot snapshot);
}

/// The UI can replace this with a fake repository in tests.
/// All disk operations are queued; a failed operation does not poison the queue.
class JsonTripRepository implements TripRepository {
  final Future<Directory> Function() directory;
  final Day Function() today;
  Future<void> _tail = Future<void>.value();
  bool _loaded = false;
  String? _baseline;

  JsonTripRepository({
    Future<Directory> Function()? directory,
    Day Function()? today,
  }) : directory = directory ?? getApplicationSupportDirectory,
       today = today ?? (() => Day.fromDateTime(DateTime.now()));

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<File> _file() async {
    final folder = await directory();
    await folder.create(recursive: true);
    return File('${folder.path}/trips.json');
  }

  @override
  Future<JournalSnapshot> load() => _serialized(() async {
    _loaded = false;
    final file = await _file();
    if (!await file.exists()) {
      _loaded = true;
      _baseline = null;
      return JournalSnapshot();
    }
    final raw = await file.readAsString();
    final snapshot = JournalSnapshot.fromJson(jsonDecode(raw), today());
    _baseline = raw;
    _loaded = true;
    return snapshot;
  });

  @override
  Future<void> save(JournalSnapshot snapshot) {
    return _serialized(() async {
      if (!_loaded) {
        throw StateError('Сначала необходимо успешно прочитать дневник');
      }
      snapshot.validate(today());
      final file = await _file();
      final onDisk = await file.exists() ? await file.readAsString() : null;
      if (onDisk != _baseline) {
        _loaded = false;
        throw StateError('Файл изменился. Необходимо повторное открытие.');
      }
      final temporary = File('${file.path}.tmp');
      final encoded = jsonEncode(snapshot.toJson());
      // Same-directory rename is atomic on Android. Never remove the old file
      // first: if writing fails, the previous journal stays intact.
      await temporary.writeAsString(encoded, flush: true);
      await temporary.rename(file.path);
      _baseline = encoded;
    });
  }
}
