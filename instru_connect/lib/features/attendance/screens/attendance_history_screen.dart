import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  /// EXCEL MASTER EXPORT: Students vs Dates
  Future<void> _exportGrandExcel(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Get all students
      final students = await FirebaseFirestore.instance
          .collection('users')
          .where('batchId', isEqualTo: batchId)
          .get();

      // 2. Get all sessions for this specific subject
      final sessions = await FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .collection('attendance')
          .where('subject', isEqualTo: subjectName)
          .orderBy('timestamp', descending: false)
          .get();

      if (context.mounted) Navigator.pop(context);

      if (sessions.docs.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No records to export")));
        return;
      }

      // 3. Build Header: [Name, MIS, Date1, Date2, ...]
      List<String> header = ["Student Name", "Email/MIS"];
      for (var s in sessions.docs) {
        header.add(s.get('date') ?? "N/A");
      }
      header.addAll(["Total Present", "%"]);

      List<List<dynamic>> rows = [header];

      // 4. Map data into rows
      for (var student in students.docs) {
        final data = student.data();
        final uid = student.id;

        List<dynamic> row = [
          data['name'] ?? data['Name'] ?? "Unknown",
          data['email'] ?? data['MIS No'] ?? "N/A",
        ];

        int presentCount = 0;
        for (var session in sessions.docs) {
          final List absentees = session.get('absentUids') ?? [];
          if (absentees.contains(uid)) {
            row.add("A");
          } else {
            row.add("P");
            presentCount++;
          }
        }

        row.add(presentCount);
        row.add("${(presentCount / sessions.docs.length * 100).toStringAsFixed(1)}%");
        rows.add(row);
      }

      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/${subjectName}_Report.csv";
      final file = File(path);
      await file.writeAsString(const ListToCsvConverter().convert(rows));

      if (context.mounted) await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint("Excel Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$subjectName History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: "Master Excel",
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
          if (snapshot.hasError) {
            // Check your console for the Index Creation Link!
            debugPrint("Firestore Stream Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No history for this subject."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final absentees = data['absentUids'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(data['date'] ?? "No Date", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${absentees.length} Absentees"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditAttendanceScreen(
                          batchId: batchId,
                          attendanceDocId: docs[index].id,
                          subjectName: subjectName,
                          currentAbsentUids: List<String>.from(absentees),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}