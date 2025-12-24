import 'package:flutter/material.dart';
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

  // IMPORTANT: include 'submitted' for dropdown validity
  final List<String> _allStatuses = [
    'submitted',
    'acknowledged',
    'in_progress',
    'resolved',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _allStatuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  // Disable selecting "submitted"
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
              decoration: const InputDecoration(
                labelText: 'Progress note (optional)',
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
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
