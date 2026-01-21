import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Complaints')),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: stream,
        builder: (context, snapshot) {
          // -----------------------------
          // LOADING
          // -----------------------------
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final complaints = snapshot.data!;

          // -----------------------------
          // EMPTY
          // -----------------------------
          if (complaints.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: complaints.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final complaint = complaints[index];

              return _ComplaintTile(
                complaint: complaint,
              );
            },
          );
        },
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final ComplaintModel complaint;

  const _ComplaintTile({
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(
              complaint: complaint,
            ),
          ),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT STATUS DOT
            _StatusDot(status: complaint.status),

            const SizedBox(width: 12),

            // CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 6),
                  _StatusChip(status: complaint.status),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'submitted':
      return Colors.grey;
    case 'acknowledged':
      return Colors.blue;
    case 'in_progress':
      return Colors.orange;
    case 'resolved':
      return Colors.green;
    default:
      return Colors.grey;
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
          Icon(
            Icons.report_problem_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text('No complaints found'),
        ],
      ),
    );
  }
}
