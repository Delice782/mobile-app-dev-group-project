import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Wraps speech-to-text with safe init and toggle listen/stop.
class SpeechService {
  SpeechService() : _stt = SpeechToText();

  final SpeechToText _stt;
  bool _initialized = false;

  /// Whether [initialize] completed successfully.
  bool get isAvailable => _initialized;

  /// Current listening state from the platform plugin.
  bool get isListening => _stt.isListening;

  /// One-time setup; safe to call multiple times.
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initialized;
  }

  /// Tap once to start listening, again to stop. Partial results update live.
  Future<void> toggleListening({
    required void Function(String recognizedWords, bool finalResult) onResult,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_stt.isListening) {
      await _stt.stop();
      return;
    }

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  /// Stop listening and release the recognition session.
  Future<void> dispose() async {
    if (_stt.isListening) {
      await _stt.stop();
    }
    await _stt.cancel();
  }
}
