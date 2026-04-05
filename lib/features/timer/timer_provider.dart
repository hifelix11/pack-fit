import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/models/profile.dart';
import 'timer_service.dart';
import 'timer_session_model.dart';

// ── Service singleton ────────────────────────────────────
final timerServiceProvider = Provider<TimerService>((ref) {
  return TimerService(Supabase.instance.client);
});

// ── Active session for a pack ────────────────────────────
final activeTimerSessionProvider =
    FutureProvider.family<TimerSession?, String>((ref, packId) async {
  return ref.read(timerServiceProvider).activeSessionForPack(packId);
});

// ── Session participants ─────────────────────────────────
final sessionParticipantsProvider =
    FutureProvider.family<List<Profile>, String>((ref, sessionId) async {
  final data = await Supabase.instance.client
      .from('session_participants')
      .select('user_id, profiles(*)')
      .eq('session_id', sessionId);

  return (data as List).map((r) {
    return Profile.fromMap(r['profiles'] as Map<String, dynamic>);
  }).toList();
});
