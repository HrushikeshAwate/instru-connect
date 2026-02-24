// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:instru_connect/features/profile/services/certification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/ui_colors.dart';

class CertificationsScreen extends StatelessWidget {
  const CertificationsScreen({super.key});

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = CertificationService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      floatingActionButton: FloatingActionButton(
        backgroundColor: UIColors.primary,
        onPressed: () => _showAddDialog(context, service, uid),
        child: const Icon(Icons.add),
      ),

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
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Certifications',
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
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: service.fetchCertificates(uid),
                    builder: (context, snapshot) {
                      // ---------- LOADING ----------
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // ---------- ERROR ----------
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Failed to load certifications'),
                        );
                      }

                      final certs = snapshot.data ?? [];

                      // ---------- EMPTY ----------
                      if (certs.isEmpty) {
                        return const _EmptyState();
                      }

                      // ---------- LIST ----------
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: certs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) {
                          final c = certs[i];
                          final fileType = c['fileType'];

                          return _CertificateCard(
                            title: c['title'] ?? 'Untitled',
                            issuer: c['issuer'] ?? '',
                            fileType: fileType,
                            onTap: () => _openInBrowser(c['fileUrl'] ?? ''),
                          );
                        },
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

  // =====================================================
  // ADD CERTIFICATE DIALOG (UI POLISHED, LOGIC SAME)
  // =====================================================

  void _showAddDialog(
    BuildContext context,
    CertificationService service,
    String uid,
  ) {
    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    PlatformFile? selectedFile;
    bool uploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Add Certificate'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: issuerCtrl,
                    decoration: const InputDecoration(labelText: 'Issuer'),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      selectedFile == null
                          ? 'Pick PDF or Image'
                          : selectedFile!.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: uploading
                        ? null
                        : () async {
                            final file = await service.pickCertificateFile();
                            if (file != null) {
                              setState(() => selectedFile = file);
                            }
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: uploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: uploading || selectedFile == null
                      ? null
                      : () async {
                          setState(() => uploading = true);

                          try {
                            await service.uploadCertificate(
                              uid: uid,
                              title: titleCtrl.text.trim(),
                              issuer: issuerCtrl.text.trim(),
                              file: selectedFile!,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Certificate uploaded'),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => uploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                  child: uploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// =======================================================
// CERTIFICATE CARD (MATCHES NOTICE / RESOURCE)
// =======================================================

class _CertificateCard extends StatelessWidget {
  final String title;
  final String issuer;
  final String fileType;
  final VoidCallback? onTap;

  const _CertificateCard({
    required this.title,
    required this.issuer,
    required this.fileType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: UIColors.primary.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // LEFT STRIP
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  gradient: UIColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 14),

              Icon(
                fileType == 'pdf'
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                color: UIColors.primary,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      issuer,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.open_in_new,
                size: 16,
                color: UIColors.textMuted,
              ),
            ],
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
              Icons.workspace_premium_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No certificates yet',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first certificate',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
