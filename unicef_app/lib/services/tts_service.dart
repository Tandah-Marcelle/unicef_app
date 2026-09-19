import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService instance = TtsService._init();
  final FlutterTts _flutterTts = FlutterTts();
  bool _enabled = false;

  TtsService._init() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      // Standard setup
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      // Fail silently if TTS hardware/service is missing
    }
  }

  bool get isEnabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  Future<void> speak(String text, String localeCode) async {
    if (!_enabled) return;
    try {
      String speechLanguage = 'en-US';
      if (localeCode == 'fr') {
        speechLanguage = 'fr-FR';
      } else if (localeCode == 'pcm') {
        // Pidgin does not have a native synthesizer engine. Use en-US synthesizer with a slower rate.
        speechLanguage = 'en-US';
        await _flutterTts.setSpeechRate(0.4);
      } else {
        await _flutterTts.setSpeechRate(0.5);
      }
      await _flutterTts.setLanguage(speechLanguage);
      await _flutterTts.speak(text);
    } catch (e) {
      // Catch exceptions silently
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
