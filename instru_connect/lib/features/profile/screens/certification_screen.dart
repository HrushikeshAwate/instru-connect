import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/features/profile/services/certification_service.dart';
class CertificationsScreen extends StatelessWidget {
  const CertificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = CertificationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Certifications')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, service, uid),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: service.fetchCertificates(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final certs = snapshot.data!;
          if (certs.isEmpty) {
            return const Center(child: Text('No certificates added'));
          }

          return ListView.builder(
            itemCount: certs.length,
            itemBuilder: (_, i) {
              final c = certs[i];
              return ListTile(
                title: Text(c.title),
                subtitle: Text(c.issuer),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // open URL (url_launcher)
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    CertificationService service,
    String uid,
  ) {
    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Certificate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: issuerCtrl, decoration: const InputDecoration(labelText: 'Issuer')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await service.uploadCertificate(
                uid: uid,
                title: titleCtrl.text.trim(),
                issuer: issuerCtrl.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}
