import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../shared/platform_utils.dart';
import '../shared/theme.dart';
import 'widgets/sign_in_buttons.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Spacer(flex: 3),
                // Logo / Title
                Text(
                  'PackFit',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontSize: 48, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Group Fitness Goals',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PackFitTheme.textSecondary,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 48),
                const AppleSignInButton(),
                const SizedBox(height: 16),
                const GoogleSignInButton(),
                const Spacer(flex: 2),
                Text(
                  'Train together. Stay accountable.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PackFitTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
