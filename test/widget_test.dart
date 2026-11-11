import 'dart:io';

import 'package:cord_card/cord_item.dart';
import 'package:cord_card/cord_store.dart';
import 'package:cord_card/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore extends CordStore {
  _MemoryStore() : super(File('unused-widget-store.json'));
  List<CordItem> items = [];

  @override
  Future<List<CordItem>> load() => Future.value(List.of(items));

  @override
  Future<void> save(List<CordItem> next) {
    items = List.of(next);
    return Future.value();
  }
}

void main() {
  late _MemoryStore store;

  setUp(() => store = _MemoryStore());

  testWidgets('displays compatibility warning and empty state', (tester) async {
    await tester.pumpWidget(CordCardApp(store: store));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Manual notes only. Connector fit does not prove'),
      findsOneWidget,
    );
    expect(find.text('No items yet'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
  });

  testWidgets('validates required name and positive length', (tester) async {
    await tester.pumpWidget(CordCardApp(store: store));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    // Tap Save with empty name
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name required'), findsOneWidget);

    // Enter negative length
    await tester.enterText(find.byKey(const Key('item-name')), 'USB Cable');
    await tester.enterText(find.byKey(const Key('item-length')), '-2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a positive length'), findsOneWidget);

    // Cancel leaves inventory untouched
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('No items yet'), findsOneWidget);
  });

  testWidgets('adds item with unknown connector/rating and persists', (
    tester,
  ) async {
    await tester.pumpWidget(CordCardApp(store: store));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unknown means not checked'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('item-name')),
      'Mystery black cable',
    );
    await tester.enterText(find.byKey(const Key('storage-spot')), 'Box 3');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Mystery black cable'), findsOneWidget);
    expect(find.text('cable · unknown / unknown · stored'), findsOneWidget);

    final saved = await store.load();
    expect(saved.length, 1);
    expect(saved.first.name, 'Mystery black cable');
    expect(saved.first.endA, isNull);
    expect(saved.first.endB, isNull);
    expect(saved.first.printedRating, isNull);
    expect(saved.first.storageSpot, 'Box 3');
  });

  testWidgets('edits existing item', (tester) async {
    final item = CordItem(
      id: 'item-1',
      name: 'Old Name',
      kind: CordKind.cable,
      updatedAt: DateTime.now().toUtc(),
      storageSpot: 'Bin A',
    );
    await store.save([item]);

    await tester.pumpWidget(CordCardApp(store: store));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();

    expect(find.text('Old Name'), findsOneWidget);

    // Tap item to open detail
    await tester.tap(find.text('Old Name'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Printed rating (unverified): unknown'),
      findsOneWidget,
    );

    // Tap Edit
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('item-name')), 'New Name');
    await tester.enterText(find.byKey(const Key('end-a')), 'USB-C');
    await tester.enterText(find.byKey(const Key('end-b')), 'Lightning');
    await tester.enterText(find.byKey(const Key('printed-rating')), '20W');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('New Name'), findsOneWidget);
    expect(find.text('cable · USB-C / Lightning · stored'), findsOneWidget);

    final saved = await store.load();
    expect(saved.length, 1);
    expect(saved.first.name, 'New Name');
    expect(saved.first.endA, 'USB-C');
    expect(saved.first.endB, 'Lightning');
    expect(saved.first.printedRating, '20W');
  });

  testWidgets('retires item with confirmation', (tester) async {
    final item = CordItem(
      id: 'item-retire',
      name: 'Frayed cable',
      kind: CordKind.cable,
      updatedAt: DateTime.now().toUtc(),
    );
    await store.save([item]);

    await tester.pumpWidget(CordCardApp(store: store));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Frayed cable'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retire'));
    await tester.pumpAndSettle();

    expect(find.text('Retire item?'), findsOneWidget);

    // Cancel first
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    var saved = await store.load();
    expect(saved.first.status, CordStatus.stored);

    // Reopen and confirm retire
    await tester.tap(find.text('Frayed cable'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retire'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Retire'));
    await tester.pumpAndSettle();

    expect(find.text('cable · unknown / unknown · retired'), findsOneWidget);
    saved = await store.load();
    expect(saved.first.status, CordStatus.retired);
  });

  testWidgets('deletes item permanently with confirmation', (tester) async {
    final item = CordItem(
      id: 'item-delete',
      name: 'Trash cord',
      kind: CordKind.cable,
      updatedAt: DateTime.now().toUtc(),
    );
    await store.save([item]);

    await tester.pumpWidget(CordCardApp(store: store));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trash cord'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete item permanently?'), findsOneWidget);

    // Cancel first
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Trash cord'), findsOneWidget);

    // Confirm delete
    await tester.tap(find.text('Trash cord'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();

    expect(find.text('No items yet'), findsOneWidget);
    final saved = await store.load();
    expect(saved, isEmpty);
  });
}
