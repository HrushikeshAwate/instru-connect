import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/session/current_user.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/features/career_links/services/career_links_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerLinksScreen extends ConsumerWidget {
  const CareerLinksScreen({super.key});

  bool get _canEdit {
    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    return role == AppRoles.admin;
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link will be added soon.')));
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
  }

  Future<void> _editLink(
    BuildContext context,
    WidgetRef ref,
    CareerLinkItem link,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CareerLinkEditDialog(link: link),
    );

    if (result == null) return;
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    try {
      await ref
          .read(careerLinksServiceProvider)
          .updateLink(linkId: link.id, url: result, uid: user.uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link updated')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const AppHeroBackground(height: 174),
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
                      const Expanded(
                        child: Text(
                          'Internships & Placements',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<CareerLinkItem>>(
                    stream: ref.read(careerLinksServiceProvider).streamLinks(),
                    builder: (context, snapshot) {
                      final links =
                          snapshot.data ?? CareerLinksService.defaultLinks;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                        children: [
                          AppSectionHeader(
                            title: 'Career Sheets',
                            subtitle: _canEdit
                                ? 'Admin can edit sheet links.'
                                : 'Open official sheets shared by department.',
                          ),
                          const SizedBox(height: 14),
                          ...links.map(
                            (link) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CareerLinkButton(
                                link: link,
                                canEdit: _canEdit,
                                onOpen: () => _openLink(context, link.url),
                                onEdit: () => _editLink(context, ref, link),
                              ),
                            ),
                          ),
                        ],
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

class _CareerLinkEditDialog extends StatefulWidget {
  const _CareerLinkEditDialog({required this.link});

  final CareerLinkItem link;

  @override
  State<_CareerLinkEditDialog> createState() => _CareerLinkEditDialogState();
}

class _CareerLinkEditDialogState extends State<_CareerLinkEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.link.url);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.link.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Sheet link',
          hintText: 'https://docs.google.com/spreadsheets/...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CareerLinkButton extends StatelessWidget {
  const _CareerLinkButton({
    required this.link,
    required this.canEdit,
    required this.onOpen,
    required this.onEdit,
  });

  final CareerLinkItem link;
  final bool canEdit;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        minTileHeight: 78,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: UIColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.table_chart_outlined, color: Colors.white),
        ),
        title: Text(
          link.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          link.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: canEdit
            ? IconButton(
                tooltip: 'Edit link',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              )
            : const Icon(Icons.open_in_new_rounded),
        onTap: onOpen,
      ),
    );
  }
}
