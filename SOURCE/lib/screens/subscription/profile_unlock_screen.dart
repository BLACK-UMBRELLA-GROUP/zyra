// Compatibility Unlock — ONE page, two sections.
//
// REBUILT 2026-08-03/04. Was two swipeable tabs (Unlock / Unlock+) with a
// sliding toggle, matching the Journeys/Activity gesture.
//
// Founder: "the compatibility unlock pages... one page instead."
//
// Why the tabs were wrong, recorded so they don't come back: a swipe
// between two tabs says "these are alternatives, pick one". They are not
// alternatives — Plus is a superset of Unlock. The gesture was actively
// teaching the wrong relationship, and it hid half the offer behind a
// swipe the user had no reason to make.
//
// Stacked, the relationship states itself:
//
//   OVERALL      the headline number          Compatibility Unlock
//   THE DETAIL   what's inside that number    Compatibility Unlock+
//
// FOUNDER DECISIONS BAKED IN HERE (2026-08-03, chosen from mockups):
//
//   • Balance shown in PLAIN WORDS, top-right of each section header
//     ("5 left" / "none left"). No balance card, no subheading. The count
//     sits beside the thing it applies to.
//   • The plus is an ICON or is welded to the word — never the word
//     "Plus". Button label is `Unlock Compatibility+`, no space, so the
//     glyph cannot break onto its own line at any text size.
//   • Locked detail rows carry a PADLOCK EACH. The user sees the shape of
//     what they'd get — six named categories — without any of the values.
//   • Unlocked state is padlock-open + "Unlocked". Nothing else. The line
//     "revisit any time, free" was cut (Founder: "the user will know each
//     unlock is permanent").
//   • No BEST VALUE badge here. It belongs on the buy page, where there
//     is something to compare it against.
//   • "Buy more unlocks" is a TEXT LINK at the foot, not a second button
//     competing with the two unlock buttons above it.
//
//   • GREEN / AMBER / RED MOVED UP TO PLUS. Founder: "unlock should only
//     be % — no green, yellow or red, so it gives unlock plus more
//     value." Compatibility Unlock is now the overall percentage and
//     nothing else. This CHANGES the tier contents in APP/Premium/
//     Profile Unlocks/Summary.md, which is updated to match.
//
// ============================ NOT REAL ==============================
// No number on this screen is computed and nothing here can be bought.
//
// The score compares one Seeker's onboarding preferences against the
// other's answers. `onboarding_answers` has zero rows for real users, and
// the scoring method is still an open to-do in the spec. There is also no
// payment SDK in the project — verified against pubspec.yaml: no
// in_app_purchase, no StoreKit, no RevenueCat, no Stripe.
//
// The unlock RECORD is real (see ZyraUnlockService) — `profile_unlocks`
// rows are written and read, and the once-per-profile rule is enforced by
// a unique index. Only the payment and the numbers are pretend.
//
// The gold SAMPLE banner that used to say so on-screen was removed
// 2026-08-03 at the Founder's instruction ("remove the yellow sample
// logo"). Nothing on this page now marks the figures as fake. The buy
// link still refuses honestly, but a screenshot of "81% overall" no
// longer carries a warning with it — worth knowing before this screen is
// shown to anyone outside the build.
// ====================================================================

import 'package:flutter/material.dart';

import '../../models/seeker_profile.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_guardian_info_service.dart';
import '../../services/zyra_unlock_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_glass_dialog.dart';

/// Free Compatibility Unlock+ credits included with ZYRA One (Founder,
/// 2026-08-03).
///
/// NO LONGER ADDED BY THIS SCREEN (2026-08-04). It used to be `+3` on top
/// of a dev-panel count, which meant the number shown and the number the
/// server would honour were computed in different places by different
/// rules — and the server's rule was "there isn't one".
///
/// These credits are now granted into `unlock_credits` with
/// reason 'zyra_one_included' when a ZYRA One subscription activates, so
/// the balance is already correct without special-casing the plan here.
/// The constant remains as the single definition of how many, read by the
/// database grant, not by the UI.
const int kZyraOneFreeUnlockPlus = 3;

