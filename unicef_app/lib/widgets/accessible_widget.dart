import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String speechText;

  const AccessibleWidget({
    super.key,
    required this.child,
    required this.speechText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.ttsEnabled) {
          appState.speak(speechText);
        }
      },
      child: child,
    );
  }
}

class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String speakText;
  final VoidCallback? onTap;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.speakText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Card(
      elevation: appState.isHighContrast ? 0 : 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          if (appState.ttsEnabled) {
            appState.speak(speakText);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
