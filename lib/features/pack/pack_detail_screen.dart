import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_provider.dart';
import '../shared/models/check_in.dart';
import '../shared/platform_utils.dart';
import '../shared/theme.dart';
import '../timer/timer_provider.dart';
import 'pack_provider.dart';
import 'widgets/admin_controls.dart';
import 'widgets/check_in_grid.dart';
import 'widgets/goal_card.dart';
import 'widgets/history_calendar.dart';
import 'widgets/streak_display.dart';

class PackDetailScreen extends ConsumerStatefulWidget {
  final String packId;

  const PackDetailScreen({super.key, required this.packId});

  @override
  ConsumerState<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends ConsumerState<PackDetailScreen> {
  RealtimeChannel? _checkInChannel;

  @override
  void initState() {
    super.initState();
    // Subscribe to live check-in updates.
    _checkInChannel = Supabase.instance.client
        .channel('checkins_${widget.packId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'check_ins',
          callback: (payload) {
            // Refresh check-ins when a new one arrives.
            final goalAsync = ref.read(activeGoalProvider(widget.packId));
            goalAsync.whenData((goal) {
              if (goal != null) {
                ref.invalidate(todayCheckInsProvider(goal.id));
                ref.invalidate(packStreakProvider(widget.packId));
              }
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _checkInChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _checkIn(String goalId) async {
    try {
      await ref.read(packServiceProvider).checkInToday(goalId);
      ref.invalidate(todayCheckInsProvider(goalId));
      ref.invalidate(packStreakProvider(widget.packId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Check-in failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final membersAsync = ref.watch(packMembersProvider(widget.packId));
    final goalAsync = ref.watch(activeGoalProvider(widget.packId));
    final streakAsync = ref.watch(packStreakProvider(widget.packId));
    final activeTimerAsync =
        ref.watch(activeTimerSessionProvider(widget.packId));

    // Find the pack from our packs list.
    final packsAsync = ref.watch(myPacksProvider);
    final pack = packsAsync.valueOrNull
        ?.where((p) => p.id == widget.packId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(pack?.name ?? 'Pack'),
        actions: [
          if (pack != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Copy invite code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pack.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Invite code #${pack.inviteCode} copied')),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? webMaxContentWidth : double.infinity,
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(packMembersProvider(widget.packId));
              ref.invalidate(activeGoalProvider(widget.packId));
              ref.invalidate(packStreakProvider(widget.packId));
              ref.invalidate(activeTimerSessionProvider(widget.packId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Invite code chip ─────────────────
                if (pack != null)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: pack.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Invite code #${pack.inviteCode} copied')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#${pack.inviteCode}',
                          style: const TextStyle(
                            color: PackFitTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // ── Member avatars row ───────────────
                membersAsync.when(
                  data: (members) => SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: members.length,
                      itemBuilder: (context, i) {
                        final p = members[i].profile;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: p.displayName ?? 'Unknown',
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  PackFitTheme.accent.withAlpha(40),
                              backgroundImage: p.avatarUrl != null
                                  ? NetworkImage(p.avatarUrl!)
                                  : null,
                              child: p.avatarUrl == null
                                  ? Text(p.initial,
                                      style: const TextStyle(
                                          color: PackFitTheme.accent,
                                          fontSize: 14))
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // ── Streak ───────────────────────────
                streakAsync.when(
                  data: (streak) => Center(child: StreakDisplay(streak: streak)),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // ── Today's goal ─────────────────────
                goalAsync.when(
                  data: (goal) {
                    if (goal == null) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius:
                              BorderRadius.circular(PackFitTheme.cardRadius),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.flag_outlined,
                                color: PackFitTheme.textSecondary, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'No goal set yet',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    return _GoalSection(
                      packId: widget.packId,
                      goal: goal,
                      onCheckIn: () => _checkIn(goal.id),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),

                // ── Timer button ─────────────────────
                activeTimerAsync.when(
                  data: (activeSession) {
                    if (activeSession != null) {
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                              '/timer?sessionId=${activeSession.id}'),
                          icon: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: PackFitTheme.accent,
                            ),
                          ),
                          label: const Text('Join Active Timer'),
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context
                            .push('/timer?packId=${widget.packId}'),
                        icon: const Icon(Icons.timer_outlined),
                        label: const Text('Start Group Timer'),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // ── History ──────────────────────────
                goalAsync.when(
                  data: (goal) {
                    if (goal == null) return const SizedBox.shrink();
                    return _HistorySection(
                        goalId: goal.id, packId: widget.packId);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // ── Admin controls ───────────────────
                membersAsync.when(
                  data: (members) {
                    final isAdmin = members.any(
                        (m) => m.member.userId == user?.id && m.member.isAdmin);
                    if (!isAdmin) return const SizedBox.shrink();
                    return AdminControls(
                        packId: widget.packId, members: members);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The goal section with check-in grid and "I did it" button.
class _GoalSection extends ConsumerWidget {
  final String packId;
  final dynamic goal; // Goal type
  final VoidCallback onCheckIn;

  const _GoalSection({
    required this.packId,
    required this.goal,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final checkInsAsync = ref.watch(todayCheckInsProvider(goal.id));
    final membersAsync = ref.watch(packMembersProvider(packId));
    final streakAsync = ref.watch(packStreakProvider(packId));

    return checkInsAsync.when(
      data: (checkIns) {
        return membersAsync.when(
          data: (members) {
            final allDone =
                checkIns.length >= members.length && members.isNotEmpty;
            final userCheckedIn =
                checkIns.any((c) => c.userId == user?.id);
            final streak = streakAsync.valueOrNull ?? 0;

            return Column(
              children: [
                GoalCard(
                    goal: goal, allComplete: allDone, streak: streak),
                const SizedBox(height: 16),
                CheckInGrid(
                    members: members, todayCheckIns: checkIns),
                const SizedBox(height: 16),
                if (!userCheckedIn)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onCheckIn,
                      child: const Text('I did it'),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: PackFitTheme.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: PackFitTheme.accent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Checked in',
                            style: TextStyle(
                              color: PackFitTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class _HistorySection extends ConsumerWidget {
  final String goalId;
  final String packId;

  const _HistorySection({required this.goalId, required this.packId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(checkInHistoryProvider(goalId));
    final membersAsync = ref.watch(packMembersProvider(packId));

    return historyAsync.when(
      data: (checkIns) {
        return membersAsync.when(
          data: (members) => HistoryCalendar(
            checkIns: checkIns,
            memberCount: members.length,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
