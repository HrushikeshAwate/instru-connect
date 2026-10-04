import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/core/demo/demo_account.dart';
import 'package:instru_connect/core/demo/demo_mode.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================
  // ROLE ASSIGNMENT (unchanged)
  // ============================

  Future<void> assignFaculty(String userId) async {
    await _assignRole(userId, 'faculty');
  }

  Future<void> assignStaff(String userId) async {
    await _assignRole(userId, 'staff');
  }

  Future<void> assignAdmin(String userId) async {
    await _assignRole(userId, 'admin');
  }

  /// Internal helper
  Future<void> _assignRole(String userId, String role) async {
    DemoMode.ensureCanWrite();

    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    final targetEmail = userDoc.data()?['email']?.toString();

    if (DemoAccount.isDemoEmail(targetEmail)) {
      throw Exception('App Review Demo role cannot be changed.');
    }

    await userRef.update({'role': role});
  }

  // ============================
  // ROLE FETCH (FIXED)
  // ============================

  Future<String> fetchUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('User document not found');
    }

    final data = doc.data();
    final role = data?['role'];

    if (role == null || role is! String || role.isEmpty) {
      throw Exception('User role not assigned');
    }

    return role;
  }
}
