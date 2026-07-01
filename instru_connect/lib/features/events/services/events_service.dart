import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/services/activity_notification_service.dart';
import 'package:instru_connect/core/services/notification_service.dart';
import '../models/event_model.dart';

class EventService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final ActivityNotificationService _activityNotifications =
      ActivityNotificationService();

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Stream<Map<DateTime, List<EventModel>>> streamEvents() {
    return _firestore.collection('events').orderBy('date').snapshots().map((
      snapshot,
    ) {
      final Map<DateTime, List<EventModel>> map = {};

      for (final doc in snapshot.docs) {
        final event = EventModel.fromDoc(doc);
        final dayKey = _normalize(event.date);

        map.putIfAbsent(dayKey, () => []);
        map[dayKey]!.add(event);
      }

      return map;
    });
  }

  Future<void> addEvent({
    required String title,
    required String details,
    required DateTime date,
  }) async {
    final normalizedDate = _normalize(date);
    await _firestore.collection('events').add({
      'title': title,
      'details': details,
      'date': Timestamp.fromDate(normalizedDate),
      'createdBy': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _notifyAllUsers(
      title: 'New Event Added',
      body: '$title on ${_formatDate(normalizedDate)}',
      eventTitle: title,
      eventDate: normalizedDate,
      type: 'event_created',
    );
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String details,
    required DateTime date,
  }) async {
    final normalizedDate = _normalize(date);
    await _firestore.collection('events').doc(eventId).update({
      'title': title,
      'details': details,
      'date': Timestamp.fromDate(normalizedDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notifyAllUsers(
      title: 'Event Updated',
      body: '$title moved/updated to ${_formatDate(normalizedDate)}',
      eventTitle: title,
      eventDate: normalizedDate,
      type: 'event_updated',
    );
  }

  Future<void> shiftEventDate({required EventModel event, required int days}) {
    return updateEvent(
      eventId: event.id,
      title: event.title,
      details: event.details,
      date: event.date.add(Duration(days: days)),
    );
  }

  Future<void> deleteEvent(String eventId) async {
    final snapshot = await _firestore.collection('events').doc(eventId).get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final title = (data['title'] ?? 'Event').toString().trim();

    await _firestore.collection('events').doc(eventId).delete();

    await _activityNotifications.notifyAllUsers(
      title: 'Event Deleted',
      body: title,
      type: 'event_deleted',
      data: {'eventId': eventId, 'eventTitle': title},
    );
  }

  Future<void> _notifyAllUsers({
    required String title,
    required String body,
    required String eventTitle,
    required DateTime eventDate,
    required String type,
  }) async {
    final uids = await _notificationService.fetchAllUserUids();
    await _notificationService.createNotificationsForUsers(
      uids: uids,
      title: title,
      body: body,
      type: type,
      data: {
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
      },
    );
  }
}
