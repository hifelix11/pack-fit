import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/theme.dart';

class TimerControls extends StatelessWidget {
  final bool isRunning;
  final String roomCode;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final VoidCallback onExit;

  const TimerControls({
    super.key,
    required this.isRunning,
    required this.roomCode,
    required this.onToggle,
    required this.onReset,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play / Pause
          IconButton(
            icon: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: PackFitTheme.textPrimary,
              size: 32,
            ),
            onPressed: onToggle,
          ),
          const SizedBox(width: 16),
          // Reset
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: PackFitTheme.textPrimary,
              size: 28,
            ),
            onPressed: () => _confirmReset(context),
          ),
          const SizedBox(width: 24),
          // Room code chip
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: roomCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room code copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '#$roomCode',
                style: const TextStyle(
                  color: PackFitTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Exit
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: PackFitTheme.textPrimary,
              size: 28,
            ),
            onPressed: onExit,
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Timer?'),
        content: const Text('This will reset the timer for everyone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onReset();
            },
            child:
                const Text('Reset', style: TextStyle(color: PackFitTheme.error)),
          ),
        ],
      ),
    );
  }
}
