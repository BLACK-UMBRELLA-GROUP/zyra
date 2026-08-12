// Journey Timeline — per ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md's
// timelines/timeline_milestones tables ("Journey timeline per match" /
// "Events recorded on the timeline"). Reads real milestones for the
// signed-in user's match with withProfile. 'match_created' is added
// automatically the instant a mutual Like creates the match;
// 'conversation_started' is added automatically on the first real
// message. 'family_stage' / 'meeting' / 'nikah' are real-world events
// with no automatic signal in the data — marking them is the "Family
// Review Period" workflow, which isn't built yet, so this screen is
// currently read-only with no way to add those stages.
//
// Falls back to a plain empty state for mock Active Journeys with no
// real backing match (nothing to show, not an error).

import 'package:flutter/material.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_match_service.dart';
import '../../state/app_state.dart';
import '../../widgets/zyra_glass_dialog.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';
import '../profile/seeker_profile_screen.dart';

class JourneyTimelineScreen extends StatefulWidget {
  final SeekerProfile withProfile;
  const JourneyTimelineScreen({super.key, required this.withProfile});

  @override
  State<JourneyTimelineScreen> createState() => _JourneyTimelineScreenState();
}

class _JourneyTimelineScreenState extends State<JourneyTimelineScreen> {
  bool _loading = true;
  List<ZyraMilestone> _milestones = [];

