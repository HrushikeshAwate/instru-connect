import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/config/routes/route_names.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final bool? confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: colorScheme.error),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        content: const Text(
          'Are you sure you want to logout?\n\n'
          'This will clear your local app cache and sign you out securely.',
          style: TextStyle(fontSize: 14),
        ),

        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    // Loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await AuthService().signOut();

      if (context.mounted) {
        Navigator.pop(context); // remove loader
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.splash, // 🔑 ALWAYS splash
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('Logout Error: $e');
    }
  }
}
