import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/global.dart';
import 'package:fixnum/fixnum.dart' as fn;

class TaetigkeitenScreen extends StatefulWidget {
  const TaetigkeitenScreen({super.key});

  @override
  State<TaetigkeitenScreen> createState() => _TaetigkeitenState();
}

class _TaetigkeitenState extends State<TaetigkeitenScreen>{
  
  List<(int, String, bool, bool)> taetigkeiten = <(int, String, bool, bool)>[];
  @override
  void initState() {
    super.initState();

    getActivitiesFromServer();


  }

  
  @override
  void dispose() {
    _activityController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  DropdownMenu<int> dropDownActivities = DropdownMenu<int>(dropdownMenuEntries: const [],);

  final _activityController = TextEditingController();
  final _responseController = TextEditingController();


  int activityIndex = 0;
  bool _abrechenbar = true;
  bool _buchbar = true;
  

  void getActivitiesFromServer() async {
    TaetigkeitReply taetigkeitRep = await globalGrpcClient.getTaetigkeiten();
    taetigkeiten.clear();
    for(int i = 0; i < taetigkeitRep.taetigkeiten.length; i++){
      taetigkeiten.add((taetigkeitRep.taetigkeiten[i].id.toInt(), taetigkeitRep.taetigkeiten[i].bezeichnung, taetigkeitRep.taetigkeiten[i].abrechenbar, taetigkeitRep.taetigkeiten[i].buchbar));
    }
    dropDownActivities = _buildActivitiesDropdown();
    setState(() {
      activityIndex = 0;
      _activityController.text = taetigkeiten[activityIndex].$2;
    });
  }

  DropdownMenu<int> _buildActivitiesDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          taetigkeiten.map<DropdownMenuEntry<int>>(
              ((int, String, bool, bool) singleRole) => DropdownMenuEntry<int>(
                  value: singleRole.$1, label: singleRole.$2))),
      enabled: true,
      initialSelection: (taetigkeiten.isNotEmpty) ? taetigkeiten.first.$1 : null,
      onSelected: (value) {
        activityIndex = taetigkeiten.indexWhere((item) => item.$1 == value);
        setState((){
          _activityController.text = taetigkeiten[activityIndex].$2;
          _abrechenbar = taetigkeiten[activityIndex].$3;
          _buchbar = taetigkeiten[activityIndex].$4;
        });
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
            child: dropDownActivities,
          ),
          const Spacer(flex: 2),
          Row(
            children: [
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _activityController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Taetigkeit',
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Text("Abrechenbar:"),
              Checkbox(value: _abrechenbar, onChanged: (bool? value) {setState(() { _abrechenbar = value!;});}),
              const Spacer(flex: 2),
              Text("Buchbar:"),
              Checkbox(value: _buchbar, onChanged: (bool? value) {setState(() { _buchbar = value!;});}),
              const Spacer(flex: 2),
            ],
          ),
          const Spacer(flex: 2),
          Row(
            children: [
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    ChangeTaetigkeitReply resp = await globalGrpcClient.changeTaetigkeit(Taetigkeit(id: fn.Int64(taetigkeiten[activityIndex].$1), bezeichnung: _activityController.text, abrechenbar: _abrechenbar, buchbar: _buchbar));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_activityController.text} wurde erfolgreich geändert";
                    }else{
                      _responseController.text = "${_activityController.text} konnte nicht geändert werden";
                    }
                    getActivitiesFromServer();
                  },
                  child: const Text('Ändern'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    SetNewTaetigkeitReply resp = await globalGrpcClient.setNewTaetigkeit(Taetigkeit(id: fn.Int64(taetigkeiten[activityIndex].$1), bezeichnung: _activityController.text, abrechenbar: _abrechenbar, buchbar: _buchbar));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_activityController.text} wurde erfolgreich angelegt";
                    }else{
                      _responseController.text = "${_activityController.text} konnte nicht angelegt werden";
                    }
                    getActivitiesFromServer();
                  },
                  child: const Text('Neu anlegen'),
                ),
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () async {
                    DeleteTaetigkeitReply resp = await globalGrpcClient.deleteTaetigkeit(fn.Int64(taetigkeiten[activityIndex].$1));
                    if(resp.errorCode.isEmpty){
                      _responseController.text = "${_activityController.text} wurde erfolgreich gelöscht";
                    }else{
                      _responseController.text = "${_activityController.text} konnte nicht gelöscht werden";
                    }
                    getActivitiesFromServer();
                  },
                  child: const Text('Löschen'),
                ),
              ),
              const Spacer(flex: 2),
            ],
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

  
  // Blöde kleine Bildschirme...
  Widget _buildNarrowLayout(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: dropDownActivities,
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _activityController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Taetigkeit',
              ),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                ChangeTaetigkeitReply resp = await globalGrpcClient.changeTaetigkeit(Taetigkeit(id: fn.Int64(taetigkeiten[activityIndex].$1), bezeichnung: _activityController.text));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_activityController.text} wurde erfolgreich geändert";
                }else{
                  _responseController.text = "${_activityController.text} konnte nicht geändert werden";
                }
                getActivitiesFromServer();
              },
              child: const Text('Ändern'),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                SetNewTaetigkeitReply resp = await globalGrpcClient.setNewTaetigkeit(Taetigkeit(id: fn.Int64(taetigkeiten[activityIndex].$1), bezeichnung: _activityController.text));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_activityController.text} wurde erfolgreich angelegt";
                }else{
                  _responseController.text = "${_activityController.text} konnte nicht angelegt werden";
                }
                getActivitiesFromServer();
              },
              child: const Text('Neu anlegen'),
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: () async {
                DeleteTaetigkeitReply resp = await globalGrpcClient.deleteTaetigkeit(fn.Int64(taetigkeiten[activityIndex].$1));
                if(resp.errorCode.isEmpty){
                  _responseController.text = "${_activityController.text} wurde erfolgreich gelöscht";
                }else{
                  _responseController.text = "${_activityController.text} konnte nicht gelöscht werden";
                }
                getActivitiesFromServer();
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