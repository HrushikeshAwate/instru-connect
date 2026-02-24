import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme/ui_colors.dart';
import '../../batches/services/batch_service.dart';

class EditAttendanceScreen extends StatefulWidget {
  final String batchId;
  final String attendanceDocId;
  final String subjectName;
  final List<String> currentAbsentUids;

  const EditAttendanceScreen({
    super.key,
    required this.batchId,
    required this.attendanceDocId,
    required this.subjectName,
    required this.currentAbsentUids,
  });

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  late Set<String> selectedAbsentIds;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    selectedAbsentIds = Set.from(widget.currentAbsentUids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

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
                      Text(
                        'Edit ${widget.subjectName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= INFO BANNER =================
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UIColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit, color: UIColors.warning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mark students who were ABSENT',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
                        .where('batchId', isEqualTo: widget.batchId)
                        .where('role', whereIn: ['student', 'cr'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final students = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final doc = students[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final uid = doc.id;

                          final name =
                              data['Name'] ?? data['name'] ?? 'Unknown';
                          final mis = (data['MIS No'] ?? data['mis'] ?? 'N/A')
                              .toString();

                          final isAbsent = selectedAbsentIds.contains(uid);

                          return _StudentCard(
                            name: name,
                            mis: mis,
                            isAbsent: isAbsent,
                            onTap: () {
                              setState(() {
                                isAbsent
                                    ? selectedAbsentIds.remove(uid)
                                    : selectedAbsentIds.add(uid);
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

      // ================= SAVE BUTTON =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: UIColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isUpdating ? null : _saveChanges,
            child: _isUpdating
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // =======================================================
  // SAVE
  // =======================================================

  void _saveChanges() async {
    setState(() => _isUpdating = true);

    try {
      final studentQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('batchId', isEqualTo: widget.batchId)
          .where('role', whereIn: ['student', 'cr'])
          .get();

      final allUids = studentQuery.docs.map((e) => e.id).toList();

      await BatchService().updateAttendance(
        batchId: widget.batchId,
        docId: widget.attendanceDocId,
        subjectName: widget.subjectName,
        newAbsentUids: selectedAbsentIds.toList(),
        allStudentUids: allUids,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}

// =======================================================
// STUDENT CARD
// =======================================================

class _StudentCard extends StatelessWidget {
  final String name;
  final String mis;
  final bool isAbsent;
  final VoidCallback onTap;

  const _StudentCard({
    required this.name,
    required this.mis,
    required this.isAbsent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAbsent ? UIColors.error : UIColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  isAbsent ? Icons.person_off : Icons.person,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'MIS: $mis',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isAbsent ? Icons.check_circle : Icons.radio_button_unchecked,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
