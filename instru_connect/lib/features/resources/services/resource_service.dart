import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/core/services/notification_service.dart';

class ResourceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // ============================
  // READ (USED BY LIST SCREEN)
  // ============================
  Future<List<ResourceModel>> fetchResources() async {
    final snapshot = await _db
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => ResourceModel.fromFirestore(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ============================
  // WRITE (USED BY ADD SCREEN)
  // ============================
  Future<void> addResource({
    required String title,
    required String description,
    required String subject,
    required File file,
    required String role,
    required String uid,
  }) async {
    final String fileName = file.path.split('/').last;

    final Reference storageRef = _storage
        .ref()
        .child('resources/${DateTime.now().year}/$fileName');

    final UploadTask uploadTask = storageRef.putFile(file);
    final TaskSnapshot snapshot = await uploadTask;

    final String fileUrl = await snapshot.ref.getDownloadURL();

    final String fileType =
        fileName.contains('.') ? fileName.split('.').last : 'unknown';

    await _db.collection('resources').add({
      'title': title,
      'description': description,
      'subject': subject,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'uploadedBy': role,
      'uploadedByUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify all students/CR
    final uids = await _notificationService.fetchAllStudentCrUids();
    await _notificationService.createNotificationsForUsers(
      uids: uids,
      title: 'New Resource',
      body: title.trim(),
      type: 'resource',
      data: {
        'subject': subject,
      },
    );
  }
}
