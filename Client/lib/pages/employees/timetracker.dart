import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:interval_time_picker/models/visible_step.dart';
import 'package:management_triangel/global.dart';
import 'package:interval_time_picker/interval_time_picker.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:fixnum/fixnum.dart' as fn;

extension TimeOfDayExtension on TimeOfDay {
  // Ported from org.threeten.bp;
  TimeOfDay plusMinutes(int minutes) {
    if (minutes == 0) {
      return this;
    } else {
      int mofd = hour * 60 + minute;
      int newMofd = ((minutes % 1440) + mofd + 1440) % 1440;
      if (mofd == newMofd) {
        return this;
      } else {
        int newHour = newMofd ~/ 60;
        int newMinute = newMofd % 60;
        return TimeOfDay(hour: newHour, minute: newMinute);
      }
    }
  }
}

class TimetrackerScreen extends StatefulWidget {
  const TimetrackerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _TimeTrackerState();
}

class _TimeTrackerState extends State<TimetrackerScreen>{


  @override
  void initState() {
    super.initState();

    dropDownChildren = DropdownMenu<String>(
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
        enabled : childList.length > 1,
        initialSelection: childList.first,
        onSelected: (value) {
          if(value != null){
            selectedChild = childListId.elementAt(childList.indexOf(value));
          }
        },
    );

    dropDownActivity = DropdownMenu<String>(
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
        activityList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
        enabled : activityList.length > 1,
        initialSelection: activityList.first,
        onSelected: (value) {
          if(value != null){
            selectedActivity = activityListId.elementAt(activityList.indexOf(value));
          }
        },
    );

  }
  
  DropdownMenu<String> dropDownChildren = DropdownMenu<String>(dropdownMenuEntries: [],);
  DropdownMenu<String> dropDownActivity = DropdownMenu<String>(dropdownMenuEntries: [],);

  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay startTime = TimeOfDay(hour:TimeOfDay.now().hour, minute: TimeOfDay.now().minute - (TimeOfDay.now().minute % 5));
  TimeOfDay endTime = TimeOfDay(hour:TimeOfDay.now().plusMinutes(30).hour, minute: TimeOfDay.now().plusMinutes(30).minute - (TimeOfDay.now().minute % 5));

  DateTime currSelDate = DateTime.now();
  int currSelActivity = 0;



  void _changedDate() async{
    final zeiteintraegeResult = await globalGrpcClient.getZeiteintraege(Datum(year: currSelDate.year, month: currSelDate.month, day: currSelDate.day));

    activityOnDayList.clear();

    for (int i = 0; i < zeiteintraegeResult.zeiteintraege.length; i++){
      TimeOfDay vonToD = TimeOfDay(hour: zeiteintraegeResult.zeiteintraege.elementAt(i).anfang.hour, minute: zeiteintraegeResult.zeiteintraege.elementAt(i).anfang.minute);
      TimeOfDay bisToD = TimeOfDay(hour: zeiteintraegeResult.zeiteintraege.elementAt(i).ende.hour, minute: zeiteintraegeResult.zeiteintraege.elementAt(i).ende.minute);
      activityOnDayList.add((vonToD, bisToD, zeiteintraegeResult.zeiteintraege.elementAt(i).taetigkeitid.toInt(), zeiteintraegeResult.zeiteintraege.elementAt(i).klientid.toInt(), zeiteintraegeResult.zeiteintraege.elementAt(i).beschreibung, zeiteintraegeResult.zeiteintraege.elementAt(i).eintragid.toInt()));
    }
    setState((){

    });
  }

