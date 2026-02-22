import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:file_picker/file_picker.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

    @override
  State<StatefulWidget> createState() => _DocumentsState();
}

class _DocumentsState extends State<DocumentsScreen>{

  @override
  void initState() {
    super.initState();

    selectedCategories.addAll(documentCategoryList);

    dropDownChildren = DropdownMenu<String>(
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
        enabled : childList.length > 1,
        initialSelection: childList.first,
        onSelected: (value) {
          if(value != null){
            selectedChild = childList.indexOf(value);
            updateDocumentList();
          }
        },
    );

    dropDownDocumnentGroup = DropdownMenu<String>(
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          documentGroupList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
        enabled : documentGroupList.length > 1,
        initialSelection: documentGroupList.first,
        onSelected: (value) {
          if(value != null){
            selectedDocumentGroup = documentGroupList.indexOf(value);
            updateDocumentList();
          }
        },
    );
    
    updateDocumentList();

  }
  
  List<(int, String, int, int)> selectedDocumentList = <(int, String, int, int)>[(0, '', 0, 0)];
  int selectedDocument = 0;

  DropdownMenu<String> dropDownChildren = DropdownMenu<String>(dropdownMenuEntries: [],);
  DropdownMenu<String> dropDownDocumnentGroup = DropdownMenu<String>(dropdownMenuEntries: [],);

  void updateDocumentList(){
    setState(() {
      selectedDocument = 0;
      selectedDocumentList = [];
      for(int i = 0; i < documentList.length; i++){
        if(documentList[i].$1 == selectedChild && documentList[i].$3 == selectedDocumentGroup && selectedCategories.contains(documentCategoryList[documentList[i].$4])){
          selectedDocumentList.add(documentList[i]);
        }
      }
    });
  }

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
                                      updateDocumentList();
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
                          flex: 8,
                          child: Padding(padding: EdgeInsetsGeometry.all(16),
                            child: ListView.builder(
                              itemCount: selectedDocumentList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title : Text(selectedDocumentList[index].$2),
                                  tileColor: selectedDocument == index ? Colors.blue : Colors.white,
                                  onTap: () {
                                    setState((){
                                      selectedDocument = index;
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
                    flex: 20
                  ),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: () async {
                        String? outputFile = await FilePicker.platform.saveFile(
                          dialogTitle: 'Please select an output file:',
                          fileName: 'output-file.pdf',
                        );

                        if (outputFile == null) {
                          // User canceled the picker
                        }
                      },
                      child: Text('Herunterladen')),
                  ),
                  Spacer(
                    flex: 1
                  ),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: () {
                        
                      },
                      child: Text('Löschen')),
                  ),
                  Spacer(
                    flex: 1
                  ),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/newdocument');
                      },
                      child: Text('Neu')),
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