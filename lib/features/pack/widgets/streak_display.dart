import 'package:flutter/material.dart';

import '../../shared/models/calendar_data.dart';
import '../../shared/theme.dart';

class StreakDisplay extends StatelessWidget {
  final StreakData streakData;

  const StreakDisplay({super.key, required this.streakData});

  @override
  Widget build(BuildContext context) {
    final streak = streakData.currentStreak;
    final best = streakData.bestStreak;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(PackFitTheme.cardRadius),
      ),
      child: Column(
        children: [
          if (streak == 0) ...[
            const Icon(Icons.circle_outlined,
                color: Color(0xFF555555), size: 32),
            const SizedBox(height: 8),
            const Text(
              'No active streak',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check in today to start one!',
              style: TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
            if (best > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Your longest: $best days',
                style:
                    const TextStyle(color: Color(0xFF666666), fontSize: 13),
              ),
            ],
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FireIcon(streak: streak),
                const SizedBox(width: 8),
                _AnimatedStreakNumber(streak: streak),
                const SizedBox(width: 6),
                const Text(
                  'Day Streak',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            if (!streakData.todayComplete && streakData.memberCount > 0) ...[
              const SizedBox(height: 8),
              _InProgressLabel(day: streak + 1),
            ],
            const SizedBox(height: 8),
            Text(
              'Your longest: $best days',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _FireIcon extends StatelessWidget {
  final int streak;

  const _FireIcon({required this.streak});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.local_fire_department,
      size: 28,
      color: streak >= 30 ? Colors.white : _color,
    );

    if (streak >= 30) {
      return ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            colors: [Color(0xFFFF5722), Color(0xFFFFEB3B), Color(0xFFFF5722)],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds);
        },
        child: icon,
      );
    }

    return icon;
  }

  Color get _color {
    if (streak == 0) return const Color(0xFF555555);
    if (streak < 7) return const Color(0xFFFF9800);
    return const Color(0xFFFF5722);
  }
}

class _AnimatedStreakNumber extends StatelessWidget {
  final int streak;

  const _AnimatedStreakNumber({required this.streak});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        '$streak',
        key: ValueKey(streak),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _InProgressLabel extends StatefulWidget {
  final int day;

  const _InProgressLabel({required this.day});

  @override
  State<_InProgressLabel> createState() => _InProgressLabelState();
}

class _InProgressLabelState extends State<_InProgressLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
      child: Text(
        'Day ${widget.day} in progress\u2026',
        style: const TextStyle(
          color: Color(0xFF00E676),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
