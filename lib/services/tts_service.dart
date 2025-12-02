import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Text-to-Speech Service using Android's native TTS
class TtsService {
  static const MethodChannel _channel = MethodChannel('com.recallme/tts');
  
  double _speechRate = AppConstants.defaultSpeechRate;
  double _pitch = AppConstants.defaultPitch;
  double _volume = AppConstants.defaultVolume;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result == true;
      
      if (_isInitialized) {
        await setSpeechRate(_speechRate);
        await setPitch(_pitch);
      }
    } catch (e) {
      print('TTS initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized || text.isEmpty) return;
    
    try {
      _isSpeaking = true;
      await _channel.invokeMethod('speak', {'text': text});
    } catch (e) {
      print('TTS speak error: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
      _isSpeaking = false;
    } catch (e) {
      print('TTS stop error: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    try {
      await _channel.invokeMethod('setSpeechRate', {'rate': _speechRate});
    } catch (e) {
      print('TTS setSpeechRate error: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    try {
      await _channel.invokeMethod('setPitch', {'pitch': _pitch});
    } catch (e) {
      print('TTS setPitch error: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    // Volume is typically controlled at system level
  }

  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  Future<void> dispose() async {
    await stop();
    try {
      await _channel.invokeMethod('shutdown');
    } catch (e) {
      print('TTS shutdown error: $e');
    }
  }
}


