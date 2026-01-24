import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notice_model.dart';
import '../services/notice_service.dart';
import 'notice_detail_screen.dart';
import '../../../config/theme/ui_colors.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final NoticeService _service = NoticeService();
  final ScrollController _scrollController = ScrollController();

  final List<Notice> _notices = [];
  bool _isLoading = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _pageLimit = 10;
  final String departmentId = 'Instrumentation';

  @override
  void initState() {
    super.initState();
    _fetchNotices();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotices() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _service.fetchNoticesSnapshot(
        departmentId: departmentId,
        lastDocument: _lastDoc,
        limit: _pageLimit,
      );

      final docs = snapshot.docs;
      final notices = docs.map((e) => Notice.fromFirestore(e)).toList();

      if (!mounted) return;

      setState(() {
        _notices.addAll(notices);
        if (docs.isNotEmpty) _lastDoc = docs.last;
        if (docs.length < _pageLimit) _hasMore = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchNotices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,
      body: Stack(
        children: [
          // ================= HEADER =================
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
                // ================= APP BAR =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Notices',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= BODY =================
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notices.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _notices.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notices.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final notice = _notices[index];

        return _NoticeCard(
          notice: notice,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoticeDetailScreen(notice: notice),
              ),
            );
          },
        );
      },
    );
  }
}

// =======================================================
// NOTICE CARD
// =======================================================

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;

  const _NoticeCard({
    required this.notice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withOpacity(0.12),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT GRADIENT STRIP
                Container(
                  width: 6,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: UIColors.primaryGradient,
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
                        notice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to view details',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: UIColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: UIColors.textMuted),
              ],
            ),
          ),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