/// Pricing — Founder approved 2026-08-03.
///
/// NOT READ BY THIS SCREEN, deliberately. Prices, savings and the BEST
/// VALUE badge all moved to the buy page (Founder: "best value isn't
/// needed on that page"), and the same reasoning removes the prices — this
/// screen's question is "spend one?", not "which pack?".
///
/// Kept here rather than deleted because these are the ratified figures
/// and the buy page has not been built yet. Deleting them would mean
/// retyping them from memory later, which is exactly how the app came to
/// disagree with the pricing document in the first place.
///
/// The savings are stated, not estimated:
///   standard  5 x 1.99 = 9.95, pack 7.99 -> 19.7%, shown as 20%
///   plus      5 x 2.99 = 14.95, pack 9.99 -> 33.2%, shown as 33%
class UnlockPricing {
  UnlockPricing._();
  static const single = '£1.99';
  static const bundle = '£7.99';
  static const singlePlus = '£2.99';
  static const bundlePlus = '£9.99';
  static const saving = 'Save 20%';
  static const savingPlus = 'Save 33%';
}

/// The sample figures, in one place and internally consistent.
///
/// The old screen showed 81% on the Unlock tab and 89% on the Unlock+ tab
/// — two different overall scores for the same pair of people, which is
/// impossible. It went unnoticed because the tabs were never on screen
/// together. Stacking them made it obvious in the first mockup.
///
/// One overall score, 81%. Everything else is derived so it holds up if
/// the Founder does the arithmetic:
///
///   counts     (62 + 19x0.5) / 88 = 81.25%   [green=1, amber=0.5, red=0]
///   categories (74+78+85+88+69+92) / 6 = 81
///
/// That weighting is an ASSUMPTION, not a ratified rule — the real scoring
/// method is still open. It is written down here so whoever builds the
/// scorer knows what these sample numbers were made to satisfy.
class _Sample {
  _Sample._();
  static const overall = 81;
  static const green = 62;
  static const amber = 19;
  static const red = 7;
  static const categories = <(String, int)>[
    ('Lifestyle', 74),
    ('Work & Education', 78),
    ('Family Values', 85),
    ('Marriage Goals', 88),
    ('Personality', 69),
    ('Deen', 92),
  ];
}

class ProfileUnlockScreen extends StatefulWidget {
  final SeekerProfile profile;

  const ProfileUnlockScreen({super.key, required this.profile});

  @override
  State<ProfileUnlockScreen> createState() => _ProfileUnlockScreenState();
}

class _ProfileUnlockScreenState extends State<ProfileUnlockScreen> {
  bool _busy = false;

  /// Real credit balances from the `unlock_credits` ledger.
  ///
  /// REPLACED the dev panel's in-memory counts 2026-08-04. Those were the
  /// only notion of a balance that existed anywhere — which is exactly why
  /// nothing could check one, and why C-1 was possible. The number on this
  /// screen is now the same number the server enforces against.
  Map<UnlockTier, int> _balance = const {};
  bool _loadingBalance = true;

