// ZYRA One upgrade / subscription management screen.
// Pricing and feature list transcribed from ZYRA_PRODUCT_SPEC §4-8.
//
// PRICING CORRECTED 2026-08-13 (Founder approved) — OA-ZYRA-207.
//
// This table was transcribed against PRODUCT_SPEC V3 and never updated
// when the 2026-08-03 reprice landed. For ten days the app ADVERTISED
// £0.99/£2.99/£1.99/£4.99 here while CHARGING £1.99/£7.99/£2.99/£9.99 on
// the unlock screen — two prices for one product, in one app, under the
// retired product names ("Unlock Profile").
//
// Found 2026-08-08 by the DANGLING DOC REF check, written up the same
// day, and then not fixed for five more days because the finding was
// recorded in a document instead of the action register. That is the
// reason OA-ZYRA-208 now requires every finding to carry an OA number.
//
// THE STRUCTURAL FIX, not just the text one: the four figures are no
// longer typed here. They are read from UnlockPricing, which is the one
// ratified definition. Retyping them from memory is how this happened —
// so this file can no longer retype them.
//
// No real payment processing exists yet (App
// Store/Play Store in-app purchase, or Stripe for web, per SYSTEM/
// OUTSTANDING_ACTIONS — not yet an OA, worth raising); "Upgrade" here
// flips the local mock entitlement (AppState.setPlan) so tier-gated UI
// elsewhere in the app is testable today, same mocking discipline used
// for auth and the rest of this build.

import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../widgets/zyra_moment.dart';
import '../../theme/zyra_text.dart';
// The single ratified definition of unlock pricing (Founder 2026-08-03).
// Imported, never transcribed — see the header note.
import 'profile_unlock_screen.dart' show UnlockPricing;

