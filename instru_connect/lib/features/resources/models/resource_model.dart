import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String section;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final String uploadedBy;
  final String uploadedByUid;
  final DateTime createdAt;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.section,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedByUid,
    required this.createdAt,
  });

  factory ResourceModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ResourceModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      section: data['section'] ?? 'General',
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      fileType: data['fileType'] ?? 'unknown',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedByUid: data['uploadedByUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
