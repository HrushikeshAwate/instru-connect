import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED for cache clearing
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
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?\nThis will clear your local app cache.',
          style: TextStyle(fontSize: 14),
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
    // Show a loading overlay so the user doesn't tap multiple times
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. CLEAR THE CACHE (The Fix for your 70MB issue)
      // Terminate stops current listeners, clearPersistence deletes the local DB file
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.clearPersistence();

      // 2. SIGN OUT
      await AuthService().signOut();

      if (context.mounted) {
        // Remove the loading indicator and go to login
        Navigator.of(context).pop();
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // Remove loader on error
      debugPrint("Logout Error: $e");
    }
  }
}