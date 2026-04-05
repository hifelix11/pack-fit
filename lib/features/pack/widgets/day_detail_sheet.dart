import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/check_in.dart';

class DayDetailSheet extends StatelessWidget {
  final DateTime date;
  final List<CheckIn> checkIns;
  final int memberCount;
  final String packId;
  final String? goalTitle;

  const DayDetailSheet({
    super.key,
    required this.date,
    required this.checkIns,
    required this.memberCount,
    required this.packId,
    this.goalTitle,
  });

  @override
  Widget build(BuildContext context) {
    final checkedUserIds = checkIns.map((c) => c.userId).toSet();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);
    final isComplete = checkIns.length >= memberCount && memberCount > 0;

    return FutureBuilder(
      future: Supabase.instance.client
          .from('pack_members')
          .select('user_id, profiles:user_id(display_name, avatar_url)')
          .eq('pack_id', packId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final members = snapshot.data as List;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
              if (goalTitle != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text('Goal: $goalTitle',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF888888))),
                ),
              ],
              const SizedBox(height: 16),
              ...members.map((member) {
                final userId = member['user_id'] as String;
                final profile =
                    member['profiles'] as Map<String, dynamic>? ?? {};
                final name =
                    profile['display_name'] as String? ?? 'Unknown';
                final didCheckIn = checkedUserIds.contains(userId);
                final checkIn = checkIns
                    .where((c) => c.userId == userId)
                    .firstOrNull;
                final timeStr = checkIn != null
                    ? DateFormat('HH:mm')
                        .format(checkIn.checkedAt.toLocal())
                    : '\u2014';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        didCheckIn ? Icons.check_circle : Icons.cancel,
                        color: didCheckIn
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF5252),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15))),
                      Text(timeStr,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 13)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  isComplete
                      ? 'All $memberCount completed \u2713'
                      : '${checkIns.length}/$memberCount completed',
                  style: TextStyle(
                    fontSize: 14,
                    color: isComplete
                        ? const Color(0xFF00E676)
                        : const Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
