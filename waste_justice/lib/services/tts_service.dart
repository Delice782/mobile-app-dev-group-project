import 'package:flutter_tts/flutter_tts.dart';

/// Short spoken feedback for collectors in the field.
class TtsService {
  TtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _ready = true;
  }

  Future<void> speakWasteRecordedSuccess() async {
    if (!_ready) await initialize();
    await _tts.speak('Waste recorded successfully');
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
