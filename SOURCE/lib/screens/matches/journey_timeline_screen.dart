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
import '../../services/zyra_match_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

class JourneyTimelineScreen extends StatefulWidget {
  final SeekerProfile withProfile;
  const JourneyTimelineScreen({super.key, required this.withProfile});

  @override
  State<JourneyTimelineScreen> createState() => _JourneyTimelineScreenState();
}

class _JourneyTimelineScreenState extends State<JourneyTimelineScreen> {
  bool _loading = true;
  List<ZyraMilestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final milestones = await ZyraMatchService.fetchTimeline(widget.withProfile.id);
    if (!mounted) return;
    setState(() {
      _milestones = milestones;
      _loading = false;
    });
  }

  static String _labelFor(String type) => switch (type) {
        'match_created' => 'Match',
        'conversation_started' => 'Conversation Started',
        'family_stage' => 'Family Stage',
        'meeting' => 'Meeting',
        'nikah' => 'Nikah',
        _ => type,
      };

  // 2026-07-26: check_circle_outline replaces favorite here (Founder:
  // "for the whole app I'm tryna avoid any heart icons") — outline
  // variant matches this switch's other three entries.
  static IconData _iconFor(String type) => switch (type) {
        'match_created' => Icons.check_circle_outline,
        'conversation_started' => Icons.forum_outlined,
        'family_stage' => Icons.family_restroom_outlined,
        'meeting' => Icons.people_outline,
        'nikah' => Icons.auto_awesome_outlined,
        _ => Icons.circle_outlined,
      };

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
                                    Text(
                                      '${m.occurredAt.day}/${m.occurredAt.month}/${m.occurredAt.year}',
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
      ),
    );
  }
}
