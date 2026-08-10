import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/session/current_user.dart';
import 'package:path_provider/path_provider.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key, this.showUploadAction = false});

  final bool showUploadAction;

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  String _selectedYear = 'SY';
  final List<String> _years = ['FY', 'SY', 'TY', 'BTech'];

  String? localPath;
  String? _sourceText;
  bool isLoading = true;
  bool _uploading = false;

  bool get _canManageTimetable {
    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    return widget.showUploadAction &&
        (role == AppRoles.faculty || role == AppRoles.admin);
  }

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() => isLoading = true);
    final year = _selectedYear;
    try {
      final service = ref.read(timetableServiceProvider);
      final dir = await getTemporaryDirectory();
      final uploaded = await service.fetchTimetable(year);

      String path;
      String sourceText;
      if (uploaded != null) {
        path = await service.downloadTimetableToFile(
          timetable: uploaded,
          directory: dir,
        );
        sourceText = 'Updated timetable: ${uploaded.fileName}';
      } else {
        path = await _loadAssetPdf(year, dir);
        sourceText = 'Default timetable';
      }

      if (!mounted || year != _selectedYear) return;
      setState(() {
        localPath = path;
        _sourceText = sourceText;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading PDF: $e");
      try {
        final dir = await getTemporaryDirectory();
        final path = await _loadAssetPdf(year, dir);
        if (!mounted) return;
        setState(() {
          localPath = path;
          _sourceText = 'Default timetable';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load updated timetable for $year. Showing default.',
            ),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          localPath = null;
          _sourceText = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Could not load PDF for $year")));
      }
    }
  }

  Future<String> _loadAssetPdf(String year, Directory dir) async {
    final assetPath = "assets/PDF's/${year.toLowerCase()}_timetable.pdf";
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final filename = '${year.toLowerCase()}_default_timetable.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _pickAndUploadPdf() async {
    if (_uploading || !_canManageTimetable) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _uploading = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      final role = (CurrentUser.role ?? '').trim().toLowerCase();
      if (role != AppRoles.faculty && role != AppRoles.admin) {
        throw Exception('Only faculty or admin can update timetables.');
      }

      await ref
          .read(timetableServiceProvider)
          .uploadTimetable(
            year: _selectedYear,
            file: File(result.files.single.path!),
            originalFileName: result.files.single.name,
            uid: user.uid,
            role: role,
          );

      await _loadPdf();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_selectedYear timetable updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: const Text(
          'Official Timetable',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF263238),
        actions: [
          if (_canManageTimetable)
            IconButton(
              tooltip: 'Upload timetable PDF',
              onPressed: _uploading ? null : _pickAndUploadPdf,
              icon: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file, color: Colors.white),
            ),
          DropdownButton<String>(
            value: _selectedYear,
            dropdownColor: const Color(0xFF263238),
            underline: const SizedBox(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: _years
                .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedYear = val);
                _loadPdf();
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF263238)),
            )
          : localPath != null
          ? Column(
              children: [
                if (_sourceText != null)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFECEFF1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      _sourceText!,
                      style: const TextStyle(
                        color: Color(0xFF37474F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Expanded(
                  child: PDFView(
                    filePath: localPath,
                    enableSwipe: true,
                    autoSpacing: true,
                    pageFling: true,
                    swipeHorizontal: false,
                  ),
                ),
              ],
            )
          : const Center(child: Text("Timetable not available")),
    );
  }
}
