import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:interval_time_picker/models/visible_step.dart';
import 'package:management_triangel/global.dart';
import 'package:interval_time_picker/interval_time_picker.dart';



class TimetrackerScreen extends StatelessWidget {
  TimetrackerScreen({super.key});

  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _descriptionController = TextEditingController();


  void _changedDate(DateTime value){
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
  }

  void _changedactivity(int changedIndex){
    _descriptionController.text = "blub";
  }

  @override
  Widget build(BuildContext context) {
    _startTimeController.text = TimeOfDay.now().hour.toString() + ":" + (TimeOfDay.now().minute - (TimeOfDay.now().minute % 5)).toString().padLeft(2, '0');
    _endTimeController.text = TimeOfDay.now().hour.toString() + ":" + (TimeOfDay.now().minute - (TimeOfDay.now().minute % 5) + 30).toString().padLeft(2, '0');


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
                          child : DropdownMenu<String>(
                              dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
                                activityList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
                                enabled : activityList.length > 1,
                                initialSelection: activityList.first,
                            )
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
                                child : Column(
                                  children : [
                                    Expanded(
                                      flex: 1,
                                      child : FilledButton(onPressed: () async {
                                          TimeOfDay? selectedTime = await(showIntervalTimePicker(context: context,
                                              initialTime: TimeOfDay(hour: TimeOfDay.now().hour, minute: TimeOfDay.now().minute - (TimeOfDay.now().minute % 5)),
                                              interval: 5,
                                              visibleStep: VisibleStep.fifths
                                            )
                                          );
                                          if(selectedTime != null && selectedTime.toString().length > 1){
                                            _startTimeController.text = selectedTime.hour.toString() + ":" + selectedTime.minute.toString().padLeft(2, '0');
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
                                              TimeOfDay? selectedTime = await(showIntervalTimePicker(context: context, initialTime: TimeOfDay(hour: TimeOfDay.now().hour, minute: TimeOfDay.now().minute - (TimeOfDay.now().minute % 5) + 30),
                                              interval: 5,
                                              visibleStep: VisibleStep.fifths
                                            )
                                          );
                                          if(selectedTime != null && selectedTime.toString().length > 1){
                                            _endTimeController.text = selectedTime.hour.toString() + ":" + selectedTime.minute.toString().padLeft(2, '0');
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
                              ),
                              Expanded(
                                flex : 1,
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
                            ],
                          )
                        )
                      ]
                    )
                  )
                ]
              )
            ),
            Spacer(
              flex: 2
            )
          ],
        )
      )
    );
  }
}