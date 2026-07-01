import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/core/services/firestore/role_service.dart'
    as firestore_role;
import 'package:instru_connect/features/resources/models/resource_library_group.dart';
import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/models/resource_screen_access.dart';
import 'package:instru_connect/features/resources/models/resource_section_model.dart';
import 'package:instru_connect/features/resources/screens/resource_subject_sections_screen.dart';
import 'package:instru_connect/features/resources/services/resource_service.dart';
import 'package:instru_connect/features/resources/utils/resource_access_actions.dart';
import 'package:instru_connect/features/resources/widgets/empty_resource_view.dart';

import '../../../config/theme/ui_colors.dart';

class ResourceListScreen extends ConsumerStatefulWidget {
  const ResourceListScreen({super.key});

  @override
  ConsumerState<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends ConsumerState<ResourceListScreen> {
  late final ResourceService _resourceService;
  late final firestore_role.RoleService _roleService;
  late final Future<_ResourceAccess> _accessFuture;
  late final Stream<List<ResourceModel>> _resourcesStream;
  late final Stream<List<ResourceSectionModel>> _sectionsStream;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _resourceService = ref.read(resourceServiceProvider);
    _roleService = ref.read(firestoreRoleServiceProvider);
    _accessFuture = _resolveAccess();
    _resourcesStream = _resourceService.streamResources();
    _sectionsStream = _resourceService.streamResourceSections();
  }

  Future<_ResourceAccess> _resolveAccess() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return const _ResourceAccess();

    try {
      final role = await _roleService.fetchUserRole(user.uid);
      final normalizedRole = role.trim().toLowerCase();
      return _ResourceAccess(
        canAdd:
            normalizedRole == AppRoles.cr ||
            normalizedRole == AppRoles.faculty ||
            normalizedRole == AppRoles.admin,
        canManage:
            normalizedRole == AppRoles.faculty ||
            normalizedRole == AppRoles.admin,
      );
    } catch (_) {
      return const _ResourceAccess();
    }
  }

  Future<void> _openAddResource() async {
    await Navigator.pushNamed(context, Routes.addResource);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ResourceSubjectGroup> _filterGroups(List<ResourceSubjectGroup> groups) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return groups;
    return groups.where((group) {
      final subjectMatch = group.subject.toLowerCase().contains(query);
      final resourceMatch = group.resources.any((resource) {
        return resource.title.toLowerCase().contains(query) ||
            resource.description.toLowerCase().contains(query) ||
            resource.section.toLowerCase().contains(query) ||
            resource.fileType.toLowerCase().contains(query);
      });
      return subjectMatch || resourceMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ResourceAccess>(
      future: _accessFuture,
      builder: (context, accessSnapshot) {
        final access = accessSnapshot.data ?? const _ResourceAccess();
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: access.canAdd
              ? FloatingActionButton.extended(
                  onPressed: _openAddResource,
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
                    _ResourcesHeader(
                      title: 'Subjects',
                      subtitle: 'Choose a subject to view its resources',
                      onBack: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: StreamBuilder<List<ResourceModel>>(
                        stream: _resourcesStream,
                        builder: (context, resourceSnapshot) {
                          if (resourceSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (resourceSnapshot.hasError) {
                            return const Center(
                              child: Text('Failed to load resources'),
                            );
                          }

                          final resources =
                              resourceSnapshot.data ?? const <ResourceModel>[];
                          return StreamBuilder<List<ResourceSectionModel>>(
                            stream: _sectionsStream,
                            builder: (context, sectionSnapshot) {
                              final sections =
                                  access.canAdd && !sectionSnapshot.hasError
                                  ? sectionSnapshot.data ??
                                        const <ResourceSectionModel>[]
                                  : const <ResourceSectionModel>[];
                              final subjectGroups = buildResourceSubjectGroups(
                                resources: resources,
                                sections: sections,
                                includeEmptySections: access.canAdd,
                              );
                              final filteredGroups = _filterGroups(
                                subjectGroups,
                              );

                              if (subjectGroups.isEmpty) {
                                return const EmptyResourcesView();
                              }

                              return Column(
                                children: [
                                  _ResourceTools(
                                    controller: _searchController,
                                    visibleCount: filteredGroups.length,
                                    totalCount: subjectGroups.length,
                                    resourceCount: resources.length,
                                    onQueryChanged: (value) =>
                                        setState(() => _query = value),
                                  ),
                                  Expanded(
                                    child: filteredGroups.isEmpty
                                        ? _EmptyFilteredResources(
                                            onClear: () {
                                              _searchController.clear();
                                              setState(() => _query = '');
                                            },
                                          )
                                        : ListView.separated(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              8,
                                              16,
                                              96,
                                            ),
                                            itemCount: filteredGroups.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 10),
                                            itemBuilder: (context, index) {
                                              final subjectGroup =
                                                  filteredGroups[index];
                                              return _SubjectCard(
                                                group: subjectGroup,
                                                onOpen: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ResourceSubjectSectionsScreen(
                                                            group: subjectGroup,
                                                            access: ResourceScreenAccess(
                                                              canAdd:
                                                                  access.canAdd,
                                                              canManage: access
                                                                  .canManage,
                                                            ),
                                                          ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              );
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
      },
    );
  }
}

class _ResourceTools extends StatelessWidget {
  final TextEditingController controller;
  final int visibleCount;
  final int totalCount;
  final int resourceCount;
  final ValueChanged<String> onQueryChanged;

  const _ResourceTools({
    required this.controller,
    required this.visibleCount,
    required this.totalCount,
    required this.resourceCount,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search subjects or resources',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CountPill(
                icon: Icons.menu_book_outlined,
                label: '$visibleCount / $totalCount subjects',
              ),
              const SizedBox(width: 8),
              _CountPill(
                icon: Icons.description_outlined,
                label: '$resourceCount resources',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CountPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: UIColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilteredResources extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyFilteredResources({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No matching resources',
      message: 'Try searching by subject, section, title, or file type.',
      actionLabel: 'Clear',
      onAction: onClear,
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final ResourceSubjectGroup group;
  final VoidCallback onOpen;

  const _SubjectCard({required this.group, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: UIColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.subject,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${group.sectionCount} sections • ${group.resourceCount} resources',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: UIColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: UIColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Copy subject links'),
                        onPressed: group.resourceCount == 0
                            ? null
                            : () => copyTextWithMessage(
                                context: context,
                                text: group.linksText,
                                message: '${group.subject} links copied',
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Share subject links',
                      onPressed: group.resourceCount == 0
                          ? null
                          : () => shareResourceLinks(
                              text: group.linksText,
                              subject: '${group.subject} resources',
                            ),
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourcesHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _ResourcesHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceAccess {
  final bool canAdd;
  final bool canManage;

  const _ResourceAccess({this.canAdd = false, this.canManage = false});
}
