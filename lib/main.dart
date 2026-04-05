import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'features/shared/constants.dart';
import 'features/shared/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: PackFitApp()));
}

class PackFitApp extends ConsumerWidget {
  const PackFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PackFit: Group Fitness Goals',
      theme: PackFitTheme.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
