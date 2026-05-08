// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/activity_notification_service.dart';
import 'package:instru_connect/core/utils/batch_ordering.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:instru_connect/features/batches/screens/assign_batch.dart';
import 'package:instru_connect/features/batches/services/batch_service.dart';

import '../../../config/theme/ui_colors.dart';
import 'batch_subject_screen.dart';

class ManageBatchesScreen extends StatefulWidget {
  const ManageBatchesScreen({super.key});

  @override
  State<ManageBatchesScreen> createState() => _ManageBatchesScreenState();
}

class _ManageBatchesScreenState extends State<ManageBatchesScreen> {
  final BatchService _batchService = BatchService();
  final ActivityNotificationService _activityNotifications =
      ActivityNotificationService();
  final Set<String> _selectedBatchIds = <String>{};
  late final Stream<QuerySnapshot> _batchesStream;
  bool _selectionMode = false;
  bool _deleting = false;

  bool get _canManageBatches => _batchService.canManageBatches;
  bool get _canDeleteBatches => _batchService.canDeleteBatches;

  @override
  void initState() {
    super.initState();
    _batchesStream = FirebaseFirestore.instance
        .collection('batches')
        .orderBy('currentYear')
        .snapshots();
  }

  Future<void> _showCreateBatchDialog(BuildContext context) async {
    if (!_canManageBatches) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin or faculty can create batches.')),
      );
      return;
    }

    final nameController = TextEditingController();
    int currentYear = 1;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Batch Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: currentYear,
              items: const [
                DropdownMenuItem(value: 1, child: Text('FY')),
                DropdownMenuItem(value: 2, child: Text('SY')),
                DropdownMenuItem(value: 3, child: Text('TY')),
                DropdownMenuItem(value: 4, child: Text('Fourth Year')),
                DropdownMenuItem(value: 0, child: Text('Alumni')),
              ],
              onChanged: (value) => currentYear = value ?? 1,
              decoration: const InputDecoration(labelText: 'Current Year'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              await FirebaseFirestore.instance.collection('batches').add({
                'name': nameController.text.trim(),
                'department': 'Instrumentation',
                'currentYear': currentYear,
                'isActive': true,
                'crUserIds': [],
                'maxCRs': 2,
              });

              await _activityNotifications.notifyAdminsAndFaculty(
                title: 'Batch Created',
                body: nameController.text.trim(),
                type: 'batch_created',
                data: {
                  'batchName': nameController.text.trim(),
                  'currentYear': currentYear,
                },
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Batch created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPromoteAllDialog(BuildContext context) async {
    if (!_canManageBatches) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin or faculty can manage batches.')),
      );
      return;
    }

    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Promote All Students?',
      message:
          'This will move FY to SY, SY to TY, TY to Fourth Year, and Fourth Year to Alumni. The promotion affects student progression records and cannot be undone or recovered.',
      confirmLabel: 'Promote All',
    );

    if (!confirmed) return;

    await BatchService().promoteAllStudents();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All students promoted successfully'),
      ),
    );
  }

  void _toggleSelection(String batchId) {
    if (!_canDeleteBatches) return;
    setState(() {
      _selectionMode = true;
      if (_selectedBatchIds.contains(batchId)) {
        _selectedBatchIds.remove(batchId);
      } else {
        _selectedBatchIds.add(batchId);
      }
      if (_selectedBatchIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedBatchIds.clear();
    });
  }

  void _syncSelectionWithVisibleItems(List<QueryDocumentSnapshot> batches) {
    final visibleIds = batches.map((batch) => batch.id).toSet();
    final staleIds = _selectedBatchIds.difference(visibleIds);
    if (staleIds.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedBatchIds.removeWhere((id) => !visibleIds.contains(id));
        if (_selectedBatchIds.isEmpty) {
          _selectionMode = false;
        }
      });
    });
  }

  Future<void> _deleteSelected(List<QueryDocumentSnapshot> batches) async {
    final selected = batches
        .where((doc) => _selectedBatchIds.contains(doc.id))
        .toList();
    if (selected.isEmpty) return;

    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Delete Batches?',
      message:
          'You are about to permanently delete ${selected.length} selected batch(es). This will also remove related subjects and attendance data, and it cannot be undone or recovered.',
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _batchService.deleteBatchesCascade(
        batchIds: selected.map((doc) => doc.id).toList(),
      );
      if (!mounted) return;
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.length} batch(es) deleted')),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: _canManageBatches
          ? FloatingActionButton.extended(
              backgroundColor: UIColors.primary,
              onPressed: () => _showCreateBatchDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Batch'),
            )
          : null,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _batchesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: [
                      _HeaderBar(
                        title: _selectionMode
                            ? '${_selectedBatchIds.length} selected'
                            : 'Manage Batches',
                        selectionMode: _selectionMode,
                        deleting: _deleting,
                        onBack: _selectionMode
                            ? _clearSelection
                            : () => Navigator.pop(context),
                        onPromoteAll: !_selectionMode && _canManageBatches
                            ? () => _showPromoteAllDialog(context)
                            : null,
                      ),
                      const Expanded(child: _EmptyState()),
                    ],
                  );
                }

                final batches = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aName = (aData['name'] ?? '').toString();
                    final bName = (bData['name'] ?? '').toString();
                    final rankCompare = BatchOrdering.rankForName(
                      aName,
                    ).compareTo(BatchOrdering.rankForName(bName));
                    if (rankCompare != 0) return rankCompare;
                    return aName.toLowerCase().compareTo(bName.toLowerCase());
                  });
                _syncSelectionWithVisibleItems(batches);

                final activeCount = batches.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isActive'] == true;
                }).length;

                return Column(
                  children: [
                    _HeaderBar(
                      title: _selectionMode
                          ? '${_selectedBatchIds.length} selected'
                          : 'Manage Batches',
                      selectionMode: _selectionMode,
                      deleting: _deleting,
                      onBack: _selectionMode
                          ? _clearSelection
                          : () => Navigator.pop(context),
                      onDeleteSelected: _selectionMode
                          ? () => _deleteSelected(batches)
                          : null,
                      onPromoteAll: !_selectionMode && _canManageBatches
                          ? () => _showPromoteAllDialog(context)
                          : null,
                    ),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                              child: _OverviewCard(
                                totalCount: batches.length,
                                activeCount: activeCount,
                                onAssign: _canManageBatches
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AssignBatchToStudentsScreen(),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Text(
                                'Batches',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index.isOdd) {
                                    return const SizedBox(height: 14);
                                  }

                                  final batchIndex = index ~/ 2;
                                  final doc = batches[batchIndex];
                                  final data =
                                      doc.data() as Map<String, dynamic>;

                                  return _BatchCard(
                                    key: ValueKey(doc.id),
                                    batchId: doc.id,
                                    name: (data['name'] ?? '').toString(),
                                    currentYear:
                                        (data['currentYear'] as num?)
                                            ?.toInt() ??
                                        0,
                                    isActive: data['isActive'] == true,
                                    selectionMode: _selectionMode,
                                    selected: _selectedBatchIds.contains(doc.id),
                                    onTap: () {
                                      if (_selectionMode) {
                                        _toggleSelection(doc.id);
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BatchSubjectsScreen(
                                            batchId: doc.id,
                                          ),
                                        ),
                                      );
                                    },
                                    onLongPress: () => _toggleSelection(doc.id),
                                  );
                                },
                                childCount: batches.isEmpty
                                    ? 0
                                    : (batches.length * 2) - 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String title;
  final bool selectionMode;
  final bool deleting;
  final VoidCallback onBack;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onPromoteAll;

  const _HeaderBar({
    required this.title,
    required this.selectionMode,
    required this.deleting,
    required this.onBack,
    this.onDeleteSelected,
    this.onPromoteAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: IconButton(
              icon: Icon(
                selectionMode
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: onBack,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!selectionMode) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Organize academic years, subjects, and attendance by batch.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!selectionMode && onPromoteAll != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: _HeaderActionButton(
                tooltip: 'Promote all students',
                icon: Icons.trending_up_rounded,
                onTap: onPromoteAll!,
              ),
            ),
          if (selectionMode && onDeleteSelected != null)
            IconButton(
              icon: deleting
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
              tooltip: 'Delete selected batches',
              onPressed: deleting ? null : onDeleteSelected,
            ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final VoidCallback? onAssign;

  const _OverviewCard({
    required this.totalCount,
    required this.activeCount,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.32)
              : theme.colorScheme.outline.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.14)
                : UIColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick actions and batch counts at a glance.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: UIColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: 'Total Batches',
                  value: totalCount.toString(),
                  icon: Icons.layers_outlined,
                  color: UIColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewStat(
                  label: 'Active',
                  value: activeCount.toString(),
                  icon: Icons.check_circle_outline,
                  color: UIColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Student Assignment',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _OverviewActionTile(
                icon: Icons.assignment_ind_outlined,
                title: 'Assign Students',
                subtitle:
                    'Open the assignment workspace to map students to the correct batches without clutter.',
                onTap: onAssign,
                outlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _OverviewActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool outlined;

  const _OverviewActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = UIColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: outlined ? null : UIColors.primaryGradient,
            color: outlined ? primary.withValues(alpha: 0.06) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: outlined
                  ? primary.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: outlined
                      ? primary.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: outlined ? primary : Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: outlined ? null : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: outlined
                            ? UIColors.textMuted
                            : Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: outlined ? primary : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.16),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: UIColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final Key? key;
  final String batchId;
  final String name;
  final int currentYear;
  final bool isActive;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BatchCard({
    this.key,
    required this.batchId,
    required this.name,
    required this.currentYear,
    required this.isActive,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yearLabel = _yearLabel(currentYear);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selectionMode && selected
              ? UIColors.primary
              : (isActive
                    ? UIColors.primary.withValues(alpha: 0.16)
                    : theme.colorScheme.outlineVariant),
          width: selectionMode && selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              if (selectionMode) ...[
                Checkbox(value: selected, onChanged: (_) => onTap()),
                const SizedBox(width: 4),
              ],
              Container(
                width: 10,
                height: 72,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? UIColors.primaryGradient
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade400,
                            Colors.grey.shade500,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusChip(isActive: isActive),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _YearChip(year: currentYear),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$yearLabel batch • Tap to manage subjects and attendance',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: UIColors.textMuted,
                              height: 1.35,
                            ),
                          ),
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
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? UIColors.success : UIColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  final int year;

  const _YearChip({required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: UIColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _yearLabel(year),
        style: const TextStyle(
          fontSize: 12,
          color: UIColors.primary,
          fontWeight: FontWeight.w700,
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
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: UIColors.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No batches created yet',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your first batch to start organizing students and subjects.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _yearLabel(int year) {
  switch (year) {
    case 1:
      return 'FY';
    case 2:
      return 'SY';
    case 3:
      return 'TY';
    case 4:
      return 'Fourth Year';
    default:
      return 'Alumni';
  }
}
