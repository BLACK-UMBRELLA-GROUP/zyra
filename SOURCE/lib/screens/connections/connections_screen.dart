// Connections tab — per APP/Navigation/SEEKER NAVIGATION/Summary.md's
// CONNECTIONS section: "Relationship Journey = Save → Consider → Match
// → Conversation → Family Stage," with sections in order Passed,
// Saved, Family Introductions, Considered, Matches. Matches is NOT a
// conversation inbox (MATCH_UX_SPEC_CURRENT_VERSION_V1.md) — it houses
// Potential Journeys, with Active/Suspended Journeys below leading
// into the Pre-Journey Ritual (JourneyFlowScreen) rather than straight
// to Chat.
//
// 2026-07-26 (DR-ZYRA-101 audit, nav bar fix — see SEEKER NAVIGATION
// Summary.md's own flagged inconsistency: live Seeker nav had only 3
// tabs, Browse/Matches/Profile, with no Connections or Wali tab at
// all). This screen used to be MatchesScreen (screens/matches/
// matches_screen.dart) and only covered the Matches section. Renamed
// and expanded to also surface Passed/Saved/Considered — reusing
// AppState.declined/saved/outgoingLikes exactly as profile_screen.dart
// already did for its own (now-superseded) connections counters — and
// a placeholder Family Introductions section, since the Wali-side
// Family Stage answering UI is a known, deliberately unbuilt gap (see
// the Founder handover's "Immediate Next Steps" item 1) rather than
// something to fake here.
//
// 2026-07-25 (DR-ZYRA-101 audit): Matches section rewritten against
// real matches.status ('potential'/'active'/'paused'/'ended') instead
// of the old client-only stand-in. "Start Journey" now calls
// ZyraJourneyService.promoteToActive (a real RPC enforcing
// one-Active-Journey-at-a-time), and both journey lists are re-fetched
// from the backend rather than mutated locally. A SUSPENDED JOURNEYS
// section surfaces paused journeys (Journey Suspension,
// JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md) with Resume/End actions.

