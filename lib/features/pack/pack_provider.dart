import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

// ── Pack streak ──────────────────────────────────────────
final packStreakProvider =
    FutureProvider.family<int, String>((ref, packId) async {
  return ref.read(packServiceProvider).getStreak(packId);
});

// ── Check-in history ─────────────────────────────────────
final checkInHistoryProvider =
    FutureProvider.family<List<CheckIn>, String>((ref, goalId) async {
  return ref.read(packServiceProvider).checkInHistory(goalId);
});
