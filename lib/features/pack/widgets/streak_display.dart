import 'package:flutter/material.dart';

import '../../shared/theme.dart';

class StreakDisplay extends StatelessWidget {
  final int streak;

  const StreakDisplay({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: PackFitTheme.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: PackFitTheme.accent, size: 22),
          const SizedBox(width: 6),
          Text(
            '$streak day streak',
            style: const TextStyle(
              color: PackFitTheme.accent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
