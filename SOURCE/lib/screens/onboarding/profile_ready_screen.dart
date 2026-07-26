// Chapter 5 — Profile Ready. Per Flow Diagram.md: profile preview, ID
// verification prompt, photo check status; goes live automatically once
// both pass, otherwise shows the "Your profile isn't live yet" checklist
// (Seeker Onboarding Summary.md §PROFILE NOT LIVE — END STATE). No real
// backend yet — photo check and ID verification are mocked with short
// delays so the full end-state flow is actually reachable for testing.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../home/home_shell.dart';

class ProfileReadyScreen extends StatefulWidget {
  const ProfileReadyScreen({super.key});

  @override
  State<ProfileReadyScreen> createState() => _ProfileReadyScreenState();
}

class _ProfileReadyScreenState extends State<ProfileReadyScreen> {
  bool _photosChecking = true;
  bool _photosApproved = false;
  bool _idVerifying = false;
  bool _idVerified = false;
  bool _idFailed = false;

  @override
  void initState() {
    super.initState();
    // Mock AI photo check running in the background per spec.
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() {
        _photosChecking = false;
        _photosApproved = true;
      });
    });
  }

  void _startIdVerification() {
    setState(() {
      _idVerifying = true;
      _idFailed = false;
    });
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() {
        _idVerifying = false;
        _idVerified = true;
      });
    });
  }

  /// Test-only affordance so the "verification failed" state (Category 2,
  /// ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md / DR-ZYRA-080)
  /// is actually reachable without a real ID-check backend to fail
  /// against.
  void _simulateFailedCheck() {
    setState(() {
      _idVerifying = false;
      _idVerified = false;
      _idFailed = true;
    });
  }

  bool get _liveReady => _photosApproved && _idVerified;

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your profile is almost ready', style: ZyraText.heading(size: 24)),
                const SizedBox(height: 8),
                Text(
                  'A couple of quick checks, then you can start exploring.',
                  style: ZyraText.subtext(),
                ),
                const SizedBox(height: 32),
                _CheckRow(
                  title: 'Photos',
                  status: _photosChecking
                      ? 'Reviewing your photos — usually within a few hours.'
                      : (_photosApproved ? 'Approved' : 'Needs attention'),
                  loading: _photosChecking,
                  done: _photosApproved,
                ),
                const SizedBox(height: 16),
                _CheckRow(
                  title: 'ID Verification',
                  status: _idVerifying
                      ? 'Verifying…'
                      : (_idVerified ? 'Verified' : (_idFailed ? 'Needs another attempt' : 'Pending — tap to verify')),
                  loading: _idVerifying,
                  done: _idVerified,
                  onTap: (!_idVerified && !_idVerifying) ? _startIdVerification : null,
                ),
                if (_idFailed) ...[
                  const SizedBox(height: 10),
                  ZyraErrorBanner(
                    message: "We couldn't confirm this — you can try again, or continue in limited mode for now.",
                    onRetry: _startIdVerification,
                    onDismiss: () => setState(() => _idFailed = false),
                  ),
                ],
                if (!_idVerified && !_idVerifying && !_idFailed)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: _simulateFailedCheck,
                      child: Text(
                        'Simulate a failed check (test only)',
                        style: ZyraText.subtext(size: 10.5, color: Colors.white38),
                      ),
                    ),
                  ),
                const Spacer(),
                if (_liveReady) ...[
                  Text('You are all set — your profile is live.', style: ZyraText.body(size: 14)),
                  const SizedBox(height: 14),
                  _PillButton(label: 'Start Exploring', onTap: _goToHome),
                ] else ...[
                  Text("Your profile isn't live yet.", style: ZyraText.body(size: 14)),
                  const SizedBox(height: 6),
                  Text(
                    'It will go live automatically once both checks pass. '
                    'You can still explore ZYRA in limited mode while you wait — '
                    'no emails or notifications during this period.',
                    style: ZyraText.subtext(size: 12),
                  ),
                  const SizedBox(height: 14),
                  _PillButton(label: 'Continue in limited mode', onTap: _goToHome),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String title;
  final String status;
  final bool loading;
  final bool done;
  final VoidCallback? onTap;

  const _CheckRow({
    required this.title,
    required this.status,
    required this.loading,
    required this.done,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                  )
                else
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? const Color(0xFF50B478) : Colors.white38,
                    size: 20,
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: ZyraText.body(size: 14)),
                      const SizedBox(height: 2),
                      Text(status, style: ZyraText.subtext(size: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ZyraColors.accentBg,
          border: Border.all(color: ZyraColors.accentBorder, width: 1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onTap,
            child: Center(child: Text(label, style: ZyraText.button())),
          ),
        ),
      ),
    );
  }
}
