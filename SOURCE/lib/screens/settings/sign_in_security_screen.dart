import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/zyra_auth.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';

class SignInSecurityScreen extends StatefulWidget {
  const SignInSecurityScreen({super.key});

  @override
  State<SignInSecurityScreen> createState() => _SignInSecurityScreenState();
}

class _SignInSecurityScreenState extends State<SignInSecurityScreen> {
  String? _busyProvider;
  String? _error;
  String? _notice;

  Future<void> _link(String provider) async {
    setState(() {
      _busyProvider = provider;
      _error = null;
      _notice = null;
    });

    final result = provider == 'apple'
        ? await ZyraAuth.linkAppleIdentity()
        : await ZyraAuth.linkGoogleIdentity();
    if (!mounted) return;

    setState(() {
      _busyProvider = null;
      if (result.outcome == ZyraAuthOutcome.error) {
        _error = result.errorMessage;
      } else if (result.outcome == ZyraAuthOutcome.success) {
        _notice = '${provider == 'apple' ? 'Apple' : 'Google'} connected.';
      }
    });
  }

  Future<void> _openRecoveryEmail() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RecoveryEmailSetupScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final providers = ZyraAuth.linkedProviders;
    final hasOAuth = ZyraAuth.hasLinkedOAuth;
    final recoveryEmail = ZyraAuth.recoveryEmail;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Sign-in & security', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
            children: [
              Text('Your ways into ZYRA', style: ZyraText.heading(size: 24)),
              const SizedBox(height: 8),
              Text(
                'Connect a backup before you need it. Every method below opens this same account.',
                style: ZyraText.body(size: 13.5),
              ),
              const SizedBox(height: 22),
              if (_error != null) ...[
                ZyraErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 12),
              ],
              if (_notice != null) ...[
                _NoticeBanner(message: _notice!),
                const SizedBox(height: 12),
              ],
              Text(
                'SIGN-IN METHODS',
                style: ZyraText.chapterLabel(color: Colors.white54),
              ),
              const SizedBox(height: 9),
              _MethodCard(
                icon: Icons.apple,
                title: 'Apple',
                detail: providers.contains('apple')
                    ? ZyraAuth.providerEmail('apple') ?? 'Connected'
                    : 'Not connected',
                connected: providers.contains('apple'),
                busy: _busyProvider == 'apple',
                onAdd: !hasOAuth && providers.contains('email')
                    ? null
                    : () => _link('apple'),
              ),
              const SizedBox(height: 10),
              _MethodCard(
                icon: Icons.g_mobiledata,
                title: 'Google',
                detail: providers.contains('google')
                    ? ZyraAuth.providerEmail('google') ?? 'Connected'
                    : 'Not connected',
                connected: providers.contains('google'),
                busy: _busyProvider == 'google',
                onAdd: !hasOAuth && providers.contains('email')
                    ? null
                    : () => _link('google'),
              ),
              const SizedBox(height: 25),
              Text(
                'RECOVERY EMAIL',
                style: ZyraText.chapterLabel(color: Colors.white54),
              ),
              const SizedBox(height: 9),
              _RecoveryCard(
                email: recoveryEmail,
                enabled: hasOAuth,
                onTap: _openRecoveryEmail,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'ZYRA never creates or stores a password. Recovery uses a one-time code sent only to a verified address.',
                      style: ZyraText.subtext(size: 12),
                    ),
                  ),
                ],
              ),
              if (!hasOAuth) ...[
                const SizedBox(height: 15),
                Text(
                  'Recovery controls become available on an Apple or Google account. This test account remains separate.',
                  style: ZyraText.subtext(size: 11.5, color: Colors.white38),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RecoveryEmailSetupScreen extends StatefulWidget {
  const RecoveryEmailSetupScreen({super.key});

  @override
  State<RecoveryEmailSetupScreen> createState() =>
      _RecoveryEmailSetupScreenState();
}

enum _RecoverySetupStep { email, newEmailCode, currentEmailCode, complete }

class _RecoveryEmailSetupScreenState extends State<RecoveryEmailSetupScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final String _currentEmail = ZyraAuth.currentUser?.email ?? '';
  _RecoverySetupStep _step = _RecoverySetupStep.email;
  bool _busy = false;
  String? _error;
  String _newEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!ZyraAuth.isValidEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ZyraAuth.requestRecoveryEmail(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.outcome == ZyraAuthOutcome.success) {
        _newEmail = email;
        _codeController.clear();
        _step = _RecoverySetupStep.newEmailCode;
      } else if (result.outcome == ZyraAuthOutcome.error) {
        _error = result.errorMessage;
      }
    });
  }

  Future<void> _verifyNewEmail() async {
    final result = await _verifyCode(_newEmail);
    if (!mounted || result.outcome != ZyraAuthOutcome.success) return;

    final complete = await ZyraAuth.isRecoveryEmailVerified(_newEmail);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeController.clear();
      _step = complete
          ? _RecoverySetupStep.complete
          : _RecoverySetupStep.currentEmailCode;
    });
  }

  Future<void> _verifyCurrentEmail() async {
    final result = await _verifyCode(_currentEmail);
    if (!mounted || result.outcome != ZyraAuthOutcome.success) return;

    final complete = await ZyraAuth.isRecoveryEmailVerified(_newEmail);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (complete) {
        _step = _RecoverySetupStep.complete;
      } else {
        _error =
            "That confirmation didn't complete the change. Request new codes and try again.";
      }
    });
  }

  Future<ZyraAuthResult> _verifyCode(String email) async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the six-digit code.');
      return const ZyraAuthResult.error('Enter the six-digit code.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ZyraAuth.verifyRecoveryEmailCode(
      email: email,
      code: code,
    );
    if (!mounted) return result;
    if (result.outcome == ZyraAuthOutcome.error) {
      setState(() {
        _busy = false;
        _error = result.errorMessage;
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _RecoverySetupStep.email => 'Add recovery email',
      _RecoverySetupStep.newEmailCode => 'Verify your recovery email',
      _RecoverySetupStep.currentEmailCode => 'Confirm it is you',
      _RecoverySetupStep.complete => 'Recovery email added',
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title, style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 70),
            children: [
              if (_step == _RecoverySetupStep.email) ...[
                Text('A safe way back in.', style: ZyraText.heading(size: 27)),
                const SizedBox(height: 9),
                Text(
                  'Use any email you control. If you lose Apple or Google access, ZYRA can send a one-time sign-in code here.',
                  style: ZyraText.body(size: 13.5),
                ),
                const SizedBox(height: 25),
                _SecurityTextField(
                  key: const ValueKey('recovery_setup_email'),
                  controller: _emailController,
                  label: 'Recovery email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _request(),
                ),
                const SizedBox(height: 13),
                Text(
                  'This address is private and is not shown on your profile.',
                  style: ZyraText.subtext(size: 11.5),
                ),
                const SizedBox(height: 25),
                _SecurityActionButton(
                  key: const ValueKey('recovery_setup_send'),
                  label: 'Send verification code',
                  busy: _busy,
                  onTap: _request,
                ),
              ] else if (_step == _RecoverySetupStep.newEmailCode) ...[
                _CodeStep(
                  title: 'Check $_newEmail',
                  description:
                      'Enter the six-digit code sent to your new recovery email.',
                  controller: _codeController,
                  busy: _busy,
                  buttonKey: const ValueKey('recovery_setup_verify_new'),
                  onVerify: _verifyNewEmail,
                ),
              ] else if (_step == _RecoverySetupStep.currentEmailCode) ...[
                _CodeStep(
                  title: 'Now check $_currentEmail',
                  description:
                      'For security, enter the code sent to your current account email too.',
                  controller: _codeController,
                  busy: _busy,
                  buttonKey: const ValueKey('recovery_setup_verify_current'),
                  onVerify: _verifyCurrentEmail,
                ),
              ] else ...[
                const Icon(
                  Icons.verified_user_outlined,
                  size: 48,
                  color: Color(0xFF84D0A8),
                ),
                const SizedBox(height: 18),
                Text(
                  'Your backup is ready.',
                  textAlign: TextAlign.center,
                  style: ZyraText.heading(size: 27),
                ),
                const SizedBox(height: 9),
                Text(
                  'You can now use $_newEmail to request a one-time sign-in code. No password has been created.',
                  textAlign: TextAlign.center,
                  style: ZyraText.body(size: 13.5),
                ),
                const SizedBox(height: 28),
                _SecurityActionButton(
                  label: 'Done',
                  busy: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                ZyraErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final bool connected;
  final bool busy;
  final VoidCallback? onAdd;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.connected,
    required this.busy,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return _SecurityCard(
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 23),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.body(size: 14.5)),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.subtext(size: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (connected)
            const _ConnectedBadge()
          else
            TextButton(
              onPressed: busy ? null : onAdd,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.6),
                    )
                  : Text('Add', style: ZyraText.button(size: 12.5)),
            ),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final String? email;
  final bool enabled;
  final VoidCallback onTap;

  const _RecoveryCard({
    required this.email,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SecurityCard(
      child: Row(
        children: [
          const Icon(Icons.alternate_email, color: Colors.white70, size: 21),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email ?? 'No recovery email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.body(size: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  email == null ? 'One-time codes · no password' : 'Verified',
                  style: ZyraText.subtext(size: 11.5),
                ),
              ],
            ),
          ),
          TextButton(
            key: const ValueKey('manage_recovery_email'),
            onPressed: enabled ? onTap : null,
            child: Text(
              email == null ? 'Add' : 'Change',
              style: ZyraText.button(size: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final Widget child;

  const _SecurityCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.iconButtonBorder),
      ),
      child: child,
    );
  }
}

class _ConnectedBadge extends StatelessWidget {
  const _ConnectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF84D0A8).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFF84D0A8).withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        'Connected',
        style: ZyraText.subtext(size: 10.5, color: const Color(0xFFBCEBD2)),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  final String message;

  const _NoticeBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF84D0A8).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF84D0A8).withValues(alpha: 0.35),
        ),
      ),
      child: Text(message, style: ZyraText.body(size: 12.5)),
    );
  }
}

