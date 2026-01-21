import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  final String batchId;

  const AttendanceHistoryScreen({super.key, required this.batchId});

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      // 1. Fetch data WITHOUT orderBy first to see if that's causing the "Bad state"
      final snapshot = await FirebaseFirestore.instance
          .collection('batches')
          .doc(batchId)
          .collection('attendance')
          .get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No records found in database to export")),
          );
        }
        return;
      }

      List<List<dynamic>> rows = [
        ["Date", "Subject", "Absent Count", "Absent Student IDs"]
      ];

      for (var doc in snapshot.docs) {
        // --- DEFENSIVE CHECK: This stops the "Bad State" crash ---
        final data = doc.data();

        // Check if absentUids exists, if not use an empty list
        final List absentees = data.containsKey('absentUids') ? data['absentUids'] : [];

        String docId = doc.id;
        List<String> parts = docId.split('_');

        rows.add([
          parts[0], // Date
          parts.length > 1 ? parts[1] : "General", // Subject
          absentees.length,
          absentees.join(", "),
        ]);
      }

      // 2. Generate and Share the File
      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      // Use a unique name to avoid file-system conflicts
      final path = "${directory.path}/Attendance_Report_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Attendance Report for $batchId');
    } catch (e) {
      if (context.mounted) {
        // This will now show the SPECIFIC reason it's failing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e")),
        );
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If the sub-collection folder doesn't exist yet
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No history records found."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final List absentees = data.containsKey('absentUids') ? data['absentUids'] : [];

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