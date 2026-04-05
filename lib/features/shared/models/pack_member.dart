class PackMember {
  final String id;
  final String packId;
  final String userId;
  final String role;
  final DateTime joinedAt;

  const PackMember({
    required this.id,
    required this.packId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  bool get isAdmin => role == 'admin';

  factory PackMember.fromMap(Map<String, dynamic> map) {
    return PackMember(
      id: map['id'] as String,
      packId: map['pack_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }
}
