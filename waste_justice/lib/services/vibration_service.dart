import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vibration/vibration.dart';

/// Android-focused vibration helpers; no-ops when unsupported.
class VibrationService {
  Future<bool> hasVibrator() async {
    if (kIsWeb) return false;
    return await Vibration.hasVibrator();
  }

  /// Success: single ~200ms pulse.
  Future<void> successPulse() async {
    if (kIsWeb) return;
    if (!await hasVibrator()) return;
    await Vibration.vibrate(duration: 200);
  }

  /// Error: distinct pattern so it feels different from success.
  Future<void> errorPattern() async {
    if (kIsWeb) return;
    if (!await hasVibrator()) return;
    await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
  }
}
