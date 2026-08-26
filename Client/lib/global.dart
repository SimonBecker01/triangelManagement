import 'package:flutter/material.dart';
import 'package:management_triangel/services/grpc_client.dart' as grpcp;

Color darkBG = Color.fromRGBO(88, 140, 52, 1);
Color lightBG = Color.fromRGBO(122, 201, 67, 1);

//Weil es auf Telefonen sonst kaum nutzbar ist...
const double wideLayoutBreakpoint = 600;
bool useWideLayout(BoxConstraints constraints) =>
    constraints.maxWidth >= wideLayoutBreakpoint && constraints.maxHeight >= 450;

AppBar standardAppBar({List<Widget> actions = const []}) {
  return AppBar(
    title: Image.asset('Assets/Logo.png'),
    backgroundColor: darkBG,
    iconTheme: const IconThemeData(color: Colors.black),
    centerTitle: true,
    actions: actions,
  );
}

Widget logoutAction(BuildContext context) {
  return IconButton(
    onPressed: () {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    },
    icon: const Icon(Icons.logout, color: Colors.black54),
    tooltip: 'Abmelden',
  );
}

int selectedChild = 0;
int selectedActivity = 0;
int selectedDocumentGroup = 0;

String loginName = '';

List<String> childList = <String>[];
List<int> childListId = <int>[];
List<String> activityList = <String>[''];
List<int> activityListId = <int>[];
List<String> documentGroupList = <String>[''];
List<int> documentGroupListId = <int>[];
List<String> documentCategoryList = <String>[''];
List<int> documentCategoryListId = <int>[];
List<(int, String, int, List<int>, String)> documentList = <(int, String, int, List<int>, String)>[];

final globalGrpcClient = grpcp.GrpcClient.instance;

List<int> selectedCategories = [];

List<(TimeOfDay, TimeOfDay, int, int, String, int)> activityOnDayList = <(TimeOfDay, TimeOfDay, int, int, String, int)>[];


