import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/services/activity_notification_service.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/models/resource_section_model.dart';
import 'package:instru_connect/core/services/notification_service.dart';

class ResourceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();
  final ActivityNotificationService _activityNotifications =
      ActivityNotificationService();

  // ============================
  // READ (USED BY LIST SCREEN)
  // ============================
  Future<List<ResourceModel>> fetchResources() async {
    final snapshot = await _db
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ResourceModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Stream<List<ResourceModel>> streamResources() {
    return _db
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ResourceModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ResourceSectionModel>> streamResourceSections() {
    return _db.collection('resourceSections').snapshots().map((snapshot) {
      final sections = snapshot.docs
          .map((doc) => ResourceSectionModel.fromFirestore(doc.id, doc.data()))
          .toList();

      sections.sort((a, b) {
        final subjectCompare = a.subject.toLowerCase().compareTo(
          b.subject.toLowerCase(),
        );
        if (subjectCompare != 0) return subjectCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return sections;
    });
  }

  Future<void> addResourceSection({
    required String subject,
    required String name,
  }) async {
    final trimmedSubject = subject.trim();
    final trimmedName = name.trim();
    if (trimmedSubject.isEmpty || trimmedName.isEmpty) {
      throw Exception('Subject and section name are required.');
    }

    final docId = _sectionDocId(trimmedSubject, trimmedName);
    await _db.collection('resourceSections').doc(docId).set({
      'subject': trimmedSubject,
      'subjectLower': trimmedSubject.toLowerCase(),
      'name': trimmedName,
      'nameLower': trimmedName.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============================
  // WRITE (USED BY ADD SCREEN)
  // ============================
  Future<void> addResource({
    required String title,
    required String description,
    required String subject,
    required String section,
    required File file,
    required String role,
    required String uid,
  }) async {
    final String fileName = file.path.split(RegExp(r'[\\/]')).last;
    final String fileType = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'unknown';
    final String safeFileName = fileName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    final String storageFileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    final Reference storageRef = _storage.ref().child(
      'resources/${DateTime.now().year}/$storageFileName',
    );

    final UploadTask uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: _contentTypeFor(fileType)),
    );
    final TaskSnapshot snapshot = await uploadTask;

    final String fileUrl = await snapshot.ref.getDownloadURL();

    final docRef = await _db.collection('resources').add({
      'title': title,
      'description': description,
      'subject': subject,
      'section': section,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'uploadedBy': role,
      'uploadedByUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addResourceSection(subject: subject, name: section);

    // Notify all students/CR
    final uids = await _notificationService.fetchAllStudentCrUids();
    await _notificationService.createNotificationsForUsers(
      uids: uids,
      title: 'New Resource Uploaded',
      body: subject.trim().isEmpty
          ? title.trim()
          : '${title.trim()} for $subject',
      type: 'resource',
      data: {
        'resourceId': docRef.id,
        'resourceTitle': title.trim(),
        'subject': subject,
        'section': section,
      },
    );
  }

  bool canDeleteResource(ResourceModel resource) {
    final role = (CurrentUser.role ?? '').toLowerCase();
    return role == AppRoles.admin || role == AppRoles.faculty;
  }

  Future<void> deleteResource(ResourceModel resource) async {
    if (!await _canManageResources()) {
      throw Exception('You are not allowed to delete this resource.');
    }

    await _db.collection('resources').doc(resource.id).delete();
    await _activityNotifications.notifyAllUsers(
      title: 'Resource Removed',
      body: resource.title,
      type: 'resource_deleted',
      data: {
        'resourceId': resource.id,
        'resourceTitle': resource.title,
        'subject': resource.subject,
        'section': resource.section,
      },
    );
    try {
      await _storage.refFromURL(resource.fileUrl).delete();
    } catch (_) {
      // Ignore storage cleanup issues so the Firestore delete still succeeds.
    }
  }

  Future<void> deleteResources(List<ResourceModel> resources) async {
    if (!await _canManageResources()) {
      throw Exception('You are not allowed to delete resources.');
    }

    final deletable = resources;
    if (deletable.isEmpty) return;

    for (final resource in deletable) {
      await _db.collection('resources').doc(resource.id).delete();
    }

    for (final resource in deletable) {
      await _activityNotifications.notifyAllUsers(
        title: 'Resource Removed',
        body: resource.title,
        type: 'resource_deleted',
        data: {
          'resourceId': resource.id,
          'resourceTitle': resource.title,
          'subject': resource.subject,
          'section': resource.section,
        },
      );
    }

    await Future.wait(
      deletable.map((resource) async {
        try {
          await _storage.refFromURL(resource.fileUrl).delete();
        } catch (_) {
          // Ignore storage cleanup issues so the Firestore delete still succeeds.
        }
      }),
    );
  }

  String _sectionDocId(String subject, String name) {
    final raw = '${subject.trim().toLowerCase()}-${name.trim().toLowerCase()}';
    return Uri.encodeComponent(raw);
  }

  Future<bool> _canManageResources() async {
    final cachedRole = (CurrentUser.role ?? '').trim().toLowerCase();
    if (cachedRole == AppRoles.admin || cachedRole == AppRoles.faculty) {
      return true;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final role = await RoleService().fetchUserRole(user.uid);
      final normalizedRole = role.trim().toLowerCase();
      return normalizedRole == AppRoles.admin ||
          normalizedRole == AppRoles.faculty;
    } catch (_) {
      return false;
    }
  }

  String _contentTypeFor(String fileType) {
    switch (fileType) {
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