import 'package:flutter/material.dart';
import '../../models/journey_match.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_journey_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../journey/journey_flow_screen.dart';
import '../subscription/upgrade_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  // Suspended journeys (JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md): these
  // are NOT a separate matches.status — per that spec's own §1.1
  // "Architectural Framing", suspension is a behavioural sub-state of
  // Active Journey, not a lifecycle transition. So a suspended journey
  // still has status='active'; it's identified by suspended_by being
  // non-null. Split out of `active` here for display purposes only.
  List<JourneyMatch> _suspended = [];
  bool _startingJourney = false;
  String? _startingMatchId;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    _refresh();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _refresh() async {
    final all = await ZyraJourneyService.fetchJourneyMatches(statuses: const ['potential', 'active']);
    if (!mounted) return;
    final potential = all.where((j) => j.status == 'potential').toList();
    final activeAll = all.where((j) => j.status == 'active').toList();
    final active = activeAll.where((j) => !j.isSuspended).toList();
    final suspended = activeAll.where((j) => j.isSuspended).toList();
    AppState.instance.setJourneyMatches(potential: potential, active: active);
    setState(() => _suspended = suspended);
  }

  void _showIncomingTease() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Incoming Potentials', style: ZyraText.heading(size: 16)),
        content: Text(
          "See who's already interested in you. Available with ZYRA One.",
          style: ZyraText.subtext(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Not now', style: ZyraText.subtext(size: 13))),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
            },
            child: Text('See ZYRA One', style: ZyraText.button(size: 13)),
          ),
        ],
      ),
    );
  }

  void _startJourney(JourneyMatch j) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Start Journey with ${j.profile.firstName}?', style: ZyraText.heading(size: 16)),
        content: Text(
          'This begins your Active Journey — a Journey slot is used, and the '
          'Pre-Journey Ritual begins with Compatibility Reveal. You may only '
          'have one Active Journey at a time.',
          style: ZyraText.subtext(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Not yet', style: ZyraText.subtext(size: 13))),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _promote(j);
            },
            child: Text('Start Journey', style: ZyraText.button(size: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _promote(JourneyMatch j) async {
    setState(() {
      _startingJourney = true;
      _startingMatchId = j.matchId;
    });
    try {
      final ok = await ZyraJourneyService.promoteToActive(j.matchId);
      await _refresh();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
        ));
      }
    } on OneActiveJourneyLimitException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You already have an Active Journey. End or pause it before starting another.'),
      ));
    } finally {
      if (mounted) setState(() => _startingJourney = false);
    }
  }

  Future<void> _resumeSuspended(JourneyMatch j) async {
    try {
      await ZyraJourneyService.resumeJourney(j.matchId);
      await _refresh();
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
      ));
    } on JourneyAutoEndedException {
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('The other Seeker started a new Journey while this one was suspended — it has now ended.'),
      ));
    }
  }

  Future<void> _endSuspended(JourneyMatch j) async {
    await ZyraJourneyService.endJourney(j.matchId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final potential = AppState.instance.potentialJourneys;
    final active = AppState.instance.activeJourneys;
    final passed = AppState.instance.declined;
    final saved = AppState.instance.saved;
    final considered = AppState.instance.outgoingLikes;

    return Container(
      // 2026-07-25: gender-matched gradient (DR-ZYRA-094), widened from
      // Profile-only to all in-app post-onboarding screens per Founder
      // instruction — see ZyraColors.genderGradient() doc comment.
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Connections', style: ZyraText.heading(size: 22)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showIncomingTease,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.white24, size: 15),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Incoming Potentials — ZYRA One', style: ZyraText.subtext(size: 12, color: Colors.white38))),
                      const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  // MATCHES — Active / Suspended / Potential Journeys.
                  Text('MATCHES', style: ZyraText.chapterLabel(color: Colors.white54)),
                  const SizedBox(height: 10),
                  Text('ACTIVE JOURNEY', style: ZyraText.chapterLabel(color: Colors.white38)),
                  const SizedBox(height: 8),
                  if (active.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: ZyraEmptyState(
                        icon: Icons.forum_outlined,
                        message: 'Once you Start a Journey, it continues here.',
                      ),
                    )
                  else
                    ...active.map((j) => _JourneyTile(
                          profile: j.profile,
                          subtitle: j.journeyStage == 'conversation' ? 'Conversation open' : 'In the Pre-Journey Ritual',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => JourneyFlowScreen(matchId: j.matchId, profile: j.profile),
                          )),
                        )),
                  if (_suspended.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('SUSPENDED JOURNEYS', style: ZyraText.chapterLabel(color: Colors.white38)),
                    const SizedBox(height: 8),
                    ..._suspended.map((j) {
                      // Only the Seeker who initiated suspension may resume
                      // (JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md §12.1). If
                      // the OTHER party suspended it, this Seeker is in the
                      // Peer-Suspended state and can only wait or End.
                      final iInitiated = j.suspendedBy == ZyraAuth.currentUser?.id;
                      return _JourneyTile(
                        profile: j.profile,
                        subtitle: iInitiated ? 'Paused by you — conversation closed' : 'Paused by them — waiting',
                        trailingLabel: iInitiated ? 'Resume' : null,
                        onTrailingTap: iInitiated ? () => _resumeSuspended(j) : null,
                        onTap: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1220),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text('Paused with ${j.profile.firstName}', style: ZyraText.heading(size: 16)),
                            content: Text(
                              iInitiated
                                  ? 'This Journey is on hold. Resume to pick up exactly where you left off, or End it permanently.'
                                  : "${j.profile.firstName} paused this Journey. You can wait for them to resume, or End it permanently — you can't resume it yourself.",
                              style: ZyraText.subtext(),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Close', style: ZyraText.subtext(size: 13))),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _endSuspended(j);
                                },
                                child: Text('End Journey', style: ZyraText.button(size: 13, color: const Color(0xFFE08080))),
                              ),
                              if (iInitiated)
                                FilledButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _resumeSuspended(j);
                                  },
                                  child: Text('Resume', style: ZyraText.button(size: 13)),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                  Text('POTENTIAL JOURNEYS', style: ZyraText.chapterLabel(color: Colors.white38)),
                  const SizedBox(height: 8),
                  if (potential.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: ZyraEmptyState(
                        icon: Icons.favorite_border,
                        message: "Nothing here yet — when you and someone else Like each other, it'll show up here.",
                      ),
                    )
                  else
                    ...potential.map((j) => _JourneyTile(
                          profile: j.profile,
                          subtitle: 'New match',
                          trailingLabel: _startingJourney && _startingMatchId == j.matchId ? 'Starting…' : 'Start Journey',
                          onTrailingTap: _startingJourney ? null : () => _startJourney(j),
                        )),

                  // CONSIDERED — outgoing Likes (renamed per DR-ZYRA-099 /
                  // OA-ZYRA-138; underlying AppState field name unchanged).
                  const SizedBox(height: 28),
                  Text('CONSIDERED (${considered.length})', style: ZyraText.chapterLabel(color: Colors.white54)),
                  const SizedBox(height: 10),
                  if (considered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: ZyraEmptyState(
                        icon: Icons.pending_outlined,
                        message: "Profiles you've Considered but who haven't matched back yet show up here.",
                      ),
                    )
                  else
                    ...considered.map((p) => _JourneyTile(profile: p, subtitle: 'Waiting to hear back')),

                  // FAMILY INTRODUCTIONS — deliberately kept a separate
                  // section (not merged into Saved) per SEEKER NAVIGATION
                  // Summary.md. Not built yet — the Wali-side Family Stage
                  // answering UI is a known, open gap (Founder handover,
                  // "Immediate Next Steps" item 1), so this stays an honest
                  // empty state rather than a fake list.
                  const SizedBox(height: 28),
                  Text('FAMILY INTRODUCTIONS', style: ZyraText.chapterLabel(color: Colors.white54)),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: ZyraEmptyState(
                      icon: Icons.groups_outlined,
                      message: 'Family Stage introductions will appear here once this stage of a Journey is built.',
                    ),
                  ),

                  // SAVED.
                  const SizedBox(height: 28),
                  Text('SAVED (${saved.length})', style: ZyraText.chapterLabel(color: Colors.white54)),
                  const SizedBox(height: 10),
                  if (saved.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: ZyraEmptyState(
                        icon: Icons.bookmark_border,
                        message: "Profiles you've Saved to revisit later show up here.",
                      ),
                    )
                  else
                    ...saved.map((p) => _JourneyTile(profile: p, subtitle: 'Saved')),

                  // PASSED — per PROFILE DECISION SYSTEM/Summary.md
                  // ("no record, no notification"), this is a purely
                  // local, session-scoped list — nothing is written to
                  // the backend for a Pass, so this list resets on
                  // sign-out/account switch.
                  const SizedBox(height: 28),
                  Text('PASSED (${passed.length})', style: ZyraText.chapterLabel(color: Colors.white54)),
                  const SizedBox(height: 10),
                  if (passed.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: ZyraEmptyState(
                        icon: Icons.close,
                        message: "Profiles you've Passed on show up here for this session.",
                      ),
                    )
                  else
                    ...passed.map((p) => _JourneyTile(profile: p, subtitle: 'Passed')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  final SeekerProfile profile;
  final String subtitle;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;

  const _JourneyTile({
    required this.profile,
    required this.subtitle,
    this.trailingLabel,
    this.onTap,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(profile.photoUrl, width: 52, height: 52, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1220), child: SizedBox(width: 52, height: 52))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${profile.firstName}, ${profile.age}', style: ZyraText.body(size: 14, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: ZyraText.subtext(size: 11.5)),
                      ],
                    ),
                  ),
                  if (trailingLabel != null)
                    TextButton(
                      onPressed: onTrailingTap,
                      child: Text(trailingLabel!, style: ZyraText.button(size: 12.5)),
                    )
                  else if (onTap != null)
                    const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
