import 'package:cord_card/cord_item.dart';
import 'package:cord_card/cord_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CordItem item(
    String id, {
    String? a,
    String? b,
    String spot = '',
    String note = '',
    CordStatus status = CordStatus.stored,
  }) => CordItem(
    id: id,
    name: id,
    kind: CordKind.cable,
    updatedAt: DateTime.utc(2026),
    endA: a,
    endB: b,
    storageSpot: spot,
    note: note,
    status: status,
  );
  final items = [
    item('Desk cable', a: 'USB-C', b: 'HDMI', spot: 'Desk drawer'),
    item(
      'Travel adapter',
      a: 'USB-C',
      spot: 'Travel bag',
      status: CordStatus.moved,
    ),
    item(
      'Retired lead',
      b: 'HDMI',
      spot: 'Desk drawer',
      status: CordStatus.retired,
    ),
    item('Mystery USB-C', spot: 'Desk drawer', note: 'USB-C unverified'),
  ];

  test(
    'connector matches known ends only; unknown is never a positive match',
    () {
      expect(searchCords(items, connector: 'usb-c').map((e) => e.id), [
        'Desk cable',
        'Travel adapter',
      ]);
      expect(searchCords(items, connector: 'HDMI').map((e) => e.id), [
        'Desk cable',
        'Retired lead',
      ]);
    },
  );

  test(
    'keyword, connector, location and status intersect, case-insensitively',
    () {
      expect(
        searchCords(
          items,
          keyword: 'travel',
          connector: 'USB-C',
          storageSpot: 'BAG',
          status: CordStatus.moved,
        ).map((e) => e.id),
        ['Travel adapter'],
      );
      expect(
        searchCords(
          items,
          keyword: 'unverified',
          connector: 'USB-C',
          storageSpot: 'drawer',
          status: CordStatus.stored,
        ).map((e) => e.id),
        isEmpty,
      );
      expect(
        searchCords(
          items,
          keyword: 'lead',
          status: CordStatus.retired,
        ).map((e) => e.id),
        ['Retired lead'],
      );
      expect(searchCords(items, storageSpot: 'DESK').map((e) => e.id), [
        'Desk cable',
        'Retired lead',
        'Mystery USB-C',
      ]);
      expect(searchCords(items, keyword: 'unverified').map((e) => e.id), [
        'Mystery USB-C',
      ]);
    },
  );

  test('connector choices derive only from entered known ends', () {
    expect(knownConnectors(items), ['HDMI', 'USB-C']);
  });
}
