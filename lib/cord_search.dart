import 'cord_item.dart';

/// Catalog filters only. A matching connector label cannot certify compatibility.
List<CordItem> searchCords(
  Iterable<CordItem> items, {
  String keyword = '',
  String connector = '',
  String storageSpot = '',
  CordStatus? status,
}) {
  final query = keyword.trim().toLowerCase();
  final end = connector.trim().toLowerCase();
  final spot = storageSpot.trim().toLowerCase();
  return items.where((item) {
    if (status != null && item.status != status) return false;
    if (end.isNotEmpty &&
        item.endA?.trim().toLowerCase() != end &&
        item.endB?.trim().toLowerCase() != end) {
      return false;
    }
    if (spot.isNotEmpty && !item.storageSpot.toLowerCase().contains(spot)) {
      return false;
    }
    if (query.isNotEmpty &&
        ![
          item.name,
          item.storageSpot,
          item.note,
          item.endA ?? '',
          item.endB ?? '',
        ].any((field) => field.toLowerCase().contains(query))) {
      return false;
    }
    return true;
  }).toList();
}

List<String> knownConnectors(Iterable<CordItem> items) {
  final names = <String>{};
  for (final item in items) {
    for (final end in [item.endA, item.endB]) {
      if (end != null && end.trim().isNotEmpty) names.add(end.trim());
    }
  }
  return names.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
