// Report / block a specific person — 2026-08-01 (Founder request).
//
// Replaces the old "Report a Problem" row, which opened the generic Help
// & Support screen: no subject, no reason, nowhere for a report to go.
//
// Structure follows Muzz's reason picker (MUZZ_TEARDOWN_CURRENT_VERSION_
// V1.md §1.3 — reviewed 2026-08-01) with three deliberate differences:
//
//   1. WE SHOW WHO IS BEING REPORTED. Muzz's sheet doesn't, and reporting
//      the wrong person is a real harm — especially reached by a hidden
//      long-press where the user may not be certain which card is under
//      their finger.
//   2. "I don't want to see this person" is visually separated as a
//      BLOCK, not a report, and says so. Muzz lists it as reason #1 among
//      the reports. Same good instinct — most people reaching for
//      "report" just want the person gone — but presenting it as a report
//      makes the user think they have accused someone when they haven't.
//   3. No "intentional false reporting will result in your account being
//      suspended" footer. Muzz leads the moment of reporting with a
//      threat aimed at the reporter. The people most deterred by that are
//      the uncertain and the frightened — exactly the reports we most
//      need. Deterring bad-faith reports is a moderation problem, not a
//      copy problem.
//
// Blocking is enforced in profiles_select's RLS, so it applies everywhere
// at once rather than only on the screen it was triggered from.

import 'package:flutter/material.dart';
import '../services/zyra_report_service.dart';
import '../state/app_state.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// Returns true if the user reported or blocked (so the caller can
/// advance past this profile), false/null if they backed out.
/// CHANGED 2026-08-01 (Founder: "when I click on report user there's one
/// animation and when I click Help and Support it's a different animation.
/// Keep them consistent — both copying the Help and Support style").
///
/// Was showModalBottomSheet: the sheet slid UP from the bottom while Help
/// pushed in from the RIGHT. Both sat behind the same two rows of the same
/// menu, so the menu appeared to lead to two different kinds of place.
///
/// Now a pushed route, matching HelpSupportScreen exactly — same
/// MaterialPageRoute, same transparent AppBar over a gender gradient, same
/// back arrow. The function name is kept so the three call sites do not
/// churn; the return contract is unchanged (true = reported or blocked).
///
/// This also resolves something flagged the same day: the Help/Report menu
/// became a centred glass card, and a centred card opening a bottom sheet
/// was the last inconsistency left in that flow.
Future<bool?> showReportProfileSheet(
  BuildContext context, {
  required String profileId,
  required String firstName,
  ZyraReportSource source = ZyraReportSource.browse,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => _ReportProfileSheet(
        profileId: profileId,
        firstName: firstName,
        source: source,
      ),
    ),
  );
}

class _ReportProfileSheet extends StatefulWidget {
  final String profileId;
  final String firstName;
  final ZyraReportSource source;

  const _ReportProfileSheet({
    required this.profileId,
    required this.firstName,
    required this.source,
  });

  @override
  State<_ReportProfileSheet> createState() => _ReportProfileSheetState();
}

class _ReportProfileSheetState extends State<_ReportProfileSheet> {
  ZyraReportReason? _selected;
  bool _submitting = false;
  String? _error;

