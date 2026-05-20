import 'package:flutter/material.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/notices/models/notice_model.dart';
import 'package:instru_connect/features/notices/screens/notice_detail_screen.dart';
import 'package:instru_connect/features/notices/services/notice_service.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final NoticeService _service = NoticeService();
  late final Stream<List<Notice>> _noticesStream;
  List<Notice> _visibleNotices = const <Notice>[];

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
    _noticesStream = _service.streamNotices();
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
                      _visibleNotices = notices;
                      if (notices.isEmpty) {
                        return const _EmptyState();
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                24,
                              ),
                              itemCount: notices.length,
                              itemBuilder: (context, index) {
                                final notice = notices[index];

                                return _NoticeCard(
                                  key: ValueKey(notice.id),
                                  notice: notice,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            NoticeDetailScreen(notice: notice),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                      width: 6,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: UIColors.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
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
                            ).textTheme.titleMedium?.copyWith(height: 1.3),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to view details',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
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
              Icons.campaign_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notices available',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _TargetBatchSummary extends StatelessWidget {
  final List<String> batchIds;

  const _TargetBatchSummary({required this.batchIds});

  @override
  Widget build(BuildContext context) {
    if (batchIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<String>>(
      future: NoticeService().fetchOrderedBatchNames(batchIds),
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
