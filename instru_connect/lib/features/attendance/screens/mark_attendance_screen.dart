import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme/ui_colors.dart';
import '../../batches/services/batch_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String batchId;
  final String subjectName;
  final bool isEditing;
  final String? docId;
  final List<String>? initialAbsentees;

  const MarkAttendanceScreen({
    super.key,
    required this.batchId,
    required this.subjectName,
    this.isEditing = false,
    this.docId,
    this.initialAbsentees,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final BatchService _batchService = BatchService();
  final TextEditingController _searchController = TextEditingController();

  final Map<String, bool> absentStatus = {};
  bool _isSaving = false;
  bool _hasInitialized = false;
  String _searchQuery = '';

  // =======================================================
  // SAVE
  // =======================================================

  Future<void> _handleSave() async {
    final allUids = absentStatus.keys.toList();
    final absentUids = absentStatus.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (allUids.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing && widget.docId != null) {
        await _batchService.updateAttendance(
          batchId: widget.batchId,
          docId: widget.docId!,
          subjectName: widget.subjectName,
          newAbsentUids: absentUids,
          allStudentUids: allUids,
        );
      } else {
        await _batchService.submitAttendance(
          batchId: widget.batchId,
          subjectName: widget.subjectName,
          absentStudentUids: absentUids,
          allStudentUids: allUids,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // =======================================================
  // UI
  // =======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Stack(
        children: [
          // ================= HEADER =================
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: widget.isEditing
                  ? UIColors.warningGradient
                  : UIColors.heroGradient,
              borderRadius: const BorderRadius.only(
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
                        widget.isEditing
                            ? 'Edit Attendance'
                            : 'Mark Attendance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= SEARCH =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search name or MIS',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // ================= INFO =================
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UIColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: UIColors.error),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tap students who are ABSENT',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= LIST =================
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('batchId', isEqualTo: widget.batchId)
                        .where('role', whereIn: ['student', 'cr'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      // INIT MAP
                      if (!_hasInitialized) {
                        for (var doc in docs) {
                          absentStatus[doc.id] =
                              widget.isEditing &&
                                  widget.initialAbsentees != null
                              ? widget.initialAbsentees!.contains(doc.id)
                              : false;
                        }
                        _hasInitialized = true;
                      }

                      final filtered = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['Name'] ?? data['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final mis = (data['MIS No'] ?? data['mis'] ?? '')
                            .toString()
                            .toLowerCase();
                        return name.contains(_searchQuery.toLowerCase()) ||
                            mis.contains(_searchQuery.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final uid = doc.id;

                          final name =
                              data['Name'] ?? data['name'] ?? 'Unknown';
                          final mis = (data['MIS No'] ?? data['mis'] ?? 'N/A')
                              .toString();

                          final isAbsent = absentStatus[uid] ?? false;

                          return _StudentCard(
                            name: name,
                            mis: mis,
                            isAbsent: isAbsent,
                            onTap: () {
                              setState(() {
                                absentStatus[uid] = !isAbsent;
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

      // ================= SAVE =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isEditing
                  ? UIColors.warning
                  : UIColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.isEditing ? 'UPDATE CHANGES' : 'CONFIRM ATTENDANCE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
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
