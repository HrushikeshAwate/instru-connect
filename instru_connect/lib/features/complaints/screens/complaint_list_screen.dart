import 'package:flutter/material.dart';

import '../../../config/theme/ui_colors.dart';
import '../models/complaint_model.dart';
import 'complaint_detail_screen.dart';

class ComplaintListScreen extends StatelessWidget {
  final Stream<List<ComplaintModel>> stream;

  const ComplaintListScreen({
    super.key,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,
      body: Stack(
        children: [
          // ================= HEADER GRADIENT =================
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
                // ================= CUSTOM APP BAR =================
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Complaints',
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
                  child: StreamBuilder<List<ComplaintModel>>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final complaints = snapshot.data!;

                      if (complaints.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                        itemCount: complaints.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _ComplaintCard(
                            complaint: complaints[index],
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
}

// =======================================================
// COMPLAINT CARD
// =======================================================

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;

  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(complaint.status);
    final statusGradient = _statusGradient(complaint.status);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(complaint: complaint),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS STRIP
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                gradient: statusGradient,
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            const SizedBox(width: 14),

            // CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _StatusChip(status: complaint.status),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded,
                color: UIColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// STATUS CHIP
// =======================================================

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final gradient = _statusGradient(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: UIColors.softBackgroundGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.report_problem_outlined,
              size: 48,
              color: UIColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No complaints found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: UIColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// STATUS HELPERS
// =======================================================

Color _statusColor(String status) {
  switch (status) {
    case 'submitted':
      return UIColors.info;
    case 'acknowledged':
      return UIColors.primary;
    case 'in_progress':
      return UIColors.warning;
    case 'resolved':
      return UIColors.success;
    default:
      return UIColors.textMuted;
  }
}

Gradient _statusGradient(String status) {
  switch (status) {
    case 'submitted':
      return UIColors.secondaryGradient;
    case 'acknowledged':
      return UIColors.primaryGradient;
    case 'in_progress':
      return UIColors.warningGradient;
    case 'resolved':
      return UIColors.successGradient;
    default:
      return UIColors.softBackgroundGradient;
  }
}
