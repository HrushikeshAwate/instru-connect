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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: colorScheme.error),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?\nYou will need to sign in again.',
          style: theme.textTheme.bodyMedium,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    await AuthService().signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.login,
        (route) => false,
      );
    }
  }
}
