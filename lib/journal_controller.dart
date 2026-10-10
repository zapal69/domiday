import 'package:flutter/foundation.dart';

import 'repository.dart';
import 'snapshot.dart';
import 'trip.dart';

class JournalController extends ChangeNotifier {
  final TripRepository repository;
  final Day Function() today;

  /// Сопоставление текста страны с кодом справочника при загрузке:
  /// записи без кода получают его в памяти, на диск — при следующей записи.
  final String? Function(String text)? match;
  JournalSnapshot snapshot = JournalSnapshot();
  bool loading = true;
  bool loadFailed = false;
  bool saving = false;
  JournalController(this.repository, this.today, {this.match});
  bool _disposed = false;

  void refresh() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    loading = true;
    loadFailed = false;
    refresh();
    try {
      final loaded = await repository.load();
      snapshot = match == null ? loaded : loaded.assignCodes(match!);
    } catch (_) {
      loadFailed = true;
    }
    loading = false;
    refresh();
  }

  Future<void> commit(JournalSnapshot next) async {
    if (loading || loadFailed || saving) {
      throw StateError('Дневник занят или недоступен');
    }
    next.validate(today());
    saving = true;
    try {
      await repository.save(next);
      snapshot = next;
      refresh();
    } finally {
      saving = false;
    }
  }
}
