import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Normalize date to midnight
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 🔥 REAL-TIME STREAM FOR CALENDAR
  Stream<Map<DateTime, List<EventModel>>> streamEvents() {
    return _firestore
        .collection('events')
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      final Map<DateTime, List<EventModel>> map = {};

      for (final doc in snapshot.docs) {
        final event = EventModel.fromDoc(doc);
        final dayKey = _normalize(event.date);

        map.putIfAbsent(dayKey, () => []);
        map[dayKey]!.add(event);
      }

      return map; // <-- empty map is VALID, no loaders
    });
  }

  /// ➕ ADD EVENT (Faculty/Admin only – rules enforce this)
  Future<void> addEvent({
    required String title,
    required DateTime date,
  }) async {
    await _firestore.collection('events').add({
      'title': title,
      'date': Timestamp.fromDate(_normalize(date)),
      'createdBy': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
