import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/features/profile/model/profile_model.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';
import 'package:instru_connect/core/services/session_cache_service.dart';
import 'package:instru_connect/core/services/theme_controller.dart';
import 'package:instru_connect/features/legal/legal_content.dart';
import 'package:instru_connect/features/legal/screens/legal_document_screen.dart';
import '../../../config/theme/ui_colors.dart';
import '../services/profile_service.dart';
import 'achievement_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool forceCompletion;
  final String? completionRoute;
  final String? userId;
  final bool readOnly;

  const ProfileScreen({
    super.key,
    this.forceCompletion = false,
    this.completionRoute,
    this.userId,
    this.readOnly = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();

  bool _loading = true;

  late ProfileModel profile;
  String? _batchName;
  String _role = '';
  bool get _isViewingOwnProfile => widget.userId == null;
  String get _targetUserId =>
      widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
  bool get _isReadOnlyView => widget.readOnly || !_isViewingOwnProfile;

  bool get _isStudentOrCr => _role == 'student' || _role == 'cr';
  bool get _hasCompletedRequiredDetails {
    final hasDepartment = (profile.department ?? '').trim().isNotEmpty;
    final hasContact = (profile.contactNo ?? '').trim().isNotEmpty;
    final hasMis = !_isStudentOrCr || (profile.misNo ?? '').trim().isNotEmpty;
    final hasParentContact =
        !_isStudentOrCr || (profile.parentContactNo ?? '').trim().isNotEmpty;
    return hasDepartment && hasContact && hasMis && hasParentContact;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final targetUserId = _targetUserId;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .get();
    _role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();

    if (_isViewingOwnProfile) {
      await _service.createProfileIfNotExists(
        uid: currentUser.uid,
        name: currentUser.displayName ?? '',
        email: currentUser.email ?? '',
      );
    }

    try {
      profile = await _service.fetchProfile(targetUserId);
    } catch (_) {
      final userData = userDoc.data() ?? <String, dynamic>{};
      profile = ProfileModel(
        uid: targetUserId,
        name: (userData['name'] ?? currentUser.displayName ?? '').toString(),
        email: (userData['email'] ?? currentUser.email ?? '').toString(),
        misNo: null,
        department: null,
        batchId: (userData['batchId'] as String?)?.trim().isNotEmpty == true
            ? userData['batchId'] as String
            : null,
        coCurricular: null,
        contactNo: null,
        parentContactNo: null,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
    }

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

    if (_isViewingOwnProfile) {
      await SessionCacheService.instance.updateProfileCompletion(
        uid: targetUserId,
        profileComplete: _hasCompletedRequiredDetails,
      );
    }

    setState(() => _loading = false);
  }

  Future<void> _openEditDetailsScreen() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProfileDetailsEditScreen(
          profile: profile,
          isStudentOrCr: _isStudentOrCr,
        ),
      ),
    );

    if (updated != true || !mounted) return;

    setState(() => _loading = true);
    await _loadProfile();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  void _continueAfterCompletion() {
    if (widget.completionRoute != null) {
      Navigator.pushReplacementNamed(context, widget.completionRoute!);
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
                      Text(
                        _isReadOnlyView ? 'User Profile' : 'Profile',
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
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Role',
                          value: _displayValue(_role),
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
                  Row(
                    children: [
                      const Expanded(child: _SectionTitle('Personal Details')),
                      if (!_isReadOnlyView)
                        TextButton.icon(
                          onPressed: _openEditDetailsScreen,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(
                            widget.forceCompletion
                                ? 'Complete Details'
                                : 'Edit Details',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _WhiteCard(
                    child: Column(
                      children: [
                        if (_isStudentOrCr)
                          _basicInfoRow(
                            icon: Icons.badge_outlined,
                            label: 'MIS No',
                            value: _displayValue(profile.misNo),
                          ),
                        _basicInfoRow(
                          icon: Icons.account_tree_outlined,
                          label: 'Department',
                          value: _displayValue(profile.department),
                        ),
                        _basicInfoRow(
                          icon: Icons.auto_awesome_outlined,
                          label: 'Co-curricular Activities',
                          value: _displayValue(profile.coCurricular),
                        ),
                        _basicInfoRow(
                          icon: Icons.call_outlined,
                          label: 'Contact No',
                          value: _displayValue(profile.contactNo),
                          showDivider: _isStudentOrCr,
                        ),
                        if (_isStudentOrCr)
                          _basicInfoRow(
                            icon: Icons.family_restroom_outlined,
                            label: 'Parent Contact No',
                            value: _displayValue(profile.parentContactNo),
                            showDivider: false,
                          ),
                        if (!_isStudentOrCr)
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ================= ACHIEVEMENTS =================
                  if (!widget.forceCompletion && !_isReadOnlyView) ...[
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

                  if (!widget.forceCompletion && !_isReadOnlyView) ...[
                    const SizedBox(height: 32),
                    const _SectionTitle('Legal'),
                    const SizedBox(height: 12),
                    _WhiteCard(
                      child: Column(
                        children: [
                          _navigationTile(
                            icon: Icons.description_outlined,
                            title: LegalContent.termsTitle,
                            subtitle:
                                'Read the full terms and conditions',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LegalDocumentScreen(
                                    title: LegalContent.termsTitle,
                                    content: LegalContent.termsFullText,
                                  ),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 24,
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.25),
                          ),
                          _navigationTile(
                            icon: Icons.privacy_tip_outlined,
                            title: LegalContent.privacyTitle,
                            subtitle: 'Read the full privacy policy',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LegalDocumentScreen(
                                    title: LegalContent.privacyTitle,
                                    content: LegalContent.privacyFullText,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  if (widget.forceCompletion)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _hasCompletedRequiredDetails
                            ? _continueAfterCompletion
                            : null,
                        child: const Text('Continue'),
                      ),
                    ),

                  if (widget.forceCompletion) const SizedBox(height: 12),

                  if (widget.forceCompletion && !_hasCompletedRequiredDetails)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Complete the required personal details before continuing.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),

                  if (!widget.forceCompletion && !_isReadOnlyView)
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

                  if (!widget.forceCompletion && !_isReadOnlyView)
                    const SizedBox(height: 12),

                  // ================= LOGOUT =================
                  if (!widget.forceCompletion && !_isReadOnlyView)
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

  String _displayValue(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  Widget _navigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: UIColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: UIColors.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ProfileDetailsEditScreen extends StatefulWidget {
  final ProfileModel profile;
  final bool isStudentOrCr;

  const _ProfileDetailsEditScreen({
    required this.profile,
    required this.isStudentOrCr,
  });

  @override
  State<_ProfileDetailsEditScreen> createState() =>
      _ProfileDetailsEditScreenState();
}

class _ProfileDetailsEditScreenState extends State<_ProfileDetailsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProfileService();

  late final TextEditingController _misController;
  late final TextEditingController _deptController;
  late final TextEditingController _coCurricularController;
  late final TextEditingController _contactController;
  late final TextEditingController _parentContactController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _misController = TextEditingController(text: widget.profile.misNo ?? '');
    _deptController = TextEditingController(
      text: widget.profile.department ?? '',
    );
    _coCurricularController = TextEditingController(
      text: widget.profile.coCurricular ?? '',
    );
    _contactController = TextEditingController(
      text: widget.profile.contactNo ?? '',
    );
    _parentContactController = TextEditingController(
      text: widget.profile.parentContactNo ?? '',
    );
  }

  @override
  void dispose() {
    _misController.dispose();
    _deptController.dispose();
    _coCurricularController.dispose();
    _contactController.dispose();
    _parentContactController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    await _service.updateProfile(
      uid: widget.profile.uid,
      misNo: widget.isStudentOrCr ? _misController.text.trim() : null,
      department: _deptController.text.trim(),
      coCurricular: _coCurricularController.text.trim(),
      contactNo: _contactController.text.trim(),
      parentContactNo: widget.isStudentOrCr
          ? _parentContactController.text.trim()
          : null,
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WhiteCard(
                  child: Column(
                    children: [
                      if (widget.isStudentOrCr)
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
                      ),
                      _editableField(
                        'Contact No',
                        _contactController,
                        required: true,
                      ),
                      if (widget.isStudentOrCr)
                        _editableField(
                          'Parent Contact No',
                          _parentContactController,
                          required: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveDetails,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
