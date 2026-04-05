import 'package:flutter/material.dart';

import '../../shared/models/profile.dart';
import '../../shared/theme.dart';

class ParticipantAvatars extends StatelessWidget {
  final List<Profile> participants;

  const ParticipantAvatars({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: participants.map((p) {
        return Tooltip(
          message: p.displayName ?? 'Unknown',
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: PackFitTheme.accent.withAlpha(40),
              backgroundImage:
                  p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
              child: p.avatarUrl == null
                  ? Text(
                      p.initial,
                      style: const TextStyle(
                          fontSize: 11, color: PackFitTheme.accent),
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