  /// Guardians of the profile being viewed. Three distinct states, and the
  /// difference between them matters (Founder decision, 2026-08-05):
  ///   null       — not unlocked at Plus, or the lookup failed. Stays locked.
  ///   empty list — unlocked, and she genuinely has no Guardian. Says so.
  ///   non-empty  — unlocked, shown in full.
  List<GuardianInfo>? _guardians;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadGuardians();
    _loadRealScore();
  }

  /// THIS SEEKER'S OWN figure for the profile on screen. Null until loaded,
  /// and null forever if they cannot be scored yet — the screen distinguishes
  /// those two states, because "still working it out" and "not enough
  /// answers between you" are different things to be told after paying.
  double? _realScore;
  bool _loadingScore = true;

  Future<void> _loadRealScore() async {
    // The sample profile is a fixture with no onboarding answers behind it,
    // so it has no score and never will. Asking would just be a round trip
    // to learn what isSampleProfile already knows.
    if (ZyraUnlockService.isSampleProfile(widget.profile.id)) {
      if (mounted) setState(() => _loadingScore = false);
      return;
    }
    final s = await ZyraDiscoveryService.fetchMyScoreFor(widget.profile.id);
    if (!mounted) return;
    setState(() {
      _realScore = s;
      _loadingScore = false;
    });
  }

  Future<void> _loadBalance() async {
    final b = await ZyraUnlockService.balances();
    if (!mounted) return;
    setState(() {
      _balance = b;
      _loadingBalance = false;
    });
  }

  /// Only ever fetched when a Plus unlock is already held — the RPC would
  /// return nothing otherwise, and asking anyway would make "no Guardian"
  /// and "not unlocked" indistinguishable in the logs.
  Future<void> _loadGuardians() async {
    if (!ZyraUnlockService.isUnlocked(widget.profile.id, UnlockTier.plus)) return;
    if (ZyraUnlockService.isSampleProfile(widget.profile.id)) return;
    final g = await ZyraGuardianInfoService.fetchUnlocked(widget.profile.id);
    if (!mounted) return;
    setState(() => _guardians = g);
  }

  /// Offers Plus when the Seeker holds credits for BOTH tiers and is about
  /// to spend the lesser one.
  ///
  /// Founder approved 2026-08-04. Shown only in that exact case: holding
  /// only one tier means there is no choice to present, and prompting
  /// anyway would be a nag rather than a question.
  ///
  /// Returns the tier to actually spend, or null if they backed out.
  Future<UnlockTier?> _tierToSpend(UnlockTier tapped) async {
    // Only ever offered as an upgrade from standard, never the reverse.
    // Someone who tapped Plus chose the better one; second-guessing that
    // is friction with nothing at the end of it.
    if (tapped != UnlockTier.standard) return tapped;

    final plus = _balance[UnlockTier.plus] ?? 0;
    final std = _balance[UnlockTier.standard] ?? 0;
    if (plus < 1 || std < 1) return tapped;

    // Already holding the detail? Then Plus buys nothing here.
    if (ZyraUnlockService.isUnlocked(widget.profile.id, UnlockTier.plus)) {
      return tapped;
    }

    final usePlus = await showZyraGlassChoice(
      context: context,
      // A padlock, not a star or a sparkle. Every icon in this feature is
      // a padlock — locked rows, the unlocked marker — and an upsell glyph
      // would make this read as an advert rather than a continuation of
      // the thing they just tapped.
      icon: Icons.lock_open_outlined,
      title: 'Use an Unlock+ instead?',
      body: "For the same tap you'd also see the Green, Amber and Red "
          'tallies and all six category scores.',
      // The one question the prompt cannot answer by itself is "can I
      // afford to be generous with the better one". One line settles it.
      detail: _BalanceLine(standard: std, plus: plus),
      primaryLabel: 'Yes, use Unlock+',
      // Not "Not now" — that implies they will come back to this, and they
      // will not; the unlock happens either way. It describes the outcome
      // rather than deferring it.
      secondaryLabel: 'No, just the overall',
    );

    if (usePlus == null) return null;              // dismissed
    return usePlus ? UnlockTier.plus : UnlockTier.standard;
  }

  /// Spends a credit, then rebuilds so the section swaps to the result.
  ///
  /// The outcome is no longer a bool (2026-08-04). "You have no credits"
  /// and "the network failed" used to produce the same retry message, and
  /// retrying will never fix the first one.
  Future<void> _unlock(UnlockTier tapped) async {
    if (_busy) return;

    final tier = await _tierToSpend(tapped);
    if (tier == null || !mounted) return;

    setState(() => _busy = true);
    final outcome = await ZyraUnlockService.unlock(widget.profile.id, tier);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case UnlockOutcome.unlocked:
      case UnlockOutcome.alreadyUnlocked:
        _loadBalance();   // a credit may have gone; re-read rather than guess
        _loadGuardians(); // Plus reveals Guardians — fetch them now it's open
      case UnlockOutcome.sampleProfile:
        // Opened for the session so the screen can be seen, but say plainly
        // that nothing real happened — a silent success here would teach the
        // wrong thing about a feature that costs money in production.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample profile — opened for preview. No unlock used.'),
          ),
        );
      case UnlockOutcome.insufficientCredits:
        _loadBalance();   // our count was stale if we got here at all
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You don't have an unlock left for this.")),
        );
      case UnlockOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("That didn't go through. Please try again.")),
        );
    }
  }

  void _buy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payments are not built yet — nothing has been charged.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.firstName;

    // Straight from the ledger. Previously `ZyraDevScenario.instance.unlocks
    // .count` — an in-memory dev-panel enum, which meant the number on
    // screen and the number the server would enforce had no relationship
    // to each other. They are now the same number.
    //
    // ZYRA One's included credits are a grant row in the same ledger
    // (reason 'zyra_one_included'), not a constant added here, so the
    // count is already correct without special-casing the plan. Founder
    // rejected itemising where credits came from — that belongs on the buy
    // screen.
    final standardLeft = _balance[UnlockTier.standard] ?? 0;
    final plusLeft = _balance[UnlockTier.plus] ?? 0;

    // Plus is a SUPERSET of Unlock, so holding Plus unlocks the overall
    // number too. Not a convenience — the spec defines Plus as "everything
    // in Compatibility Unlock, plus a category breakdown", and charging
    // again for the part they already bought would break the permanence
    // rule the unique index exists to enforce.
    final detailUnlocked = ZyraUnlockService.isUnlocked(widget.profile.id, UnlockTier.plus);
    final overallUnlocked =
        detailUnlocked || ZyraUnlockService.isUnlocked(widget.profile.id, UnlockTier.standard);

    final everBought = standardLeft > 0 || plusLeft > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Compatibility', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        // BoxConstraints.expand for the same reason as the report screen
        // and transition_screen: the Scaffold background is now the gender
        // gradient's first stop, so a short page would show a band of flat
        // Rose Pink under the content.
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              20,
              32,
            ),
            children: [
              Text('You and $name', style: ZyraText.heading(size: 22)),
              const SizedBox(height: 4),
              Text(
                'Built from what you both already told ZYRA. Neither of you '
                'sees the other’s answers.',
                style: ZyraText.subtext(size: 12.5),
              ),
              const SizedBox(height: 20),

              // ONE card, two sections, one divider. A card each would put
              // a gap between them and read as two unrelated offers; the
              // whole point of the single page is that the second section
              // is the inside of the first.
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      label: 'OVERALL',
                      // `left: null` while the ledger is still loading.
                      // Showing 0 would render "none left" for a moment to
                      // someone who has five — the exact complaint that
                      // started this screen's rebuild, reintroduced by the
                      // move to an async balance. The corner stays empty
                      // until the real number arrives.
                      left: _loadingBalance ? null : standardLeft,
                      unlocked: overallUnlocked,
                      buttonLabel: 'Unlock Compatibility',
                      busy: _busy,
                      onUnlock: () => _unlock(UnlockTier.standard),
                      child: overallUnlocked
                          ? _OverallResult(
                              score: _realScore,
                              loading: _loadingScore,
                              name: name,
                            )
                          : _OverallLocked(name: name),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.14), height: 1, thickness: 1),
                    _Section(
                      label: 'THE DETAIL',
                      left: _loadingBalance ? null : plusLeft,
                      unlocked: detailUnlocked,
                      // Plus welded to the word — Founder's choice from
                      // five treatments. No space means no break
                      // opportunity, so the glyph can never end up on a
                      // line of its own however the text is scaled.
                      buttonLabel: 'Unlock Compatibility+',
                      busy: _busy,
                      // Same reasoning as OVERALL above.
                      onUnlock: () => _unlock(UnlockTier.plus),
                      child: _Detail(
                        unlocked: detailUnlocked,
                        guardians: _guardians,
                        firstName: name,
                        gender: widget.profile.gender,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // A GLASS PILL, not an underlined text link — 2026-08-06.
              // Founder: "the buy more unlock word / sign, make it stand
              // out more. Maybe the outer circle like we have on the app."
              //
              // Same tokens as the app's other glass controls
              // (ZyraColors.iconButtonBg / iconButtonBorder, 50pt radius),
              // so it reads as a control rather than as a hyperlink — an
              // underline is web furniture and was the weakest thing on
              // the screen.
              //
              // Still not a FilledButton. The primary actions here are the
              // two unlock buttons; a third solid button would compete with
              // the thing this screen is actually for. A bordered pill sits
              // deliberately one step below them.
              //
              // "more" only once they have some — "Buy more unlocks" to
              // someone who has never had one is quietly wrong.
              Center(
                child: Material(
                  color: ZyraColors.iconButtonBg,
                  borderRadius: BorderRadius.circular(50),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _buy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: ZyraColors.accentBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white.withValues(alpha: 0.85)),
                          const SizedBox(width: 8),
                          Text(
                            everBought ? 'Buy more unlocks' : 'Buy unlocks',
                            style: ZyraText.button(size: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // REMOVED 2026-08-06, Founder: "the text at bottom an unlock
              // never shows — remove that."
              //
              // It read: "An unlock never shows what either of you wrote,
              // or which questions caused a Green, Amber or Red."
              //
              // The privacy promise it made is REAL and still holds — the
              // screen shows percentages and tallies, never an answer. It
              // is simply not this screen's job to keep saying so. Nothing
              // above it claims otherwise, so the sentence was defending
              // against a reading nobody was making, and it was the last
              // thing on the page.
              //
              // NOTE FOR THE SOLICITOR REVIEW: this wording exists nowhere
              // else in the product now. If the Privacy Policy or the
              // Article 9 consent text relies on the user having been told
              // this in-app, it needs a home — most likely the buy page,
              // where the promise is part of what is being sold.
            ],
          ),
        ),
      ),
    );
  }
}

