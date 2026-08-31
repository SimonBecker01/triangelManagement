import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:file_picker/file_picker.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:fixnum/fixnum.dart' as fn;
import 'dart:typed_data';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

    @override
  State<DocumentsScreen> createState() => _DocumentsState();
}

class _DocumentsState extends State<DocumentsScreen>{

  @override
  void initState() {
    super.initState();

    selectedCategories.addAll(documentCategoryListId);
    if (documentGroupListId.isNotEmpty) {
      selectedDocumentGroup = documentGroupListId.first;
    }

    dropDownChildren = _buildChildDropdown();
    dropDownDocumnentGroup = _buildGroupDropdown();
    
    getDocumentsFromServer();

  }
  
  List<(int, String, int, List<int>, String)> selectedDocumentList = <(int, String, int, List<int>, String)>[];
  int selectedDocument = 0;

  DropdownMenu<String> dropDownChildren = DropdownMenu<String>(dropdownMenuEntries: const [],);
  DropdownMenu<String> dropDownDocumnentGroup = DropdownMenu<String>(dropdownMenuEntries: const [],);

  final _authorController = TextEditingController();

  @override
  void dispose() {
    _authorController.dispose();
    super.dispose();
  }

  DropdownMenu<String> _buildChildDropdown() {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          childList.map<DropdownMenuEntry<String>>(
              (String name) => DropdownMenuEntry<String>(
                  value: name, label: name))),
      enabled: childList.length > 1,
      initialSelection: childList.isNotEmpty ? childList.first : null,
      onSelected: (value) {
        if (value != null) {
          selectedChild = childListId.elementAt(childList.indexOf(value));
          getDocumentsFromServer();
        }
      },
    );
  }

  DropdownMenu<String> _buildGroupDropdown() {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
          documentGroupList.map<DropdownMenuEntry<String>>(
              (String name) => DropdownMenuEntry<String>(
                  value: name, label: name))),
      enabled: documentGroupList.length > 1,
      initialSelection:
          documentGroupList.isNotEmpty ? documentGroupList.first : null,
      onSelected: (value) {
        if (value != null) {
          selectedDocumentGroup =
              documentGroupListId.elementAt(documentGroupList.indexOf(value));
          updateDocumentList();
        }
      },
    );
  }

  void getDocumentsFromServer() async {
    DocumentsReply docs =
        await globalGrpcClient.getDocuments(fn.Int64(selectedChild));
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

  Widget _categoryListView() {
    return ListView.builder(
      itemCount: documentCategoryList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(documentCategoryList[index]),
          tileColor: selectedCategories.contains(documentCategoryListId[index])
              ? Colors.blue
              : Colors.white,
          onTap: () {
            setState(() {
              if (selectedCategories.contains(documentCategoryListId[index])) {
                selectedCategories
                    .removeAt(selectedCategories.indexOf(documentCategoryListId[index]));
              } else {
                selectedCategories.add(documentCategoryListId[index]);
              }
              updateDocumentList();
            });
          },
        );
      },
    );
  }

  Widget _documentListView() {
    return ListView.builder(
      itemCount: selectedDocumentList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(selectedDocumentList[index].$2),
          tileColor: selectedDocument == index ? Colors.blue : Colors.white,
          onTap: () {
            setState(() {
              selectedDocument = index;
              _authorController.text =
                  '${"Author: "} ${selectedDocumentList.elementAt(selectedDocument).$5}';
            });
          },
        );
      },
    );
  }

  Future<void> _downloadSelectedDocument() async {
    if (selectedDocumentList.isEmpty) {
      return;
    }

    final (int klient, String name, int gruppe, List<int> kategorien, _) =
        selectedDocumentList.elementAt(selectedDocument);

    Dokument getDoc = Dokument(
      name: name,
      gruppe: IdObjekt(id: fn.Int64(gruppe)),
      klient: fn.Int64(klient),
    );

    for (int i = 0; i < kategorien.length; i++) {
      getDoc.kategorie.add(IdObjekt(id: fn.Int64(kategorien.elementAt(i))));
    }

    final DocumentReply doc = await globalGrpcClient.getDocument(getDoc);

    final Uint8List preppedFile = Uint8List.fromList(doc.file);

    await FilePicker.platform.saveFile(
      dialogTitle: 'Bitte Speicherort auswählen:',
      fileName: name,
      bytes: preppedFile,
    );
  }

  Future<void> _deleteSelectedDocument() async {
    if (selectedDocumentList.isEmpty) {
      return;
    }
    await globalGrpcClient.deleteDocument(Dokument(
        name: selectedDocumentList.elementAt(selectedDocument).$2,
        gruppe: IdObjekt(
            id: fn.Int64(selectedDocumentList.elementAt(selectedDocument).$3)),
        klient: fn.Int64(selectedDocumentList.elementAt(selectedDocument).$1)));
    getDocumentsFromServer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standardAppBar(actions: [logoutAction(context)]),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (useWideLayout(constraints)) {
            return _buildWideLayout(context);
          }
          return _buildNarrowLayout(context);
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                const Spacer(flex: 9),
                Expanded(
                  flex: 2,
                  child: dropDownChildren,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Kategorien',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 11,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _categoryListView(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: dropDownDocumnentGroup,
                      ),
                      Expanded(
                        flex: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _documentListView(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _authorController,
                  ),
                ),
                const Spacer(flex: 18),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: selectedDocumentList.isNotEmpty
                        ? _downloadSelectedDocument
                        : null,
                    child: const Text('Herunterladen'),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed:
                        (selectedDocumentList.isNotEmpty && selectedDocumentList.elementAt(selectedDocument).$5 == loginName)
                            ? _deleteSelectedDocument
                            : null,
                    child: const Text('Löschen'),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/newdocument');
                    },
                    child: const Text('Neu'),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Blöde kleine Bildschirme...
  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            dropDownChildren,
            const SizedBox(height: 12),
            dropDownDocumnentGroup,
            const SizedBox(height: 12),
            const Text('Kategorien', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _categoryListView(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: _documentListView(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Autor',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: selectedDocumentList.isNotEmpty
                      ? _downloadSelectedDocument
                      : null,
                  child: const Text('Herunterladen'),
                ),
                FilledButton(
                  onPressed:
                      (selectedDocumentList.isNotEmpty && selectedDocumentList.elementAt(selectedDocument).$5 == loginName)
                          ? _deleteSelectedDocument
                          : null,
                  child: const Text('Löschen'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/newdocument');
                  },
                  child: const Text('Neu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}