import 'dart:io';

import 'package:domiday/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('domiday-settings');
  });
  tearDown(() => dir.delete(recursive: true));

  test('параллельные записи не мешают друг другу', () async {
    final repo = JsonSettingsRepository(directory: () async => dir);
    // Раньше все записи делили один settings.json.tmp, и вторая падала на
    // переименовании: PathNotFoundException на телефоне владельца.
    await Future.wait([
      for (var i = 0; i < 20; i++)
        repo.save(
          AppSettings(
            themeMode: i.isEven ? ThemeMode.dark : ThemeMode.light,
            backgroundDetect: i == 19,
          ),
        ),
    ]);
    final loaded = await repo.load();
    expect(loaded.backgroundDetect, isTrue);
    expect(loaded.themeMode, ThemeMode.light);
    final leftovers = dir.listSync().where((f) => f.path.endsWith('.tmp'));
    expect(leftovers, isEmpty);
  });

  test('ошибка одной записи не блокирует следующие', () async {
    var calls = 0;
    final repo = JsonSettingsRepository(
      directory: () async {
        calls++;
        if (calls == 1) throw const FileSystemException('нет папки');
        return dir;
      },
    );
    await expectLater(
      repo.save(const AppSettings(autoDetect: false)),
      throwsA(isA<FileSystemException>()),
    );
    await repo.save(const AppSettings(autoDetect: true));
    expect((await repo.load()).autoDetect, isTrue);
  });
}
