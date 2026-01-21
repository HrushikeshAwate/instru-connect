import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String body;
  final String departmentId;
  final DateTime createdAt;
  final String? priority;
  final List<String> attachments;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.departmentId,
    required this.createdAt,
    this.priority,
    this.attachments = const [],
  });

  factory Notice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Notice(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      departmentId: data['departmentId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      priority: data['priority'],
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }
}
