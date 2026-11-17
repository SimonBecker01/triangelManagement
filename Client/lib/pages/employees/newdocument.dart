import 'package:management_triangel/widgets/admin_ui.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:management_triangel/global.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:io';

import 'package:fixnum/fixnum.dart' as fn;

import 'dart:typed_data';

import 'package:management_triangel/src/generated/triangel.pb.dart';

class NewDocumentScreen extends StatefulWidget {
  const NewDocumentScreen({super.key});

  @override
  State<NewDocumentScreen> createState() => _NewDocumentState();
}

class _NewDocumentState extends State<NewDocumentScreen> {
  final _fileUploadNameController = TextEditingController();
  final _fileNameController = TextEditingController();
  String shadowFilename = "";
  Uint8List? _pickedBytes;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (!documentGroupListId.contains(selectedDocumentGroup) && documentGroupListId.isNotEmpty) {
      selectedDocumentGroup = documentGroupListId.first;
    }
    if (selectedCategories.isEmpty) selectedCategories.addAll(documentCategoryListId);
    if (!childListId.contains(selectedChild) && childListId.isNotEmpty)
      selectedChild = childListId.first;
  }

  @override
  void dispose() {
    _fileUploadNameController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  DropdownMenu<String> _buildChildDropdown() {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
        childList.map<DropdownMenuEntry<String>>(
          (String name) => DropdownMenuEntry<String>(value: name, label: name),
        ),
      ),
      enabled: childList.length > 1,
      initialSelection: childListId.contains(selectedChild)
          ? childList[childListId.indexOf(selectedChild)]
          : (childList.isNotEmpty ? childList.first : null),
      onSelected: (value) {
        if (value != null) {
          selectedChild = childListId.elementAt(childList.indexOf(value));
        }
      },
    );
  }

  DropdownMenu<String> _buildGroupDropdown() {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
        documentGroupList.map<DropdownMenuEntry<String>>(
          (String name) => DropdownMenuEntry<String>(value: name, label: name),
        ),
      ),
      enabled: documentGroupList.length > 1,
      initialSelection: documentGroupListId.contains(selectedDocumentGroup)
          ? documentGroupList[documentGroupListId.indexOf(selectedDocumentGroup)]
          : (documentGroupList.isNotEmpty ? documentGroupList.first : null),
      onSelected: (value) {
        if (value != null) {
          selectedDocumentGroup = documentGroupListId.elementAt(documentGroupList.indexOf(value));
        }
      },
    );
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
                selectedCategories.removeAt(
                  selectedCategories.indexOf(documentCategoryListId[index]),
                );
              } else {
                selectedCategories.add(documentCategoryListId[index]);
              }
            });
          },
        );
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (!mounted || result == null) return; // cancellation is not an error
      final file = result.files.single;
      if (file.size > 20 * 1024 * 1024) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Die Datei darf höchstens 20 MiB groß sein.')));
        return;
      }
      setState(() {
        _pickedBytes = file.bytes;
        shadowFilename = file.path ?? '';
        _fileNameController.text = file.name;
      });
    } catch (error) {
      if (mounted) showRequestError(context, error);
    }
  }

  Future<void> _upload() async {
    if (_uploading) return;
    final name = _fileUploadNameController.text.trim();
    // A display name AND a chosen file are required; validate before file I/O.
    if (name.isEmpty ||
        name.length > 255 ||
        (_pickedBytes == null && shadowFilename.isEmpty) ||
        selectedDocumentGroup <= 0 ||
        selectedCategories.isEmpty ||
        selectedChild <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Name, Datei, Gruppe und mindestens eine Kategorie auswählen.'),
        ),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final Uint8List bytes = _pickedBytes ?? await File(shadowFilename).readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Die Datei ist leer oder größer als 20 MiB.')));
        return;
      }
      final document = Dokument(
        author: loginName,
        name: name,
        gruppe: IdObjekt(id: fn.Int64(selectedDocumentGroup)),
        klient: fn.Int64(selectedChild),
      );
      document.kategorie.addAll(selectedCategories.map((id) => IdObjekt(id: fn.Int64(id))));
      final reply = await globalGrpcClient.sendDocument(document, bytes);
      if (!mounted) return;
      if (reply.errorCode.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reply.errorCode)));
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) showRequestError(context, error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
                Expanded(flex: 2, child: _buildChildDropdown()),
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
                        child: Text('Kategorien', textAlign: TextAlign.center),
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
                      Expanded(flex: 3, child: _buildGroupDropdown()),
                      Expanded(
                        flex: 1,
                        child: FilledButton(
                          onPressed: _pickFile,
                          child: const Text('Datei auswählen'),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _fileNameController,
                          enabled: false,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                      const Spacer(flex: 3),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _fileUploadNameController,
                          enabled: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Hochladen mit diesem Namen...',
                          ),
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
                const Spacer(flex: 24),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Abbrechen'),
                  ),
                ),
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    onPressed: _uploading ? null : _upload,
                    child: const Text('Anlegen'),
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
            _buildChildDropdown(),
            const SizedBox(height: 12),
            _buildGroupDropdown(),
            const SizedBox(height: 12),
            const Text('Kategorien', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: _categoryListView()),
            const SizedBox(height: 16),
            FilledButton(onPressed: _pickFile, child: const Text('Datei auswählen')),
            const SizedBox(height: 12),
            TextField(
              controller: _fileNameController,
              enabled: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Ausgewählte Datei',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fileUploadNameController,
              enabled: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Hochladen mit diesem Namen...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _uploading ? null : _upload,
                    child: const Text('Anlegen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
