import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/pack/pack_detail_screen.dart';
import '../features/timer/timer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);
  final needsOnboarding = ref.watch(needsOnboardingProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuthenticated = user != null;
      final isSignIn = state.matchedLocation == '/sign-in';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isSignIn) return '/sign-in';
      if (isAuthenticated && isSignIn) {
        return needsOnboarding ? '/onboarding' : '/home';
      }
      if (isAuthenticated && needsOnboarding && !isOnboarding) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/pack/:packId',
        builder: (context, state) {
          final packId = state.pathParameters['packId']!;
          return PackDetailScreen(packId: packId);
        },
      ),
      GoRoute(
        path: '/timer',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'];
          final packId = state.uri.queryParameters['packId'];
          return TimerScreen(sessionId: sessionId, packId: packId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
