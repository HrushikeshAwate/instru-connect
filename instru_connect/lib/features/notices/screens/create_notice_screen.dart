import 'package:flutter/material.dart';
// import 'package:instru_connect/core/constants/firestore_collections.dart';
import 'package:instru_connect/features/notices/services/notice_service.dart';
// import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/storage_service.dart';
// import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

class CreateNoticeScreen extends StatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();

  final NoticeService _noticeService = NoticeService();
  final StorageService _storageService = StorageService();

  Uint8List? _fileBytes;
  String? _fileName;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  // Placeholder for Step 4 (attachments)
  String? _selectedAttachmentName;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
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
        _selectedAttachmentName = _fileName;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      const String departmentId = 'Instrumentation'; // same source as READ

      final noticeId = await _noticeService.createNotice(
        title: _titleController.text,
        body: _bodyController.text,
        departmentId: departmentId,
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

      if (!mounted) return;
      Navigator.pop(context,true);
    } catch (e, st) {
      debugPrint('CREATE NOTICE ERROR: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Notice')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter notice title',
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Body
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Notice Content',
                    hintText: 'Enter notice details',
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Notice content is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Attachment (optional)
                OutlinedButton.icon(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Add Attachment (optional)'),
                ),

                if (_selectedAttachmentName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Selected: $_selectedAttachmentName',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publish Notice'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
