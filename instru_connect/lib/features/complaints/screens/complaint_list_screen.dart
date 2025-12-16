import 'package:flutter/material.dart';

class ComplaintListScreen extends StatelessWidget {
  const ComplaintListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // placeholder
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Complaint #${index + 1}'),
            subtitle: const Text('Status: Pending'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Later → ComplaintDetailScreen
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Later → CreateComplaintScreen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
