import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart';
import 'package:instru_connect/features/resources/services/resource_service.dart';

class AddResourceScreen extends StatefulWidget {
  const AddResourceScreen({super.key});

  @override
  State<AddResourceScreen> createState() =>
      _AddResourceScreenState();
}

class _AddResourceScreenState
    extends State<AddResourceScreen> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _resourceService = ResourceService();

  File? _selectedFile;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submit() async {
    if (_loading) return;

    if (_selectedFile == null ||
        _titleCtrl.text.trim().isEmpty ||
        _subjectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final role =
          await RoleService().fetchUserRole(user.uid);

      if (role.isEmpty) throw Exception('User role not found');

      await _resourceService.addResource(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        file: _selectedFile!,
        role: role,
        uid: user.uid,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ================= HEADER =================
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
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
                        'Add Resource',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- BODY CARD ----------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 16, 16, 0),
                    child: SizedBox(
                      width: double.infinity, // 🔥 KEY FIX
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle(
                                'Resource Details'),
                            const SizedBox(height: 16),

                            TextField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Title *',
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _subjectCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Subject *',
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _descCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 28),

                            const _SectionTitle('File'),
                            const SizedBox(height: 10),

                            OutlinedButton.icon(
                              icon: const Icon(
                                  Icons.attach_file_outlined),
                              label: Text(
                                _selectedFile == null
                                    ? 'Pick file'
                                    : _selectedFile!.path
                                        .split('/')
                                        .last,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed:
                                  _loading ? null : _pickFile,
                            ),

                            if (_selectedFile != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  Icon(Icons.check_circle,
                                      color: Colors.green,
                                      size: 18),
                                  SizedBox(width: 6),
                                  Text('File selected'),
                                ],
                              ),
                            ],

                            const Spacer(),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Upload Resource'),
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
