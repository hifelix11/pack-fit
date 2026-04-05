import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import '../shared/models/profile.dart';

// ── Auth service singleton ─────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

// ── Current Supabase auth state ────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

// ── Current user (nullable) ────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).whenData((s) => s.session?.user).value;
});

// ── Current user profile from the `profiles` table ─────
final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return Profile.fromMap(data);
});

// ── Whether onboarding (name input) is needed ──────────
final needsOnboardingProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return profile == null ||
      profile.displayName == null ||
      profile.displayName!.isEmpty;
});
