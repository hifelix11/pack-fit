import 'package:flutter/material.dart';

import '../../shared/models/check_in.dart';
import '../../shared/theme.dart';

/// A simple grid showing the last 30 days with colour-coded dots.
class HistoryCalendar extends StatelessWidget {
  final List<CheckIn> checkIns;
  final int memberCount;

  const HistoryCalendar({
    super.key,
    required this.checkIns,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    // Build a map of date → check-in count.
    final Map<String, int> dayMap = {};
    for (final c in checkIns) {
      dayMap[c.checkedDate] = (dayMap[c.checkedDate] ?? 0) + 1;
    }

    final today = DateTime.now();
    final days = List.generate(30, (i) {
      final date = today.subtract(Duration(days: 29 - i));
      return date.toIso8601String().substring(0, 10);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 30 Days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: days.map((dateStr) {
            final count = dayMap[dateStr] ?? 0;
            final complete = count >= memberCount && memberCount > 0;
            final isToday = dateStr ==
                today.toIso8601String().substring(0, 10);

            return Tooltip(
              message: dateStr,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: complete
                      ? PackFitTheme.accent
                      : count > 0
                          ? PackFitTheme.accent.withAlpha(60)
                          : Colors.white10,
                  border: isToday
                      ? Border.all(color: PackFitTheme.textPrimary, width: 2)
                      : null,
                ),
                child: complete
                    ? const Icon(Icons.check, size: 14, color: Colors.black)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
