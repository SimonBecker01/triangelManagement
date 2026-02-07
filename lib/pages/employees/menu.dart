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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children : [
              Expanded(
                flex : 1,
                child : Row(
                  children : [
                    Expanded(
                      flex : 9,
                      child : Spacer()
                    ),
                    Expanded(
                      flex : 1,
                      child: DropdownMenu<String>(
                        dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
                          childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
                          enabled : childList.length > 1,
                          initialSelection: childList.first,
                      ),
                    )
                  ]
                ),
              ),
              Expanded(
                flex: 2,
                child: Spacer()
              ),
              Expanded(
                flex : 3,
                child : Row(
                    children : [
                      Expanded(
                        flex : 3,
                        child : Spacer()
                      ),
                      Expanded(
                        flex : 2,
                        child : ElevatedButton(onPressed: (){
                            Navigator.of(context).pushReplacementNamed('/timetracker');
                          },
                          child: Text('Zeiterfassung')
                        ),
                      ),
                      Expanded(
                        flex : 1,
                        child : Spacer()
                      ),
                      Expanded(
                        flex : 2,
                        child : ElevatedButton(onPressed: (){
                            Navigator.of(context).pushReplacementNamed('/documents');
                          },
                          child: Text('Klientenakte')
                        ),
                      ),
                      Expanded(
                        flex : 3,
                        child : Spacer()
                      ),
                    ]
                  )
              ),
              Expanded(
                flex: 4,
                child: Spacer()
              )
            ],
          )
        )
      )
    );
  }
}
