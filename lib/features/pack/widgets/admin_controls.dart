import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/pack_member.dart';
import '../../shared/models/profile.dart';
import '../../shared/theme.dart';
import '../pack_provider.dart';

class AdminControls extends ConsumerStatefulWidget {
  final String packId;
  final List<({PackMember member, Profile profile})> members;

  const AdminControls({
    super.key,
    required this.packId,
    required this.members,
  });

  @override
  ConsumerState<AdminControls> createState() => _AdminControlsState();
}

class _AdminControlsState extends ConsumerState<AdminControls> {
  Future<void> _editGoal() async {
    final titleController = TextEditingController();
    final minutesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Goal title (e.g. "20 min Workout")',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Target minutes (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save')),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final minutes = int.tryParse(minutesController.text.trim());
      await ref
          .read(packServiceProvider)
          .setGoal(widget.packId, titleController.text.trim(), minutes);
      ref.invalidate(activeGoalProvider(widget.packId));
    }
  }

  Future<void> _removeMember(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Remove $name from this pack?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Remove', style: TextStyle(color: PackFitTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(packServiceProvider).removeMember(widget.packId, userId);
      ref.invalidate(packMembersProvider(widget.packId));
    }
  }

  Future<void> _deletePack() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pack?'),
        content: const Text(
            'This will permanently delete this pack and all its data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: PackFitTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(packServiceProvider).deletePack(widget.packId);
      ref.invalidate(myPacksProvider);
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Admin', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // Edit Goal
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit, color: PackFitTheme.accent),
          title: const Text('Edit Goal'),
          onTap: _editGoal,
        ),
        // Remove members
        ...widget.members
            .where((m) => !m.member.isAdmin)
            .map((m) => Dismissible(
                  key: Key(m.member.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: PackFitTheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeMember(
                      m.member.userId, m.profile.displayName ?? 'Unknown'),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: m.profile.avatarUrl != null
                          ? NetworkImage(m.profile.avatarUrl!)
                          : null,
                      child: m.profile.avatarUrl == null
                          ? Text(m.profile.initial,
                              style: const TextStyle(fontSize: 12))
                          : null,
                    ),
                    title: Text(m.profile.displayName ?? 'Unknown'),
                    trailing: const Icon(Icons.chevron_left,
                        color: PackFitTheme.textSecondary, size: 18),
                  ),
                )),
        const SizedBox(height: 8),
        // Delete pack
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _deletePack,
            style: OutlinedButton.styleFrom(
              foregroundColor: PackFitTheme.error,
              side: const BorderSide(color: PackFitTheme.error),
            ),
            child: const Text('Delete Pack'),
          ),
        ),
      ],
    );
  }
}