/// One half of the card: a header with the balance in the corner, a body,
/// and either an unlock button or the unlocked marker.
class _Section extends StatelessWidget {
  final String label;

  /// Credits remaining, or null while the ledger is still loading.
  final int? left;
  final bool unlocked;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onUnlock;
  final Widget child;

  const _Section({
    required this.label,
    required this.left,
    required this.unlocked,
    required this.buttonLabel,
    required this.busy,
    required this.onUnlock,
    required this.child,
  });

  /// Plain words, Founder's choice. "none left" rather than "0 left"
  /// because a zero in a corner reads as a score, not a stock level.
  ///
  /// null renders NOTHING, not "none left" — the balance is still loading
  /// and claiming zero would be a lie the user has already caught once.
  String? get _balance => switch (left) {
        null => null,
        0 => 'none left',
        1 => '1 left',
        final n => '$n left',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: ZyraText.chapterLabel(color: Colors.white))),
              // The count disappears once unlocked. It answers "can I
              // afford this", and there is nothing left to afford.
              if (!unlocked && _balance != null)
                Text(
                  _balance!,
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: Colors.white.withValues(alpha: left == 0 ? 0.40 : 0.75),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 14),
          if (unlocked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open_outlined, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 7),
                Text('Unlocked', style: ZyraText.subtext(size: 12.5)),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // Disabled at zero rather than relabelled. The corner
                // already says why, and the foot link says what to do —
                // swapping this to a buy button would put the same offer
                // on screen twice.
                // `left == null` means the balance has not arrived yet.
                // Disabled until it does — an enabled button whose result
                // we cannot predict is worse than a brief dim one.
                onPressed: (left == null || left == 0 || busy) ? null : onUnlock,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Text(
                  buttonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZyraText.button(size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Unlock 5 | Unlock+ 5" — both balances, quietly, inside the Unlock+
/// prompt. Deliberately not a table or a pair of cards: the reader is
/// answering one yes/no question and only needs to know they can afford
/// either answer.
class _BalanceLine extends StatelessWidget {
  final int standard;
  final int plus;
  const _BalanceLine({required this.standard, required this.plus});

  @override
  Widget build(BuildContext context) {
    Widget part(String label, int n) => RichText(
          text: TextSpan(children: [
            TextSpan(text: '$label  ', style: ZyraText.subtext(size: 11.5, color: Colors.white54)),
            TextSpan(text: '$n', style: ZyraText.body(size: 12.5, color: Colors.white)),
          ]),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        part('Unlock', standard),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('|', style: ZyraText.subtext(size: 11.5, color: Colors.white24)),
        ),
        part('Unlock+', plus),
      ],
    );
  }
}

