import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      appBar: AppBar(title: Text(subjectName)),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['student', 'cr'])
            .where('batchId', isEqualTo: batchId)
            .snapshots(),

        builder: (context, snapshot) {
          // -------------------------------
          // ERROR (IMPORTANT)
          // -------------------------------
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading students:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // -------------------------------
          // LOADING
          // -------------------------------
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // -------------------------------
          // EMPTY
          // -------------------------------
          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No students found in this batch'),
            );
          }

          final students = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data =
                  students[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(data['name'] ?? 'Unnamed Student'),
                subtitle: Text(data['email'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
