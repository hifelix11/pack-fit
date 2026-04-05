class Profile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'display_name': displayName,
        'avatar_url': avatarUrl,
      };

  String get initial =>
      (displayName?.isNotEmpty == true) ? displayName![0].toUpperCase() : '?';
}
