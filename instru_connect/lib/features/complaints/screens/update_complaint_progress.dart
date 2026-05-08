// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';

import '../services/complaint_service.dart';

class UpdateComplaintProgressScreen extends StatefulWidget {
  final String complaintId;
  final String currentStatus;

  const UpdateComplaintProgressScreen({
    super.key,
    required this.complaintId,
    required this.currentStatus,
  });

  @override
  State<UpdateComplaintProgressScreen> createState() =>
      _UpdateComplaintProgressScreenState();
}

class _UpdateComplaintProgressScreenState
    extends State<UpdateComplaintProgressScreen> {
  final _service = ComplaintService();
  final _noteController = TextEditingController();

  late String _status;
  bool _loading = false;

  final List<String> _allStatuses = [
    'submitted',
    'acknowledged',
    'in_progress',
    'resolved',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus == 'resolved'
        ? 'in_progress'
        : widget.currentStatus;
  }

  Future<bool> _canEditCurrentComplaint() async {
    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    return role == AppRoles.admin || role == AppRoles.faculty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.currentStatus == 'resolved'
              ? 'Reopen Complaint'
              : 'Update Progress',
        ),
      ),
      body: FutureBuilder<bool>(
        future: _canEditCurrentComplaint(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data != true) {
            return const Center(
              child: Text('You do not have permission to update this complaint.'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _allStatuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      enabled: status != 'submitted',
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: status == 'submitted'
                            ? const TextStyle(color: Colors.grey)
                            : null,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != 'submitted') {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: widget.currentStatus == 'resolved'
                        ? 'Reopen note (optional)'
                        : 'Progress note (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);

                          await _service.updateProgress(
                            complaintId: widget.complaintId,
                            status: _status,
                            progressNote: _noteController.text.trim().isEmpty
                                ? null
                                : _noteController.text.trim(),
                          );

                          if (mounted) Navigator.pop(context);
                        },
                  child: Text(
                    widget.currentStatus == 'resolved' ? 'Reopen' : 'Update',
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
