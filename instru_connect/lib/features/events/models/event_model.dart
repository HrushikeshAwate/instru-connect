import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String details;
  final DateTime date;

  EventModel({
    required this.id,
    required this.title,
    required this.details,
    required this.date,
  });

  factory EventModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      details: data['details'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
