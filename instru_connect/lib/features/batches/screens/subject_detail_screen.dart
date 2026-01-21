import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../attendance/screens/mark_attendance_screen.dart';

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
                  builder: (context) => AttendanceHistoryScreen(
                    batchId: batchId,
                    subjectName: subjectName,
                  ),
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
              final data = students[index].data() as Map<String, dynamic>? ?? {};

              // --- FIELD NAME FIXES ---
              final String studentName = data['Name'] ?? data['name'] ?? 'Unnamed Student';
              final String mis = (data['MIS No'] ?? data['mis'] ?? 'N/A').toString();

              // --- SUBJECT SPECIFIC CALCULATION ---
              final Map<String, dynamic> subjectsMap = data['subjects'] ?? {};
              final Map<String, dynamic> stats = subjectsMap[subjectName] ?? {};

              final int total = stats['total'] ?? 0;
              final int attended = stats['attended'] ?? 0;
              final double percentage = total == 0 ? 0.0 : (attended / total) * 100;

              final bool isLowAttendance = percentage < 75 && total > 0;

              return ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isLowAttendance ? Colors.red.shade200 : Colors.grey.shade200)
                ),
                tileColor: isLowAttendance ? Colors.red.shade50 : Colors.white,
                leading: CircleAvatar(
                  backgroundColor: isLowAttendance ? Colors.red : Colors.green,
                  child: Text(
                      "${percentage.toInt()}%",
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
                title: Text(
                    studentName,
                    style: TextStyle(fontWeight: isLowAttendance ? FontWeight.bold : FontWeight.normal)
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("MIS: $mis | Subject Attended: $attended/$total"),
                    if (isLowAttendance)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                            "⚠ WARNING: LOW ATTENDANCE (<75%)",
                            style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                      ),
                  ],
                ),
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

class AttendanceHistoryScreen extends StatelessWidget {
  final String batchId;
  final String subjectName;

  const AttendanceHistoryScreen({
    super.key,
    required this.batchId,
    required this.subjectName
  });

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final query = FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .collection('attendance')
          .where('subject', isEqualTo: subjectName);

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
        final data = doc.data();
        final List absentees = data['absentUids'] ?? [];
        final String date = data['date'] ?? "Unknown";

        rows.add([date, subjectName, absentees.length, absentees.join(", ")]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      // Clean file name for subjects with spaces
      final String fileName = subjectName.replaceAll(' ', '_');
      final path = "${directory.path}/${fileName}_Report.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      if (context.mounted) {
        await Share.shareXFiles([XFile(path)], text: '$subjectName Attendance Report');
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
        title: Text("$subjectName History"),
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
            .where('subject', isEqualTo: subjectName)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No records found for this subject."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final List absentees = data['absentUids'] ?? [];
              final String date = data['date'] ?? doc.id.split('_')[0]; // Fallback to ID date

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.history_edu, color: Colors.blueAccent),
                  title: Text(date),
                  subtitle: Text("${absentees.length} Students Absent"),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}