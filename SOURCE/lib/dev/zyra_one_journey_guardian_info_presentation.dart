import '../widgets/zyra_developer_title.dart';
// LOCK 3: local Founder preview education, using current Profiles components.
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_profiles_components.dart';
import '../widgets/zyra_swipe_track.dart';

class ZyraGuardianInfoPresentation extends StatefulWidget {
  const ZyraGuardianInfoPresentation({
    super.key,
    required this.mainGuardian,
    required this.canAct,
    required this.onManage,
    required this.onMove,
  });
  final String mainGuardian;
  final bool Function() canAct;
  final VoidCallback onManage, onMove;
  @override
  State<ZyraGuardianInfoPresentation> createState() =>
      _ZyraGuardianInfoPresentationState();
}

class _ZyraGuardianInfoPresentationState
    extends State<ZyraGuardianInfoPresentation> {
  final _controller = ZyraSwipeController();
  int _index = 0;
  int _render = 0;
  void _move(int next) => _controller.animateTo(next);

  @override
  Widget build(BuildContext context) {
    final render = ++_render, authority = widget.canAct;
    bool current() => mounted && render == _render && authority();
    final cards =
        <({IconData icon, String title, String subtitle, List<String> rows})>[
          (
            icon: Icons.verified_user_outlined,
            title: 'Your Main Guardian',
            subtitle: widget.mainGuardian,
            rows: [
              'Is part of every Journey you begin',
              'Sees your Journey requests — sent and received — and who each is with',
              'Sees that person’s profile as anyone browsing would',
              'Decides each 48-hour Family Review',
            ],
          ),
          (
            icon: Icons.groups_outlined,
            title: 'Your Additional Guardians',
            subtitle: 'You choose, Journey by Journey',
            rows: [
              'See a Journey only if you switch View on',
              'Write in it only if you switch Chat on and they have Guardian One',
              'Don’t see your Journey requests',
            ],
          ),
          (
            icon: Icons.people_outline,
            title: 'Other Seekers’ Guardians',
            subtitle: 'When you send someone a request',
            rows: [
              'Their Main Guardian sees that you asked to begin a Journey',
              'They see your profile as anyone browsing would',
              'Nothing more',
            ],
          ),
          (
            icon: Icons.visibility_off_outlined,
            title: 'No Guardian ever sees',
            subtitle: 'Yours stays yours',
            rows: [
              'Your private answers',
              'Your Compatibility Unlock details',
              'Your past Journey summaries — unless you switch that on for them',
            ],
          ),
        ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZyraDeveloperTitle(
              child: Text('What Guardians can do', style: ZyraText.pageTitle()),
            ),
            const SizedBox(height: 20),
            ZyraProfilesDots(
              count: 4,
              index: _index,
              dotKey: (i) => ValueKey('guardian_info_dot_$i'),
              targetKey: (i) => ValueKey('guardian_info_dot_target_$i'),
              canAct: current,
              onSelected: (i) {
                if (current()) _move(i);
              },
            ),
            Expanded(
              child: ZyraSwipeTrack(
                key: const ValueKey('guardian_info_cards'),
                controller: _controller,
                index: _index,
                itemCount: cards.length,
                canAct: current,
                onSettled: (index) {
                  setState(() => _index = index);
                  widget.onMove();
                },
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Semantics(
                    label: '${card.title}, card ${index + 1} of 4',
                    container: true,
                    child: LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: ZyraTapFeedback.onChanged(
                          context,
                          (details) => _move(
                            index +
                                (details.localPosition.dx >=
                                        constraints.maxWidth / 2
                                    ? 1
                                    : -1),
                          ),
                        ),
                        child: ZyraProfilesDetailsContent(
                          borderRadius: BorderRadius.circular(
                            ZyraCardMetrics.cardRadius,
                          ),
                          scrollKey: ValueKey('guardian_info_scroll_$index'),
                          children: [
                            ExcludeSemantics(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ZyraColors.journeyGold.withValues(
                                      alpha: .65,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ZyraColors.journeyGold.withValues(
                                        alpha: .07,
                                      ),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  card.icon,
                                  size: 29,
                                  color: ZyraColors.journeyGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            ExcludeSemantics(
                              child: Text(
                                card.title,
                                textAlign: TextAlign.center,
                                style: ZyraText.heading(size: 34),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card.subtitle,
                              textAlign: TextAlign.center,
                              style: ZyraText.body(
                                size: 14,
                                color: ZyraColors.goldText,
                              ),
                            ),
                            const SizedBox(height: 24),
                            for (final row in card.rows)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: ZyraColors.ink(.13)),
                                  ),
                                ),
                                child: Text(
                                  row,
                                  style: ZyraText.body(size: 14),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ZyraProfilesBottomRow(
              previous: zyraProfilesPill(
                key: const ValueKey('guardian_info_previous'),
                label: 'Previous card',
                icon: Icons.chevron_left,
                onTap: _index == 0 || !current()
                    ? null
                    : () {
                        if (current()) _move(_index - 1);
                      },
              ),
              action: zyraProfilesPill(
                key: const ValueKey('guardian_info_manage'),
                label: 'Manage your Guardians',
                primary: true,
                onTap: () {
                  if (widget.canAct()) widget.onManage();
                },
              ),
              next: zyraProfilesPill(
                key: const ValueKey('guardian_info_next'),
                label: 'Next card',
                icon: Icons.chevron_right,
                iconSize: 24,
                onTap: _index == 3 || !current()
                    ? null
                    : () {
                        if (current()) _move(_index + 1);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
