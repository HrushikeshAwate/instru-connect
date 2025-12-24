import 'package:flutter/material.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/services/resource_service.dart';
import 'package:instru_connect/features/resources/widgets/empty_resource_view.dart';
import 'package:instru_connect/features/resources/widgets/resource_tile.dart';

class ResourceListScreen extends StatelessWidget {
  const ResourceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ResourceService resourceService = ResourceService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Resources'),
      ),
      body: FutureBuilder<List<ResourceModel>>(
        future: resourceService.fetchResources(),
        builder: (context, snapshot) {
          // =================================================
          // LOADING
          // =================================================
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // =================================================
          // ERROR
          // =================================================
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load resources'),
            );
          }

          // =================================================
          // EMPTY
          // =================================================
          final resources = snapshot.data;
          if (resources == null || resources.isEmpty) {
            return const EmptyResourcesView();
          }

          // =================================================
          // LIST
          // =================================================
          return ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: resources.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return ResourceTile(
                resource: resources[index],
              );
            },
          );
        },
      ),
    );
  }
}
