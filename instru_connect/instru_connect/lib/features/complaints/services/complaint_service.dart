import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/complaint_model.dart';

class ComplaintService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'complaints';

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
  }) async {
    final docRef = _db.collection(_collection).doc();

    await docRef.set({
      'title': title,
      'description': description,
      'category': category,
      'status': 'submitted',
      'progressNote': null,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'assignedTo': null,
      'assignedRole': null,
      'departmentId': departmentId,
      'mediaUrl': null,
      'mediaType': null,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ComplaintModel.fromFirestore).toList(),
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

  /// Staff / Faculty — complaints assigned to them
  Stream<List<ComplaintModel>> fetchAssignedComplaints(String uid) {
    return _db
        .collection(_collection)
        .where('assignedTo', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ComplaintModel.fromFirestore).toList(),
        );
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

    final ref = FirebaseStorage.instance
        .ref()
        .child('complaints_media/$complaintId/attachment.$extension');

    await ref.putFile(file);

    final downloadUrl = await ref.getDownloadURL();

    return {
      'mediaUrl': downloadUrl,
      'mediaType': mediaType,
    };
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
    await _db.collection(_collection).doc(complaintId).update({
      'assignedTo': assignedTo,
      'assignedRole': assignedRole,
      'status': 'acknowledged',
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =====================================================
  // PHASE 2 — UPDATE PROGRESS
  // =====================================================

  Future<void> updateProgress({
    required String complaintId,
    required String status,
    String? progressNote,
  }) async {
    await _db.collection(_collection).doc(complaintId).update({
      'status': status,
      'progressNote': progressNote,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