enum _BillingCycle { monthly, annual }

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  _BillingCycle _cycle = _BillingCycle.monthly;

  static const _basicFeatures = [
    'Create profile, upload photos',
    'Browse up to 50 profiles every 4 hours',
    'Save up to 10 profiles per day',
    'Like up to 10 profiles per day',
    'Unlimited Potential Journeys',
    'One Active Journey',
    // ADDED 2026-08-01. Found via Fable's FAQ review: the FAQ sold an
    // ad-free tier that this list never mentioned, so a benefit was
    // discoverable only in the help centre. Sponsored cards are real and
    // are gated on ZyraPlan.basic (browse_screen.dart) — this is an
    // accurate benefit, it was simply missing from the place people buy.
    'No sponsored cards while browsing',
    'Standard Compatibility Unlock on Active Journey',
    'Link a Guardian',
    '7-day ZYRA One trial on your first Active Journey',
  ];

  static const _oneFeatures = [
    'Everything in ZYRA Basic',
    'Unlimited browsing, Saves and Likes',
    'Incoming Potentials — see who Liked you first',
    'Mutual Save Detection',
    'Pause / Resume Journey, unlimited Paused Journeys',
    'Priority Discovery',
    'Compatibility Unlock Plus on Active Journey creation',
    'ZYRA Intelligence — Recommendations, Insights, Summaries',
    'One Guardian+ entitlement included',
  ];

  static const _unlocks = [
    ('Compatibility Unlock', '1 profile', UnlockPricing.single),
    ('Compatibility Unlock', '5 profiles', UnlockPricing.bundle),
    ('Compatibility Unlock Plus', '1 profile', UnlockPricing.singlePlus),
    ('Compatibility Unlock Plus', '5 profiles', UnlockPricing.bundlePlus),
  ];

  /// Pre-purchase legal disclosure — ADDED 2026-08-01 (Founder: "we need
  /// warnings when someone subscribes for legal reasons").
  ///
  /// Required, not optional polish. Two UK regimes bite here:
  ///
  ///   • Consumer Contracts Regulations 2013 — a 14-day right to cancel,
  ///     and the digital-content carve-out only applies if the consumer
  ///     ACKNOWLEDGED losing that right before the content is supplied.
  ///     An unacknowledged carve-out is not a carve-out.
  ///   • Consumer Protection from Unfair Trading Regs — auto-renewal and
  ///     the real recurring price must be clear BEFORE purchase, not
  ///     discoverable afterwards. The CMA has acted on subscription
  ///     traps repeatedly.
  ///
  /// Placed before the purchase completes rather than in the Terms,
  /// because "it was in clause 9.6" is not a defence if the buying screen
  /// said nothing. Muzz's Terms draw attention to exactly these points in
  /// their opening clause for the same reason (see ZYRA_LEGAL_RESEARCH §2).
  ///
  /// NOT LEGAL ADVICE and NOT FINAL — the wording below is a considered
  /// draft that must go to a solicitor with the Terms. The prices are
  /// taken from BUSINESS/ZYRA PRICING/Summary.md.
  Future<void> _confirmPurchase() async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZyraColors.luxuryDarkPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Before you subscribe', style: ZyraText.heading(size: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ZYRA One is £34.99 a month. It renews automatically each month '
                'until you cancel, and you can cancel any time through your App '
                'Store or Google Play subscription settings.\n\n'
                'You have 14 days to change your mind. If you start using the '
                'paid features straight away, you agree that this 14-day right '
                'ends once you do.\n\n'
                'Cancelling stops the next payment. It does not refund the '
                'period you are already in, and your ZYRA One features stay '
                'until that period ends.',
                style: ZyraText.subtext(size: 13),
              ),
              const SizedBox(height: 14),
              // ADDED 2026-08-01. _WaliDependencyNotice already carries this
              // warning on the screen itself — but this dialog is the
              // ACKNOWLEDGEMENT step, and a notice further up the page is
              // not the same as the last thing someone reads before they
              // agree. A woman with no linked Wali would otherwise tap "I
              // understand" having been told the price and the renewal, but
              // not that part of what she is buying cannot work yet.
              Text(
                'Some ZYRA One features need a linked Guardian — including the Guardian '
                'One entitlement included with your subscription. Subscribing '
                'does not remove that requirement. Everything unlocks on its own '
                'once your Guardian accepts.',
                style: ZyraText.subtext(size: 13),
              ),
              const SizedBox(height: 14),
              Text(
                'Nothing about your safety is behind this. Blocking, reporting '
                'and privacy controls are free for everyone, always.',
                style: ZyraText.body(size: 12.5, color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Not now', style: ZyraText.subtext(size: 13)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('I understand — continue', style: ZyraText.button(size: 13)),
          ),
        ],
      ),
    );
    if (agreed == true && mounted) _upgrade();
  }

  Future<void> _upgrade() async {
    AppState.instance.setPlan(ZyraPlan.one);
    // R5 (DR-ZYRA-147/148) — the quiet premium welcome: what changed,
    // not a sales page. Replaces the stock AlertDialog that congratulated
    // in Material's voice instead of ZYRA's.
    await showZyraMoment(
      context,
      mark: Icons.workspace_premium_outlined,
      lines: const [
        ZyraMomentLine.heading('ZYRA One, active.'),
        ZyraMomentLine.body('Three Journeys may run at once.'),
        ZyraMomentLine.body('Pauses hold their place.'),
        ZyraMomentLine.body('Unlocks are included.'),
        ZyraMomentLine.quiet('Same seriousness. More room.'),
      ],
      ctaLabel: 'Continue',
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _downgrade() {
    AppState.instance.setPlan(ZyraPlan.basic);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOne = AppState.instance.plan == ZyraPlan.one;
    return Scaffold(
      body: Container(
        // 2026-07-25: gender-matched gradient (DR-ZYRA-094) — see
        // ZyraColors.genderGradient() doc comment.
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    Text('Subscription', style: ZyraText.heading(size: 18)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  children: [
                    if (isOne)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: ZyraColors.accentBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ZyraColors.accentBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF50B478), size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text("You're currently on ZYRA One.", style: ZyraText.body(size: 13))),
                          ],
                        ),
                      ),
                    if (isOne) const SizedBox(height: 20),

                    Text('ZYRA One', style: ZyraText.wordmark(size: 26)),
                    const SizedBox(height: 6),
                    Text(
                      'One genuine marriage journey at a time, with fewer limits along the way.',
                      style: ZyraText.subtext(),
                    ),
                    const SizedBox(height: 20),

                    _BillingToggle(
                      cycle: _cycle,
                      onChanged: (c) => setState(() => _cycle = c),
                    ),
                    const SizedBox(height: 24),

                    _PlanCard(
                      title: 'ZYRA Basic',
                      price: 'Free',
                      features: _basicFeatures,
                      highlighted: false,
                    ),
                    const SizedBox(height: 14),
                    _PlanCard(
                      title: 'ZYRA One',
                      price: _cycle == _BillingCycle.monthly ? '£34.99 / month' : '£349.90 / year',
                      priceNote: _cycle == _BillingCycle.annual ? '10 months paid, 12 received' : null,
                      features: _oneFeatures,
                      highlighted: true,
                    ),
                    const SizedBox(height: 14),

                    // Touchpoint 2 — Subscription Purchase Screen, per
                    // APP/Premium/SUBSCRIPTION TRANSPARENCY/TRANSPARENCY_
                    // CURRENT_VERSION_V1.md. Added 2026-07-25 (OA-ZYRA-140
                    // item 10, Founder decision: "add it now"). Positive-
                    // framing dependency notice, shown immediately before
                    // the purchase button, only while the Wali-dependent
                    // features are actually unresolved (not yet on ZYRA
                    // One — once subscribed this notice would be stale).
                    if (!isOne) const _WaliDependencyNotice(),
                    if (!isOne) const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isOne ? ZyraColors.iconButtonBg : ZyraColors.accentBg,
                          border: Border.all(color: isOne ? ZyraColors.iconButtonBorder : ZyraColors.accentBorder, width: 1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            // 2026-08-01: routes through _confirmPurchase,
                            // not straight to _upgrade — the pre-purchase
                            // disclosure must be seen before money is taken.
                            onTap: isOne ? _downgrade : _confirmPurchase,
                            child: Center(
                              child: Text(
                                isOne ? 'Switch back to ZYRA Basic' : 'Upgrade to ZYRA One',
                                style: ZyraText.button(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'This is a preview build — no payment is actually taken. Real purchases go through the App Store / Play Store once this is ready for release.',
                        style: ZyraText.subtext(size: 10.5, color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text('UNLOCK INDIVIDUAL PROFILES', style: ZyraText.chapterLabel(color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text(
                      'Available on any plan — reveal extra compatibility detail before a Match.',
                      style: ZyraText.subtext(size: 12),
                    ),
                    const SizedBox(height: 12),
                    ..._unlocks.map((u) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text('${u.$1} — ${u.$2}', style: ZyraText.body(size: 13))),
                              Text(u.$3, style: ZyraText.body(size: 13, color: Colors.white)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Touchpoint 2 dependency notice (TRANSPARENCY_CURRENT_VERSION_V1.md).
/// "Before you subscribe" — Wali One entitlement (bundled with
/// ZYRA One) requires an actual linked Wali before AI Journey
/// Summaries, Guided Wali Conversations, and Wali One Questions
/// activate. Positive framing per the standard's own example wording.
class _WaliDependencyNotice extends StatelessWidget {
  const _WaliDependencyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ZyraColors.iconButtonBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.white70, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: 'Before you subscribe\n', style: ZyraText.body(size: 12.5).copyWith(fontWeight: FontWeight.w500)),
                  TextSpan(
                    text: 'Some ZYRA One features require a linked Guardian. Once your Guardian accepts their invitation, everything unlocks automatically.',
                    style: ZyraText.subtext(size: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  final _BillingCycle cycle;
  final ValueChanged<_BillingCycle> onChanged;
  const _BillingToggle({required this.cycle, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: _segment('Monthly', _BillingCycle.monthly)),
          Expanded(child: _segment('Annual · save 17%', _BillingCycle.annual)),
        ],
      ),
    );
  }

  Widget _segment(String label, _BillingCycle value) {
    final selected = cycle == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ZyraColors.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: selected ? Border.all(color: ZyraColors.accentBorder, width: 1) : null,
        ),
        child: Center(child: Text(label, style: ZyraText.body(size: 12.5, color: Colors.white))),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String? priceNote;
  final List<String> features;
  final bool highlighted;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.highlighted,
    this.priceNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted ? ZyraColors.accentBg : ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: highlighted ? ZyraColors.accentBorder : ZyraColors.iconButtonBorder, width: highlighted ? 1.5 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: ZyraText.body(size: 16, color: Colors.white).copyWith(fontWeight: FontWeight.w500)),
              Text(price, style: ZyraText.body(size: 15, color: Colors.white)),
            ],
          ),
          if (priceNote != null) ...[
            const SizedBox(height: 2),
            Text(priceNote!, style: ZyraText.subtext(size: 11)),
          ],
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, color: Color(0xFF50B478), size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: ZyraText.subtext(size: 12.5))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
