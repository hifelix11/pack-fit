import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/constants.dart';
import '../shared/models/calendar_data.dart';
import '../shared/models/check_in.dart';
import '../shared/models/goal.dart';
import '../shared/models/pack.dart';
import '../shared/models/pack_member.dart';
import '../shared/models/profile.dart';

class PackService {
  final SupabaseClient _client;

  PackService(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ── Invite code generation ─────────────────────────────
  String _generateCode() {
    final rng = Random.secure();
    return List.generate(
        codeLength, (_) => codeChars[rng.nextInt(codeChars.length)]).join();
  }

  // ── Create pack ────────────────────────────────────────
  Future<Pack> createPack(String name) async {
    final code = _generateCode();
    final data = await _client.from('packs').insert({
      'name': name,
      'invite_code': code,
      'created_by': _userId,
    }).select().single();

    // Add creator as admin member.
    await _client.from('pack_members').insert({
      'pack_id': data['id'],
      'user_id': _userId,
      'role': 'admin',
    });

    return Pack.fromMap(data);
  }

  // ── Join pack by invite code ───────────────────────────
  Future<Pack> joinPack(String inviteCode) async {
    final code = inviteCode.trim().toUpperCase().replaceAll('#', '');

    final data = await _client
        .from('packs')
        .select()
        .eq('invite_code', code)
        .maybeSingle();

    if (data == null) {
      throw Exception('Pack not found. Check the code and try again.');
    }

    final pack = Pack.fromMap(data);

    // Check if already a member.
    final existing = await _client
        .from('pack_members')
        .select()
        .eq('pack_id', pack.id)
        .eq('user_id', _userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You are already a member of this pack.');
    }

    await _client.from('pack_members').insert({
      'pack_id': pack.id,
      'user_id': _userId,
      'role': 'member',
    });

    return pack;
  }

  // ── Fetch user's packs ─────────────────────────────────
  Future<List<Pack>> fetchMyPacks() async {
    final memberRows = await _client
        .from('pack_members')
        .select('pack_id')
        .eq('user_id', _userId);

    final packIds =
        (memberRows as List).map((r) => r['pack_id'] as String).toList();

    if (packIds.isEmpty) return [];

    final data =
        await _client.from('packs').select().inFilter('id', packIds).order('created_at');
    return (data as List).map((m) => Pack.fromMap(m)).toList();
  }

  // ── Pack members with profiles ─────────────────────────
  Future<List<({PackMember member, Profile profile})>> fetchMembers(
      String packId) async {
    final rows = await _client
        .from('pack_members')
        .select('*, profiles(*)')
        .eq('pack_id', packId)
        .order('joined_at');

    return (rows as List).map((r) {
      final member = PackMember.fromMap(r);
      final profile = Profile.fromMap(r['profiles'] as Map<String, dynamic>);
      return (member: member, profile: profile);
    }).toList();
  }

  // ── Member count ───────────────────────────────────────
  Future<int> memberCount(String packId) async {
    final data = await _client
        .from('pack_members')
        .select('id')
        .eq('pack_id', packId);
    return (data as List).length;
  }

  // ── Active goal ────────────────────────────────────────
  Future<Goal?> activeGoal(String packId) async {
    final data = await _client
        .from('goals')
        .select()
        .eq('pack_id', packId)
        .eq('is_active', true)
        .maybeSingle();
    return data != null ? Goal.fromMap(data) : null;
  }

  // ── Create / update goal ───────────────────────────────
  Future<Goal> setGoal(
      String packId, String title, int? targetMinutes) async {
    // Deactivate existing goals.
    await _client
        .from('goals')
        .update({'is_active': false})
        .eq('pack_id', packId)
        .eq('is_active', true);

    final data = await _client.from('goals').insert({
      'pack_id': packId,
      'title': title,
      'target_minutes': targetMinutes,
      'is_active': true,
      'created_by': _userId,
    }).select().single();

    return Goal.fromMap(data);
  }

  // ── Check-in ───────────────────────────────────────────
  Future<void> checkInToday(String goalId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _client.from('check_ins').upsert(
      {
        'goal_id': goalId,
        'user_id': _userId,
        'checked_date': today,
      },
      onConflict: 'goal_id,user_id,checked_date',
    );
  }

  // ── Today's check-ins for a goal ───────────────────────
  Future<List<CheckIn>> todayCheckIns(String goalId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _client
        .from('check_ins')
        .select()
        .eq('goal_id', goalId)
        .eq('checked_date', today);
    return (data as List).map((m) => CheckIn.fromMap(m)).toList();
  }

  // ── History check-ins (last N days) ────────────────────
  Future<List<CheckIn>> checkInHistory(String goalId, {int days = 30}) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    final data = await _client
        .from('check_ins')
        .select()
        .eq('goal_id', goalId)
        .gte('checked_date', since)
        .order('checked_date');
    return (data as List).map((m) => CheckIn.fromMap(m)).toList();
  }

  // ── Streak (calls DB function) ─────────────────────────
  Future<int> getStreak(String packId) async {
    final result =
        await _client.rpc('get_pack_streak', params: {'p_pack_id': packId});
    return (result as int?) ?? 0;
  }

  // ── Streak with best (calls enhanced DB function) ──────
  Future<StreakData> getStreakWithBest(String packId) async {
    try {
      final result = await _client
          .rpc('get_pack_streak_with_best', params: {'p_pack_id': packId});

      final row = (result as List).first;
      final currentStreak = row['current_streak'] as int? ?? 0;
      final bestStreak = row['best_streak'] as int? ?? 0;

      // Also get today's completion status
      final goal = await activeGoal(packId);
      int todayCheckins = 0;
      int members = 0;
      if (goal != null) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final checkIns = await _client
            .from('check_ins')
            .select('id')
            .eq('goal_id', goal.id)
            .eq('checked_date', today);
        todayCheckins = (checkIns as List).length;
        members = await memberCount(packId);
      }

      return StreakData(
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        todayComplete: members > 0 && todayCheckins >= members,
        todayCheckIns: todayCheckins,
        memberCount: members,
      );
    } catch (_) {
      // Fallback if the new function doesn't exist yet
      final streak = await getStreak(packId);
      return StreakData(
        currentStreak: streak,
        bestStreak: streak,
        todayComplete: false,
        todayCheckIns: 0,
        memberCount: 0,
      );
    }
  }

  // ── Month check-ins for calendar ───────────────────────
  Future<Map<String, List<CheckIn>>> fetchMonthCheckIns({
    required String goalId,
    required int year,
    required int month,
  }) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';

    final data = await _client
        .from('check_ins')
        .select()
        .eq('goal_id', goalId)
        .gte('checked_date', startDate)
        .lt('checked_date', endDate)
        .order('checked_at', ascending: true);

    final Map<String, List<CheckIn>> grouped = {};
    for (final row in data as List) {
      final date = row['checked_date'] as String;
      grouped.putIfAbsent(date, () => []).add(CheckIn.fromMap(row));
    }
    return grouped;
  }

  // ── Fetch members for day detail (with profiles) ───────
  Future<List<({String userId, String displayName, String? avatarUrl})>>
      fetchPackMembersForDetail(String packId) async {
    final rows = await _client
        .from('pack_members')
        .select('user_id, profiles:user_id(display_name, avatar_url)')
        .eq('pack_id', packId);

    return (rows as List).map((r) {
      final profile = r['profiles'] as Map<String, dynamic>?;
      return (
        userId: r['user_id'] as String,
        displayName: profile?['display_name'] as String? ?? 'Unknown',
        avatarUrl: profile?['avatar_url'] as String?,
      );
    }).toList();
  }

  // ── Admin: remove member ───────────────────────────────
  Future<void> removeMember(String packId, String userId) async {
    await _client
        .from('pack_members')
        .delete()
        .eq('pack_id', packId)
        .eq('user_id', userId);

    // If the removed user was admin, promote the earliest member.
    final remaining = await _client
        .from('pack_members')
        .select()
        .eq('pack_id', packId)
        .order('joined_at')
        .limit(1)
        .maybeSingle();

    if (remaining == null) {
      // No members left — delete the pack.
      await _client.from('packs').delete().eq('id', packId);
    } else if (remaining['role'] != 'admin') {
      // Promote earliest member to admin.
      await _client
          .from('pack_members')
          .update({'role': 'admin'})
          .eq('id', remaining['id']);
    }
  }

  // ── Admin: delete pack ─────────────────────────────────
  Future<void> deletePack(String packId) async {
    await _client.from('packs').delete().eq('id', packId);
  }

  // ── Admin: update pack name ────────────────────────────
  Future<void> updatePackName(String packId, String name) async {
    await _client.from('packs').update({'name': name}).eq('id', packId);
  }

  // ── Leave pack ─────────────────────────────────────────
  Future<void> leavePack(String packId) async {
    await removeMember(packId, _userId);
  }
}
