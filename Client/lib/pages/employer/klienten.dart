import 'package:fixnum/fixnum.dart' as fn;
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/widgets/admin_ui.dart';

class KlientenverwaltungScreen extends StatefulWidget {
  const KlientenverwaltungScreen({super.key});
  @override
  State<KlientenverwaltungScreen> createState() => _KlientenState();
}

class _KlientenState extends State<KlientenverwaltungScreen> {
  final _first = TextEditingController(), _last = TextEditingController();
  List<Klient> _clients = [];
  int? _selected;
  bool _busy = false;
  String _status = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  void _apply(Klient? client) {
    _selected = client?.id.toInt();
    _first.text = client?.fname ?? '';
    _last.text = client?.nname ?? '';
    if (_selected != null) selectedChild = _selected!;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final reply = await globalGrpcClient.getKlienten();
      if (!mounted) return;
      final clients = reply.klientenList.toList();
      final found = clients.where((c) => c.id.toInt() == _selected).toList();
      // Replace the global lists rather than appending duplicate names on reload.
      childList
        ..clear()
        ..addAll(clients.map((c) => '${c.fname} ${c.nname}'));
      childListId
        ..clear()
        ..addAll(clients.map((c) => c.id.toInt()));
      setState(() {
        _clients = clients;
        _apply(found.isNotEmpty ? found.first : (clients.isEmpty ? null : clients.first));
      });
      if (clients.isEmpty) selectedChild = 0;
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mutate(String operation) async {
    if (operation != 'delete' && (_first.text.trim().isEmpty || _last.text.trim().isEmpty)) {
      setState(() => _status = 'Bitte Vor- und Nachnamen eingeben.');
      return;
    }
    if (operation != 'create' && _selected == null) return;
    if (operation == 'delete' && !await confirmRemoval(context, 'Klient')) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _status = '';
    });
    try {
      final client = Klient(
        id: fn.Int64(_selected ?? 0),
        fname: _first.text.trim(),
        nname: _last.text.trim(),
      );
      final error = operation == 'create'
          ? (await globalGrpcClient.setNewKlient(client)).errorCode
          : operation == 'change'
          ? (await globalGrpcClient.changeKlient(client)).errorCode
          : (await globalGrpcClient.deleteKlient(fn.Int64(_selected!))).errorCode;
      if (!mounted) return;
      if (error.isNotEmpty) {
        setState(() => _status = error);
        return;
      }
      setState(() => _status = 'Klient wurde gespeichert.');
      await _load();
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AdminPageLayout(
    title: 'Klientenverwaltung',
    children: [
      if (_busy) const LinearProgressIndicator(),
      if (_clients.isEmpty && !_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Noch keine Klienten vorhanden.'),
        ),
      AdminGrid(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selected,
            isExpanded: true,
            decoration: adminDecoration('Klient auswählen'),
            items: [
              for (final c in _clients)
                DropdownMenuItem(
                  value: c.id.toInt(),
                  child: Text('${c.fname} ${c.nname}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy
                ? null
                : (id) {
                    final match = _clients.where((c) => c.id.toInt() == id);
                    if (match.isNotEmpty) setState(() => _apply(match.first));
                  },
          ),
          TextField(controller: _first, maxLength: 255, decoration: adminDecoration('Vorname')),
          TextField(controller: _last, maxLength: 255, decoration: adminDecoration('Nachname')),
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
          TextButton(onPressed: _busy ? null : _load, child: const Text('Aktualisieren')),
        ],
      ),
      if (_status.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_status)),
    ],
  );
}
