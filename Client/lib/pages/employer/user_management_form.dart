import 'package:fixnum/fixnum.dart' as fn;
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/widgets/admin_ui.dart';

// CHANGE: One form backs both the create and edit screens. Selected roles are
// stored as IDs, never used as indexes into a list whose IDs may have gaps.
class UserManagementForm extends StatefulWidget {
  const UserManagementForm({super.key, required this.create});
  final bool create;
  @override
  State<UserManagementForm> createState() => _UserManagementFormState();
}

class _UserManagementFormState extends State<UserManagementForm> {
  final _login = TextEditingController(), _first = TextEditingController();
  final _last = TextEditingController(), _email = TextEditingController();
  List<IdObjekt> _roles = [];
  List<UserObjekt> _users = [];
  int? _roleId, _userId;
  bool _resetPassword = false, _busy = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _login.dispose();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  void _applyUser(UserObjekt? user) {
    _userId = user?.id.toInt();
    _login.text = user?.loginName ?? '';
    _first.text = user?.fname ?? '';
    _last.text = user?.lname ?? '';
    _email.text = user?.email ?? '';
    _roleId = user != null && _roles.any((r) => r.id.toInt() == user.role)
        ? user.role
        : (_roles.isNotEmpty ? _roles.first.id.toInt() : null);
    _resetPassword = false;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final roles = (await globalGrpcClient.getRoles()).rolesList.toList();
      final users = widget.create
          ? <UserObjekt>[]
          : (await globalGrpcClient.getUsers()).userList.toList();
      if (!mounted) return;
      final matches = users.where((u) => u.id.toInt() == _userId).toList();
      setState(() {
        _roles = roles;
        _users = users;
        if (widget.create) {
          if (!_roles.any((r) => r.id.toInt() == _roleId))
            _roleId = _roles.isEmpty ? null : _roles.first.id.toInt();
        } else {
          _applyUser(matches.isNotEmpty ? matches.first : (users.isEmpty ? null : users.first));
        }
      });
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final login = _login.text.trim(),
        first = _first.text.trim(),
        last = _last.text.trim(),
        email = _email.text.trim();
    if (login.isEmpty || first.isEmpty || last.isEmpty || !email.contains('@') || _roleId == null) {
      setState(() => _status = 'Bitte alle Felder und eine gültige E-Mail-Adresse angeben.');
      return;
    }
    if (!widget.create && _userId == null) return;
    setState(() {
      _busy = true;
      _status = '';
    });
    try {
      final user = UserObjekt(
        id: fn.Int64(_userId ?? 0),
        loginName: login,
        fname: first,
        lname: last,
        email: email,
        role: _roleId!,
      );
      final error = widget.create
          ? (await globalGrpcClient.createUser(user)).errorCode
          : (await globalGrpcClient.changeUser(user, _resetPassword ? 1 : 0)).errorCode;
      if (!mounted) return;
      if (error.isNotEmpty) {
        setState(() => _status = error);
        return;
      }
      setState(() {
        _status = widget.create ? 'Nutzer wurde angelegt.' : 'Nutzer wurde geändert.';
        if (widget.create) {
          _login.clear();
          _first.clear();
          _last.clear();
          _email.clear();
        }
      });
      if (!widget.create) await _load();
    } catch (error) {
      if (mounted) setState(() => _status = requestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AdminPageLayout(
    title: widget.create ? 'Neuen Nutzer anlegen' : 'Nutzerverwaltung',
    children: [
      if (_busy) const LinearProgressIndicator(),
      if (!widget.create && _users.isEmpty && !_busy)
        const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Keine Nutzer vorhanden.')),
      if (_roles.isEmpty && !_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Keine Rollen verfügbar. Bitte zuerst eine Rolle anlegen.'),
        ),
      AdminGrid(
        children: [
          if (!widget.create)
            DropdownButtonFormField<int>(
              initialValue: _userId,
              isExpanded: true,
              decoration: adminDecoration('Nutzer auswählen'),
              items: [
                for (final u in _users)
                  DropdownMenuItem(
                    value: u.id.toInt(),
                    child: Text(u.loginName, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (id) {
                      final match = _users.where((u) => u.id.toInt() == id);
                      if (match.isNotEmpty) setState(() => _applyUser(match.first));
                    },
            ),
          TextField(
            controller: _login,
            maxLength: 255,
            decoration: adminDecoration('Benutzername'),
          ),
          TextField(controller: _first, maxLength: 255, decoration: adminDecoration('Vorname')),
          TextField(controller: _last, maxLength: 255, decoration: adminDecoration('Nachname')),
          TextField(
            controller: _email,
            maxLength: 255,
            keyboardType: TextInputType.emailAddress,
            decoration: adminDecoration('E-Mail'),
          ),
          DropdownButtonFormField<int>(
            initialValue: _roleId,
            isExpanded: true,
            decoration: adminDecoration('Rolle'),
            items: [
              for (final role in _roles)
                DropdownMenuItem(
                  value: role.id.toInt(),
                  child: Text(role.bezeichnung, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy ? null : (id) => setState(() => _roleId = id),
          ),
        ],
      ),
      if (!widget.create)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Passwort zurücksetzen und per E-Mail zusenden'),
          value: _resetPassword,
          onChanged: _busy ? null : (value) => setState(() => _resetPassword = value ?? false),
        ),
      const SizedBox(height: 20),
      AdminActions(
        children: [
          FilledButton(
            onPressed: _busy || _roleId == null || (!widget.create && _userId == null)
                ? null
                : _save,
            child: Text(widget.create ? 'Nutzer anlegen' : 'Änderungen speichern'),
          ),
        ],
      ),
      if (_status.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_status)),
    ],
  );
}
