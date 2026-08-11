import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart'; // Add this
import 'services/config_service.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/user_provider.dart'; // Add this
import 'screens/login_screen.dart';
import 'screens/shell/dashboard_shell.dart';
import 'screens/overview/overview_screen.dart';
import 'screens/projects/projects_manager_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/users/users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.init();
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en', null);
  runApp(const VivumDashboardApp());
}

final _router = GoRouter(
  initialLocation: '/overview',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoggingIn = state.matchedLocation == '/login';
    if (!loggedIn && !isLoggingIn) return '/login';
    if (loggedIn && isLoggingIn) return '/overview';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => DashboardShell(child: child),
      routes: [
        GoRoute(path: '/overview', builder: (c, s) => const OverviewScreen()),
        GoRoute(path: '/projects', builder: (c, s) => const ProjectsManagerScreen()),
        GoRoute(path: '/messages', builder: (c, s) => const MessagesScreen()),
        GoRoute(path: '/users', builder: (c, s) => const UsersScreen()),
      ],
    ),
  ],
);

class VivumDashboardApp extends StatefulWidget {
  const VivumDashboardApp({super.key});

  @override
  State<VivumDashboardApp> createState() => _VivumDashboardAppState();
}

class _VivumDashboardAppState extends State<VivumDashboardApp> {
  String _lang = 'en';
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleLang() => setState(() => _lang = _lang == 'en' ? 'ar' : 'en');
  void _toggleTheme() => setState(() => _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: AppProvider(
        lang: _lang,
        themeMode: _themeMode,
        onToggleLang: _toggleLang,
        onToggleTheme: _toggleTheme,
        child: Builder(
          builder: (context) {
            final lp = AppProvider.of(context);
            return MaterialApp.router(
            title: 'VIVUM Admin Dashboard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: lp.themeMode,
            routerConfig: _router,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad},
            ),
          );
        },
      ),
    ));
  }
}
