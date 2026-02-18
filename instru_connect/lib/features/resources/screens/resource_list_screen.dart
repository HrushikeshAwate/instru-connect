import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/services/resource_service.dart';
import 'package:instru_connect/features/resources/widgets/empty_resource_view.dart';
import '../../../config/theme/ui_colors.dart';

class ResourceListScreen extends StatefulWidget {
  const ResourceListScreen({super.key});

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final ResourceService _resourceService = ResourceService();
  final RoleService _roleService = RoleService();
  late Future<List<ResourceModel>> _resourcesFuture;
  late Future<bool> _canAddResourceFuture;

  @override
  void initState() {
    super.initState();
    _resourcesFuture = _resourceService.fetchResources();
    _canAddResourceFuture = _resolveCanAddResource();
  }

  Future<bool> _resolveCanAddResource() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final role = await _roleService.fetchUserRole(user.uid);
      return role == 'faculty' || role == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<void> _openAddResource() async {
    await Navigator.pushNamed(context, Routes.addResource);
    if (!mounted) return;
    setState(() {
      _resourcesFuture = _resourceService.fetchResources();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,
      floatingActionButton: FutureBuilder<bool>(
        future: _canAddResourceFuture,
        builder: (context, snapshot) {
          if (snapshot.data != true) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _openAddResource,
            icon: const Icon(Icons.add),
            label: const Text('Add Resource'),
          );
        },
      ),
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
                // ================= CUSTOM APP BAR =================
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
                        'Study Resources',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= BODY =================
                Expanded(
                  child: FutureBuilder<List<ResourceModel>>(
                    future: _resourcesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Failed to load resources'),
                        );
                      }

                      final resources = snapshot.data;
                      if (resources == null || resources.isEmpty) {
                        return const EmptyResourcesView();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: resources.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return ResourceTile(resource: resources[index]);
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

class ResourceTile extends StatelessWidget {
  final ResourceModel resource;

  const ResourceTile({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // ✅ WHITE like notice
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
            Navigator.pushNamed(
              context,
              Routes.resourceDetail,
              arguments: resource,
            );
          },

          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT ACCENT STRIP (same as notice)
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resource.subject,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: UIColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
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
