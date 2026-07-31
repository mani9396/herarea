import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:her_area/core/routing/app_router.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HerAreaApp()));
}

class HerAreaApp extends ConsumerWidget {
  const HerAreaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch global theme mode state (False = Luxury Blush Light Mode, True = Midnight Dark Mode)
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
