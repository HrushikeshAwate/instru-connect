import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import '../../../core/utils/date_utils.dart';

class NoticeTile extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;

  const NoticeTile({
    super.key,
    required this.notice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        notice.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(formatDate(notice.createdAt)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
