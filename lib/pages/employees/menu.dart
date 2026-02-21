import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  
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
                    flex : 2,
                    child: dropDownChildren,
                  )
                ]
              ),
            ),
            Spacer(
              flex: 2
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
                      child : FilledButton(onPressed: (){
                          Navigator.of(context).pushReplacementNamed('/timetracker');
                        },
                        child: Text('Zeiterfassung')
                      ),
                    ),
                    Spacer(
                      flex : 1
                    ),
                    Expanded(
                      flex : 2,
                      child : FilledButton(onPressed: (){
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
