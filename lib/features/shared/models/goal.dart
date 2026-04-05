class Goal {
  final String id;
  final String packId;
  final String title;
  final int? targetMinutes;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.packId,
    required this.title,
    this.targetMinutes,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      packId: map['pack_id'] as String,
      title: map['title'] as String,
      targetMinutes: map['target_minutes'] as int?,
      isActive: map['is_active'] as bool? ?? true,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
