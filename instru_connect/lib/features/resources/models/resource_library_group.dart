import 'package:instru_connect/features/resources/models/resource_model.dart';
import 'package:instru_connect/features/resources/models/resource_section_model.dart';

class ResourceSubjectGroup {
  final String subject;
  final Map<String, ResourceSectionGroup> sections;

  ResourceSubjectGroup({required this.subject, required this.sections});

  List<ResourceSectionGroup> get sortedSections {
    return sections.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<ResourceModel> get resources {
    return sortedSections
        .expand((section) => section.resources)
        .toList(growable: false);
  }

  int get resourceCount => resources.length;

  int get sectionCount => sections.length;

  String get linksText {
    final buffer = StringBuffer('$subject resources');
    for (final section in sortedSections) {
      if (section.resources.isEmpty) continue;
      buffer
        ..writeln()
        ..writeln()
        ..writeln('[${section.name}]');
      for (final resource in section.resources) {
        buffer
          ..writeln('${resource.title}:')
          ..writeln(resource.fileUrl);
      }
    }
    return buffer.toString();
  }
}

class ResourceSectionGroup {
  final String subject;
  final String name;
  final List<ResourceModel> resources;

  ResourceSectionGroup({
    required this.subject,
    required this.name,
    List<ResourceModel>? resources,
  }) : resources = resources ?? <ResourceModel>[];

  String get linksText {
    final buffer = StringBuffer('$subject - $name resources');
    for (final resource in resources) {
      buffer
        ..writeln()
        ..writeln('${resource.title}:')
        ..writeln(resource.fileUrl);
    }
    return buffer.toString();
  }
}

List<ResourceSubjectGroup> buildResourceSubjectGroups({
  required List<ResourceModel> resources,
  required List<ResourceSectionModel> sections,
  required bool includeEmptySections,
}) {
  final groups = <String, ResourceSubjectGroup>{};

  ResourceSubjectGroup subjectGroupFor(String subject) {
    final displaySubject = _displayName(subject, 'Uncategorized');
    return groups.putIfAbsent(
      _keyFor(displaySubject),
      () => ResourceSubjectGroup(
        subject: displaySubject,
        sections: <String, ResourceSectionGroup>{},
      ),
    );
  }

  if (includeEmptySections) {
    for (final section in sections) {
      final subject = _displayName(section.subject, 'Uncategorized');
      final sectionName = _displayName(section.name, 'General');
      subjectGroupFor(subject).sections.putIfAbsent(
        _keyFor(sectionName),
        () => ResourceSectionGroup(subject: subject, name: sectionName),
      );
    }
  }

  for (final resource in resources) {
    final subject = _displayName(resource.subject, 'Uncategorized');
    final sectionName = _displayName(resource.section, 'General');
    subjectGroupFor(subject).sections
        .putIfAbsent(
          _keyFor(sectionName),
          () => ResourceSectionGroup(subject: subject, name: sectionName),
        )
        .resources
        .add(resource);
  }

  return groups.values.toList()..sort(
    (a, b) => a.subject.toLowerCase().compareTo(b.subject.toLowerCase()),
  );
}

String _displayName(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _keyFor(String value) => value.trim().toLowerCase();
