import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:interval_time_picker/models/visible_step.dart';
import 'package:management_triangel/global.dart';
import 'package:interval_time_picker/interval_time_picker.dart';

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


  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay startTime = TimeOfDay(hour:TimeOfDay.now().hour, minute: TimeOfDay.now().minute - (TimeOfDay.now().minute % 5));
  TimeOfDay endTime = TimeOfDay(hour:TimeOfDay.now().plusMinutes(30).hour, minute: TimeOfDay.now().plusMinutes(30).minute - (TimeOfDay.now().minute % 5));


  void _changedDate(DateTime value){
    setState(() {
      switch (value.day % 3) {
        case 0:
          activityOnDayList = [];
          break;
        case 1:
          activityOnDayList = [(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 0), 0, 0, 'Was getan')];
          break;
        case 2:
          activityOnDayList = [(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 0), 0, 0, 'Was getan'),(TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 12, minute: 30), 1, 0, 'Noch was getan')];
          break;
        default:
      }
    });
  }

  void _changedactivity(int changedIndex){

    startTime = activityOnDayList[changedIndex].$1;
    endTime = activityOnDayList[changedIndex].$2;
    selectedActivity = activityOnDayList[changedIndex].$3;
    selectedChild = activityOnDayList[changedIndex].$4;
    _descriptionController.text = activityOnDayList[changedIndex].$5;


    setState(() {
      
      dropDownActivity = DropdownMenu<String>(
        dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          activityList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
          enabled : activityList.length > 1,
          initialSelection: activityList[activityOnDayList[changedIndex].$3],
          onSelected: (value) {
            if(value != null){
              selectedActivity = activityList.indexOf(value);
            }
          },
      );

      dropDownChildren = DropdownMenu<String>(
        dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
            childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name, enabled: false))),
          enabled : childList.length > 1,
          initialSelection: childList[activityOnDayList[changedIndex].$4],
          onSelected: (value) {
            if(value != null){
              selectedChild = childList.indexOf(value);
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
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(3000),
                            onDateChanged: (DateTime value) { 
                              _changedDate(value);
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
                                              startTime = selectedTime;
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
                                                endTime = selectedTime;
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
                                  child : Container(
                                    decoration: BoxDecoration(color : Colors.white),
                                    child: ListView.builder(
                                      itemCount: activityOnDayList.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title : Text(activityOnDayList[index].$1.format(context) + "-" + activityOnDayList[index].$2.format(context) + " - " + activityList[activityOnDayList[index].$3]),
                                          tileColor: selectedIndex == index ? Colors.blue : null,
                                          onTap: () {
                                              selectedIndex = index;
                                              _changedactivity(index);
                                          }
                                        );
                                      }
                                    ),
                                  )
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
                    flex: 8
                  ),
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      onPressed: () {
                        if(activityOnDayList.length >= selectedIndex){
                          setState(
                            (){
                                activityOnDayList.removeAt(selectedIndex);
                              }
                          );
                        }
                      },
                      child: Text('Löschen')),
                  ),
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      onPressed: () {
                        setState(
                          (){
                            activityOnDayList.add((startTime, endTime, selectedActivity, selectedChild, _descriptionController.text));
                          }
                        );
                      },
                      child: Text('Speichern')),
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