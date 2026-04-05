class Pack {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;

  const Pack({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
  });

  factory Pack.fromMap(Map<String, dynamic> map) {
    return Pack(
      id: map['id'] as String,
      name: map['name'] as String,
      inviteCode: map['invite_code'] as String,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
