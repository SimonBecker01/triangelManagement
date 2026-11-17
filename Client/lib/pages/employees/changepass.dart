import 'package:flutter/material.dart';
import 'package:management_triangel/widgets/admin_ui.dart';
import 'package:management_triangel/global.dart';

class ChangePassScreen extends StatefulWidget {
  const ChangePassScreen({super.key});

  @override
  State<ChangePassScreen> createState() => _ChangePassScreenState();
}

class _ChangePassScreenState extends State<ChangePassScreen> {
  final _passOldController = TextEditingController();
  final _passNewOneController = TextEditingController();
  final _passNewTwoController = TextEditingController();
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _passOldController.dispose();
    _passNewOneController.dispose();
    _passNewTwoController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  bool _changingPassword = false;

  Future<void> _changePass() async {
    if (_changingPassword) return;
    if (_passNewOneController.text.isEmpty ||
        _passNewOneController.text != _passNewTwoController.text) {
      _responseController.text = 'Neues Passwort ist leer oder stimmt nicht überein.';
      return;
    }
    setState(() => _changingPassword = true);
    try {
      final reply = await globalGrpcClient.changePassword(
        _passOldController.text,
        _passNewOneController.text,
      );
      if (!mounted) return;
      if (reply.errorCode.isNotEmpty) {
        _responseController.text = reply.errorCode;
      } else {
        _passOldController.clear();
        _passNewOneController.clear();
        _passNewTwoController.clear();
        if (passwordResetRequired) {
          // Forced reset was reached directly from login, not from a menu.
          passwordResetRequired = false;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(currentUserRole == 1 ? '/employermenu' : '/menu', (_) => false);
        } else {
          Navigator.of(context).pop();
        }
        return;
      }
    } catch (error) {
      if (!mounted) return;
      _responseController.text = requestErrorMessage(error);
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
    if (!mounted) return;
    _passOldController.clear();
    _passNewOneController.clear();
    _passNewTwoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !passwordResetRequired,
      child: Scaffold(
        appBar: standardAppBar(actions: passwordResetRequired ? [logoutAction(context)] : []),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (useWideLayout(constraints)) {
              return _buildWideLayout();
            }
            return _buildNarrowLayout();
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Center(
      child: Row(
        children: [
          const Spacer(flex: 1),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _passOldController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Altes Passwort',
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _passNewOneController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Neues Passwort',
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _passNewTwoController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Neues Passwort bestätigen',
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _changingPassword ? null : _changePass,
                    child: const Text('Passwort ändern'),
                  ),
                ),
                const Spacer(flex: 3),
                Expanded(flex: 2, child: TextField(controller: _responseController)),
              ],
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  // Blöde kleine Bildschirme...
  Widget _buildNarrowLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _passOldController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Altes Passwort',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passNewOneController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Neues Passwort',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passNewTwoController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Neues Passwort bestätigen',
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _changingPassword ? null : _changePass,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Passwort ändern'),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _responseController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Status',
                ),
                readOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
