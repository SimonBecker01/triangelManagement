import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';


class OnDeviceSpeechService {

  OnDeviceSpeechService([SpeechToText? speech])
      : _speech = speech ?? SpeechToText();

  static final OnDeviceSpeechService instance = OnDeviceSpeechService();

  final SpeechToText _speech;
  bool _initialized = false;


  static bool get isPlatformSupported => !kIsWeb && Platform.isAndroid;

  bool get isListening => _speech.isListening;

  bool get isInitialized => _initialized;

  Future<bool> checkAvailable({String? localeId}) async {
    if (!isPlatformSupported) {
      return false;
    }
    return SpeechToTextPlatform.instance.hasOnDeviceSupport(localeId: localeId);
  }


  Future<bool> startListening({
    required SpeechResultListener onResult,
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    String? localeId,
    Duration pauseFor = const Duration(seconds: 3),
    Duration listenFor = const Duration(seconds: 30),
    bool partialResults = true,
  }) async {
    if (!isPlatformSupported) {
      return false;
    }

    if (!await checkAvailable(localeId: localeId)) {
      return false;
    }

    _speech.errorListener = onError;
    _speech.statusListener = onStatus;

    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: onError,
        onStatus: onStatus,
      );
      if (!_initialized) {
        return false;
      }
    }

    if (_speech.isListening) {
      await _speech.stop();
    }

    await _speech.listen(
      onResult: onResult,
      listenOptions: SpeechListenOptions(
        onDevice: true,
        partialResults: partialResults,
        cancelOnError: true,
        pauseFor: pauseFor,
        listenFor: listenFor,
        localeId: localeId,
      ),
    );
    return _speech.isListening;
  }

  Future<void> stopListening() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
