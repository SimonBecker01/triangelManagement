import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/global.dart';
import 'package:fixnum/fixnum.dart' as fn;

class KategorienScreen extends StatefulWidget {
  const KategorienScreen({super.key});

  @override
  State<KategorienScreen> createState() => _KategorienState();
}

class _KategorienState extends State<KategorienScreen>{
  
  List<(int, String)> kategorien = <(int, String)>[];
  @override
  void initState() {
    super.initState();

    getCategoriesFromServer();


  }

  
  @override
  void dispose() {
    _categoryController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  DropdownMenu<int> dropDownCategories = DropdownMenu<int>(dropdownMenuEntries: const [],);

  final _categoryController = TextEditingController();
  final _responseController = TextEditingController();


  int categotryIndex = 0;
  

  void getCategoriesFromServer() async {
    DocumentConfigReply docConfRep = await globalGrpcClient.getDocumentConfig();
    kategorien.clear();
    for(int i = 0; i < docConfRep.kategorien.length; i++){
      kategorien.add((docConfRep.kategorien[i].id.toInt(), docConfRep.kategorien[i].bezeichnung));
    }
    dropDownCategories = _buildCategoriesDropdown();
    setState(() {
      categotryIndex = 0;
      _categoryController.text = kategorien[categotryIndex].$2;
    });
  }

  DropdownMenu<int> _buildCategoriesDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          kategorien.map<DropdownMenuEntry<int>>(
              ((int, String) singleCategory) => DropdownMenuEntry<int>(
                  value: singleCategory.$1, label: singleCategory.$2))),
      enabled: true,
      initialSelection: (kategorien.isNotEmpty) ? kategorien.first.$1 : null,
      onSelected: (value) {
        categotryIndex = kategorien.indexWhere((item) => item.$1 == value);
        _categoryController.text = kategorien[categotryIndex].$2;
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
            child: dropDownCategories,
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Kategorie',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Row(children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    ChangeKategorieReply resp = await globalGrpcClient.changeKategorie(IdObjekt(id: fn.Int64(kategorien[categotryIndex].$1), bezeichnung: _categoryController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_categoryController.text} wurde erfolgreich geändert";
                    }else{
                      _responseController.text = "${_categoryController.text} konnte nicht geändert werden";
                    }
                    getCategoriesFromServer();
                  },
                  child: const Text('Ändern'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    SetNewKategorieReply resp = await globalGrpcClient.setNewKategorie(IdObjekt(id: fn.Int64(kategorien[categotryIndex].$1), bezeichnung: _categoryController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_categoryController.text} wurde erfolgreich angelegt";
                    }else{
                      _responseController.text = "${_categoryController.text} konnte nicht angelegt werden";
                    }
                    getCategoriesFromServer();
                  },
                  child: const Text('Neu anlegen'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    DeleteKategorieReply resp = await globalGrpcClient.deleteKategorie(IdObjekt(id: fn.Int64(kategorien[categotryIndex].$1), bezeichnung: _categoryController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_categoryController.text} wurde erfolgreich gelöscht";
                    }else{
                      _responseController.text = "${_categoryController.text} konnte nicht gelöscht werden";
                    }
                    getCategoriesFromServer();
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
            child: dropDownCategories,
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Kategorie',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                ChangeKategorieReply resp = await globalGrpcClient.changeKategorie(IdObjekt(id: fn.Int64(kategorien[categotryIndex].$1), bezeichnung: _categoryController.text));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_categoryController.text} wurde erfolgreich geändert";
                }else{
                  _responseController.text = "${_categoryController.text} konnte nicht geändert werden";
                }
                getCategoriesFromServer();
              },
              child: const Text('Ändern'),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                SetNewKategorieReply resp = await globalGrpcClient.setNewKategorie(IdObjekt(id: fn.Int64(kategorien[categotryIndex].$1), bezeichnung: _categoryController.text));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_categoryController.text} wurde erfolgreich angelegt";
                }else{
                  _responseController.text = "${_categoryController.text} konnte nicht angelegt werden";
                }
                getCategoriesFromServer();
              },
              child: const Text('Neu anlegen'),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                DeleteKategorieReply resp = await globalGrpcClient.deleteKategorie(IdObjekt(id: fn.Int64(kategorien[categotryIndex].$1), bezeichnung: _categoryController.text));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_categoryController.text} wurde erfolgreich gelöscht";
                }else{
                  _responseController.text = "${_categoryController.text} konnte nicht gelöscht werden";
                }
                getCategoriesFromServer();
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