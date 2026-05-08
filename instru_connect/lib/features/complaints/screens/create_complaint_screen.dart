import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme/ui_colors.dart';
import '../../../core/sessioin/current_user.dart';
import '../services/complaint_service.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _service = ComplaintService();

  final _title = TextEditingController();
  final _description = TextEditingController();

  String _category = 'Technical';
  File? _mediaFile;
  String? _mediaType;
  bool _loading = false;
  bool _isAnonymous = false;

  Future<void> _pickMedia(bool video) async {
    final picker = ImagePicker();
    final picked = video
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _mediaType = video ? 'video' : 'image';
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;
      final role = (CurrentUser.role ?? 'unknown').trim().toLowerCase();

      final docRef = await _service.createComplaint(
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category,
        createdBy: uid,
        createdByRole: role,
        departmentId: '',
        isAnonymous: role == 'student' ? _isAnonymous : false,
      );

      if (_mediaFile != null) {
        final media = await _service.uploadMedia(
          complaintId: docRef.id,
          file: _mediaFile!,
          mediaType: _mediaType!,
        );

        await _service.attachMedia(
          complaintId: docRef.id,
          mediaUrl: media['mediaUrl']!,
          mediaType: media['mediaType']!,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : UIColors.primary.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ================= HEADER GRADIENT =================
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // ================= CUSTOM APP BAR =================
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Raise Complaint',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ================= FORM CARD =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Complaint Details'),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        dropdownColor: surfaceColor,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items:
                            const [
                                  'Technical',
                                  'Teaching Faculty',
                                  'Non-Teaching Faculty',
                                  'Others',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _description,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),

                      if ((CurrentUser.role ?? '').trim().toLowerCase() ==
                          'student') ...[
                        const SizedBox(height: 18),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _isAnonymous,
                          onChanged: (value) {
                            setState(() => _isAnonymous = value);
                          },
                          title: const Text('Submit anonymously'),
                          subtitle: const Text(
                            'Your complaint will still be linked to your account, but your identity will be hidden in the complaint view.',
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ================= ATTACHMENT =================
                      const _SectionTitle('Attachment (Optional)'),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _AttachButton(
                            icon: Icons.image_outlined,
                            label: 'Add Image',
                            onTap: () => _pickMedia(false),
                          ),
                          const SizedBox(width: 12),
                          _AttachButton(
                            icon: Icons.videocam_outlined,
                            label: 'Add Video',
                            onTap: () => _pickMedia(true),
                          ),
                        ],
                      ),

                      if (_mediaFile != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: UIColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_mediaType!.toUpperCase()} attached',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ================= SUBMIT BUTTON =================
                Container(
                  decoration: BoxDecoration(
                    gradient: UIColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: UIColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Complaint',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
// REUSABLE COMPONENTS
// =======================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _AttachButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF243244)
        : const Color(0xFFE2E8F0);
    final backgroundColor = isDark
        ? const Color(0xFF182235)
        : const Color(0xFFF8FAFC);

    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
