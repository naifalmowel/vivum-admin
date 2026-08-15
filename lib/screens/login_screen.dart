import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_container.dart';
import '../widgets/toast_helper.dart';
import '../widgets/app_bar_actions.dart';
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
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final lp = AppProvider.of(context);

    if (email.isEmpty || password.isEmpty) {
      VivumToast.show(context, lp.t('auth.err.empty'), isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        if (email == 'naif.almowel@gmail.com') {
          if (mounted) context.go('/overview');
          return;
        }

        final userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();

        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data();
          final bool isActive = userData['isActive'] ?? false;

          if (!isActive) {
            await FirebaseAuth.instance.signOut();
            if (mounted) VivumToast.show(context, lp.t('auth.err.inactive'), isError: true);
            return;
          }
        }

        if (mounted) context.go('/overview');
      }
    } on FirebaseAuthException catch (e) {
      String messageKey = 'auth.err.unknown';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        messageKey = 'auth.err.invalid';
      } else if (e.code == 'wrong-password') {
        messageKey = 'auth.err.wrong_pass';
      } else if (e.code == 'user-disabled') {
        messageKey = 'auth.err.disabled';
      } else if (e.code == 'invalid-email') {
        messageKey = 'auth.err.invalid_email';
      } else if (e.code == 'too-many-requests') {
        messageKey = 'auth.err.too_many';
      }

      if (mounted) VivumToast.show(context, lp.t(messageKey), isError: true);
    } catch (e) {
      if (mounted) VivumToast.show(context, '${lp.t('auth.err.unknown')}: $e', isError: true);
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

    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
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
                // Mobile View - Shared style with Desktop side
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        left: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: GlassContainer(
                            blur: 15,
                            opacity: 0.1,
                            padding: const EdgeInsets.all(32),
                            child: _buildLoginForm(lp, theme, isMobile: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          Positioned(
            top: 20,
            right: 20,
            child: AppBarActions(
              iconColor: MediaQuery.of(context).size.width <= 900 ? Colors.white : null,
            ),
          ),
        ],
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
            colorScheme.primary.withValues(alpha: 0.8),
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
                color: Colors.white.withValues(alpha: 0.05),
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
                color: Colors.white.withValues(alpha: 0.05),
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
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
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
                          color: colorScheme.secondary.withValues(alpha: 0.5),
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
                child: const Icon(Icons.dashboard_customize_rounded, size: 70, color: Colors.white)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.bounceOut),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'VIVUM',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
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
                color: isMobile ? Colors.white : textTheme.headlineMedium?.color,
              ),
            ).animate().fade().slideY(begin: 0.1),
            const SizedBox(height: 8),
            Text(
              lp.t('auth.subtitle'),
              style: textTheme.bodyLarge?.copyWith(
                color: isMobile ? Colors.white70 : textTheme.bodyLarge?.color,
              ),
            ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 48),

            // Email Field
            _buildLabel(lp.t('auth.email'), theme, isMobile: isMobile),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isMobile ? Colors.white : theme.textTheme.bodyLarge?.color,
              ),
              textInputAction: TextInputAction.next,
              decoration: _buildInputDecoration(
                hint: 'name@company.com',
                icon: Icons.alternate_email_rounded,
                theme: theme,
                isMobile: isMobile,
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Password Field
            _buildLabel(lp.t('auth.password'), theme, isMobile: isMobile),
            const SizedBox(height: 10),
            TextField(
              controller: _passController,
              obscureText: _isObscured,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isMobile ? Colors.white : theme.textTheme.bodyLarge?.color,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              decoration: _buildInputDecoration(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                theme: theme,
                isMobile: isMobile,
                suffix: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: isMobile ? Colors.white70 : theme.hintColor,
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
                    color: isMobile ? Colors.white : colorScheme.primary,
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
                  backgroundColor: isMobile ? Colors.white : colorScheme.primary,
                  foregroundColor: isMobile ? colorScheme.primary : colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? CircularProgressIndicator(color: isMobile ? colorScheme.primary : colorScheme.onPrimary, strokeWidth: 3)
                    : Text(
                        lp.t('auth.login_btn'),
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w800,
                          color: isMobile ? colorScheme.primary : colorScheme.onPrimary,
                        ),
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

  Widget _buildLabel(String label, ThemeData theme, {bool isMobile = false}) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: isMobile ? Colors.white : theme.textTheme.titleSmall?.color,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required ThemeData theme,
    Widget? suffix,
    bool isMobile = false,
  }) {
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: isMobile ? Colors.white60 : theme.hintColor,
      ),
      prefixIcon: Icon(icon, color: isMobile ? Colors.white : colorScheme.primary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: isMobile ? Colors.white.withValues(alpha: 0.1) : theme.cardTheme.color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isMobile ? Colors.white24 : colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isMobile ? Colors.white24 : colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isMobile ? Colors.white : colorScheme.primary, width: 2),
      ),
    );
  }
}
