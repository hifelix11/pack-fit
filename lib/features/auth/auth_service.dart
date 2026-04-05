import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/constants.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Google Sign-In ─────────────────────────────────────
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: webOAuthRedirectUrl,
      );
      return;
    }

    // Native mobile flow
    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? null : googleIosClientId,
      serverClientId: googleWebClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // User cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('Google Sign-In failed: no ID token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // ── Apple Sign-In ──────────────────────────────────────
  Future<void> signInWithApple() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: webOAuthRedirectUrl,
      );
      return;
    }

    // Native Apple Sign-In (iOS)
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign-In failed: no identity token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
    );

    // Apple only sends the name on first sign-in. Save it now.
    final givenName = credential.givenName;
    final familyName = credential.familyName;
    if (givenName != null || familyName != null) {
      final fullName = [givenName, familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      if (fullName.isNotEmpty) {
        await _client.auth.updateUser(UserAttributes(
          data: {'full_name': fullName},
        ));
      }
    }
  }

  // ── Sign Out ───────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Profile helpers ────────────────────────────────────
  String? get displayNameFromMeta {
    final meta = currentUser?.userMetadata;
    if (meta == null) return null;
    return meta['full_name'] as String? ??
        meta['name'] as String? ??
        _buildNameFromParts(meta);
  }

  String? get avatarUrlFromMeta {
    final meta = currentUser?.userMetadata;
    if (meta == null) return null;
    return meta['avatar_url'] as String? ?? meta['picture'] as String?;
  }

  String? _buildNameFromParts(Map<String, dynamic> meta) {
    final given = meta['given_name'] as String? ?? '';
    final family = meta['family_name'] as String? ?? '';
    final full = '$given $family'.trim();
    return full.isNotEmpty ? full : null;
  }
}
