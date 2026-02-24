import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/profile/model/profile_model.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';
import 'package:instru_connect/core/services/theme_controller.dart';
import '../../../config/theme/ui_colors.dart';
import '../services/profile_service.dart';
import 'achievement_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool forceCompletion;
  final String? completionRoute;

  const ProfileScreen({
    super.key,
    this.forceCompletion = false,
    this.completionRoute,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();

  final _misController = TextEditingController();
  final _deptController = TextEditingController();
  final _coCurricularController = TextEditingController();
  final _contactController = TextEditingController();
  final _parentContactController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  late ProfileModel profile;
  String? _batchName;
  String _role = '';

  bool get _isStudentOrCr => _role == 'student' || _role == 'cr';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    _role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();

    await _service.createProfileIfNotExists(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
    );

    profile = await _service.fetchProfile(user.uid);

    _misController.text = profile.misNo ?? '';
    _deptController.text = profile.department ?? '';
    _coCurricularController.text = profile.coCurricular ?? '';
    _contactController.text = profile.contactNo ?? '';
    _parentContactController.text = profile.parentContactNo ?? '';

    // ================= FETCH REAL BATCH NAME =================
    final fallbackBatchId = (userDoc.data()?['batchId'] ?? '').toString();
    final selectedBatchId = (profile.batchId ?? '').trim().isNotEmpty
        ? profile.batchId!
        : fallbackBatchId;

    if (selectedBatchId.isNotEmpty) {
      final batchDoc = await FirebaseFirestore.instance
          .collection('batches')
          .doc(selectedBatchId)
          .get();

      if (batchDoc.exists) {
        _batchName = batchDoc.data()?['name'];
      } else {
        _batchName = null;
      }
    } else {
      _batchName = null;
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    await _service.updateProfile(
      uid: profile.uid,
      misNo: _isStudentOrCr ? _misController.text.trim() : null,
      department: _deptController.text.trim(),
      coCurricular: _coCurricularController.text.trim(),
      contactNo: _contactController.text.trim(),
      parentContactNo: _isStudentOrCr
          ? _parentContactController.text.trim()
          : null,
    );

    setState(() => _saving = false);

    if (mounted) {
      if (widget.forceCompletion && widget.completionRoute != null) {
        Navigator.pushReplacementNamed(context, widget.completionRoute!);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ================= GRADIENT HEADER =================
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= APP BAR =================
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                          onPressed: widget.forceCompletion
                              ? null
                              : () => Navigator.pop(context),
                        ),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ================= PROFILE HEADER =================
                    _WhiteCard(
                      child: _ProfileHeader(
                        name: profile.name,
                        email: profile.email,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ================= BASIC INFO =================
                    const _SectionTitle('Basic Information'),
                    const SizedBox(height: 12),

                    _WhiteCard(
                      child: Column(
                        children: [
                          _basicInfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Name',
                            value: profile.name,
                          ),
                          _basicInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: profile.email,
                          ),
                          _basicInfoRow(
                            icon: Icons.groups_2_outlined,
                            label: 'Batch',
                            value: _batchName ?? '-',
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ================= PERSONAL DETAILS =================
                    const _SectionTitle('Personal Details'),
                    const SizedBox(height: 12),

                    _WhiteCard(
                      child: Column(
                        children: [
                          if (_isStudentOrCr)
                            _editableField(
                              'MIS No',
                              _misController,
                              required: true,
                            ),
                          _editableField(
                            'Department',
                            _deptController,
                            required: true,
                          ),
                          _editableField(
                            'Co-curricular Activities',
                            _coCurricularController,
                            maxLines: 3,
                            required: true,
                          ),
                          _editableField(
                            'Contact No',
                            _contactController,
                            required: true,
                          ),
                          if (_isStudentOrCr)
                            _editableField(
                              'Parent Contact No',
                              _parentContactController,
                              required: true,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ================= ACHIEVEMENTS =================
                    if (!widget.forceCompletion) ...[
                      const _SectionTitle('Achievements'),
                      const SizedBox(height: 12),

                      _WhiteCard(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: UIColors.secondaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_outlined,
                              color: Colors.white,
                            ),
                          ),
                          title: const Text('Achievements'),
                          subtitle: const Text(
                            'Upload and manage your achievements',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AchievementsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ================= SAVE BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.forceCompletion
                                    ? 'Continue'
                                    : 'Save Changes',
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (!widget.forceCompletion)
                      _WhiteCard(
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Use darker app appearance'),
                          value: ThemeController.instance.isDarkMode,
                          onChanged: (enabled) {
                            ThemeController.instance.setDarkMode(enabled);
                            setState(() {});
                          },
                        ),
                      ),

                    if (!widget.forceCompletion) const SizedBox(height: 12),

                    // ================= LOGOUT =================
                    if (!widget.forceCompletion)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => showLogoutDialog(context),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Log Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UIColors.error,
                            side: const BorderSide(color: UIColors.error),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= FIELD WIDGETS =================

  Widget _basicInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color;
    final textPrimary = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: UIColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: UIColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) const SizedBox(height: 12),
        if (showDivider) Divider(color: textSecondary?.withValues(alpha: 0.25)),
        if (showDivider) const SizedBox(height: 12),
      ],
    );
  }

  Widget _editableField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (value) {
                if ((value ?? '').trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

// ================= HEADER =================

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;

  const _ProfileHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: UIColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(14),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(email, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ================= WHITE CARD =================

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ================= SECTION TITLE =================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
