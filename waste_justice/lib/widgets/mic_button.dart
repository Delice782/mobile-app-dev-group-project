import 'package:flutter/material.dart';

/// Large, easy-to-tap microphone control for outdoor / glove use.
class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  final bool isListening;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Colors.red.shade700;
    final Color idleColor = Colors.green.shade700;

    return Semantics(
      button: true,
      label: isListening ? 'Stop voice input' : 'Start voice input',
      child: Material(
        color: isListening ? activeColor : idleColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 88,
            height: 88,
            child: Icon(
              Icons.mic,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
