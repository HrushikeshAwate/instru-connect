import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/core/demo/demo_mode.dart';

class AdminService {
  final _db = FirebaseFirestore.instance;

  Future<int> getTotalUsers() async {
    if (DemoMode.isActive) return 0;

    try {
      final snapshot = await _db.collection('users').count().get();
      final count = snapshot.count;
      return count ?? 0;
    } catch (_) {
      final snapshot = await _db.collection('users').get();
      return snapshot.size;
    }
  }

  Stream<int> pendingComplaintsCount() {
    if (DemoMode.isActive) return Stream.value(0);

    return FirebaseFirestore.instance.collection('complaints').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] ?? 'submitted';
        return status != 'resolved';
      }).length;
    });
  }

  Stream<Map<String, int>> complaintStatusCounts() {
    if (DemoMode.isActive) {
      return Stream.value(const {'pending': 0, 'resolved': 0});
    }

    return FirebaseFirestore.instance.collection('complaints').snapshots().map((
      snapshot,
    ) {
      int pending = 0;
      int resolved = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'submitted';

        if (status == 'resolved') {
          resolved++;
        } else {
          pending++;
        }
      }

      return {'pending': pending, 'resolved': resolved};
    });
  }
}
