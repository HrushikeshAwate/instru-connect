import 'package:flutter/material.dart';
import '../services/complaint_service.dart';

class AssignComplaintScreen extends StatefulWidget {
  final String complaintId;

  const AssignComplaintScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<AssignComplaintScreen> createState() =>
      _AssignComplaintScreenState();
}

class _AssignComplaintScreenState
    extends State<AssignComplaintScreen> {
  final _service = ComplaintService();

  String? _selectedUserId;
  String? _selectedRole;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Complaint'),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _service.fetchAssignableUsers(),
        builder: (context, snapshot) {
          // -----------------------------
          // LOADING
          // -----------------------------
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------
                // CONTEXT TEXT
                // ---------------------------------------------
                Text(
                  'Assign to',
                  style:
                      Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a staff or faculty member to handle this complaint.',
                  style:
                      Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------
                // DROPDOWN
                // ---------------------------------------------
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'User',
                  ),
                  items: users
                      .map(
                        (u) => DropdownMenuItem(
                          value: u['uid'],
                          child: Text(
                            '${u['name']} (${u['role']})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    final user = users.firstWhere(
                      (u) => u['uid'] == value,
                    );
                    setState(() {
                      _selectedUserId = value;
                      _selectedRole = user['role'];
                    });
                  },
                ),

                const Spacer(),

                // ---------------------------------------------
                // ACTION BUTTON
                // ---------------------------------------------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ||
                            _selectedUserId == null
                        ? null
                        : () async {
                            setState(() => _loading = true);

                            await _service.assignComplaint(
                              complaintId:
                                  widget.complaintId,
                              assignedTo:
                                  _selectedUserId!,
                              assignedRole:
                                  _selectedRole!,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Assign'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
