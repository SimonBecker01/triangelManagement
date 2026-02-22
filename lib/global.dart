import 'package:flutter/material.dart';

const Color darkBG = Color.fromRGBO(88, 140, 52, 1);
const Color lightBG = Color.fromRGBO(122, 201, 67, 1);

AppBar standardAppBar = AppBar(title: Image.asset('Assets/Logo.png'), backgroundColor: darkBG,);

int userLoggedIn = 0;
int selectedChild = 0;
int selectedActivity = 0;
int selectedDocumentGroup = 0;

List<String> childList = <String>[''];
List<String> activityList = <String>[''];
List<String> documentGroupList = <String>[''];
List<String> documentCategoryList = <String>[''];
List<(int, String, int, int)> documentList = <(int, String, int, int)>[(0, '', 0, 0)];


List<String> selectedCategories = [];

List<(TimeOfDay, TimeOfDay, int, int, String)> activityOnDayList = <(TimeOfDay, TimeOfDay, int, int, String)>[(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 0), 0, 0, 'Initialwert wird von der DB dann direkt befüllt.')];


