import 'package:management_triangel/widgets/admin_ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:interval_time_picker/models/visible_step.dart';
import 'package:management_triangel/global.dart';
import 'package:interval_time_picker/interval_time_picker.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart';
import 'package:fixnum/fixnum.dart' as fn;
import 'package:management_triangel/speechttbutton.dart';

extension TimeOfDayExtension on TimeOfDay {
  // Ported from org.threeten.bp;
  TimeOfDay plusMinutes(int minutes) {
    if (minutes == 0) {
      return this;
    } else {
      int mofd = hour * 60 + minute;
      int newMofd = ((minutes % 1440) + mofd + 1440) % 1440;
      if (mofd == newMofd) {
        return this;
      } else {
        int newHour = newMofd ~/ 60;
        int newMinute = newMofd % 60;
        return TimeOfDay(hour: newHour, minute: newMinute);
      }
    }
  }
}

class TimetrackerScreen extends StatefulWidget {
  const TimetrackerScreen({super.key});

  @override
  State<TimetrackerScreen> createState() => _TimeTrackerState();
}

class _TimeTrackerState extends State<TimetrackerScreen> {
  DropdownMenu<String> dropDownChildren = DropdownMenu<String>(dropdownMenuEntries: const []);
  DropdownMenu<String> dropDownActivity = DropdownMenu<String>(dropdownMenuEntries: const []);

  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay startTime = TimeOfDay(
    hour: TimeOfDay.now().hour,
    minute: TimeOfDay.now().minute - (TimeOfDay.now().minute % 5),
  );
  TimeOfDay endTime = TimeOfDay(
    hour: TimeOfDay.now().plusMinutes(30).hour,
    minute: TimeOfDay.now().plusMinutes(30).minute - (TimeOfDay.now().minute % 5),
  );

  DateTime currSelDate = DateTime.now();
  int currSelActivity = -1;
  bool _saving = false;
  int _loadSequence = 0;

