import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/services/resource_service.dart';
import 'package:instru_connect/features/resources/widgets/empty_resource_view.dart';
import '../../../config/theme/ui_colors.dart';

class ResourceListScreen extends StatelessWidget {
  const ResourceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ResourceService resourceService = ResourceService();

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
                    future: resourceService.fetchResources(),
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
