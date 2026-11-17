import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/global.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _passController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  bool _loggingIn = false;

  static Color _serverColor(Color fallback, int r, int g, int b) {
    if (r <= 0 && g <= 0 && b <= 0) return fallback;
    return Color.fromRGBO(r, g, b, 1);
  }

  void _applyServerColors(Color light, Color dark) {
    appTheme.setColors(
      light: _serverColor(
        appTheme.lightBG,
        light.r.toInt(),
        light.g.toInt(),
        light.b.toInt(),
      ),
      dark: _serverColor(
        appTheme.darkBG,
        dark.r.toInt(),
        dark.g.toInt(),
        dark.b.toInt(),
      ),
    );
  }

  Future<void> _login() async {
    if (_loggingIn) return;
    if (_nameController.text.trim().isEmpty || _passController.text.isEmpty) {
      _responseController.text = 'Bitte Benutzername und Passwort eingeben.';
      return;
    }
    setState(() => _loggingIn = true);
    _responseController.clear();
    try {
      final loginResult = await globalGrpcClient.login(_nameController.text, _passController.text);

      if (!mounted) return;
      if (loginResult.errorCode.isEmpty) {
        if (loginResult.accessToken.isEmpty) {
          throw StateError('Die Anmeldung enthielt kein Zugriffstoken.');
        }
        loginName = _nameController.text;
        currentUserRole = loginResult.role;
        passwordResetRequired = loginResult.forceResetPass == 1;

        globalGrpcClient.setAuthToken(loginResult.accessToken);
        
        
        _applyServerColors(Color.fromRGBO(loginResult.lightbg.r, loginResult.lightbg.g, loginResult.lightbg.b, 1,),Color.fromRGBO(loginResult.darkbg.r, loginResult.darkbg.g, loginResult.darkbg.b, 1,),);

        childList.clear();
        childListId.clear();

        for (int i = 0; i < loginResult.klienten.length; i++) {
          childList.add(
            '${loginResult.klienten.elementAt(i).fname} ${loginResult.klienten.elementAt(i).nname}',
          );
          childListId.add(loginResult.klienten.elementAt(i).id.toInt());
        }

        selectedChild = childListId.isNotEmpty ? childListId.first : 0;

        final docConfigResult = await globalGrpcClient.getDocumentConfig();
        if (!mounted) return;

        documentGroupList.clear();
        documentGroupListId.clear();

        for (int i = 0; i < docConfigResult.gruppen.length; i++) {
          documentGroupList.add(docConfigResult.gruppen.elementAt(i).bezeichnung);
          documentGroupListId.add(docConfigResult.gruppen.elementAt(i).id.toInt());
        }

        documentCategoryList.clear();
        documentCategoryListId.clear();

        for (int i = 0; i < docConfigResult.kategorien.length; i++) {
          documentCategoryList.add(docConfigResult.kategorien.elementAt(i).bezeichnung);
          documentCategoryListId.add(docConfigResult.kategorien.elementAt(i).id.toInt());
        }

        final taetigkeitenResult = await globalGrpcClient.getTaetigkeiten();
        if (!mounted) return;

        activityList.clear();
        activityListId.clear();

        for (int i = 0; i < taetigkeitenResult.taetigkeiten.length; i++) {
          activityList.add(taetigkeitenResult.taetigkeiten.elementAt(i).bezeichnung);
          activityListId.add(taetigkeitenResult.taetigkeiten.elementAt(i).id.toInt());
        }

        selectedActivity = activityListId.isNotEmpty ? activityListId.first : 0;

        if (mounted) {
          // A required password change takes priority for every role.
          _passController.clear();
          if (passwordResetRequired) {
            Navigator.of(context).pushNamed('/changepass');
          } else {
            Navigator.of(context).pushNamed(loginResult.role == 1 ? '/employermenu' : '/menu');
          }
        }
      } else {
        clearSession();
        _responseController.text = loginResult.errorCode;
      }
    } catch (error) {
      // Never leave a partially initialized authenticated session behind.
      clearSession();
      if (!mounted) return;
      if (error is GrpcError && error.code == StatusCode.unauthenticated) {
        _responseController.text = 'Benutzername oder Passwort ist falsch.';
      } else if (error is GrpcError && error.code == StatusCode.permissionDenied) {
        _responseController.text = 'Zugriff verweigert.';
      } else {
        _responseController.text =
            'Anmeldung fehlgeschlagen. Bitte Verbindung prüfen und erneut versuchen.';
      }
      _passController.clear();
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standardAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (useWideLayout(constraints)) {
            return _buildWideLayout();
          }
          return _buildNarrowLayout();
        },
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Benutzername',
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Passwort',
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _loggingIn ? null : _login,
                    child: const Text('Login'),
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
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Benutzername',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Passwort',
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loggingIn ? null : _login,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Login'),
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
