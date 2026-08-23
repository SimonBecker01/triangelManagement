import 'package:flutter/material.dart';
import 'package:management_triangel/services/grpc_client.dart' as grpcp;

Color darkBG = Color.fromRGBO(88, 140, 52, 1);
Color lightBG = Color.fromRGBO(122, 201, 67, 1);

AppBar standardAppBar = AppBar(
  title: Image.asset('Assets/Logo.png'),
  backgroundColor: darkBG,
  iconTheme: IconThemeData(
    color: Colors.black, //change your color here
  ),
  centerTitle: true,
);

int selectedChild = 0;
int selectedActivity = 0;
int selectedDocumentGroup = 0;

List<String> childList = <String>[];
List<int> childListId = <int>[];
List<String> activityList = <String>[''];
List<int> activityListId = <int>[];
List<String> documentGroupList = <String>[''];
List<int> documentGroupListId = <int>[];
List<String> documentCategoryList = <String>[''];
List<int> documentCategoryListId = <int>[];
List<(int, String, int, int)> documentList = <(int, String, int, int)>[(0, '', 0, 0)];

final globalGrpcClient = grpcp.GrpcClient.instance;

List<String> selectedCategories = [];

List<(TimeOfDay, TimeOfDay, int, int, String, int)> activityOnDayList = <(TimeOfDay, TimeOfDay, int, int, String, int)>[];


