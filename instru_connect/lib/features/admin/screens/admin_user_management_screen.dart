// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/firestore/batch_services.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';
import '../../../config/theme/ui_colors.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedBatchId = _allBatchesValue;

  static const String _allBatchesValue = '__all_batches__';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            height: 220,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildFiltersCard(context),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('batches')
                        .snapshots(),
                    builder: (context, batchesSnapshot) {
                      final batchNameById = <String, String>{};
                      if (batchesSnapshot.hasData) {
                        for (final doc in batchesSnapshot.data!.docs) {
                          batchNameById[doc.id] =
                              (doc.data()['name'] ?? doc.id).toString();
                        }
                      }

                      return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, usersSnapshot) {
                          if (usersSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!usersSnapshot.hasData ||
                              usersSnapshot.data!.docs.isEmpty) {
                            return const _EmptyState();
                          }

                          final filteredUsers = _buildFilteredUsers(
                            usersSnapshot.data!.docs,
                            batchNameById,
                          );

                          if (filteredUsers.isEmpty) {
                            return const _NoResultsState();
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final doc = filteredUsers[index];
                              final data = doc.data();
                              final batchId =
                                  (data['batchId'] ?? '').toString().trim();

                              return _UserCard(
                                userId: doc.id,
                                name:
                                    (data['name'] ?? 'Unknown User').toString(),
                                email:
                                    (data['email'] ?? 'Unknown').toString(),
                                role:
                                    (data['role'] ?? 'unknown').toString(),
                                batchId: batchId.isEmpty ? null : batchId,
                                batchName: batchId.isEmpty
                                    ? null
                                    : batchNameById[batchId] ?? batchId,
                              );
                            },
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

  Widget _buildFiltersCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('batches').snapshots(),
      builder: (context, snapshot) {
        final batchDocs = snapshot.data?.docs.toList() ?? [];
        batchDocs.sort((a, b) {
          final aName = (a.data()['name'] ?? a.id).toString().toLowerCase();
          final bName = (b.data()['name'] ?? b.id).toString().toLowerCase();
          return aName.compareTo(bName);
        });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, email, role, or batch',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBatchId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Sort / Filter by batch',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _allBatchesValue,
                    child: Text('All batches'),
                  ),
                  ...batchDocs.map(
                    (doc) => DropdownMenuItem(
                      value: doc.id,
                      child: Text((doc.data()['name'] ?? doc.id).toString()),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedBatchId = value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _buildFilteredUsers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    Map<String, String> batchNameById,
  ) {
    final filtered = users.where((doc) {
      final data = doc.data();
      final batchId = (data['batchId'] ?? '').toString().trim();
      final batchName = (batchNameById[batchId] ?? batchId).toLowerCase();

      if (_selectedBatchId != _allBatchesValue && batchId != _selectedBatchId) {
        return false;
      }

      if (_searchQuery.isEmpty) {
        return true;
      }

      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? '').toString().toLowerCase();

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          role.contains(_searchQuery) ||
          batchName.contains(_searchQuery);
    }).toList();

    filtered.sort((a, b) {
      final aData = a.data();
      final bData = b.data();

      final aBatchId = (aData['batchId'] ?? '').toString().trim();
      final bBatchId = (bData['batchId'] ?? '').toString().trim();
      final aBatchName = (batchNameById[aBatchId] ?? aBatchId).toLowerCase();
      final bBatchName = (batchNameById[bBatchId] ?? bBatchId).toLowerCase();
      final batchCompare = aBatchName.compareTo(bBatchName);
      if (batchCompare != 0) return batchCompare;

      final aName = (aData['name'] ?? '').toString().toLowerCase();
      final bName = (bData['name'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });

    return filtered;
  }
}

class _UserCard extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? batchId;
  final String? batchName;

  const _UserCard({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.batchId,
    this.batchName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: userId, readOnly: true),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: UIColors.primaryGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: role.toUpperCase()),
                          _InfoChip(label: batchName ?? 'No Batch'),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View profile',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(userId: userId, readOnly: true),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 20,
                        color: UIColors.textMuted,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Manage role',
                      onPressed: () {
                        _showRoleDialog(
                          context: context,
                          userId: userId,
                          currentRole: role,
                          batchId: batchId,
                        );
                      },
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: UIColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: UIColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: UIColors.primary,
          fontWeight: FontWeight.w600,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  await batchService.assignCR(userId: userId, batchId: batchId);
                } else if (selectedRole == 'faculty') {
                  await roleService.assignFaculty(userId);
                } else if (selectedRole == 'staff') {
                  await roleService.assignStaff(userId);
                } else if (selectedRole == 'admin') {
                  await roleService.assignAdmin(userId);
                }

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Assign'),
          ),
        ],
      );
    },
  );
}

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
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: UIColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: UIColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching users',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
