import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/session/current_user.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/notices/models/notice_model.dart';
import 'package:instru_connect/features/notices/screens/notice_detail_screen.dart';
import 'package:instru_connect/features/notices/services/notice_service.dart';

class NoticeListScreen extends ConsumerStatefulWidget {
  const NoticeListScreen({super.key});

  @override
  ConsumerState<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends ConsumerState<NoticeListScreen> {
  late final NoticeService _service;
  late final Stream<List<Notice>> _noticesStream;
  final TextEditingController _searchController = TextEditingController();
  List<Notice> _visibleNotices = const <Notice>[];
  String _query = '';
  _NoticeFilter _filter = _NoticeFilter.all;

  bool get _canClearNotices {
    final role = (CurrentUser.role ?? '').toLowerCase();
    return role == AppRoles.admin || role == AppRoles.faculty;
  }

  Future<void> _clearVisibleNotices() async {
    if (_visibleNotices.isEmpty) return;

    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Clear Notices?',
      message:
          'This will permanently delete all notices currently shown in this list.',
      confirmLabel: 'Clear Notices',
    );
    if (confirmed != true) return;

    try {
      await _service.deleteNotices(
        _visibleNotices.map((notice) => notice.id).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Visible notices cleared')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  void initState() {
    super.initState();
    _service = ref.read(noticeServiceProvider);
    _noticesStream = _service.streamNotices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Notice> _applyFilters(List<Notice> notices) {
    final query = _query.trim().toLowerCase();
    return notices.where((notice) {
      final matchesQuery =
          query.isEmpty ||
          notice.title.toLowerCase().contains(query) ||
          notice.body.toLowerCase().contains(query) ||
          notice.createdByRole.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        _NoticeFilter.all => true,
        _NoticeFilter.withAttachments => notice.attachments.isNotEmpty,
        _NoticeFilter.targeted => notice.batchIds.isNotEmpty,
      };
      return matchesQuery && matchesFilter;
    }).toList();
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
                      const Expanded(
                        child: Text(
                          'Notices',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_canClearNotices)
                        IconButton(
                          tooltip: 'Clear notices',
                          onPressed: _clearVisibleNotices,
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Notice>>(
                    stream: _noticesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Unable to load notices: ${snapshot.error}',
                          ),
                        );
                      }

                      final notices = snapshot.data ?? const <Notice>[];
                      final filteredNotices = _applyFilters(notices);
                      _visibleNotices = filteredNotices;
                      if (notices.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.campaign_outlined,
                          title: 'No notices yet',
                          message:
                              'Notices from faculty and admins will appear here.',
                        );
                      }

                      return Column(
                        children: [
                          _NoticeTools(
                            controller: _searchController,
                            totalCount: notices.length,
                            visibleCount: filteredNotices.length,
                            filter: _filter,
                            onQueryChanged: (value) =>
                                setState(() => _query = value),
                            onFilterChanged: (filter) =>
                                setState(() => _filter = filter),
                          ),
                          Expanded(
                            child: filteredNotices.isEmpty
                                ? AppEmptyState(
                                    icon: Icons.search_off_rounded,
                                    title: 'No matching notices',
                                    message:
                                        'Try a different search or filter.',
                                    actionLabel: 'Clear filters',
                                    onAction: () {
                                      _searchController.clear();
                                      setState(() {
                                        _query = '';
                                        _filter = _NoticeFilter.all;
                                      });
                                    },
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      24,
                                    ),
                                    itemCount: filteredNotices.length,
                                    itemBuilder: (context, index) {
                                      final notice = filteredNotices[index];

                                      return _NoticeCard(
                                        key: ValueKey(notice.id),
                                        notice: notice,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  NoticeDetailScreen(
                                                    notice: notice,
                                                  ),
                                            ),
                                          );
                                        },
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

enum _NoticeFilter { all, withAttachments, targeted }

class _NoticeTools extends StatelessWidget {
  final TextEditingController controller;
  final int totalCount;
  final int visibleCount;
  final _NoticeFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_NoticeFilter> onFilterChanged;

  const _NoticeTools({
    required this.controller,
    required this.totalCount,
    required this.visibleCount,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              hintText: 'Search notices',
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '$visibleCount of $totalCount notices',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _FilterChip(
                label: 'All',
                selected: filter == _NoticeFilter.all,
                onSelected: () => onFilterChanged(_NoticeFilter.all),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Files',
                selected: filter == _NoticeFilter.withAttachments,
                onSelected: () =>
                    onFilterChanged(_NoticeFilter.withAttachments),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Batch',
                selected: filter == _NoticeFilter.targeted,
                onSelected: () => onFilterChanged(_NoticeFilter.targeted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;

  const _NoticeCard({required this.notice, required this.onTap, super.key});

  String? get _firstImageAttachment {
    for (final url in notice.attachments) {
      final lower = url.toLowerCase();
      final isImage =
          lower.contains('.png') ||
          lower.contains('.jpg') ||
          lower.contains('.jpeg') ||
          lower.contains('.webp');
      if (isImage) return url;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _firstImageAttachment;

    final date = DateFormat('dd MMM').format(notice.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (previewUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 220),
                      color: Theme.of(context).cardColor,
                      child: Image.network(
                        previewUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 120,
                          child: Center(
                            child: Icon(Icons.broken_image_outlined, size: 26),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: UIColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_outlined,
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
                            notice.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(height: 1.25),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _MetaPill(
                                icon: Icons.today_outlined,
                                label: date,
                              ),
                              if (notice.attachments.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                _MetaPill(
                                  icon: Icons.attach_file_rounded,
                                  label: '${notice.attachments.length}',
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          _TargetBatchSummary(batchIds: notice.batchIds),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: UIColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: UIColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: UIColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: UIColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetBatchSummary extends ConsumerWidget {
  final List<String> batchIds;

  const _TargetBatchSummary({required this.batchIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (batchIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<String>>(
      future: ref.read(noticeServiceProvider).fetchOrderedBatchNames(batchIds),
      builder: (context, snapshot) {
        final names = snapshot.data ?? batchIds;
        return Text(
          'Target Batches: ${names.join(' • ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