  Future<void> _blockOnly() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await ZyraReportService.block(widget.profileId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = "That didn't go through. Please try again.";
    });
  }

  Future<void> _submitReport() async {
    final reason = _selected;
    if (reason == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await ZyraReportService.reportAndBlock(
      reportedId: widget.profileId,
      reason: reason,
      source: widget.source,
      // A Guardian is not blocked by reporting them. Removing a Guardian is
      // a separate, deliberate action on their detail page — see the note
      // on ZyraReportService.reportAndBlock.
      alsoBlock: widget.source != ZyraReportSource.guardian,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    // Deliberately NOT silent. A report that vanishes without telling the
    // user is the worst outcome this feature can produce.
    setState(() {
      _submitting = false;
      _error = "We couldn't send that report. Please try again — nothing has been sent yet.";
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIXED 2026-08-01 (Founder: "look at the bottom of the picture,
    // it's still the browse page then it's purple"). SafeArea was
    // WRAPPING the coloured Container, so the sheet's surface stopped
    // above the home-indicator inset and the Browse photo showed through
    // underneath it as a strip. Moving SafeArea INSIDE means the colour
    // runs to the physical bottom edge while the content still clears
    // the home indicator.
    // NOW A FULL SCREEN, 2026-08-01. Structure copied from
    // HelpSupportScreen so the two destinations behind the long-press menu
    // are the same kind of place: transparent AppBar over the ratified
    // gender gradient, body extended behind it, back arrow in the corner.
    //
    // SafeArea's top inset covers the status bar only, not the toolbar, so
    // content extending behind the AppBar needs both — same calculation as
    // HelpSupportScreen, for the same reason.
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Report', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      // FIXED 2026-08-03 (Founder: "at the bottom there's a pink line —
      // that shouldn't be there").
      //
      // `SingleChildScrollView` sizes itself to its CONTENT, not to the
      // viewport. So this Container — which has only a decoration and a
      // child — shrank to the content height too, and whatever was left
      // below it showed the Scaffold's own background.
      //
      // That background is Rose Pink for a female Seeker, because
      // main.dart sets scaffoldBackgroundColor to the gender gradient's
      // FIRST stop. Which is a change I made earlier the same day to kill
      // the purple-to-pink launch flash — correct there, and it turned a
      // previously-invisible seam into a bright pink band here.
      //
      // Fixed at the cause: the gradient now fills the viewport whatever
      // the content height. Left as-is, every future screen built on
      // SingleChildScrollView would inherit the same band.
      //
      // Not fixed by changing scaffoldBackgroundColor to the gradient's
      // last stop — that would hide gaps at the bottom while reintroducing
      // a flash at the top on cold start, which is the worse trade.
      body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            gradient: ZyraColors.genderGradient(AppState.instance.gender),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(0, topInset + 4, 0, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // The drag handle went with the bottom sheet — a pushed
                // screen is not draggable, so a handle would be an
                // affordance that does nothing.

                // WHO. Muzz omits this; it matters most on Browse, where
                // this sheet is reached by a hidden long-press and the
                // user may not be sure which card they were on.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      Text('Report ${widget.firstName}', style: ZyraText.heading(size: 17), textAlign: TextAlign.center),
                      const SizedBox(height: 5),
                      Text(
                        "They won't be told, and they won't see you again.",
                        style: ZyraText.subtext(size: 12.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final reason in ZyraReportReason.values)
                        _ReasonTile(
                          reason: reason,
                          selected: _selected == reason,
                          enabled: !_submitting,
                          onTap: () => setState(() => _selected = reason),
                        ),

                      // HIDDEN for Guardians, 2026-08-06. Blocking your own
                      // Guardian is not the action anyone wants here — it
                      // leaves the link intact while silently changing what
                      // other Seekers see on your profile, because
                      // guardians_for_unlocked tests zyra_block_exists.
                      // The Guardian equivalent is Remove, which lives on
                      // the Guardian's own detail page as its own decision.
                      if (widget.source != ZyraReportSource.guardian) ...[
                        const SizedBox(height: 14),
                        Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
                        const SizedBox(height: 14),

                        // Separated from the reasons above, because it is
                        // not an accusation and shouldn't feel like one.
                        _BlockOnlyRow(
                          firstName: widget.firstName,
                          enabled: !_submitting,
                          onTap: _blockOnly,
                        ),
                      ],
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      _error!,
                      style: ZyraText.subtext(size: 12.5, color: const Color(0xFFE08080)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _selected == null ? Colors.white24 : ZyraColors.royalPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: (_selected == null || _submitting) ? null : _submitReport,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Send report', style: ZyraText.button(size: 14)),
                    ),
                  ),
                ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: ZyraText.subtext(size: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final ZyraReportReason reason;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? ZyraColors.accentBg : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? ZyraColors.accentBorder : Colors.white.withValues(alpha: 0.10),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reason.label, style: ZyraText.body(size: 14.5, color: Colors.white)),
                    if (reason.isUrgent) ...[
                      const SizedBox(height: 2),
                      Text('Reviewed first', style: ZyraText.subtext(size: 11)),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                // White, not ZyraColors.accentBorder — that constant is a
                // 40%-opacity purple intended as a BORDER against a light
                // fill. As an icon colour on this dark sheet it reads as
                // disabled rather than selected.
                color: selected ? Colors.white : Colors.white30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockOnlyRow extends StatelessWidget {
  final String firstName;
  final bool enabled;
  final VoidCallback onTap;

  const _BlockOnlyRow({required this.firstName, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_off_outlined, size: 20, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("I just don't want to see $firstName", style: ZyraText.body(size: 14.5, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text("Hides you both. Nothing is reported.", style: ZyraText.subtext(size: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
