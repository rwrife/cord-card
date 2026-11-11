/// User-entered inventory only. Connector and rating notes never certify compatibility.
enum CordKind { cable, charger, adapter }

enum CordStatus { stored, moved, retired }

class CordItem {
  CordItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.updatedAt,
    this.endA,
    this.endB,
    this.printedRating,
    this.length,
    this.storageSpot = '',
    this.status = CordStatus.stored,
    this.note = '',
  }) {
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        storageSpot.length > 500 ||
        note.length > 2000 ||
        (endA?.trim().isEmpty ?? false) ||
        (endB?.trim().isEmpty ?? false) ||
        (printedRating?.trim().isEmpty ?? false) ||
        (length != null && (!length!.isFinite || length! <= 0)) ||
        updatedAt.isUtc == false) {
      throw const FormatException('Invalid inventory item');
    }
  }

  final String id;
  final String name;
  final CordKind kind;
  final String? endA; // null means unknown, not a positive match.
  final String? endB;
  final String? printedRating; // User-reported text, never verified.
  final double? length; // User-reported length in meters.
  final String storageSpot;
  final CordStatus status;
  final String note;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'endA': endA,
    'endB': endB,
    'printedRating': printedRating,
    'length': length,
    'storageSpot': storageSpot,
    'status': status.name,
    'note': note,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CordItem.fromJson(Object? input) {
    if (input is! Map<String, dynamic>) {
      throw const FormatException('Expected inventory item');
    }
    const keys = {
      'id',
      'name',
      'kind',
      'endA',
      'endB',
      'printedRating',
      'length',
      'storageSpot',
      'status',
      'note',
      'updatedAt',
    };
    if (input.keys.toSet().difference(keys).isNotEmpty ||
        !input.keys.toSet().containsAll(keys)) {
      throw const FormatException('Unknown or missing inventory field');
    }
    try {
      final timestamp = DateTime.parse(input['updatedAt'] as String);
      if (!(input['updatedAt'] as String).endsWith('Z')) {
        throw const FormatException('Timestamp must be UTC');
      }
      return CordItem(
        id: input['id'] as String,
        name: input['name'] as String,
        kind: CordKind.values.byName(input['kind'] as String),
        endA: input['endA'] as String?,
        endB: input['endB'] as String?,
        printedRating: input['printedRating'] as String?,
        length: (input['length'] as num?)?.toDouble(),
        storageSpot: input['storageSpot'] as String,
        status: CordStatus.values.byName(input['status'] as String),
        note: input['note'] as String,
        updatedAt: timestamp,
      );
    } on Object catch (error) {
      if (error is FormatException) rethrow;
      throw FormatException('Invalid inventory item: $error');
    }
  }
}
