import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/batch_service.dart';

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

  // Stores presence status: Key = UID, Value = true (present)
  Map<String, bool> attendanceStatus = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mark: ${widget.subjectName}"),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('batchId', isEqualTo: widget.batchId)
            .where('role', whereIn: ['student', 'cr'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No students found in this batch."));
          }

          final students = snapshot.data!.docs;

          return Column(
            children: [
              Container(
                color: Colors.blue.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Uncheck the box if the student is ABSENT"),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final studentDoc = students[index];
                    final String uid = studentDoc.id;

                    // --- SAFETY FIX START ---
                    // This converts the document to a Map so we can check for fields safely
                    final Map<String, dynamic> data = studentDoc.data() as Map<String, dynamic>;

                    // We check if 'name' exists. If not, we use "Unnamed" instead of crashing.
                    final String name = data.containsKey('name') ? data['name'] : "Unnamed Student";
                    final String rollNo = data.containsKey('rollNo') ? data['rollNo'] : "N/A";
                    // --- SAFETY FIX END ---

                    attendanceStatus.putIfAbsent(uid, () => true);

                    return CheckboxListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text("Roll: $rollNo"),
                      value: attendanceStatus[uid],
                      activeColor: Colors.green,
                      onChanged: (bool? val) {
                        setState(() {
                          attendanceStatus[uid] = val!;
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSaving ? null : () => _handleSave(),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SUBMIT ATTENDANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    List<String> allUids = attendanceStatus.keys.toList();
    List<String> absentUids = attendanceStatus.entries
        .where((entry) => entry.value == false)
        .map((entry) => entry.key)
        .toList();

    try {
      await _batchService.submitAttendance(
        batchId: widget.batchId,
        subjectName: widget.subjectName,
        absentStudentUids: absentUids,
        allStudentUids: allUids,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance recorded successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}