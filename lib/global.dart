import 'package:flutter/material.dart';
import 'dart:collection';

const Color darkBG = Color.fromRGBO(88, 140, 52, 1);
const Color lightBG = Color.fromRGBO(122, 201, 67, 1);

AppBar standardAppBar = AppBar(title: Image.asset('Assets/Logo.png'), backgroundColor: darkBG,);

int userLoggedIn = 0;
int selectedChild = 0;
int selectedActivity = 0;

List<String> childList = <String>[''];
List<String> activityList = <String>[''];

List<(TimeOfDay, TimeOfDay, int, int, String)> activityOnDayList = <(TimeOfDay, TimeOfDay, int, int, String)>[(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 0), 0, 0, 'Initialwert wird von der DB dann direkt befüllt.')];


DropdownMenu<String> dropDownChildren = DropdownMenu<String>(
  dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
      childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name, enabled: false))),
    enabled : childList.length > 1,
    initialSelection: childList.first,
    onSelected: (value) {
      if(value != null){
        selectedChild = childList.indexOf(value);
      }
    },
);

DropdownMenu<String> dropDownActivity = DropdownMenu<String>(
  dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
    activityList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
    enabled : activityList.length > 1,
    initialSelection: activityList.first,
    onSelected: (value) {
      if(value != null){
        selectedActivity = activityList.indexOf(value);
      }
    },
);