import 'package:fixnum/fixnum.dart' as fn;
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/widgets/admin_ui.dart';

class TaetigkeitenScreen extends StatefulWidget {
  const TaetigkeitenScreen({super.key});
  @override
  State<TaetigkeitenScreen> createState() => _TaetigkeitenState();
}

class _TaetigkeitenState extends State<TaetigkeitenScreen> {
  final _name = TextEditingController();
  List<Taetigkeit> _activities = [];
  int? _selected;
  bool _billable = false, _bookable = false, _busy = false;
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

  void _apply(Taetigkeit? activity) {
    _selected = activity?.id.toInt();
    _name.text = activity?.bezeichnung ?? '';
    _billable = activity?.abrechenbar ?? false;
    _bookable = activity?.buchbar ?? false;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final reply = await globalGrpcClient.getTaetigkeiten();
      if (!mounted) return;
      final activities = reply.taetigkeiten.toList();
      final found = activities.where((a) => a.id.toInt() == _selected).toList();
      setState(() {
        _activities = activities;
        _apply(found.isNotEmpty ? found.first : (activities.isEmpty ? null : activities.first));
      });
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mutate(String operation) async {
    if (operation != 'delete' && _name.text.trim().isEmpty) {
      setState(() => _status = 'Bitte eine Bezeichnung eingeben.');
      return;
    }
    if (operation != 'create' && _selected == null) return;
    if (operation == 'delete' && !await confirmRemoval(context, 'Tätigkeit')) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _status = '';
    });
    try {
      // Both screen sizes send all flags; the old narrow path silently reset them.
      final item = Taetigkeit(
        id: fn.Int64(_selected ?? 0),
        bezeichnung: _name.text.trim(),
        abrechenbar: _billable,
        buchbar: _bookable,
      );
      final error = operation == 'create'
          ? (await globalGrpcClient.setNewTaetigkeit(item)).errorCode
          : operation == 'change'
          ? (await globalGrpcClient.changeTaetigkeit(item)).errorCode
          : (await globalGrpcClient.deleteTaetigkeit(fn.Int64(_selected!))).errorCode;
      if (!mounted) return;
      if (error.isNotEmpty) {
        setState(() => _status = error);
        return;
      }
      setState(() => _status = 'Tätigkeit wurde gespeichert.');
      await _load();
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AdminPageLayout(
    title: 'Tätigkeiten',
    children: [
      if (_busy) const LinearProgressIndicator(),
      if (_activities.isEmpty && !_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Noch keine Tätigkeiten vorhanden.'),
        ),
      AdminGrid(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selected,
            isExpanded: true,
            decoration: adminDecoration('Bestehende Tätigkeit'),
            items: [
              for (final a in _activities)
                DropdownMenuItem(
                  value: a.id.toInt(),
                  child: Text(a.bezeichnung, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy
                ? null
                : (id) {
                    final found = _activities.where((a) => a.id.toInt() == id);
                    if (found.isNotEmpty) setState(() => _apply(found.first));
                  },
          ),
          TextField(controller: _name, maxLength: 255, decoration: adminDecoration('Bezeichnung')),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Abrechenbar'),
            value: _billable,
            onChanged: _busy ? null : (value) => setState(() => _billable = value ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Buchbar'),
            value: _bookable,
            onChanged: _busy ? null : (value) => setState(() => _bookable = value ?? false),
          ),
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
            onPressed: _busy || _selected == null ? null : () => _mutate('change'),
            child: const Text('Ändern'),
          ),
          OutlinedButton(
            onPressed: _busy || _selected == null ? null : () => _mutate('delete'),
            child: const Text('Löschen'),
          ),
        ],
      ),
      if (_status.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_status)),
    ],
  );
}
