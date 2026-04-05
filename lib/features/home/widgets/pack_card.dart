import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pack/pack_provider.dart';
import '../../shared/models/pack.dart';
import '../../shared/theme.dart';

class PackCard extends ConsumerWidget {
  final Pack pack;
  final VoidCallback onTap;

  const PackCard({super.key, required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberCountAsync = ref.watch(memberCountProvider(pack.id));
    final goalAsync = ref.watch(activeGoalProvider(pack.id));
    final streakAsync = ref.watch(packStreakProvider(pack.id));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(PackFitTheme.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pack.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  // Streak
                  streakAsync.when(
                    data: (streak) => streak > 0
                        ? _StreakChip(streak: streak)
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              memberCountAsync.when(
                data: (count) => Text(
                  '$count member${count != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              // Goal status
              goalAsync.when(
                data: (goal) {
                  if (goal == null) {
                    return Text(
                      'No goal set',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  return _GoalStatusRow(goalId: goal.id, packId: pack.id);
                },
                loading: () => const SizedBox(
                    height: 20, child: LinearProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;
  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PackFitTheme.accent.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              size: 16, color: PackFitTheme.accent),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
                color: PackFitTheme.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _GoalStatusRow extends ConsumerWidget {
  final String goalId;
  final String packId;

  const _GoalStatusRow({required this.goalId, required this.packId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInsAsync = ref.watch(todayCheckInsProvider(goalId));
    final memberCountAsync = ref.watch(memberCountProvider(packId));

    return checkInsAsync.when(
      data: (checkIns) {
        final done = checkIns.length;
        return memberCountAsync.when(
          data: (total) {
            final allDone = done >= total && total > 0;
            return Row(
              children: [
                if (allDone)
                  const Icon(Icons.check_circle,
                      color: PackFitTheme.accent, size: 20)
                else
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: total > 0 ? done / total : 0,
                      strokeWidth: 3,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(
                          PackFitTheme.accent),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  allDone ? 'All Clear' : '$done/$total done',
                  style: TextStyle(
                    color:
                        allDone ? PackFitTheme.accent : PackFitTheme.textSecondary,
                    fontWeight:
                        allDone ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
