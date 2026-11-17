import 'package:fixnum/fixnum.dart' as fn;
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/widgets/admin_ui.dart';

enum LookupKind { group, category }

// CHANGE: Both lists now share the same error handling, empty-state handling,
// and responsive form. A new item can be created even if the list is empty.
class LookupManagementScreen extends StatefulWidget {
  const LookupManagementScreen({super.key, required this.kind});
  final LookupKind kind;
  @override
  State<LookupManagementScreen> createState() => _LookupManagementState();
}

class _LookupManagementState extends State<LookupManagementScreen> {
  final _name = TextEditingController();
  List<IdObjekt> _items = [];
  int? _selectedId;
  bool _busy = false;
  String _status = '';
  bool get _group => widget.kind == LookupKind.group;
  String get _label => _group ? 'Gruppe' : 'Kategorie';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load({int? select}) async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final result = await globalGrpcClient.getDocumentConfig();
      if (!mounted) return;
      final items = (_group ? result.gruppen : result.kategorien).toList();
      final wanted = select ?? _selectedId;
      final match = items.where((e) => e.id.toInt() == wanted).toList();
      final selected = match.isNotEmpty ? match.first : (items.isNotEmpty ? items.first : null);
      setState(() {
        _items = items;
        _selectedId = selected?.id.toInt();
        _name.text = selected?.bezeichnung ?? '';
      });
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _select(int? id) {
    final matches = _items.where((e) => e.id.toInt() == id);
    if (matches.isEmpty) return;
    setState(() {
      _selectedId = id;
      _name.text = matches.first.bezeichnung;
    });
  }

  Future<void> _mutate(String operation) async {
    final name = _name.text.trim();
    if (operation != 'delete' && name.isEmpty) {
      setState(() => _status = 'Bitte eine Bezeichnung eingeben.');
      return;
    }
    if (operation != 'create' && _selectedId == null) return;
    if (operation == 'delete' && !await confirmRemoval(context, _label)) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _status = '';
    });
    try {
      final item = IdObjekt(id: fn.Int64(_selectedId ?? 0), bezeichnung: name);
      String error;
      if (_group) {
        error = operation == 'create'
            ? (await globalGrpcClient.setNewGruppe(item)).errorCode
            : operation == 'change'
            ? (await globalGrpcClient.changeGruppe(item)).errorCode
            : (await globalGrpcClient.deleteGruppe(item)).errorCode;
      } else {
        error = operation == 'create'
            ? (await globalGrpcClient.setNewKategorie(item)).errorCode
            : operation == 'change'
            ? (await globalGrpcClient.changeKategorie(item)).errorCode
            : (await globalGrpcClient.deleteKategorie(item)).errorCode;
      }
      if (!mounted) return;
      if (error.isNotEmpty) {
        setState(() => _status = error);
        return;
      }
      setState(() => _status = '$_label wurde gespeichert.');
      await _load(select: operation == 'delete' ? null : _selectedId);
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AdminPageLayout(
    title: _group ? 'Dokumentgruppen' : 'Dokumentkategorien',
    children: [
      if (_busy) const LinearProgressIndicator(),
      if (_items.isEmpty && !_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Noch keine Einträge vorhanden.'),
        ),
      AdminGrid(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedId,
            isExpanded: true,
            decoration: adminDecoration('Bestehende $_label'),
            items: [
              for (final item in _items)
                DropdownMenuItem(
                  value: item.id.toInt(),
                  child: Text(item.bezeichnung, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy || _items.isEmpty ? null : _select,
          ),
          TextField(controller: _name, maxLength: 255, decoration: adminDecoration('Bezeichnung')),
        ],
      ),
      const SizedBox(height: 20),
      AdminActions(
        children: [
          FilledButton(
            onPressed: _busy ? null : () => _mutate('create'),
            child: const Text('Neu anlegen'),
          ),
          OutlinedButton(
            onPressed: _busy || _selectedId == null ? null : () => _mutate('change'),
            child: const Text('Ändern'),
          ),
          OutlinedButton(
            onPressed: _busy || _selectedId == null ? null : () => _mutate('delete'),
            child: const Text('Löschen'),
          ),
          TextButton(onPressed: _busy ? null : _load, child: const Text('Aktualisieren')),
        ],
      ),
      if (_status.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_status)),
    ],
  );
}
