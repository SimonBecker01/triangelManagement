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
          child : FractionallySizedBox(
            widthFactor: 0.5,
            child: GridView.count(
              crossAxisCount: 4,
              children: [
                Spacer(),
                Spacer(),
                Spacer(),
                DropdownMenu<String>(
                  dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
                    childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name)))
                ),
                Spacer(),
                ElevatedButton(onPressed: (){
                    Navigator.of(context).pushReplacementNamed('/timetracker');
                  },
                  child: Text('Zeiterfassung')
                ),
                ElevatedButton(onPressed: (){
                    Navigator.of(context).pushReplacementNamed('/documents');
                  },
                  child: Text('Klientenakte')
                ),
                Spacer()
              ],
            )
          )
        )
      )
    );
  }
}