/// Locked overall — the shape of the answer, with the number withheld.
///
/// REPLACES a widget that hardcoded "You have none left" regardless of
/// balance, which is how the Founder saw that sentence while the dev panel
/// held five credits. The balance is now stated once, in the section
/// header, by the code that actually knows it. This widget says nothing
/// about stock at all — that is why it cannot be wrong about it again.
class _OverallLocked extends StatelessWidget {
  final String name;
  const _OverallLocked({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lock_outline, size: 20, color: Colors.white.withValues(alpha: 0.45)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your overall compatibility with $name.',
            style: ZyraText.body(size: 14, color: Colors.white),
          ),
        ),
        Text('__%', style: ZyraText.heading(size: 26, color: Colors.white24)),
      ],
    );
  }
}

/// Unlocked overall — the percentage, and nothing else.
///
/// Green/Amber/Red used to live here. Founder moved them to Plus so that
/// Plus has more to sell. Compatibility Unlock is now exactly one number,
/// which is also the easiest thing in the app to explain.
class _OverallResult extends StatelessWidget {
  /// THE REAL FIGURE, at last — OA-ZYRA-192, unblocked by OA-ZYRA-193 on
  /// 2026-08-11. This showed `_Sample.overall` — a constant 81% — to every
  /// Seeker for every profile, while taking a real credit for it. The
  /// transaction was real and the number was not.
  ///
  /// It is the SIGNED-IN Seeker's own figure, per decision (a2): how well
  /// this person's answers fit what you said you were looking for. The other
  /// person has their own, and it is not yours to see.
  final double? score;
  final bool loading;
  final String name;

