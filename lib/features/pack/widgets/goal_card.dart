import 'package:flutter/material.dart';

import '../../shared/models/goal.dart';
import '../../shared/theme.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final bool allComplete;
  final int streak;

  const GoalCard({
    super.key,
    required this.goal,
    required this.allComplete,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PackFitTheme.cardRadius),
        gradient: allComplete
            ? LinearGradient(
                colors: [
                  PackFitTheme.accent.withAlpha(30),
                  PackFitTheme.accent.withAlpha(10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: allComplete ? null : const Color(0xFF1A1A1A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allComplete ? Icons.emoji_events : Icons.flag_outlined,
                color: PackFitTheme.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (goal.targetMinutes != null)
                Text(
                  '${goal.targetMinutes} min',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
          if (allComplete) ...[
            const SizedBox(height: 8),
            Text(
              'Pack Complete! Day $streak',
              style: const TextStyle(
                color: PackFitTheme.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
