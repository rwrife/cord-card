import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'cord_item.dart';
import 'cord_search.dart';
import 'cord_store.dart';

void main() => runApp(const CordCardApp());

class CordCardApp extends StatefulWidget {
  const CordCardApp({super.key, this.store});

  final CordStore? store;

  @override
  State<CordCardApp> createState() => _CordCardAppState();
}

class _CordCardAppState extends State<CordCardApp> {
  final _navigator = GlobalKey<NavigatorState>();
  CordStore? _store;
  List<CordItem> _items = [];
  String? _error;
  bool _busy = false;
  final _query = TextEditingController();
  String _connector = '';
  String _spot = '';
  CordStatus? _status;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final store =
          widget.store ??
          CordStore(
            File(
              '${(await getApplicationSupportDirectory()).path}/cord-card.json',
            ),
          );
      final items = await store.load();
      if (mounted) {
        setState(() {
          _store = store;
          _items = items;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Cannot load inventory: $error');
    }
  }

  Future<void> _save(List<CordItem> next) async {
    if (_busy || _store == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _store!.save(next);
      if (mounted) setState(() => _items = next);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not save. Inventory unchanged: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([CordItem? item]) async {
    if (_busy) return;
    final result = await showDialog<CordItem>(
      context: _navigator.currentContext!,
      builder: (context) => _ItemEditor(item: item),
    );
    if (result == null || !mounted) return;
    await _save(
      item == null
          ? [..._items, result]
          : [
              for (final current in _items)
                if (current.id == item.id) result else current,
            ],
    );
  }

  Future<void> _setStatus(CordItem item, CordStatus status) async {
    await _save([
      for (final current in _items)
        if (current.id == item.id) _copy(current, status: status) else current,
    ]);
  }

  Future<void> _retire(CordItem item) async {
    final confirmed = await showDialog<bool>(
      context: _navigator.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Retire item?'),
        content: Text('Retire ${item.name}? You can still view its record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retire'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _save([
        for (final current in _items)
          if (current.id == item.id)
            _copy(current, status: CordStatus.retired)
          else
            current,
      ]);
    }
  }

  Future<void> _delete(CordItem item) async {
    final confirmed = await showDialog<bool>(
      context: _navigator.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Delete item permanently?'),
        content: Text('Delete ${item.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _save(_items.where((current) => current.id != item.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectors = knownConnectors(_items);
    final spots = {
      for (final i in _items)
        if (i.storageSpot.trim().isNotEmpty) i.storageSpot.trim(),
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final visible = searchCords(
      _items,
      keyword: _query.text,
      connector: _connector,
      storageSpot: _spot,
      status: _status,
    );

    return MaterialApp(
      title: 'Cord Card',
      navigatorKey: _navigator,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF142537)),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Cord Card')),
        body: SafeArea(
          child: _error != null && _store == null
              ? Center(child: Text(_error!))
              : _store == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Manual notes only. Connector fit does not prove voltage, power, data or USB-PD compatibility. Check device specifications before connecting.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        key: const Key('search-query'),
                        controller: _query,
                        decoration: const InputDecoration(
                          labelText: 'Search keyword',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          DropdownButton<String>(
                            key: const Key('filter-connector'),
                            value: _connector.isEmpty ? null : _connector,
                            hint: const Text('Connector: all'),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Connector: all'),
                              ),
                              for (final c in {
                                ...connectors,
                                if (_connector.isNotEmpty) _connector,
                              })
                                DropdownMenuItem(value: c, child: Text(c)),
                            ],
                            onChanged: (val) =>
                                setState(() => _connector = val ?? ''),
                          ),
                          DropdownButton<String>(
                            key: const Key('filter-spot'),
                            value: _spot.isEmpty ? null : _spot,
                            hint: const Text('Spot: all'),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Spot: all'),
                              ),
                              for (final s in {
                                ...spots,
                                if (_spot.isNotEmpty) _spot,
                              })
                                DropdownMenuItem(value: s, child: Text(s)),
                            ],
                            onChanged: (val) =>
                                setState(() => _spot = val ?? ''),
                          ),
                          DropdownButton<CordStatus?>(
                            key: const Key('filter-status'),
                            value: _status,
                            hint: const Text('Status: all'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Status: all'),
                              ),
                              for (final st in CordStatus.values)
                                DropdownMenuItem(
                                  value: st,
                                  child: Text(st.name),
                                ),
                            ],
                            onChanged: (val) => setState(() => _status = val),
                          ),
                          if (_query.text.isNotEmpty ||
                              _connector.isNotEmpty ||
                              _spot.isNotEmpty ||
                              _status != null)
                            TextButton(
                              key: const Key('reset-filters'),
                              onPressed: () => setState(() {
                                _query.clear();
                                _connector = '';
                                _spot = '';
                                _status = null;
                              }),
                              child: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!, key: const Key('save-error')),
                      ),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(
                              child: Text(
                                _items.isEmpty
                                    ? 'No items yet'
                                    : 'No items match filters',
                              ),
                            )
                          : ListView.builder(
                              itemCount: visible.length,
                              itemBuilder: (context, index) {
                                final item = visible[index];
                                return ListTile(
                                  title: Text(item.name),
                                  subtitle: Text(
                                    '${item.kind.name} · ${item.endA ?? 'unknown'} / ${item.endB ?? 'unknown'} · ${item.storageSpot.isEmpty ? 'unknown spot' : item.storageSpot} · ${item.status.name}',
                                  ),
                                  onTap: () => showDialog<void>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(item.name),
                                      content: SingleChildScrollView(
                                        child: Text(
                                          'Connectors: ${item.endA ?? 'unknown'} / ${item.endB ?? 'unknown'}\n'
                                          'Printed rating (unverified): ${item.printedRating ?? 'unknown'}\n'
                                          'Length (m): ${item.length?.toString() ?? 'unknown'}\n'
                                          'Storage: ${item.storageSpot.isEmpty ? 'unknown' : item.storageSpot}\n'
                                          'Status: ${item.status.name}\nNotes: ${item.note}',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _edit(item);
                                          },
                                          child: const Text('Edit'),
                                        ),
                                        if (item.status != CordStatus.stored)
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _setStatus(
                                                item,
                                                CordStatus.stored,
                                              );
                                            },
                                            child: const Text('Mark stored'),
                                          ),
                                        if (item.status != CordStatus.moved)
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _setStatus(
                                                item,
                                                CordStatus.moved,
                                              );
                                            },
                                            child: const Text('Mark moved'),
                                          ),
                                        if (item.status != CordStatus.retired)
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _retire(item);
                                            },
                                            child: const Text('Retire'),
                                          ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _delete(item);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: _store == null || _busy
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _edit(),
                label: const Text('Add item'),
                icon: const Icon(Icons.add),
              ),
      ),
    );
  }
}

