import 'package:flutter/material.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    // 🛑 SAFETY CHECK (UNCHANGED)
    if (args == null || args is! ResourceModel) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resource')),
        body: const Center(
          child: Text('Resource data not available'),
        ),
      );
    }

    final ResourceModel resource = args;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // TITLE
            // =================================================
            Text(
              resource.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            // =================================================
            // SUBJECT
            // =================================================
            Text(
              resource.subject,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const Divider(height: 32),

            // =================================================
            // DESCRIPTION
            // =================================================
            if (resource.description.isNotEmpty) ...[
              const _SectionTitle('Description'),
              const SizedBox(height: 8),
              Text(
                resource.description,
                style:
                    Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            const Spacer(),

            // =================================================
            // ACTION
            // =================================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open / Download'),
                onPressed: () async {
                  final uri = Uri.parse(resource.fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// SECTION TITLE
// =======================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style:
          Theme.of(context).textTheme.titleMedium,
    );
  }
}
