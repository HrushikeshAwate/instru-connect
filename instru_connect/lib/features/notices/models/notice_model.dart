import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String body;
  final String departmentId;
  final DateTime createdAt;
  final List<String> batchIds;
  final String createdBy;
  final String createdByRole;
  final String? priority;
  final List<String> attachments;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.departmentId,
    required this.createdAt,
    this.batchIds = const [],
    this.createdBy = '',
    this.createdByRole = '',
    this.priority,
    this.attachments = const [],
  });

  factory Notice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'];

    return Notice(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      departmentId: data['departmentId'] ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      batchIds: List<String>.from(data['batchIds'] ?? const []),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdByRole: (data['createdByRole'] ?? '').toString(),
      priority: data['priority'],
      attachments: List<String>.from(data['attachments'] ?? const []),
    );
  }
}
