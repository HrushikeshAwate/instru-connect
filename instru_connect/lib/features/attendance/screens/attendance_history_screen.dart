import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../batches/services/batch_service.dart';
import 'mark_attendance_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String batchId;
  final String subjectName;

  const AttendanceHistoryScreen({
    super.key,
    required this.batchId,
    required this.subjectName,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? _cachedRole;

  Future<String> _getUserRole() async {
    if (_cachedRole != null) return _cachedRole!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'student';

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    _cachedRole = doc.data()?['role'] ?? 'student';
    return _cachedRole!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.subjectName} History")),
      body: FutureBuilder<String>(
        future: _getUserRole(),
        builder: (context, roleSnapshot) {
          if (!roleSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userRole = roleSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('batches')
                .doc(widget.batchId)
                .collection('attendance')
                .where('subject', isEqualTo: widget.subjectName.trim())
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final List<String> absentees = List<String>.from(data['absentUids'] ?? []);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(data['date'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${absentees.length} Students Absent"),
                      // This TRAILING section is what was missing in your screenshot!
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _navigateToEdit(doc.id, absentees),
                          ),
                          // Delete is only for Admin/Faculty
                          if (userRole != 'cr')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(doc.id),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToEdit(String docId, List<String> absentees) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendanceScreen(
          batchId: widget.batchId,
          subjectName: widget.subjectName,
          isEditing: true,
          docId: docId,
          initialAbsentees: absentees,
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record"),
        content: const Text("This will permanently remove the record and update student stats."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await BatchService().deleteAttendance(widget.batchId, docId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}