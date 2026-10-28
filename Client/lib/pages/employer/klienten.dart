import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/global.dart';
import 'package:fixnum/fixnum.dart' as fn;

class KlientenverwaltungScreen extends StatefulWidget {
  const KlientenverwaltungScreen({super.key});

  @override
  State<KlientenverwaltungScreen> createState() => _KlientenverwaltungState();
}

class _KlientenverwaltungState extends State<KlientenverwaltungScreen>{
  
  List<(String, String)> klientenNamen = <(String, String)>[];
  @override
  void initState() {
    super.initState();

    getChildrenFromServer();


  }

  
  @override
  void dispose() {
    _nachNameController.dispose();
    _vorNameController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  DropdownMenu<String> dropDownChildren = DropdownMenu<String>(dropdownMenuEntries: const [],);

  final _nachNameController = TextEditingController();
  final _vorNameController = TextEditingController();
  final _responseController = TextEditingController();


  int categotryIndex = 0;
  

  void getChildrenFromServer() async {
    GetKlientenReply klienten = await globalGrpcClient.getKlienten();

    childList.clear();
    childListId.clear();

    for (int i = 0; i < klienten.klientenList.length; i++) {
      childList.add(klienten.klientenList.elementAt(i).fname + klienten.klientenList.elementAt(i).nname);
      childListId.add(klienten.klientenList.elementAt(i).id.toInt());
      klientenNamen.add((klienten.klientenList.elementAt(i).nname, klienten.klientenList.elementAt(i).fname));
    }

    selectedChild = 0;

    dropDownChildren = _buildChildDropdown();
    setState(() {
      _nachNameController.text = klientenNamen[selectedChild].$1;
      _vorNameController.text = klientenNamen[selectedChild].$2;
    });
  }

  DropdownMenu<String> _buildChildDropdown() {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          childList.map<DropdownMenuEntry<String>>(
              (String name) => DropdownMenuEntry<String>(
                  value: name, label: name))),
      enabled: childList.length > 1,
      initialSelection: (childList.isNotEmpty && selectedChild > 0) ? childList[selectedChild] : null,
      onSelected: (value) {
        if (value != null) {
          selectedChild = childList.indexOf(value);
        }
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
            child: dropDownChildren,
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nachNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nachname',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _vorNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Vorname',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Row(children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    ChangeKlientReply resp = await globalGrpcClient.changeKlient(Klient(id: fn.Int64(childListId[selectedChild]), nname: _nachNameController.text, fname: _vorNameController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${childList[selectedChild]} wurde erfolgreich geändert";
                    }else{
                      _responseController.text = "${childList[selectedChild]} konnte nicht geändert werden";
                    }
                    getChildrenFromServer();
                  },
                  child: const Text('Ändern'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    SetNewKlientReply resp = await globalGrpcClient.setNewKlient(Klient(nname: _nachNameController.text, fname: _vorNameController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_vorNameController.text + _nachNameController.text} wurde erfolgreich angelegt";
                    }else{
                      _responseController.text = "${_vorNameController.text + _nachNameController.text} konnte nicht angelegt werden";
                    }
                    getChildrenFromServer();
                  },
                  child: const Text('Neu anlegen'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    DeleteKlientReply resp = await globalGrpcClient.deleteKlient(fn.Int64(childListId[selectedChild]));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${childList[selectedChild]} wurde erfolgreich gelöscht";
                    }else{
                      _responseController.text = "${childList[selectedChild]} konnte nicht gelöscht werden";
                    }
                    getChildrenFromServer();
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
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: dropDownChildren,
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nachNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nachname',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _vorNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Vorname',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Row(children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    ChangeKlientReply resp = await globalGrpcClient.changeKlient(Klient(id: fn.Int64(childListId[selectedChild]), nname: _nachNameController.text, fname: _vorNameController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${childList[selectedChild]} wurde erfolgreich geändert";
                    }else{
                      _responseController.text = "${childList[selectedChild]} konnte nicht geändert werden";
                    }
                    getChildrenFromServer();
                  },
                  child: const Text('Ändern'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    SetNewKlientReply resp = await globalGrpcClient.setNewKlient(Klient(nname: _nachNameController.text, fname: _vorNameController.text));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_vorNameController.text + _nachNameController.text} wurde erfolgreich angelegt";
                    }else{
                      _responseController.text = "${_vorNameController.text + _nachNameController.text} konnte nicht angelegt werden";
                    }
                    getChildrenFromServer();
                  },
                  child: const Text('Neu anlegen'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    DeleteKlientReply resp = await globalGrpcClient.deleteKlient(fn.Int64(childListId[selectedChild]));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${childList[selectedChild]} wurde erfolgreich gelöscht";
                    }else{
                      _responseController.text = "${childList[selectedChild]} konnte nicht gelöscht werden";
                    }
                    getChildrenFromServer();
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

}