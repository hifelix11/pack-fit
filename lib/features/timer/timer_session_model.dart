class TimerSession {
  final String id;
  final String roomCode;
  final String? packId;
  final String createdBy;
  final String state; // 'running' | 'paused' | 'stopped'
  final int elapsedMs;
  final DateTime? lastStartedAt;
  final DateTime createdAt;

  const TimerSession({
    required this.id,
    required this.roomCode,
    this.packId,
    required this.createdBy,
    required this.state,
    required this.elapsedMs,
    this.lastStartedAt,
    required this.createdAt,
  });

  bool get isRunning => state == 'running';
  bool get isPaused => state == 'paused';
  bool get isStopped => state == 'stopped';

  /// Compute the current elapsed time, accounting for running state.
  int get currentElapsedMs {
    if (isRunning && lastStartedAt != null) {
      final sinceStart =
          DateTime.now().toUtc().difference(lastStartedAt!).inMilliseconds;
      return elapsedMs + sinceStart;
    }
    return elapsedMs;
  }

  factory TimerSession.fromMap(Map<String, dynamic> map) {
    return TimerSession(
      id: map['id'] as String,
      roomCode: map['room_code'] as String,
      packId: map['pack_id'] as String?,
      createdBy: map['created_by'] as String,
      state: map['state'] as String? ?? 'paused',
      elapsedMs: (map['elapsed_ms'] as num?)?.toInt() ?? 0,
      lastStartedAt: map['last_started_at'] != null
          ? DateTime.parse(map['last_started_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
