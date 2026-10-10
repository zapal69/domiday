import 'dart:convert';
import 'dart:io';

import 'package:domiday/repository.dart';
import 'package:domiday/snapshot.dart';
import 'package:domiday/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory folder;
  late JsonTripRepository repo;
  final today = Day(2026, 9, 13);
  final sample = Trip(
    id: 'one',
    country: '  ГрУзия  ',
    city: 'Тбилиси',
    note: 'Старый город\n  !',
    arrival: Day(2024, 2, 28),
    departure: Day(2024, 3, 2),
  );
  JournalSnapshot data([List<Trip>? trips]) =>
      JournalSnapshot(trips: trips ?? [sample]);
  JournalSnapshot profiled() => data().copyWith(
    homeCountry: 'Россия',
    current: CurrentStay(
      id: 'current',
      country: 'Турция',
      arrival: Day(2026, 9, 1),
      confirmedOn: today,
    ),
    undated: [
      UndatedStay(id: 'unknown', country: 'Грузия', departure: Day(2026, 8, 1)),
    ],
  );
  JsonTripRepository fresh() =>
      JsonTripRepository(directory: () async => folder, today: () => today);
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('domiday_test_');
    repo = fresh();
  });
  tearDown(() async => folder.delete(recursive: true));

  test(
    'missing file starts truly empty; save requires successful load',
    () async {
      await expectLater(repo.save(data()), throwsStateError);
      final loaded = await repo.load();
      expect(loaded.trips, isEmpty);
      expect(loaded.needsOnboarding, isTrue);
      expect(await File('${folder.path}/trips.json').exists(), isFalse);
    },
  );

  test(
    'JSON roundtrip (schema 3), independent repository and delete persistence',
    () async {
      await repo.load();
      await repo.save(profiled());
      final json = jsonDecode(
        await File('${folder.path}/trips.json').readAsString(),
      );
      expect(json['schemaVersion'], 5);
      expect(json['trips'][0]['countryCode'], isNull);
      expect(json['trips'][0]['arrival'], '2024-02-28');
      final reopened = fresh();
      final loaded = await reopened.load();
      expect(loaded.toJson(), profiled().toJson());
      expect(loaded.trips.single.toJson(), sample.toJson());
      expect(await File('${folder.path}/trips.json.tmp').exists(), isFalse);
      await repo.save(loaded.copyWith(trips: []));
      expect((await reopened.load()).trips, isEmpty);
      expect((await reopened.load()).current!.country, 'Турция');
    },
  );

  test('v1 migration preserves every historical value/order/id and does not write on read', () async {
    final other = Trip(
      id: 'z',
      country: 'Россия',
      city: '  Ёлки ',
      note: '\nне менять\n',
      arrival: Day(2023, 12, 31),
      departure: Day(2024, 1, 2),
    );
    final file = File('${folder.path}/trips.json');
    final old = jsonEncode({
      'schemaVersion': 1,
      'trips': [sample.toJson(), other.toJson()],
    });
    await file.writeAsString(old);
    final migrated = await repo.load();
    expect(migrated.needsOnboarding, isTrue);
    expect(migrated.current, isNull);
    expect(await file.readAsString(), old);
    final upgraded = migrated.copyWith(
      homeCountry: 'Россия',
      current: CurrentStay(
        id: 'now',
        country: 'Россия',
        arrival: null,
        confirmedOn: today,
      ),
    );
    await repo.save(upgraded);
    final restarted = await fresh().load();
    expect(restarted.trips.map((t) => t.toJson()).toList(), [
      sample.toJson(),
      other.toJson(),
    ]);
    expect(restarted.current!.arrival, isNull);
    expect(restarted.homeCountry, 'Россия');
    expect(restarted.needsOnboarding, isFalse);
  });

  test('failed first v2 write leaves exact original v1 file intact', () async {
    final file = File('${folder.path}/trips.json');
    final old = jsonEncode({
      'schemaVersion': 1,
      'trips': [sample.toJson()],
    });
    await file.writeAsString(old);
    await repo.load();
    await Directory('${file.path}.tmp').create();
    await expectLater(
      repo.save(profiled()),
      throwsA(isA<FileSystemException>()),
    );
    expect(await file.readAsString(), old);
    expect((await fresh().load()).needsOnboarding, isTrue);
  });

  test(
    'corruption is not replaced and retry can recover repaired file',
    () async {
      final file = File('${folder.path}/trips.json');
      const broken = '{"schemaVersion":1,"trips":[';
      await file.writeAsString(broken);
      await expectLater(repo.load(), throwsFormatException);
      await expectLater(repo.save(data([])), throwsStateError);
      expect(await file.readAsString(), broken);
      await file.writeAsString(jsonEncode(data().toJson()));
      expect((await repo.load()).trips, hasLength(1));
      await repo.save(data([]));
    },
  );

  test('unsupported schema, wrong types, duplicate ids, impossible/future dates, malformed v2', () async {
    final file = File('${folder.path}/trips.json');
    final invalid = [
      {'schemaVersion': 6, 'trips': []},
      {'schemaVersion': 1.0, 'trips': []},
      {'schemaVersion': 1, 'trips': 'not a list'},
      {'schemaVersion': 2, 'trips': []},
      {
        'schemaVersion': 1,
        'trips': [sample.toJson(), sample.toJson()],
      },
      {
        'schemaVersion': 1,
        'trips': [
          {...sample.toJson(), 'city': 42},
        ],
      },
      {
        'schemaVersion': 1,
        'trips': [
          {...sample.toJson(), 'arrival': '2024-02-30'},
        ],
      },
      {
        'schemaVersion': 1,
        'trips': [
          {...sample.toJson(), 'departure': '2099-01-01'},
        ],
      },
      {...profiled().toJson(), 'homeCountry': null},
      {...profiled().toJson(), 'homeCountry': 8},
      {...profiled().toJson(), 'current': false},
      {
        ...profiled().toJson(),
        'current': {...profiled().current!.toJson(), 'arrival': 42},
      },
      {
        ...profiled().toJson(),
        'current': {
          ...profiled().current!.toJson(),
          'confirmedOn': '2099-01-01',
        },
      },
      {
        ...profiled().toJson(),
        'current': {...profiled().current!.toJson(), 'id': 'one'},
      },
      {
        ...profiled().toJson(),
        'undated': [
          {'id': 'x', 'country': 'Россия'},
        ],
      },
    ];
    for (final value in invalid) {
      final encoded = jsonEncode(value);
      await file.writeAsString(encoded);
      await expectLater(repo.load(), throwsFormatException, reason: encoded);
      await expectLater(repo.save(data([])), throwsStateError);
      expect(await file.readAsString(), encoded);
    }
  });

  test(
    'serialized saves finish in order; failed write preserves old journal',
    () async {
      await repo.load();
      await Future.wait([repo.save(data([])), repo.save(data())]);
      expect((await repo.load()).trips, hasLength(1));
      final file = File('${folder.path}/trips.json');
      final original = await file.readAsString();
      final obstruction = await Directory('${file.path}.tmp').create();
      await expectLater(
        repo.save(data([])),
        throwsA(isA<FileSystemException>()),
      );
      expect(await file.readAsString(), original);
      await obstruction.delete();
      await repo.save(data([]));
      expect((await repo.load()).trips, isEmpty);
    },
  );

  test(
    'external corruption/future version after load is never overwritten',
    () async {
      await repo.load();
      await repo.save(profiled());
      final file = File('${folder.path}/trips.json');
      const future = '{"schemaVersion":99,"trips":[]}';
      await file.writeAsString(future);
      await expectLater(repo.save(data([])), throwsStateError);
      expect(await file.readAsString(), future);
      await expectLater(repo.load(), throwsFormatException);
      await expectLater(repo.save(data([])), throwsStateError);
    },
  );
}
