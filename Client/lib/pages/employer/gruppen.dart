import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/global.dart';
import 'package:fixnum/fixnum.dart' as fn;

class GruppenScreen extends StatefulWidget {
  const GruppenScreen({super.key});

  @override
  State<GruppenScreen> createState() => _GruppenState();
}

class _GruppenState extends State<GruppenScreen>{
  
  List<(int, String)> gruppen = <(int, String)>[];
  @override
  void initState() {
    super.initState();

    getGroupsFromServer();


  }

  
  @override
  void dispose() {
    _groupController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  DropdownMenu<int> dropDownGroups = DropdownMenu<int>(dropdownMenuEntries: const [],);

  final _groupController = TextEditingController();
  final _responseController = TextEditingController();


  int categotryIndex = 0;
  

  void getGroupsFromServer() async {
    DocumentConfigReply docConfRep = await globalGrpcClient.getDocumentConfig();
    gruppen.clear();
    for(int i = 0; i < docConfRep.gruppen.length; i++){
      gruppen.add((docConfRep.gruppen[i].id.toInt(), docConfRep.gruppen[i].bezeichnung));
    }
    dropDownGroups = _buildGroupsDropdown();
    setState(() {
      categotryIndex = 0;
      _groupController.text = gruppen[categotryIndex].$2;
    });
  }

  DropdownMenu<int> _buildGroupsDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          gruppen.map<DropdownMenuEntry<int>>(
              ((int, String) singleGroup) => DropdownMenuEntry<int>(
                  value: singleGroup.$1, label: singleGroup.$2))),
      enabled: true,
      initialSelection: (gruppen.isNotEmpty) ? gruppen.first.$1 : null,
      onSelected: (value) {
        categotryIndex = gruppen.indexWhere((item) => item.$1 == value);
        _groupController.text = gruppen[categotryIndex].$2;
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
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: dropDownGroups,
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _groupController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Gruppe',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Row(children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    ChangeGruppeReply resp = await globalGrpcClient.changeGruppe(IdObjekt(id: fn.Int64(gruppen[categotryIndex].$1), bezeichnung: _groupController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_groupController.text} wurde erfolgreich geändert";
                    }else{
                      _responseController.text = "${_groupController.text} konnte nicht geändert werden";
                    }
                    getGroupsFromServer();
                  },
                  child: const Text('Ändern'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    SetNewGruppeReply resp = await globalGrpcClient.setNewGruppe(IdObjekt(id: fn.Int64(gruppen[categotryIndex].$1), bezeichnung: _groupController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_groupController.text} wurde erfolgreich angelegt";
                    }else{
                      _responseController.text = "${_groupController.text} konnte nicht angelegt werden";
                    }
                    getGroupsFromServer();
                  },
                  child: const Text('Neu anlegen'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    DeleteGruppeReply resp = await globalGrpcClient.deleteGruppe(IdObjekt(id: fn.Int64(gruppen[categotryIndex].$1), bezeichnung: _groupController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_groupController.text} wurde erfolgreich gelöscht";
                    }else{
                      _responseController.text = "${_groupController.text} konnte nicht gelöscht werden";
                    }
                    getGroupsFromServer();
                  },
                  child: const Text('Löschen'),
                ),
              ),
            ]
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 2,
            child: Center(child: TextField(controller: _responseController, enabled: false,)),
          ),
        ]
      )
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: dropDownGroups,
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _groupController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Gruppe',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                ChangeGruppeReply resp = await globalGrpcClient.changeGruppe(IdObjekt(id: fn.Int64(gruppen[categotryIndex].$1), bezeichnung: _groupController.text));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_groupController.text} wurde erfolgreich geändert";
                }else{
                  _responseController.text = "${_groupController.text} konnte nicht geändert werden";
                }
                getGroupsFromServer();
              },
              child: const Text('Ändern'),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                SetNewGruppeReply resp = await globalGrpcClient.setNewGruppe(IdObjekt(id: fn.Int64(gruppen[categotryIndex].$1), bezeichnung: _groupController.text));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_groupController.text} wurde erfolgreich angelegt";
                }else{
                  _responseController.text = "${_groupController.text} konnte nicht angelegt werden";
                }
                getGroupsFromServer();
              },
              child: const Text('Neu anlegen'),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                DeleteGruppeReply resp = await globalGrpcClient.deleteGruppe(IdObjekt(id: fn.Int64(gruppen[categotryIndex].$1), bezeichnung: _groupController.text));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_groupController.text} wurde erfolgreich gelöscht";
                }else{
                  _responseController.text = "${_groupController.text} konnte nicht gelöscht werden";
                }
                getGroupsFromServer();
              },
              child: const Text('Löschen'),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 2,
            child: Center(child: TextField(controller: _responseController, enabled: false,)),
          ),
        ]
      )
    );
  }

}