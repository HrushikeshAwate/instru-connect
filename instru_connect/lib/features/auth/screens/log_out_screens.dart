import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/config/routes/route_names.dart'; // or Routes

class showLogoutDialog extends StatelessWidget {
  const showLogoutDialog({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
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
                onPressed: () => Navigator.pop(context, false),
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
                onPressed: () => Navigator.pop(context, true),
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
          Routes.login, // or RouteNames.login
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),

            Icon(
              Icons.logout,
              size: 72,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),

            Text(
              'Sign out of your account',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            Text(
              'You will need to sign in again to access the app.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _handleLogout(context),
              child: const Text('Logout'),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
