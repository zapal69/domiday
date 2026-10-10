import 'dart:convert';
import 'dart:typed_data';

import 'package:domiday/backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('picked file is read, then the temporary copies are cleared', () async {
    var cleared = 0;
    final store = FilePickerStore(
      pick: () async => [PickedFile('timeline.json', () async => Uint8List.fromList(utf8.encode('{"a":1}')))],
      clear: () async => cleared++,
    );
    final pick = await store.open();
    expect(pick!.name, 'timeline.json');
    expect(pick.contents, '{"a":1}');
    expect(cleared, 1);
  });

  test('cancel and failure also clear the temporary copies', () async {
    var cleared = 0;
    final cancelled = FilePickerStore(pick: () async => [], clear: () async => cleared++);
    expect(await cancelled.open(), isNull);
    expect(cleared, 1);
    final failing = FilePickerStore(
      pick: () async => throw StateError('picker failed'),
      clear: () async => cleared++,
    );
    await expectLater(failing.open(), throwsStateError);
    expect(cleared, 2);
    // Ошибка очистки не мешает вернуть файл.
    final noClear = FilePickerStore(
      pick: () async => [PickedFile('b.json', () async => Uint8List.fromList(utf8.encode('x')))],
      clear: () async => throw UnimplementedError(),
    );
    expect((await noClear.open())!.contents, 'x');
  });

  test('Timeline import picks JSON only; restore keeps any file', () async {
    final calls = <String>[];
    Future<List<PickedFile>> file(String kind) async {
      calls.add(kind);
      return [PickedFile('$kind.json', () async => Uint8List.fromList(utf8.encode(kind)))];
    }

    final store = FilePickerStore(
      pick: () => file('any'),
      pickJson: () => file('json'),
      clear: () async {},
    );
    expect((await store.open(jsonOnly: true))!.contents, 'json');
    expect((await store.open())!.contents, 'any');
    expect(calls, ['json', 'any']);
  });
}
