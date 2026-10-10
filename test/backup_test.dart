import 'package:domiday/backup.dart';
import 'package:domiday/settings.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show dashboardFixture;
import 'widget_test.dart'
    show launch, reveal;

void main() {
  final today = Day(2026, 9, 13);
  final now = DateTime(2026, 9, 13, 12, 5);

  test(
    'backup: round trip keeps the journal, file name has the date',
    () async {
      final snapshot = await dashboardFixture().load();
      final text = encodeBackup(snapshot, now: now, appVersion: '0.9.0');
      expect(backupFileName(now), 'domiday-backup-2026-09-13.json');
      final info = decodeBackup(text, today);
      expect(info.snapshot.trips.length, snapshot.trips.length);
      expect(info.snapshot.toJson(), snapshot.toJson());
      expect(info.appVersion, '0.9.0');
      expect(info.createdAt, now.toUtc());
    },
  );

  test('backup: foreign, newer and damaged files are rejected', () {
    BackupErrorCode codeOf(String text) {
      try {
        decodeBackup(text, today);
      } on BackupError catch (e) {
        return e.code;
      }
      fail('accepted: $text');
    }

    expect(codeOf('not json'), BackupErrorCode.notBackup);
    expect(
      codeOf('{"schemaVersion": 4, "trips": []}'),
      BackupErrorCode.notBackup,
    );
    expect(
      codeOf('{"format": "domiday-backup", "backupVersion": 2, "journal": {}}'),
      BackupErrorCode.newer,
    );
    expect(
      codeOf(
        '{"format": "domiday-backup", "backupVersion": 1, '
        '"journal": {"schemaVersion": 6, "trips": []}}',
      ),
      BackupErrorCode.newer,
    );
    expect(
      codeOf(
        '{"format": "domiday-backup", "backupVersion": 1, '
        '"journal": {"schemaVersion": 4, "trips": [{"id": 1}]}}',
      ),
      BackupErrorCode.corrupt,
    );
  });

  testWidgets('settings: save writes a backup file, cancel is silent', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final store = FakeBackupStore();
    await launch(tester, repo, journal: false, backup: store);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backupSave')));
    await tester.tap(find.byKey(const Key('backupSave')));
    await tester.pumpAndSettle();
    expect(store.savedName, startsWith('domiday-backup-'));
    final info = decodeBackup(store.saved!, today);
    expect(info.snapshot.trips.length, (await repo.load()).trips.length);
    expect(find.textContaining('Копия сохранена'), findsOneWidget);
    expect(repo.writes, 0);
  });

  testWidgets('settings: restore replaces the history after confirmation', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final original = await repo.load();
    final smaller = JournalSnapshot(
      trips: original.trips.take(1),
      homeCountry: original.homeCountry,
      homeCountryCode: original.homeCountryCode,
      current: original.current,
    );
    final store = FakeBackupStore()
      ..toOpen = BackupPick(
        'old.json',
        encodeBackup(smaller, now: now, appVersion: '0.9.0'),
      );
    final settings = MemorySettingsRepository();
    await launch(tester, repo, journal: false, backup: store, settings: settings);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backupRestore')));
    await tester.tap(find.byKey(const Key('backupRestore')));
    await tester.pumpAndSettle();
    expect(find.text('Восстановить из копии?'), findsOneWidget);
    expect(find.textContaining('old.json: 1 поездка'), findsOneWidget);
    // Отмена — ничего не записано.
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    await tester.tap(find.byKey(const Key('backupRestore')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Заменить историю'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect((await repo.load()).trips.length, 1);
    expect(find.textContaining('История восстановлена'), findsOneWidget);
    // Восстановились из копии — дата последней копии равна дате файла,
    // напоминание «копии ещё не было» не появляется.
    expect(settings.settings.lastBackupAt!.toUtc(), now.toUtc());
    expect(find.byKey(const Key('backupNudge')), findsNothing);
    // Вернулись на главный экран.
    expect(find.byKey(const Key('backupRestore')), findsNothing);
  });

  testWidgets('settings: a foreign file is refused without writing', (
    tester,
  ) async {
    final repo = dashboardFixture();
    final store = FakeBackupStore()
      ..toOpen = const BackupPick('notes.json', '{"hello": 1}');
    await launch(tester, repo, journal: false, backup: store);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('backupRestore')));
    await tester.tap(find.byKey(const Key('backupRestore')));
    await tester.pumpAndSettle();
    expect(find.text('Это не файл резервной копии Domiday.'), findsOneWidget);
    expect(repo.writes, 0);
  });
}
