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
      appBar: AppBar(title: const Text('Notice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              notice.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            // Date
            Text(
              formatDate(notice.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const Divider(height: 32),

            // Body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.body,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    // 🔽 ATTACHMENTS
                    if (notice.attachments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Attachments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      ...notice.attachments.map((url) {
                        final isPdf =
                            url.toLowerCase().endsWith('.pdf');

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isPdf
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                          title: Text(
                            isPdf ? 'View PDF' : 'View Attachment',
                          ),
                          onTap: () async {
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode:
                                    LaunchMode.externalApplication,
                              );
                            }
                          },
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
