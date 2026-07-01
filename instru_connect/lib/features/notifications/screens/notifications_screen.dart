import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/session/current_user.dart';
import 'package:instru_connect/core/services/notification_service.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:instru_connect/features/attendance/screens/attendance_history_screen.dart';
import 'package:instru_connect/features/batches/screens/manage_batches_screen.dart';
import 'package:instru_connect/features/batches/screens/subject_detail_screen.dart';
import 'package:instru_connect/features/complaints/models/complaint_model.dart';
import 'package:instru_connect/features/complaints/screens/complaint_detail_screen.dart';
import 'package:instru_connect/features/events/screens/event_calendar_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_detail_screen.dart';
import 'package:instru_connect/features/notices/services/notice_service.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/screens/resource_detail_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late final NotificationService _service;
  late final NoticeService _noticeService;
  late final FirebaseFirestore _firestore;
  bool _isMarkingVisibleNotificationsRead = false;

  Future<bool> _confirmDeleteNotification({
    required bool canDeletePostedNotification,
  }) {
    return showDestructiveConfirmationDialog(
      context: context,
      title: canDeletePostedNotification
          ? 'Delete Posted Notification?'
          : 'Delete Notification?',
      message: canDeletePostedNotification
          ? 'This will permanently delete the notification entry for the posted notice. The deleted notification cannot be recovered.'
          : 'This notification will be permanently deleted and cannot be recovered.',
    );
  }

  Future<bool> _confirmClearAllNotifications() {
    return showDestructiveConfirmationDialog(
      context: context,
      title: 'Clear All Notifications?',
      message:
          'This will permanently delete all notifications from this list. They cannot be recovered once cleared.',
      confirmLabel: 'Clear All',
    );
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final type = (notification['type'] ?? '').toString();
    final noticeId = (notification['noticeId'] ?? '').toString();
    final rawData = notification['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(
            rawData.map((key, value) => MapEntry(key.toString(), value)),
          )
        : <String, dynamic>{};

    if (noticeId.isNotEmpty) {
      final notice = await _noticeService.fetchNoticeById(noticeId);
      if (!mounted) return;
      if (notice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This notice is no longer available.')),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
      );
      return;
    }

    final complaintId = (data['complaintId'] ?? '').toString();
    if (complaintId.isNotEmpty &&
        type.startsWith('complaint_') &&
        type != 'complaint_deleted') {
      final complaintDoc = await _firestore
          .collection('complaints')
          .doc(complaintId)
          .get();
      if (!mounted) return;
      if (!complaintDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This complaint is no longer available.'),
          ),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComplaintDetailScreen(
            complaint: ComplaintModel.fromFirestore(complaintDoc),
          ),
        ),
      );
      return;
    }

    final resourceId = (data['resourceId'] ?? '').toString();
    if (resourceId.isNotEmpty &&
        (type == 'resource' || type == 'resource_deleted')) {
      final resourceDoc = await _firestore
          .collection('resources')
          .doc(resourceId)
          .get();
      if (!mounted) return;
      if (!resourceDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This resource is no longer available.'),
          ),
        );
        return;
      }
      final resource = ResourceModel.fromFirestore(
        resourceDoc.id,
        resourceDoc.data()!,
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ResourceDetailScreen(),
          settings: RouteSettings(arguments: resource),
        ),
      );
      return;
    }

    final batchId = (data['batchId'] ?? '').toString();
    final subjectName = (data['subjectName'] ?? data['subject'] ?? '')
        .toString()
        .trim();

    if (type == 'subject_created' &&
        batchId.isNotEmpty &&
        subjectName.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SubjectDetailScreen(subjectName: subjectName, batchId: batchId),
        ),
      );
      return;
    }

    if (type == 'batch_created' ||
        type == 'batch_deleted' ||
        type == 'subject_deleted') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManageBatchesScreen()),
      );
      return;
    }

    if (type.startsWith('event_')) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EventCalendarScreen()),
      );
      return;
    }

    if ((type == 'attendance_marked' ||
            type == 'attendance_updated' ||
            type == 'low_attendance') &&
        subjectName.isNotEmpty &&
        (CurrentUser.batchId ?? '').isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceHistoryScreen(
            batchId: CurrentUser.batchId!,
            subjectName: subjectName,
          ),
        ),
      );
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _service = ref.read(notificationServiceProvider);
    _noticeService = ref.read(noticeServiceProvider);
    _firestore = ref.read(firebaseFirestoreProvider);
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _service.purgeExpiredNotifications();
        _service.markAllReadForUser(uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const AppHeroBackground(height: 172),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Notifications',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: StreamBuilder<NotificationCounter>(
                            stream: _service.streamUserNotificationCounter(uid),
                            builder: (context, snapshot) {
                              final counter =
                                  snapshot.data ??
                                  const NotificationCounter(
                                    total: 0,
                                    unread: 0,
                                  );
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _CountChip(
                                      label: 'Unread',
                                      value: counter.unread,
                                    ),
                                    const SizedBox(width: 8),
                                    _CountChip(
                                      label: 'Total',
                                      value: counter.total,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Clear all notifications',
                        onPressed: () async {
                          final confirmed =
                              await _confirmClearAllNotifications();
                          if (!confirmed) return;
                          await _service.clearAllForUser(uid);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _service.streamUserNotifications(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load notifications: ${snapshot.error}',
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];
                      final unreadCount = items.where((n) {
                        return n['isRead'] != true;
                      }).length;

                      if (unreadCount > 0 &&
                          !_isMarkingVisibleNotificationsRead) {
                        _isMarkingVisibleNotificationsRead = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _service.markAllReadForUser(uid).whenComplete(() {
                            if (mounted) {
                              setState(() {
                                _isMarkingVisibleNotificationsRead = false;
                              });
                            } else {
                              _isMarkingVisibleNotificationsRead = false;
                            }
                          });
                        });
                      }

                      if (items.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final n = items[index];
                          final id = (n['id'] ?? '').toString();
                          final title = (n['title'] ?? '').toString();
                          final body = (n['body'] ?? '').toString();
                          final isRead = (n['isRead'] ?? false) as bool;
                          final noticeId = (n['noticeId'] ?? '').toString();
                          final createdBy = (n['createdBy'] ?? '').toString();
                          final canDeletePostedNotification =
                              noticeId.isNotEmpty && createdBy == uid;

                          return Dismissible(
                            key: ValueKey('$id-$index'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              padding: const EdgeInsets.only(right: 20),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: UIColors.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              return _confirmDeleteNotification(
                                canDeletePostedNotification:
                                    canDeletePostedNotification,
                              );
                            },
                            onDismissed: (_) async {
                              if (canDeletePostedNotification) {
                                await _service.deleteNotificationsForNotice(
                                  noticeId,
                                );
                                return;
                              }

                              if (id.isNotEmpty) {
                                await _service.deleteNotification(id);
                              }
                            },
                            child: _NotificationCard(
                              title: title,
                              body: body,
                              isRead: isRead,
                              onTap: () async {
                                if (!isRead && id.isNotEmpty) {
                                  await _service.markRead(id);
                                }
                                if (!context.mounted) return;
                                await _openNotification(n);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;

  const _CountChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final unreadBorderColor = isDark
        ? const Color(0xFF60A5FA)
        : UIColors.primary;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.24)
        : UIColors.primary.withValues(alpha: 0.10);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isDark ? 22 : 16,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isRead ? Colors.transparent : unreadBorderColor,
            width: isRead ? 0 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  gradient: UIColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Notification' : title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: UIColors.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'You are all caught up',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
