// Path 3 step 4 (WALI SCREEN FLOW): "Wali generates an invitation for
// their Seeker." The code itself is now real (ZyraWaliLinkService,
// backed by the wali_invites table + accept_wali_invite function) —
// no SMS/email sending backend exists, so delivery is still manual
// copy/share rather than an automated message.

import 'package:flutter/material.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'wali_home_shell.dart';

class WaliInviteSeekerScreen extends StatefulWidget {
  const WaliInviteSeekerScreen({super.key});

  @override
  State<WaliInviteSeekerScreen> createState() => _WaliInviteSeekerScreenState();
}

class _WaliInviteSeekerScreenState extends State<WaliInviteSeekerScreen> {
  String? _code;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    final token = await ZyraWaliLinkService.createInvite();
    if (!mounted) return;
    setState(() {
      _generating = false;
      if (token == null) {
        _error = "Couldn't generate an invite code. Tap to try again.";
      } else {
        _code = token;
      }
    });
  }

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WaliHomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 2026-07-25 fix (DR-ZYRA-101 audit): was hardcoded to
        // backgroundFor(male) — an onboarding-context helper that
        // always returns the flat neutral gradient regardless of
        // variant, and hardcoded male besides. This is a signed-in
        // Wali screen (reached from the Dashboard, which already
        // reads AppState.gender), so it should match its siblings.
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text('Invite your Seeker', style: ZyraText.heading(size: 24)),
                const SizedBox(height: 8),
                Text(
                  "Share this code with the person you're supporting. Once they enter it, "
                  "your accounts link automatically and their journey will appear on your Dashboard.",
                  style: ZyraText.subtext(),
                ),
                const SizedBox(height: 28),
                if (_generating)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: Colors.white54)),
                  )
                else if (_code != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ZyraColors.iconButtonBg,
                      border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(_code!, style: ZyraText.heading(size: 24).copyWith(letterSpacing: 4)),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ZyraErrorBanner(message: _error!, onRetry: _generate),
                ],
                const SizedBox(height: 8),
                Text(
                  "Sharing (SMS, email, WhatsApp) isn't wired up yet in this preview build — copy and send this code however works today.",
                  style: ZyraText.subtext(size: 11, color: Colors.white38),
                ),
                const Spacer(),
                SizedBox(
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
                        onTap: () => _goToDashboard(context),
                        child: Center(child: Text('Done', style: ZyraText.button())),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => _goToDashboard(context),
                    child: Text("I'll invite them later", style: ZyraText.subtext(size: 12.5)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
