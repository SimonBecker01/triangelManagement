import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standardAppBar,
      body: Center(
        child: Padding(padding: const EdgeInsets.all(30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children : [
              Column(
                children: [
                  Spacer(),
                  Spacer(),
                  Spacer()
                ]
              ),
              Column(
                children : [
                  Spacer(),
                  ElevatedButton(onPressed: (){
                      Navigator.of(context).pushReplacementNamed('/timetracker');
                    },
                    child: Text('Zeiterfassung')
                  ),
                  Spacer()
                ]
              ),
              Column(
                children: [
                  Spacer(),
                  SizedBox(
                    width : 30
                  ),
                  Spacer()
                ]
              ),
              Column(
                children : [
                  Spacer(),
                  ElevatedButton(onPressed: (){
                      Navigator.of(context).pushReplacementNamed('/documents');
                    },
                    child: Text('Klientenakte')
                  ),
                  Spacer()
                ]
              ),
              Column(
                children : [
                  DropdownMenu<String>(
                    dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
                      childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
                      enabled : childList.length > 1,
                      initialSelection: childList.first,
                  ),
                  Spacer(),
                  Spacer()
                ]
              )
            ],
          )
        )
      )
    );
  }
}
