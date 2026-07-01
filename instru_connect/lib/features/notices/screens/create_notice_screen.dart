// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/ui_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_ui.dart';
import '../services/notice_service.dart';

class CreateNoticeScreen extends ConsumerStatefulWidget {
  final List<String>? fixedBatchIds;
  final bool showBatchSelector;

  const CreateNoticeScreen({
    super.key,
    this.fixedBatchIds,
    required this.showBatchSelector,
  });

  @override
  ConsumerState<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends ConsumerState<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();

  late final NoticeService _noticeService;
  late final StorageService _storageService;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final Set<String> _selectedBatchIds = {};

  Uint8List? _fileBytes;
  String? _fileName;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _noticeService = ref.read(noticeServiceProvider);
    _storageService = ref.read(storageServiceProvider);
    if (widget.fixedBatchIds != null) {
      _selectedBatchIds.addAll(widget.fixedBatchIds!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<List<Map<String, String>>> _fetchBatches() async {
    return _noticeService.fetchBatchOptions();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes!;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBatchIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No target batch selected')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      const departmentId = 'Instrumentation';

      final noticeId = await _noticeService.createNotice(
        title: _titleController.text,
        body: _bodyController.text,
        departmentId: departmentId,
        batchIds: _selectedBatchIds.toList(),
      );

      if (_fileBytes != null && _fileName != null) {
        final url = await _storageService.uploadNoticeAttachment(
          bytes: _fileBytes!,
          fileName: _fileName!,
          noticeId: noticeId,
        );

        await _noticeService.addAttachment(
          noticeId: noticeId,
          attachmentUrl: url,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final softFillColor = isDark
        ? const Color(0xFF182235)
        : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? const Color(0xFF243244)
        : const Color(0xFFE2E8F0);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : UIColors.primary.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const AppHeroBackground(height: 198),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // ================= APP BAR =================
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Notice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Notice Details'),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _titleController,
                          maxLength: 100,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _bodyController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Notice Content',
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),

                        // ================= BATCH SELECTOR =================
                        if (widget.showBatchSelector) ...[
                          const SizedBox(height: 28),
                          const _SectionTitle('Target Batches'),
                          const SizedBox(height: 12),

                          FutureBuilder<List<Map<String, String>>>(
                            future: _fetchBatches(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                );
                              }

                              return Column(
                                children: snapshot.data!.map((batch) {
                                  final id = batch['id']!;
                                  final name = batch['name']!;
                                  final selected = _selectedBatchIds.contains(
                                    id,
                                  );

                                  return CheckboxListTile(
                                    tileColor: softFillColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: selected
                                            ? UIColors.primary.withValues(
                                                alpha: isDark ? 0.7 : 0.25,
                                              )
                                            : borderColor,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(name),
                                    value: selected,
                                    activeColor: UIColors.primary,
                                    onChanged: (v) {
                                      setState(() {
                                        v == true
                                            ? _selectedBatchIds.add(id)
                                            : _selectedBatchIds.remove(id);
                                      });
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ================= ATTACHMENT =================
                        OutlinedButton.icon(
                          onPressed: _pickAttachment,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Add Attachment'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: softFillColor,
                            side: BorderSide(color: borderColor),
                          ),
                        ),

                        if (_fileName != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: UIColors.success,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _fileName!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ================= PUBLISH BUTTON =================
                Container(
                  decoration: BoxDecoration(
                    gradient: UIColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: UIColors.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
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
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Publish Notice',
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
// LOCAL WIDGET
// =======================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
