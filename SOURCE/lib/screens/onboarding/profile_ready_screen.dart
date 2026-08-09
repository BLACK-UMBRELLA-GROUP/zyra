// Chapter 5 — Profile Ready. Per Flow Diagram.md: profile preview, ID
// verification prompt, photo check status; goes live automatically once
// both pass, otherwise shows the "Your profile isn't live yet" checklist
// (Seeker Onboarding Summary.md §PROFILE NOT LIVE — END STATE). No real
// backend yet — photo check and ID verification are mocked with short
// delays so the full end-state flow is actually reachable for testing.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/zyra_profile_service.dart';
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

  /// Guards against writing profile_complete more than once — both mock
  /// checks can settle in either order, and _goLiveIfReady is called from
  /// both paths.
  bool _wentLive = false;

  @override
  void initState() {
    super.initState();
    // Mock AI photo check running in the background per spec.
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _photosChecking = false;
        _photosApproved = true;
      });
      _goLiveIfReady();
    });
  }

  /// FIXED 2026-08-01 (audit finding C3). This screen already computed
  /// `_liveReady` and told the user "your profile is live" — but nothing
  /// ever wrote `profile_complete` to the database, so the claim was
  /// false. The row stayed invisible to profiles_select's RLS, their
  /// photos stayed invisible to profile_photos_select, and Browse's
  /// discovery query filtered them out. Every real sign-up was silently
  /// unreachable, forever.
  ///
  /// This is the correct place for the write: the spec (Seeker Onboarding
  /// Summary.md §PROFILE NOT LIVE — END STATE) says the profile "goes
  /// live automatically once both checks pass", so going live is exactly
  /// this condition, not the tap on Continue. A user who leaves via
  /// "Continue in limited mode" is genuinely not live and correctly stays
  /// invisible.
  ///
  /// NOTE for whoever replaces the mocks with real photo moderation and
  /// real ID verification: keep the write here, attached to the same
  /// condition. Do not move it earlier to "make Browse work" — an
  /// unmoderated profile appearing in Browse is a safeguarding failure,
  /// not a convenience.
  Future<void> _goLiveIfReady() async {
    if (_wentLive || !_liveReady) return;
    _wentLive = true;
    final ok = await ZyraProfileService.setProfileComplete(true);
    if (!ok) _wentLive = false; // allow a retry if the other check settles later
  }

  void _startIdVerification() {
    setState(() {
      _idVerifying = true;
      _idFailed = false;
    });
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _idVerifying = false;
        _idVerified = true;
      });
      _goLiveIfReady();
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
