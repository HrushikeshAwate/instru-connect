import 'package:flutter/material.dart';

class EmptyResourcesView extends StatelessWidget {
  const EmptyResourcesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No resources available yet',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
