
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

  Future<void> _login() async {
    try {
      final loginResult =
          await globalGrpcClient.login(_nameController.text, _passController.text);

      if (loginResult.errorCode.isEmpty) {
        loginName = _nameController.text;

        globalGrpcClient.setAuthToken(loginResult.accessToken);

        darkBG = Color.fromRGBO(loginResult.darkbg.r, loginResult.darkbg.g, loginResult.darkbg.b, 1);
        lightBG = Color.fromRGBO(loginResult.lightbg.r, loginResult.lightbg.g, loginResult.lightbg.b, 1);

        childList.clear();
        childListId.clear();

        for (int i = 0; i < loginResult.klienten.length; i++) {
          childList.add(loginResult.klienten.elementAt(i).fname + loginResult.klienten.elementAt(i).nname);
          childListId.add(loginResult.klienten.elementAt(i).id.toInt());
        }

        if (childList.isNotEmpty) {
          selectedChild = childListId.first;
        }

        final docConfigResult = await globalGrpcClient.getDocumentConfig();

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

        activityList.clear();
        activityListId.clear();

        for (int i = 0; i < taetigkeitenResult.taetigkeiten.length; i++) {
          activityList.add(taetigkeitenResult.taetigkeiten.elementAt(i).bezeichnung);
          activityListId.add(taetigkeitenResult.taetigkeiten.elementAt(i).id.toInt());
        }

        if (activityList.isNotEmpty) {
          selectedActivity = activityListId.first;
        }

        if (mounted) {
          Navigator.of(context).pushNamed('/menu');
        }
      } else {
        _responseController.text = loginResult.errorCode;
      }
    } catch (error) {
      if (error is GrpcError && error.code == StatusCode.permissionDenied) {
        _responseController.text = error.codeName;
      }
      _passController.text = '';
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
                  flex : 2,
                  child : TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Benutzername',
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex : 2,
                  child : TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ),
                const Spacer(flex: 3),
                Expanded(
                  flex: 2,
                  child: TextField(controller: _responseController),
                ),
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
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _login,
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
