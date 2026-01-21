import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/batches/screens/assign_batch.dart';
import 'batch_subject_screen.dart';
import 'package:instru_connect/features/batches/services/batch_service.dart';
class ManageBatchesScreen extends StatelessWidget {
  const ManageBatchesScreen({super.key});

  // =====================================
  // CREATE BATCH DIALOG (UNCHANGED)
  // =====================================
  Future<void> _showCreateBatchDialog(BuildContext context) async {
    final nameController = TextEditingController();
    int currentYear = 1;

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
                decoration: const InputDecoration(labelText: 'Batch Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: currentYear,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('FY')),
                  DropdownMenuItem(value: 2, child: Text('SY')),
                  DropdownMenuItem(value: 3, child: Text('TY')),
                  DropdownMenuItem(value: 4, child: Text('Final')),
                  DropdownMenuItem(value: 0, child: Text('Alumni')),
                ],
                onChanged: (value) {
                  currentYear = value!;
                },
                decoration: const InputDecoration(labelText: 'Current Year'),
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

                await FirebaseFirestore.instance.collection('batches').add({
                  'name': nameController.text.trim(),
                  'department': 'Instrumentation',
                  'currentYear': currentYear,
                  'isActive': true,
                  'crUserIds': [],
                  'maxCRs': 2,
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batch created successfully')),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPromoteAllDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Promote All Students'),
          content: const Text(
            'This will promote ALL students:\n\n'
            'FY → SY\n'
            'SY → TY\n'
            'TY → Final\n'
            'Final → Alumni\n\n'
            'This action cannot be undone.\n\n'
            'Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              child: const Text('Promote All'),
              onPressed: () async {
                await BatchService().promoteAllStudents();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All students promoted successfully'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // =====================================
  // SCREEN
  // =====================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Batches'),

        // ✅ NEW ACTION ADDED (ONLY CHANGE)
        actions: [
          IconButton(
            tooltip: 'Promote all students',
            icon: const Icon(Icons.trending_up),
            onPressed: () {
              _showPromoteAllDialog(context);
            },
          ),

          IconButton(
            tooltip: 'Assign batches to students',
            icon: const Icon(Icons.assignment_ind_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AssignBatchToStudentsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // ➕ CREATE BATCH (UNCHANGED)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBatchDialog(context),
        child: const Icon(Icons.add),
      ),

      // =====================================
      // BATCH LIST
      // =====================================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('batches')
            .orderBy('currentYear')
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
                currentYear: data['currentYear'],
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
// BATCH TILE (UNCHANGED)
/// =======================================================

class _BatchTile extends StatelessWidget {
  final String batchId;
  final String name;
  final int currentYear;
  final bool isActive;

  const _BatchTile({
    required this.batchId,
    required this.name,
    required this.currentYear,
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
            builder: (_) => BatchSubjectsScreen(batchId: batchId),
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
            // ICON
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups_outlined, color: color),
            ),

            const SizedBox(width: 14),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  _YearChip(year: currentYear),
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
  final int year;

  const _YearChip({required this.year});

  @override
  Widget build(BuildContext context) {
    final label = switch (year) {
      1 => 'FY',
      2 => 'SY',
      3 => 'TY',
      4 => 'Final',
      9 => 'Alumni',
      _ => 'Unknown',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
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
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No batches created yet'),
        ],
      ),
    );
  }
}
