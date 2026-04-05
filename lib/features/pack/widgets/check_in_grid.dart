import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/models/check_in.dart';
import '../../shared/models/pack_member.dart';
import '../../shared/models/profile.dart';
import '../../shared/theme.dart';

class CheckInGrid extends StatelessWidget {
  final List<({PackMember member, Profile profile})> members;
  final List<CheckIn> todayCheckIns;

  const CheckInGrid({
    super.key,
    required this.members,
    required this.todayCheckIns,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: members.map((m) {
        final checkIn = todayCheckIns
            .where((c) => c.userId == m.member.userId)
            .firstOrNull;
        final isDone = checkIn != null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: PackFitTheme.accent.withAlpha(40),
                backgroundImage: m.profile.avatarUrl != null
                    ? NetworkImage(m.profile.avatarUrl!)
                    : null,
                child: m.profile.avatarUrl == null
                    ? Text(m.profile.initial,
                        style: const TextStyle(
                            fontSize: 14, color: PackFitTheme.accent))
                    : null,
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Text(
                  m.profile.displayName ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              // Status
              if (isDone) ...[
                Text(
                  'checked in at ${DateFormat.Hm().format(checkIn.checkedAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: PackFitTheme.textSecondary,
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.check_circle,
                    color: PackFitTheme.accent, size: 22),
              ] else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
