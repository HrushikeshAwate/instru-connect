import 'package:flutter/material.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/features/resources/models/resource_library_group.dart';
import 'package:instru_connect/features/resources/models/resource_screen_access.dart';
import 'package:instru_connect/features/resources/screens/resource_section_resources_screen.dart';
import 'package:instru_connect/features/resources/utils/resource_access_actions.dart';

import '../../../config/theme/ui_colors.dart';

class ResourceSubjectSectionsScreen extends StatelessWidget {
  final ResourceSubjectGroup group;
  final ResourceScreenAccess access;

  const ResourceSubjectSectionsScreen({
    super.key,
    required this.group,
    required this.access,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const AppHeroBackground(height: 172),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  title: group.subject,
                  subtitle: 'Segregations inside this subject',
                  onBack: () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
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
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Share links'),
                          onPressed: group.resourceCount == 0
                              ? null
                              : () => shareResourceLinks(
                                  text: group.linksText,
                                  subject: '${group.subject} resources',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: group.sortedSections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final section = group.sortedSections[index];
                      return _SectionCard(
                        section: section,
                        onOpen: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResourceSectionResourcesScreen(
                                section: section,
                                access: access,
                              ),
                            ),
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
  }
}

class _SectionCard extends StatelessWidget {
  final ResourceSectionGroup section;
  final VoidCallback onOpen;

  const _SectionCard({required this.section, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: UIColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.folder_open_outlined),
        ),
        title: Text(section.name),
        subtitle: Text('${section.resources.length} resource(s)'),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onOpen,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _Header({
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
