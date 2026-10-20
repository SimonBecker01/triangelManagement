import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:management_triangel/speechttservice.dart';

class OnDeviceSpeechButton extends StatefulWidget {
  const OnDeviceSpeechButton({
    super.key,
    required this.onResult,
    this.onError,
    this.onListeningChanged,
    this.localeId,
    this.pauseFor = const Duration(seconds: 3),
    this.listenFor = const Duration(seconds: 30),
    this.partialResults = true,
    this.icon = Icons.mic,
    this.listeningIcon = Icons.stop,
    this.tooltip = 'Voice input (offline)',
  });

  final SpeechResultListener onResult;

  final SpeechErrorListener? onError;

  final ValueChanged<bool>? onListeningChanged;

  final String? localeId;

  final Duration pauseFor;

  final Duration listenFor;

  final bool partialResults;

  final IconData icon;

  final IconData listeningIcon;

  final String? tooltip;

  @override
  State<OnDeviceSpeechButton> createState() => _OnDeviceSpeechButtonState();
}

class _OnDeviceSpeechButtonState extends State<OnDeviceSpeechButton> {
  final OnDeviceSpeechService _service = OnDeviceSpeechService.instance;
  late final Future<bool> _available;
  bool _listening = false;

  @override
  void initState() {
    super.initState();

    _available = _service.checkAvailable(localeId: widget.localeId);
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _service.stopListening();
      _setListening(false);
      return;
    }
    final started = await _service.startListening(
      onResult: widget.onResult,
      onError: widget.onError,
      onStatus: _handleStatus,
      localeId: widget.localeId,
      pauseFor: widget.pauseFor,
      listenFor: widget.listenFor,
      partialResults: widget.partialResults,
    );
    _setListening(started);
  }

  void _handleStatus(String status) {
    switch (status) {
      case SpeechToText.listeningStatus:
        _setListening(true);
      case SpeechToText.notListeningStatus:
      case SpeechToText.doneStatus:
      case 'doneNoResult':
        _setListening(false);
      default:
        break;
    }
  }

  void _setListening(bool listening) {
    if (!mounted) return;
    if (_listening != listening) {
      setState(() => _listening = listening);
      widget.onListeningChanged?.call(listening);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _available,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return IconButton(
          onPressed: _toggle,
          tooltip: widget.tooltip,
          icon: Icon(_listening ? widget.listeningIcon : widget.icon),
          style: _listening
              ? IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                )
              : null,
        );
      },
    );
  }
}
