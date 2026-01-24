import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../batches/services/batch_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String batchId;
  final String subjectName;
  final bool isEditing;
  final String? docId;
  final List<String>? initialAbsentees;

  const MarkAttendanceScreen({
    super.key,
    required this.batchId,
    required this.subjectName,
    this.isEditing = false,
    this.docId,
    this.initialAbsentees,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final BatchService _batchService = BatchService();
  final TextEditingController _searchController = TextEditingController();

  Map<String, bool> absentStatus = {};
  String _searchQuery = "";
  bool _isSaving = false;
  bool _hasInitialized = false;

  Future<void> _handleSave() async {
    List<String> allUids = absentStatus.keys.toList();
    List<String> absentUids = absentStatus.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    if (allUids.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      if (widget.isEditing && widget.docId != null) {
        await _batchService.updateAttendance(
          batchId: widget.batchId,
          docId: widget.docId!,
          subjectName: widget.subjectName,
          newAbsentUids: absentUids,
          allStudentUids: allUids,
        );
      } else {
        await _batchService.submitAttendance(
          batchId: widget.batchId,
          subjectName: widget.subjectName,
          absentStudentUids: absentUids,
          allStudentUids: allUids,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Edit Attendance" : "Mark Attendance"),
        backgroundColor: widget.isEditing ? Colors.orange.shade800 : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search Name or MIS No",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // Instructional Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red.shade50,
            child: const Text(
              "TICK STUDENTS WHO ARE ABSENT",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

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

                final docs = snapshot.data!.docs;

                // Initialize map once
                if (!_hasInitialized) {
                  for (var doc in docs) {
                    final uid = doc.id;
                    if (widget.isEditing && widget.initialAbsentees != null) {
                      absentStatus[uid] = widget.initialAbsentees!.contains(uid);
                    } else {
                      absentStatus[uid] = false;
                    }
                  }
                  _hasInitialized = true;
                }

                // IMPROVED SEARCH: Safe field access prevents crashes
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['Name'] ?? data['name'] ?? "").toString().toLowerCase();
                  final mis = (data['MIS No'] ?? data['mis'] ?? "").toString().toLowerCase();
                  return name.contains(_searchQuery) || mis.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = doc.id;

                    // FIX: Safe access to student info
                    final String name = data['Name'] ?? data['name'] ?? "Unknown Student";
                    final String mis = (data['MIS No'] ?? data['mis'] ?? "N/A").toString();

                    bool isAbsent = absentStatus[uid] ?? false;

                    return CheckboxListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text("MIS: $mis"),
                      activeColor: Colors.red,
                      secondary: CircleAvatar(
                        backgroundColor: isAbsent ? Colors.red.shade100 : Colors.green.shade100,
                        child: Icon(
                          isAbsent ? Icons.person_off : Icons.person,
                          color: isAbsent ? Colors.red : Colors.green,
                        ),
                      ),
                      value: isAbsent,
                      onChanged: (bool? newValue) {
                        setState(() {
                          absentStatus[uid] = newValue ?? false;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isEditing ? Colors.orange.shade800 : Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  widget.isEditing ? "UPDATE CHANGES" : "CONFIRM CHANGES",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}


