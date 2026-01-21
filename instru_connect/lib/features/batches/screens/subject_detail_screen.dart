import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'mark_attendance_screen.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subjectName;
  final String batchId;

  const SubjectDetailScreen({
    super.key,
    required this.subjectName,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceHistoryScreen(batchId: batchId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['student', 'cr'])
            .where('batchId', isEqualTo: batchId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No students found'));

          final students = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = students[index].data() as Map<String, dynamic>? ?? {}; // Safety cast
              final int total = data['totalClasses'] ?? 0;
              final int attended = data['attendedClasses'] ?? 0;
              final double percentage = total == 0 ? 0.0 : (attended / total) * 100;

              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                leading: CircleAvatar(
                  backgroundColor: percentage < 75 ? Colors.red.shade50 : Colors.green.shade50,
                  child: Text("${percentage.toInt()}%", style: TextStyle(fontSize: 10, color: percentage < 75 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                ),
                title: Text(data['name'] ?? 'Unnamed Student'),
                subtitle: Text("Attended: $attended/$total"),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MarkAttendanceScreen(batchId: batchId, subjectName: subjectName)),
          );
        },
        label: const Text('Mark Attendance'),
        icon: const Icon(Icons.fact_check),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

// --- THE FULLY PROTECTED HISTORY SCREEN ---
class AttendanceHistoryScreen extends StatelessWidget {
  final String batchId;
  const AttendanceHistoryScreen({super.key, required this.batchId});

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final query = FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .collection('attendance');

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data found to export")));
        }
        return;
      }

      List<List<dynamic>> rows = [
        ["Date", "Subject", "Absent Count", "Absent Student IDs"]
      ];

      for (var doc in snapshot.docs) {
        // ULTIMATE SAFETY CHECK: Prevents Bad State
        if (!doc.exists) continue;
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final List absentees = data['absentUids'] ?? []; // Safe access

        String docId = doc.id;
        List<String> parts = docId.split('_');
        String date = parts.isNotEmpty ? parts[0] : "Unknown";
        String subject = parts.length > 1 ? parts[1] : "General";

        rows.add([date, subject, absentees.length, absentees.join(", ")]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Attendance_Report_$batchId.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      if (context.mounted) {
        await Share.shareXFiles([XFile(path)], text: 'Attendance Report');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Critical Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportToCSV(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('batches')
            .doc(batchId)
            .collection('attendance')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No records found yet."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {}; // Avoid Bad State
              final List absentees = data['absentUids'] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.history_edu),
                  title: Text(doc.id.replaceAll('_', ' - ')),
                  subtitle: Text("${absentees.length} Absentees"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}