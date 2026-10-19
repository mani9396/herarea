import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:her_area/core/routing/app_router.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:her_area/firebase_options.dart';
import 'package:shared/shared.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:her_area/core/routing/route_paths.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService().initialize(
      onNotificationTap: (actionUrl) async {
        final url = actionUrl.trim();
        if (url.isEmpty || url == '/' || url == RoutePaths.splash) {
          appRouter.go(RoutePaths.home);
          return;
        }
        if (url.startsWith('http://') || url.startsWith('https://')) {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          return;
        }
        if (url == RoutePaths.home ||
            url == RoutePaths.categories ||
            url == RoutePaths.nearby ||
            url == RoutePaths.games ||
            url == RoutePaths.messages ||
            url == RoutePaths.profile) {
          appRouter.go(url);
        } else {
          appRouter.push(url);
        }
      },
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
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
