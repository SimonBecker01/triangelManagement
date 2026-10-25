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

    getDocConfigFromServer();

    getRechteFromServer();

    getRolesFromServer();

  }

  
  @override
  void dispose() {
    super.dispose();
  }

  DropdownMenu<int> dropDownRoles = DropdownMenu<int>(dropdownMenuEntries: const [],);

  final _roleController = TextEditingController();
  final _responseController = TextEditingController();

  List<(int, int)> rechtGrp = [];
  List<(int, int)> rechtKat = [];


  int nutzerIndex = 0;
  int roleIndex = 0;
  
  void getDocConfigFromServer() async {
    
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
  }


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

  void getRechteFromServer() async {
    GetRechteGruppeReply rechtGrpRep = await globalGrpcClient.getRechteGruppe();
    GetRechteKategorienReply rechtKatRep = await globalGrpcClient.getRechteKategorien();
    rechtGrp.clear();
    rechtKat.clear();
    for(int i = 0; i < rechtGrpRep.rechteGruppe.length; i++){
      rechtGrp.add((rechtGrpRep.rechteGruppe[i].idFirst.toInt(), rechtGrpRep.rechteGruppe[i].idSecond.toInt()));
    }
    for(int i = 0; i < rechtKatRep.rechteKategorien.length; i++){
      rechtKat.add((rechtKatRep.rechteKategorien[i].idFirst.toInt(), rechtKatRep.rechteKategorien[i].idSecond.toInt()));
    }

  }

  DropdownMenu<int> _buildRolesDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          rollen.map<DropdownMenuEntry<int>>(
              ((int, String) singleRole) => DropdownMenuEntry<int>(
                  value: singleRole.$1, label: singleRole.$2))),
      enabled: true,
      initialSelection: (rollen.isNotEmpty) ? rollen.first.$1 : null,
      onSelected: (value) {
        for(int i = 0; i < rollen.length; i++){
          if(rollen[i].$1 == value){
            roleIndex = i;
            break;
          }
        }
        setState(() {
          _roleController.text = rollen[roleIndex].$2;
          selectedCategories.clear();
          selectedDocumentGroups.clear();
          for(int i = 0; i < rechtGrp.length; i++){
            if(rechtGrp[i].$1 == rollen[roleIndex].$1){
              selectedDocumentGroups.add(rechtGrp[i].$2);
            }
          }
          for(int i = 0; i < rechtKat.length; i++){
            if(rechtKat[i].$1 == rollen[roleIndex].$1){
              selectedCategories.add(rechtKat[i].$2);
            }
          }
        });
      },
    );
  }
  
  
  Widget _categoryListView() {
    return ListView.builder(
      itemCount: documentCategoryList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(documentCategoryList[index]),
          tileColor: selectedCategories.contains(documentCategoryListId[index])
              ? Colors.blue
              : Colors.white,
          onTap: () {
            setState(() {
              if (selectedCategories.contains(documentCategoryListId[index])) {
                selectedCategories
                    .removeAt(selectedCategories.indexOf(documentCategoryListId[index]));
              } else {
                selectedCategories.add(documentCategoryListId[index]);
              }
            });
          },
        );
      },
    );
  }
  
  Widget _groupListView() {
    return ListView.builder(
      itemCount: documentGroupListId.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(documentGroupList[index]),
          tileColor: selectedDocumentGroups.contains(documentGroupListId[index])
              ? Colors.blue
              : Colors.white,
          onTap: () {
            setState(() {
              if (selectedDocumentGroups.contains(documentGroupListId[index])) {
                selectedDocumentGroups
                    .removeAt(selectedDocumentGroups.indexOf(documentGroupListId[index]));
              } else {
                selectedDocumentGroups.add(documentGroupListId[index]);
              }
            });
          },
        );
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
                  child: dropDownRoles,
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Rolle',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Spacer(flex: 2),
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _categoryListView(),
                  ),
                ),
                const Spacer(flex: 4),
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _groupListView(),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Row(children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    String respText;
                    List<fn.Int64> gruppenId = [];
                    List<fn.Int64> kategorienId = [];
                    for(int i = 0; i < selectedDocumentGroups.length; i++){
                      gruppenId.add(fn.Int64(selectedDocumentGroups[i]));
                    }
                    for(int i = 0; i < selectedCategories.length; i++){
                      kategorienId.add(fn.Int64(selectedCategories[i]));
                    }
                    if((rollen[roleIndex].$2) != _roleController.text){
                      ChangeRolleReply resp = await globalGrpcClient.changeRolle(IdObjekt(id: fn.Int64(rollen[roleIndex].$1), bezeichnung: _roleController.text));
                      if(resp.errorCode.isEmpty){
                        SetRechteReply rechtRep = await globalGrpcClient.setRechte(fn.Int64(rollen[roleIndex].$1), gruppenId, kategorienId);
                        if(rechtRep.errorCode.isEmpty){
                          respText = "${_roleController.text} wurde erfolgreich geändert";
                        }else{
                          respText = "${_roleController.text} wurde erfolgreich geändert, Rechte konnten nicht gesetzt werden";
                        }
                      }else{
                        respText = "${_roleController.text} konnte nicht geändert werden";
                      }
                    }else{
                        SetRechteReply rechtRep = await globalGrpcClient.setRechte(fn.Int64(rollen[roleIndex].$1), gruppenId, kategorienId);
                        if(rechtRep.errorCode.isEmpty){
                          respText = "${_roleController.text} Rechte wurden erfolgreich gesetzt";
                        }else{
                          respText = "${_roleController.text} Rechte konnten nicht gesetzt werden";
                        }
                    }
                    _responseController.text = respText;
                    getRechteFromServer();
                    getRolesFromServer();
                  },
                  child: const Text('Ändern'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    String respText;
                    List<fn.Int64> gruppenId = [];
                    List<fn.Int64> kategorienId = [];
                    for(int i = 0; i < selectedDocumentGroups.length; i++){
                      gruppenId.add(fn.Int64(selectedDocumentGroups[i]));
                    }
                    for(int i = 0; i < selectedCategories.length; i++){
                      kategorienId.add(fn.Int64(selectedCategories[i]));
                    }
                    SetNewRolleReply resp = await globalGrpcClient.setNewRolle(IdObjekt(id: fn.Int64(rollen[roleIndex].$1), bezeichnung: _roleController.text));
                    if(resp.errorCode.isEmpty){
                      
                      GetRolesReply rolesRep = await globalGrpcClient.getRoles();
                      fn.Int64 roleId = fn.Int64(0);
                      for(int i = 0; i < rolesRep.rolesList.length; i++){
                        if(rolesRep.rolesList[i].bezeichnung == _roleController.text){
                          roleId = rolesRep.rolesList[i].id;
                          break;
                        }
                      }
                      SetRechteReply rechtRep = await globalGrpcClient.setRechte(roleId, gruppenId, kategorienId);
                      if(rechtRep.errorCode.isEmpty){
                        respText = "${_roleController.text} wurde erfolgreich angelegt";
                      }else{
                        respText = "${_roleController.text} wurde erfolgreich angelegt, Rechte konnten nicht gesetzt werden";
                      }
                    }else{
                      respText = "${_roleController.text} konnte nicht geändert werden";
                    }
                    _responseController.text = respText;
                    getRechteFromServer();
                    getRolesFromServer();
                  },
                  child: const Text('Neu anlegen'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    DeleteRolleReply resp = await globalGrpcClient.deleteRolle(IdObjekt(id: fn.Int64(rollen[roleIndex].$1), bezeichnung: _roleController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_roleController.text} wurde erfolgreich gelöscht";
                    }else{
                      _responseController.text = "${_roleController.text} konnte nicht gelöscht werden";
                    }
                    getRolesFromServer();
                  },
                  child: const Text('Löschen'),
                ),
              ),
            ]
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
    return SingleChildScrollView(
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
                  child: dropDownRoles,
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Rolle',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Spacer(flex: 2),
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _categoryListView(),
                  ),
                ),
                const Spacer(flex: 4),
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _groupListView(),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Row(children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    String respText;
                    List<fn.Int64> gruppenId = [];
                    List<fn.Int64> kategorienId = [];
                    for(int i = 0; i < selectedDocumentGroups.length; i++){
                      gruppenId.add(fn.Int64(selectedDocumentGroups[i]));
                    }
                    for(int i = 0; i < selectedCategories.length; i++){
                      kategorienId.add(fn.Int64(selectedCategories[i]));
                    }
                    if((rollen[roleIndex].$2) != _roleController.text){
                      ChangeRolleReply resp = await globalGrpcClient.changeRolle(IdObjekt(id: fn.Int64(rollen[roleIndex].$1), bezeichnung: _roleController.text));
                      if(resp.errorCode.isEmpty){
                        SetRechteReply rechtRep = await globalGrpcClient.setRechte(fn.Int64(rollen[roleIndex].$1), gruppenId, kategorienId);
                        if(rechtRep.errorCode.isEmpty){
                          respText = "${_roleController.text} wurde erfolgreich geändert";
                        }else{
                          respText = "${_roleController.text} wurde erfolgreich geändert, Rechte konnten nicht gesetzt werden";
                        }
                      }else{
                        respText = "${_roleController.text} konnte nicht geändert werden";
                      }
                    }else{
                        SetRechteReply rechtRep = await globalGrpcClient.setRechte(fn.Int64(rollen[roleIndex].$1), gruppenId, kategorienId);
                        if(rechtRep.errorCode.isEmpty){
                          respText = "${_roleController.text} Rechte wurden erfolgreich gesetzt";
                        }else{
                          respText = "${_roleController.text} Rechte konnten nicht gesetzt werden";
                        }
                    }
                    _responseController.text = respText;
                    getRechteFromServer();
                    getRolesFromServer();
                  },
                  child: const Text('Ändern'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    String respText;
                    List<fn.Int64> gruppenId = [];
                    List<fn.Int64> kategorienId = [];
                    for(int i = 0; i < selectedDocumentGroups.length; i++){
                      gruppenId.add(fn.Int64(selectedDocumentGroups[i]));
                    }
                    for(int i = 0; i < selectedCategories.length; i++){
                      kategorienId.add(fn.Int64(selectedCategories[i]));
                    }
                    SetNewRolleReply resp = await globalGrpcClient.setNewRolle(IdObjekt(id: fn.Int64(rollen[roleIndex].$1), bezeichnung: _roleController.text));
                    if(resp.errorCode.isEmpty){
                      
                      GetRolesReply rolesRep = await globalGrpcClient.getRoles();
                      fn.Int64 roleId = fn.Int64(0);
                      for(int i = 0; i < rolesRep.rolesList.length; i++){
                        if(rolesRep.rolesList[i].bezeichnung == _roleController.text){
                          roleId = rolesRep.rolesList[i].id;
                          break;
                        }
                      }
                      SetRechteReply rechtRep = await globalGrpcClient.setRechte(roleId, gruppenId, kategorienId);
                      if(rechtRep.errorCode.isEmpty){
                        respText = "${_roleController.text} wurde erfolgreich angelegt";
                      }else{
                        respText = "${_roleController.text} wurde erfolgreich angelegt, Rechte konnten nicht gesetzt werden";
                      }
                    }else{
                      respText = "${_roleController.text} konnte nicht geändert werden";
                    }
                    _responseController.text = respText;
                    getRechteFromServer();
                    getRolesFromServer();
                  },
                  child: const Text('Neu anlegen'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    DeleteRolleReply resp = await globalGrpcClient.deleteRolle(IdObjekt(id: fn.Int64(rollen[roleIndex].$1), bezeichnung: _roleController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_roleController.text} wurde erfolgreich gelöscht";
                    }else{
                      _responseController.text = "${_roleController.text} konnte nicht gelöscht werden";
                    }
                    getRolesFromServer();
                  },
                  child: const Text('Löschen'),
                ),
              ),
            ]
          ),
          Expanded(
            flex: 2,
            child: Center(child: TextField(controller: _responseController, enabled: false,)),
          ),
        ]
      )
    );
  }
}