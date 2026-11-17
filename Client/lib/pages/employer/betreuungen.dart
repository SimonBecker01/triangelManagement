import 'package:fixnum/fixnum.dart' as fn;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:management_triangel/global.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/widgets/admin_ui.dart';

class BetreuungenScreen extends StatefulWidget {
  const BetreuungenScreen({super.key});
  @override
  State<BetreuungenScreen> createState() => _BetreuungenState();
}

class _BetreuungenState extends State<BetreuungenScreen> {
  final _weeklyHours = TextEditingController(text: '0');
  final _hourlyRate = TextEditingController(text: '0');
  List<UserObjekt> _users = [];
  List<Klient> _clients = [];
  List<Betreuung> _care = [];
  int? _userId, _clientId, _careId;
  DateTime _from = DateTime(1700, 1, 1), _until = DateTime(2700, 1, 1);
  bool _busy = false;
  String _status = '';
  final _format = DateFormat('dd.MM.yyyy', 'de_DE');
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _weeklyHours.dispose();
    _hourlyRate.dispose();
    super.dispose();
  }

  // CHANGE: dependent lists are awaited together before labels are built.
  // Missing/deleted referenced users or clients are shown safely, not indexed.
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final users = await globalGrpcClient.getUsers();
      final clients = await globalGrpcClient.getKlienten();
      final care = await globalGrpcClient.getBetreuungen(true);
      if (!mounted) return;
      setState(() {
        _users = users.userList.toList();
        _clients = clients.klientenList.toList();
        _care = care.betreuungen.toList();
        if (!_users.any((u) => u.id.toInt() == _userId))
          _userId = _users.isEmpty ? null : _users.first.id.toInt();
        if (!_clients.any((c) => c.id.toInt() == _clientId))
          _clientId = _clients.isEmpty ? null : _clients.first.id.toInt();
        if (!_care.any((c) => c.id.toInt() == _careId))
          _careId = _care.isEmpty ? null : _care.first.id.toInt();
        if (_careId != null) _applyCare(_care.firstWhere((c) => c.id.toInt() == _careId));
      });
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _userLabel(int id) {
    final matches = _users.where((u) => u.id.toInt() == id);
    return matches.isEmpty
        ? 'Unbekannter Betreuer ($id)'
        : '${matches.first.fname} ${matches.first.lname} (${matches.first.loginName})';
  }

  String _clientLabel(int id) {
    final matches = _clients.where((c) => c.id.toInt() == id);
    return matches.isEmpty
        ? 'Unbekannter Klient ($id)'
        : '${matches.first.fname} ${matches.first.nname}';
  }

  void _applyCare(Betreuung care) {
    _careId = care.id.toInt();
    _userId = _users.any((u) => u.id == care.betreuerId) ? care.betreuerId.toInt() : null;
    _clientId = _clients.any((c) => c.id == care.klientId) ? care.klientId.toInt() : null;
    _from = DateTime(care.gueltigVon.year, care.gueltigVon.month, care.gueltigVon.day);
    _until = DateTime(care.gueltigBis.year, care.gueltigBis.month, care.gueltigBis.day);
    _weeklyHours.text = (care.wochenstunden.toInt() / 60).toString();
    _hourlyRate.text = (care.stundensatz.toInt() / 100).toString();
  }

  void _reset() => setState(() {
    _from = DateTime(1700, 1, 1);
    _until = DateTime(2700, 1, 1);
    _weeklyHours.text = '0';
    _hourlyRate.text = '0';
    _status = '';
  });
  Future<void> _pickDate(bool start) async {
    final selected = start ? _from : _until;
    final first = DateTime(1900), last = DateTime(2200, 12, 31);
    final initial = selected.isBefore(first) || selected.isAfter(last) ? DateTime.now() : selected;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (start) {
        _from = picked;
      } else {
        _until = picked;
      }
    });
  }

  String _displayDate(DateTime value, bool start) =>
      (start && value.year == 1700) || (!start && value.year == 2700)
      ? 'Unbegrenzt'
      : _format.format(value);
  Datum _protoDate(DateTime date) => Datum(year: date.year, month: date.month, day: date.day);

  Future<void> _create() async {
    final hours = double.tryParse(_weeklyHours.text.trim().replaceAll(',', '.'));
    final rate = double.tryParse(_hourlyRate.text.trim().replaceAll(',', '.'));
    if (_userId == null ||
        _clientId == null ||
        hours == null ||
        rate == null ||
        !hours.isFinite ||
        !rate.isFinite ||
        hours < 0 ||
        hours > 168 ||
        rate < 0 ||
        rate > 1000000 ||
        _from.isAfter(_until)) {
      setState(
        () =>
            _status = 'Bitte Betreuer, Klient, Zeitraum und gültige nicht negative Zahlen angeben.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _status = '';
    });
    try {
      // The database stores weekly minutes and the hourly rate in cents.
      final reply = await globalGrpcClient.setNewBetreuung(
        Betreuung(
          klientId: fn.Int64(_clientId!),
          betreuerId: fn.Int64(_userId!),
          gueltigVon: _protoDate(_from),
          gueltigBis: _protoDate(_until),
          wochenstunden: fn.Int64((hours * 60).round()),
          stundensatz: fn.Int64((rate * 100).round()),
        ),
      );
      if (!mounted) return;
      if (reply.errorCode.isNotEmpty) {
        setState(() => _status = reply.errorCode);
        return;
      }
      setState(() => _status = 'Betreuung wurde angelegt.');
      await _load();
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    if (_careId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Betreuung beenden?'),
        content: const Text('Die ausgewählte Betreuung wird beendet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _busy = true;
      _status = '';
    });
    try {
      final reply = await globalGrpcClient.endBetreuung(fn.Int64(_careId!));
      if (!mounted) return;
      if (reply.errorCode.isNotEmpty) {
        setState(() => _status = reply.errorCode);
        return;
      }
      setState(() => _status = 'Betreuung wurde beendet.');
      await _load();
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AdminPageLayout(
    title: 'Betreuungen',
    children: [
      if (_busy) const LinearProgressIndicator(),
      if (_care.isEmpty && !_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Keine aktiven Betreuungen vorhanden.'),
        ),
      DropdownButtonFormField<int>(
        initialValue: _careId,
        isExpanded: true,
        decoration: adminDecoration('Aktive Betreuung'),
        items: [
          for (final c in _care)
            DropdownMenuItem(
              value: c.id.toInt(),
              child: Text(
                '${_userLabel(c.betreuerId.toInt())} betreut ${_clientLabel(c.klientId.toInt())}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: _busy
            ? null
            : (id) {
                final match = _care.where((c) => c.id.toInt() == id);
                if (match.isNotEmpty) setState(() => _applyCare(match.first));
              },
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          onPressed: _busy || _careId == null ? null : _end,
          child: const Text('Betreuung beenden'),
        ),
      ),
      const SizedBox(height: 20),
      Text('Neue Betreuung', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      AdminGrid(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _clientId,
            isExpanded: true,
            decoration: adminDecoration('Klient'),
            items: [
              for (final c in _clients)
                DropdownMenuItem(
                  value: c.id.toInt(),
                  child: Text('${c.fname} ${c.nname}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy ? null : (id) => setState(() => _clientId = id),
          ),
          DropdownButtonFormField<int>(
            initialValue: _userId,
            isExpanded: true,
            decoration: adminDecoration('Betreuer'),
            items: [
              for (final u in _users)
                DropdownMenuItem(
                  value: u.id.toInt(),
                  child: Text(
                    '${u.fname} ${u.lname} (${u.loginName})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _busy ? null : (id) => setState(() => _userId = id),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pickDate(true),
            icon: const Icon(Icons.calendar_today),
            label: Text('Gültig von: ${_displayDate(_from, true)}'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pickDate(false),
            icon: const Icon(Icons.calendar_today),
            label: Text('Gültig bis: ${_displayDate(_until, false)}'),
          ),
          TextField(
            controller: _weeklyHours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: adminDecoration('Wochenstunden'),
          ),
          TextField(
            controller: _hourlyRate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: adminDecoration('Stundensatz in Euro'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      AdminActions(
        children: [
          FilledButton(
            onPressed: _busy || _userId == null || _clientId == null ? null : _create,
            child: const Text('Neu anlegen'),
          ),
          OutlinedButton(onPressed: _busy ? null : _reset, child: const Text('Werte zurücksetzen')),
        ],
      ),
      if (_status.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_status)),
    ],
  );
}
