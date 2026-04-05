import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_provider.dart';
import '../shared/platform_utils.dart';
import '../shared/theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from OAuth metadata.
    final authService = ref.read(authServiceProvider);
    final name = authService.displayNameFromMeta;
    if (name != null && name.isNotEmpty) {
      _nameController.text = name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final authService = ref.read(authServiceProvider);
      final avatarUrl = authService.avatarUrlFromMeta;

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'display_name': name,
        'avatar_url': avatarUrl,
      });

      // Invalidate the profile provider so downstream sees the new name.
      ref.invalidate(profileProvider);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final avatarUrl = authService.avatarUrlFromMeta;
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : '?';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? webMaxContentWidth : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Text(
                  'Welcome to PackFit',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: PackFitTheme.accent.withAlpha(40),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(initial,
                          style: const TextStyle(
                              fontSize: 36, color: PackFitTheme.accent))
                      : null,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'What should we call you?',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().isEmpty || _saving
                        ? null
                        : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Let's go"),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
