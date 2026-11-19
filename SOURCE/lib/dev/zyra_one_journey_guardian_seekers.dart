// LOCK 35: caller-owned fictional Seekers, using the LOCK 26 swipe track.
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_motion.dart';
import '../theme/zyra_preview_spacing.dart';
import '../theme/zyra_text.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_profiles_components.dart';
import '../widgets/zyra_swipe_track.dart';
import '../widgets/zyra_tab_title.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_one_journey_monogram_presentation.dart';

class ZyraGuardianSeekersPager extends StatefulWidget {
  const ZyraGuardianSeekersPager({
    super.key,
    required this.linked,
    required this.selectedSeeker,
    required this.adamMain,
    required this.adamMembership,
    required this.adamJourney,
    required this.onAction,
    required this.canAct,
    required this.identity,
  });
  final bool linked, adamMain;
  final int selectedSeeker;
  final String adamMembership;
  final String? adamJourney;
  final ValueChanged<String> onAction;
  final bool Function() canAct;
  final Object? identity;

  @override
  State<ZyraGuardianSeekersPager> createState() =>
      _ZyraGuardianSeekersPagerState();
}

class _ZyraGuardianSeekersPagerState extends State<ZyraGuardianSeekersPager> {
  final _track = ZyraSwipeController();
  late int _index;
  int _revision = 0;
  int get _people => widget.linked ? 2 : 0;

  @override
  void initState() {
    super.initState();
    _index = widget.linked ? widget.selectedSeeker : 0;
  }

