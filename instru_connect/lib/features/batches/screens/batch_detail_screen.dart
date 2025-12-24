import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/batches/services/batch_service.dart';

class BatchDetailScreen extends StatelessWidget {
  final String batchId;
  final String batchName;

  const BatchDetailScreen({
    super.key,
    required this.batchId,
    required this.batchName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(batchName),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snapshot) {
          // -------------------------------
          // LOADING
          // -------------------------------
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // -------------------------------
          // EMPTY
          // -------------------------------
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          final students = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = students[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name =
                  data['name'] ?? 'Unnamed Student';
              final String? currentBatchId =
                  data['batchId'];

              final bool isAssigned =
                  currentBatchId == batchId;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context)
                        .dividerColor,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge,
                  ),

                  // -------------------------------
                  // STATUS CHIP
                  // -------------------------------
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _StatusChip(
                      currentBatchId: currentBatchId,
                      batchId: batchId,
                    ),
                  ),

                  // -------------------------------
                  // ACTION
                  // -------------------------------
                  trailing: isAssigned
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : TextButton(
                          onPressed: () async {
                            await BatchService()
                                .assignStudentToBatch(
                              studentUid: doc.id,
                              batchId: batchId,
                            );

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Student assigned to batch',
                                ),
                              ),
                            );
                          },
                          child: const Text('Assign'),
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

class _StatusChip extends StatelessWidget {
  final String? currentBatchId;
  final String batchId;

  const _StatusChip({
    required this.currentBatchId,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    if (currentBatchId == batchId) {
      return _chip(
        context,
        label: 'Assigned to this batch',
        color: Colors.green,
      );
    }

    if (currentBatchId == null) {
      return _chip(
        context,
        label: 'Not assigned',
        color: Colors.grey,
      );
    }

    return _chip(
      context,
      label: 'Assigned to another batch',
      color: Colors.orange,
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No students found',
          ),
        ],
      ),
    );
  }
}
