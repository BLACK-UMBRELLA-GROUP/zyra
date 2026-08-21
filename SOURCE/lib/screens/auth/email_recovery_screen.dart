import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/zyra_auth.dart';
import '../../services/zyra_session_router.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';

typedef RecoveryCodeSender = Future<ZyraAuthResult> Function(String email);
typedef RecoveryCodeVerifier =
    Future<ZyraAuthResult> Function({
      required String email,
      required String code,
    });

class EmailRecoveryScreen extends StatefulWidget {
  final RecoveryCodeSender? sendCode;
  final RecoveryCodeVerifier? verifyCode;
  final Future<void> Function()? onRecovered;

  const EmailRecoveryScreen({
    super.key,
    this.sendCode,
    this.verifyCode,
    this.onRecovered,
  });

  @override
  State<EmailRecoveryScreen> createState() => _EmailRecoveryScreenState();
}

class _EmailRecoveryScreenState extends State<EmailRecoveryScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String _email = '';

  RecoveryCodeSender get _send =>
      widget.sendCode ?? ZyraAuth.sendRecoverySignInCode;
  RecoveryCodeVerifier get _verify =>
      widget.verifyCode ?? ZyraAuth.verifyRecoverySignInCode;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!ZyraAuth.isValidEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _send(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.outcome == ZyraAuthOutcome.success) {
        _email = email;
        _codeSent = true;
        _codeController.clear();
      } else if (result.outcome == ZyraAuthOutcome.error) {
        _error = result.errorMessage;
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the six-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _verify(email: _email, code: code);
    if (!mounted) return;
    if (result.outcome == ZyraAuthOutcome.error) {
      setState(() {
        _busy = false;
        _error = result.errorMessage;
      });
      return;
    }
    if (result.outcome != ZyraAuthOutcome.success) {
      setState(() => _busy = false);
      return;
    }

    if (widget.onRecovered != null) {
      await widget.onRecovered!();
      return;
    }
    final home = await ZyraSessionRouter.resolveHome();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => home),
      (route) => false,
    );
  }

  void _changeEmail() {
    setState(() {
      _codeSent = false;
      _busy = false;
      _error = null;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Account recovery', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(25, 44, 25, 60),
            children: [
              Icon(
                _codeSent
                    ? Icons.mark_email_read_outlined
                    : Icons.lock_open_outlined,
                size: 38,
                color: ZyraColors.unlockText,
              ),
              const SizedBox(height: 20),
              Text(
                _codeSent ? 'Check your email.' : 'Use your recovery email.',
                textAlign: TextAlign.center,
                style: ZyraText.heading(size: 27),
              ),
              const SizedBox(height: 10),
              Text(
                _codeSent
                    ? 'If $_email is linked to a ZYRA account, a six-digit code is on its way.'
                    : 'Enter the verified recovery address you added in Settings. No password is needed.',
                textAlign: TextAlign.center,
                style: ZyraText.body(size: 13.5),
              ),
              const SizedBox(height: 30),
              if (!_codeSent)
                _RecoveryField(
                  key: const ValueKey('recovery_signin_email'),
                  controller: _emailController,
                  label: 'Recovery email',
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _busy ? null : _sendCode(),
                )
              else
                _RecoveryField(
                  key: const ValueKey('recovery_signin_code'),
                  controller: _codeController,
                  label: 'Six-digit code',
                  keyboardType: TextInputType.number,
                  inputFormatters: const [_RecoverySixDigitFormatter()],
                  onSubmitted: (_) => _busy ? null : _verifyCode(),
                ),
              if (_error != null) ...[
                const SizedBox(height: 15),
                ZyraErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  key: ValueKey(
                    _codeSent
                        ? 'recovery_signin_verify'
                        : 'recovery_signin_send',
                  ),
                  onPressed: _busy
                      ? null
                      : (_codeSent ? _verifyCode : _sendCode),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 1.8),
                        )
                      : Text(
                          _codeSent ? 'Continue' : 'Send code',
                          style: ZyraText.button(size: 14),
                        ),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 11),
                TextButton(
                  onPressed: _busy ? null : _sendCode,
                  child: Text(
                    'Send a new code',
                    style: ZyraText.subtext(size: 12.5),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _changeEmail,
                  child: Text(
                    'Use a different email',
                    style: ZyraText.subtext(size: 12.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoverySixDigitFormatter extends TextInputFormatter {
  const _RecoverySixDigitFormatter();

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

class _RecoveryField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  const _RecoveryField({
    super.key,
    required this.controller,
    required this.label,
    required this.keyboardType,
    this.inputFormatters,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.done,
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
