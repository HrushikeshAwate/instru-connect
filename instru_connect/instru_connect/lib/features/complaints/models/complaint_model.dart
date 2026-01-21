import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String title;
  final String description;
  final String category;

  final String status;
  final String? progressNote;

  final String createdBy;
  final String createdByRole;

  final String? assignedTo;
  final String? assignedRole;

  final String departmentId;

  // 🔹 NEW
  final String? mediaUrl;
  final String? mediaType; // image | video

  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.progressNote,
    required this.createdBy,
    required this.createdByRole,
    this.assignedTo,
    this.assignedRole,
    required this.departmentId,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ComplaintModel(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      category: data['category'],
      status: data['status'],
      progressNote: data['progressNote'],
      createdBy: data['createdBy'],
      createdByRole: data['createdByRole'],
      assignedTo: data['assignedTo'],
      assignedRole: data['assignedRole'],
      departmentId: data['departmentId'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp).toDate(),
    );
  }
}
