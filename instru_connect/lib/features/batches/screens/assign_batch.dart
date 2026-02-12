// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme/ui_colors.dart';
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
      backgroundColor: UIColors.background,

      // ================= FAB =================
      floatingActionButton:
          selectedStudentIds.isNotEmpty && selectedBatchId != null
              ? FloatingActionButton.extended(
                  backgroundColor: UIColors.primary,
                  icon: const Icon(Icons.check),
                  label: const Text('Assign Batch'),
                  onPressed: () async {
                    try {
                      await BatchService().bulkAssignStudents(
                        studentUids: selectedStudentIds.toList(),
                        batchId: selectedBatchId!,
                      );

                      setState(() => selectedStudentIds.clear());

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
                        'Assign Batches',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= CONTROLS =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      // -------- BATCH SELECTOR --------
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('batches')
                              .where('isActive',
                                  isEqualTo: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const LinearProgressIndicator();
                            }

                            final batches =
                                snapshot.data!.docs;

                            return DropdownButtonFormField<String>(
                              initialValue: selectedBatchId,
                              hint:
                                  const Text('Select Batch'),
                              isExpanded: true,
                              items: batches.map((doc) {
                                final data = doc.data()
                                    as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(data['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() =>
                                    selectedBatchId = value);
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -------- SEARCH --------
                      Container(
                        decoration: _cardDecoration(),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText:
                                'Search by name or email',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.all(16),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery =
                                  value.toLowerCase();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= STUDENT LIST =================
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role',
                            whereIn: ['student', 'cr'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final students =
                          snapshot.data!.docs.where((doc) {
                        final data = doc.data()
                            as Map<String, dynamic>;

                        final name = (data['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final email =
                            (data['email'] ?? '')
                                .toString()
                                .toLowerCase();

                        return name.contains(searchQuery) ||
                            email.contains(searchQuery);
                      }).toList();

                      if (students.isEmpty) {
                        return const Center(
                          child:
                              Text('No matching students'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, 24),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final doc = students[index];
                          final data = doc.data()
                              as Map<String, dynamic>;

                          final selected =
                              selectedStudentIds
                                  .contains(doc.id);

                          return _StudentCard(
                            name: _getStudentName(data),
                            email: data['email'] ?? '',
                            assigned:
                                data['batchId'] != null,
                            selected: selected,
                            onChanged: (checked) {
                              setState(() {
                                checked
                                    ? selectedStudentIds
                                        .add(doc.id)
                                    : selectedStudentIds
                                        .remove(doc.id);
                              });
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
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

// =======================================================
// STUDENT CARD
// =======================================================

class _StudentCard extends StatelessWidget {
  final String name;
  final String email;
  final bool assigned;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _StudentCard({
    required this.name,
    required this.email,
    required this.assigned,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
        onChanged: (v) => onChanged(v ?? false),
        title: Text(name,
            style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text(email),
        secondary: Icon(
          assigned
              ? Icons.check_circle
              : Icons.info_outline,
          color:
              assigned ? Colors.green : Colors.grey,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// =======================================================
// NAME RESOLVER
// =======================================================

String _getStudentName(Map<String, dynamic> data) {
  if ((data['name'] ?? '').toString().trim().isNotEmpty) {
    return data['name'];
  }
  if ((data['displayName'] ?? '')
      .toString()
      .trim()
      .isNotEmpty) {
    return data['displayName'];
  }
  return 'Unknown Student';
}
