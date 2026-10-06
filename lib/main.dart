import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/supabase_client.dart';
import 'screens/admin_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/browse_screen.dart';
import 'screens/chat_screens.dart';
import 'screens/create_project_screen.dart';
import 'screens/money_screens.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/project_screen.dart';
import 'screens/shell.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) => const ProviderScope(child: AegisApp()),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/role', builder: (_, __) => const RoleScreen()),
    GoRoute(path: '/home', builder: (_, __) => const Shell()),

    GoRoute(
      path: '/project/:id',
      builder: (_, state) => ProjectScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/post', builder: (_, __) => const CreateProjectScreen()),
    GoRoute(
      path: '/deposit/:id',
      builder: (_, state) => DepositScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (_, state) => ChatScreen(projectId: state.pathParameters['id']!),
    ),

    GoRoute(
      path: '/browse-jobs',
      builder: (_, __) => const BrowseScreen(initialTab: 0, standalone: true),
    ),
    GoRoute(
      path: '/browse-people',
      builder: (_, __) => const BrowseScreen(initialTab: 1, standalone: true),
    ),

    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
    GoRoute(path: '/verification', builder: (_, __) => const VerificationScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
  ],
);

class AegisApp extends StatelessWidget {
  const AegisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aegis',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}