  const _OverallResult({required this.score, required this.loading, required this.name});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Text('Working it out…', style: ZyraText.subtext(size: 13));
    }

    // NO NUMBER RATHER THAN A MADE-UP ONE. Reachable today because the
    // onboarding completeness gate (OA-ZYRA-193c) is decided but unbuilt, so
    // a half-finished profile can still be looked at. When that gate exists
    // this branch becomes unreachable — and it should STILL be here, because
    // the alternative is inventing a figure the moment it is.
    if (score == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('—', style: ZyraText.heading(size: 44, color: Colors.white38)),
          const SizedBox(height: 6),
          Text(
            'Not enough answers between you yet. This fills in as you and '
            '$name both cover more ground.',
            style: ZyraText.subtext(size: 12.5),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('${score!.round()}%', style: ZyraText.heading(size: 44)),
        const SizedBox(width: 12),
        Text('overall', style: ZyraText.subtext(size: 13)),
      ],
    );
  }
}

/// Says out loud that the figures above are not this person's score.
///
/// RESTORED 2026-08-10 (Founder decision, OA-ZYRA-192). A marker was removed
/// on 2026-08-03 — "remove the yellow sample banner" — and that was the right
/// call at the time: the screen was a mockup under review, and a real number
/// was impossible because `onboarding_answers` held zero rows.
///
/// That stopped being true on 2026-08-10. The table now holds 144 rows,
/// `seeker_details` another 144, and `score_candidates()` returns real
/// per-pair numbers that TWO live services already consume — Browse curation
/// (`zyra_discovery_service`) and the Journey reveal (`zyra_journey_service`).
/// So the app computes a real score in two places and shows a constant in the
/// one the Seeker pays a credit for. The unlock transaction is real;
/// `_Sample.overall` is not.
///
/// THE SECOND SENTENCE IS THE ONE THAT MATTERS. "Example figures" alone would
/// read as "not final". The problem is not that 81% is provisional — it is
/// that it is IDENTICAL FOR EVERY PROFILE, so without saying so a Seeker
/// reads it as a fact about this particular person.
///
/// Deliberately not a banner. This is the same idiom as the onboarding
/// privacy indicator — a small coloured dot and plain text, no card, no box —
/// and it borrows that system's amber, which already means "conditional, not
/// yet". Same tokens, so it stays in step if the palette moves.
///
/// STILL LIVE, AND MOVED — 2026-08-11. The overall percentage became real
/// (OA-ZYRA-192 closed by OA-ZYRA-193), so this came off it and went onto the
/// category breakdown, which is still a constant and stays one until
/// OA-ZYRA-193(d) settles what the categories are.
///
/// DELETE THIS WIDGET when the BREAKDOWN is real too. Not before: the earlier
/// instruction said to delete it when the screen showed a real number, which
/// on the day would have removed the qualifier from six sample figures
/// because a seventh had been fixed.
class _SampleMarker extends StatelessWidget {
  const _SampleMarker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(color: ZyraColors.unlockDot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'This breakdown is an example — the same for every profile. '
              'Your overall figure above is real.',
              style: ZyraText.privacyText(color: ZyraColors.unlockText),
            ),
          ),
        ],
      ),
    );
  }
}

