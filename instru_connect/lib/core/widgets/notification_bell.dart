import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/services/notification_service.dart';

class NotificationBell extends ConsumerWidget {
  final Color iconColor;

  const NotificationBell({super.key, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final service = ref.watch(notificationServiceProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: iconColor),
          onPressed: () => Navigator.pushNamed(context, Routes.notifications),
        ),
        if (uid != null)
          Positioned(
            right: 8,
            top: 8,
            child: StreamBuilder<NotificationCounter>(
              stream: service.streamUserNotificationCounter(uid),
              builder: (context, snapshot) {
                final count = snapshot.data?.unread ?? 0;
                if (count == 0) return const SizedBox.shrink();

                final display = count > 99 ? '99+' : count.toString();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
