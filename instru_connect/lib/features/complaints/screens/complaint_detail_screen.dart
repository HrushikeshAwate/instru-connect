import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/ui_colors.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import 'assign_complaint_screen.dart';
import 'update_complaint_progress.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final ComplaintModel complaint;
  static final ComplaintService _complaintService = ComplaintService();

  const ComplaintDetailScreen({super.key, required this.complaint});

  // =======================================================
  // FETCH CURRENT USER ROLE
  // =======================================================
  Future<String?> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['role'] as String?;
  }

  Future<Map<String, dynamic>> _getComplaintPermissions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final role = await _getUserRole();

    final normalizedRole = (role ?? '').toLowerCase();
    final canAssignComplaint = normalizedRole == 'admin';
    final canUpdateComplaint =
        normalizedRole == 'admin' || normalizedRole == 'faculty';
    final canDeleteComplaint = normalizedRole == 'admin';
    final canUseCoordinationNotes =
        normalizedRole == 'admin' ||
        (complaint.assignedTo != null && complaint.assignedTo == uid);

    return {
      'role': normalizedRole,
      'canAssignComplaint': canAssignComplaint,
      'canUpdateComplaint': canUpdateComplaint,
      'canDeleteComplaint': canDeleteComplaint,
      'canUseCoordinationNotes': canUseCoordinationNotes,
    };
  }

  // =======================================================
  // OPEN VIDEO IN BROWSER
  // =======================================================
  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _reporterLabel() {
    if (complaint.isAnonymous) {
      return 'Anonymous Reporter';
    }
    return 'By ${complaint.createdByRole}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ================= HEADER GRADIENT =================
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // ================= CUSTOM APP BAR =================
                Row(
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
                        'Complaint Details',
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

                const SizedBox(height: 20),

                // ================= MAIN CARD =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: UIColors.primary.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      Text(
                        complaint.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),

                      const SizedBox(height: 12),

                      // META CHIPS
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            label: complaint.category,
                            icon: Icons.category_outlined,
                            gradient: UIColors.secondaryGradient,
                          ),
                          _MetaChip(
                            label: complaint.status,
                            icon: Icons.info_outline,
                            gradient: complaint.status == 'resolved'
                                ? UIColors.successGradient
                                : UIColors.warningGradient,
                          ),
                          _MetaChip(
                            label: _reporterLabel(),
                            icon: Icons.person_outline,
                            gradient: UIColors.primaryGradient,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const _SectionTitle('Complaint Stage'),
                      const SizedBox(height: 10),
                      _ComplaintStageTracker(currentStatus: complaint.status),

                      const SizedBox(height: 24),

                      // DESCRIPTION
                      const _SectionTitle('Description'),
                      const SizedBox(height: 8),
                      Text(
                        complaint.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),

                      const SizedBox(height: 24),

                      // ATTACHMENT
                      if (complaint.mediaUrl != null) ...[
                        const _SectionTitle('Attachment'),
                        const SizedBox(height: 8),
                        if (complaint.mediaType == 'image')
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(complaint.mediaUrl!),
                          )
                        else
                          OutlinedButton.icon(
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Video'),
                            onPressed: () =>
                                _openInBrowser(complaint.mediaUrl!),
                          ),
                        const SizedBox(height: 24),
                      ],

                      // PROGRESS NOTE
                      if (complaint.progressNote != null) ...[
                        const _SectionTitle('Progress Note'),
                        const SizedBox(height: 8),
                        Text(complaint.progressNote!),
                        const SizedBox(height: 24),
                      ],

                      if (complaint.assignedRole != null &&
                          complaint.assignedRole!.trim().isNotEmpty) ...[
                        const _SectionTitle('Assigned To'),
                        const SizedBox(height: 8),
                        Text(
                          complaint.assignedRole!
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ================= ACTIONS =================
                FutureBuilder<Map<String, dynamic>>(
                  future: _getComplaintPermissions(),
                  builder: (context, snapshot) {
                    final permissions =
                        snapshot.data ?? const <String, dynamic>{};
                    final role = (permissions['role'] ?? '').toString();
                    final canAssignComplaint =
                        permissions['canAssignComplaint'] == true;
                    final canUpdateComplaint =
                        permissions['canUpdateComplaint'] == true;
                    final canDeleteComplaint =
                        permissions['canDeleteComplaint'] == true;
                    final canUseCoordinationNotes =
                        permissions['canUseCoordinationNotes'] == true;

                    if (!canAssignComplaint &&
                        !canUpdateComplaint &&
                        !canDeleteComplaint &&
                        !canUseCoordinationNotes) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        if (complaint.assignedTo == null && canAssignComplaint)
                          _GradientButton(
                            label: 'Assign Complaint',
                            icon: Icons.assignment_ind_outlined,
                            gradient: UIColors.primaryGradient,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssignComplaintScreen(
                                    complaintId: complaint.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (complaint.assignedTo == null && canAssignComplaint)
                          const SizedBox(height: 12),
                        if (canUpdateComplaint)
                          _GradientButton(
                            label: complaint.status == 'resolved'
                                ? 'Reopen / Update Complaint'
                                : 'Update Progress',
                            icon: complaint.status == 'resolved'
                                ? Icons.refresh_rounded
                                : Icons.update_outlined,
                            gradient: UIColors.secondaryGradient,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UpdateComplaintProgressScreen(
                                    complaintId: complaint.id,
                                    currentStatus: complaint.status,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (canUpdateComplaint) const SizedBox(height: 12),
                        if (canUseCoordinationNotes) ...[
                          _CoordinationNotesSection(
                            complaintId: complaint.id,
                            complaintStatus: complaint.status,
                            complaintService: _complaintService,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (canDeleteComplaint)
                          _GradientButton(
                            label: 'Delete Complaint',
                            icon: Icons.delete_outline_rounded,
                            gradient: UIColors.errorGradient,
                            onTap: () async {
                              final confirmed =
                                  await showDestructiveConfirmationDialog(
                                    context: context,
                                    title: 'Delete Complaint?',
                                    message:
                                        'This complaint will be permanently deleted and cannot be recovered. Any linked complaint data or progress notes will also be removed.',
                                  );
                              if (confirmed != true) return;

                              try {
                                await _complaintService.deleteComplaint(
                                  complaintId: complaint.id,
                                  actorRole: role,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                              }
                            },
                          ),
                      ],
                    );
                  },
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
// REUSABLE UI COMPONENTS
// =======================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _CoordinationNotesSection extends StatefulWidget {
  final String complaintId;
  final String complaintStatus;
  final ComplaintService complaintService;

  const _CoordinationNotesSection({
    required this.complaintId,
    required this.complaintStatus,
    required this.complaintService,
  });

  @override
  State<_CoordinationNotesSection> createState() =>
      _CoordinationNotesSectionState();
}

class _CoordinationNotesSectionState extends State<_CoordinationNotesSection> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.complaintService.addCoordinationNote(
        complaintId: widget.complaintId,
        message: _controller.text,
      );
      _controller.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Coordination Notes'),
          const SizedBox(height: 6),
          Text(
            'A lightweight internal log for admin and the assigned member.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.complaintService.streamCoordinationNotes(
              widget.complaintId,
            ),
            builder: (context, snapshot) {
              final notes = snapshot.data ?? const <Map<String, dynamic>>[];
              if (notes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text('No coordination notes yet.'),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: notes.map((note) {
                    final createdAt = note['createdAt'];
                    final timestamp = createdAt is Timestamp
                        ? createdAt.toDate()
                        : null;
                    final byline =
                        '${(note['createdByName'] ?? 'Unknown').toString()} | ${(note['createdByRole'] ?? '').toString().toUpperCase()}';
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            byline,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (timestamp != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 6),
                              child: Text(
                                '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          Text((note['message'] ?? '').toString()),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Add coordination note',
              hintText: 'Leave a short update or question',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                widget.complaintStatus == 'resolved'
                    ? 'Add Reopen Note'
                    : 'Post Note',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintStageTracker extends StatelessWidget {
  final String currentStatus;

  const _ComplaintStageTracker({required this.currentStatus});

  static const List<String> _orderedStages = [
    'submitted',
    'acknowledged',
    'in_progress',
    'resolved',
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _orderedStages.indexOf(currentStatus);

    return Column(
      children: List.generate(_orderedStages.length, (index) {
        final stage = _orderedStages[index];
        final isReached = currentIndex >= index && currentIndex != -1;
        final isLast = index == _orderedStages.length - 1;
        final color = isReached ? UIColors.primary : UIColors.textMuted;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isReached ? 0.14 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isReached
                        ? Icons.check_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 26,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color.withValues(alpha: 0.28),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelFor(stage),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isReached ? null : UIColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _descriptionFor(stage),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _labelFor(String stage) {
    switch (stage) {
      case 'submitted':
        return 'Submitted';
      case 'acknowledged':
        return 'Assigned / Acknowledged';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return stage.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _descriptionFor(String stage) {
    switch (stage) {
      case 'submitted':
        return 'Your complaint has been created and is waiting for review.';
      case 'acknowledged':
        return 'The complaint has been seen and assigned for action.';
      case 'in_progress':
        return 'Work is currently underway to address the issue.';
      case 'resolved':
        return 'The complaint has been marked resolved.';
      default:
        return '';
    }
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;

  const _MetaChip({
    required this.label,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
