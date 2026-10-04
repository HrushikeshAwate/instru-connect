import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/demo/demo_mode.dart';
import 'package:instru_connect/core/services/activity_notification_service.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart';
import 'package:instru_connect/core/session/current_user.dart';
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
    if (DemoMode.isActive) return const [];

    final snapshot = await _scopedResourceQuery().get();

    final resources = snapshot.docs
        .map((doc) => ResourceModel.fromFirestore(doc.id, doc.data()))
        .toList();
    resources.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return resources;
  }

  Stream<List<ResourceModel>> streamResources() {
    if (DemoMode.isActive) return Stream.value(const <ResourceModel>[]);

    return _scopedResourceQuery().snapshots().map(
      (snapshot) =>
          (snapshot.docs
              .map((doc) => ResourceModel.fromFirestore(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt))),
    );
  }

  Stream<List<ResourceSectionModel>> streamResourceSections() {
    if (DemoMode.isActive) {
      return Stream.value(const <ResourceSectionModel>[]);
    }

    final query = _isResourceManager
        ? _db.collection('resourceSections')
        : _db
              .collection('resourceSections')
              .where('batchId', isEqualTo: CurrentUser.batchId)
              .where('academicYear', isEqualTo: CurrentUser.academicYear);
    return query.snapshots().map((snapshot) {
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
    required String batchId,
    required String batchName,
    required int academicYear,
  }) async {
    DemoMode.ensureCanWrite();
    if (!await _canManageResources()) {
      throw Exception('You are not allowed to add resources.');
    }

    final trimmedSubject = subject.trim();
    final trimmedName = name.trim();
    if (trimmedSubject.isEmpty || trimmedName.isEmpty) {
      throw Exception('Subject and section name are required.');
    }

    final docId = _sectionDocId(trimmedSubject, trimmedName, batchId);
    await _db.collection('resourceSections').doc(docId).set({
      'subject': trimmedSubject,
      'subjectLower': trimmedSubject.toLowerCase(),
      'name': trimmedName,
      'nameLower': trimmedName.toLowerCase(),
      'batchId': batchId,
      'batchName': batchName,
      'academicYear': academicYear,
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
    required String batchId,
    required String batchName,
    required int academicYear,
  }) async {
    DemoMode.ensureCanWrite();

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
      'resources/$academicYear/$batchId/$storageFileName',
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
      'batchId': batchId,
      'batchName': batchName,
      'academicYear': academicYear,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addResourceSection(
      subject: subject,
      name: section,
      batchId: batchId,
      batchName: batchName,
      academicYear: academicYear,
    );

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
    if (DemoMode.isActive) return false;

    final role = (CurrentUser.role ?? '').toLowerCase();
    return role == AppRoles.admin || role == AppRoles.faculty;
  }

  Future<void> deleteResource(ResourceModel resource) async {
    DemoMode.ensureCanWrite();

    if (!await _canManageResources()) {
      throw Exception('You are not allowed to delete this resource.');
    }

    await _deleteStorageFile(resource.fileUrl);
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
    DemoMode.ensureCanWrite();

    if (!await _canManageResources()) {
      throw Exception('You are not allowed to delete resources.');
    }

    final deletable = resources;
    if (deletable.isEmpty) return;

    for (final resource in deletable) {
      await _deleteStorageFile(resource.fileUrl);
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
    }
  }

  Query<Map<String, dynamic>> _scopedResourceQuery() {
    final resources = _db.collection('resources');
    if (_isResourceManager) return resources;

    final batchId = CurrentUser.batchId;
    if (batchId == null || batchId.trim().isEmpty) {
      return resources.where('batchId', isEqualTo: '__no_batch__');
    }
    return resources
        .where('batchId', isEqualTo: batchId)
        .where('academicYear', isEqualTo: CurrentUser.academicYear);
  }

  bool get _isResourceManager {
    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    return role == AppRoles.admin || role == AppRoles.faculty;
  }

  Future<void> _deleteStorageFile(String fileUrl) async {
    if (fileUrl.trim().isEmpty) return;
    try {
      await _storage.refFromURL(fileUrl).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  String _sectionDocId(String subject, String name, String batchId) {
    final raw =
        '${batchId.trim()}-${subject.trim().toLowerCase()}-${name.trim().toLowerCase()}';
    return Uri.encodeComponent(raw);
  }

  Future<bool> _canManageResources() async {
    if (DemoMode.isActive) return false;

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
