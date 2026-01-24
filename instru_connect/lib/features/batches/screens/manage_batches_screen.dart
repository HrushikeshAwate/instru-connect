import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/batches/screens/assign_batch.dart';
import 'package:instru_connect/features/batches/services/batch_service.dart';
import '../../../config/theme/ui_colors.dart';
import 'batch_subject_screen.dart';

class ManageBatchesScreen extends StatelessWidget {
  const ManageBatchesScreen({super.key});

  // =====================================
  // CREATE BATCH DIALOG
  // =====================================
  Future<void> _showCreateBatchDialog(BuildContext context) async {
    final nameController = TextEditingController();
    int currentYear = 1;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Batch Name'),
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
              onChanged: (v) => currentYear = v!,
              decoration:
                  const InputDecoration(labelText: 'Current Year'),
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
                'currentYear': currentYear,
                'isActive': true,
                'crUserIds': [],
                'maxCRs': 2,
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Batch created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPromoteAllDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Promote All Students'),
        content: const Text(
          'FY → SY\nSY → TY\nTY → Final\nFinal → Alumni\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await BatchService().promoteAllStudents();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('All students promoted successfully')),
              );
            },
            child: const Text('Promote All'),
          ),
        ],
      ),
    );
  }

  // =====================================
  // SCREEN
  // =====================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,

      floatingActionButton: FloatingActionButton(
        backgroundColor: UIColors.primary,
        onPressed: () => _showCreateBatchDialog(context),
        child: const Icon(Icons.add),
      ),

      body: Stack(
        children: [
          // ================= HEADER =================
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ================= CUSTOM APP BAR =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Manage Batches',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.trending_up,
                            color: Colors.white),
                        onPressed: () =>
                            _showPromoteAllDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.assignment_ind_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AssignBatchToStudentsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ================= LIST =================
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('batches')
                        .orderBy('currentYear')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const _EmptyState();
                      }

                      final batches = snapshot.data!.docs;

                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: batches.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final doc = batches[index];
                          final data =
                              doc.data() as Map<String, dynamic>;

                          return _BatchCard(
                            batchId: doc.id,
                            name: data['name'],
                            currentYear: data['currentYear'],
                            isActive: data['isActive'],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// BATCH CARD
// =======================================================

class _BatchCard extends StatelessWidget {
  final String batchId;
  final String name;
  final int currentYear;
  final bool isActive;

  const _BatchCard({
    required this.batchId,
    required this.name,
    required this.currentYear,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BatchSubjectsScreen(batchId: batchId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  gradient: UIColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium),
                    const SizedBox(height: 6),
                    _YearChip(year: currentYear),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: UIColors.textMuted),
            ],
          ),
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
      _ => 'Alumni',
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: UIColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: UIColors.primary,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: UIColors.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_outlined,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'No batches created yet',
            style:
                TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
