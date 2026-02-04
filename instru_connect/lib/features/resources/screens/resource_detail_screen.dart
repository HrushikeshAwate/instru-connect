import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    // ================= SAFETY CHECK =================
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
      body: Stack(
        children: [
          // ================= HEADER GRADIENT =================
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF4F46E5),
                  Color(0xFF06B6D4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          // ================= CONTENT =================
          SafeArea(
            child: Column(
              children: [
                // ---------- APP BAR ----------
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Resource',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- MAIN CARD ----------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ================= TITLE =================
                            Text(
                              resource.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 6),

                            // ================= SUBJECT =================
                            Text(
                              resource.subject,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),

                            const SizedBox(height: 24),

                            // ================= DESCRIPTION =================
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

                            // ================= ACTION =================
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open / Download'),
                                onPressed: () async {
                                  // ---------- PDF ----------
                                  if (resource.fileType
                                      .toLowerCase()
                                      .contains('pdf')) {
                                    try {
                                      final dir =
                                          await getTemporaryDirectory();
                                      final filePath =
                                          '${dir.path}/${resource.fileName}';

                                      final file = File(filePath);

                                      if (!await file.exists()) {
                                        final response = await http.get(
                                          Uri.parse(resource.fileUrl),
                                        );
                                        await file.writeAsBytes(
                                            response.bodyBytes);
                                      }

                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => _PdfViewerScreen(
                                              filePath: filePath,
                                              title: resource.title,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to open PDF: $e'),
                                        ),
                                      );
                                    }
                                  }
                                  // ---------- NON-PDF ----------
                                  else {
                                    final uri =
                                        Uri.parse(resource.fileUrl);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode
                                            .externalApplication,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// =======================================================
// PDF VIEWER SCREEN (IN-APP)
// =======================================================

class _PdfViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const _PdfViewerScreen({
    required this.filePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF error: $error')),
          );
        },
      ),
    );
  }
}
