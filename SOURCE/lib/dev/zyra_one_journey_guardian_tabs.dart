import '../widgets/floating_nav_bar.dart';
import '../widgets/zyra_floating_surface.dart';
// LOCK 8 V3 / LOCK 15 V2: fictional Guardian presentation only. No service, RPC or member
// authority. The admitted shell owns changes and the lifetime of callbacks.
import 'package:flutter/material.dart';
import '../theme/zyra_motion.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_preview_spacing.dart';
import '../theme/zyra_text.dart';
import '../theme/zyra_interaction_style.dart';
import '../widgets/zyra_tab_title.dart';
import '../widgets/zyra_tap_feedback.dart';
import '../widgets/zyra_state_widgets.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_seeker_avatar.dart';
import '../widgets/zyra_focus_dashboard.dart';
import '../widgets/zyra_profiles_components.dart';
import '../widgets/zyra_swipe_track.dart';
import 'zyra_one_journey_tab.dart' show ZyraJourneyPhotoCard;
import 'zyra_one_journey_guardian_seeker.dart';
import 'zyra_one_journey_guardian_action.dart';
import 'zyra_one_journey_monogram_presentation.dart';
import 'zyra_guardian_family_preview.dart';
import 'zyra_view_request_draft_model.dart' show DraftProfile;
import '../screens/wali/family_messaging_screens.dart'
    show ZyraFamilyMessageComposer;

enum ZyraGuardianReview { open, paused, continued }

enum ZyraGuardianConnection { pending, accepted, dismissed, blocked, none }

class ZyraGuardianTabsSnapshot {
  const ZyraGuardianTabsSnapshot({
    this.review = ZyraGuardianReview.open,
    this.hours = 41,
    this.reviewRevision = 0,
    this.connection = ZyraGuardianConnection.none,
    this.seeker = 0,
    this.requestSeeker = 0,
    this.requestsSent = false,
    this.connectReceived = false,
    this.networkIndex = 0,
    this.introduced = const {},
    this.sent = const {},
    this.attentionSeen = false,
    this.focusIndex = 0,
    this.consumedFocus = const {},
    this.freePlaceInviteExpiresAt,
  });
  // The existing fictional Family Review is already seen at startup.
  const ZyraGuardianTabsSnapshot.quiet()
    : this(consumedFocus: const {'review-open-0'});

  final ZyraGuardianReview review;
  final ZyraGuardianConnection connection;
  final int hours, seeker, requestSeeker, networkIndex, reviewRevision;
  final bool requestsSent, connectReceived, attentionSeen;
  final Set<String> introduced, sent, consumedFocus;
  final int focusIndex;
  final DateTime? freePlaceInviteExpiresAt;
}

class ZyraGuardianTabsState {
  ZyraGuardianTabsState([
    ZyraGuardianTabsSnapshot saved = const ZyraGuardianTabsSnapshot.quiet(),
  ]) : freePlaceInviteExpiresAt = saved.freePlaceInviteExpiresAt {
    review = saved.review;
    hours = saved.hours.clamp(0, 48);
    reviewRevision = saved.reviewRevision < 0 ? 0 : saved.reviewRevision;
    connection = saved.connection;
    seeker = saved.seeker.clamp(0, 1);
    requestSeeker = saved.requestSeeker.clamp(0, 2);
    requestsSent = saved.requestsSent;
    connectReceived = saved.connectReceived;
    networkIndex = saved.networkIndex.clamp(0, network.length - 1);
    introduced.addAll(
      saved.introduced.where(
        (id) => RegExp(r'^(adam|yusuf):(aisha|noor)$').hasMatch(id),
      ),
    );
    sent.addAll(saved.sent.where(validId));
    attentionSeen = saved.attentionSeen;
    focusIndex = saved.focusIndex < 0 ? 0 : saved.focusIndex;
    consumedFocus.addAll(saved.consumedFocus);
  }
  // Basic-only families are excluded before any Network card can be selected.
  static const candidates = [
    (id: 'aisha', name: 'Aisha', age: 29, city: 'London', guardianOne: true),
    (
      id: 'basic-only',
      name: 'Basic-only sample',
      age: 27,
      city: 'York',
      guardianOne: false,
    ),
    (id: 'noor', name: 'Noor', age: 25, city: 'Nottingham', guardianOne: true),
  ];
  static final network = candidates
      .where((p) => p.guardianOne)
      .toList(growable: false);
  static bool validId(String id) => network.any((p) => p.id == id);
  late ZyraGuardianReview review;
  late ZyraGuardianConnection connection;
  late int hours, seeker, requestSeeker, networkIndex, reviewRevision;
  late bool requestsSent, connectReceived, attentionSeen;
  final introduced = <String>{}, sent = <String>{}, consumedFocus = <String>{};
  late int focusIndex;
  // Explicitly seeded Founder sample. Never inferred from linked Guardians.
  final DateTime? freePlaceInviteExpiresAt;
  static const freePlaceInviteFocus = 'free-place-invite';
  String get reviewFocusId =>
      'review-${review == ZyraGuardianReview.paused ? 'paused' : 'open'}-$reviewRevision';
  String get seekerName => seeker == 0 ? 'Adam' : 'Yusuf';
  bool get main => seeker == 0;
  bool get canPrevious => networkIndex > 0;
  bool get canNext => networkIndex < network.length - 1;
  bool get hasUnseenReview =>
      review != ZyraGuardianReview.continued &&
      !consumedFocus.contains(reviewFocusId);
  bool get hasUnseenConnection =>
      connection == ZyraGuardianConnection.pending &&
      !consumedFocus.contains('connect-pending');
  bool get needsYou => hasUnseenReview || hasUnseenConnection;
  int get receivedCount =>
      connection == ZyraGuardianConnection.pending ||
          connection == ZyraGuardianConnection.accepted
      ? 1
      : 0;
  String get stage => switch (review) {
    ZyraGuardianReview.open => 'Family Review',
    ZyraGuardianReview.paused => 'Paused by family',
    ZyraGuardianReview.continued => 'Building a Life',
  };
  String get stageLine =>
      'Stage ${review == ZyraGuardianReview.continued ? 5 : 4} of 8 · $stage';
  String get introducedKey =>
      '${seekerName.toLowerCase()}:${network[networkIndex].id}';
  bool introducedForCurrent() => introduced.contains(introducedKey);
  int get introductionCount => introduced
      .where((id) => id.startsWith('${seekerName.toLowerCase()}:'))
      .length;
  ZyraGuardianTabsSnapshot get snapshot => ZyraGuardianTabsSnapshot(
    review: review,
    hours: hours,
    reviewRevision: reviewRevision,
    connection: connection,
    seeker: seeker,
    requestSeeker: requestSeeker,
    requestsSent: requestsSent,
    connectReceived: connectReceived,
    networkIndex: networkIndex,
    introduced: Set.unmodifiable(introduced),
    sent: Set.unmodifiable(sent),
    attentionSeen: attentionSeen,
    focusIndex: focusIndex,
    consumedFocus: Set.unmodifiable(consumedFocus),
    freePlaceInviteExpiresAt: freePlaceInviteExpiresAt,
  );
}