  @override
  void didUpdateWidget(ZyraGuardianSeekersPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.linked != widget.linked ||
        oldWidget.selectedSeeker != widget.selectedSeeker) {
      _index = widget.linked ? widget.selectedSeeker : 0;
      _revision++;
    }
  }

  VoidCallback _action(String action, {int? card}) {
    final revision = _revision;
    final callback = widget.onAction;
    final admitted = widget.canAct;
    return () {
      if (!mounted ||
          revision != _revision ||
          !admitted() ||
          _track.isMoving ||
          (card != null && card != _index)) {
        return;
      }
      callback(action);
    };
  }

  void _select(int index) {
    if (!widget.canAct() || index < 0 || index > _people) return;
    setState(() {
      _index = index;
      _revision++;
    });
    // Invite is a page, never a third Seeker or a Circle identity.
    widget.onAction('seekers_select_$index');
  }

  Widget _round(String key, IconData icon, String label, String action) =>
      ZyraFloatingSurface(
        circle: true,
        child: SizedBox.square(
          dimension: 38,
          child: Material(
            color: ZyraColors.cardSurface,
            shape: const CircleBorder(),
            child: IconButton(
              key: ValueKey(key),
              tooltip: label,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              onPressed: ZyraTapFeedback.onTap(context, _action(action)),
              icon: Icon(icon, size: 20, color: ZyraColors.foreground),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        ZyraPreviewSpacing.pageMargin,
        16,
        ZyraPreviewSpacing.pageMargin,
        ZyraNavBarMetrics.contentBottomClearance(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            key: const ValueKey('guardian_seekers_title_block'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: ZyraTabTitle('Seekers')),
              _round(
                'guardian_seekers_chat',
                Icons.forum_outlined,
                'Guardian Circle',
                'circle',
              ),
              const SizedBox(width: 10),
              _round(
                'guardian_invite',
                Icons.add,
                'Invite your Seeker',
                'invite',
              ),
            ],
          ),
          const SizedBox(height: ZyraPreviewSpacing.titleToDots),
          ZyraProfilesDots(
            count: _people + 1,
            index: _index,
            dotKey: (i) => ValueKey('guardian_seekers_dot_$i'),
            targetKey: (i) => ValueKey('guardian_seekers_dot_target_$i'),
            itemLabel: (i) => i == _people ? 'Invite a Seeker' : _name(i),
            canAct: widget.canAct,
            canSelect: () => !_track.isMoving,
            onSelected: _track.animateTo,
            exposeSemanticAction: true,
          ),
          const SizedBox(height: 3),
          Expanded(
            child: ZyraSwipeTrack(
              key: const ValueKey('guardian_seekers_track'),
              controller: _track,
              index: _index,
              itemCount: _people + 1,
              canAct: widget.canAct,
              motionIdentity: widget.identity,
              onSettled: _select,
              onDragSettled: ZyraTapFeedback.onTap(context, () {}),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _surface(i, i == _people ? _invite(i) : _seeker(i)),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _name(int i) => i == 0 ? 'Adam' : 'Yusuf';

  Widget _surface(int i, Widget child) => ZyraFloatingSurface(
    radius: 22,
    child: Material(
      key: ValueKey('guardian_seekers_card_$i'),
      color: ZyraColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: ZyraColors.surfaceBorder),
      ),
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          key: ValueKey('guardian_seekers_content_$i'),
          primary: false,
          physics: ZyraMotion.fixedCardScrollPhysics,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        ),
      ),
    ),
  );

  Text _text(String value, double size, {bool muted = false}) => Text(
    value,
    style: ZyraText.body(
      size: size,
      color: muted ? ZyraColors.secondaryText : ZyraColors.foreground,
    ),
  );

  Widget _details(int i, String label, String value) => InkWell(
    onTap: ZyraTapFeedback.onTap(context, _action('seeker_$i', card: i)),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ZyraColors.ink(.12))),
      ),
      child: Row(
        children: [
          Expanded(child: _text(label, 14, muted: true)),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: _text(value, 14),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _seeker(int i) {
    final name = _name(i);
    final journey = i == 0 ? widget.adamJourney : null;
    final parts = journey?.split(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ZyraGoldRingMonogram(name: name, size: 76, fontSize: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: ZyraText.heading(
                        size: 30,
                      ).copyWith(fontWeight: FontWeight.w300, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i == 0 && widget.adamMain
                          ? 'YOU ARE HIS MAIN GUARDIAN'
                          : 'ADDITIONAL GUARDIAN',
                      style: ZyraText.body(
                        size: 11,
                        color: ZyraColors.goldText,
                      ).copyWith(letterSpacing: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          KeyedSubtree(
            key: ValueKey('guardian_seeker_$i'),
            child: _details(i, 'Relationship', 'Father'),
          ),
          _details(
            i,
            'Membership',
            i == 0 ? widget.adamMembership : 'Seeker Basic',
          ),
          _details(i, 'Linked', i == 0 ? '20 Sep 2026' : '02 Oct 2026'),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'CURRENT JOURNEY',
              style: ZyraText.body(
                size: 11,
                color: ZyraColors.goldText,
              ).copyWith(letterSpacing: 1.3),
            ),
          ),
          InkWell(
            key: ValueKey('guardian_seekers_journey_$i'),
            onTap: ZyraTapFeedback.onTap(
              context,
              _action(
                journey == null ? 'seeker_$i' : 'seekers_journey_$i',
                card: i,
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 76),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: ZyraColors.ink(.12)),
                ),
              ),
              child: journey == null
                  ? Center(child: _text('No current Journey', 14, muted: true))
                  : Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: ZyraColors.journeyGold,
                          size: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _text(parts!.first, 17),
                              const SizedBox(height: 2),
                              _text(
                                parts.skip(1).join(' · '),
                                12.5,
                                muted: true,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: ZyraColors.ink(.3),
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
          const Spacer(),
          InkWell(
            key: ValueKey('guardian_seekers_circle_$i'),
            onTap: ZyraTapFeedback.onTap(
              context,
              _action('seekers_circle_$i', card: i),
            ),
            child: Container(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ZyraColors.ink(.12))),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    color: ZyraColors.journeyGold,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _text('$name’s Guardian Circle', 15)),
                  Icon(
                    Icons.chevron_right,
                    color: ZyraColors.ink(.3),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invite(int i) => InkWell(
    key: const ValueKey('guardian_seekers_invite_card'),
    onTap: ZyraTapFeedback.onTap(context, _action('invite', card: i)),
    borderRadius: BorderRadius.circular(22),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZyraGoldRingMonogram(
            name: '+',
            size: 104,
            fontSize: 44,
            child: Icon(Icons.add, size: 44, color: ZyraColors.journeyGold),
          ),
          const SizedBox(height: 14),
          _text('Invite a Seeker', 20),
          const SizedBox(height: 14),
          _text('You can support up to 10 Seekers', 12.5, muted: true),
        ],
      ),
    ),
  );
}
