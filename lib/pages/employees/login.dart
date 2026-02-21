import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});


  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  final _responseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standardAppBar,
      body: Center(
        child : Row(
          children : [
            Spacer(flex : 1),
            Expanded(flex : 1, child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(
                  flex : 3
                ),
                Expanded(
                  flex : 2,
                  child : TextField(
                    controller: _nameController,
                    decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Benutzername')
                  )
                ),
                Spacer(
                  flex : 2
                ),
                Expanded(
                  flex : 2,
                  child : TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Password')
                  )
                ),
                Spacer(
                  flex : 3
                ),
                Expanded(
                  flex : 2,
                  child : FilledButton(onPressed: (){
                      //Pseudologin
                      _responseController.text = '';
                      if(_nameController.text == 'Mitarbeiter' && _passController.text == 'Mitarbeiter1'){
                        userLoggedIn = 1;
                        childList = ['Kind1'];
                        activityList = ['Dokumentation', 'Betreuung'];
                        Navigator.of(context).pushReplacementNamed('/menu');
                      }
                      else{
                        if(_nameController.text == 'Koordinator' && _passController.text == 'Koordinator1'){
                          userLoggedIn = 2;
                          childList = ['Kind1', 'Kind2'];
                          activityList = ['Dokumentation', 'Beratung', 'Verwaltung'];
                          Navigator.of(context).pushReplacementNamed('/menu');
                        }
                        else{
                          _responseController.text = 'Benutzername und Passwort sind nicht korrekt!';
                        }
                      }
                      dropDownChildren = DropdownMenu<String>(
                            dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
                              childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
                              enabled : childList.length > 1,
                              initialSelection: childList.first,
                          );
                    },
                    child: Text('Login')
                  )
                ),
                Spacer(
                  flex : 3
                ),
                Expanded(
                  flex : 2,
                  child : TextField(
                    controller: _responseController
                  ),
                ),
              ]
            )
          ),
            Spacer(flex : 1),
          ]
        )
      )
    );
  }


}
