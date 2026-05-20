// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/ui_colors.dart';
import '../../../core/utils/batch_ordering.dart';
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
  String filterMode = 'unassigned';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton:
          selectedStudentIds.isNotEmpty && selectedBatchId != null
          ? FloatingActionButton.extended(
              backgroundColor: UIColors.primary,
              icon: const Icon(Icons.check),
              label: Text(
                selectedStudentIds.length == 1
                    ? 'Assign 1 Student'
                    : 'Assign ${selectedStudentIds.length} Students',
              ),
              onPressed: () async {
                try {
                  await BatchService().bulkAssignStudents(
                    studentUids: selectedStudentIds.toList(),
                    batchId: selectedBatchId!,
                  );

                  setState(() => selectedStudentIds.clear());

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Batch assigned successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
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
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Assign Batches',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(context),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('batches')
                              .where('isActive', isEqualTo: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const LinearProgressIndicator();
                            }

                            final batches = snapshot.data!.docs.toList()
                              ..sort((a, b) {
                                final aData = a.data() as Map<String, dynamic>;
                                final bData = b.data() as Map<String, dynamic>;
                                final aName = (aData['name'] ?? '').toString();
                                final bName = (bData['name'] ?? '').toString();
                                final rankCompare = BatchOrdering.rankForName(
                                  aName,
                                ).compareTo(BatchOrdering.rankForName(bName));
                                if (rankCompare != 0) return rankCompare;
                                return aName.toLowerCase().compareTo(
                                  bName.toLowerCase(),
                                );
                              });

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Batch',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Choose the destination batch first, then select the students below.',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedBatchId,
                                  hint: const Text('Select Batch'),
                                  isExpanded: true,
                                  items: batches.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final year =
                                        (data['currentYear'] as num?)
                                            ?.toInt() ??
                                        0;
                                    return DropdownMenuItem(
                                      value: doc.id,
                                      child: Text(
                                        '${data['name']} • ${_yearLabel(year)}',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => selectedBatchId = value);
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(context),
                        child: Column(
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search by name, MIS, or email',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value.toLowerCase();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _FilterChipButton(
                                    label: 'Unassigned',
                                    selected: filterMode == 'unassigned',
                                    onTap: () {
                                      setState(() => filterMode = 'unassigned');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _FilterChipButton(
                                    label: 'Assigned',
                                    selected: filterMode == 'assigned',
                                    onTap: () {
                                      setState(() => filterMode = 'assigned');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _FilterChipButton(
                                    label: 'All',
                                    selected: filterMode == 'all',
                                    onTap: () {
                                      setState(() => filterMode = 'all');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', whereIn: ['student', 'cr'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final students =
                          snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            final email = (data['email'] ?? '')
                                .toString()
                                .toLowerCase();
                            final mis = (data['MIS No'] ?? data['mis'] ?? '')
                                .toString()
                                .toLowerCase();
                            final hasBatch = (data['batchId'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty;

                            final matchesFilter = switch (filterMode) {
                              'assigned' => hasBatch,
                              'all' => true,
                              _ => !hasBatch,
                            };

                            return matchesFilter &&
                                (name.contains(searchQuery) ||
                                    email.contains(searchQuery) ||
                                    mis.contains(searchQuery));
                          }).toList()..sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aAssigned = (aData['batchId'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty;
                            final bAssigned = (bData['batchId'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty;
                            if (aAssigned != bAssigned) {
                              return aAssigned ? 1 : -1;
                            }
                            return _getStudentName(
                              aData,
                            ).toLowerCase().compareTo(
                              _getStudentName(bData).toLowerCase(),
                            );
                          });

                      if (students.isEmpty) {
                        return Center(
                          child: Text(
                            'No students match this view.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('batches')
                            .snapshots(),
                        builder: (context, batchSnapshot) {
                          final batchNameById = <String, String>{};
                          if (batchSnapshot.hasData) {
                            for (final doc in batchSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              batchNameById[doc.id] = (data['name'] ?? '')
                                  .toString();
                            }
                          }

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${students.length} students shown',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '${selectedStudentIds.length} selected',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    24,
                                  ),
                                  itemCount: students.length,
                                  itemBuilder: (context, index) {
                                    final doc = students[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final selected = selectedStudentIds
                                        .contains(doc.id);
                                    final batchId = (data['batchId'] ?? '')
                                        .toString();

                                    return _StudentCard(
                                      name: _getStudentName(data),
                                      email: (data['email'] ?? '').toString(),
                                      mis: (data['MIS No'] ?? data['mis'] ?? '')
                                          .toString(),
                                      currentBatch: batchNameById[batchId],
                                      assigned: batchId.isNotEmpty,
                                      selected: selected,
                                      onChanged: (checked) {
                                        setState(() {
                                          checked
                                              ? selectedStudentIds.add(doc.id)
                                              : selectedStudentIds.remove(
                                                  doc.id,
                                                );
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
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

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: UIColors.primary.withValues(alpha: 0.10),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String name;
  final String email;
  final String mis;
  final String? currentBatch;
  final bool assigned;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _StudentCard({
    required this.name,
    required this.email,
    required this.mis,
    required this.currentBatch,
    required this.assigned,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            if (mis.isNotEmpty) Text('MIS: $mis'),
            const SizedBox(height: 4),
            Text(
              assigned
                  ? 'Current batch: ${currentBatch ?? 'Assigned'}'
                  : 'Currently unassigned',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: assigned ? UIColors.primary : UIColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        secondary: Icon(
          assigned ? Icons.check_circle : Icons.info_outline,
          color: assigned ? Colors.green : Colors.grey,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

String _getStudentName(Map<String, dynamic> data) {
  if ((data['name'] ?? '').toString().trim().isNotEmpty) {
    return data['name'];
  }
  if ((data['displayName'] ?? '').toString().trim().isNotEmpty) {
    return data['displayName'];
  }
  return 'Unknown Student';
}

String _yearLabel(int year) {
  switch (year) {
    case 1:
      return 'FY';
    case 2:
      return 'SY';
    case 3:
      return 'TY';
    case 4:
      return 'Fourth Year';
    default:
      return 'Alumni';
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? UIColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? UIColors.primary : UIColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
