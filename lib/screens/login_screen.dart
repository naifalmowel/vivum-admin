import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_container.dart';
import '../widgets/toast_helper.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _isObscured = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      VivumToast.show(context, 'يرجى إدخال البريد الإلكتروني وكلمة المرور', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      if (mounted) context.go('/overview');
    } catch (e) {
      if (mounted) {
        VivumToast.show(context, 'خطأ: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppProvider.of(context).t('auth.forgot_password'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أدخل بريدك الإلكتروني لاستعادة كلمة المرور'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: _buildInputDecoration(
                hint: 'name@company.com',
                icon: Icons.email_outlined,
                theme: theme,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: emailCtrl.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    VivumToast.show(context, 'تم إرسال رابط استعادة كلمة المرور');
                  }
                } catch (e) {
                  if (context.mounted) {
                    VivumToast.show(context, 'خطأ: $e', isError: true);
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = AppProvider.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              textDirection: TextDirection.ltr,
              children: [
                // Left Side: Professional Content
                Expanded(
                  flex: 5,
                  child: _buildDecorativeSide(theme),
                ),
                // Right Side: Login Form
                Expanded(
                  flex: 4,
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: _buildLoginForm(lp, theme),
                  ),
                ),
              ],
            );
          } else {
            // Mobile View
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [VivumColors.darkBG, colorScheme.surface]
                      : [VivumColors.lightBG, VivumColors.lightBGAlt],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(32),
                    child: _buildLoginForm(lp, theme, isMobile: true),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDecorativeSide(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.dashboard_customize_rounded, size: 100, color: colorScheme.onPrimary)
                      .animate()
                      .fade(duration: 800.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 32),
                  Text(
                    'VIVUM DASHBOARD',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                  ).animate().fade(delay: 200.ms, duration: 800.ms).slideX(begin: -0.2),
                  const SizedBox(height: 16),
                  Text(
                    AppProvider.of(context).t('auth.slogan'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.9),
                      fontWeight: FontWeight.w300,
                    ),
                  ).animate().fade(delay: 400.ms, duration: 800.ms).slideX(begin: -0.2),
                  const SizedBox(height: 48),
                  Container(
                    height: 6,
                    width: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.secondary.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 600.ms).scaleX(alignment: Alignment.centerLeft),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AppProvider lp, ThemeData theme, {bool isMobile = false}) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              Center(
                child: Icon(Icons.dashboard_customize_rounded, size: 70, color: colorScheme.primary)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.bounceOut),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'VIVUM',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
            Text(
              lp.t('auth.login'),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ).animate().fade().slideY(begin: 0.1),
            const SizedBox(height: 8),
            Text(
              lp.t('auth.subtitle'),
              style: textTheme.bodyLarge,
            ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 48),

            // Email Field
            _buildLabel(lp.t('auth.email'), theme),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textInputAction: TextInputAction.next,
              decoration: _buildInputDecoration(
                hint: 'name@company.com',
                icon: Icons.alternate_email_rounded,
                theme: theme,
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Password Field
            _buildLabel(lp.t('auth.password'), theme),
            const SizedBox(height: 10),
            TextField(
              controller: _passController,
              obscureText: _isObscured,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              decoration: _buildInputDecoration(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                theme: theme,
                suffix: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: theme.hintColor,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
              ),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  lp.t('auth.forgot_password'),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 3)
                    : Text(
                        lp.t('auth.login_btn'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
              ),
            ).animate().fade(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 32),
            
            if (!isMobile)
              Center(
                child: Text(
                  lp.t('auth.footer'),
                  style: textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required ThemeData theme,
    Widget? suffix,
  }) {
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.hintColor,
      ),
      prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.cardTheme.color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }
}