/// The lower section, locked or not.
///
/// Locked, every row keeps its name and loses its value to a padlock —
/// the Founder's pick from four treatments. It shows the buyer exactly
/// what they are buying (six named areas plus the colour tallies) without
/// leaking a single figure, and it needs no sentence explaining itself.
class _Detail extends StatelessWidget {
  final bool unlocked;

  /// Guardians of the profile being viewed, or null while locked/unknown.
  /// An empty list is a real answer — "No Guardian linked" — not a gap.
  final List<GuardianInfo>? guardians;

  /// Whose Guardians these are, for the section copy.
  final String firstName;

  /// Their gender, so the copy says his/her rather than always "her".
  final String? gender;

  const _Detail({
    required this.unlocked,
    required this.guardians,
    required this.firstName,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Tally(colour: const Color(0xFF6FBF8A), label: 'Green', value: unlocked ? _Sample.green : null),
            _Tally(colour: const Color(0xFFE0C070), label: 'Amber', value: unlocked ? _Sample.amber : null),
            _Tally(colour: ZyraColors.destructive, label: 'Red', value: unlocked ? _Sample.red : null),
          ],
        ),
        const SizedBox(height: 14),
        for (final row in _Sample.categories)
          _CategoryRow(name: row.$1, value: unlocked ? row.$2 : null),
        // MOVED HERE 2026-08-11, not deleted. The overall figure above is
        // real now; THIS breakdown still is not, and cannot be until
        // OA-ZYRA-193(d) decides how many categories there are and which —
        // the screen shows six, onboarding has nine, and they do not map.
        // score_candidates returns no category detail at all.
        //
        // Plus charges MORE than Unlock, and what it charges more for is
        // exactly this. So the marker belongs on the part that is still a
        // sample, and it would have been quietly deleted along with the 81%
        // if its own doc comment had been followed literally.
        if (unlocked) const _SampleMarker(),
        _GuardianSection(
          unlocked: unlocked,
          guardians: guardians,
          firstName: firstName,
          gender: gender,
        ),
      ],
    );
  }
}

