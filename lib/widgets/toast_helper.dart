import 'package:flutter/material.dart';

class VivumToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        width: 300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
