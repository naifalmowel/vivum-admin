import 'package:flutter/material.dart';
import '../providers/app_provider.dart';

class AppBarActions extends StatelessWidget {
  final bool showLogout;
  final VoidCallback? onLogout;
  final Color? iconColor;

  const AppBarActions({
    super.key,
    this.showLogout = false,
    this.onLogout,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Theme Toggle
        _buildActionButton(
          icon: Icon(lp.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          onTap: lp.onToggleTheme,
          tooltip: lp.isDark ? 'Light Mode' : 'Dark Mode',
          theme: theme,
        ),
        const SizedBox(width: 8),

        // Language Dropdown
        _buildLanguageDropdown(lp, theme),

        if (showLogout) ...[
          const SizedBox(width: 8),
          _buildActionButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onTap: onLogout,
            tooltip: lp.t('dash.logout'),
            theme: theme,
            isLogout: true,
          ),
        ],
      ],
    );
  }

  Widget _buildLanguageDropdown(AppProvider lp, ThemeData theme) {
    final bgColor = iconColor != null 
        ? Colors.white.withValues(alpha: 0.1) 
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    
    final borderColor = iconColor != null 
        ? Colors.white.withValues(alpha: 0.1) 
        : theme.colorScheme.outline.withValues(alpha: 0.1);

    return PopupMenuButton<String>(
      tooltip: lp.isAr ? 'تغيير اللغة' : 'Change Language',
      onSelected: (String lang) {
        if (lp.lang != lang) lp.onToggleLang();
      },
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupItem('en', 'English', lp.lang == 'en'),
        _buildPopupItem('ar', 'العربية', lp.lang == 'ar'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded, 
              size: 20, 
              color: iconColor ?? theme.colorScheme.onSurface
            ),
            const SizedBox(width: 8),
            Text(
              lp.lang == 'ar' ? 'العربية' : 'English',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: iconColor ?? theme.colorScheme.onSurface,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded, 
              color: iconColor ?? theme.colorScheme.onSurface
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String label, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.teal : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required VoidCallback? onTap,
    required String tooltip,
    required ThemeData theme,
    bool isLogout = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: iconColor != null 
              ? Colors.white.withValues(alpha: 0.1) 
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor != null 
                ? Colors.white.withValues(alpha: 0.1) 
                : theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: IconButton(
          icon: icon,
          onPressed: onTap,
          iconSize: 20,
          color: iconColor ?? (isLogout ? Colors.redAccent : theme.colorScheme.onSurface),
          visualDensity: VisualDensity.compact,
          splashRadius: 24,
        ),
      ),
    );
  }
}
