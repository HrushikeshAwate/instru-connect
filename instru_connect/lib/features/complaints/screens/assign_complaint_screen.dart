import 'package:flutter/material.dart';
import '../services/complaint_service.dart';
import '../../../config/theme/ui_colors.dart';

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
      backgroundColor: UIColors.background,
      body: Stack(
        children: [
          // ---------------------------------------------
          // HEADER GRADIENT
          // ---------------------------------------------
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ---------------------------------------------
                // CUSTOM APP BAR
                // ---------------------------------------------
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Assign Complaint',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------------------------------------------
                // CONTENT
                // ---------------------------------------------
                Expanded(
                  child: FutureBuilder<List<Map<String, String>>>(
                    future: _service.fetchAssignableUsers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final users = snapshot.data!;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---------------------------------------------
                            // INFO CARD
                            // ---------------------------------------------
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: UIColors.primary.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Assign To',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: UIColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Select a staff or faculty member responsible for resolving this complaint.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: UIColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // ---------------------------------------------
                                  // DROPDOWN
                                  // ---------------------------------------------
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'User',
                                      filled: true,
                                      fillColor: UIColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
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
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ---------------------------------------------
                            // ACTION BUTTON
                            // ---------------------------------------------
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: UIColors.primaryGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        UIColors.primary.withOpacity(0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: _loading ||
                                        _selectedUserId == null
                                    ? null
                                    : () async {
                                        setState(() => _loading = true);

                                        await _service.assignComplaint(
                                          complaintId: widget.complaintId,
                                          assignedTo: _selectedUserId!,
                                          assignedRole: _selectedRole!,
                                        );

                                        if (mounted) {
                                          Navigator.pop(context);
                                        }
                                      },
                                child: _loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Assign Complaint',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
