import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';
import '../services/notice_service.dart';
import '../widgets/notice_tile.dart';
import 'notice_detail_screen.dart';

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

  // TODO: replace with real department source (same as WRITE)
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

        if (docs.isNotEmpty) {
          _lastDoc = docs.last;
        }

        // 🔑 IMPORTANT FIX: stop loader correctly
        if (docs.length < _pageLimit) {
          _hasMore = false;
        }
      });
    } catch (_) {
      // optional: show error UI
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
    if (_isLoading && _notices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notices.isEmpty) {
      return const Center(child: Text('No notices available'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _notices.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notices.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final notice = _notices[index];
        return NoticeTile(
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
