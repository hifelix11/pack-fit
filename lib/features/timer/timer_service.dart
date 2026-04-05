import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/constants.dart';
import 'timer_session_model.dart';

class TimerService {
  final SupabaseClient _client;

  TimerService(this._client);

  String get _userId => _client.auth.currentUser!.id;

  String _generateRoomCode() {
    final rng = Random.secure();
    return List.generate(
        codeLength, (_) => codeChars[rng.nextInt(codeChars.length)]).join();
  }

  // ── Create session ─────────────────────────────────────
  Future<TimerSession> createSession({String? packId}) async {
    final roomCode = _generateRoomCode();
    final data = await _client.from('timer_sessions').insert({
      'room_code': roomCode,
      'pack_id': packId,
      'created_by': _userId,
      'state': 'paused',
      'elapsed_ms': 0,
    }).select().single();

    // Add creator as participant.
    await _client.from('session_participants').insert({
      'session_id': data['id'],
      'user_id': _userId,
    });

    return TimerSession.fromMap(data);
  }

  // ── Join session by room code ──────────────────────────
  Future<TimerSession> joinSession(String roomCode) async {
    final code = roomCode.trim().toUpperCase().replaceAll('#', '');

    final data = await _client
        .from('timer_sessions')
        .select()
        .eq('room_code', code)
        .maybeSingle();

    if (data == null) {
      throw Exception('Timer session not found.');
    }

    final session = TimerSession.fromMap(data);

    // Add as participant (ignore if already in).
    await _client.from('session_participants').upsert(
      {
        'session_id': session.id,
        'user_id': _userId,
      },
      onConflict: 'session_id,user_id',
    );

    return session;
  }

  // ── Find active session for a pack ─────────────────────
  Future<TimerSession?> activeSessionForPack(String packId) async {
    final data = await _client
        .from('timer_sessions')
        .select()
        .eq('pack_id', packId)
        .neq('state', 'stopped')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data != null ? TimerSession.fromMap(data) : null;
  }

  // ── Start / Resume ─────────────────────────────────────
  Future<void> startTimer(String sessionId, int currentElapsedMs) async {
    await _client.from('timer_sessions').update({
      'state': 'running',
      'elapsed_ms': currentElapsedMs,
      'last_started_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }

  // ── Pause ──────────────────────────────────────────────
  Future<void> pauseTimer(String sessionId, int totalElapsedMs) async {
    await _client.from('timer_sessions').update({
      'state': 'paused',
      'elapsed_ms': totalElapsedMs,
      'last_started_at': null,
    }).eq('id', sessionId);
  }

  // ── Reset ──────────────────────────────────────────────
  Future<void> resetTimer(String sessionId) async {
    await _client.from('timer_sessions').update({
      'state': 'paused',
      'elapsed_ms': 0,
      'last_started_at': null,
    }).eq('id', sessionId);
  }

  // ── Stop (end session) ─────────────────────────────────
  Future<void> stopTimer(String sessionId) async {
    await _client.from('timer_sessions').update({
      'state': 'stopped',
    }).eq('id', sessionId);
  }

  // ── Leave session ──────────────────────────────────────
  Future<void> leaveSession(String sessionId) async {
    await _client
        .from('session_participants')
        .delete()
        .eq('session_id', sessionId)
        .eq('user_id', _userId);
  }

  // ── Fetch session ──────────────────────────────────────
  Future<TimerSession?> fetchSession(String sessionId) async {
    final data = await _client
        .from('timer_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();
    return data != null ? TimerSession.fromMap(data) : null;
  }

  // ── Realtime subscription on a session ─────────────────
  RealtimeChannel subscribeToSession(
    String sessionId,
    void Function(TimerSession) onUpdate,
  ) {
    return _client
        .channel('timer_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'timer_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            onUpdate(TimerSession.fromMap(newData));
          },
        )
        .subscribe();
  }
}
