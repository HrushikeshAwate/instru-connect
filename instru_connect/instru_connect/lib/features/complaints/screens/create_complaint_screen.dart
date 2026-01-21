import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/complaint_service.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() =>
      _CreateComplaintScreenState();
}

class _CreateComplaintScreenState
    extends State<CreateComplaintScreen> {
  final _service = ComplaintService();

  final _title = TextEditingController();
  final _description = TextEditingController();

  String _category = 'Technical';
  File? _mediaFile;
  String? _mediaType;
  bool _loading = false;

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

    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    final token = await user.getIdTokenResult();
    final role = token.claims?['role'] ?? 'unknown';

    final docRef = await _service.createComplaint(
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      createdBy: uid,
      createdByRole: role,
      departmentId: '',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise Complaint'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // =================================================
          // BASIC DETAILS
          // =================================================
          const _SectionTitle('Complaint Details'),
          const SizedBox(height: 12),

          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
            ),
            items: const [
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
            onChanged: (v) =>
                setState(() => _category = v!),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
            ),
          ),

          const SizedBox(height: 24),

          // =================================================
          // ATTACHMENT
          // =================================================
          const _SectionTitle('Attachment (Optional)'),
          const SizedBox(height: 8),

          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.image_outlined),
                label: const Text('Add Image'),
                onPressed: () => _pickMedia(false),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Add Video'),
                onPressed: () => _pickMedia(true),
              ),
            ],
          ),

          if (_mediaFile != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_mediaType selected',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // =================================================
          // SUBMIT
          // =================================================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit Complaint'),
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
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
