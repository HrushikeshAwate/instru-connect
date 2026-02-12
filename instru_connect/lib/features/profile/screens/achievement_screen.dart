// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:instru_connect/features/profile/services/achievement_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/ui_colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  Future<void> _openInBrowser(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = AchievementService();

    return Scaffold(
      backgroundColor: UIColors.background,
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
                        'Achievements',
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
                    stream: service.fetchAchievements(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Failed to load achievements'),
                        );
                      }

                      final achievements = snapshot.data ?? [];

                      if (achievements.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: achievements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) {
                          final a = achievements[i];
                          final fileType = a['certificateType'] ?? '';

                          return _AchievementCard(
                            title: a['title'] ?? 'Untitled',
                            event: a['event'] ?? '',
                            rank: a['rank'] ?? '',
                            score: a['score'] ?? '',
                            fileType: fileType,
                            onTap: () => _openInBrowser(a['certificateUrl'] ?? ''),
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
  // ADD ACHIEVEMENT DIALOG
  // =====================================================

  void _showAddDialog(
    BuildContext context,
    AchievementService service,
    String uid,
  ) {
    final titleCtrl = TextEditingController();
    final eventCtrl = TextEditingController();
    final rankCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
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
              title: const Text('Add Achievement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'What did you achieve?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: eventCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Event / Competition',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rankCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Rank (if applicable)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: scoreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Score (if applicable)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        selectedFile == null
                            ? 'Pick Certificate (PDF/Image)'
                            : selectedFile!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: uploading
                          ? null
                          : () async {
                              final file =
                                  await service.pickAchievementFile();
                              if (file != null) {
                                setState(() => selectedFile = file);
                              }
                            },
                    ),
                  ],
                ),
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
                            await service.uploadAchievement(
                              uid: uid,
                              title: titleCtrl.text.trim(),
                              event: eventCtrl.text.trim(),
                              rank: rankCtrl.text.trim(),
                              score: scoreCtrl.text.trim(),
                              description: descriptionCtrl.text.trim(),
                              file: selectedFile!,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Achievement uploaded'),
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
// ACHIEVEMENT CARD
// =======================================================

class _AchievementCard extends StatelessWidget {
  final String title;
  final String event;
  final String rank;
  final String score;
  final String fileType;
  final VoidCallback? onTap;

  const _AchievementCard({
    required this.title,
    required this.event,
    required this.rank,
    required this.score,
    required this.fileType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [rank, score].where((v) => v.trim().isNotEmpty).join(' • ');

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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    if (event.isNotEmpty)
                      Text(
                        event,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: UIColors.textSecondary),
                      ),
                    if (meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          meta,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: UIColors.textMuted),
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
              Icons.emoji_events_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No achievements yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first achievement',
            style: TextStyle(color: UIColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
