import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'cord_item.dart';

/// App-private local JSON store. Operations on one path serialize in this process.
class CordStore {
  CordStore(this.file);

  final File file;
  static final Map<String, Future<void>> _operations = {};
  static const maxBytes = 4 * 1024 * 1024;

  Future<T> _run<T>(Future<T> Function() action) {
    final key = file.absolute.path;
    final previous = _operations[key] ?? Future<void>.value();
    final job = previous.catchError((Object _) {}).then((_) => action());
    final completion = job.then<void>((_) {}, onError: (Object _) {});
    _operations[key] = completion;
    completion.whenComplete(() {
      if (identical(_operations[key], completion)) _operations.remove(key);
    });
    return job;
  }

  Future<List<CordItem>> load() => _run(_load);

  Future<List<CordItem>> _load() async {
    final backup = File('${file.path}.bak');
    final source = await file.exists() ? file : backup;
    if (!await source.exists()) return [];
    final bytes = await source.length();
    if (bytes > maxBytes) throw const FormatException('Inventory too large');
    final data = jsonDecode(await source.readAsString());
    if (data is! Map<String, dynamic> ||
        data.keys.toSet().difference({'version', 'items'}).isNotEmpty ||
        data.length != 2 ||
        data['version'] != 1 ||
        data['items'] is! List) {
      throw const FormatException('Unsupported inventory format');
    }
    final items = (data['items'] as List).map(CordItem.fromJson).toList();
    if (items.length > 10000 ||
        items.map((e) => e.id).toSet().length != items.length) {
      throw const FormatException('Duplicate or excessive inventory items');
    }
    return items;
  }

  Future<void> save(List<CordItem> items) {
    final snapshot = List<CordItem>.of(items);
    return _run(() => _save(snapshot));
  }

  Future<void> _save(List<CordItem> items) async {
    if (items.length > 10000 ||
        items.map((e) => e.id).toSet().length != items.length) {
      throw const FormatException('Duplicate or excessive inventory items');
    }
    final content = utf8.encode(
      jsonEncode({
        'version': 1,
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );
    if (content.length > maxBytes) {
      throw const FormatException('Inventory too large');
    }
    await file.parent.create(recursive: true);
    final temporary = File(
      '${file.path}.${Random.secure().nextInt(0x7fffffff)}.tmp',
    );
    final backup = File('${file.path}.bak');
    try {
      await temporary.writeAsBytes(content, flush: true);
      // Never destroy last valid copy when a prior interrupted write left a backup.
      if (await backup.exists() && await file.exists()) await backup.delete();
      if (await file.exists()) await file.rename(backup.path);
      try {
        await temporary.rename(file.path);
      } catch (_) {
        if (await backup.exists() && !await file.exists()) {
          await backup.rename(file.path);
        }
        rethrow;
      }
      if (await backup.exists()) await backup.delete();
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