  void _changedactivity(int changedIndex){

    startTime = activityOnDayList[changedIndex].$1;
    endTime = activityOnDayList[changedIndex].$2;
    selectedActivity = activityOnDayList[changedIndex].$3;
    selectedChild = activityOnDayList[changedIndex].$4;
    _descriptionController.text = activityOnDayList[changedIndex].$5;
    currSelActivity = activityOnDayList[changedIndex].$6;


    setState(() {
      
      dropDownActivity = DropdownMenu<String>(
        dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          activityList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
          enabled : activityList.length > 1,
          initialSelection: activityList.elementAt(activityListId.indexOf(activityOnDayList[changedIndex].$3)),
          onSelected: (value) {
            if(value != null){
              selectedActivity = activityListId.elementAt(activityList.indexOf(value));
            }
          },
      );

      dropDownChildren = DropdownMenu<String>(
        dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
            childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name, enabled: false))),
          enabled : childList.length > 1,
          initialSelection: childList.elementAt(childListId.indexOf(activityOnDayList[changedIndex].$4)),
          onSelected: (value) {
            if(value != null){
              selectedChild = childListId.elementAt(childList.indexOf(value));
            }
          },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _startTimeController.text = startTime.format(context);
    _endTimeController.text = endTime.format(context);


    int selectedIndex = 0;

    return Scaffold(
      appBar: standardAppBar,
      body: Center(
        child : Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children : [
            Expanded(
              flex : 1,
              child : Row(
                children : [
                  Spacer(
                    flex : 9
                  ),
                  Expanded(
                    flex : 2,
                    child: dropDownChildren,
                  )
                ]
              ),
            ),
            Expanded(
              flex : 7,
              child : Row(
                children : [
                  Spacer(
                    flex: 3
                  ),
                  Expanded(
                    flex: 3,
                    child : Column(
                      children: [
                        Spacer(
                          flex : 2
                        ),
                        Expanded(
                          flex : 3,
                          child : dropDownActivity
                        ),
                        Expanded(
                          flex: 8,
                          child : TextField(
                            controller: _descriptionController,
                            maxLines : null,
                            expands : true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Beschreibung',
                            ),
                          )
                        )
                      ]
                    )
                  ),
                  Expanded(
                    flex: 3,
                    child : Column(
                      children: [
                        Expanded(
                          flex : 2,
                          child : CalendarDatePicker(
                            initialDate: currSelDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(3000),
                            onDateChanged: (DateTime value) { 
                              currSelDate = value;
                              _changedDate();
                            },
                          ),
                        ),
                        Expanded(
                          flex : 4,
                          child : Row(
                            children: [
                              Expanded(
                                flex : 1,
                                child: Padding(padding: EdgeInsetsGeometry.all(16),
                                  child : Column(
                                    children : [
                                      Expanded(
                                        flex: 1,
                                        child : FilledButton(onPressed: () async {
                                            TimeOfDay? selectedTime = await(showIntervalTimePicker(context: context,
                                                initialTime: startTime,
                                                interval: 5,
                                                visibleStep: VisibleStep.fifths
                                              )
                                            );
                                            if(selectedTime != null && selectedTime.toString().length > 1){
                                              setState(() {
                                                startTime = selectedTime;
                                              });
                                            }
                                          },
                                          child: TextField(controller: _startTimeController, enabled: false, textAlign: TextAlign.center, textAlignVertical: TextAlignVertical.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),)
                                        ),
                                      ),
                                      Expanded(
                                        flex : 1,
                                        child : Text("Tätigkeitsbeginn")
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child : FilledButton(onPressed: () async {
                                                TimeOfDay? selectedTime = await(showIntervalTimePicker(context: context,
                                                initialTime: endTime,
                                                interval: 5,
                                                visibleStep: VisibleStep.fifths
                                              )
                                            );
                                            if(selectedTime != null && selectedTime.toString().length > 1){
                                              setState(() {
                                                if(selectedTime.compareTo(startTime) > 0){
                                                  endTime = selectedTime;
                                                }
                                                else{
                                                  endTime = startTime.plusMinutes(5);
                                                }
                                              });
                                            }
                                          },
                                          child: TextField(controller: _endTimeController, enabled: false, textAlign: TextAlign.center, textAlignVertical: TextAlignVertical.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)
                                        ),
                                      ),
                                      Expanded(
                                        flex : 1,
                                        child : Text("Tätigkeitsende")
                                      ),
                                      Spacer(flex: 8,)
                                    ]
                                  )
                                )
                              ),
                              Expanded(
                                flex : 1,
                                child: Padding(padding: EdgeInsetsGeometry.all(16),
                                  child: ListView.builder(
                                    itemCount: activityOnDayList.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title : Text("${activityOnDayList[index].$1.format(context)}-${activityOnDayList[index].$2.format(context)} - ${activityList.elementAt(activityListId.indexOf(activityOnDayList[index].$3))}"),
                                        tileColor: selectedIndex == index ? Colors.blue :  Colors.white,
                                        onTap: () {
                                            selectedIndex = index;
                                            _changedactivity(index);
                                        }
                                      );
                                    }
                                  ),
                                )
                              )
                            ],
                          )
                        )
                      ]
                    )
                  )
                ]
              )
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Spacer(
                    flex: 7
                  ),
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      onPressed: () async{
                        try{
                          await globalGrpcClient.saveZeiteintrag(Zeiteintrag(dayofentry: Datum(year: currSelDate.year, month: currSelDate.month, day: currSelDate.day)
                            , anfang: Uhrzeit(hour: startTime.hour, minute: startTime.minute)
                            , ende: Uhrzeit(hour: endTime.hour, minute: endTime.minute)
                            , taetigkeitid: fn.Int64(selectedActivity)
                            , klientid: fn.Int64(selectedChild)
                            , beschreibung: _descriptionController.text
                            , eintragid: fn.Int64(currSelActivity)), 2);
                        }catch(error){
                          GrpcError grpce = error as GrpcError;
                          if (grpce.code == 6 && context.mounted){
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Überschneidung'),
                                content: const Text('Überschneidung mit bestehendem Eintrag!'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }else{
                            if (context.mounted){
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Serverfehler'),
                                  content: const Text('Fehler auf Serverseite.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }
                        setState(
                          () {
                            _changedDate();
                          }
                        );
                      },
                      child: Text('Ändern')),
                  ),
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      onPressed: () async{
                        try{
                          await globalGrpcClient.saveZeiteintrag(Zeiteintrag(dayofentry: Datum(year: currSelDate.year, month: currSelDate.month, day: currSelDate.day)
                            , anfang: Uhrzeit(hour: startTime.hour, minute: startTime.minute)
                            , ende: Uhrzeit(hour: endTime.hour, minute: endTime.minute)
                            , taetigkeitid: fn.Int64(selectedActivity)
                            , klientid: fn.Int64(selectedChild)
                            , eintragid: fn.Int64(currSelActivity)), 3);
                        }catch(error){
                          if (context.mounted){
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Serverfehler'),
                                content: const Text('Fehler auf Serverseite.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                        setState(
                          () {
                            _changedDate();
                          }
                        );
                      },
                      child: Text('Löschen')),
                  ),
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      onPressed: () async{
                        try{
                          await globalGrpcClient.saveZeiteintrag(Zeiteintrag(dayofentry: Datum(year: currSelDate.year, month: currSelDate.month, day: currSelDate.day)
                            , anfang: Uhrzeit(hour: startTime.hour, minute: startTime.minute)
                            , ende: Uhrzeit(hour: endTime.hour, minute: endTime.minute)
                            , taetigkeitid: fn.Int64(selectedActivity)
                            , klientid: fn.Int64(selectedChild)
                            , beschreibung: _descriptionController.text), 1);
                        }catch(error){
                          GrpcError grpce = error as GrpcError;
                          if (grpce.code == 6 && context.mounted){
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Überschneidung'),
                                content: const Text('Überschneidung mit bestehendem Eintrag!'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }else{
                            if (context.mounted){
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Serverfehler'),
                                  content: const Text('Fehler auf Serverseite.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }
                        setState(
                          () {
                            _changedDate();
                          }
                        );
                      },
                      child: Text('Neu Anlegen')),
                  )
                ]
              ),
            )
          ],
        )
      )
    );
  }

}

//activityDropDown