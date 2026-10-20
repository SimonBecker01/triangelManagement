import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/global.dart';
import 'package:fixnum/fixnum.dart' as fn;

class NutzerverwaltungScreen extends StatefulWidget {
  const NutzerverwaltungScreen({super.key});

  @override
  State<NutzerverwaltungScreen> createState() => _NutzerverwaltungState();
}

class _NutzerverwaltungState extends State<NutzerverwaltungScreen>{
  
  List<(int, String)> rollen = <(int, String)>[];
  List<(int, String, String, String, String, int)> nutzer = <(int, String, String, String, String, int)>[];
  @override
  void initState() {
    super.initState();

    getRolesFromServer();


  }

  
  @override
  void dispose() {
    super.dispose();
  }

  
  DropdownMenu<int> dropDownUsers = DropdownMenu<int>(dropdownMenuEntries: const [],);
  DropdownMenu<int> dropDownRoles = DropdownMenu<int>(dropdownMenuEntries: const [],);

  final _loginController = TextEditingController();
  final _lnameController = TextEditingController();
  final _fnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _responseController = TextEditingController();

  bool _passReset = true;

  int nutzerIndex = 0;
  int roleIndex = 0;
  

  void getRolesFromServer() async {
    GetRolesReply rolesRep = await globalGrpcClient.getRoles();
    rollen.clear();
    for(int i = 0; i < rolesRep.rolesList.length; i++){
      rollen.add((rolesRep.rolesList[i].id.toInt(), rolesRep.rolesList[i].bezeichnung));
    }
    getUsersFromServer();
  }

  void getUsersFromServer() async {
    GetUsersReply usersRep = await globalGrpcClient.getUsers();
    nutzer.clear();
    for(int i = 0; i < usersRep.userList.length; i++){
      nutzer.add((usersRep.userList[i].id.toInt(), usersRep.userList[i].loginName, usersRep.userList[i].lname, usersRep.userList[i].fname, usersRep.userList[i].email, usersRep.userList[i].role.toInt()));
    }
    dropDownUsers = _buildUserDropdown();
    dropDownRoles = _buildRolesDropdown();
    updateNutzerDisplay(nutzer[0].$1);
  }

  DropdownMenu<int> _buildRolesDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          rollen.map<DropdownMenuEntry<int>>(
              ((int, String) singleRole) => DropdownMenuEntry<int>(
                  value: singleRole.$1, label: singleRole.$2))),
      enabled: true,
      controller: _roleController,
      initialSelection: (rollen.isNotEmpty && nutzer.isNotEmpty) ? nutzer.first.$6 : null,
      onSelected: (value) {
        roleIndex = value!;
      },
    );
  }
  
  DropdownMenu<int> _buildUserDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          nutzer.map<DropdownMenuEntry<int>>(
              ((int, String, String, String, String, int) singleUser) => DropdownMenuEntry<int>(
                  value: singleUser.$1, label: singleUser.$2))),
      enabled: true,
      initialSelection: nutzer.isNotEmpty ? nutzer.first.$1 : null,
      onSelected: (value) {
        if (value != null) {
          updateNutzerDisplay(value);
        }
      },
    );
  }

  
  void updateNutzerDisplay(int nutzerId) {
    setState(() {
        if(rollen.isNotEmpty && nutzer.isNotEmpty){
          nutzerIndex = nutzer.indexWhere((item) => item.$1 == nutzerId);
          _loginController.text = nutzer[nutzerIndex].$2;
          _lnameController.text = nutzer[nutzerIndex].$3;
          _fnameController.text = nutzer[nutzerIndex].$4;
          _emailController.text = nutzer[nutzerIndex].$5;
          roleIndex = rollen.indexWhere((item) => item.$1 == nutzer[nutzerIndex].$6);
          _roleController.text = rollen[roleIndex].$2;
          _passReset = false;
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standardAppBar(actions: [logoutAction(context)]),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (useWideLayout(constraints)) {
            return _buildWideLayout(context);
          }
          return _buildNarrowLayout(context);
        },
      ),
    );
  }

  
  Widget _buildWideLayout(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                const Spacer(flex: 1),
                Expanded(
                  flex: 1,
                  child: dropDownUsers,
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _lnameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _fnameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: dropDownRoles,
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Text("Passwort zurücksetzen:"),
                      Checkbox(value: _passReset, onChanged: (bool? value) {setState(() { _passReset = value!;});})
                    ]
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: () async {
                      ChangeUserReply resp = await globalGrpcClient.changeUser(UserObjekt(id: fn.Int64(nutzer[nutzerIndex].$1), loginName: _loginController.text, email: _emailController.text, fname: _fnameController.text, lname: _lnameController.text, role: rollen[roleIndex].$1), (_passReset) ? 1 : 0);
                      if(resp.errorCode.isEmpty){
                        _responseController.text = "${_loginController.text} wurde erfolgreich geändert";
                      }else{
                        _responseController.text = "${_loginController.text} konnte nicht geändert werden";
                      }
                      getUsersFromServer();
                    },
                    child: const Text('Änderung speichern'),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/neuernutzer');
                    },
                    child: const Text('Neu'),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: TextField(controller: _responseController, enabled: false,)),
          ),
        ]
      )
    );
  }

  
  // Blöde kleine Bildschirme...
  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView();
  }
}