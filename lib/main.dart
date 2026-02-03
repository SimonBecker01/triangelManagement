import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:management_triangel/pages/employees/documents.dart';
import 'package:management_triangel/pages/employees/login.dart';
import 'package:management_triangel/pages/employees/menu.dart';
import 'package:management_triangel/pages/employees/timetracker.dart';


void main() {
  runApp(const TriangelManagementMain());
}


class TriangelManagementMain extends StatelessWidget {
  const TriangelManagementMain({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triangel',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: lightBG),
      ),
      initialRoute: '/login',
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => LoginScreen(),
        '/menu': (BuildContext context) => const MenuScreen(),
        '/timetracker': (BuildContext context) => const TimetrackerScreen(),
        '/documents': (BuildContext context) => const DocumentsScreen()
      }
    );
  }
}

