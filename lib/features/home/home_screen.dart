import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../pack/pack_provider.dart';
import '../shared/platform_utils.dart';
import '../shared/theme.dart';
import 'widgets/create_pack_sheet.dart';
import 'widgets/join_pack_sheet.dart';
import 'widgets/pack_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final packsAsync = ref.watch(myPacksProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? webMaxContentWidth : double.infinity,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myPacksProvider);
                ref.invalidate(profileProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // ── Top greeting ───────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showProfileMenu(context, ref),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  PackFitTheme.accent.withAlpha(40),
                              backgroundImage: profile?.avatarUrl != null
                                  ? NetworkImage(profile!.avatarUrl!)
                                  : null,
                              child: profile?.avatarUrl == null
                                  ? Text(
                                      profile?.initial ?? '?',
                                      style: const TextStyle(
                                        color: PackFitTheme.accent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hey, ${profile?.displayName ?? 'there'}',
                              style: Theme.of(context).textTheme.headlineMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Section title ──────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Text(
                        'My Packs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),

                  // ── Pack list ──────────────────────────
                  packsAsync.when(
                    data: (packs) {
                      if (packs.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.group_outlined,
                                    size: 64,
                                    color: PackFitTheme.textSecondary
                                        .withAlpha(80)),
                                const SizedBox(height: 16),
                                Text(
                                  'No packs yet.\nCreate or join one below.',
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => PackCard(
                            pack: packs[index],
                            onTap: () =>
                                context.push('/pack/${packs[index].id}'),
                          ),
                          childCount: packs.length,
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('Error: $e',
                            style: const TextStyle(
                                color: PackFitTheme.error)),
                      ),
                    ),
                  ),

                  // ── Action buttons ─────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showCreateSheet(context),
                              child: const Text('Create a Pack'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _showJoinSheet(context),
                              child: const Text('Join a Pack'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.push('/timer'),
                            child: const Text('Quick Timer'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Web: "Get the App" link ────────────
                  if (kIsWeb)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32, top: 8),
                        child: Center(
                          child: Text(
                            'Get the App on iOS & Android',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: PackFitTheme.textSecondary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreatePackSheet(),
    );
  }

  void _showJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const JoinPackSheet(),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/onboarding');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: PackFitTheme.error),
              title: const Text('Sign Out',
                  style: TextStyle(color: PackFitTheme.error)),
              onTap: () async {
                Navigator.of(ctx).pop();
                await ref.read(authServiceProvider).signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
