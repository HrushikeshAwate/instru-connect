import 'package:flutter/material.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/config/routes/route_names.dart';

class ResourceTile extends StatelessWidget {
  final ResourceModel resource;

  const ResourceTile({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf),
      title: Text(resource.title),
      subtitle: Text(resource.subject),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.resourceDetail,
          arguments: resource,
        );
      },
    );
  }
}
