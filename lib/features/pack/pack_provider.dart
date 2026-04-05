import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/models/calendar_data.dart';
import '../shared/models/check_in.dart';
import '../shared/models/goal.dart';
import '../shared/models/pack.dart';
import '../shared/models/pack_member.dart';
import '../shared/models/profile.dart';
import 'pack_service.dart';

// ── Service singleton ────────────────────────────────────
final packServiceProvider = Provider<PackService>((ref) {
  return PackService(Supabase.instance.client);
});

// ── My packs list ────────────────────────────────────────
final myPacksProvider = FutureProvider<List<Pack>>((ref) async {
  return ref.read(packServiceProvider).fetchMyPacks();
});

// ── Pack members ─────────────────────────────────────────
final packMembersProvider = FutureProvider.family<
    List<({PackMember member, Profile profile})>, String>((ref, packId) async {
  return ref.read(packServiceProvider).fetchMembers(packId);
});

// ── Member count for a pack ──────────────────────────────
final memberCountProvider =
    FutureProvider.family<int, String>((ref, packId) async {
  return ref.read(packServiceProvider).memberCount(packId);
});

// ── Active goal for a pack ───────────────────────────────
final activeGoalProvider =
    FutureProvider.family<Goal?, String>((ref, packId) async {
  return ref.read(packServiceProvider).activeGoal(packId);
});

// ── Today's check-ins for a goal ─────────────────────────
final todayCheckInsProvider =
    FutureProvider.family<List<CheckIn>, String>((ref, goalId) async {
  return ref.read(packServiceProvider).todayCheckIns(goalId);
});

// ── Pack streak (simple int, kept for backward compat) ───
final packStreakProvider =
    FutureProvider.family<int, String>((ref, packId) async {
  return ref.read(packServiceProvider).getStreak(packId);
});

// ── Pack streak with best ────────────────────────────────
final packStreakWithBestProvider =
    FutureProvider.family<StreakData, String>((ref, packId) async {
  return ref.read(packServiceProvider).getStreakWithBest(packId);
});

// ── Check-in history ─────────────────────────────────────
final checkInHistoryProvider =
    FutureProvider.family<List<CheckIn>, String>((ref, goalId) async {
  return ref.read(packServiceProvider).checkInHistory(goalId);
});

// ── Calendar data for a month ────────────────────────────
// Key: "packId|goalId|year|month"
final packCalendarProvider = FutureProvider.family<CalendarData, String>(
    (ref, key) async {
  final parts = key.split('|');
  final packId = parts[0];
  final goalId = parts[1];
  final year = int.parse(parts[2]);
  final month = int.parse(parts[3]);

  final service = ref.read(packServiceProvider);
  final checkIns =
      await service.fetchMonthCheckIns(goalId: goalId, year: year, month: month);
  final members = await service.memberCount(packId);

  // Get goal creation date for noGoal status
  final goal = await service.activeGoal(packId);

  return CalendarData(
    year: year,
    month: month,
    checkInsByDate: checkIns,
    memberCount: members,
    goalCreatedAt: goal?.createdAt,
  );
});
