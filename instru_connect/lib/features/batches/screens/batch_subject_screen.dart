// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/activity_notification_service.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';

import '../../../config/theme/ui_colors.dart';
import '../services/batch_service.dart';
import 'subject_detail_screen.dart';

class BatchSubjectsScreen extends StatefulWidget {
  final String batchId;

  const BatchSubjectsScreen({super.key, required this.batchId});

  @override
  State<BatchSubjectsScreen> createState() => _BatchSubjectsScreenState();
}

class _BatchSubjectsScreenState extends State<BatchSubjectsScreen> {
  final BatchService _batchService = BatchService();
  final ActivityNotificationService _activityNotifications =
      ActivityNotificationService();
  final Set<String> _selectedSubjectIds = <String>{};
  late final Stream<QuerySnapshot> _subjectsStream;
  List<QueryDocumentSnapshot> _visibleSubjects = const <QueryDocumentSnapshot>[];
  bool _selectionMode = false;
  bool _deleting = false;

  bool get _canManageSubjects => _batchService.canManageSubjects;

  @override
  void initState() {
    super.initState();
    _subjectsStream = FirebaseFirestore.instance
        .collection('subjects')
        .where('batchId', isEqualTo: widget.batchId)
        .snapshots();
  }

  void _toggleSelection(String subjectId) {
    if (!_canManageSubjects) return;
    setState(() {
      _selectionMode = true;
      if (_selectedSubjectIds.contains(subjectId)) {
        _selectedSubjectIds.remove(subjectId);
      } else {
        _selectedSubjectIds.add(subjectId);
      }
      if (_selectedSubjectIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedSubjectIds.clear();
    });
  }

  void _syncSelectionWithVisibleItems(List<QueryDocumentSnapshot> subjects) {
    final visibleIds = subjects.map((subject) => subject.id).toSet();
    final staleIds = _selectedSubjectIds.difference(visibleIds);
    if (staleIds.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedSubjectIds.removeWhere((id) => !visibleIds.contains(id));
        if (_selectedSubjectIds.isEmpty) {
          _selectionMode = false;
        }
      });
    });
  }

  Future<void> _showCreateSubjectDialog(BuildContext context) async {
    if (!_canManageSubjects) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin or faculty can manage subjects.')),
      );
      return;
    }

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
                  'batchId': widget.batchId,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                await _activityNotifications.notifyBatchStudentsAndCr(
                  batchId: widget.batchId,
                  title: 'New Subject Added',
                  body: nameController.text.trim(),
                  type: 'subject_created',
                  data: {
                    'batchId': widget.batchId,
                    'subjectName': nameController.text.trim(),
                    'subjectCode': codeController.text.trim(),
                  },
                );

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedSubjects(List<QueryDocumentSnapshot> subjects) async {
    final selected = subjects
        .where((doc) => _selectedSubjectIds.contains(doc.id))
        .toList();
    if (selected.isEmpty) return;

    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Delete Subjects?',
      message:
          'You are about to permanently delete ${selected.length} selected subject(s). Related attendance history and linked subject data may also be removed, and this action cannot be undone or recovered.',
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _batchService.deleteSubjectsCascade(
        batchId: widget.batchId,
        subjects: selected
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, String>{
                'id': doc.id,
                'name': (data['name'] ?? '').toString(),
              };
            })
            .toList(),
      );
      if (!mounted) return;
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.length} subject(s) deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _canManageSubjects
          ? FloatingActionButton(
              backgroundColor: UIColors.primary,
              child: const Icon(Icons.add),
              onPressed: () => _showCreateSubjectDialog(context),
            )
          : null,
      body: Stack(
        children: [
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _selectionMode
                              ? Icons.close_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _selectionMode
                            ? _clearSelection
                            : () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          _selectionMode
                              ? '${_selectedSubjectIds.length} selected'
                              : 'Subjects',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_selectionMode)
                        IconButton(
                          onPressed: _deleting
                              ? null
                              : () => _deleteSelectedSubjects(_visibleSubjects),
                          icon: _deleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _subjectsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading subjects',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final subjects = snapshot.data?.docs ?? [];
                      _visibleSubjects = subjects;
                      _syncSelectionWithVisibleItems(subjects);
                      if (subjects.isEmpty) {
                        return const _EmptyState();
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                24,
                              ),
                              itemCount: subjects.length,
                              itemBuilder: (context, index) {
                                final doc = subjects[index];
                                final data = doc.data() as Map<String, dynamic>;

                                return _SubjectCard(
                                  key: ValueKey(doc.id),
                                  name: data['name'],
                                  code: data['code'],
                                  selectionMode: _selectionMode,
                                  selected: _selectedSubjectIds.contains(doc.id),
                                  onTap: () {
                                    if (_selectionMode) {
                                      _toggleSelection(doc.id);
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubjectDetailScreen(
                                          subjectName: data['name'],
                                          batchId: widget.batchId,
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: () => _toggleSelection(doc.id),
                                );
                              },
                            ),
                          ),
                        ],
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

class _SubjectCard extends StatelessWidget {
  final Key? key;
  final String name;
  final String code;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SubjectCard({
    this.key,
    required this.name,
    required this.code,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: selectionMode && selected
            ? Border.all(color: UIColors.primary, width: 2)
            : null,
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
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                if (selectionMode) ...[
                  Checkbox(value: selected, onChanged: (_) => onTap()),
                  const SizedBox(width: 4),
                ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium),
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
                if (!selectionMode)
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
            decoration: const BoxDecoration(
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
            'No subjects yet',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
