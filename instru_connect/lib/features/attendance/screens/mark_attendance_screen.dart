import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../batches/services/batch_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String batchId;
  final String subjectName;

  const MarkAttendanceScreen({
    super.key,
    required this.batchId,
    required this.subjectName,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final BatchService _batchService = BatchService();
  final TextEditingController _searchController = TextEditingController();

  // Maps to store state. Using a Map for status ensures we don't lose data
  // when the StreamBuilder rebuilds or filters the list.
  Map<String, bool> absentStatus = {};
  String _searchQuery = "";
  bool _isSaving = false;

  // Function to handle the Submit action
  Future<void> _handleSave() async {
    // Collect all UIDs currently in the status map
    List<String> allUids = absentStatus.keys.toList();

    // Filter only those who are marked as true (Absent)
    List<String> absentUids = absentStatus.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    if (allUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No students available to mark attendance.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Calls the BatchService to handle Firestore updates
      await _batchService.submitAttendance(
        batchId: widget.batchId,
        subjectName: widget.subjectName,
        absentStudentUids: absentUids,
        allStudentUids: allUids,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance submitted successfully!")),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text("Action Failed"),
          ],
        ),
        content: Text(error.replaceAll("Exception: ", "")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName),
            Text(formattedDate,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Name or MIS...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Legend/Instruction
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red.shade50,
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text("Tick students who are ABSENT",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),

          // Real-time Student List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('batchId', isEqualTo: widget.batchId)
                  .where('role', whereIn: ['student', 'cr'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Filter docs based on search query locally
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['Name'] ?? data['name'] ?? "").toString().toLowerCase();
                  final mis = (data['MIS No'] ?? data['mis'] ?? "").toString();
                  return name.contains(_searchQuery) || mis.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No students found in this batch."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String uid = docs[index].id;

                    // Support both naming conventions seen in your DB
                    final String name = data['Name'] ?? data['name'] ?? "Unknown Student";
                    final String mis = (data['MIS No'] ?? data['mis'] ?? "N/A").toString();

                    // Initialize the status in the map if it's the first time we see this student
                    absentStatus.putIfAbsent(uid, () => false);

                    bool isAbsent = absentStatus[uid]!;

                    return CheckboxListTile(
                      activeColor: Colors.red,
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text("MIS: $mis"),
                      value: isAbsent,
                      secondary: CircleAvatar(
                        backgroundColor: isAbsent ? Colors.red.shade100 : Colors.green.shade100,
                        child: Icon(
                          isAbsent ? Icons.person_off : Icons.person,
                          color: isAbsent ? Colors.red : Colors.green,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          absentStatus[uid] = val!;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Submit Action
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT ATTENDANCE",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}