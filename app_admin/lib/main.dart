import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_admin/firebase_options.dart';
import 'package:app_admin/core/routing/admin_app_router.dart';
import 'package:shared/shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService().initialize(
      onNotificationTap: (actionUrl) {
        if (actionUrl.isNotEmpty) {
          adminAppRouter.push(actionUrl);
        }
      },
    );
  } catch (e) {
    debugPrint('Firebase init error in Admin App: $e');
  }
  runApp(const ProviderScope(child: HerAreaAdminApp()));
}

class HerAreaAdminApp extends StatelessWidget {
  const HerAreaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HER AREA — Marketplace Admin Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: adminAppRouter,
    );
  }
}
