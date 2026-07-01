import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:instru_connect/features/resources/models/resource_library_group.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/models/resource_screen_access.dart';
import 'package:instru_connect/features/resources/services/resource_service.dart';
import 'package:instru_connect/features/resources/utils/resource_access_actions.dart';

import '../../../config/theme/ui_colors.dart';

class ResourceSectionResourcesScreen extends ConsumerStatefulWidget {
  final ResourceSectionGroup section;
  final ResourceScreenAccess access;

  const ResourceSectionResourcesScreen({
    super.key,
    required this.section,
    required this.access,
  });

  @override
  ConsumerState<ResourceSectionResourcesScreen> createState() =>
      _ResourceSectionResourcesScreenState();
}

class _ResourceSectionResourcesScreenState
    extends ConsumerState<ResourceSectionResourcesScreen> {
  late final ResourceService _resourceService;
  final Set<String> _selectedIds = <String>{};
  bool _deleting = false;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _resourceService = ref.read(resourceServiceProvider);
  }

  void _toggleSelection(ResourceModel resource) {
    if (!widget.access.canManage) return;
    setState(() {
      if (_selectedIds.contains(resource.id)) {
        _selectedIds.remove(resource.id);
      } else {
        _selectedIds.add(resource.id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final selected = widget.section.resources
        .where((resource) => _selectedIds.contains(resource.id))
        .toList();
    if (selected.isEmpty) return;

    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Delete Resources?',
      message:
          'You are about to permanently delete ${selected.length} selected resource(s).',
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _resourceService.deleteResources(selected);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.length} resource(s) deleted')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: widget.access.canAdd && !_selectionMode
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, Routes.addResource),
              icon: const Icon(Icons.add),
              label: const Text('Add Resource'),
            )
          : null,
      body: Stack(
        children: [
          const AppHeroBackground(height: 172),
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
                        icon: Icon(
                          _selectionMode
                              ? Icons.close_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _selectionMode
                            ? () => setState(() => _selectedIds.clear())
                            : () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectionMode
                                  ? '${_selectedIds.length} selected'
                                  : widget.section.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.section.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectionMode)
                        IconButton(
                          onPressed: _deleting ? null : _deleteSelected,
                          icon: _deleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.link_rounded),
                          label: const Text('Copy links'),
                          onPressed: widget.section.resources.isEmpty
                              ? null
                              : () => copyTextWithMessage(
                                  context: context,
                                  text: widget.section.linksText,
                                  message:
                                      '${widget.section.name} links copied',
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Share links'),
                          onPressed: widget.section.resources.isEmpty
                              ? null
                              : () => shareResourceLinks(
                                  text: widget.section.linksText,
                                  subject:
                                      '${widget.section.subject} ${widget.section.name} resources',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: widget.section.resources.isEmpty
                      ? const Center(
                          child: Text('No resources in this segregation yet'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          itemCount: widget.section.resources.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final resource = widget.section.resources[index];
                            return _ResourceCard(
                              resource: resource,
                              selected: _selectedIds.contains(resource.id),
                              selectionMode: _selectionMode,
                              canManage: widget.access.canManage,
                              onTap: () {
                                if (_selectionMode) {
                                  _toggleSelection(resource);
                                  return;
                                }
                                Navigator.pushNamed(
                                  context,
                                  Routes.resourceDetail,
                                  arguments: resource,
                                );
                              },
                              onLongPress: widget.access.canManage
                                  ? () => _toggleSelection(resource)
                                  : null,
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

class _ResourceCard extends StatelessWidget {
  final ResourceModel resource;
  final bool selected;
  final bool selectionMode;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ResourceCard({
    required this.resource,
    required this.selected,
    required this.selectionMode,
    required this.canManage,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: selected ? Border.all(color: UIColors.primary, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectionMode) ...[
                  Checkbox(value: selected, onChanged: (_) => onTap()),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (resource.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          resource.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: UIColors.textMuted),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Preview'),
                              onPressed: () => previewResourceFile(
                                fileUrl: resource.fileUrl,
                                fileType: resource.fileType,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download'),
                              onPressed: () =>
                                  downloadResourceFile(resource.fileUrl),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!selectionMode)
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
