
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/global.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});


  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  final _responseController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    standardAppBar = AppBar(
      title: Image.asset('Assets/Logo.png'),
      backgroundColor: darkBG,
      iconTheme: IconThemeData(
        color: Colors.black, //change your color here
      ),
      centerTitle: true,
      actions: [
        InkWell(
          onTap: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
          },
          child: Icon(
            Icons.logout,
            color: Colors.black54,
          ),
        ),
      ]
    );

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
                  child : FilledButton(onPressed: () async{
                      try{
                        final loginResult = await globalGrpcClient.login(_nameController.text, _passController.text);

                        if (loginResult.errorCode.isEmpty){

                          loginName = _nameController.text;

                          globalGrpcClient.setAuthToken(loginResult.accessToken);

                          darkBG = Color.fromRGBO(loginResult.darkbg.r, loginResult.darkbg.g, loginResult.darkbg.b, 1);
                          lightBG = Color.fromRGBO(loginResult.lightbg.r, loginResult.lightbg.g, loginResult.lightbg.b, 1);
                          
                          
                          childList.clear();
                          childListId.clear();

                          for (int i = 0; i < loginResult.klienten.length; i++){
                            childList.add(loginResult.klienten.elementAt(i).fname + loginResult.klienten.elementAt(i).nname);
                            childListId.add(loginResult.klienten.elementAt(i).id.toInt());
                          }

                          if(childList.isNotEmpty){
                            selectedChild = childListId.first;
                          }

                          final docConfigResult = await globalGrpcClient.getDocumentConfig();
                          
                          documentGroupList.clear();
                          documentGroupListId.clear();

                          for (int i = 0; i < docConfigResult.gruppen.length; i++){
                            documentGroupList.add(docConfigResult.gruppen.elementAt(i).bezeichnung);
                            documentGroupListId.add(docConfigResult.gruppen.elementAt(i).id.toInt());
                          }

                          documentCategoryList.clear();
                          documentCategoryListId.clear();

                          for (int i = 0; i < docConfigResult.kategorien.length; i++){
                            documentCategoryList.add(docConfigResult.kategorien.elementAt(i).bezeichnung);
                            documentCategoryListId.add(docConfigResult.kategorien.elementAt(i).id.toInt());
                          }

                          final taetigkeitenResult = await globalGrpcClient.getTaetigkeiten();

                          activityList.clear();
                          activityListId.clear();

                          for (int i = 0; i < taetigkeitenResult.taetigkeiten.length; i++){
                            activityList.add(taetigkeitenResult.taetigkeiten.elementAt(i).bezeichnung);
                            activityListId.add(taetigkeitenResult.taetigkeiten.elementAt(i).id.toInt());
                          }
                          
                          if(activityList.isNotEmpty){
                            selectedActivity = activityListId.first;
                          }

                          if(context.mounted){
                            Navigator.of(context).pushNamed('/menu');
                          }
                        }else{
                          _responseController.text = loginResult.errorCode;
                        }
                      }catch (error) {
                        if (error is GrpcError &&
                            error.code == StatusCode.permissionDenied) {
                          _responseController.text = error.codeName;
                        }
                      _passController.text = '';
                      }
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
