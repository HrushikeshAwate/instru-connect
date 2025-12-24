import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notice_model.dart';
import '../services/notice_service.dart';
import '../widgets/notice_tile.dart';
import 'notice_detail_screen.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() =>
      _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final NoticeService _service = NoticeService();
  final ScrollController _scrollController =
      ScrollController();

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
      final snapshot =
          await _service.fetchNoticesSnapshot(
        departmentId: departmentId,
        lastDocument: _lastDoc,
        limit: _pageLimit,
      );

      final docs = snapshot.docs;
      final notices =
          docs.map((e) => Notice.fromFirestore(e)).toList();

      if (!mounted) return;

      setState(() {
        _notices.addAll(notices);

        if (docs.isNotEmpty) {
          _lastDoc = docs.last;
        }

        if (docs.length < _pageLimit) {
          _hasMore = false;
        }
      });
    } catch (_) {
      // Optional: error UI later
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      appBar: AppBar(title: const Text('Notices')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // =================================================
    // INITIAL LOADING
    // =================================================
    if (_isLoading && _notices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // =================================================
    // EMPTY STATE
    // =================================================
    if (_notices.isEmpty) {
      return const _EmptyState();
    }

    // =================================================
    // LIST
    // =================================================
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _notices.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // ---------------------------------------------
        // BOTTOM LOADER
        // ---------------------------------------------
        if (index == _notices.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        }

        final notice = _notices[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NoticeTile(
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
          ),
        );
      },
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
          Icon(
            Icons.campaign_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text('No notices available'),
        ],
      ),
    );
  }
}