class _CodeStep extends StatelessWidget {
  final String title;
  final String description;
  final TextEditingController controller;
  final bool busy;
  final Key buttonKey;
  final VoidCallback onVerify;

  const _CodeStep({
    required this.title,
    required this.description,
    required this.controller,
    required this.busy,
    required this.buttonKey,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ZyraText.heading(size: 25)),
        const SizedBox(height: 9),
        Text(description, style: ZyraText.body(size: 13.5)),
        const SizedBox(height: 25),
        _SecurityTextField(
          key: const ValueKey('recovery_setup_code'),
          controller: controller,
          label: 'Six-digit code',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: const [_SixDigitFormatter()],
          onSubmitted: (_) => busy ? null : onVerify(),
        ),
        const SizedBox(height: 24),
        _SecurityActionButton(
          key: buttonKey,
          label: 'Verify code',
          busy: busy,
          onTap: onVerify,
        ),
      ],
    );
  }
}

class _SixDigitFormatter extends TextInputFormatter {
  const _SixDigitFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final value = digits.length > 6 ? digits.substring(0, 6) : digits;
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class _SecurityTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  const _SecurityTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.keyboardType,
    required this.textInputAction,
    this.inputFormatters,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: onSubmitted,
      style: ZyraText.body(size: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ZyraText.subtext(size: 12.5),
        filled: true,
        fillColor: ZyraColors.iconButtonBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ZyraColors.iconButtonBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ZyraColors.primaryAction),
        ),
      ),
    );
  }
}

class _SecurityActionButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;

  const _SecurityActionButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              )
            : Text(label, style: ZyraText.button(size: 14)),
      ),
    );
  }
}
