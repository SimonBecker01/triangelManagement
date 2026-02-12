import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';

class TimetrackerScreen extends StatelessWidget {
  const TimetrackerScreen({super.key});

  
  @override
  Widget build(BuildContext context) {
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
                    flex : 1,
                    child: dropDownChildren,
                  )
                ]
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children : [
                  Spacer(
                    flex : 3
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
                  Spacer(
                    flex : 1
                  ),
                  Expanded(
                    flex : 2,
                    child : CalendarDatePicker(initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(3000), onDateChanged: (DateTime value) {  },
                    ),
                  ),
                ]
              )
            ),
            Expanded(
              flex : 3,
              child : Row(
                  children : [
                    Spacer(
                      flex : 3
                    ),
                    Expanded(
                      flex : 2,
                      child : CalendarDatePicker(initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(3000), onDateChanged: (DateTime value) {  },
                      ),
                    ),
                    Spacer(
                      flex : 1
                    ),
                    Expanded(
                      flex : 2,
                      child : ElevatedButton(onPressed: (){
                          Navigator.of(context).pushReplacementNamed('/documents');
                        },
                        child: Text('Klientenakte')
                      ),
                    ),
                    Spacer(
                      flex : 3
                    ),
                  ]
                )
            ),
            Spacer(
              flex: 4
            )
          ],
        )
      )
    );
  }
}