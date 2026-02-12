import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/ui_colors.dart';
import '../models/complaint_model.dart';
import 'assign_complaint_screen.dart';
import 'update_complaint_progress.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
  });

  // =======================================================
  // FETCH CURRENT USER ROLE
  // =======================================================
  Future<String?> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  // =======================================================
  // OPEN VIDEO IN BROWSER
  // =======================================================
  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Complaint Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ================= MAIN CARD =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                            label: 'By ${complaint.createdByRole}',
                            icon: Icons.person_outline,
                            gradient: UIColors.primaryGradient,
                          ),
                        ],
                      ),

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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ================= ACTIONS =================
                if (complaint.assignedTo == null)
                  _GradientButton(
                    label: 'Assign Complaint',
                    icon: Icons.assignment_ind_outlined,
                    gradient: UIColors.primaryGradient,
                    onTap: () async {
                      final role = await _getUserRole();
                      if (role == 'admin' && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignComplaintScreen(
                              complaintId: complaint.id,
                            ),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'You are not allowed to assign complaints'),
                          ),
                        );
                      }
                    },
                  ),

                if (complaint.status != 'resolved') ...[
                  const SizedBox(height: 12),
                  _GradientButton(
                    label: 'Update Progress',
                    icon: Icons.update_outlined,
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
                ],
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: onTap,
      ),
    );
  }
}