CordItem _copy(CordItem item, {CordStatus? status}) => CordItem(
  id: item.id,
  name: item.name,
  kind: item.kind,
  updatedAt: DateTime.now().toUtc(),
  endA: item.endA,
  endB: item.endB,
  printedRating: item.printedRating,
  length: item.length,
  storageSpot: item.storageSpot,
  note: item.note,
  status: status ?? item.status,
);

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({this.item});
  final CordItem? item;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _endA = TextEditingController(text: widget.item?.endA ?? '');
  late final _endB = TextEditingController(text: widget.item?.endB ?? '');
  late final _rating = TextEditingController(
    text: widget.item?.printedRating ?? '',
  );
  late final _length = TextEditingController(
    text: widget.item?.length?.toString() ?? '',
  );
  late final _spot = TextEditingController(
    text: widget.item?.storageSpot ?? '',
  );
  late final _note = TextEditingController(text: widget.item?.note ?? '');
  late CordKind _kind = widget.item?.kind ?? CordKind.cable;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _endA,
      _endB,
      _rating,
      _length,
      _spot,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final item = CordItem(
      id:
          widget.item?.id ??
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff)}',
      updatedAt: DateTime.now().toUtc(),
      name: _name.text.trim(),
      kind: _kind,
      endA: _optional(_endA.text),
      endB: _optional(_endB.text),
      printedRating: _optional(_rating.text),
      length: _optional(_length.text) == null
          ? null
          : double.parse(_length.text.trim()),
      storageSpot: _spot.text.trim(),
      note: _note.text.trim(),
      status: widget.item?.status ?? CordStatus.stored,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Add item' : 'Edit item'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('item-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              DropdownButtonFormField<CordKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Kind'),
                items: [
                  for (final kind in CordKind.values)
                    DropdownMenuItem(value: kind, child: Text(kind.name)),
                ],
                onChanged: (kind) {
                  if (kind != null) setState(() => _kind = kind);
                },
              ),
              TextFormField(
                key: const Key('end-a'),
                controller: _endA,
                decoration: const InputDecoration(
                  labelText: 'Connector end A (blank = unknown)',
                ),
              ),
              TextFormField(
                key: const Key('end-b'),
                controller: _endB,
                decoration: const InputDecoration(
                  labelText: 'Connector end B (blank = unknown)',
                ),
              ),
              TextFormField(
                key: const Key('printed-rating'),
                controller: _rating,
                decoration: const InputDecoration(
                  labelText: 'Printed rating (unverified; blank = unknown)',
                ),
              ),
              TextFormField(
                key: const Key('item-length'),
                controller: _length,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Length in meters (blank = unknown)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim());
                  return n == null || !n.isFinite || n <= 0
                      ? 'Enter a positive length'
                      : null;
                },
              ),
              TextFormField(
                key: const Key('storage-spot'),
                controller: _spot,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Storage spot (blank = unknown)',
                ),
              ),
              TextFormField(
                key: const Key('item-note'),
                controller: _note,
                maxLength: 2000,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Unknown means not checked. Printed ratings are user-reported; connector fit does not prove voltage, power, data or USB-PD compatibility.',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _submit, child: const Text('Save')),
    ],
  );
}
