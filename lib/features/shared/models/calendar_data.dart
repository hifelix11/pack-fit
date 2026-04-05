import 'check_in.dart';

enum DayStatus {
  complete,
  missed,
  inProgress,
  future,
  noGoal,
}

class CalendarData {
  final int year;
  final int month;
  final Map<String, List<CheckIn>> checkInsByDate;
  final int memberCount;
  final DateTime? goalCreatedAt;

  const CalendarData({
    required this.year,
    required this.month,
    required this.checkInsByDate,
    required this.memberCount,
    this.goalCreatedAt,
  });

  DayStatus getStatusForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAfter(today)) return DayStatus.future;

    if (goalCreatedAt != null) {
      final goalDate = DateTime(
          goalCreatedAt!.year, goalCreatedAt!.month, goalCreatedAt!.day);
      if (dateOnly.isBefore(goalDate)) return DayStatus.noGoal;
    }

    final dayCheckIns = checkInsByDate[key];
    if (dayCheckIns == null || dayCheckIns.isEmpty) {
      return DayStatus.missed;
    }
    if (dayCheckIns.length >= memberCount) return DayStatus.complete;
    if (dateOnly == today) return DayStatus.inProgress;
    return DayStatus.missed;
  }
}

class StreakData {
  final int currentStreak;
  final int bestStreak;
  final bool todayComplete;
  final int todayCheckIns;
  final int memberCount;

  const StreakData({
    required this.currentStreak,
    required this.bestStreak,
    required this.todayComplete,
    required this.todayCheckIns,
    required this.memberCount,
  });

  bool get todayInProgress =>
      !todayComplete && todayCheckIns > 0 && memberCount > 0;
}
