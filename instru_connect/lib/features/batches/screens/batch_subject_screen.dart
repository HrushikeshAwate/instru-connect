import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_detail_screen.dart';

class BatchSubjectsScreen extends StatelessWidget {
  final String batchId;

  const BatchSubjectsScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showCreateSubjectDialog(context),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .where('batchId', isEqualTo: batchId)
            .snapshots(),
        builder: (context, snapshot) {
          // -------------------------------
          // ERROR
          // -------------------------------
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading subjects:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          // -------------------------------
          // LOADING (ONLY WHILE CONNECTING)
          // -------------------------------
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // -------------------------------
          // EMPTY STATE
          // -------------------------------
          final subjects = snapshot.data?.docs ?? [];

          if (subjects.isEmpty) {
            return const Center(
              child: Text('No subjects created'),
            );
          }

          // -------------------------------
          // LIST
          // -------------------------------
          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final doc = subjects[index];
              final data =
                  doc.data() as Map<String, dynamic>;

              return ListTile(
                leading:
                    const Icon(Icons.menu_book_outlined),
                title: Text(data['name']),
                subtitle: Text(data['code']),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectDetailScreen(
                        subjectName: data['name'],
                        batchId: batchId,
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

  // ===============================
  // CREATE SUBJECT DIALOG
  // ===============================
  Future<void> _showCreateSubjectDialog(
      BuildContext context) async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Create Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Subject Code',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    codeController.text.trim().isEmpty) {
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('subjects')
                    .add({
                  'name': nameController.text.trim(),
                  'code': codeController.text.trim(),
                  'batchId': batchId,
                  'createdAt':
                      FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