  @override
  void initState() {
    super.initState();

    dropDownChildren = _buildChildDropdown();
    dropDownActivity = _buildActivityDropdown();
    _changedDate();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DropdownMenu<String> _buildChildDropdown({String? initialName, bool entriesEnabled = true}) {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
        childList.map<DropdownMenuEntry<String>>(
          (String name) =>
              DropdownMenuEntry<String>(value: name, label: name, enabled: entriesEnabled),
        ),
      ),
      enabled: childList.length > 1,
      initialSelection: initialName ?? (childList.isNotEmpty ? childList.first : null),
      onSelected: (value) {
        if (value != null) {
          selectedChild = childListId.elementAt(childList.indexOf(value));
        }
      },
    );
  }

  DropdownMenu<String> _buildActivityDropdown({String? initialName}) {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: UnmodifiableListView<DropdownMenuEntry<String>>(
        activityList.map<DropdownMenuEntry<String>>(
          (String name) => DropdownMenuEntry<String>(value: name, label: name),
        ),
      ),
      enabled: activityList.length > 1,
      initialSelection: initialName ?? (activityList.isNotEmpty ? activityList.first : null),
      onSelected: (value) {
        if (value != null) {
          selectedActivity = activityListId.elementAt(activityList.indexOf(value));
        }
      },
    );
  }

  Future<void> _changedDate() async {
    final requested = currSelDate;
    final sequence = ++_loadSequence;
    try {
      final result = await globalGrpcClient.getZeiteintraege(
        Datum(year: requested.year, month: requested.month, day: requested.day),
      );
      if (!mounted || sequence != _loadSequence) return;
      final entries = result.zeiteintraege
          .map(
            (e) => (
              TimeOfDay(hour: e.anfang.hour, minute: e.anfang.minute),
              TimeOfDay(hour: e.ende.hour, minute: e.ende.minute),
              e.taetigkeitid.toInt(),
              e.klientid.toInt(),
              e.beschreibung,
              e.eintragid.toInt(),
            ),
          )
          .toList();
      setState(() {
        activityOnDayList
          ..clear()
          ..addAll(entries);
        if (!entries.any((e) => e.$6 == currSelActivity)) currSelActivity = -1;
      });
    } catch (error) {
      if (mounted && sequence == _loadSequence) showRequestError(context, error);
    }
  }

  void _changedactivity(int changedIndex) {
    if (changedIndex < 0 || changedIndex >= activityOnDayList.length) return;
    final entry = activityOnDayList[changedIndex];
    startTime = entry.$1;
    endTime = entry.$2;
    selectedActivity = entry.$3;
    selectedChild = entry.$4;
    _descriptionController.text = entry.$5;
    currSelActivity = entry.$6;
    final activityIndex = activityListId.indexOf(entry.$3);
    final childIndex = childListId.indexOf(entry.$4);
    setState(() {
      dropDownActivity = _buildActivityDropdown(
        initialName: activityIndex < 0 ? null : activityList[activityIndex],
      );
      dropDownChildren = _buildChildDropdown(
        initialName: childIndex < 0 ? null : childList[childIndex],
      );
    });
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? selectedTime = await (showIntervalTimePicker(
      context: context,
      initialTime: startTime,
      interval: 5,
      visibleStep: VisibleStep.fifths,
    ));
    if (mounted && selectedTime != null) {
      setState(() {
        startTime = selectedTime;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? selectedTime = await (showIntervalTimePicker(
      context: context,
      initialTime: endTime,
      interval: 5,
      visibleStep: VisibleStep.fifths,
    ));
    if (mounted && selectedTime != null) {
      setState(() {
        if (selectedTime.compareTo(startTime) > 0) {
          endTime = selectedTime;
        } else {
          endTime = startTime.plusMinutes(5);
        }
      });
    }
  }

  Widget _startTimeButton() {
    return FilledButton(
      onPressed: _pickStartTime,
      child: TextField(
        controller: _startTimeController,
        enabled: false,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _endTimeButton() {
    return FilledButton(
      onPressed: _pickEndTime,
      child: TextField(
        controller: _endTimeController,
        enabled: false,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _activityName(int id) {
    final index = activityListId.indexOf(id);
    return index < 0 ? 'Unbekannte Tätigkeit' : activityList[index];
  }

  Widget _entryListView() {
    return ListView.builder(
      itemCount: activityOnDayList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            "${activityOnDayList[index].$1.format(context)}-${activityOnDayList[index].$2.format(context)} - ${_activityName(activityOnDayList[index].$3)}",
          ),
          tileColor: activityOnDayList[index].$6 == currSelActivity ? Colors.blue : Colors.white,
          onTap: () {
            _changedactivity(index);
          },
        );
      },
    );
  }

  Future<void> _saveChange() async {
    await _performOperation(2);
  }

  Future<void> _delete() async {
    await _performOperation(3);
  }

  Future<void> _createNew() async {
    await _performOperation(1);
  }

  // Domain validation errors are returned in errorCode on an OK gRPC reply;
  // transport errors are caught separately. Never display a failed save as success.
  Future<void> _performOperation(int operation) async {
    if (_saving) return;
    if ((operation != 1 && currSelActivity <= 0) ||
        selectedChild <= 0 ||
        (operation != 3 && (selectedActivity <= 0 || endTime.compareTo(startTime) <= 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Klient, Tätigkeit und einen gültigen Zeitraum auswählen.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final reply = await globalGrpcClient.saveZeiteintrag(
        Zeiteintrag(
          dayofentry: Datum(year: currSelDate.year, month: currSelDate.month, day: currSelDate.day),
          anfang: Uhrzeit(hour: startTime.hour, minute: startTime.minute),
          ende: Uhrzeit(hour: endTime.hour, minute: endTime.minute),
          taetigkeitid: fn.Int64(selectedActivity),
          klientid: fn.Int64(selectedChild),
          beschreibung: _descriptionController.text,
          eintragid: fn.Int64(operation == 1 ? 0 : currSelActivity),
        ),
        operation,
      );
      if (!mounted) return;
      if (reply.errorCode.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reply.errorCode)));
        return;
      }
      await _changedDate();
    } catch (error) {
      if (mounted) showRequestError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _startTimeController.text = startTime.format(context);
    _endTimeController.text = endTime.format(context);

    return Scaffold(
      appBar: standardAppBar(actions: [logoutAction(context)]),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (useWideLayout(constraints)) {
            return _buildWideLayout();
          }
          return _buildNarrowLayout();
        },
      ),
    );
  }

  Widget _buildWideLayout() {
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
                Expanded(flex: 2, child: dropDownChildren),
              ],
            ),
          ),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                const Spacer(flex: 3),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Expanded(flex: 3, child: dropDownActivity),
                      Expanded(
                        flex: 8,
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Beschreibung',
                          ),
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
                        flex: 2,
                        child: CalendarDatePicker(
                          initialDate: currSelDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(3000),
                          onDateChanged: (DateTime value) {
                            currSelDate = value;
                            currSelActivity = -1;
                            _changedDate();
                          },
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Expanded(flex: 1, child: _startTimeButton()),
                                    const Expanded(flex: 1, child: Text('Tätigkeitsbeginn')),
                                    Expanded(flex: 1, child: _endTimeButton()),
                                    const Expanded(flex: 1, child: Text('Tätigkeitsende')),
                                    const Spacer(flex: 8),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: _entryListView(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Spacer(flex: 7),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    onPressed: !_saving && currSelActivity > 0 ? _saveChange : null,
                    child: const Text('Ändern'),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    onPressed: !_saving && currSelActivity > 0 ? _delete : null,
                    child: const Text('Löschen'),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    onPressed: _saving ? null : _createNew,
                    child: const Text('Neu Anlegen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Blöde kleine Bildschirme...
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            dropDownChildren,
            const SizedBox(height: 12),
            dropDownActivity,
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Beschreibung',
              ),
            ),
            const SizedBox(height: 6),
            OnDeviceSpeechButton(
              onResult: (result) {
                setState(() {
                  _descriptionController.text = result.recognizedWords;
                  _descriptionController.selection = TextSelection.collapsed(
                    offset: _descriptionController.text.length,
                  );
                });
              },
              onError: (error) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Speech error: ${error.errorMsg}')));
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 340,
              child: CalendarDatePicker(
                initialDate: currSelDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(3000),
                onDateChanged: (DateTime value) {
                  currSelDate = value;
                  currSelActivity = -1;
                  _changedDate();
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _startTimeButton(),
                      const SizedBox(height: 4),
                      const Text('Tätigkeitsbeginn', textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _endTimeButton(),
                      const SizedBox(height: 4),
                      const Text('Tätigkeitsende', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: _entryListView()),
            const SizedBox(height: 16),
            AdminActions(
              children: [
                FilledButton(
                  onPressed: !_saving && currSelActivity > 0 ? _saveChange : null,
                  child: const Text('Ändern'),
                ),
                OutlinedButton(
                  onPressed: !_saving && currSelActivity > 0 ? _delete : null,
                  child: const Text('Löschen'),
                ),
                FilledButton(
                  onPressed: _saving ? null : _createNew,
                  child: const Text('Neu anlegen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
