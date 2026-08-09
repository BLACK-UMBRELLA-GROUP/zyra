// Path 3 step 4 (WALI SCREEN FLOW): "Guardian generates an invitation for
// their Seeker." The code itself is now real (ZyraWaliLinkService,
// backed by the wali_invites table + accept_wali_invite function) —
// no SMS/email sending backend exists, so delivery is still manual
// copy/share rather than an automated message.

import 'package:flutter/material.dart';
import '../../data/zyra_reference_data.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'wali_home_shell.dart';
import '../../widgets/zyra_loading.dart';

class WaliInviteSeekerScreen extends StatefulWidget {
  const WaliInviteSeekerScreen({super.key});

  @override
  State<WaliInviteSeekerScreen> createState() => _WaliInviteSeekerScreenState();
}

class _WaliInviteSeekerScreenState extends State<WaliInviteSeekerScreen> {
  String? _code;
  bool _generating = false;
  String? _error;

  /// The Guardian's statement about THEMSELVES for this link. Stored code,
  /// never the label.
  ///
  /// ADDED 2026-08-07 — the ownership rule: "The relationship is a statement
  /// about the Guardian, so the Guardian makes it — once per link, at the
  /// point they create that link." In this direction the Guardian is gone by
  /// the time the link exists, so it is captured here and carried on the
  /// invite.
  String? _relationship;
  bool _loadingPrefill = true;

  @override
  void initState() {
    super.initState();
    // The code is NO LONGER generated here. It used to be minted in
    // initState, before the Guardian had been asked anything — which is
    // exactly why this flow could never capture a relationship. The invite
    // now waits until there is something to put on it.
    _loadPrefill();
  }

  /// Blank for a Guardian with no links yet; their last answer otherwise.
  /// Never locked — every invitation is a new link and may be a different
  /// relationship (Father for one Seeker, Uncle for another).
  Future<void> _loadPrefill() async {
    final last = await ZyraWaliLinkService.lastUsedRelationship();
    if (!mounted) return;
    setState(() {
      _relationship = last;
      _loadingPrefill = false;
    });
  }

  Future<void> _generate() async {
    if (_relationship == null) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    final token = await ZyraWaliLinkService.createInvite(relationship: _relationship);
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
                const SizedBox(height: 26),

                // Asked BEFORE the code exists, because the answer travels
                // on the invite.
                if (_code == null && !_loadingPrefill) ...[
                  Text('How are you related to them?',
                      style: ZyraText.body(size: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'They will see this once you are linked.',
                    style: ZyraText.subtext(size: 11.5, color: Colors.white38),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in zyraGuardianRelationships)
                        _RelChip(
                          label: r.name,
                          selected: _relationship == r.code,
                          onTap: () => setState(() => _relationship = r.code),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _relationship == null
                            ? ZyraColors.iconButtonBg
                            : ZyraColors.accentBg,
                        border: Border.all(
                          color: _relationship == null
                              ? ZyraColors.iconButtonBorder
                              : ZyraColors.accentBorder,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: _relationship == null || _generating ? null : _generate,
                          child: Center(
                            child: Text(
                              _generating ? 'Generating…' : 'Create invite code',
                              style: ZyraText.button(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                if (_generating)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: ZyraLoading(),
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

/// A relationship choice. Wrap-flowed rather than a full-width list, because
/// seven options as stacked rows would push the invite code off screen and
/// the code is the point of the page.
class _RelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RelChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ZyraColors.accentBg : ZyraColors.iconButtonBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? ZyraColors.accentBorder : ZyraColors.iconButtonBorder,
              width: selected ? 1 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: ZyraText.subtext(
              size: 13,
              color: Colors.white.withValues(alpha: selected ? 1 : 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
