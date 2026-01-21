import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/services/storage_service.dart';
import '../services/notice_service.dart';

class CreateNoticeScreen extends StatefulWidget {
  /// If provided, notice will ALWAYS be sent to these batches
  /// (used for CR)
  final List<String>? fixedBatchIds;

  /// Whether batch selector UI should be shown
  /// Faculty/Admin → true
  /// CR → false
  final bool showBatchSelector;

  const CreateNoticeScreen({
    super.key,
    this.fixedBatchIds,
    required this.showBatchSelector,
  });

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();

  final NoticeService _noticeService = NoticeService();
  final StorageService _storageService = StorageService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final Set<String> _selectedBatchIds = {};

  Uint8List? _fileBytes;
  String? _fileName;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // 🔒 CR case: force batchIds
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

  // --------------------------------------------------
  // Fetch ALL active batches (Faculty/Admin only)
  // --------------------------------------------------
  Future<List<Map<String, String>>> _fetchBatches() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('batches')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] as String,
      };
    }).toList();
  }

  // --------------------------------------------------
  // Pick attachment
  // --------------------------------------------------
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

  // --------------------------------------------------
  // Submit
  // --------------------------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBatchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No target batch selected')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      const String departmentId = 'Instrumentation';

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

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Notice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                maxLines: 6,
                decoration:
                    const InputDecoration(labelText: 'Notice Content'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),

              // =================================================
              // BATCH SELECTOR (ONLY FACULTY / ADMIN)
              // =================================================
              if (widget.showBatchSelector) ...[
                const SizedBox(height: 24),
                Text(
                  'Target Batches',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                FutureBuilder<List<Map<String, String>>>(
                  future: _fetchBatches(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    return Column(
                      children: snapshot.data!.map((batch) {
                        final id = batch['id']!;
                        final name = batch['name']!;
                        final selected =
                            _selectedBatchIds.contains(id);

                        return CheckboxListTile(
                          title: Text(name),
                          value: selected,
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

              OutlinedButton.icon(
                onPressed: _pickAttachment,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Attachment'),
              ),

              if (_fileName != null) Text('Selected: $_fileName'),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Publish Notice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
