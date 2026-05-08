import 'package:flutter/material.dart';
import 'package:instru_connect/core/widgets/animated_splash_loader.dart';
import 'package:instru_connect/features/legal/legal_content.dart';
import 'package:instru_connect/features/legal/services/legal_acceptance_service.dart';

class TermsAcceptanceGate extends StatefulWidget {
  final Widget child;

  const TermsAcceptanceGate({super.key, required this.child});

  @override
  State<TermsAcceptanceGate> createState() => _TermsAcceptanceGateState();
}

class _TermsAcceptanceGateState extends State<TermsAcceptanceGate> {
  final _legalAcceptanceService = LegalAcceptanceService();

  bool? _hasAcceptedCurrentVersion;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    _loadAcceptanceState();
  }

  Future<void> _loadAcceptanceState() async {
    final hasAccepted =
        await _legalAcceptanceService.hasAcceptedCurrentVersion();

    if (!mounted) return;

    setState(() => _hasAcceptedCurrentVersion = hasAccepted);

    if (hasAccepted) {
      await _legalAcceptanceService.syncAcceptanceAuditIfNeeded();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAcceptanceDialog();
      }
    });
  }

  Future<void> _showAcceptanceDialog() async {
    if (_dialogVisible) return;
    _dialogVisible = true;

    final accepted = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Terms and Privacy Policy',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      pageBuilder: (context, _, __) => PopScope(
        canPop: false,
        child: _TermsAcceptanceDialog(
          onAccept: _legalAcceptanceService.acceptCurrentVersion,
        ),
      ),
    );

    _dialogVisible = false;

    if (accepted == true && mounted) {
      setState(() => _hasAcceptedCurrentVersion = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAcceptedCurrentVersion == true) {
      return widget.child;
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedSplashLoader(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsAcceptanceDialog extends StatefulWidget {
  final Future<void> Function() onAccept;

  const _TermsAcceptanceDialog({required this.onAccept});

  @override
  State<_TermsAcceptanceDialog> createState() => _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends State<_TermsAcceptanceDialog> {
  bool _submitting = false;

  Future<void> _handleAccept() async {
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await widget.onAccept();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save acceptance. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Review our policies',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please review and accept the Terms and Conditions and Privacy Policy to continue using the app.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 320),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PolicyPreview(
                              title: LegalContent.termsTitle,
                              body: LegalContent.termsSummary,
                            ),
                            const SizedBox(height: 18),
                            Divider(
                              color: theme.dividerColor.withValues(
                                alpha: 0.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _PolicyPreview(
                              title: LegalContent.privacyTitle,
                              body: LegalContent.privacySummary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _handleAccept,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('I Accept'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyPreview extends StatelessWidget {
  final String title;
  final String body;

  const _PolicyPreview({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
        ),
      ],
    );
  }
}
