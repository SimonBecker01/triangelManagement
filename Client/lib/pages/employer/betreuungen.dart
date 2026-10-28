import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/global.dart';
import 'package:fixnum/fixnum.dart' as fn;
import 'package:intl/intl.dart';

class BetreuungenScreen extends StatefulWidget {
  const BetreuungenScreen({super.key});

  @override
  State<BetreuungenScreen> createState() => _BetreuungenState();
}

class _BetreuungenState extends State<BetreuungenScreen>{
  


  @override
  void initState() {
    super.initState();
    getUsersFromServer();
    getBetreuungenFromServer();
  }

  
  @override
  void dispose() {
    _responseController.dispose();
    _gueltVonController.dispose();
    _gueltBisController.dispose();
    _wochenstundenController.dispose();
    _stundensatzController.dispose();
    _userController.dispose();
    _klientController.dispose();
    _betreuungenController.dispose();
    super.dispose();
  }


  List<(int, String, String)> nutzer = <(int, String, String)>[];
  List<(int, String, int, int, int, int, DateTime, DateTime)> betreuungen = <(int, String, int, int, int, int, DateTime, DateTime)>[];
  int nutzerIndex = 0;
  int betreuungenIndex = 0;
  DateTime selectedGueltigVon = DateTime(1700, 1, 1);
  DateTime selectedGueltigBis = DateTime(2700, 1, 1);
  final _responseController = TextEditingController();
  final _gueltVonController = TextEditingController();
  final _gueltBisController = TextEditingController();
  final _wochenstundenController = TextEditingController();
  final _stundensatzController = TextEditingController();
  final _userController = TextEditingController();
  final _klientController = TextEditingController();
  final _betreuungenController = TextEditingController();
  


  final DateFormat formatYMD = DateFormat('y.M.d');

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
  

  void getUsersFromServer() async {
    GetUsersReply usersRep = await globalGrpcClient.getUsers();
    nutzer.clear();
    for(int i = 0; i < usersRep.userList.length; i++){
      nutzer.add((usersRep.userList[i].id.toInt(), "${usersRep.userList[i].fname} ${usersRep.userList[i].lname}", usersRep.userList[i].loginName));
    }
  }

  void getBetreuungenFromServer() async {
    GetBetreuungenReply betreuungenRep = await globalGrpcClient.getBetreuungen(true);
    betreuungen.clear();
    for(int i = 0; i < betreuungenRep.betreuungen.length; i++){
      int uind = 0;
      for(uind;uind < nutzer.length; uind++){
        if(nutzer[uind].$1 == betreuungenRep.betreuungen[i].betreuerId.toInt()) break;
      }
      betreuungen.add((betreuungenRep.betreuungen[i].id.toInt(),
      "${nutzer[uind].$3}, ${nutzer[uind].$2} betreut ${childList[childListId.indexOf(betreuungenRep.betreuungen[i].klientId.toInt())]}${(betreuungenRep.betreuungen[i].gueltigVon.year > 1800)?(" von ${betreuungenRep.betreuungen[i].gueltigVon.year}-${betreuungenRep.betreuungen[i].gueltigVon.month}-${betreuungenRep.betreuungen[i].gueltigVon.day}"):""}${(betreuungenRep.betreuungen[i].gueltigBis.year > 1800)?(" bis ${betreuungenRep.betreuungen[i].gueltigBis.year}-${betreuungenRep.betreuungen[i].gueltigBis.month}-${betreuungenRep.betreuungen[i].gueltigBis.day}"):""}",
      uind,
      childListId.indexOf(betreuungenRep.betreuungen[i].klientId.toInt()),
      betreuungenRep.betreuungen[i].wochenstunden.toInt(),
      betreuungenRep.betreuungen[i].stundensatz.toInt(),
      DateTime(betreuungenRep.betreuungen[i].gueltigVon.year.toInt(), betreuungenRep.betreuungen[i].gueltigVon.month.toInt(), betreuungenRep.betreuungen[i].gueltigVon.day.toInt()),
      DateTime(betreuungenRep.betreuungen[i].gueltigBis.year.toInt(), betreuungenRep.betreuungen[i].gueltigBis.month.toInt(), betreuungenRep.betreuungen[i].gueltigBis.day.toInt())));
    }
    if(betreuungen.isNotEmpty){
      betreuungenIndex = 0;
      _betreuungenController.text = betreuungen.first.$2;
      _wochenstundenController.text = "${betreuungen.first.$5 / 60}";
      _stundensatzController.text = "${betreuungen.first.$6 / 100}";
      _gueltVonController.text = formatYMD.format(betreuungen.first.$7);
      _gueltBisController.text = formatYMD.format(betreuungen.first.$8);
      selectedChild = betreuungen.first.$4;
      _klientController.text = childList.elementAt(selectedChild);
      nutzerIndex = betreuungen.first.$3;
      _userController.text = nutzer[nutzerIndex].$2;
    }
    setState(() {
      //Rebuilding the DropDowns with filled Lists
    });
  }



