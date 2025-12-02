import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter/foundation.dart';

/// Speech-to-Text Service using speech_to_text package
class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  final StreamController<String> _partialResultController = StreamController<String>.broadcast();
  final StreamController<String> _finalResultController = StreamController<String>.broadcast();
  final StreamController<SttState> _stateController = StreamController<SttState>.broadcast();

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  
  Stream<String> get partialResults => _partialResultController.stream;
  Stream<String> get finalResults => _finalResultController.stream;
  Stream<SttState> get stateChanges => _stateController.stream;

  Future<void> init() async {
    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );
      debugPrint('STT initialized: $_isInitialized');
      
      if (_isInitialized) {
        // Get available locales
        final locales = await _speech.locales();
        debugPrint('Available locales: ${locales.map((l) => l.localeId).join(', ')}');
      }
    } catch (e) {
      debugPrint('STT initialization error: $e');
      _isInitialized = false;
    }
  }

  void _onStatus(String status) {
    debugPrint('STT Status: $status');
    switch (status) {
      case 'listening':
        _isListening = true;
        _stateController.add(SttState.listening);
        break;
      case 'notListening':
        _isListening = false;
        _stateController.add(SttState.idle);
        break;
      case 'done':
        _isListening = false;
        _stateController.add(SttState.idle);
        break;
    }
  }

  void _onError(dynamic error) {
    debugPrint('STT Error: $error');
    _isListening = false;
    _stateController.add(SttState.error);
  }

  void _onResult(SpeechRecognitionResult result) {
    debugPrint('STT Result: ${result.recognizedWords} (final: ${result.finalResult})');
    
    if (result.finalResult) {
      if (result.recognizedWords.isNotEmpty) {
        _finalResultController.add(result.recognizedWords);
      }
      _stateController.add(SttState.idle);
    } else {
      if (result.recognizedWords.isNotEmpty) {
        _partialResultController.add(result.recognizedWords);
      }
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      debugPrint('STT not initialized, attempting to initialize...');
      await init();
      if (!_isInitialized) {
        debugPrint('STT initialization failed');
        _stateController.add(SttState.error);
        return;
      }
    }
    
    if (_isListening) {
      debugPrint('Already listening');
      return;
    }
    
    try {
      _isListening = true;
      _stateController.add(SttState.listening);
      
      await _speech.listen(
        onResult: _onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      
      debugPrint('STT listening started');
    } catch (e) {
      debugPrint('STT start listening error: $e');
      _isListening = false;
      _stateController.add(SttState.error);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speech.stop();
      _isListening = false;
      _stateController.add(SttState.idle);
      debugPrint('STT listening stopped');
    } catch (e) {
      debugPrint('STT stop listening error: $e');
    }
  }

  Future<void> dispose() async {
    await stopListening();
    await _partialResultController.close();
    await _finalResultController.close();
    await _stateController.close();
  }
}

enum SttState {
  idle,
  listening,
  processing,
  error,
}
