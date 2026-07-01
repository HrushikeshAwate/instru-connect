import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/session/current_user.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';

import '../../../config/theme/ui_colors.dart';
import '../models/complaint_model.dart';
import 'complaint_detail_screen.dart';
import 'create_complaint_screen.dart';

class ComplaintListScreen extends ConsumerStatefulWidget {
  final Stream<List<ComplaintModel>>? stream;

  const ComplaintListScreen({super.key, this.stream});

  @override
  ConsumerState<ComplaintListScreen> createState() =>
      _ComplaintListScreenState();
}

class _ComplaintListScreenState extends ConsumerState<ComplaintListScreen> {
  late final ComplaintService _complaintService;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedComplaintIds = <String>{};
  List<ComplaintModel> _visibleComplaints = const <ComplaintModel>[];
  bool _selectionMode = false;
  bool _deleting = false;
  String _query = '';
  String _statusFilter = 'all';

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

  @override
  void initState() {
    super.initState();
    _complaintService = ref.read(complaintServiceProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ComplaintModel> _applyFilters(List<ComplaintModel> complaints) {
    final query = _query.trim().toLowerCase();
    return complaints.where((complaint) {
      final matchesQuery =
          query.isEmpty ||
          complaint.title.toLowerCase().contains(query) ||
          complaint.description.toLowerCase().contains(query) ||
          complaint.category.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'all' || complaint.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  Map<String, int> _statusCounts(List<ComplaintModel> complaints) {
    final counts = <String, int>{
      'all': complaints.length,
      'submitted': 0,
      'acknowledged': 0,
      'in_progress': 0,
      'resolved': 0,
    };
    for (final complaint in complaints) {
      counts[complaint.status] = (counts[complaint.status] ?? 0) + 1;
    }
    return counts;
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
          const AppHeroBackground(height: 172),
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
                      final filteredComplaints = _applyFilters(complaints);
                      _visibleComplaints = filteredComplaints;
                      _syncSelectionWithVisibleItems(filteredComplaints);
                      if (complaints.isEmpty) {
                        return _EmptyState(canCreate: _canCreateComplaints);
                      }

                      return Column(
                        children: [
                          _ComplaintTools(
                            controller: _searchController,
                            counts: _statusCounts(complaints),
                            visibleCount: filteredComplaints.length,
                            statusFilter: _statusFilter,
                            onQueryChanged: (value) =>
                                setState(() => _query = value),
                            onStatusChanged: (status) =>
                                setState(() => _statusFilter = status),
                          ),
                          Expanded(
                            child: filteredComplaints.isEmpty
                                ? _EmptyFilteredComplaints(
                                    onClear: () {
                                      _searchController.clear();
                                      setState(() {
                                        _query = '';
                                        _statusFilter = 'all';
                                      });
                                    },
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      32,
                                    ),
                                    itemCount: filteredComplaints.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final complaint =
                                          filteredComplaints[index];
                                      return _ComplaintCard(
                                        key: ValueKey(complaint.id),
                                        complaint: complaint,
                                        selectionMode: _selectionMode,
                                        selected: _selectedComplaintIds
                                            .contains(complaint.id),
                                        onTap: () {
                                          if (_selectionMode &&
                                              _canManageComplaints) {
                                            _toggleSelection(complaint);
                                            return;
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ComplaintDetailScreen(
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

class _ComplaintTools extends StatelessWidget {
  final TextEditingController controller;
  final Map<String, int> counts;
  final int visibleCount;
  final String statusFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;

  const _ComplaintTools({
    required this.controller,
    required this.counts,
    required this.visibleCount,
    required this.statusFilter,
    required this.onQueryChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = counts['all'] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search complaints',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$visibleCount of $total complaints',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusFilterChip(
                  label: 'All',
                  count: counts['all'] ?? 0,
                  selected: statusFilter == 'all',
                  onTap: () => onStatusChanged('all'),
                ),
                _StatusFilterChip(
                  label: 'Submitted',
                  count: counts['submitted'] ?? 0,
                  selected: statusFilter == 'submitted',
                  onTap: () => onStatusChanged('submitted'),
                ),
                _StatusFilterChip(
                  label: 'Acknowledged',
                  count: counts['acknowledged'] ?? 0,
                  selected: statusFilter == 'acknowledged',
                  onTap: () => onStatusChanged('acknowledged'),
                ),
                _StatusFilterChip(
                  label: 'In Progress',
                  count: counts['in_progress'] ?? 0,
                  selected: statusFilter == 'in_progress',
                  onTap: () => onStatusChanged('in_progress'),
                ),
                _StatusFilterChip(
                  label: 'Resolved',
                  count: counts['resolved'] ?? 0,
                  selected: statusFilter == 'resolved',
                  onTap: () => onStatusChanged('resolved'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label $count'),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: selectionMode && selected
              ? Border.all(color: UIColors.primary, width: 2)
              : Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
                ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: statusGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _statusIcon(complaint.status),
                color: Colors.white,
                size: 20,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _StatusChip(status: complaint.status),
                      _MiniMeta(
                        icon: Icons.category_outlined,
                        label: complaint.category,
                      ),
                    ],
                  ),
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
  final bool canCreate;

  const _EmptyState({required this.canCreate});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.report_problem_outlined,
      title: 'No complaints found',
      message: canCreate
          ? 'Submitted complaints and their progress will appear here.'
          : 'Complaints assigned to your role will appear here.',
    );
  }
}

class _EmptyFilteredComplaints extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyFilteredComplaints({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.manage_search_rounded,
      title: 'No matching complaints',
      message: 'Try another search term or status filter.',
      actionLabel: 'Clear',
      onAction: onClear,
    );
  }
}

class _MiniMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: UIColors.textMuted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: UIColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: UIColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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

IconData _statusIcon(String status) {
  switch (status) {
    case 'submitted':
      return Icons.outbox_rounded;
    case 'acknowledged':
      return Icons.verified_outlined;
    case 'in_progress':
      return Icons.timelapse_rounded;
    case 'resolved':
      return Icons.check_circle_outline_rounded;
    default:
      return Icons.report_problem_outlined;
  }
}
