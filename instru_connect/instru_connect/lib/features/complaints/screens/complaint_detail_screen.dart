import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data()?['role'] as String?;
  }

  // =======================================================
  // OPEN VIDEO IN BROWSER
  // =======================================================

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not open $url';
    }
  }

  // =======================================================
  // BUILD
  // =======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // =================================================
          // TITLE
          // =================================================
          Text(
            complaint.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          // =================================================
          // META INFO
          // =================================================
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                label: complaint.category,
                icon: Icons.category_outlined,
              ),
              _MetaChip(
                label: complaint.status,
                icon: Icons.info_outline,
              ),
              _MetaChip(
                label: 'By ${complaint.createdByRole}',
                icon: Icons.person_outline,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // =================================================
          // DESCRIPTION
          // =================================================
          const _SectionTitle('Description'),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const SizedBox(height: 24),

          // =================================================
          // MEDIA (IMAGE / VIDEO)
          // =================================================
          if (complaint.mediaUrl != null) ...[
            const _SectionTitle('Attachment'),
            const SizedBox(height: 8),

            if (complaint.mediaType == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(complaint.mediaUrl!),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Video in Browser'),
                onPressed: () {
                  _openInBrowser(complaint.mediaUrl!);
                },
              ),

            const SizedBox(height: 24),
          ],

          // =================================================
          // PROGRESS NOTE
          // =================================================
          if (complaint.progressNote != null) ...[
            const _SectionTitle('Progress Note'),
            const SizedBox(height: 8),
            Text(complaint.progressNote!),
            const SizedBox(height: 24),
          ],

          // =================================================
          // ACTIONS
          // =================================================
          if (complaint.assignedTo == null) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Assign Complaint'),
              onPressed: () async {
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
                        'You are not allowed to assign complaints',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          if (complaint.status != 'resolved') ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.update_outlined),
              label: const Text('Update Progress'),
              onPressed: () {
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
    );
  }
}

// =======================================================
// UI COMPONENTS
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

  const _MetaChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
