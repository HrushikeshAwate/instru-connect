import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/firestore/batch_services.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['email'] ?? 'Unknown'),
                subtitle: Text('Role: ${data['role']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showRoleDialog(
                      context: context,
                      userId: doc.id,
                      currentRole: data['role'],
                      batchId: data['batchId'],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}


Future<void> _showRoleDialog({
  required BuildContext context,
  required String userId,
  required String currentRole,
  String? batchId,
}) async {
  final roleService = RoleService();
  final batchService = BatchService();

  String selectedRole = currentRole;

  await showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('Assign Role'),
        content: DropdownButton<String>(
          value: selectedRole,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'student', child: Text('Student')),
            DropdownMenuItem(value: 'cr', child: Text('CR')),
            DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
            DropdownMenuItem(value: 'staff', child: Text('Staff')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (value) {
            if (value != null) selectedRole = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Assign'),
            onPressed: () async {
              try {
                if (selectedRole == 'cr') {
                  if (batchId == null) {
                    throw Exception('User has no batch');
                  }
                  await batchService.assignCR(
                    userId: userId,
                    batchId: batchId,
                  );
                } else if (selectedRole == 'faculty') {
                  await roleService.assignFaculty(userId);
                } else if (selectedRole == 'staff') {
                  await roleService.assignStaff(userId);
                } else if (selectedRole == 'admin') {
                  await roleService.assignAdmin(userId);
                }

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
