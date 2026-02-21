import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';

class NewDocumentScreen extends StatelessWidget {
  const NewDocumentScreen({super.key});

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standardAppBar,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            ElevatedButton(onPressed: (){
                Navigator.of(context).pushReplacementNamed('/timetracker');
              },
              child: Text('Zeiterfassung')
            ),
            Spacer(),
            ElevatedButton(onPressed: (){
                Navigator.of(context).pushReplacementNamed('/documents');
              },
              child: Text('Klientenakte')
            ),
            Spacer()
          ],
        )
      )
    );
  }
}
