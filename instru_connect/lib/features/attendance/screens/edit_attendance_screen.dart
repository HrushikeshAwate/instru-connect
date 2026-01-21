import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../batches/services/batch_service.dart'; // Ensure this path is correct

class EditAttendanceScreen extends StatefulWidget {
  final String batchId;
  final String attendanceDocId;
  final String subjectName;
  final List<String> currentAbsentUids;

  const EditAttendanceScreen({
    super.key,
    required this.batchId,
    required this.attendanceDocId,
    required this.subjectName,
    required this.currentAbsentUids,
  });

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  // Use a simple Set for faster lookups and easier state management
  late Set<String> selectedAbsentIds;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the UIDs already marked as absent in Firestore
    selectedAbsentIds = Set.from(widget.currentAbsentUids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit ${widget.subjectName}"),
      ),
      body: Column(
        children: [
          // Banner instruction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade50,
            child: const Row(
              children: [
                Icon(Icons.edit, color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Text("Update student status below",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
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

                final students = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final data = students[index].data() as Map<String, dynamic>;
                    final String uid = students[index].id;

                    // Match your DB keys: 'Name' and 'MIS No'
                    final String name = data['Name'] ?? data['name'] ?? "Unknown";
                    final String mis = (data['MIS No'] ?? data['mis'] ?? "N/A").toString();

                    bool isTicked = selectedAbsentIds.contains(uid);

                    return CheckboxListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text("MIS: $mis"),
                      value: isTicked,
                      activeColor: Colors.red,
                      secondary: CircleAvatar(
                        backgroundColor: isTicked ? Colors.red.shade100 : Colors.green.shade100,
                        child: Icon(
                          isTicked ? Icons.person_off : Icons.person,
                          color: isTicked ? Colors.red : Colors.green,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedAbsentIds.add(uid);
                          } else {
                            selectedAbsentIds.remove(uid);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Submit button
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
                onPressed: _isUpdating ? null : _saveChanges,
                child: _isUpdating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _saveChanges() async {
    setState(() => _isUpdating = true);

    try {
      // Fetch all student UIDs currently in the list to pass to the service
      final studentQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('batchId', isEqualTo: widget.batchId)
          .where('role', whereIn: ['student', 'cr'])
          .get();

      final List<String> allUids = studentQuery.docs.map((doc) => doc.id).toList();

      // Ensure the parameter names match your BatchService exactly
      await BatchService().updateAttendance(
        batchId: widget.batchId,
        docId: widget.attendanceDocId, // Changed from attendanceDocId to docId to match service
        subjectName: widget.subjectName,
        newAbsentUids: selectedAbsentIds.toList(),
        allStudentUids: allUids,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}