/// Display facts projected by the admitted shell; this card grants no access.
class ZyraGuardianJourneyCard {
  const ZyraGuardianJourneyCard({
    required this.id,
    required this.title,
    required this.details,
    required this.stageLine,
    this.photo,
  });
  final String id, title, details, stageLine;
  final ImageProvider? photo;
}

class ZyraGuardianJourneyPager extends StatefulWidget {
  const ZyraGuardianJourneyPager({
    super.key,
    required this.cards,
    required this.index,
    required this.identity,
    required this.onAction,
  }) : assert(cards.length > 0);
  final List<ZyraGuardianJourneyCard> cards;
  final int index;
  final Object? identity;
  final ValueChanged<String> onAction;

  @override
  State<ZyraGuardianJourneyPager> createState() => _GuardianJourneyPagerState();
}

class _GuardianJourneyPagerState extends State<ZyraGuardianJourneyPager> {
  int _revision = 0;
  final _track = ZyraSwipeController();

  @override
  Widget build(BuildContext context) {
    final revision = ++_revision;
    final identity = widget.identity;
    final index = widget.index.clamp(0, widget.cards.length - 1);
    final expandedText = MediaQuery.textScalerOf(context).scale(13) > 16;
    final feedback = context
        .dependOnInheritedWidgetOfExactType<ZyraTapFeedback>();
    var revoked = false;
    bool current() {
      if (revoked) return false;
      if (!mounted ||
          revision != _revision ||
          !identical(identity, widget.identity) ||
          !(feedback?.canAct() ?? true)) {
        revoked = true;
        return false;
      }
      return true;
    }

    void select(int target) {
      if (!current() ||
          target == index ||
          target < 0 ||
          target >= widget.cards.length) {
        return;
      }
      setState(() => _revision++);
      widget.onAction('journey_select_${widget.cards[target].id}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Center(
            child: ZyraProfilesDots(
              count: widget.cards.length,
              index: index,
              dotKey: (i) => ValueKey('guardian_journey_dot_$i'),
              targetKey: (i) => ValueKey('guardian_journey_dot_target_$i'),
              canAct: current,
              onSelected: (target) {
                if (current()) _track.animateTo(target);
              },
            ),
          ),
        ),
        // The 6 pt dot ends 9 pt before the end of its touch slot.
        const SizedBox(height: 3),
        Expanded(
          child: ZyraSwipeTrack(
            key: const ValueKey('guardian_journey_card'),
            controller: _track,
            index: index,
            itemCount: widget.cards.length,
            motionIdentity: widget.cards.map((card) => card.id).join(','),
            canAct: current,
            onSettled: select,
            itemBuilder: (context, page) {
              final card = widget.cards[page];
              return Semantics(
                container: true,
                label:
                    '${card.title}, ${card.stageLine}, ${page + 1} of ${widget.cards.length}',
                child: ZyraJourneyPhotoCard(
                  surfaceKey: ValueKey('guardian_journey_person_${card.id}'),
                  scrollKey: ValueKey('guardian_journey_overlay_${card.id}'),
                  photo: card.photo,
                  fadeStart: expandedText ? 0 : .3,
                  fadeTop: expandedText
                      ? const Color(0xA6000000)
                      : Colors.transparent,
                  children: [
                    Text(
                      card.stageLine.toUpperCase(),
                      key: const ValueKey('guardian_journey_stage'),
                      style: ZyraText.body(
                        size: 11,
                        color: Colors.white,
                      ).copyWith(letterSpacing: 1.1, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card.title,
                      style: ZyraText.heading(
                        size: 28,
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w300, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.details,
                      style: ZyraText.body(
                        size: 13,
                        color: Colors.white.withValues(alpha: .78),
                      ).copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('guardian_journey'),
                      onPressed: ZyraTapFeedback.onTap(context, () {
                        if (!current() || page != index || _track.isMoving) {
                          return;
                        }
                        setState(() => _revision++);
                        widget.onAction('journey_open_${card.id}');
                      }, canAct: current),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        backgroundColor: ZyraColors.goldTextFill,
                        foregroundColor: ZyraColors.foreground,
                        textStyle: ZyraText.body(size: 14),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Open Journey'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ZyraGuardianTabsPresentation extends StatelessWidget {
  const ZyraGuardianTabsPresentation({
    super.key,
    required this.state,
    required this.page,
    required this.onAction,
    required this.photoFor,
    this.adamPhoto,
    this.adamAvatarAlignment = Offset.zero,
    required this.seekerGender,
    this.currentSeekerJourney,
    this.currentSeekerJourneyId,
    this.linked = true,
    this.linkedSeekerNames = const ['Adam', 'Yusuf'],
    this.paid = true,
    this.adamMain = true,
    this.focusItems,
    this.circleFocus = const [],
    this.notificationCount = 0,
    this.newJourneyRequestCount = 0,
    this.receivedJourneyRequests = const [],
    this.sentJourneyRequests = const [],
    this.tabClearance = false,
    this.canInteract,
    this.journeys = const [],
    this.journeyIndex = 0,
    this.journeyIdentity,
    this.familyOffer,
    this.freePlaceInvite = false,
    this.familyCanAct,
  });
  final ZyraGuardianTabsState state;
  final String page, seekerGender;
  final String? currentSeekerJourney, currentSeekerJourneyId;
  final ValueChanged<String> onAction;
  final String? Function(String) photoFor;
  final String? adamPhoto;
  final Offset adamAvatarAlignment;
  final bool linked, paid, adamMain;
  final List<String> linkedSeekerNames;
  final List<ZyraFocusItem>? focusItems;
  final List<ZyraFocusItem> circleFocus;
  final int notificationCount, newJourneyRequestCount;
  final List<DraftProfile> receivedJourneyRequests, sentJourneyRequests;
  final bool tabClearance;
  final bool Function()? canInteract;
  final List<ZyraGuardianJourneyCard> journeys;
  final int journeyIndex;
  final Object? journeyIdentity;
  final ZyraGuardianFamilyInvite? familyOffer;
  final bool freePlaceInvite;
  final bool Function()? familyCanAct;
  Widget _text(
    String text, {
    double size = 14,
    bool muted = false,
    bool gold = false,
  }) => Text(
    text,
    style: ZyraText.body(
      size: size,
      color: gold
          ? (size < 24 ? ZyraColors.goldText : ZyraColors.journeyGold)
          : muted
          ? ZyraColors.ink(.55)
          : ZyraColors.foreground,
    ).copyWith(height: 1.45),
  );
  Text _title(String text, {double size = 28}) => Text(
    text,
    style: ZyraText.heading(
      size: size,
    ).copyWith(fontWeight: FontWeight.w300, height: 1.2),
  );
  // R2 Larger Text: fit the longest word only when it cannot fit on one
  // line. Text still handles ordinary word wrapping and explicit line breaks.
  Widget _networkTitle() => _fitNetworkLabel(
    'Network',
    ZyraText.pageTitle(),
    (scaler) => ZyraTabTitle('Network', textScaler: scaler),
  );

  Widget _networkLabel(Text label) => _fitNetworkLabel(
    label.data!,
    label.style!,
    (scaler) => scaler == null
        ? label
        : Text(
            label.data!,
            style: label.style,
            textAlign: label.textAlign,
            textScaler: scaler,
          ),
  );

  Widget _fitNetworkLabel(
    String label,
    TextStyle style,
    Widget Function(TextScaler?) buildLabel,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final scaler = MediaQuery.textScalerOf(context);
      final fontSize = style.fontSize!;
      if (scaler.scale(fontSize) <= fontSize) return buildLabel(null);
      var widest = 0.0;
      final painter = TextPainter(
        textDirection: Directionality.of(context),
        textScaler: scaler,
        locale: Localizations.maybeLocaleOf(context),
      );
      final inheritedStyle = DefaultTextStyle.of(context).style.merge(style);
      for (final word in label.split(RegExp(r'\s+'))) {
        painter.text = TextSpan(text: word, style: inheritedStyle);
        painter.layout();
        if (painter.width > widest) widest = painter.width;
      }
      painter.dispose();
      if (widest <= constraints.maxWidth) return buildLabel(null);
      return buildLabel(
        TextScaler.linear(
          scaler.scale(fontSize) /
              fontSize *
              constraints.maxWidth /
              widest *
              .995,
        ),
      );
    },
  );

  Widget _button(
    String label,
    String action, {
    bool gold = false,
    bool network = false,
    bool requestSent = false,
  }) => Builder(
    builder: (context) {
      final text = Text(
        label,
        textAlign: TextAlign.center,
        style: ZyraText.body(
          size: 13,
          color: requestSent || (gold && !network)
              ? ZyraColors.goldText
              : ZyraColors.foreground,
        ).copyWith(height: network ? 1.35 : 1.45),
      );
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: network ? 52 : 46),
        child: ZyraFloatingSurface(
          radius: 28,
          child: TextButton(
            key: ValueKey('guardian_$action'),
            onPressed: ZyraTapFeedback.onTap(context, () => onAction(action)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: network ? 10 : 14,
                vertical: network ? 8 : 11,
              ),
              backgroundColor: ZyraColors.surfaceFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: gold
                      ? ZyraColors.journeyGold.withValues(alpha: .75)
                      : ZyraColors.surfaceBorder,
                ),
              ),
            ),
            child: network ? _networkLabel(text) : text,
          ),
        ),
      );
    },
  );
  Widget _box(
    Widget child, {
    bool gold = false,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) => ZyraFloatingSurface(
    radius: 20,
    circle: false,
    gold: false,
    child: Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold
              ? ZyraColors.journeyGold.withValues(alpha: .6)
              : ZyraColors.surfaceBorder,
        ),
      ),
      child: child,
    ),
  );
  Widget _tile(
    String title,
    String detail,
    IconData icon,
    String action, {
    double bottomGap = 10,
  }) => Padding(
    padding: EdgeInsets.only(bottom: bottomGap),
    child: Builder(
      builder: (context) => InkWell(
        key: ValueKey('guardian_$action'),
        onTap: ZyraTapFeedback.onTap(context, () => onAction(action)),
        borderRadius: BorderRadius.circular(20),
        child: _box(
          Row(
            children: [
              ZyraFloatingSurface(
                radius: 12,
                circle: false,
                gold: false,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ZyraColors.surfaceFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: ZyraColors.journeyGold, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text(title, size: 15),
                    _text(detail, size: 12, muted: true),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _text('›', muted: true),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _header(
    Widget title, {
    Widget? trailing,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: alignment,
      children: [
        Expanded(child: title),
        ?trailing,
      ],
    ),
  );
  Widget _switcher(
    String label,
    String action, {
    bool chevron = true,
    IconData? icon,
  }) => Builder(
    builder: (context) => GestureDetector(
      key: ValueKey('guardian_$action'),
      behavior: HitTestBehavior.opaque,
      onTap: ZyraTapFeedback.onTap(context, () => onAction(action)),
      child: ZyraFloatingSurface(
        radius: 22,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: ZyraColors.foreground),
                const SizedBox(width: 4),
              ],
              _text(chevron ? '$label ▾' : label, size: 12),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _linkedSeekerAvatar({required bool adam}) => Container(
    width: 62,
    height: 62,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: ZyraColors.journeyGold.withValues(alpha: .6)),
    ),
    child: ZyraSeekerAvatar(
      photo: adam ? adamPhoto : null,
      size: 62,
      alignmentX: adam ? adamAvatarAlignment.dx : 0,
      alignmentY: adam ? adamAvatarAlignment.dy : 0,
    ),
  );
  Widget _photo(String id) => ClipOval(
    child: ZyraAvatarImage(
      photoFor(id) ?? '',
      width: 54,
      height: 54,
      alignmentX: 0,
      alignmentY: 0,
    ),
  );
  Widget _segments(List<String> labels, int selected, String action) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Builder(
      builder: (context) => Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: ZyraFloatingSurface(
                radius: 28,
                child: TextButton(
                  key: ValueKey('guardian_$action$i'),
                  onPressed: ZyraTapFeedback.onTap(
                    context,
                    () => onAction('$action$i'),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: selected == i
                        ? ZyraColors.surfaceFill
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: selected == i
                            ? ZyraColors.journeyGold.withValues(alpha: .75)
                            : ZyraColors.surfaceBorder,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: ZyraText.body(size: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  Widget _viewport(Widget child, {bool scroll = true, double bottom = 104}) =>
      Builder(
        builder: (context) {
          final clearance = tabClearance
              ? ZyraNavBarMetrics.contentBottomClearance(context)
              : bottom;
          return SafeArea(
            bottom: false,
            child: scroll
                ? ZyraShadowScrollView(
                    key: PageStorageKey('guardian_tabs_$page'),
                    padding: EdgeInsets.fromLTRB(
                      ZyraPreviewSpacing.pageMargin,
                      16,
                      ZyraPreviewSpacing.pageMargin,
                      clearance,
                    ),
                    child: child,
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      ZyraPreviewSpacing.pageMargin,
                      16,
                      ZyraPreviewSpacing.pageMargin,
                      tabClearance ? clearance : 0,
                    ),
                    child: child,
                  ),
          );
        },
      );
  Widget _quiet(
    String title,
    String detail,
    IconData icon, {
    bool network = false,
  }) {
    final empty = ZyraEmptyState(
      icon: icon,
      title: title,
      message: detail,
      ctaLabel: network ? 'Open Network' : null,
      ctaKey: network ? const ValueKey('guardian_empty_network') : null,
      onCta: network ? () => onAction('network') : null,
    );
    return Expanded(
      child: tabClearance
          ? LayoutBuilder(
              builder: (context, bounds) => ZyraShadowScrollView(
                key: ValueKey('guardian_quick_empty_$page'),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: bounds.maxHeight),
                  child: empty,
                ),
              ),
            )
          : Builder(
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.textScalerOf(context).scale(12.5) <= 12.5
                      ? 240
                      : 0,
                ),
                child: empty,
              ),
            ),
    );
  }

  List<ZyraFocusItem> get _homeFocusItems {
    final review = state.review;
    final hours = state.hours;
    return [
      if (freePlaceInvite)
        ZyraFocusItem(
          id: ZyraGuardianTabsState.freePlaceInviteFocus,
          icon: Icons.verified_user_outlined,
          title: 'Adam asked you to be his Guardian',
          detail:
              'His free Guardian Basic place is already used. You can still join on Guardian One.',
          actionLabel: 'View',
          actionKey: 'guardian_free_place_view',
          onAction: () => onAction('free_place_view'),
        ),
      if (familyOffer case final offer?)
        ZyraFocusItem(
          id: 'family-offer-${offer.revision}',
          icon: Icons.verified_user_outlined,
          title: '${offer.seekerName} has given\nyou Guardian One',
          detail:
              'A place in ${offer.seekerName}’s ZYRA Family. You pay nothing. Choose by ${offer.chooseBy}.',
          actionLabel: 'View',
          actionKey: 'guardian_family_view',
          onAction: () => onAction('family_view'),
        ),
      if (linked && review != ZyraGuardianReview.continued)
        ZyraFocusItem(
          id: state.reviewFocusId,
          icon: Icons.verified_user_outlined,
          title: 'Family Review for\nAdam and Sara',
          detail: review == ZyraGuardianReview.paused
              ? 'You paused the move to Building a Life. Adam and Sara stay on Faith & Values. When your families have spoken, reopen the review for a fresh 48 hours.'
              : 'Faith & Values is complete. Continue, or pause the move to the next stage. $hours hours left — if you do nothing, the Journey continues.',
          actionLabel: !adamMain
              ? ''
              : review == ZyraGuardianReview.paused
              ? 'Reopen review'
              : 'Continue',
          actionKey: !adamMain
              ? null
              : review == ZyraGuardianReview.paused
              ? 'guardian_reopen'
              : 'guardian_continue',
          onAction: () {
            if (!adamMain) return;
            onAction(
              review == ZyraGuardianReview.paused ? 'reopen' : 'continue',
            );
          },
          secondaryLabel: adamMain && review == ZyraGuardianReview.open
              ? 'Pause'
              : null,
          secondaryKey: 'guardian_pause',
          onSecondaryAction: adamMain && review == ZyraGuardianReview.open
              ? () => onAction('pause')
              : null,
        ),
      if (linked &&
          paid &&
          adamMain &&
          state.connection == ZyraGuardianConnection.pending)
        ZyraFocusItem(
          id: 'connect-pending',
          icon: Icons.forum_outlined,
          title: 'Adam · Connect\nwith Guardian',
          detail: "Noor's Main Guardian asks to connect about Adam.",
          actionLabel: 'View request',
          actionKey: 'guardian_received',
          onAction: () => onAction('received'),
        ),
    ];
  }

  Widget _home() {
    final hasRequest = linked && adamMain && newJourneyRequestCount > 0;
    final hasConnect = linked && paid && adamMain && state.hasUnseenConnection;
    final items = [...circleFocus, ...(focusItems ?? _homeFocusItems)]
        .where((item) => !state.consumedFocus.contains(item.id))
        .toList(growable: false);
    return ZyraFocusDashboard(
      canInteract: canInteract,
      greeting: linked
          ? 'Assalamu alaikum, Hassan. You support Adam and Yusuf.'
          : 'Assalamu alaikum, Hassan.',
      items: items,
      initialIndex: state.focusIndex,
      onIndexChanged: (index) => onAction('focus_index_$index'),
      chips: [
        if (linked) ...[
          ZyraFocusChip(
            id: 'guardian_focus_adam',
            label: 'Adam · ${state.stage}',
            icon: Icons.people_outline,
            onTap: () => onAction('focus_adam'),
          ),
          ZyraFocusChip(
            id: 'guardian_focus_yusuf',
            label: 'Yusuf · no Journey',
            icon: Icons.person_outline,
            onTap: () => onAction('focus_yusuf'),
          ),
        ],
      ],
      tiles: [
        ZyraFocusTile(
          id: 'guardian_requests',
          label: 'Journey\nrequests',
          status: hasRequest ? '$newJourneyRequestCount new' : 'None',
          icon: Icons.inbox_outlined,
          isNew: hasRequest,
          onTap: () => onAction('quick_requests'),
        ),
        ZyraFocusTile(
          id: 'guardian_connect',
          label: 'Connect with\nGuardian',
          status: paid
              ? hasConnect
                    ? '1 new'
                    : '${state.sent.length} sent'
              : 'Guardian One',
          icon: Icons.forum_outlined,
          isNew: hasConnect,
          locked: !paid,
          onTap: () => onAction(paid ? 'quick_connect' : 'membership'),
        ),
        ZyraFocusTile(
          id: 'guardian_introductions',
          label: 'Introductions',
          status: paid ? '${state.introduced.length} made' : 'Guardian One',
          icon: Icons.groups_outlined,
          locked: !paid,
          onTap: () => onAction(paid ? 'quick_introductions' : 'membership'),
        ),
        ZyraFocusTile(
          id: 'guardian_notifications',
          label: 'Notifications',
          status: notificationCount > 0
              ? '$notificationCount new'
              : 'Nothing new',
          icon: Icons.notifications_none,
          isNew: notificationCount > 0,
          onTap: () => onAction('quick_notifications'),
        ),
      ],
    );
  }

  Widget _requests() {
    final requests = state.requestsSent
        ? sentJourneyRequests
        : receivedJourneyRequests;
    return _viewport(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(
            _title('Journey requests'),
            trailing: _switcher(
              const [
                'All Seekers',
                'for Adam',
                'for Yusuf',
              ][state.requestSeeker],
              'request_seeker',
            ),
          ),
          _segments(
            const ['Received', 'Sent'],
            state.requestsSent ? 1 : 0,
            'requests_tab_',
          ),
          if (linked && adamMain && state.requestSeeker != 2) ...[
            for (final (i, person) in requests.indexed) ...[
              if (i > 0) const SizedBox(height: ZyraPreviewSpacing.cardToCard),
              _box(
                Row(
                  children: [
                    _photo(person.id.replaceFirst('draft-', '')),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _text(
                            '${person.firstName} ${person.surname}',
                            size: 18,
                          ),
                          _text(
                            '${person.age} · ${person.city}',
                            size: 12,
                            muted: true,
                          ),
                          _text(
                            state.requestsSent
                                ? 'Adam is waiting for a response'
                                : 'Journey request to Adam',
                            size: 12,
                            gold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (requests.isEmpty)
              _text(
                state.requestsSent
                    ? 'No sent requests yet.'
                    : 'No received requests yet.',
                muted: true,
              )
            else ...[
              const SizedBox(height: 10),
              _text(
                'You see these as their Main Guardian. Each Seeker decides on their own requests.',
                size: 12,
                muted: true,
              ),
            ],
          ] else
            _text('Main Guardian only', muted: true),
        ],
      ),
    );
  }

  Widget _connect() {
    final received = state.connectReceived;
    final empty = received
        ? (!linked || !adamMain || state.receivedCount == 0)
        : state.sent.isEmpty;
    return _viewport(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(_title('Connect with Guardian')),
          _segments(
            const ['Sent', 'Received'],
            received ? 1 : 0,
            'connect_tab_',
          ),
          if (empty)
            _quiet(
              received ? 'No requests received yet.' : 'No requests sent yet.',
              received
                  ? "When another family's Guardian asks to speak about Adam, it appears here."
                  : 'Find a family in Network and choose Connect with Guardian.',
              Icons.forum_outlined,
              network: !received,
            )
          else ...[
            if (received)
              _connectionCard(
                'noor',
                accepted: state.connection == ZyraGuardianConnection.accepted,
              )
            else
              for (final (i, id) in state.sent.indexed) ...[
                if (i > 0)
                  const SizedBox(height: ZyraPreviewSpacing.cardToCard),
                _connectionCard(id),
              ],
            if (received &&
                state.connection == ZyraGuardianConnection.pending) ...[
              const SizedBox(height: 10),
              _text(
                "Accepting opens a private chat between you and Noor's Main Guardian about Adam and Noor. Only the two of you see it.",
                size: 12,
                muted: true,
              ),
            ],
          ],
        ],
      ),
      scroll: !empty,
    );
  }

  Widget _connectionCard(String id, {bool accepted = false}) {
    final person = ZyraGuardianTabsState.network.firstWhere((p) => p.id == id);
    return _box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _photo(id),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text("${person.name}'s Main Guardian", size: 18),
                    _text(
                      'For ${person.name}, ${person.age} · ${person.city}',
                      size: 12,
                      muted: true,
                    ),
                    _text(
                      id == 'noor' && state.connectReceived
                          ? accepted
                                ? 'Connected · private chat'
                                : 'Asks to connect about Adam'
                          : 'Waiting for a response',
                      size: 12,
                      gold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (id == 'noor' && state.connectReceived) ...[
            const SizedBox(height: 12),
            if (accepted)
              _button('Open chat', 'chat')
            else
              Row(
                children: [
                  Expanded(child: _button('Accept', 'accept', gold: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _button('Not now', 'dismiss')),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _introductions() => state.introductionCount == 0
      ? _viewport(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(_title("Introductions you've made")),
              _quiet(
                'No introductions yet.',
                'Find someone in Network and choose Introduce to ${state.seekerName}.',
                Icons.groups_outlined,
                network: true,
              ),
            ],
          ),
          scroll: false,
        )
      : _viewport(
          Column(
            children: [
              _header(_title("Introductions you've made")),
              for (final (i, entry)
                  in state.introduced
                      .where(
                        (id) =>
                            id.startsWith('${state.seekerName.toLowerCase()}:'),
                      )
                      .indexed) ...[
                if (i > 0)
                  const SizedBox(height: ZyraPreviewSpacing.cardToCard),
                _tile(
                  entry.split(':').last == 'aisha' ? 'Aisha' : 'Noor',
                  'Suggested to ${state.seekerName}',
                  Icons.groups_outlined,
                  'network',
                  bottomGap: 0,
                ),
              ],
            ],
          ),
        );
  Widget _networkArrow(bool forward) => Builder(
    builder: (context) {
      final enabled = forward ? state.canNext : state.canPrevious;
      return SizedBox.square(
        dimension: 52,
        child: IconButton(
          key: ValueKey(forward ? 'guardian_next' : 'guardian_previous'),
          onPressed: ZyraTapFeedback.onTap(
            context,
            enabled ? () => onAction(forward ? 'next' : 'previous') : null,
          ),
          style: IconButton.styleFrom(
            backgroundColor: ZyraColors.surfaceFill,
            shape: CircleBorder(
              side: BorderSide(color: ZyraColors.surfaceBorder),
            ),
          ),
          icon: Icon(
            forward ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            size: 20,
            color: enabled ? ZyraColors.journeyGold : ZyraColors.ink(.28),
          ),
        ),
      );
    },
  );

  // Line119: the membership gate is a full-page presentation. The shell owns
  // linked names and the existing membership action; this grants no access.
  Widget _lockedNetwork(BuildContext context) {
    final names = linked ? linkedSeekerNames : const <String>[];
    final seeker = names.length == 1 ? names.single : 'your Seekers';
    final suggestion = names.length == 1 ? names.single : 'one of your Seekers';
    Widget row(IconData icon, String title, String detail) => Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ZyraColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ZyraColors.journeyGold.withValues(alpha: .5),
              ),
            ),
            child: Icon(icon, color: ZyraColors.journeyGold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.body(size: 15)),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: ZyraText.body(
                    size: 12.5,
                    color: ZyraColors.foregroundMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return SafeArea(
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
            _header(_networkTitle()),
            Expanded(
              child: LayoutBuilder(
                builder: (context, bounds) => SingleChildScrollView(
                  key: const ValueKey('guardian_network_locked_scroll'),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: bounds.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    key: const ValueKey(
                                      'guardian_network_lock_circle',
                                    ),
                                    width: 102,
                                    height: 102,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ZyraColors.journeyGold
                                            .withValues(alpha: .65),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline,
                                      color: ZyraColors.journeyGold,
                                      size: 34,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'NETWORK',
                                    style: ZyraText.body(
                                      size: 11,
                                      color: ZyraColors.journeyGold,
                                    ).copyWith(letterSpacing: 1.2),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Network is part\nof Guardian One',
                                    textAlign: TextAlign.center,
                                    style: ZyraText.heading(size: 24).copyWith(
                                      fontWeight: FontWeight.w300,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          row(
                            Icons.search,
                            'Find other families',
                            'Browse Seekers whose Guardians are open to it',
                          ),
                          row(
                            Icons.person_add_outlined,
                            'Introduce someone to $seeker',
                            'Suggest a profile for $suggestion to look at',
                          ),
                          row(
                            Icons.groups_outlined,
                            'Connect with their Guardians',
                            'Talk Guardian to Guardian before anything moves',
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 14),
                            child: Text(
                              'Everything else you do for $seeker stays the same.',
                              textAlign: TextAlign.center,
                              style: ZyraText.body(
                                size: 12.5,
                                color: ZyraColors.foregroundMuted,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('guardian_network_membership'),
                            onPressed: ZyraTapFeedback.onTap(
                              context,
                              () => onAction('membership'),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: ZyraColors.primaryAction,
                              shape: const StadiumBorder(),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'View Guardian One',
                              style: ZyraText.body(
                                size: 14,
                                color: ZyraColors.onPrimaryAction,
                              ).copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _network(BuildContext context) {
    if (!paid) return _lockedNetwork(context);
    final bottom = ZyraNavBarMetrics.contentBottomClearance(context);
    if (!linked) {
      return _viewport(
        Column(
          children: [
            _header(_networkTitle()),
            _tile(
              'Invite your Seeker',
              'Support someone on their journey.',
              Icons.add,
              'invite',
              bottomGap: 0,
            ),
          ],
        ),
        bottom: bottom,
      );
    }
    final largerText = MediaQuery.textScalerOf(context).scale(14) > 14;
    final person = ZyraGuardianTabsState.network[state.networkIndex];
    final requestSent = state.sent.contains(person.id);
    return _viewport(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(
            _networkTitle(),
            alignment: CrossAxisAlignment.start,
            trailing: _switcher('for ${state.seekerName}', 'seeker'),
          ),
          Expanded(
            child: SizedBox(
              key: const ValueKey('guardian-network-card'),
              child: _box(
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    key: const ValueKey('guardian-network-card-scroll'),
                    physics: largerText
                        ? ZyraMotion.fixedCardScrollPhysics
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ZyraGoldRingMonogram(
                                key: const ValueKey(
                                  'guardian_network_monogram',
                                ),
                                name: person.name[0],
                                size: 110,
                                fontSize: 52,
                                textScaler: TextScaler.noScaling,
                              ),
                              const SizedBox(height: 20),
                              _title(
                                '${person.name[0]}., ${person.age}',
                                size: 34,
                              ),
                              _text(person.city, size: 20),
                              const SizedBox(height: 18),
                              _info('Main Guardian', 'Father · ✓ Verified'),
                              _info('Nationality', 'British'),
                              _info('Ethnicity', 'Mixed'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ZyraPreviewSpacing.cardToPill),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _networkArrow(false),
              const SizedBox(width: 10),
              Expanded(
                child: _button(
                  state.introducedForCurrent()
                      ? 'Introduced'
                      : 'Introduce to\n${state.seekerName}',
                  'introduce_confirm',
                  gold: true,
                  network: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _button(
                  requestSent ? 'Request sent' : 'Connect with\nGuardian',
                  'connect_confirm',
                  gold: true,
                  network: true,
                  requestSent: requestSent,
                ),
              ),
              const SizedBox(width: 10),
              _networkArrow(true),
            ],
          ),
          SizedBox(height: bottom),
        ],
      ),
      scroll: false,
    );
  }

  Widget _info(String name, String value, {bool rule = true}) => Container(
    padding: EdgeInsets.symmetric(vertical: rule ? 15 : 10),
    decoration: rule
        ? BoxDecoration(
            border: Border(top: BorderSide(color: ZyraColors.surfaceBorder)),
          )
        : null,
    child: Builder(
      builder: (context) {
        final constrained =
            MediaQuery.textScalerOf(context).scale(14) > 14 ||
            MediaQuery.sizeOf(context).width < 360;
        return Row(
          children: [
            if (constrained)
              Expanded(child: _text(name, size: 14, muted: true))
            else
              _text(name, size: 14, muted: true),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _text(value, size: 14),
              ),
            ),
          ],
        );
      },
    ),
  );
  Widget _confirm(bool introduction) {
    final person = ZyraGuardianTabsState.network[state.networkIndex];
    return ZyraGuardianActionPage(
      introduction: introduction,
      personName: person.name,
      seekerName: state.seekerName,
      seekerGender: seekerGender,
      onAction: onAction,
    );
  }

  Widget _journeys(BuildContext context) => _viewport(
    Padding(
      padding: EdgeInsets.only(
        bottom: ZyraNavBarMetrics.contentBottomClearance(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: linked && journeys.isNotEmpty
                  ? ZyraPreviewSpacing.titleToDots
                  : 4,
            ),
            child: LayoutBuilder(
              key: const ValueKey('guardian_journeys_title_block'),
              builder: (context, constraints) {
                final switcher = _switcher('for ${state.seekerName}', 'seeker');
                if (MediaQuery.textScalerOf(context).scale(28) > 36 ||
                    constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZyraTabTitle('Journeys'),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: switcher),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: ZyraTabTitle('Journeys')),
                    switcher,
                  ],
                );
              },
            ),
          ),
          if (linked && journeys.isNotEmpty)
            Expanded(
              child: ZyraGuardianJourneyPager(
                cards: journeys,
                index: journeyIndex,
                identity: journeyIdentity,
                onAction: onAction,
              ),
            )
          else
            const Expanded(
              child: ZyraEmptyState(
                icon: Icons.route_outlined,
                message: 'No current Journey',
              ),
            ),
          SizedBox(
            height: linked && journeys.isNotEmpty
                ? ZyraPreviewSpacing.cardToCard
                : 10,
          ),
          if (linked)
            _tile(
              'Ended Journeys',
              'Only what ${state.seekerName} shares with you',
              Icons.history,
              'ended',
              bottomGap: 0,
            ),
        ],
      ),
    ),
    scroll: false,
  );
  Widget _seekers(BuildContext context) => _viewport(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          const ZyraTabTitle('Seekers'),
          alignment: CrossAxisAlignment.start,
          trailing: Builder(
            builder: (context) => SizedBox.square(
              dimension: 38,
              child: IconButton(
                key: const ValueKey('guardian_invite'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 38,
                  height: 38,
                ),
                onPressed: ZyraTapFeedback.onTap(
                  context,
                  () => onAction('invite'),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: ZyraColors.surfaceFill,
                  shape: CircleBorder(
                    side: BorderSide(color: ZyraColors.surfaceBorder),
                  ),
                ),
                icon: Icon(Icons.add, size: 21, color: ZyraColors.foreground),
              ),
            ),
          ),
        ),
        if (linked)
          for (var i = 0; i < 2; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == 0 ? ZyraPreviewSpacing.cardToCard : 10,
              ),
              child: Builder(
                builder: (context) => InkWell(
                  key: ValueKey('guardian_seeker_$i'),
                  onTap: ZyraTapFeedback.onTap(
                    context,
                    () => onAction('seeker_$i'),
                  ),
                  child: _box(
                    Row(
                      children: [
                        _linkedSeekerAvatar(adam: i == 0),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _text(i == 0 ? 'Adam' : 'Yusuf', size: 20),
                              _text(
                                i == 0
                                    ? 'You are his Main Guardian · Father'
                                    : 'Additional Guardian · Father',
                                size: 12,
                                muted: true,
                              ),
                              const SizedBox(height: 4),
                              _text(
                                i == 0
                                    ? 'Journey with Sara · ${state.stage}'
                                    : 'No current Journey',
                                size: 12,
                                gold: true,
                              ),
                            ],
                          ),
                        ),
                        _text('›', muted: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        _text('You can support up to 10 Seekers.', size: 12, muted: true),
      ],
    ),
    bottom: ZyraNavBarMetrics.contentBottomClearance(context),
  );
  Widget _seeker() => ZyraGuardianSeekerPage(
    name: state.seekerName,
    photo: state.main ? adamPhoto : null,
    avatarAlignment: state.main ? adamAvatarAlignment : Offset.zero,
    gender: seekerGender,
    main: state.main && adamMain,
    linkedDate: state.main ? '20 Sep 2026' : '02 Oct 2026',
    journeys: state.main && adamMain
        ? 'View and Chat'
        : 'As ${state.seekerName} allows, Journey by Journey',
    requests: state.main && adamMain ? 'You see them' : 'Main Guardian only',
    currentJourney: currentSeekerJourney,
    onJourney: currentSeekerJourneyId == null
        ? null
        : () => onAction('seeker_journey_$currentSeekerJourneyId'),
    onCircle: () => onAction('circle'),
  );
  @override
  Widget build(BuildContext context) => switch (page) {
    'my_zyra' => _home(),
    'requests' => _requests(),
    'connect' => _connect(),
    'introductions' => _introductions(),
    'network' => _network(context),
    'introduce_confirm' => _confirm(true),
    'connect_confirm' => _confirm(false),
    'family_offer' =>
      familyOffer == null
          ? const SizedBox.shrink()
          : ZyraGuardianActionPage(
              introduction: false,
              personName: familyOffer!.seekerName,
              seekerName: familyOffer!.seekerName,
              seekerGender: familyOffer!.seekerGender,
              familyInvite: familyOffer,
              canAct: familyCanAct,
              onAction: onAction,
            ),
    'journeys' => _journeys(context),
    'seekers' => _seekers(context),
    'seeker' => _seeker(),
    _ => const SizedBox.shrink(),
  };
}

// LOCK8 V4: this accepted sample connection is Adam/Noor, independent of
// the currently selected Network person or supported Seeker.
class ZyraGuardianPrivateChat extends StatefulWidget {
  const ZyraGuardianPrivateChat({
    super.key,
    required this.onSend,
    required this.onReport,
    required this.onOptions,
    required this.canAct,
  });
  final VoidCallback onSend, onReport, onOptions;
  final bool Function() canAct;
  @override
  State<ZyraGuardianPrivateChat> createState() =>
      _ZyraGuardianPrivateChatState();
}

class _ZyraGuardianPrivateChatState extends State<ZyraGuardianPrivateChat> {
  final _controller = TextEditingController();
  final _messages = <String>[];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _reportable(Widget child) {
    final canAct = widget.canAct;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      key: _messages.isEmpty ? const ValueKey('guardian_chat_report') : null,
      onLongPress: ZyraTapFeedback.onTap(
        context,
        widget.onReport,
        canAct: () => mounted && canAct(),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAct = widget.canAct;
    final onSend = widget.onSend;
    bool current() => mounted && canAct();
    final feedback = context
        .dependOnInheritedWidgetOfExactType<ZyraTapFeedback>();
    return ZyraTapFeedback(
      level: feedback?.level ?? () => ZyraInteractionStyle.hapticLevel,
      canAct: () => current() && (feedback?.canAct() ?? true),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const ScrollPhysics(),
                key: const ValueKey('guardian_chat_scroll'),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guardian chat',
                            style: ZyraText.heading(
                              size: 28,
                            ).copyWith(fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(height: 20),
                          ZyraFloatingSurface(
                            radius: 18,
                            child: Container(
                              key: const ValueKey('guardian_chat_header'),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: ZyraColors.surfaceFill,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: ZyraColors.surfaceBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ZyraColors.journeyGold,
                                      ),
                                    ),
                                    child: Text(
                                      'N',
                                      style: ZyraText.body(
                                        size: 20,
                                        color: ZyraColors.goldText,
                                      ).copyWith(fontWeight: FontWeight.w200),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Noor’s Main Guardian",
                                          style: ZyraText.body(size: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ABOUT ADAM AND NOOR',
                                          style: ZyraText.body(
                                            size: 11,
                                            color: ZyraColors.goldText,
                                          ).copyWith(letterSpacing: 1.1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ZyraFloatingSurface(
                                    circle: true,
                                    child: IconButton(
                                      key: const ValueKey(
                                        'guardian_chat_options',
                                      ),
                                      tooltip: 'Guardian chat options',
                                      style: IconButton.styleFrom(
                                        backgroundColor: ZyraColors.surfaceFill,
                                      ),
                                      onPressed: ZyraTapFeedback.onTap(
                                        context,
                                        widget.onOptions,
                                        canAct: () => current(),
                                      ),
                                      icon: const Icon(
                                        Icons.more_horiz,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _messages.isEmpty
                        ? Center(
                            child: _reportable(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 28,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 300,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 24,
                                        color: ZyraColors.foregroundSecondary,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'A private chat',
                                        textAlign: TextAlign.center,
                                        style: ZyraText.body(size: 15),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Only you and Noor’s Main Guardian see it. Keep it respectful — you can report anything here.",
                                        textAlign: TextAlign.center,
                                        style: ZyraText.subtext(
                                          size: 13,
                                        ).copyWith(height: 1.45),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final message in _messages)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _reportable(
                                      Container(
                                        margin: const EdgeInsets.only(
                                          left: 68,
                                          top: 8,
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          10,
                                          14,
                                          10,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: ZyraColors.journeyGold,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              message,
                                              style: ZyraText.body(size: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'now',
                                              style: ZyraText.subtext(size: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            ZyraFamilyMessageComposer(
              controller: _controller,
              busy: !current(),
              contextEnabled: false,
              selectedContext: null,
              onChooseContext: () {},
              onRemoveContext: () {},
              onOpenContext: null,
              hint: 'Message Noor’s Main Guardian',
              privateGuardian: true,
              onSend: () {
                if (!current() || _controller.text.trim().isEmpty) return;
                setState(() => _messages.add(_controller.text.trim()));
                _controller.clear();
                onSend();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ZyraGuardianChatOptions extends StatelessWidget {
  const ZyraGuardianChatOptions({
    super.key,
    required this.onReport,
    required this.onBlock,
    required this.onDone,
  });
  final VoidCallback onReport, onBlock, onDone;
  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.modalSheetSurface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        key: const ValueKey('guardian_chat_options_scroll'),
        padding: const EdgeInsets.fromLTRB(23, 14, 23, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ZyraColors.ink(.16),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Guardian chat',
              style: ZyraText.heading(
                size: 22,
              ).copyWith(fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 20),
            ListTile(
              key: const ValueKey('guardian_chat_options_report'),
              contentPadding: EdgeInsets.zero,
              minTileHeight: 48,
              dense: true,
              title: Text(
                'Report a message',
                style: ZyraText.body(size: 15, color: ZyraColors.dangerText),
              ),
              trailing: const Icon(Icons.chevron_right, size: 14),
              onTap: ZyraTapFeedback.onTap(context, onReport),
            ),
            Divider(color: ZyraColors.surfaceBorder, height: 1),
            ListTile(
              key: const ValueKey('guardian_chat_options_block'),
              contentPadding: EdgeInsets.zero,
              minTileHeight: 48,
              dense: true,
              title: Text(
                'Block Noor’s Main Guardian',
                style: ZyraText.body(size: 15, color: ZyraColors.dangerText),
              ),
              trailing: const Icon(Icons.chevron_right, size: 14),
              onTap: ZyraTapFeedback.onTap(context, onBlock),
            ),
            Divider(color: ZyraColors.surfaceBorder, height: 1),
            const SizedBox(height: 16),
            ZyraFloatingSurface(
              gold: true,
              child: FilledButton(
                key: const ValueKey('guardian_chat_options_done'),
                style: FilledButton.styleFrom(
                  backgroundColor: ZyraColors.actionFill,
                  foregroundColor: ZyraColors.onAction,
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: ZyraTapFeedback.onTap(context, onDone),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
