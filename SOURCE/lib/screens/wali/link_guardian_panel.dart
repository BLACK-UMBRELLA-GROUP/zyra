// The two ways to link a Guardian: generate a code, or enter theirs.
//
// EXTRACTED 2026-08-03 from seeker_wali_tab.dart, which had it inline.
//
// Founder: "on the Guardian page, if there is no Guardian then I want it
// to show this. But if there is one Guardian or more, then below the last
// Guardian I want a plus symbol, and a user can click on that and it can
// take them to a page which shows picture 1 without the 'no Guardian is
// linked' text."
//
// So the same two controls appear in two places:
//
//   NO GUARDIAN   inline on the tab, under the empty state — there is
//                 nothing else on that screen, and burying the only
//                 available action behind a tap would be perverse.
//   ONE OR MORE   behind a + tile, on its own screen. The tab's job
//                 becomes "who are my Guardians", and an invite form
//                 sitting permanently below them competes with that.
//
// Extracted rather than duplicated: `_generateInvite` writes a real
// `wali_invites` row with an 8-character token and a 7-day expiry. Two
// copies of that would be two things to keep in step.

import 'package:flutter/material.dart';

import '../../services/zyra_wali_link_service.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'accept_wali_invite_screen.dart';

class LinkGuardianPanel extends StatefulWidget {
  /// Called after a code is successfully accepted, so the caller can
  /// refresh its list.
  final VoidCallback onLinked;

  const LinkGuardianPanel({super.key, required this.onLinked});

  @override
  State<LinkGuardianPanel> createState() => _LinkGuardianPanelState();
}

class _LinkGuardianPanelState extends State<LinkGuardianPanel> {
  String? _generatedCode;
  bool _generating = false;
  String? _error;

  /// Optional, private, and the sender's own reminder — "Dad", "Uncle
  /// Ibrahim". ADDED 2026-08-06.
  ///
  /// An invite has no recipient: the flow is "generate a code, share it
  /// however you like", so `wali_invites` knows a token and who sent it and
  /// nothing more. Without this, Pending Invitations could only ever list
  /// eight-character codes, which does not read like a family network.
  ///
  /// It is NOT an identity claim. Whoever redeems the code becomes the
  /// Guardian regardless of what this says, and it is never shown to them —
  /// `wali_invites_select` is scoped to the sender and
  /// `preview_wali_invite` cannot return it.
  final TextEditingController _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _generateInvite() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    final token = await ZyraWaliLinkService.createInvite(label: _labelController.text);
    if (!mounted) return;
    setState(() {
      _generating = false;
      if (token == null) {
        _error = "Couldn't generate a code. Tap to try again.";
      } else {
        _generatedCode = token;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INVITE A GUARDIAN', style: ZyraText.chapterLabel(color: Colors.white54)),
        const SizedBox(height: 10),
        if (_generatedCode == null) ...[
          TextField(
            controller: _labelController,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            style: ZyraText.body(size: 15, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Who is this for? (optional)',
              hintStyle: ZyraText.subtext(size: 14),
              helperText: 'Just for you — they never see this.',
              helperStyle: ZyraText.subtext(size: 11, color: Colors.white38),
              counterText: '',
              filled: true,
              fillColor: ZyraColors.iconButtonBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ActionButton(
            label: _generating ? 'Generating…' : 'Generate Invite Code',
            onTap: _generating ? null : _generateInvite,
          ),
        ]
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ZyraColors.iconButtonBg,
              border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Share this code with your Guardian:', style: ZyraText.subtext(size: 12)),
                const SizedBox(height: 8),
                Text(_generatedCode!, style: ZyraText.heading(size: 22).copyWith(letterSpacing: 4)),
                const SizedBox(height: 8),
                Text(
                  "Sharing (SMS, email, WhatsApp) isn't wired up yet in this "
                  'preview build — copy and send this code however works today.',
                  style: ZyraText.subtext(size: 11, color: Colors.white38),
                ),
                const SizedBox(height: 4),
                Text(
                  'This code expires 7 days from now.',
                  style: ZyraText.subtext(size: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          ZyraErrorBanner(
            message: _error!,
            onRetry: _generateInvite,
            onDismiss: () => setState(() => _error = null),
          ),
        ],
        const SizedBox(height: 28),
        Text('HAVE A CODE?', style: ZyraText.chapterLabel(color: Colors.white54)),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Enter Invite Code',
          outlined: true,
          onTap: () async {
            final linked = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AcceptWaliInviteScreen()),
            );
            if (linked == true) widget.onLinked();
          },
        ),
      ],
    );
  }
}

/// Pushed from the + tile once a Seeker already has at least one Guardian.
///
/// Titled "Link another Guardian" rather than "Add another Guardian"
/// (Founder: "maybe something like add another guardian but you word it
/// better"). Two reasons for the verb: the app's own vocabulary is
/// linking — the table is `wali_links`, the copy elsewhere says "linked
/// Guardian" — and "add" implies the Seeker can do it alone, when in fact
/// the other person has to accept a code. "Link" carries the two-sidedness.
class LinkGuardianScreen extends StatelessWidget {
  final VoidCallback onLinked;
  final String? gender;

  const LinkGuardianScreen({super.key, required this.onLinked, this.gender});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Link another Guardian', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(gender)),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 40),
            children: [
              // The tab's empty state explains what a Guardian is. Here
              // the Seeker already has one, so the only open question is
              // what an ADDITIONAL Guardian gets — which is the same
              // sentence shown above the Additional list on the tab.
              Text(
                'Additional Guardians can follow your Journey. Only your '
                'Main Guardian is asked to act on it.',
                style: ZyraText.subtext(size: 12.5),
              ),
              const SizedBox(height: 24),
              LinkGuardianPanel(onLinked: () {
                onLinked();
                Navigator.of(context).pop();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Moved here with the panel it belongs to, byte-for-byte as it was in
/// seeker_wali_tab.dart. Rewriting it from memory would have silently
/// restyled both buttons — this is a move, not a redesign.
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  const _ActionButton({required this.label, this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : ZyraColors.accentBg,
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
