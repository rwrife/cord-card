import 'dart:convert';
import 'dart:io';

import 'package:cord_card/cord_item.dart';
import 'package:cord_card/cord_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final item = CordItem(
    id: 'one',
    name: 'Desk cable',
    kind: CordKind.cable,
    updatedAt: DateTime.utc(2026, 1, 1),
    printedRating: '5A printed, unverified',
    storageSpot: 'drawer',
  );

  test(
    'round trip and restart preserve unknown ends and manual notes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'cord-card-test-',
      );
      try {
        final file = File('${directory.path}/inventory.json');
        await CordStore(file).save([item]);
        final loaded = await CordStore(file).load();
        expect(loaded.single.endA, isNull);
        expect(loaded.single.endB, isNull);
        expect(loaded.single.printedRating, item.printedRating);
        expect(loaded.single.toJson(), item.toJson());
        final second = CordItem(
          id: 'two',
          name: 'Adapter',
          kind: CordKind.adapter,
          endA: 'USB-C',
          status: CordStatus.moved,
          updatedAt: DateTime.utc(2026, 2, 1),
        );
        await CordStore(file).save([item, second]);
        expect((await CordStore(file).load()).last.status, CordStatus.moved);
        expect(await File('${file.path}.bak').exists(), false);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'bad records, unknown fields, duplicates and versions fail closed',
    () async {
      expect(
        () => CordItem(
          id: '',
          name: 'x',
          kind: CordKind.charger,
          updatedAt: DateTime.utc(2026),
        ),
        throwsFormatException,
      );
      expect(
        () => CordItem(
          id: 'a',
          name: 'x',
          kind: CordKind.charger,
          length: -1,
          updatedAt: DateTime.utc(2026),
        ),
        throwsFormatException,
      );
      expect(
        () => CordItem.fromJson({...item.toJson(), 'unexpected': 'data'}),
        throwsFormatException,
      );
      expect(
        () => CordItem.fromJson({...item.toJson(), 'endA': 42}),
        throwsFormatException,
      );
      final directory = await Directory.systemTemp.createTemp(
        'cord-card-test-',
      );
      try {
        final file = File('${directory.path}/inventory.json');
        final store = CordStore(file);
        await expectLater(store.save([item, item]), throwsFormatException);
        expect(await file.exists(), false);
        await file.writeAsString(jsonEncode({'version': 999, 'items': []}));
        await expectLater(store.load(), throwsFormatException);
        await file.writeAsString(
          jsonEncode({
            'version': 1,
            'items': [
              {...item.toJson(), 'mystery': 'no'},
            ],
          }),
        );
        await expectLater(store.load(), throwsFormatException);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('save failure preserves existing content; backup survives interrupted rename', () async {
    final directory = await Directory.systemTemp.createTemp('cord-card-test-');
    try {
      final file = File('${directory.path}/inventory.json');
      final store = CordStore(file);
      await store.save([item]);
      final previous = await file.readAsBytes();
      await expectLater(
        store.save(List.filled(10001, item)),
        throwsFormatException,
      );
      expect(await file.readAsBytes(), previous);
      final blockedBackup = await Directory('${file.path}.bak').create();
      await expectLater(store.save([]), throwsA(isA<FileSystemException>()));
      expect(await file.readAsBytes(), previous);
      await blockedBackup.delete();
      await file.rename('${file.path}.bak');
      expect((await CordStore(file).load()).single.name, 'Desk cable');
      await CordStore(file).save([item]);
      expect((await CordStore(file).load()).single.id, 'one');
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test(
    'queued save snapshots input; concurrent reads never disappear',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'cord-card-test-',
      );
      try {
        final file = File('${directory.path}/inventory.json');
        final store = CordStore(file);
        await store.save([item]);
        final mutable = [item];
        final pending = store.save(mutable);
        mutable.clear();
        await pending;
        expect((await store.load()).single.id, item.id);
        await Future.wait([
          () async {
            for (var i = 0; i < 50; i++) {
              await CordStore(file).save([item]);
            }
          }(),
          () async {
            for (var i = 0; i < 100; i++) {
              expect((await CordStore(file).load()).single.id, item.id);
            }
          }(),
        ]);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('two store instances serialize concurrent writes', () async {
    final directory = await Directory.systemTemp.createTemp('cord-card-test-');
    try {
      final file = File('${directory.path}/inventory.json');
      await Future.wait([
        CordStore(file).save([item]),
        CordStore(file).save([]),
      ]);
      expect(await CordStore(file).load(), isEmpty);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
