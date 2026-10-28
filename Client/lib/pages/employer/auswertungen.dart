import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:management_triangel/global.dart';
import 'package:fixnum/fixnum.dart' as fn;
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class AuswertungenScreen extends StatefulWidget {
  const AuswertungenScreen({super.key});

  @override
  State<AuswertungenScreen> createState() => _AuswertungenState();
}

class _AuswertungenState extends State<AuswertungenScreen>{
  


  @override
  void initState() {
    super.initState();
    getUsersFromServer();
    getBetreuungenFromServer();
  }

  
  @override
  void dispose() {
    super.dispose();
  }


  List<(int, String, String)> nutzer = <(int, String, String)>[];
  List<(int, String, String, int)> betreuungen = <(int, String, String, int)>[];
  int nutzerIndex = 0;
  int betreuungenIndex = 0;
  DateTime selectedDate = DateTime.now();
  bool _abrechenbar = true;

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
    GetBetreuungenReply betreuungenRep = await globalGrpcClient.getBetreuungen(false);
    betreuungen.clear();
    for(int i = 0; i < betreuungenRep.betreuungen.length; i++){
      int uind = 0;
      for(uind;uind < nutzer.length; uind++){
        if(nutzer[uind].$1 == betreuungenRep.betreuungen[i].betreuerId.toInt()) break;
      }
      betreuungen.add((betreuungenRep.betreuungen[i].id.toInt(), "${nutzer[uind].$2} betreut ${childList[childListId.indexOf(betreuungenRep.betreuungen[i].klientId.toInt())]}${(betreuungenRep.betreuungen[i].gueltigVon.year > 1800)?(" von ${betreuungenRep.betreuungen[i].gueltigVon.year}-${betreuungenRep.betreuungen[i].gueltigVon.month}-${betreuungenRep.betreuungen[i].gueltigVon.day}"):""}${(betreuungenRep.betreuungen[i].gueltigBis.year < 2500)?(" bis ${betreuungenRep.betreuungen[i].gueltigBis.year}-${betreuungenRep.betreuungen[i].gueltigBis.month}-${betreuungenRep.betreuungen[i].gueltigBis.day}"):""}", nutzer[uind].$3, betreuungenRep.betreuungen[i].wochenstunden.toInt()));
    }
    setState(() {
      //Rebuilding the DropDowns with filled Lists
    });
  }

  Future<void> _buildAndSavePdf(AuswertungReply rep, String art, String name, [int? fls]) async {

    int summeMinuten = 0;
    final DateFormat formatSpelled = DateFormat('MMMM y');
    NumberFormat withLeadingZero = NumberFormat("00");
    List<List<String>> tablePrepared = [];
    for(int i = 0; i < rep.auswertung.length; i++){
      List<String> nextRow = [];
      nextRow.add("${withLeadingZero.format(rep.auswertung[i].dayofentry.day)}.${withLeadingZero.format(rep.auswertung[i].dayofentry.month)}.${withLeadingZero.format(rep.auswertung[i].dayofentry.year)}");
      nextRow.add(rep.auswertung[i].betreuer);
      nextRow.add(rep.auswertung[i].beschreibung);
      nextRow.add("${withLeadingZero.format(rep.auswertung[i].anfang.hour)}:${withLeadingZero.format(rep.auswertung[i].anfang.minute)}-${withLeadingZero.format(rep.auswertung[i].ende.hour)}:${withLeadingZero.format(rep.auswertung[i].ende.minute)}");
      int minuten = rep.auswertung[i].ende.hour * 60 + rep.auswertung[i].ende.minute - rep.auswertung[i].anfang.hour * 60 - rep.auswertung[i].anfang.minute;
      summeMinuten += minuten;
      nextRow.add((minuten / 60).toStringAsFixed(2));
      tablePrepared.add(nextRow);
    }
    tablePrepared.add(["", "", "", "Summe", (summeMinuten / 60).toStringAsFixed(2)]);
    final img = await DefaultAssetBundle.of(context).load('Assets/Logo.png');
    final imageBytes = img.buffer.asUint8List();
    pw.Image logo = pw.Image(pw.MemoryImage(imageBytes));
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      header: (context) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Column(children: [
          pw.Row(children: [pw.Spacer(flex:8), pw.Container(alignment: pw.Alignment.topRight, height: 50, child: logo)]),
          pw.Row(children: [pw.Text("Nachweis für Abrechnung ${formatSpelled.format(selectedDate)}", textScaleFactor: 2)]),
          pw.Row(children: [pw.Text(name, textScaleFactor: 1)]),
          (fls != null && fls > 0)?(pw.Row(children: [pw.Text("Leistungsumfang: max. ${(fls/60).toStringAsFixed(2)} FLS/Woche", textScaleFactor: 1)])):(pw.SizedBox(height: 1, width: 1))
        ])),
      
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Seite ${context.pageNumber} von ${context.pagesCount}'),
          ],
        ),
      ),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headers: ["Datum", "Teilnehmer*in/nen", "Tätigkeit", "Dauer", "Stunden"],
          data: tablePrepared,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(5),
            2: const pw.FlexColumnWidth(9),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          cellAlignments: {
            0: pw.Alignment.topCenter,
            1: pw.Alignment.topCenter,
            2: pw.Alignment.topCenter,
            3: pw.Alignment.topCenter,
            4: pw.Alignment.topRight,
          }
        )
      ],
    ));

    await FilePicker.platform.saveFile(
      dialogTitle: 'Bitte Speicherort auswählen:',
      fileName: "Auswertung_$art-${name}_${selectedDate.year}-${selectedDate.month}${(_abrechenbar)?"":"_intern"}.pdf",
      bytes: await pdf.save(),
    );
  }

  DropdownMenu<int> _buildUserDropdown() {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<int>>(
          nutzer.map<DropdownMenuEntry<int>>(
              ((int, String, String) singleUser) => DropdownMenuEntry<int>(
                  value: singleUser.$1, label: "${singleUser.$3}, ${singleUser.$2}"))),
      enabled: true,
      initialSelection: nutzer.isNotEmpty ? nutzer.first.$1 : null,
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
      initialSelection: childList.isNotEmpty ? childList.first : null,
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
              ((int, String, String, int) singleBetreuung) => DropdownMenuEntry<int>(
                  value: singleBetreuung.$1, label: "${singleBetreuung.$3}, ${singleBetreuung.$2}"))),
      enabled: true,
      initialSelection: betreuungen.isNotEmpty ? betreuungen.first.$1 : null,
      onSelected: (value) {
        if (value != null) {
          for(int i = 0; i < betreuungen.length; i++){
            if(betreuungen[i].$1 == value){
              betreuungenIndex = i;
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
                  flex: 5,
                  child: FloatingActionButton(
                    onPressed: () {
                      showMonthPicker(
                        context: context,
                        initialDate: DateTime.now(),
                        monthPickerDialogSettings: const MonthPickerDialogSettings(
                            headerSettings: PickerHeaderSettings(
                                headerCurrentPageTextStyle: TextStyle(fontSize: 14),
                                headerSelectedIntervalTextStyle: TextStyle(fontSize: 16),
                            ),
                            dialogSettings: PickerDialogSettings(
                                locale: const Locale('de'),
                                dialogRoundedCornersRadius: 20,
                            ),
                        ),
                        ).then((date) {
                        if (date != null) {
                            setState(() {
                              selectedDate = date;
                            });
                        }
                        });
                    },
                    child: Text("${selectedDate.year}-${selectedDate.month}"),
                  ),
                ),
                const Spacer(flex: 2),
                Text("Nur abrechenbar:"),
                Checkbox(value: _abrechenbar, onChanged: (bool? value) {setState(() { _abrechenbar = value!;});}),
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
                  child: _buildUserDropdown(),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      _buildAndSavePdf(await globalGrpcClient.auswertungBetreuer(fn.Int64(nutzer[nutzerIndex].$1), Datum(year: selectedDate.year, month: selectedDate.month, day: 1), _abrechenbar ), "Betreuer", nutzer[nutzerIndex].$2);
                    },
                    child: const Text('Auswertung Betreuer'),
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
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      _buildAndSavePdf(await globalGrpcClient.auswertungKlient(fn.Int64(selectedChild), Datum(year: selectedDate.year, month: selectedDate.month, day: 1), _abrechenbar ), "Klient", childList[childListId.indexOf(selectedChild)]);
                    },
                    child: const Text('Auswertung Klient'),
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
                  child: _buildBetreuungDropdown(),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      _buildAndSavePdf(await globalGrpcClient.auswertungBetreuung(fn.Int64(betreuungen[betreuungenIndex].$1), Datum(year: selectedDate.year, month: selectedDate.month, day: 1), _abrechenbar ), "Betreuung", betreuungen[betreuungenIndex].$2, betreuungen[betreuungenIndex].$4);
                    },
                    child: const Text('Auswertung Betreuung'),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
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