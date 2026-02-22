import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:file_picker/file_picker.dart';

class NewDocumentScreen extends StatefulWidget {
  const NewDocumentScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NewDocumentState();
}

class _NewDocumentState extends State<NewDocumentScreen>{

  
  final _fileUploadNameController = TextEditingController();
  final _fileNameController = TextEditingController();

  final DropdownMenu dropDownChildren = DropdownMenu<String>(
    dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
        childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
      enabled : childList.length > 1,
      initialSelection: childList.first,
      onSelected: (value) {
        if(value != null){
          selectedChild = childList.indexOf(value);
        }
      }
  );

  final DropdownMenu dropDownDocumnentGroup = DropdownMenu<String>(
    dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
        documentGroupList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
      enabled : documentGroupList.length > 1,
      initialSelection: documentGroupList.first,
      onSelected: (value) {
        if(value != null){
          selectedDocumentGroup = documentGroupList.indexOf(value);
        }
      },
  );
  
  
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
            Expanded(
              flex : 7,
              child : Row(
                children : [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('Kategorien', textAlign: TextAlign.center,)
                        ),
                        Expanded(
                          flex : 11,
                          child: Padding(padding: EdgeInsetsGeometry.all(16),
                            child: ListView.builder(
                              itemCount: documentCategoryList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title : Text(documentCategoryList[index]),
                                  tileColor: selectedCategories.contains(documentCategoryList[index]) ? Colors.blue : Colors.white,
                                  onTap: () {
                                    setState((){
                                      if(selectedCategories.contains(documentCategoryList[index])){
                                        selectedCategories.removeAt(selectedCategories.indexOf(documentCategoryList[index]));
                                      }else{
                                        selectedCategories.add(documentCategoryList[index]);
                                      }
                                    });
                                  }
                                );
                              }
                            ),
                          )
                        )
                      ]
                    )
                  ),
                  Expanded(
                    flex: 3,
                    child : Column(
                      children: [
                        Expanded(
                          flex : 3,
                          child : dropDownDocumnentGroup
                        ),
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            onPressed: () async{
                              FilePickerResult? result = await FilePicker.platform.pickFiles();

                              if (result != null) {
                                _fileNameController.text = result.files.single.path!;
                              } else {
                                // User canceled the picker
                              }
                            },
                            child: Text('Datei auswählen'))
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _fileNameController, 
                            enabled: false,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            )
                          )
                        ),
                        Spacer(
                          flex: 3,
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _fileUploadNameController, 
                            enabled: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Hochladen als...'
                            )
                          ),
                        )
                      ]
                    )
                  ),
                  Spacer(
                    flex: 3
                  )
                ]
              )
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Spacer(
                    flex: 24
                  ),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/documents');
                      },
                      child: Text('Abbrechen')),
                  ),
                  Spacer(
                    flex: 1
                  ),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/documents');
                      },
                      child: Text('Anlegen')),
                  ),
                  Spacer(
                    flex: 1
                  ),
                ]
              ),
            )
          ],
        )
      )
    );
  }
}