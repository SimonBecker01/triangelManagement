import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:file_picker/file_picker.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:fixnum/fixnum.dart' as fn;
import 'dart:typed_data';
import 'dart:io';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

    @override
  State<StatefulWidget> createState() => _DocumentsState();
}

class _DocumentsState extends State<DocumentsScreen>{

  @override
  void initState() {
    super.initState();

    selectedCategories.addAll(documentCategoryListId);
    selectedDocumentGroup = documentGroupListId.first;

    dropDownChildren = DropdownMenu<String>(
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          childList.map<DropdownMenuEntry<String>>((String name) => DropdownMenuEntry<String>(value: name, label: name))),
        enabled : childList.length > 1,
        initialSelection: childList.first,
        onSelected: (value) {
          if(value != null){
            selectedChild = childListId.elementAt(childList.indexOf(value));
            getDocumentsFromServer();
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
            selectedDocumentGroup = documentGroupListId.elementAt(documentGroupList.indexOf(value));
            updateDocumentList();
          }
        },
    );
    
    getDocumentsFromServer();

  }
  
  List<(int, String, int, List<int>, String)> selectedDocumentList = <(int, String, int, List<int>, String)>[];
  int selectedDocument = 0;

  DropdownMenu<String> dropDownChildren = DropdownMenu<String>(dropdownMenuEntries: [],);
  DropdownMenu<String> dropDownDocumnentGroup = DropdownMenu<String>(dropdownMenuEntries: [],);

  final _authorController = TextEditingController();

  void getDocumentsFromServer() async{
    DocumentsReply docs = await globalGrpcClient.getDocuments(fn.Int64(selectedChild));
    documentList.clear();
    for(int i = 0; i < docs.dokumente.length; i++){
      List<int> katList = [];
      for(int j = 0; j < docs.dokumente.elementAt(i).kategorie.length; j++){
        katList.add(docs.dokumente.elementAt(i).kategorie.elementAt(j).id.toInt());
      }
      documentList.add((docs.dokumente[i].klient.toInt(), docs.dokumente[i].name, docs.dokumente[i].gruppe.id.toInt(), katList, docs.dokumente[i].author));
    }
    updateDocumentList();
  }

  void updateDocumentList() {
    setState(() {
      selectedDocument = 0;
      selectedDocumentList = [];
      for(int i = 0; i < documentList.length; i++){
        if(documentList[i].$1 == selectedChild && documentList[i].$3 == selectedDocumentGroup && selectedCategories.toSet().intersection(documentList[i].$4.toSet()).isNotEmpty){
          selectedDocumentList.add(documentList[i]);
        }
      }
       _authorController.text = (selectedDocumentList.isNotEmpty) ? '${"Author: "} ${selectedDocumentList.elementAt(selectedDocument).$5}' : '';
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
                                  tileColor: selectedCategories.contains(documentCategoryListId[index]) ? Colors.blue : Colors.white,
                                  onTap: () {
                                    setState((){
                                      if(selectedCategories.contains(documentCategoryListId[index])){
                                        selectedCategories.removeAt(selectedCategories.indexOf(documentCategoryListId[index]));
                                      }else{
                                        selectedCategories.add(documentCategoryListId[index]);
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
                                      _authorController.text = '${"Author: "} ${selectedDocumentList.elementAt(selectedDocument).$5}';
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
                  Expanded(
                    flex: 3
                    , child: TextField(controller: _authorController,)
                  ),
                  Spacer(
                    flex: 18
                  ),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: () async {
                        Dokument getDoc = Dokument(name: documentList.elementAt(selectedDocument).$2
                          , gruppe: IdObjekt(id: fn.Int64(documentList.elementAt(selectedDocument).$3))
                          , klient: fn.Int64(documentList.elementAt(selectedDocument).$1));
                        
                        for(int i = 0; i < documentList.elementAt(selectedDocument).$4.length; i++){
                          getDoc.kategorie.add(IdObjekt(id: fn.Int64(documentList.elementAt(selectedDocument).$4.elementAt(i))));
                        }

                        final DocumentReply doc = await globalGrpcClient.getDocument(getDoc);
                        
                        final Uint8List preppedFile = Uint8List.fromList(doc.file);

                        final String? outputFile = await FilePicker.platform.saveFile(
                          dialogTitle: 'Bitte Speicherort auswählen:',
                          fileName: documentList.elementAt(selectedDocument).$2,
                          bytes: preppedFile
                        );

                        if (outputFile == null && (Platform.isWindows || Platform.isLinux)) {
                          await File(outputFile!).writeAsBytes(preppedFile);
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
                      onPressed: (selectedDocumentList.isNotEmpty && selectedDocumentList.elementAt(selectedDocument).$5 == loginName) ? () async{
                        await globalGrpcClient.deleteDocument(Dokument(name: selectedDocumentList.elementAt(selectedDocument).$2
                          , gruppe: IdObjekt(id: fn.Int64(selectedDocumentList.elementAt(selectedDocument).$3))
                          , klient: fn.Int64(selectedDocumentList.elementAt(selectedDocument).$1)));
                        getDocumentsFromServer();
                      } :null ,
                      child: Text('Löschen')),
                  ),
                  Spacer(
                    flex: 1
                  ),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/newdocument');
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