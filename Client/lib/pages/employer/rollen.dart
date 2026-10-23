import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/global.dart';
import 'package:fixnum/fixnum.dart' as fn;

class RollenScreen extends StatefulWidget {
  const RollenScreen({super.key});

  @override
  State<RollenScreen> createState() => _RollenState();
}

class _RollenState extends State<RollenScreen>{
  
  List<(int, String)> rollen = <(int, String)>[];
  @override
  void initState() {
    super.initState();

    getRolesFromServer();


  }

  
  @override
  void dispose() {
    super.dispose();
  }

  DropdownMenu<int> dropDownRoles = DropdownMenu<int>(dropdownMenuEntries: const [],);

  final _loginController = TextEditingController();
  final _lnameController = TextEditingController();
  final _fnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _responseController = TextEditingController();


  int nutzerIndex = 0;
  int roleIndex = 0;
  

  void getRolesFromServer() async {
    GetRolesReply rolesRep = await globalGrpcClient.getRoles();
    rollen.clear();
    for(int i = 0; i < rolesRep.rolesList.length; i++){
      rollen.add((rolesRep.rolesList[i].id.toInt(), rolesRep.rolesList[i].bezeichnung));
    }
    dropDownRoles = _buildRolesDropdown();
    setState(() {
      roleIndex = 0;
      _roleController.text = rollen[roleIndex].$2;
    });
  }

  void clearFields(){
    setState(() {
      _loginController.text = "";
      _lnameController.text = "";
      _fnameController.text = "";
      _emailController.text = "";
    });
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
      initialSelection: (rollen.isNotEmpty) ? rollen.first.$1 : null,
      onSelected: (value) {
        roleIndex = value!;
      },
    );
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
                  flex: 3,
                  child: TextField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Benutzername',
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
                      labelText: 'Nachname',
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
                      labelText: 'Vorname',
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
                      labelText: 'Email',
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: dropDownRoles,
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
                      CreateUserReply resp = await globalGrpcClient.createUser(UserObjekt(loginName: _loginController.text, email: _emailController.text, fname: _fnameController.text, lname: _lnameController.text, role: rollen[roleIndex].$1));
                      if(resp.errorCode.isEmpty){
                        _responseController.text = "${_loginController.text} wurde erfolgreich angelegt";
                        clearFields();
                      }else{
                        _responseController.text = "${_loginController.text} konnte nicht angelegt werden";
                      }
                    },
                    child: const Text('Nutzer anlegen'),
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