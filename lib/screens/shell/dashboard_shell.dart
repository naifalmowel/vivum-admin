import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      drawer: isMobile ? _Sidebar(lp: lp) : null,
      appBar: AppBar(
        title: const Text('VIVUM Admin'),
        actions: [
          IconButton(
            icon: Icon(lp.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: lp.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: lp.onToggleLang,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirm(context, lp),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile) _Sidebar(lp: lp),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final AppProvider lp;
  const _Sidebar({required this.lp});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);
    
    return Material(
      color: theme.cardColor,
      elevation: 0,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 16),
            const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 32),
            _NavTile(
              icon: Icons.dashboard_outlined,
              title: lp.t('dash.overview'),
              isActive: location == '/overview',
              onTap: () => context.go('/overview'),
            ),
            _NavTile(
              icon: Icons.work_outline,
              title: lp.t('dash.projects'),
              isActive: location == '/projects',
              onTap: () => context.go('/projects'),
            ),
            _NavTile(
              icon: Icons.message_outlined,
              title: lp.t('dash.messages'),
              isActive: location == '/messages',
              onTap: () => context.go('/messages'),
            ),
            _NavTile(
              icon: Icons.people_outline,
              title: lp.t('dash.users'),
              isActive: location == '/users',
              onTap: () => context.go('/users'),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(lp.t('dash.logout'), style: const TextStyle(color: Colors.redAccent)),
              onTap: () => _showLogoutConfirm(context, lp),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      selected: isActive,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
      leading: Icon(icon, color: isActive ? colorScheme.primary : null),
      title: Text(
        title, 
        style: TextStyle(
          color: isActive ? colorScheme.primary : null, 
          fontWeight: isActive ? FontWeight.bold : null,
        ),
      ),
      onTap: onTap,
    );
  }
}

Future<void> _showLogoutConfirm(BuildContext context, AppProvider lp) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(lp.t('dash.logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
      content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('خروج'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }
}
