import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/services/resource_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! ResourceModel) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resource')),
        body: const Center(child: Text('Resource data not available')),
      );
    }

    final ResourceModel resource = args;
    final resourceService = ResourceService();
    final canDeleteFuture = _resolveCanDeleteResources();
    final canUseLinkControlsFuture = _resolveCanUseLinkControls();
    final fileUri = Uri.parse(resource.fileUrl);
    final previewUri = Uri.https('docs.google.com', '/gview', {
      'embedded': 'true',
      'url': resource.fileUrl,
    });

    Future<void> copyResourceLink() async {
      await Clipboard.setData(ClipboardData(text: resource.fileUrl));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download link copied')));
    }

    Future<void> openResourceLink() async {
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      }
    }

    Future<void> previewResource() async {
      final uri = _canUseDocumentPreview(resource.fileType)
          ? previewUri
          : fileUri;
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF4F46E5),
                  Color(0xFF06B6D4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Resource',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FutureBuilder<bool>(
                        future: canUseLinkControlsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.data != true) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            tooltip: 'Copy download link',
                            icon: const Icon(
                              Icons.link_rounded,
                              color: Colors.white,
                            ),
                            onPressed: copyResourceLink,
                          );
                        },
                      ),
                      FutureBuilder<bool>(
                        future: canDeleteFuture,
                        builder: (context, snapshot) {
                          if (snapshot.data != true) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              final confirmed =
                                  await showDestructiveConfirmationDialog(
                                    context: context,
                                    title: 'Delete Resource?',
                                    message:
                                        'This resource will be permanently deleted and cannot be recovered. The uploaded file and its details will be removed.',
                                  );
                              if (confirmed != true) return;

                              try {
                                await resourceService.deleteResource(resource);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${resource.subject} - ${resource.section}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              if (resource.description.isNotEmpty) ...[
                                const _SectionTitle('Description'),
                                const SizedBox(height: 8),
                                Text(
                                  resource.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 24),
                              ],
                              FutureBuilder<bool>(
                                future: canUseLinkControlsFuture,
                                builder: (context, snapshot) {
                                  final canUseLinkControls =
                                      snapshot.data == true;
                                  return _AccessSection(
                                    resourceUrl: resource.fileUrl,
                                    canUseLinkControls: canUseLinkControls,
                                    onCopyLink: copyResourceLink,
                                    onOpenLink: openResourceLink,
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                      label: const Text('Preview'),
                                      onPressed: previewResource,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.download_rounded),
                                      label: const Text('Download'),
                                      onPressed: openResourceLink,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

bool _canUseDocumentPreview(String fileType) {
  final type = fileType.toLowerCase();
  return type == 'pdf' ||
      type == 'doc' ||
      type == 'docx' ||
      type == 'ppt' ||
      type == 'pptx';
}

Future<bool> _resolveCanUseLinkControls() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  try {
    final role = await RoleService().fetchUserRole(user.uid);
    final normalizedRole = role.trim().toLowerCase();
    return normalizedRole == AppRoles.cr ||
        normalizedRole == AppRoles.faculty ||
        normalizedRole == AppRoles.admin;
  } catch (_) {
    return false;
  }
}

Future<bool> _resolveCanDeleteResources() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  try {
    final role = await RoleService().fetchUserRole(user.uid);
    final normalizedRole = role.trim().toLowerCase();
    return normalizedRole == AppRoles.faculty ||
        normalizedRole == AppRoles.admin;
  } catch (_) {
    return false;
  }
}

class _AccessSection extends StatelessWidget {
  final String resourceUrl;
  final bool canUseLinkControls;
  final VoidCallback onCopyLink;
  final VoidCallback onOpenLink;

  const _AccessSection({
    required this.resourceUrl,
    required this.canUseLinkControls,
    required this.onCopyLink,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Access'),
        const SizedBox(height: 8),
        Text(
          canUseLinkControls
              ? 'Preview first without loading the file inside the app. Copy the link to use it on a laptop.'
              : 'Preview the file first, then download it when needed.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (canUseLinkControls) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(resourceUrl, maxLines: 3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Copy Link'),
                  onPressed: onCopyLink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Link'),
                  onPressed: onOpenLink,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
