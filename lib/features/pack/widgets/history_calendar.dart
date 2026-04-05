import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/models/calendar_data.dart';
import '../../shared/models/check_in.dart';
import '../pack_provider.dart';
import 'day_detail_sheet.dart';
import 'pulsing_dot.dart';

class HistoryCalendar extends ConsumerStatefulWidget {
  final String packId;
  final String goalId;
  final DateTime packCreatedAt;

  const HistoryCalendar({
    super.key,
    required this.packId,
    required this.goalId,
    required this.packCreatedAt,
  });

  @override
  ConsumerState<HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends ConsumerState<HistoryCalendar> {
  late int _displayYear;
  late int _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayYear = now.year;
    _displayMonth = now.month;
  }

  String get _calendarKey =>
      '${widget.packId}|${widget.goalId}|$_displayYear|$_displayMonth';

  bool get _canGoBack {
    final created = widget.packCreatedAt;
    if (_displayYear > created.year) return true;
    return _displayYear == created.year && _displayMonth > created.month;
  }

  bool get _canGoForward {
    final now = DateTime.now();
    final nextMonth = _displayMonth == 12 ? 1 : _displayMonth + 1;
    final nextYear = _displayMonth == 12 ? _displayYear + 1 : _displayYear;
    if (nextYear > now.year) return false;
    if (nextYear == now.year && nextMonth > now.month) return false;
    return true;
  }

  void _previousMonth() {
    if (!_canGoBack) return;
    setState(() {
      if (_displayMonth == 1) {
        _displayMonth = 12;
        _displayYear--;
      } else {
        _displayMonth--;
      }
    });
  }

  void _nextMonth() {
    if (!_canGoForward) return;
    setState(() {
      if (_displayMonth == 12) {
        _displayMonth = 1;
        _displayYear++;
      } else {
        _displayMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(packCalendarProvider(_calendarKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Text('History',
              style: Theme.of(context).textTheme.titleMedium),
        ),

        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left,
                  color: _canGoBack ? Colors.white : const Color(0xFF444444)),
              onPressed: _canGoBack ? _previousMonth : null,
            ),
            Text(
              DateFormat('MMMM yyyy')
                  .format(DateTime(_displayYear, _displayMonth)),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right,
                  color:
                      _canGoForward ? Colors.white : const Color(0xFF444444)),
              onPressed: _canGoForward ? _nextMonth : null,
            ),
          ],
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF666666)))),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Calendar grid
        calendarAsync.when(
          loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              const Center(child: Text('Error loading calendar')),
          data: (calendarData) => _buildGrid(calendarData),
        ),
      ],
    );
  }

  Widget _buildGrid(CalendarData data) {
    final firstDay = DateTime(data.year, data.month, 1);
    final daysInMonth = DateTime(data.year, data.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // Monday = 1
    final leadingEmpty = startWeekday - 1;
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: daysInMonth + leadingEmpty,
        itemBuilder: (context, index) {
          if (index < leadingEmpty) return const SizedBox();

          final day = index - leadingEmpty + 1;
          final date = DateTime(data.year, data.month, day);
          final status = data.getStatusForDate(date);
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          return GestureDetector(
            onTap: status == DayStatus.future || status == DayStatus.noGoal
                ? null
                : () => _showDayDetail(date, data),
            child:
                _DayCell(day: day, status: status, isToday: isToday),
          );
        },
      ),
    );
  }

  void _showDayDetail(DateTime date, CalendarData data) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dayCheckIns = data.checkInsByDate[key] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DayDetailSheet(
        date: date,
        checkIns: dayCheckIns,
        memberCount: data.memberCount,
        packId: widget.packId,
        goalTitle: null, // Will be fetched inside the sheet
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DayStatus status;
  final bool isToday;

  const _DayCell(
      {required this.day, required this.status, required this.isToday});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case DayStatus.complete:
        bgColor = const Color(0xFF00E676).withOpacity(0.2);
        textColor = const Color(0xFF00E676);
        break;
      case DayStatus.missed:
        bgColor = const Color(0xFFFF5252).withOpacity(0.15);
        textColor = const Color(0xFFFF5252);
        break;
      case DayStatus.inProgress:
        bgColor = const Color(0xFF00E676).withOpacity(0.08);
        textColor = Colors.white;
        break;
      case DayStatus.future:
      case DayStatus.noGoal:
        bgColor = Colors.transparent;
        textColor = const Color(0xFF444444);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day',
                style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500)),
            if (status == DayStatus.complete)
              const Icon(Icons.circle, size: 6, color: Color(0xFF00E676)),
            if (status == DayStatus.missed)
              const Icon(Icons.circle, size: 6, color: Color(0xFFFF5252)),
            if (status == DayStatus.inProgress)
              const PulsingDot(),
          ],
        ),
      ),
    );
  }
}
