import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // Removed 'FY' from the list
  String _selectedYear = 'SY';
  final List<String> _years = ['SY', 'TY', 'BTech'];

  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() => isLoading = true);
    try {
      // Constructs path based on your pubspec.yaml structure
      final String assetPath =
          "assets/PDF's/${_selectedYear.toLowerCase()}_timetable.pdf";

      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();

      final String filename = "${_selectedYear.toLowerCase()}_temp.pdf";
      final file = File("${dir.path}/$filename");

      await file.writeAsBytes(bytes, flush: true);

      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading PDF: $e");
      setState(() {
        isLoading = false;
        localPath = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not load PDF for $_selectedYear")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        // Heading text is now White
        title: const Text(
          'Official Timetable',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // Ensures the back arrow button is also White
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF263238),
        actions: [
          // Year Selection Dropdown
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
          ? PDFView(
              filePath: localPath,
              enableSwipe: true,
              autoSpacing: true,
              pageFling: true,
              swipeHorizontal: false,
            )
          : const Center(child: Text("Timetable not available")),
    );
  }
}
