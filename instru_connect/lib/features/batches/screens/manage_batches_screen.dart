import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/batches/screens/batch_detail_screen.dart';

class ManageBatchesScreen extends StatelessWidget {
  const ManageBatchesScreen({super.key});

  Future<void> _showCreateBatchDialog(BuildContext context) async {
    final nameController = TextEditingController();
    String academicYear = 'FY';

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Create Batch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Batch Name',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: academicYear,
                items: const [
                  DropdownMenuItem(value: 'FY', child: Text('FY')),
                  DropdownMenuItem(value: 'SY', child: Text('SY')),
                  DropdownMenuItem(value: 'TY', child: Text('TY')),
                  DropdownMenuItem(value: 'FINAL', child: Text('FINAL')),
                ],
                onChanged: (value) {
                  academicYear = value!;
                },
                decoration: const InputDecoration(
                  labelText: 'Academic Year',
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
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('batches')
                    .add({
                  'name': nameController.text.trim(),
                  'department': 'Instrumentation',
                  'academicYear': academicYear,
                  'isActive': true,
                  'crIds': [],
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batch created')),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Batches')),

      // ➕ CREATE BATCH (FAB is correct here)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBatchDialog(context),
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('batches')
            .orderBy('academicYear')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          final batches = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: batches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = batches[index];
              final data = doc.data() as Map<String, dynamic>;

              return _BatchTile(
                batchId: doc.id,
                name: data['name'],
                academicYear: data['academicYear'],
                isActive: data['isActive'],
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// BATCH TILE (POLISHED)
// =======================================================

class _BatchTile extends StatelessWidget {
  final String batchId;
  final String name;
  final String academicYear;
  final bool isActive;

  const _BatchTile({
    required this.batchId,
    required this.name,
    required this.academicYear,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BatchDetailScreen(
              batchId: batchId,
              batchName: name,
            ),
          ),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Row(
          children: [
            // LEFT ICON
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                color: color,
              ),
            ),

            const SizedBox(width: 14),

            // TITLE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style:
                        Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  _YearChip(year: academicYear),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// YEAR CHIP
// =======================================================

class _YearChip extends StatelessWidget {
  final String year;

  const _YearChip({required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        year,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// =======================================================
// EMPTY STATE
// =======================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text('No batches created yet'),
        ],
      ),
    );
  }
}