  DropdownMenu<int> _buildUserDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          nutzer.map<DropdownMenuEntry<int>>(
              ((int, String, String) singleUser) => DropdownMenuEntry<int>(
                  value: singleUser.$1, label: "${singleUser.$3}, ${singleUser.$2}"))),
      enabled: true,
      controller: _userController,
      initialSelection: (nutzer.isNotEmpty && nutzerIndex > 0) ? nutzer[nutzerIndex].$1 : null,
      onSelected: (value) {
        if (value != null) {
          for(int i = 0; i < nutzer.length; i++){
            if(nutzer[i].$1 == value){
              nutzerIndex = i;
              break;
            }
          }
        }
      },
    );
  }
  
  DropdownMenu<String> _buildChildDropdown() {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          childList.map<DropdownMenuEntry<String>>(
              (String name) => DropdownMenuEntry<String>(
                  value: name, label: name))),
      enabled: childList.length > 1,
      controller: _klientController,
      initialSelection: (childList.isNotEmpty && selectedChild > 0) ? childList[selectedChild] : null,
      onSelected: (value) {
        if (value != null) {
          selectedChild = childListId.elementAt(childList.indexOf(value));
        }
      },
    );
  }

  DropdownMenu<int> _buildBetreuungDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          betreuungen.map<DropdownMenuEntry<int>>(
              ((int, String, int, int, int, int, DateTime, DateTime) singleBetreuung) => DropdownMenuEntry<int>(
                  value: singleBetreuung.$1, label: singleBetreuung.$2))),
      enabled: true,
      controller: _betreuungenController,
      initialSelection: betreuungen.isNotEmpty ? betreuungen.first.$1 : null,
      onSelected: (value) {
        if (value != null) {
          for(int i = 0; i < betreuungen.length; i++){
            if(betreuungen[i].$1 == value){
              betreuungenIndex = i;
              _gueltVonController.text = formatYMD.format(betreuungen[i].$7);
              _gueltBisController.text = formatYMD.format(betreuungen[i].$8);
              _wochenstundenController.text = (betreuungen[i].$5 / 60).toString();
              _stundensatzController.text = (betreuungen[i].$6 / 100).toString();
              selectedChild = betreuungen[i].$4;
              _klientController.text = childList.elementAt(selectedChild);
              nutzerIndex = betreuungen[i].$3;
              _userController.text = nutzer[nutzerIndex].$2;
              break;
            }
          }
        }
      },
    );
  }

  
  Widget _buildWideLayout(BuildContext context) {
    return Center(child: Column
    (
      children: [
        const Spacer(flex: 2),
        Expanded(
          flex: 5,
          child:
            Row(children: 
              [
                const Spacer(flex: 2),
                Expanded(
                  flex: 10,
                  child: _buildBetreuungDropdown(),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      EndBetreuungReply resp = await globalGrpcClient.endBetreuung(fn.Int64(betreuungen[betreuungenIndex].$1));
                      if(resp.errorCode.isEmpty){
                        _responseController.text = "Betreuung wurde erfolgreich beendet";
                      }else{
                        _responseController.text = "Betreuung konnte nicht beendet werden";
                      }
                      getBetreuungenFromServer();
                    },
                    child: const Text('Betreuung beenden'),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
        ),
        const Spacer(flex: 2),
        Expanded(
          flex: 5,
          child:
            Row(children: 
              [
                const Spacer(flex: 2),
                Expanded(
                  flex: 5,
                  child: _buildChildDropdown(),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 5,
                  child: _buildUserDropdown(),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _gueltVonController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Gültig von',
                      enabled: false,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _gueltBisController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Gültig bis',
                      enabled: false,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _wochenstundenController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Wochenstunden',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _stundensatzController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Stundensatz',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
        ),
        const Spacer(flex: 2),
        Expanded(
          flex: 9,
          child:
            Row(children: 
              [
                const Spacer(flex: 8),
                Expanded(
                  flex: 3,
                  child: CalendarDatePicker(
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2200),
                    onDateChanged: (DateTime value) {
                      selectedGueltigVon = value;
                      _gueltVonController.text = formatYMD.format(selectedGueltigVon);
                    },
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: CalendarDatePicker(
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2200),
                    onDateChanged: (DateTime value) {
                      selectedGueltigBis = value;
                      _gueltBisController.text = formatYMD.format(selectedGueltigBis);
                    },
                  ),
                ),
                const Spacer(flex: 6),
              ],
            ),
        ),
        const Spacer(flex: 2),
        Expanded(
          flex: 5,
          child:
            Row(children: 
              [
                const Spacer(flex: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      selectedGueltigVon = DateTime(1700, 1, 1);
                      _gueltVonController.text = formatYMD.format(selectedGueltigVon);
                      selectedGueltigVon = DateTime(2700, 1, 1);
                      _gueltVonController.text = formatYMD.format(selectedGueltigVon);
                      _wochenstundenController.text = "0";
                      _stundensatzController.text = "0";
                    },
                    child: const Text('Werte zurücksetzen'),
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      SetNewBetreuungReply resp = await globalGrpcClient.setNewBetreuung(Betreuung(
                        klientId: fn.Int64(childListId[selectedChild]),
                        betreuerId: fn.Int64(nutzer[nutzerIndex].$1),
                        gueltigVon: Datum(year: selectedGueltigVon.year, month: selectedGueltigVon.month, day: selectedGueltigVon.day),
                        gueltigBis: Datum(year: selectedGueltigBis.year, month: selectedGueltigBis.month, day: selectedGueltigBis.day),
                        wochenstunden: fn.Int64((num.parse(_wochenstundenController.text) * 60).round()),
                        stundensatz: fn.Int64((num.parse(_stundensatzController.text) * 100).round())
                        )
                      );
                      if(resp.errorCode.isEmpty){
                        _responseController.text = "Betreuung wurde erfolgreich angelegt";
                      }else{
                        _responseController.text = "Betreuung konnte nicht angelegt werden";
                      }
                      getBetreuungenFromServer();
                    },
                    child: const Text('Neu anlegen'),
                  ),
                ),
                const Spacer(flex: 8),
              ]
            ),
        ),
        const Spacer(flex: 2),
        Expanded(
          flex: 2,
          child: Center(child: TextField(controller: _responseController, enabled: false,)),
        ),
      ],
    ),
    );
  }

  
  // Blöde kleine Bildschirme...
  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView();
  }
}