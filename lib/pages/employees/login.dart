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
        child: Padding(padding: const EdgeInsets.all(30.0),
          child : FractionallySizedBox(
            widthFactor: 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Benutzername')
                ),
                Spacer(),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Password')
                ),
                Spacer(),
                ElevatedButton(onPressed: (){
                  //Pseudologin
                  _responseController.text = '';
                  if(_nameController.text == 'Mitarbeiter' && _passController.text == 'Mitarbeiter1'){
                    userLoggedIn = 1;
                    childList = ['Kind1'];
                    Navigator.of(context).pushReplacementNamed('/menu');
                  }
                  else{
                    if(_nameController.text == 'Koordinator' && _passController.text == 'Koordinator1'){
                      userLoggedIn = 2;
                    childList = ['Kind1', 'Kind2'];
                      Navigator.of(context).pushReplacementNamed('/menu');
                    }
                    else{
                      _responseController.text = 'Benutzername und Passwort sind nicht korrekt!';
                    }
                  }
                },
                child: Text('Login')),
                TextField(
                  controller: _responseController
                ),
              ]
            )
          )
        )
      )
    );
  }


}
