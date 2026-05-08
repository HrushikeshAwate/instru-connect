import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/services/notification_service.dart';

class ActivityNotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> notifyUsers({
    required Iterable<String> uids,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final uniqueUids = uids
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList();

    if (uniqueUids.isEmpty) return;

    await _notificationService.createNotificationsForUsers(
      uids: uniqueUids,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  Future<void> notifyAdminsAndFaculty({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final uids = await _notificationService.fetchUidsByRoles([
      AppRoles.admin,
      AppRoles.faculty,
    ]);

    await notifyUsers(
      uids: uids,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  Future<void> notifyAllUsers({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final uids = await _notificationService.fetchAllUserUids();

    await notifyUsers(
      uids: uids,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  Future<void> notifyBatchMembers({
    required String batchId,
    required String title,
    required String body,
    required String type,
    List<String>? roles,
    Map<String, dynamic>? data,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .where('batchId', isEqualTo: batchId);

    if (roles != null && roles.isNotEmpty && roles.length <= 10) {
      query = query.where('role', whereIn: roles);
    }

    final snapshot = await query.get();
    final filteredDocs = roles == null || roles.isEmpty
        ? snapshot.docs
        : snapshot.docs.where((doc) {
            final role = (doc.data()['role'] ?? '').toString();
            return roles.contains(role);
          });

    await notifyUsers(
      uids: filteredDocs.map((doc) => doc.id),
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  Future<void> notifyBatchStudentsAndCr({
    required String batchId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await notifyBatchMembers(
      batchId: batchId,
      title: title,
      body: body,
      type: type,
      roles: const [AppRoles.student, AppRoles.cr],
      data: data,
    );
  }
}
