import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/notice_model.dart';
import '../../../core/utils/date_utils.dart';

class NoticeDetailScreen extends StatelessWidget {
  final Notice notice;

  const NoticeDetailScreen({
    super.key,
    required this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // TITLE
            // =================================================
            Text(
              notice.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            // =================================================
            // DATE
            // =================================================
            Text(
              formatDate(notice.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const Divider(height: 32),

            // =================================================
            // BODY + ATTACHMENTS
            // =================================================
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BODY
                    Text(
                      notice.body,
                      style:
                          Theme.of(context).textTheme.bodyMedium,
                    ),

                    // =================================================
                    // ATTACHMENTS
                    // =================================================
                    if (notice.attachments.isNotEmpty) ...[
                      const SizedBox(height: 32),

                      Text(
                        'Attachments',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),

                      const SizedBox(height: 8),

                      ...notice.attachments.map((url) {
                        final isPdf = url
                            .toLowerCase()
                            .endsWith('.pdf');

                        return _AttachmentTile(
                          url: url,
                          isPdf: isPdf,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final String url;
  final bool isPdf;

  const _AttachmentTile({
    required this.url,
    required this.isPdf,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      },
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
        ),
        child: Row(
          children: [
            Icon(
              isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              color:
                  Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isPdf ? 'View PDF' : 'View Attachment',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
            ),
            const Icon(Icons.open_in_new),
          ],
        ),
      ),
    );
  }
}
