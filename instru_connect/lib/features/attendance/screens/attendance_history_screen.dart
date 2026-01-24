import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/theme/ui_colors.dart';
import '../../batches/services/batch_service.dart';
import 'mark_attendance_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String batchId;
  final String subjectName;

  const AttendanceHistoryScreen({
    super.key,
    required this.batchId,
    required this.subjectName,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends State<AttendanceHistoryScreen> {
  String? _cachedRole;

  Future<String> _getUserRole() async {
    if (_cachedRole != null) return _cachedRole!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'student';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    _cachedRole = doc.data()?['role'] ?? 'student';
    return _cachedRole!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,

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
                        '${widget.subjectName} History',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= BODY =================
                Expanded(
                  child: FutureBuilder<String>(
                    future: _getUserRole(),
                    builder: (context, roleSnapshot) {
                      if (!roleSnapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final userRole = roleSnapshot.data!;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('batches')
                            .doc(widget.batchId)
                            .collection('attendance')
                            .where('subject',
                                isEqualTo:
                                    widget.subjectName.trim())
                            .orderBy('timestamp',
                                descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                  'Error: ${snapshot.error}'),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                                child:
                                    CircularProgressIndicator());
                          }

                          final docs = snapshot.data!.docs;

                          if (docs.isEmpty) {
                            return const _EmptyState();
                          }

                          return ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(
                                    16, 16, 16, 24),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data()
                                  as Map<String, dynamic>;
                              final List<String> absentees =
                                  List<String>.from(
                                      data['absentUids'] ??
                                          []);

                              return _AttendanceCard(
                                date: data['date'] ?? 'N/A',
                                absentCount: absentees.length,
                                onEdit: () => _navigateToEdit(
                                  doc.id,
                                  absentees,
                                ),
                                onDelete: userRole != 'cr'
                                    ? () =>
                                        _confirmDelete(doc.id)
                                    : null,
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

  void _navigateToEdit(String docId, List<String> absentees) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendanceScreen(
          batchId: widget.batchId,
          subjectName: widget.subjectName,
          isEditing: true,
          docId: docId,
          initialAbsentees: absentees,
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
          'This will permanently remove the record and update student stats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await BatchService()
                  .deleteAttendance(widget.batchId, docId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// ATTENDANCE CARD
// =======================================================

class _AttendanceCard extends StatelessWidget {
  final String date;
  final int absentCount;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _AttendanceCard({
    required this.date,
    required this.absentCount,
    required this.onEdit,
    this.onDelete,
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$absentCount students absent',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            color:
                                UIColors.textSecondary),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.edit,
                  color: UIColors.primary),
              onPressed: onEdit,
            ),

            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete,
                    color: Colors.red),
                onPressed: onDelete,
              ),
          ],
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
              Icons.history_edu,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No attendance records found',
            style:
                TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
