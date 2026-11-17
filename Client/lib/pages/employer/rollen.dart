import 'package:fixnum/fixnum.dart' as fn;
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/widgets/admin_ui.dart';

class RollenScreen extends StatefulWidget {
  const RollenScreen({super.key});
  @override
  State<RollenScreen> createState() => _RollenState();
}

class _RollenState extends State<RollenScreen> {
  final _name = TextEditingController();
  List<IdObjekt> _roles = [], _groups = [], _categories = [];
  List<IdPair> _groupRights = [], _categoryRights = [];
  final Set<int> _selectedGroups = {}, _selectedCategories = {};
  int? _roleId;
  bool _busy = false;
  String _status = '';
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

  // Keep permissions local to this screen and initialize them on the first
  // selection as well as subsequent selections; global document filters are
  // unrelated and must not be overwritten here.
  void _select(int? id) {
    final match = _roles.where((r) => r.id.toInt() == id).toList();
    _roleId = match.isEmpty ? null : id;
    _name.text = match.isEmpty ? '' : match.first.bezeichnung;
    _selectedGroups
      ..clear()
      ..addAll(_groupRights.where((p) => p.idFirst.toInt() == id).map((p) => p.idSecond.toInt()));
    _selectedCategories
      ..clear()
      ..addAll(
        _categoryRights.where((p) => p.idFirst.toInt() == id).map((p) => p.idSecond.toInt()),
      );
  }

  Future<void> _load({int? select}) async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final config = await globalGrpcClient.getDocumentConfig();
      final roles = await globalGrpcClient.getRoles();
      final groupRights = await globalGrpcClient.getRechteGruppe();
      final categoryRights = await globalGrpcClient.getRechteKategorien();
      if (!mounted) return;
      setState(() {
        _groups = config.gruppen.toList();
        _categories = config.kategorien.toList();
        _roles = roles.rolesList.toList();
        _groupRights = groupRights.rechteGruppe.toList();
        _categoryRights = categoryRights.rechteKategorien.toList();
        final wanted = select ?? _roleId;
        _select(
          _roles.any((r) => r.id.toInt() == wanted)
              ? wanted
              : (_roles.isEmpty ? null : _roles.first.id.toInt()),
        );
      });
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mutate(String operation) async {
    final name = _name.text.trim();
    if (operation != 'delete' && name.isEmpty) {
      setState(() => _status = 'Bitte einen Rollennamen eingeben.');
      return;
    }
    if (operation != 'create' && _roleId == null) return;
    if (operation == 'delete' && !await confirmRemoval(context, 'Rolle')) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _status = '';
    });
    bool roleSaved = false;
    try {
      var id = _roleId;
      final item = IdObjekt(id: fn.Int64(id ?? 0), bezeichnung: name);
      String error;
      if (operation == 'delete') {
        error = (await globalGrpcClient.deleteRolle(item)).errorCode;
      } else if (operation == 'create') {
        error = (await globalGrpcClient.setNewRolle(item)).errorCode;
        if (error.isEmpty) {
          roleSaved = true;
          final roles = await globalGrpcClient.getRoles();
          final matching = roles.rolesList.where((r) => r.bezeichnung == name).toList();
          if (matching.length != 1) throw StateError('New role could not be identified');
          id = matching.first.id.toInt();
        }
      } else {
        error = (await globalGrpcClient.changeRolle(item)).errorCode;
        roleSaved = error.isEmpty;
      }
      if (!mounted) return;
      if (error.isNotEmpty) {
        setState(() => _status = error);
        return;
      }
      if (operation != 'delete') {
        // Role metadata and permissions are separate RPCs. If the second fails,
        // explicitly report the partial result rather than claiming full success.
        final rights = await globalGrpcClient.setRechte(
          fn.Int64(id!),
          _selectedGroups.map(fn.Int64.new).toList(),
          _selectedCategories.map(fn.Int64.new).toList(),
        );
        if (!mounted) return;
        if (rights.errorCode.isNotEmpty) {
          setState(
            () => _status = 'Rolle gespeichert, Rechte nicht gespeichert: ${rights.errorCode}',
          );
          return;
        }
      }
      setState(() => _status = 'Rolle und Rechte wurden gespeichert.');
      await _load(select: operation == 'delete' ? null : id);
    } catch (error) {
      if (mounted)
        setState(
          () => _status = roleSaved
              ? 'Rolle gespeichert, Rechte nicht gespeichert. Bitte erneut versuchen.'
              : requestErrorMessage(error),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _rightsCard(String title, List<IdObjekt> options, Set<int> selected) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Keine Einträge vorhanden.'),
            ),
          for (final option in options)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(option.bezeichnung),
              value: selected.contains(option.id.toInt()),
              onChanged: _busy
                  ? null
                  : (checked) => setState(() {
                      if (checked == true) {
                        selected.add(option.id.toInt());
                      } else {
                        selected.remove(option.id.toInt());
                      }
                    }),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AdminPageLayout(
    title: 'Rollen und Rechte',
    children: [
      if (_busy) const LinearProgressIndicator(),
      if (_roles.isEmpty && !_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Noch keine Rollen vorhanden.'),
        ),
      AdminGrid(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _roleId,
            isExpanded: true,
            decoration: adminDecoration('Rolle auswählen'),
            items: [
              for (final r in _roles)
                DropdownMenuItem(
                  value: r.id.toInt(),
                  child: Text(r.bezeichnung, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy ? null : (id) => setState(() => _select(id)),
          ),
          TextField(controller: _name, maxLength: 255, decoration: adminDecoration('Rollenname')),
        ],
      ),
      const SizedBox(height: 20),
      AdminGrid(
        children: [
          _rightsCard('Dokumentgruppen', _groups, _selectedGroups),
          _rightsCard('Kategorien', _categories, _selectedCategories),
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
            onPressed: _busy || _roleId == null ? null : () => _mutate('change'),
            child: const Text('Änderungen speichern'),
          ),
          OutlinedButton(
            onPressed: _busy || _roleId == null ? null : () => _mutate('delete'),
            child: const Text('Löschen'),
          ),
        ],
      ),
      if (_status.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_status)),
    ],
  );
}
