import 'package:flutter/material.dart';
import 'package:instru_connect/features/admin/screens/admin_dashboard.dart';
import 'package:instru_connect/features/admin/services/role_switcher.dart';

// IMPORT EXISTING HOME SCREENS
import 'home_student.dart';
import 'home_cr.dart';
import 'home_faculty.dart';
import 'home_staff.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _selectedIndex = 0;

  final List<String> _roles = [
    'Admin',
    'Student',
    'CR',
    'Faculty',
    'Staff',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔑 AppBar ONLY for Admin view
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text('Admin Dashboard'),
            )
          : null,

      body: Stack(
        children: [
          // ===============================
          // HOME PREVIEW AREA
          // ===============================
          IndexedStack(
            index: _selectedIndex,
            children: const [
              AdminDashboardView(),
              HomeStudent(),
              HomeCr(),
              HomeFaculty(),
              HomeStaff(),
            ],
          ),

          // ===============================
          // PREVIEW MODE BANNER
          // ===============================
          // if (_selectedIndex != 0)
          //   Positioned(
          //     top: MediaQuery.of(context).padding.top + 8,
          //     left: 16,
          //     right: 16,
          //     child: _PreviewBanner(role: _roles[_selectedIndex]),
          //   ),
        ],
      ),

      // ===============================
      // FLOATING ROLE SWITCHER (ALWAYS VISIBLE)
      // ===============================
      floatingActionButton: RoleSwitcher(
        roles: _roles,
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}



// =======================================================
// FLOATING ROLE SWITCHER
// =======================================================


// =======================================================
// PREVIEW MODE BANNER
// =======================================================

// class _PreviewBanner extends StatelessWidget {
//   final String role;

//   const _PreviewBanner({required this.role});

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       elevation: 4,
//       borderRadius: BorderRadius.circular(12),
//       color: Colors.black.withOpacity(0.75),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//         child: Row(
//           children: [
//             const Icon(Icons.visibility, color: Colors.white, size: 18),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Previewing as $role',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).findAncestorStateOfType<_HomeAdminState>()!
//                     .setState(() {
//                   Navigator.of(context)
//                       .findAncestorStateOfType<_HomeAdminState>()!
//                       ._selectedIndex = 0;
//                 });
//               },
//               child: const Text(
//                 'EXIT',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }