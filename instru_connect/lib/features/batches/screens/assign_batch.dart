import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/batch_service.dart';

class AssignBatchToStudentsScreen extends StatefulWidget {
  const AssignBatchToStudentsScreen({super.key});

  @override
  State<AssignBatchToStudentsScreen> createState() =>
      _AssignBatchToStudentsScreenState();
}

class _AssignBatchToStudentsScreenState
    extends State<AssignBatchToStudentsScreen> {
  final Set<String> selectedStudentIds = {};
  String? selectedBatchId;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Batches to Students'),
      ),

      // ===============================
      // ASSIGN BUTTON
      // ===============================
      floatingActionButton:
          selectedStudentIds.isNotEmpty && selectedBatchId != null
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.check),
                  label: const Text('Assign Batch'),
                  onPressed: () async {
                    try {
                      await BatchService().bulkAssignStudents(
                        studentUids: selectedStudentIds.toList(),
                        batchId: selectedBatchId!,
                      );

                      setState(() {
                        selectedStudentIds.clear();
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Batch assigned successfully'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                )
              : null,

      body: Column(
        children: [
          // ===============================
          // SELECT BATCH
          // ===============================
          Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('batches')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final batches = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  initialValue: selectedBatchId,
                  hint: const Text('Select Batch'),
                  isExpanded: true,
                  items: batches.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBatchId = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ),

          // ===============================
          // SEARCH BAR
          // ===============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          // ===============================
          // STUDENT LIST
          // ===============================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', whereIn: ['student', 'cr'])
                  .snapshots(),
              builder: (context, snapshot) {
                // ERROR
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading students:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // LOADING
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No students found'));
                }

                // -------------------------------
                // FILTER BY SEARCH
                // -------------------------------
                final students =
                    snapshot.data!.docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final name =
                      (data['name'] ?? '').toString().toLowerCase();
                  final email =
                      (data['email'] ?? '').toString().toLowerCase();

                  return name.contains(searchQuery) ||
                      email.contains(searchQuery);
                }).toList();

                if (students.isEmpty) {
                  return const Center(
                      child: Text('No matching students'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = students[index];
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final bool selected =
                        selectedStudentIds.contains(doc.id);

                    final String studentName =
                        _getStudentName(data);
                    final String email =
                        data['email'] ?? '';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context)
                              .dividerColor,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: selected,
                        onChanged: (checked) {
                          setState(() {
                            checked == true
                                ? selectedStudentIds
                                    .add(doc.id)
                                : selectedStudentIds
                                    .remove(doc.id);
                          });
                        },
                        title: Text(
                          studentName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge,
                        ),
                        subtitle: Text(email),
                        secondary: data['batchId'] == null
                            ? const Icon(Icons.info_outline,
                                color: Colors.grey)
                            : const Icon(Icons.check_circle,
                                color: Colors.green),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// NAME RESOLVER (READS FROM users COLLECTION)
/// =======================================================

String _getStudentName(Map<String, dynamic> data) {
  if (data['name'] != null &&
      data['name'].toString().trim().isNotEmpty) {
    return data['name'];
  }
  if (data['displayName'] != null &&
      data['displayName'].toString().trim().isNotEmpty) {
    return data['displayName'];
  }
  return 'Unknown Student';
}
