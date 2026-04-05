import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../shared/models/profile.dart';
import '../shared/theme.dart';
import 'timer_provider.dart';
import 'timer_session_model.dart';
import 'widgets/led_display.dart';
import 'widgets/participant_avatars.dart';
import 'widgets/timer_controls.dart';

class TimerScreen extends ConsumerStatefulWidget {
  /// If non-null, join an existing session. Otherwise create a new one.
  final String? sessionId;

  /// If non-null, create a session tied to this pack.
  final String? packId;

  const TimerScreen({super.key, this.sessionId, this.packId});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with SingleTickerProviderStateMixin {
  TimerSession? _session;
  Timer? _ticker;
  int _displayMs = 0;
  bool _loading = true;
  RealtimeChannel? _channel;
  List<Profile> _participants = [];

  // Blink animation for pause state.
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

  // Colon pulse animation.
  late final AnimationController _colonController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _blinkAnimation =
        Tween<double>(begin: 1.0, end: 0.3).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));

    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      WakelockPlus.enable();
    }

    _init();
  }

  Future<void> _init() async {
    final service = ref.read(timerServiceProvider);

    if (widget.sessionId != null) {
      // Join existing session.
      _session = await service.joinSession(widget.sessionId!);
    } else {
      // Create new session.
      _session = await service.createSession(packId: widget.packId);
    }

    if (_session == null) {
      if (mounted) context.pop();
      return;
    }

    _displayMs = _session!.currentElapsedMs;
    _startLocalTicker();
    _subscribeRealtime();
    _loadParticipants();

    setState(() => _loading = false);
  }

  void _startLocalTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_session != null && mounted) {
        setState(() {
          _displayMs = _session!.currentElapsedMs;
        });
      }
    });
  }

  void _subscribeRealtime() {
    if (_session == null) return;
    final service = ref.read(timerServiceProvider);
    _channel = service.subscribeToSession(_session!.id, (updated) {
      setState(() {
        _session = updated;
        _displayMs = updated.currentElapsedMs;
        _updateBlinkState();
      });
    });
  }

  void _updateBlinkState() {
    if (_session?.isPaused == true) {
      _blinkController.repeat(reverse: true);
    } else {
      _blinkController.stop();
      _blinkController.value = 0;
    }
  }

  Future<void> _loadParticipants() async {
    if (_session == null) return;
    final data = await Supabase.instance.client
        .from('session_participants')
        .select('user_id, profiles(*)')
        .eq('session_id', _session!.id);
    if (mounted) {
      setState(() {
        _participants = (data as List)
            .map((r) => Profile.fromMap(r['profiles'] as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _toggleTimer() async {
    if (_session == null) return;
    final service = ref.read(timerServiceProvider);

    if (_session!.isRunning) {
      await service.pauseTimer(_session!.id, _session!.currentElapsedMs);
    } else {
      await service.startTimer(_session!.id, _session!.elapsedMs);
    }
  }

  Future<void> _resetTimer() async {
    if (_session == null) return;
    await ref.read(timerServiceProvider).resetTimer(_session!.id);
  }

  Future<void> _exit() async {
    if (_session != null) {
      await ref.read(timerServiceProvider).leaveSession(_session!.id);
    }
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _channel?.unsubscribe();
    _blinkController.dispose();
    _colonController.dispose();

    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      WakelockPlus.disable();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: PackFitTheme.timerBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isRunning = _session?.isRunning ?? false;
    final isPaused = _session?.isPaused ?? true;

    return Scaffold(
      backgroundColor: PackFitTheme.timerBackground,
      body: AnimatedBuilder(
        animation: _blinkAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: isPaused ? _blinkAnimation.value : 1.0,
            child: child,
          );
        },
        child: Stack(
          children: [
            // ── LED Display ──────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LedDisplay(elapsedMs: _displayMs),
              ),
            ),

            // ── Controls overlay at bottom ───────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_participants.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child:
                          ParticipantAvatars(participants: _participants),
                    ),
                  TimerControls(
                    isRunning: isRunning,
                    roomCode: _session?.roomCode ?? '',
                    onToggle: _toggleTimer,
                    onReset: _resetTimer,
                    onExit: _exit,
                  ),
                ],
              ),
            ),

            // ── Web: fullscreen button ───────────────
            if (kIsWeb)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen,
                      color: Colors.white38, size: 28),
                  onPressed: () {
                    // Web fullscreen API via JS interop would go here.
                    // For now, show a tooltip.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Press F11 for fullscreen'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
