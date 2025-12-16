import 'package:flutter/material.dart';

class RoleSwitcher extends StatelessWidget {
  final List<String> roles;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const RoleSwitcher({super.key, 
    required this.roles,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.swap_horiz),
      label: const Text('Switch'),
      onPressed: () async {
        final selected = await showModalBottomSheet<int>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) {
            return ListView(
              shrinkWrap: true,
              children: List.generate(
                roles.length,
                (index) => ListTile(
                  leading: Icon(
                    index == 0 ? Icons.admin_panel_settings : Icons.person,
                  ),
                  title: Text(roles[index]),
                  trailing: index == selectedIndex
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, index),
                ),
              ),
            );
          },
        );

        if (selected != null) {
          onSelected(selected);
        }
      },
    );
  }
}
