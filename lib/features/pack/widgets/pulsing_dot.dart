import 'package:flutter/material.dart';

class PulsingDot extends StatefulWidget {
  final double size;
  final Color color;

  const PulsingDot({
    super.key,
    this.size = 6,
    this.color = const Color(0xFF00E676),
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
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
      opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
      child: Icon(Icons.circle_outlined, size: widget.size, color: widget.color),
    );
  }
}