  // Meeting/Nikah attestation (Founder 2026-08-12: both Seekers confirm).
  ZyraTimelineContext _context = const ZyraTimelineContext();
  bool _pendingDismissed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ZyraMatchService.fetchTimeline(widget.withProfile.id),
      ZyraMatchService.fetchTimelineContext(widget.withProfile.id),
    ]);
    if (!mounted) return;
    setState(() {
      _milestones = results[0] as List<ZyraMilestone>;
      _context = results[1] as ZyraTimelineContext;
      _loading = false;
    });
  }

  /// The two attestable types not yet on this Timeline.
  List<String> get _attestableTypes {
    final recorded = _milestones.map((m) => m.type).toSet();
    return ['meeting', 'nikah'].where((t) => !recorded.contains(t)).toList();
  }

  static String _attestLabel(String type) => type == 'meeting' ? 'Meeting' : 'Nikah';

  Future<void> _openPropose() async {
    final types = _attestableTypes;
    if (types.isEmpty || _context.matchId == null) return;
    final picked = await showZyraGlassDialog<String>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 30),
          const SizedBox(height: 14),
          Text('Record a milestone', style: ZyraText.heading(size: 18), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'It joins the Timeline once ${widget.withProfile.firstName} confirms it too.',
            style: ZyraText.subtext(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          for (final t in types) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(t),
                child: Text(_attestLabel(t), style: ZyraText.button(size: 13)),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: ZyraText.subtext(size: 13)),
          ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2024),
      lastDate: now,
      helpText: 'When was your ${_attestLabel(picked).toLowerCase()}?',
    );
    if (date == null || !mounted) return;
    final error = await ZyraMatchService.proposeMilestone(_context.matchId!, picked, date);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          'Asked ${widget.withProfile.firstName} to confirm. It joins the Timeline when they do.'),
    ));
    await _load();
  }

  Future<void> _confirmPending() async {
    final pending = _context.pending;
    if (pending == null || _busy) return;
    setState(() => _busy = true);
    final error = await ZyraMatchService.confirmMilestone(pending.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    await _load();
  }

  // ── EXTENDED 2026-08-11 with the Journey's own milestones. Until today
  // the Timeline could draw exactly one thing — 'match_created' — because
  // that was the only milestone anything wrote. Eight stages ran past it
  // leaving no mark, so a couple at Open Conversation and a couple who had
  // just matched had identical Timelines.
  //
  // WRITTEN AS A MOMENT, NOT AS A STAGE NAME. 'Faith & Values' is where you
  // ARE; 'You finished Faith & Values' is what HAPPENED, and a timeline is a
  // list of things that happened. The stage labels themselves still come from
  // the canonical map and are not duplicated here — these are event names.
  static String _labelFor(String type) => switch (type) {
        'liked' => 'You liked each other',
        'match_created' => 'Match',
        'journey_started' => 'Journey began',
        'compatibility_revealed' => 'Compatibility revealed',
        'salam_exchanged' => 'Salam exchanged',
        'guardian_linked' => 'Guardians linked',
        'phase_1_complete' => 'Finished Faith & Values',
        'phase_2_complete' => 'Finished Building a Life',
        'phase_3_complete' => 'Finished Navigating Life',
        'family_stage' => 'Families introduced',
        'conversation_started' => 'Open Conversation began',
        'meeting' => 'Meeting',
        'nikah' => 'Nikah',
        'journey_ended' => 'Journey ended',
        'journey_restarted' => 'Journey began again',
        _ => type,
      };

  // 2026-07-26: check_circle_outline replaces favorite here (Founder:
  // "for the whole app I'm tryna avoid any heart icons") — outline
  // variant matches this switch's other three entries.
  static IconData _iconFor(String type) => switch (type) {
        // No hearts anywhere, per the 2026-07-26 rule — mutual interest is a
        // handshake here, not a heart.
        'liked' => Icons.handshake_outlined,
        'match_created' => Icons.check_circle_outline,
        'journey_started' => Icons.flag_outlined,
        'compatibility_revealed' => Icons.insights_outlined,
        'salam_exchanged' => Icons.waving_hand_outlined,
        'guardian_linked' => Icons.shield_outlined,
        'phase_1_complete' => Icons.menu_book_outlined,
        'phase_2_complete' => Icons.home_outlined,
        'phase_3_complete' => Icons.route_outlined,
        'family_stage' => Icons.family_restroom_outlined,
        'conversation_started' => Icons.forum_outlined,
        'meeting' => Icons.people_outline,
        'nikah' => Icons.auto_awesome_outlined,
        'journey_ended' => Icons.do_not_disturb_alt_outlined,
        'journey_restarted' => Icons.restart_alt_outlined,
        _ => Icons.circle_outlined,
      };

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// "08 August 2026" — Founder's spec, 2026-08-11: the Timeline is the
  /// permanent history of the relationship, so every entry carries the
  /// ACTUAL calendar date, written out, never a relative "2 days ago"
  /// (relative dates rot; a record does not). Zero-padded day and full
  /// month name exactly as the spec's own example. Hand-rolled rather
  /// than adding the intl package for one format.
  static String _dateFor(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${_months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIXED 2026-08-01 (Founder: "there should be no purple at top, it
      // should blend the pink/purple colour... that should be across all
      // things"). Same fix notifications_screen.dart got on 2026-07-27:
      // without this the transparent AppBar shows the Scaffold's own flat
      // background through, cutting the gender gradient off with a hard
      // purple strip. Body content compensates with SafeArea, which still
      // clears the status bar.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Timeline with ${widget.withProfile.firstName}', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        // 2026-07-25: gender-matched gradient (DR-ZYRA-094) — see
        // ZyraColors.genderGradient() doc comment.
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: Column(
            children: [
              // FULL PROFILE LIVES HERE. Founder, 2026-08-10.
              //
              // It was briefly an expand glyph on the Active Journey card's
              // photo and the Founder rejected it: a small icon sitting on
              // someone's face, doing something the icon does not name.
              //
              // A labelled bubble at the top of the Timeline is better for a
              // reason worth writing down — this screen is already the place
              // you come to look BACK at a person rather than act on them, so
              // "see them properly" belongs to the same intention. The card is
              // for getting into the Journey; this is for dwelling on it.
              //
              // ABOVE the loading and empty states on purpose. The profile is
              // worth looking at from the first day, when the Timeline itself
              // still says "Nothing recorded here yet."
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TimelineBubble(
                        label: 'View full profile',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => SeekerProfileScreen(profile: widget.withProfile),
                        )),
                      ),
                      // Meeting/Nikah are real-world events with no automatic
                      // signal in the data — either Seeker proposes, the other
                      // confirms (Founder 2026-08-12). Only on a running
                      // Journey, only while something is left to record, and
                      // never while a proposal is already pending.
                      if (_context.active &&
                          !_context.paused &&
                          _context.matchId != null &&
                          _context.pending == null &&
                          _attestableTypes.isNotEmpty)
                        _TimelineBubble(
                          label: 'Record a milestone',
                          onTap: _openPropose,
                        ),
                    ],
                  ),
                ),
              ),
              // A proposal from the other Seeker: confirm it here, or leave
              // it — "Not yet" only hides it for this visit, deliberately.
              if (_context.pending != null &&
                  _context.pending!.proposedBy != ZyraAuth.currentUser?.id &&
                  !_pendingDismissed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    decoration: BoxDecoration(
                      color: ZyraColors.frostFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ZyraColors.frostBorder, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.withProfile.firstName} says your '
                          '${_attestLabel(_context.pending!.type).toLowerCase()} was on '
                          '${_dateFor(_context.pending!.occurredOn)}.',
                          style: ZyraText.body(size: 13.5),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _pendingDismissed = true),
                              child: Text('Not yet', style: ZyraText.subtext(size: 12.5)),
                            ),
                            const SizedBox(width: 4),
                            FilledButton(
                              onPressed: _busy ? null : _confirmPending,
                              child: Text(_busy ? 'Confirming…' : 'Confirm',
                                  style: ZyraText.button(size: 12.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              // Your own proposal, still waiting on them.
              if (_context.pending != null &&
                  _context.pending!.proposedBy == ZyraAuth.currentUser?.id)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    'Waiting for ${widget.withProfile.firstName} to confirm — '
                    '${_attestLabel(_context.pending!.type)}, '
                    '${_dateFor(_context.pending!.occurredOn)}.',
                    style: ZyraText.subtext(size: 12),
                  ),
                ),
              Expanded(
                child: _loading
              ? const ZyraLoading()
              : _milestones.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: ZyraEmptyState(
                          icon: Icons.timeline_outlined,
                          message: 'Nothing recorded here yet.',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                      itemCount: _milestones.length,
                      itemBuilder: (context, index) {
                        final m = _milestones[index];
                        final isLast = index == _milestones.length - 1;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ZyraColors.accentBg,
                                    border: Border.all(color: ZyraColors.accentBorder, width: 1),
                                  ),
                                  child: Icon(_iconFor(m.type), color: Colors.white, size: 16),
                                ),
                                if (!isLast) Container(width: 1.5, height: 44, color: Colors.white24),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 30, top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_labelFor(m.type), style: ZyraText.body(size: 14.5, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    // "08 August 2026", not "8/8/2026" —
                                    // see _dateFor.
                                    Text(
                                      _dateFor(m.occurredAt),
                                      style: ZyraText.subtext(size: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app's pill — circular(20), iconButtonBg/iconButtonBorder — as a text
/// bubble.
///
/// DUPLICATED from `_CardPill` in connections_screen.dart, knowingly. Two
/// copies is not yet a shared widget; three is. Noted here so the third
/// person to need one lifts all three into `widgets/` rather than adding a
/// fourth quietly.
class _TimelineBubble extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimelineBubble({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZyraColors.iconButtonBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
          ),
          child: Text(label, style: ZyraText.button(size: 13)),
        ),
      ),
    );
  }
}
