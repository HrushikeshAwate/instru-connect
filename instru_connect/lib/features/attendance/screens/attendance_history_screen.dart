import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../batches/services/batch_service.dart';
import 'edit_attendance_screen.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  final String batchId;
  final String subjectName;

  const AttendanceHistoryScreen({
    super.key,
    required this.batchId,
    required this.subjectName,
  });

  /// THE "GRAND EXCEL" LOGIC: Generates a Student vs Date Matrix
  Future<void> _exportGrandExcel(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Fetch all students in this batch
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('batchId', isEqualTo: batchId)
          .get();

      // 2. Fetch all attendance sessions for this subject
      final sessions = await FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .collection('attendance')
          .where('subject', isEqualTo: subjectName)
          .orderBy('timestamp', descending: false)
          .get();

      if (context.mounted) Navigator.pop(context);

      if (sessions.docs.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No records found.")));
        return;
      }

      // 3. Build CSV Header: Name, Email, Date1, Date2, ..., Total, %
      List<String> header = ["Student Name", "Email/MIS"];
      for (var doc in sessions.docs) {
        header.add(doc.get('date') ?? "N/A");
      }
      header.addAll(["Total Present", "Percentage"]);

      List<List<dynamic>> csvRows = [header];

      // 4. Build Student Rows
      for (var studentDoc in studentSnapshot.docs) {
        final sData = studentDoc.data();
        final String uid = studentDoc.id;

        List<dynamic> row = [
          sData['name'] ?? "Unknown", // Matching lowercase key from your screenshot
          sData['email'] ?? "N/A"    // Matching lowercase key from your screenshot
        ];

        int presentCount = 0;
        for (var sessionDoc in sessions.docs) {
          final List absentees = sessionDoc.get('absentUids') ?? [];
          if (absentees.contains(uid)) {
            row.add("A"); // Absent
          } else {
            row.add("P"); // Present
            presentCount++;
          }
        }

        double percentage = (presentCount / sessions.docs.length) * 100;
        row.add(presentCount);
        row.add("${percentage.toStringAsFixed(1)}%");
        csvRows.add(row);
      }

      // 5. Save and Share
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/${subjectName}_Detailed_Report.csv";
      final file = File(path);
      await file.writeAsString(const ListToCsvConverter().convert(csvRows));

      if (context.mounted) await Share.shareXFiles([XFile(path)], text: '$subjectName Detailed Report');
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$subjectName History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on), // Excel icon
            tooltip: "Download Grand Excel",
            onPressed: () => _exportGrandExcel(context),
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No history found. Ensure the subject name matches exactly."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              final List absentees = data['absentUids'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['date'] ?? "No Date", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${absentees.length} Students marked Absent"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditAttendanceScreen(
                              batchId: batchId,
                              attendanceDocId: docId,
                              subjectName: subjectName,
                              currentAbsentUids: List<String>.from(absentees),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("This will revert the counts for all students. This action is permanent."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await BatchService().deleteAttendance(batchId, docId);
              },
              child: const Text("DELETE", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}