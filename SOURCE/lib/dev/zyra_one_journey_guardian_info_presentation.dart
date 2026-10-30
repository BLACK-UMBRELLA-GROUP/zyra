// LOCK 3: local Founder preview education, using current Profiles components.
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_profiles_components.dart';

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
  final _controller = PageController();
  int _index = 0;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int next) {
    if (!widget.canAct() || next < 0 || next > 3 || next == _index) return;
    _controller.animateToPage(
      next,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text('What Guardians can do', style: ZyraText.pageTitle()),
            const SizedBox(height: 20),
            SizedBox(
              height: 16,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        key: ValueKey('guardian_info_dot_$i'),
                        width: i == _index ? 20 : 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _index
                              ? ZyraColors.journeyGold
                              : ZyraColors.ink(.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
                child: PageView.builder(
                  key: const ValueKey('guardian_info_cards'),
                  controller: _controller,
                  itemCount: 4,
                  onPageChanged: (index) {
                    if (!widget.canAct()) return;
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
                                        color: ZyraColors.journeyGold
                                            .withValues(alpha: .07),
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
                                  color: ZyraColors.journeyGold,
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
                                      top: BorderSide(
                                        color: ZyraColors.ink(.13),
                                      ),
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
            ),
            const SizedBox(height: 16),
            ZyraProfilesBottomRow(
              previous: zyraProfilesPill(
                key: const ValueKey('guardian_info_previous'),
                label: 'Previous card',
                icon: Icons.chevron_left,
                onTap: _index == 0 ? null : () => _move(_index - 1),
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
                onTap: _index == 3 ? null : () => _move(_index + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
