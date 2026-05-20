import 'package:flutter/material.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';

import '../../../config/theme/ui_colors.dart';
import '../models/complaint_model.dart';
import 'complaint_detail_screen.dart';
import 'create_complaint_screen.dart';

class ComplaintListScreen extends StatefulWidget {
  final Stream<List<ComplaintModel>>? stream;

  const ComplaintListScreen({super.key, this.stream});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final Set<String> _selectedComplaintIds = <String>{};
  List<ComplaintModel> _visibleComplaints = const <ComplaintModel>[];
  bool _selectionMode = false;
  bool _deleting = false;

  bool get _canCreateComplaints {
    final role = (CurrentUser.role ?? '').toLowerCase();
    return role == AppRoles.student ||
        role == AppRoles.cr ||
        role == AppRoles.faculty ||
        role == AppRoles.staff;
  }

  String get _screenTitle {
    final role = (CurrentUser.role ?? '').toLowerCase();
    if (role == AppRoles.student || role == AppRoles.cr) {
      return 'My Complaints';
    }
    return 'Complaints';
  }

  bool get _canManageComplaints {
    final role = (CurrentUser.role ?? '').toLowerCase();
    return role == AppRoles.admin;
  }

  void _toggleSelection(ComplaintModel complaint) {
    if (!_canManageComplaints) return;
    setState(() {
      _selectionMode = true;
      if (_selectedComplaintIds.contains(complaint.id)) {
        _selectedComplaintIds.remove(complaint.id);
      } else {
        _selectedComplaintIds.add(complaint.id);
      }
      if (_selectedComplaintIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedComplaintIds.clear();
    });
  }

  void _syncSelectionWithVisibleItems(List<ComplaintModel> complaints) {
    final visibleIds = complaints.map((complaint) => complaint.id).toSet();
    final staleIds = _selectedComplaintIds.difference(visibleIds);
    if (staleIds.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedComplaintIds.removeWhere((id) => !visibleIds.contains(id));
        if (_selectedComplaintIds.isEmpty) {
          _selectionMode = false;
        }
      });
    });
  }

  Future<void> _deleteComplaints(List<ComplaintModel> complaints) async {
    final selected = complaints
        .where((complaint) => _selectedComplaintIds.contains(complaint.id))
        .toList();
    if (selected.isEmpty) return;

    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Delete Complaints?',
      message:
          'You are about to permanently delete ${selected.length} selected complaint(s). Their details and progress history will not be recoverable after deletion.',
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      final role = (CurrentUser.role ?? '').toLowerCase();
      await _complaintService.deleteComplaints(
        complaintIds: selected.map((complaint) => complaint.id).toList(),
        actorRole: role,
      );
      if (!mounted) return;
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.length} complaint(s) deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _selectionMode
                              ? Icons.close_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _selectionMode
                            ? _clearSelection
                            : () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          _selectionMode
                              ? '${_selectedComplaintIds.length} selected'
                              : _screenTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_selectionMode && _canCreateComplaints)
                        IconButton(
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateComplaintScreen(),
                              ),
                            );
                          },
                        ),
                      if (_selectionMode)
                        IconButton(
                          onPressed: _deleting
                              ? null
                              : () => _deleteComplaints(_visibleComplaints),
                          icon: _deleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ComplaintModel>>(
                    stream:
                        widget.stream ??
                        _complaintService.streamForCurrentUser(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final complaints = snapshot.data!;
                      _visibleComplaints = complaints;
                      _syncSelectionWithVisibleItems(complaints);
                      if (complaints.isEmpty) {
                        return const _EmptyState();
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                24,
                                16,
                                32,
                              ),
                              itemCount: complaints.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final complaint = complaints[index];
                                return _ComplaintCard(
                                  key: ValueKey(complaint.id),
                                  complaint: complaint,
                                  selectionMode: _selectionMode,
                                  selected: _selectedComplaintIds.contains(
                                    complaint.id,
                                  ),
                                  onTap: () {
                                    if (_selectionMode &&
                                        _canManageComplaints) {
                                      _toggleSelection(complaint);
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ComplaintDetailScreen(
                                          complaint: complaint,
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: _canManageComplaints
                                      ? () => _toggleSelection(complaint)
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
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

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ComplaintCard({
    super.key,
    required this.complaint,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(complaint.status);
    final statusGradient = _statusGradient(complaint.status);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: selectionMode && selected
              ? Border.all(color: UIColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectionMode) ...[
              Checkbox(value: selected, onChanged: (_) => onTap()),
              const SizedBox(width: 4),
            ],
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                gradient: statusGradient,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusChip(status: complaint.status),
                ],
              ),
            ),
            if (!selectionMode)
              const Icon(
                Icons.chevron_right_rounded,
                color: UIColors.textMuted,
              ),
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
            decoration: const BoxDecoration(
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
          Text(
            'No complaints found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

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