/// Guardian visibility — Founder decision, 2026-08-05: "I want the Guardian
/// to be visible. Show the Guardian's details, not just the relationship…
/// if no Guardian is linked, I want that shown honestly rather than hiding
/// the row. I don't want the UI to obscure or infer this information."
///
/// Consent is taken at onboarding and the Privacy Policy / Terms name
/// exactly what an unlock reveals, with solicitor review before launch.
///
/// Plus tier only, matching `guardians_for_unlocked()`, which will return
/// nothing for a standard unlock however this widget is called. Locked, it
/// keeps the same padlock treatment as every row above it, so a buyer can
/// see this is part of what Plus includes before paying for it.
class _GuardianSection extends StatelessWidget {
  final bool unlocked;
  final List<GuardianInfo>? guardians;
  final String firstName;

  /// The viewed profile's gender — 'male' | 'female' | null.
  ///
  /// ADDED 2026-08-06. The sentence below said "her Journey" for everyone,
  /// so viewing Tariq read "Tariq has 2 Guardians involved in her Journey."
  /// Founder: "Tariq would be a man, so make sure the app knows the wording
  /// to differentiate between man and woman."
  ///
  /// Worth noting WHY it was hardcoded: this screen only ever shows the
  /// opposite gender to the viewer, so on a female Seeker's device every
  /// profile is male and on a male Seeker's every profile is female. It
  /// reads correctly for exactly half the users and wrongly for the other
  /// half — the kind of bug that survives testing on one account.
  final String? gender;

  const _GuardianSection({
    required this.unlocked,
    required this.guardians,
    required this.firstName,
    required this.gender,
  });

  /// his / her / their. Falls back to "their" rather than guessing — an
  /// unknown gender is not a reason to misgender someone.
  String get _possessive => switch (gender) {
        'male' => 'his',
        'female' => 'her',
        _ => 'their',
      };

  @override
  Widget build(BuildContext context) {
    final list = guardians;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 14),
          Text('GUARDIAN', style: ZyraText.chapterLabel(color: Colors.white54)),
          const SizedBox(height: 10),

          if (!unlocked || list == null)
            // Same visual language as the locked category rows above.
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.lock_outline, size: 14, color: Colors.white.withValues(alpha: 0.35)),
              ],
            )
          else if (list.isEmpty)
            // Stated plainly, per the decision above. Not softened, not
            // hidden, and not inferred from silence.
            Text(
              'No Guardian linked.',
              style: ZyraText.body(size: 14, color: Colors.white.withValues(alpha: 0.85)),
            )
          else ...[
            for (final g in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        g.displayLine,
                        style: ZyraText.body(size: 14, color: Colors.white),
                      ),
                    ),
                    if (g.isMain)
                      Text('Main', style: ZyraText.subtext(size: 11.5)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              list.length == 1
                  ? '$firstName has a Guardian involved in $_possessive Journey.'
                  : '$firstName has ${list.length} Guardians involved in $_possessive Journey.',
              style: ZyraText.subtext(size: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  final Color colour;
  final String label;

  /// null = locked, and a padlock stands where the count would.
  final int? value;

  const _Tally({required this.colour, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: value == null ? colour.withValues(alpha: 0.4) : colour,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          if (value == null)
            Icon(Icons.lock_outline, size: 13, color: Colors.white.withValues(alpha: 0.35))
          else
            Text('$value', style: ZyraText.body(size: 15, color: Colors.white)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZyraText.subtext(size: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;

  /// null = locked: empty track, padlock where the percentage would be.
  final int? value;

  const _CategoryRow({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final locked = value == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZyraText.subtext(
                size: 12.5,
                color: Colors.white.withValues(alpha: locked ? 0.55 : 0.70),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                // Locked draws the track and no fill — the row is clearly
                // a measurement, with the measurement missing.
                //
                // `0.0` not `0`: the two branches of a conditional are
                // unified before the context type is applied, so `0` and
                // `value! / 100` would infer as `num` and fail to assign
                // to a `double?` parameter.
                value: locked ? 0.0 : value! / 100,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.55)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: locked
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  )
                : Text(
                    '$value%',
                    textAlign: TextAlign.right,
                    style: ZyraText.body(size: 12.5, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
