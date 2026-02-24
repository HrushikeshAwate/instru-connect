// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme/ui_colors.dart';
import 'subject_detail_screen.dart';

class BatchSubjectsScreen extends StatelessWidget {
  final String batchId;

  const BatchSubjectsScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ================= FAB =================
      floatingActionButton: FloatingActionButton(
        backgroundColor: UIColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showCreateSubjectDialog(context),
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
                // ================= APP BAR =================
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
                        'Subjects',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= LIST =================
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('subjects')
                        .where('batchId', isEqualTo: batchId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ERROR
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading subjects',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }

                      // LOADING
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final subjects = snapshot.data?.docs ?? [];

                      // EMPTY
                      if (subjects.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final doc = subjects[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return _SubjectCard(
                            name: data['name'],
                            code: data['code'],
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
                            onDelete: () => _confirmDeleteSubject(
                              context,
                              subjectId: doc.id,
                              subjectName: (data['name'] ?? '').toString(),
                            ),
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

  // ===============================
  // CREATE SUBJECT DIALOG
  // ===============================
  Future<void> _showCreateSubjectDialog(BuildContext context) async {
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
                decoration: const InputDecoration(labelText: 'Subject Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Subject Code'),
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

                await FirebaseFirestore.instance.collection('subjects').add({
                  'name': nameController.text.trim(),
                  'code': codeController.text.trim(),
                  'batchId': batchId,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteSubject(
    BuildContext context, {
    required String subjectId,
    required String subjectName,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Delete "$subjectName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: UIColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subject deleted')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete subject: $e')));
    }
  }
}

// =======================================================
// SUBJECT CARD (WHITE TILE LIKE NOTICE/RESOURCE)
// =======================================================

class _SubjectCard extends StatelessWidget {
  final String name;
  final String code;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.name,
    required this.code,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // LEFT STRIP
                Container(
                  width: 6,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: UIColors.primaryGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 14),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        code,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: UIColors.textMuted,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete Subject'),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: UIColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            child: const Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No subjects created',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
