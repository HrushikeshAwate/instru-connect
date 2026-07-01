import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/services/activity_notification_service.dart';
import 'package:instru_connect/core/session/current_user.dart';

import '../models/complaint_model.dart';
import '../../../core/services/notification_service.dart';

class ComplaintService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'complaints';
  final NotificationService _notificationService = NotificationService();
  final ActivityNotificationService _activityNotifications =
      ActivityNotificationService();
  static const Duration _openComplaintRetention = Duration(days: 120);
  static const Duration _resolvedComplaintRetention = Duration(days: 40);

  // =====================================================
  // PHASE 1 — CREATE COMPLAINT
  // =====================================================

  Future<DocumentReference> createComplaint({
    required String title,
    required String description,
    required String category,
    required String createdBy,
    required String createdByRole,
    required String departmentId,
    bool isAnonymous = false,
  }) async {
    final normalizedRole = (createdByRole).trim().toLowerCase();
    const allowedRoles = {
      AppRoles.student,
      AppRoles.cr,
      AppRoles.faculty,
      AppRoles.staff,
    };
    if (!allowedRoles.contains(normalizedRole)) {
      throw Exception('You are not allowed to create complaints.');
    }

    final docRef = _db.collection(_collection).doc();
    final now = DateTime.now();
    final deleteAt = Timestamp.fromDate(now.add(_openComplaintRetention));

    await docRef.set({
      'title': title,
      'description': description,
      'category': category,
      'status': 'submitted',
      'progressNote': null,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'isAnonymous': isAnonymous,
      'assignedTo': null,
      'assignedRole': null,
      'departmentId': departmentId,
      'mediaUrl': null,
      'mediaType': null,
      'resolvedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'deleteAt': deleteAt,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    await _activityNotifications.notifyAdminsAndFaculty(
      title: 'New Complaint Submitted',
      body: title,
      type: 'complaint_created',
      data: {
        'complaintId': docRef.id,
        'category': category,
        'createdBy': createdBy,
        'createdByRole': createdByRole,
      },
    );

    return docRef;
  }

  // =====================================================
  // READ COMPLAINTS
  // =====================================================

  /// Student / CR — only their own complaints
  Stream<List<ComplaintModel>> fetchMyComplaints(String uid) {
    return _db
        .collection(_collection)
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => _sortByNewest(
            snapshot.docs.map(ComplaintModel.fromFirestore).toList(),
          ),
        );
  }

  /// Admin / Faculty — all complaints
  Stream<List<ComplaintModel>> fetchAllComplaints() {
    return _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ComplaintModel.fromFirestore).toList(),
        );
  }

  Stream<List<ComplaintModel>> fetchComplaintsByStatus({
    required bool resolved,
  }) {
    return fetchAllComplaints().map(
      (complaints) => complaints.where((complaint) {
        return resolved
            ? complaint.status == 'resolved'
            : complaint.status != 'resolved';
      }).toList(),
    );
  }

  /// Staff — complaints assigned to them
  Stream<List<ComplaintModel>> fetchAssignedComplaints(String uid) {
    return _db
        .collection(_collection)
        .where('assignedTo', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => _sortByNewest(
            snapshot.docs.map(ComplaintModel.fromFirestore).toList(),
          ),
        );
  }

  Stream<List<ComplaintModel>> streamForCurrentUser() {
    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    final uid = (CurrentUser.uid ?? '').trim();

    if (role == AppRoles.admin ||
        role == AppRoles.faculty ||
        role == AppRoles.staff) {
      return fetchAllComplaints();
    }

    if (uid.isNotEmpty) {
      return fetchMyComplaints(uid);
    }

    return const Stream<List<ComplaintModel>>.empty();
  }

  // =====================================================
  // MEDIA (IMAGE / VIDEO)
  // =====================================================

  Future<Map<String, String>> uploadMedia({
    required String complaintId,
    required File file,
    required String mediaType,
  }) async {
    final extension = file.path.split('.').last;

    final ref = FirebaseStorage.instance.ref().child(
      'complaints_media/$complaintId/attachment.$extension',
    );

    await ref.putFile(file);

    final downloadUrl = await ref.getDownloadURL();

    return {'mediaUrl': downloadUrl, 'mediaType': mediaType};
  }

  Future<void> attachMedia({
    required String complaintId,
    required String mediaUrl,
    required String mediaType,
  }) async {
    await _db.collection(_collection).doc(complaintId).update({
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =====================================================
  // FETCH ASSIGNABLE USERS (STAFF + FACULTY)
  // =====================================================

  Future<List<Map<String, String>>> fetchAssignableUsers() async {
    final snapshot = await _db
        .collection('users')
        .where('role', whereIn: ['faculty', 'staff'])
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return <String, String>{
        'uid': doc.id,
        'name': (data['name'] ?? 'Unknown').toString(),
        'role': (data['role'] ?? '').toString(),
      };
    }).toList();
  }

  // =====================================================
  // PHASE 2 — ASSIGN COMPLAINT
  // =====================================================

  Future<void> assignComplaint({
    required String complaintId,
    required String assignedTo,
    required String assignedRole,
  }) async {
    final actorRole = (CurrentUser.role ?? '').trim().toLowerCase();
    if (actorRole != AppRoles.admin) {
      throw Exception('Only admins can assign complaints.');
    }

    final complaintRef = _db.collection(_collection).doc(complaintId);
    final complaintSnap = await complaintRef.get();
    final complaintData = complaintSnap.data() ?? <String, dynamic>{};
    final complaintTitle = (complaintData['title'] ?? 'Complaint')
        .toString()
        .trim();
    final createdBy = (complaintData['createdBy'] ?? '').toString().trim();

    await _db.collection(_collection).doc(complaintId).update({
      'assignedTo': assignedTo,
      'assignedRole': assignedRole,
      'status': 'acknowledged',
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    await _activityNotifications.notifyUsers(
      uids: [assignedTo, createdBy],
      title: 'Complaint Assigned',
      body: complaintTitle,
      type: 'complaint_assigned',
      data: {
        'complaintId': complaintId,
        'assignedTo': assignedTo,
        'assignedRole': assignedRole,
      },
    );
  }

  // =====================================================
  // PHASE 2 — UPDATE PROGRESS
  // =====================================================

  Future<void> updateProgress({
    required String complaintId,
    required String status,
    String? progressNote,
  }) async {
    final docRef = _db.collection(_collection).doc(complaintId);
    final existing = await docRef.get();
    if (!existing.exists) {
      throw Exception('Complaint not found.');
    }

    final actorRole = (CurrentUser.role ?? '').trim().toLowerCase();
    final canUpdate =
        actorRole == AppRoles.admin || actorRole == AppRoles.faculty;

    if (!canUpdate) {
      throw Exception('You are not allowed to update this complaint.');
    }

    final oldStatus = existing.data()?['status']?.toString();
    final existingDeleteAt = existing.data()?['deleteAt'] as Timestamp?;

    final Map<String, dynamic> updates = {
      'status': status,
      'progressNote': progressNote,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (oldStatus != 'resolved' && status == 'resolved') {
      updates['resolvedAt'] = FieldValue.serverTimestamp();
      updates['deleteAt'] = Timestamp.fromDate(
        DateTime.now().add(_resolvedComplaintRetention),
      );
    } else if (oldStatus == 'resolved' && status != 'resolved') {
      updates['resolvedAt'] = null;
      final reopenedDeleteAt = Timestamp.fromDate(
        DateTime.now().add(_openComplaintRetention),
      );
      if (existingDeleteAt == null ||
          reopenedDeleteAt.toDate().isAfter(existingDeleteAt.toDate())) {
        updates['deleteAt'] = reopenedDeleteAt;
      }
    }

    await docRef.update(updates);

    final createdBy = existing.data()?['createdBy']?.toString();
    final title = existing.data()?['title']?.toString() ?? 'Complaint';
    final assignedToUser = existing.data()?['assignedTo']?.toString();
    final notificationTitle = status == 'resolved'
        ? 'Complaint Resolved'
        : 'Complaint Updated';

    await _activityNotifications.notifyUsers(
      uids: [
        if (createdBy != null) createdBy,
        if (assignedToUser != null) assignedToUser,
      ],
      title: notificationTitle,
      body: title,
      type: status == 'resolved' ? 'complaint_resolved' : 'complaint_updated',
      data: {'complaintId': complaintId, 'status': status},
    );

    if (oldStatus != 'resolved' && status == 'resolved') {
      if (createdBy != null && createdBy.isNotEmpty) {
        await _notificationService.createUserNotification(
          uid: createdBy,
          title: 'Complaint Resolved',
          body: title,
          type: 'complaint_resolved',
          data: {'complaintId': complaintId},
        );
      }
    }
  }

  Future<bool> canAccessCoordinationNotes(String complaintId) async {
    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    final uid = (CurrentUser.uid ?? '').trim();

    if (uid.isEmpty) return false;
    if (role == AppRoles.admin) return true;

    final complaintDoc = await _db
        .collection(_collection)
        .doc(complaintId)
        .get();
    if (!complaintDoc.exists) return false;

    final data = complaintDoc.data() ?? <String, dynamic>{};
    final assignedTo = (data['assignedTo'] ?? '').toString().trim();
    return assignedTo == uid;
  }

  Stream<List<Map<String, dynamic>>> streamCoordinationNotes(
    String complaintId,
  ) {
    return _db
        .collection(_collection)
        .doc(complaintId)
        .collection('coordination_notes')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'message': (data['message'] ?? '').toString(),
              'createdBy': (data['createdBy'] ?? '').toString(),
              'createdByName': (data['createdByName'] ?? 'Unknown').toString(),
              'createdByRole': (data['createdByRole'] ?? '').toString(),
              'createdAt': data['createdAt'],
            };
          }).toList();
        });
  }

  Future<void> addCoordinationNote({
    required String complaintId,
    required String message,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw Exception('Please enter a note.');
    }

    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    final uid = (CurrentUser.uid ?? '').trim();
    if (uid.isEmpty) {
      throw Exception('You must be signed in.');
    }

    final complaintRef = _db.collection(_collection).doc(complaintId);
    final complaintSnap = await complaintRef.get();
    if (!complaintSnap.exists) {
      throw Exception('Complaint not found.');
    }

    final complaintData = complaintSnap.data() ?? <String, dynamic>{};
    final assignedTo = (complaintData['assignedTo'] ?? '').toString().trim();
    final complaintTitle = (complaintData['title'] ?? 'Complaint')
        .toString()
        .trim();

    final canAddNote = role == AppRoles.admin || assignedTo == uid;
    if (!canAddNote) {
      throw Exception('You are not allowed to add coordination notes.');
    }

    await complaintRef.collection('coordination_notes').add({
      'message': trimmedMessage,
      'createdBy': uid,
      'createdByName': (CurrentUser.name ?? 'Unknown').trim(),
      'createdByRole': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await complaintRef.update({'lastUpdatedAt': FieldValue.serverTimestamp()});

    final recipients = <String>{
      if (role == AppRoles.admin && assignedTo.isNotEmpty) assignedTo,
      if (role != AppRoles.admin) ...[
        ...await _notificationService.fetchUidsByRoles([AppRoles.admin]),
      ],
    }.toList();

    await _activityNotifications.notifyUsers(
      uids: recipients,
      title: 'Complaint Coordination Note',
      body: complaintTitle,
      type: 'complaint_note',
      data: {'complaintId': complaintId},
    );
  }

  Future<void> deleteComplaint({
    required String complaintId,
    required String actorRole,
  }) async {
    final normalizedRole = actorRole.trim().toLowerCase();
    if (normalizedRole != AppRoles.admin) {
      throw Exception('You are not allowed to delete complaints.');
    }

    final docRef = _db.collection(_collection).doc(complaintId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    await docRef.delete();
  }

  Future<void> deleteComplaints({
    required List<String> complaintIds,
    required String actorRole,
  }) async {
    final normalizedRole = actorRole.trim().toLowerCase();
    if (normalizedRole != AppRoles.admin) {
      throw Exception('You are not allowed to delete complaints.');
    }

    final ids = complaintIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return;

    for (final complaintId in ids) {
      await _db.collection(_collection).doc(complaintId).delete();
    }
  }

  List<ComplaintModel> _sortByNewest(List<ComplaintModel> complaints) {
    complaints.sort((a, b) {
      final timeCompare = b.createdAt.compareTo(a.createdAt);
      if (timeCompare != 0) return timeCompare;
      return a.id.compareTo(b.id);
    });
    return complaints;
  }
}
