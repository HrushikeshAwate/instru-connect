// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/firestore/batch_services.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart';
import '../../../config/theme/ui_colors.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,
      body: Stack(
        children: [
          // ================= HEADER =================
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
                // ================= APP BAR =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'User Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= USER LIST =================
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const _EmptyState();
                      }

                      final users = snapshot.data!.docs;

                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final doc = users[index];
                          final data =
                              doc.data() as Map<String, dynamic>;

                          return _UserCard(
                            userId: doc.id,
                            name: data['name'] ?? 'Unknown User',
                            email: data['email'] ?? 'Unknown',
                            role: data['role'] ?? 'unknown',
                            batchId: data['batchId'],
                          );
                        },
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

//
// =======================================================
// USER CARD
// =======================================================
//

class _UserCard extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? batchId;

  const _UserCard({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _showRoleDialog(
              context: context,
              userId: userId,
              currentRole: role,
              batchId: batchId,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // LEFT STRIP
                Container(
                  width: 6,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: UIColors.primaryGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),

                const SizedBox(width: 14),

                // CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // NAME
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),

                      const SizedBox(height: 4),

                      // EMAIL
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: UIColors.textSecondary,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // ROLE BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              UIColors.primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: UIColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.edit,
                  size: 18,
                  color: UIColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// =======================================================
// ROLE ASSIGN DIALOG
// =======================================================
//

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Assign Role'),
        content: DropdownButtonFormField<String>(
          initialValue: selectedRole,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Role',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'student', child: Text('Student')),
            DropdownMenuItem(value: 'cr', child: Text('CR')),
            DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
            DropdownMenuItem(value: 'staff', child: Text('Staff')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (v) => selectedRole = v!,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            child: const Text('Assign'),
          ),
        ],
      );
    },
  );
}

//
// =======================================================
// EMPTY STATE
// =======================================================
//

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: UIColors.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No users found',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
