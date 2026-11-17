import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:management_triangel/services/grpc_client.dart';
import 'package:management_triangel/src/generated/triangel.pb.dart' as genProt;
import 'package:management_triangel/global.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SystemeinstellungenScreen extends StatefulWidget {
  const SystemeinstellungenScreen({super.key});

  @override
  State<SystemeinstellungenScreen> createState() => _SystemeinstellungenState();
}

class _SystemeinstellungenState extends State<SystemeinstellungenScreen> {
  Future<void> _pickColor(BuildContext context, {required bool light}) async {
    final Color original = light ? appTheme.lightBG : appTheme.darkBG;
    var selection = original;

    void apply(Color color) =>
        light ? appTheme.setLight(color) : appTheme.setDark(color);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(light ? 'Helle Hintergrundfarbe' : 'Dunkle Hintergrundfarbe'),
          content: SingleChildScrollView(
            child: HueRingPicker(
              pickerColor: selection,
              onColorChanged: (Color color) {
                setDialogState(() => selection = color);
                apply(color); // live preview; app-wide, since appTheme notifies
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                apply(original); // revert the live preview
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                _persist(light: light, color: selection);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _persist({required bool light, required Color color}) async {
    final String prefix = light ? 'lightBG' : 'darkBG';
    final List<genProt.Setting> settings = <genProt.Setting>[
      genProt.Setting(name: '${prefix}R', wert: (color.r * 255).round().toString()),
      genProt.Setting(name: '${prefix}G', wert: (color.g * 255).round().toString()),
      genProt.Setting(name: '${prefix}B', wert: (color.b * 255).round().toString()),
    ];
    try {
      genProt.SetSettingsReply rep =  await globalGrpcClient.setSettings(settings);
      rep.errorCode[0];
      light ? appTheme.setColors(light: color) : appTheme.setColors(dark: color);
    } catch (error) {
      debugPrint('Saving the color failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farbe konnte nicht gespeichert werden.')),
      );
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
        children: [
          const Spacer(flex: 2),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => _pickColor(context, light: true),
                    child: const Text('Helle Hintergrundfarbe auswählen'),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                const Spacer(flex: 2),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => _pickColor(context, light: false),
                    child: const Text('Dunkle Hintergrundfarbe auswählen'),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // Blöde kleine Bildschirme... (was an empty SingleChildScrollView)
  Widget _buildNarrowLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => _pickColor(context, light: true),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Helle Hintergrundfarbe auswählen'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _pickColor(context, light: false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Dunkle Hintergrundfarbe auswählen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
