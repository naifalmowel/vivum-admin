import 'package:flutter/material.dart';

class AppProvider extends InheritedWidget {
  final String lang;
  final ThemeMode themeMode;
  final VoidCallback onToggleLang;
  final VoidCallback onToggleTheme;

  const AppProvider({
    super.key,
    required this.lang,
    required this.themeMode,
    required this.onToggleLang,
    required this.onToggleTheme,
    required super.child,
  });

  static AppProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppProvider>()!;
  }

  bool get isAr => lang == 'ar';
  bool get isDark => themeMode == ThemeMode.dark;

  String t(String key) {
    return (isAr ? _ar[key] : _en[key]) ?? _en[key] ?? key;
  }

  @override
  bool updateShouldNotify(AppProvider old) => 
      old.lang != lang || old.themeMode != themeMode;

  static const _en = {
    'auth.login': 'Login',
    'auth.email': 'Email',
    'auth.password': 'Password',
    'auth.welcome': 'Welcome Back',
    'auth.slogan': 'Your future starts here. Integrated dashboard for efficient management.',
    'auth.subtitle': 'Enter your credentials to access your dashboard',
    'auth.forgot_password': 'Forgot password?',
    'auth.login_btn': 'Sign In',
    'auth.footer': '© 2026 VIVUM Tech. All rights reserved.',
    'dash.overview': 'Overview',
    'dash.projects': 'Projects',
    'dash.messages': 'Messages',
    'dash.logout': 'Logout',
    'dash.users': 'User Management',
    'dash.total_projects': 'Total Projects',
    'dash.total_messages': 'Total Messages',
    'dash.total_users': 'Total Users',
    'proj.add': 'Add Project',
    'proj.edit': 'Edit Project',
    'proj.name': 'Project Name',
    'proj.desc': 'Description',
    'proj.image': 'Project Image',
    'msg.from': 'From',
    'msg.date': 'Date',
  };

  static const _ar = {
    'auth.login': 'تسجيل الدخول',
    'auth.email': 'البريد الإلكتروني',
    'auth.password': 'كلمة المرور',
    'auth.welcome': 'مرحباً بك مجدداً',
    'auth.slogan': 'مستقبلك يبدأ هنا. لوحة تحكم متكاملة لإدارة أعمالك بكفاءة وذكاء.',
    'auth.subtitle': 'أدخل بياناتك للوصول إلى لوحة التحكم الخاصة بك',
    'auth.forgot_password': 'نسيت كلمة المرور؟',
    'auth.login_btn': 'دخول النظام',
    'auth.footer': '© 2026 VIVUM Tech. جميع الحقوق محفوظة.',
    'dash.overview': 'نظرة عامة',
    'dash.projects': 'المشاريع',
    'dash.messages': 'الرسائل',
    'dash.logout': 'تسجيل الخروج',
    'dash.users': 'إدارة المستخدمين',
    'dash.total_projects': 'إجمالي المشاريع',
    'dash.total_messages': 'إجمالي الرسائل',
    'dash.total_users': 'إجمالي المستخدمين',
    'proj.add': 'إضافة مشروع',
    'proj.edit': 'تعديل مشروع',
    'proj.name': 'اسم المشروع',
    'proj.desc': 'الوصف',
    'proj.image': 'صورة المشروع',
    'msg.from': 'من',
    'msg.date': 'التاريخ',
  };
}
