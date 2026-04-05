import 'package:flutter/material.dart';

import '../../shared/theme.dart';

class LedDisplay extends StatelessWidget {
  final int elapsedMs;

  const LedDisplay({super.key, required this.elapsedMs});

  @override
  Widget build(BuildContext context) {
    final totalSeconds = elapsedMs ~/ 1000;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Dim "off" segments
        FittedBox(
          fit: BoxFit.contain,
          child: Text(
            '88:88',
            style: TextStyle(
              fontFamily: 'DSEG7Classic',
              fontWeight: FontWeight.bold,
              color: PackFitTheme.ledOff,
              fontSize: 200,
            ),
          ),
        ),
        // Active segments
        FittedBox(
          fit: BoxFit.contain,
          child: Text(
            timeStr,
            style: TextStyle(
              fontFamily: 'DSEG7Classic',
              fontWeight: FontWeight.bold,
              color: PackFitTheme.ledOn,
              fontSize: 200,
            ),
          ),
        ),
      ],
    );
  }
}
