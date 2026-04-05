class CheckIn {
  final String id;
  final String goalId;
  final String userId;
  final String checkedDate;
  final DateTime checkedAt;

  const CheckIn({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.checkedDate,
    required this.checkedAt,
  });

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      userId: map['user_id'] as String,
      checkedDate: map['checked_date'] as String,
      checkedAt: DateTime.parse(map['checked_at'] as String),
    );
  }
}
