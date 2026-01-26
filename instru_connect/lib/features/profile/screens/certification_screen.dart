import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:instru_connect/features/profile/services/certification_service.dart';

class CertificationsScreen extends StatelessWidget {
  const CertificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = CertificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certifications'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, service, uid),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.fetchCertificates(uid),
        builder: (context, snapshot) {
          // ================= LOADING =================
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ================= ERROR =================
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load certifications'),
            );
          }

          final certs = snapshot.data ?? [];

          // ================= EMPTY STATE =================
          if (certs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No certificates yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap + to add your first certificate',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ================= LIST =================
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: certs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = certs[i];
              final fileType = c['fileType'];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(
                    fileType == 'pdf'
                        ? Icons.picture_as_pdf
                        : Icons.image,
                  ),
                  title: Text(c['title'] ?? 'Untitled'),
                  subtitle: Text(c['issuer'] ?? ''),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // Optional: open file using url_launcher
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =====================================================
  // ADD CERTIFICATE DIALOG (NO VALIDATION)
  // =====================================================

  void _showAddDialog(
    BuildContext context,
    CertificationService service,
    String uid,
  ) {
    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    PlatformFile? selectedFile;
    bool uploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Add Certificate'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: issuerCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Issuer'),
                  ),
                  const SizedBox(height: 16),

                  // PICK FILE BUTTON
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      selectedFile == null
                          ? 'Pick PDF or Image'
                          : selectedFile!.name,
                    ),
                    onPressed: uploading
                        ? null
                        : () async {
                            final file =
                                await service.pickCertificateFile();
                            if (file != null) {
                              setState(() => selectedFile = file);
                            }
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      uploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: uploading || selectedFile == null
                      ? null
                      : () async {
                          setState(() => uploading = true);

                          try {
                            await service.uploadCertificate(
                              uid: uid,
                              title: titleCtrl.text.trim(),
                              issuer: issuerCtrl.text.trim(),
                              file: selectedFile!,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Certificate uploaded'),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => uploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                  child: uploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
