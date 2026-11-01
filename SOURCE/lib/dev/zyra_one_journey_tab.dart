import '../widgets/zyra_state_widgets.dart';
import '../widgets/zyra_floating_surface.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_journey_icon.dart';
import '../widgets/zyra_profiles_components.dart';
import '../widgets/zyra_tap_feedback.dart';

/// LOCK 13 V2 display facts. Ordering, stage and timer authority stay with the
/// local Journey owner; this widget never reads or changes a relationship.
@immutable
class ZyraJourneyTabCard {
  const ZyraJourneyTabCard({
    required this.id,
    required this.firstName,
    required this.details,
    required this.stageNumber,
    required this.stageLabel,
    required this.nextStep,
    this.photo,
    this.unavailable = false,
  });

  final String id, firstName, details, stageLabel, nextStep;
  final int stageNumber;
  final ImageProvider? photo;
  final bool unavailable;
}

/// The LOCK 13 photo surface, reused by Guardian Journeys (LOCK 8 V5).
/// Callers supply display content and retain all action/permission authority.
class ZyraJourneyPhotoCard extends StatelessWidget {
  const ZyraJourneyPhotoCard({
    super.key,
    required this.surfaceKey,
    required this.scrollKey,
    required this.children,
    this.photo,
    this.fadeStart = .3,
    this.fadeTop = Colors.transparent,
  });
  final Key surfaceKey, scrollKey;
  final ImageProvider? photo;
  final List<Widget> children;
  // Defaults retain LOCK 13; expanded Guardian text may occupy the full photo.
  final double fadeStart;
  final Color fadeTop;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 22,
    circle: false,
    gold: false,
    child: Container(
      key: surfaceKey,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(22),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ZyraColors.journeyGold.withValues(alpha: .6)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image(image: photo!, fit: BoxFit.cover)
            else
              Center(
                child: ZyraJourneyIcon(color: ZyraColors.ink(.35), size: 64),
              ),
            Positioned(
              top: constraints.maxHeight * fadeStart,
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [fadeTop, const Color(0xE6000000)],
                  ),
                ),
              ),
            ),
            ZyraShadowScrollView(
              key: scrollKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A bounded, caller-controlled pager: a place per card and no wrap at the ends.
/// Every retained callback expires on a rebuild or page move, including an
/// index/account/route round trip back to the same displayed person.
class ZyraOneJourneyTab extends StatefulWidget {
  const ZyraOneJourneyTab({
    super.key,
    required this.journeys,
    required this.capacity,
    required this.index,
    required this.onIndexChanged,
    required this.onContinue,
    required this.onOptions,
    required this.onBrowse,
    required this.onPlans,
    required this.sessionIdentity,
    this.onEndUnavailable,
  }) : assert(capacity == 1 || capacity == 3);

  final List<ZyraJourneyTabCard> journeys;
  final int capacity, index;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onContinue, onOptions, onBrowse, onPlans;
  final VoidCallback? onEndUnavailable;
  final Object sessionIdentity;

  @override
  State<ZyraOneJourneyTab> createState() => _ZyraOneJourneyTabState();
}

class _ZyraOneJourneyTabState extends State<ZyraOneJourneyTab> {
  int _revision = 0;
  double _dragDistance = 0;

  void _page(int target, bool Function() current) {
    if (!current() || target < 0 || target >= widget.capacity) return;
    // Expire the outgoing card synchronously, before the owner's next frame.
    setState(() => _revision++);
    widget.onIndexChanged(target);
  }

  Widget _button({
    required String key,
    required String label,
    required VoidCallback action,
    required bool Function() current,
    bool filled = false,
    bool outline = false,
    Color? color,
  }) => ZyraFloatingSurface(
    radius: 999,
    circle: false,
    gold: true,
    child: Material(
      color: filled ? ZyraColors.goldTextFill : Colors.transparent,
      shape: StadiumBorder(
        side: outline
            ? BorderSide(color: ZyraColors.journeyGold.withValues(alpha: .7))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(key),
        onTap: ZyraTapFeedback.onTap(context, action, canAct: current),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: filled ? 52 : 44),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: outline ? 16 : 20,
              vertical: 10,
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style:
                    ZyraText.body(
                      size: outline ? 13 : 14,
                      color:
                          color ??
                          (filled
                              ? ZyraColors.luxuryDarkPurple
                              : ZyraColors.goldText),
                    ).copyWith(
                      fontWeight: filled ? FontWeight.w500 : FontWeight.w300,
                    ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _upsell(bool Function() current) => _DashedJourneySurface(
    key: const ValueKey('journey_tab_upsell'),
    child: ZyraShadowScrollView(
      key: const ValueKey('journey_tab_upsell_scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 20,
            color: ZyraColors.journeyGold,
          ),
          const SizedBox(height: 12),
          Text(
            'More Journeys come with Seeker One',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Up to 3 at once.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 12, color: ZyraColors.ink(.65)),
          ),
          const SizedBox(height: 8),
          _button(
            key: 'journey_tab_plans',
            label: 'See Seeker One ›',
            action: widget.onPlans,
            current: current,
          ),
        ],
      ),
    ),
  );

  Widget _empty(bool Function() current) => LayoutBuilder(
    builder: (context, constraints) => ZyraShadowScrollView(
      key: const ValueKey('journey_tab_empty_scroll'),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZyraEmptyState(
                icon: Icons.route_outlined,
                iconWidget: const ZyraJourneyIcon(
                  size: 34,
                  color: ZyraColors.journeyGold,
                ),
                title: 'No Journey yet',
                titleKey: const ValueKey('journey_tab_empty_title'),
                message:
                    'You have ${widget.capacity} ${widget.capacity == 1 ? 'place' : 'places'}. '
                    'Send a Journey request from Profiles to begin.',
                ctaLabel: 'Browse profiles',
                ctaKey: const ValueKey('journey_tab_browse'),
                onCta: widget.onBrowse,
                canAct: current,
              ),
              if (widget.capacity == 1) ...[
                const SizedBox(height: 14),
                _upsell(current),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _freePlace(bool Function() current) => _DashedJourneySurface(
    child: LayoutBuilder(
      builder: (context, constraints) => ZyraShadowScrollView(
        key: const ValueKey('journey_tab_free_scroll'),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  painter: _JourneyDashedBorder(
                    color: ZyraColors.journeyGold.withValues(alpha: .65),
                    radius: 24,
                  ),
                  child: const SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: 26,
                        color: ZyraColors.journeyGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Free place', style: ZyraText.body(size: 15)),
                const SizedBox(height: 6),
                Text(
                  'When you and someone both agree, your Journey starts here.',
                  textAlign: TextAlign.center,
                  style: ZyraText.body(size: 12, color: ZyraColors.ink(.65)),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 140,
                  child: _button(
                    key: 'journey_tab_browse',
                    label: 'Browse profiles',
                    action: widget.onBrowse,
                    current: current,
                    outline: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _journey(
    ZyraJourneyTabCard card,
    int index,
    bool Function() current,
  ) => Semantics(
    container: true,
    label: card.unavailable
        ? 'User not found, ${index + 1} of ${widget.capacity}'
        : 'Journey with ${card.firstName}, ${card.stageNumber > 0 ? 'stage ${card.stageNumber} of 8, ' : ''}'
              '${card.stageLabel}, ${card.nextStep.replaceAll(' · ', ' ')}, '
              '${index + 1} of ${widget.capacity}',
    excludeSemantics: !card.unavailable,
    child: ZyraJourneyPhotoCard(
      surfaceKey: ValueKey('journey_tab_person_${card.id}'),
      scrollKey: ValueKey('journey_tab_overlay_scroll_${card.id}'),
      photo: card.unavailable ? null : card.photo,
      children: [
        if (!card.unavailable)
          Text(
            card.stageNumber > 0
                ? 'Stage ${card.stageNumber} of 8 · ${card.stageLabel}'
                : card.stageLabel,
            style: ZyraText.body(size: 12.5, color: Colors.white),
          ),
        const SizedBox(height: 6),
        Text(
          card.unavailable ? 'User not found' : card.firstName,
          style: ZyraText.heading(size: 30, color: Colors.white),
        ),
        if (card.unavailable) ...[
          const SizedBox(height: 8),
          Text(
            'This Journey place is retained. The profile and conversation are unavailable.',
            style: ZyraText.body(color: Colors.white.withValues(alpha: .7)),
          ),
          if (widget.onEndUnavailable != null) ...[
            const SizedBox(height: 12),
            _button(
              key: 'journey_tab_end_unavailable',
              label: 'End Journey',
              action: widget.onEndUnavailable!,
              current: current,
              color: ZyraColors.destructive,
            ),
          ],
        ],
        const SizedBox(height: 2),
        if (!card.unavailable)
          Text(
            card.details,
            style: ZyraText.body(size: 15, color: Colors.white),
          ),
        const SizedBox(height: 12),
        if (!card.unavailable && card.stageNumber > 0)
          Row(
            children: [
              for (var stage = 1; stage <= 8; stage++) ...[
                if (stage > 1) const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: stage <= card.stageNumber
                          ? ZyraColors.journeyGold
                          : Colors.white.withValues(alpha: .2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 6),
        if (!card.unavailable)
          Text(
            card.nextStep,
            style: ZyraText.body(
              size: 12,
              color: Colors.white.withValues(alpha: .75),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final revision = ++_revision;
    final identity = widget.sessionIdentity;
    final index = widget.index.clamp(0, widget.capacity - 1);
    final card = index < widget.journeys.length ? widget.journeys[index] : null;
    final parentFeedback = context
        .dependOnInheritedWidgetOfExactType<ZyraTapFeedback>();
    bool current() =>
        mounted &&
        revision == _revision &&
        identical(identity, widget.sessionIdentity);
    return ZyraTapFeedback(
      level: parentFeedback?.level ?? () => ZyraInteractionStyle.hapticLevel,
      canAct: () => current() && (parentFeedback?.canAct() ?? true),
      child: Builder(
        builder: (context) => SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 98),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Journey', style: ZyraText.pageTitle()),
                      ),
                      if (card != null && !card.unavailable)
                        SizedBox.square(
                          dimension: 44,
                          child: IconButton(
                            key: ValueKey('draft_journey_options_${card.id}'),
                            tooltip: 'Journey options for ${card.firstName}',
                            onPressed: ZyraTapFeedback.onTap(
                              context,
                              widget.onOptions,
                              canAct: current,
                            ),
                            icon: const Icon(
                              Icons.more_horiz,
                              color: ZyraColors.journeyGold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.journeys.isEmpty)
                  Expanded(child: _empty(current))
                else ...[
                  SizedBox(
                    height: 28,
                    child: Center(
                      child: ZyraProfilesDots(
                        count: widget.capacity,
                        index: index,
                        dotKey: (i) => ValueKey('journey_tab_dot_$i'),
                        activeWidth: 30,
                        size: 6,
                        lift: 0,
                        canAct: current,
                        onSelected: (value) => _page(value, current),
                        targetKey: (i) => ValueKey('journey_tab_dot_target_$i'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      key: const ValueKey('journey_tab_card'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => _dragDistance = 0,
                      onHorizontalDragUpdate: (details) {
                        if (current()) {
                          _dragDistance += details.primaryDelta ?? 0;
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        if (!current()) return;
                        final velocity = details.primaryVelocity ?? 0;
                        if (_dragDistance.abs() < 24 && velocity.abs() < 100) {
                          return;
                        }
                        final direction = velocity.abs() >= 100
                            ? velocity
                            : _dragDistance;
                        _page(index + (direction < 0 ? 1 : -1), current);
                      },
                      child: card == null
                          ? _freePlace(current)
                          : _journey(card, index, current),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ZyraProfilesRequestRow(
                    actionKey: const ValueKey('journey_tab_continue'),
                    label: card == null
                        ? 'Browse profiles'
                        : 'Continue Journey',
                    labels: const ['Continue Journey', 'Browse profiles'],
                    sent: false,
                    previousKey: const ValueKey('journey_tab_previous'),
                    nextKey: const ValueKey('journey_tab_next'),
                    previousLabel: 'Previous Journey place',
                    nextLabel: 'Next Journey place',
                    onPrevious: index > 0
                        ? () => _page(index - 1, current)
                        : null,
                    onNext: index < widget.capacity - 1
                        ? () => _page(index + 1, current)
                        : null,
                    onRequest: card?.unavailable == true
                        ? null
                        : () {
                            if (current()) {
                              (card == null
                                  ? widget.onBrowse
                                  : widget.onContinue)();
                            }
                          },
                  ),
                  if (widget.capacity == 1) ...[
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                        height: math.min(
                          144.0,
                          MediaQuery.sizeOf(context).height * .2,
                        ),
                        child: _upsell(current),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedJourneySurface extends StatelessWidget {
  const _DashedJourneySurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _JourneyDashedBorder(color: ZyraColors.surfaceBorder),
    child: ZyraFloatingSurface(
      radius: 22,
      circle: false,
      gold: false,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      ),
    ),
  );
}

class _JourneyDashedBorder extends CustomPainter {
  const _JourneyDashedBorder({required this.color, this.radius = 22});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var offset = 0.0; offset < metric.length; offset += 5) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 3, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_JourneyDashedBorder oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
