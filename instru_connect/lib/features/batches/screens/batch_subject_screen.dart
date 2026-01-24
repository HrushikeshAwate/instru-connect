import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme/ui_colors.dart';
import 'subject_detail_screen.dart';

class BatchSubjectsScreen extends StatelessWidget {
  final String batchId;

  const BatchSubjectsScreen({
    super.key,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,

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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                        );
                      }

                      // LOADING
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final subjects =
                          snapshot.data?.docs ?? [];

                      // EMPTY
                      if (subjects.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 24),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final doc = subjects[index];
                          final data =
                              doc.data() as Map<String, dynamic>;

                          return _SubjectCard(
                            name: data['name'],
                            code: data['code'],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SubjectDetailScreen(
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

// =======================================================
// SUBJECT CARD (WHITE TILE LIKE NOTICE/RESOURCE)
// =======================================================

class _SubjectCard extends StatelessWidget {
  final String name;
  final String code;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.name,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        code,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  UIColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: UIColors.textMuted,
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
