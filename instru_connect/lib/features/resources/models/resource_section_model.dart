import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceSectionModel {
  final String id;
  final String subject;
  final String name;
  final DateTime createdAt;

  const ResourceSectionModel({
    required this.id,
    required this.subject,
    required this.name,
    required this.createdAt,
  });

  factory ResourceSectionModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return ResourceSectionModel(
      id: id,
      subject: data['subject'] ?? '',
      name: data['name'] ?? 'General',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
