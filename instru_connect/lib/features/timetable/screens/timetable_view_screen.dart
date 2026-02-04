import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Already in your pubspec

class TimetableViewScreen extends StatefulWidget {
  final String assetPath;

  const TimetableViewScreen({super.key, required this.assetPath});

  @override
  State<TimetableViewScreen> createState() => _TimetableViewScreenState();
}

class _TimetableViewScreenState extends State<TimetableViewScreen> {
  String? localPath;
  int totalPages = 0;
  int currentPage = 0;
  bool isReady = false;
  late PDFViewController pdfController;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final bytes = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      // Use a clean filename without apostrophes for the file system
      final cleanName = widget.assetPath.split('/').last.replaceAll("'", "");
      final file = File("${dir.path}/$cleanName");

      await file.writeAsBytes(bytes, flush: true);
      setState(() {
        localPath = file.path;
      });
    } catch (e) {
      debugPrint("Error loading PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Better for PDF focus
      appBar: AppBar(
        title: Text(widget.assetPath.split('/').last),
        backgroundColor: const Color(0xFF263238),
        actions: [
          // Share/Download Button
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              if (localPath != null) {
                await Share.shareXFiles([XFile(localPath!)], text: 'My Timetable');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (localPath != null)
            PDFView(
              filePath: localPath,
              enableSwipe: true,
              swipeHorizontal: false, // Vertical scroll is usually easier for schedules
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) => setState(() => totalPages = pages!),
              onViewCreated: (controller) => pdfController = controller,
              onPageChanged: (page, total) => setState(() => currentPage = page!),
              onError: (error) => debugPrint(error.toString()),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Page Indicator Overlay
          if (isReady || totalPages > 0)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Page ${currentPage + 1} of $totalPages",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      // Floating Action Buttons for quick navigation
      floatingActionButton: totalPages > 1
          ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "prev",
            onPressed: () => pdfController.setPage(currentPage - 1),
            child: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: "next",
            onPressed: () => pdfController.setPage(currentPage + 1),
            child: const Icon(Icons.chevron_right),
          ),
        ],
      )
          : null,
    );
  }
}