import 'zyra_floating_surface.dart';
// Shared Portrait Browse with caller-owned identity, selection and actions.
// This presenter owns only per-profile gallery position and layout. It has no
// services, account, matching, admission, entitlement or persistence authority.
// Photo rendering is required and explicitly supplied by the caller; this
// widget has no default image provider or ability to fetch a photo.

import 'zyra_tap_feedback.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/seeker_profile.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_preview_spacing.dart';
import '../theme/zyra_text.dart';
import 'floating_nav_bar.dart';
import 'zyra_browse_options_button.dart';
import 'zyra_browse_next_photo_motion.dart';
import 'zyra_invitation_outline.dart';
import 'zyra_profile_details_page.dart';
import 'zyra_profiles_components.dart';
import 'zyra_swipe_track.dart';

/// Explicit rendering seam. The caller supplies already-authorised photo
/// references and the renderer; a reference alone never initiates a fetch here.
/// A gallery page requests infinite width inside the bounded photo card.
/// Details-page avatars request a finite square and keep their own fit.
typedef ZyraBrowsePhotoBuilder =
    Widget Function(
      BuildContext context,
      String photo, {
      required double width,
      required double height,
      required Alignment alignment,
    });

/// The owner resolves neighbouring visits from current eligibility and history.
/// Indices refer to the owner's supplied profile list.
typedef ZyraProfileSwipe = ({
  int? previousIndex,
  int? nextIndex,
  VoidCallback? onBlockedPrevious,
  bool Function() canAct,
});

enum ZyraOneJourneyBrowseDesign {
  portraitCard(
    'Portrait card',
    'Public details first, then a bounded swipeable photo gallery.',
  );

  const ZyraOneJourneyBrowseDesign(this.label, this.description);

  final String label;
  final String description;
}

/// Bounded Portrait Browse with caller-owned selection and actions.
/// Previous/Next are neutral navigation, never Pass or Dislike.
class ZyraBrowseDesigns extends StatefulWidget {
  const ZyraBrowseDesigns({
    super.key,
    required this.profiles,
    required this.selectedIndex,
    required this.design,
    required this.photoBuilder,
    this.readOnlyPreview = false,
    this.showFeedChrome = true,
    this.onPrevious,
    this.onNext,
    this.onFilters,
    this.onBrowseMenu,
    this.onProfile,
    this.onRequest,
    this.requestLabel,
    this.requestSemanticLabel,
    this.invitationSent,
    this.canRequest,
    this.requestRowLabels,
    this.profileSwipe,
    this.bottomPadding = 100,
    this.fixedTabFooter = false,
    this.alignHeaderActions = false,
    this.nextProfileMotion = ZyraBrowseNextMotion.current,
    this.nextProfileMotionEpoch = 0,
    this.hapticLevel,
    this.initialPhotoIndices = const <String, int>{},
    this.onPhotoIndexChanged,
    this.initialGalleryIndices = const <String, int>{},
    this.onGalleryIndexChanged,
    this.ownPreviewActions,
  });

  /// The owner sees the live card with local photo taps and an informational
  /// request affordance. Feed selection and invitation delegates stay absent.
  ZyraBrowseDesigns.ownProfile({
    Key? key,
    required SeekerProfile profile,
    required ZyraBrowsePhotoBuilder photoBuilder,
    required bool Function() canAct,
    required VoidCallback showRequestInfo,
    ZyraHapticLevel? hapticLevel,
  }) : this(
         key: key,
         profiles: [profile],
         selectedIndex: 0,
         design: ZyraOneJourneyBrowseDesign.portraitCard,
         photoBuilder: photoBuilder,
         readOnlyPreview: true,
         showFeedChrome: false,
         hapticLevel: hapticLevel,
         ownPreviewActions: (canAct: canAct, requestInfo: showRequestInfo),
       );

  final List<SeekerProfile> profiles;
  final ZyraBrowsePhotoBuilder photoBuilder;

  /// Own-profile presentation only. Shows inert feed controls, without menu;
  /// this flag never supplies profile data or changes disclosure authority.
  final bool readOnlyPreview;
  final ({bool Function() canAct, VoidCallback requestInfo})? ownPreviewActions;

  /// Presentation only: omit feed controls and their reserved space when an
  /// owner supplies its own inspection header/actions. Feed decision delegates
  /// are not evaluated in this mode; profile/source authority stays caller-owned.
  final bool showFeedChrome;
  final int selectedIndex;
  final ZyraOneJourneyBrowseDesign design;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onFilters;
  final ValueChanged<SeekerProfile?>? onBrowseMenu;
  final ValueChanged<SeekerProfile>? onProfile;
  final ValueChanged<SeekerProfile>? onRequest;
  final String Function(SeekerProfile)? requestLabel;
  final String Function(SeekerProfile)? requestSemanticLabel;
  final bool Function(SeekerProfile)? invitationSent;
  final bool Function(SeekerProfile)? canRequest;

  /// LOCK 7 opt-in. The owning root supplies every label for stable row sizing.
  /// Null retains the shared presenter's existing three-pill layout.
  final List<String>? requestRowLabels;
  final ZyraProfileSwipe? profileSwipe;
  final double bottomPadding;
  final bool fixedTabFooter;
  final bool alignHeaderActions;
  // Optional presentation-only preview. Callers own selection and actions;
  // unchanged default and token zero preserve all existing shared callers.
  final ZyraBrowseNextMotion nextProfileMotion;
  final int nextProfileMotionEpoch;

  /// Explicit local feedback choice. Null preserves member preferences.
  final ZyraHapticLevel? hapticLevel;

  /// Initial-only presentation ordinals. Copied and bounded against the
  /// supplied photos before the first frame; later changes do not seek a pager.
  final Map<String, int> initialPhotoIndices;
  final void Function(String, int)? onPhotoIndexChanged;

  /// Gallery positions are separate from real photo ordinals: details at zero.
  /// Explicit gallery seeds take priority;
  /// legacy photo seeds always retain their actual-photo meaning.
  final Map<String, int> initialGalleryIndices;
  final void Function(String, int)? onGalleryIndexChanged;

  @override
  State<ZyraBrowseDesigns> createState() => _ZyraBrowseDesignsState();
}

class _ZyraBrowseDesignsState extends State<ZyraBrowseDesigns> {
  static const _backPillWidth = 50.0;
  static const _nextPillWidth = 72.0;
  static const _footerGap = 8.0;
  static const _pillBorderExtent = 2.0;
  static const _pillMinTapHeight = 48.0;
  static const _pillHorizontalTextPadding = 10.0;
  static const _pillVerticalPadding = 8.0;
  final Map<String, int> _galleryIndices = <String, int>{};
  final Map<String, GlobalKey> _cardAnchors = <String, GlobalKey>{};
  final _profileTrack = ZyraSwipeController();
  int _layoutRevision = 0;

  @override
  void initState() {
    super.initState();
    final initial = Map<String, int>.of(widget.initialPhotoIndices);
    final gallery = Map<String, int>.of(widget.initialGalleryIndices);
    for (final profile in widget.profiles) {
      final photo = initial[profile.id];
      final index =
          gallery[profile.id] ??
          (photo == null || profile.photos.isEmpty
              ? null
              : photo.clamp(0, profile.photos.length - 1) + 1);
      if (index == null) continue;
      _galleryIndices[profile.id] = index.clamp(
        0,
        _galleryPageCount(profile) - 1,
      );
    }
  }

  String? get _selectedId => widget.profiles.isEmpty
      ? null
      : widget
            .profiles[widget.selectedIndex.clamp(0, widget.profiles.length - 1)]
            .id;

  int _galleryPageCount(SeekerProfile profile) =>
      math.max(1, profile.photos.length + 1);

  int _galleryIndex(SeekerProfile profile) => (_galleryIndices[profile.id] ?? 0)
      .clamp(0, _galleryPageCount(profile) - 1);

  @override
  void didUpdateWidget(covariant ZyraBrowseDesigns oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.profiles.map((profile) => profile.id).toSet();
    _galleryIndices.removeWhere((id, _) => !currentIds.contains(id));
    _cardAnchors.removeWhere((id, _) => !currentIds.contains(id));
    final oldSelectedId = oldWidget.profiles.isEmpty
        ? null
        : oldWidget
              .profiles[oldWidget.selectedIndex.clamp(
                0,
                oldWidget.profiles.length - 1,
              )]
              .id;
    if (oldSelectedId != _selectedId) {
      // Every newly selected person starts at the first gallery page. Gallery
      // navigation is not a profile decision or person-navigation event.
      _galleryIndices.remove(_selectedId);
    }
    ++_layoutRevision;
  }

  void _selectGalleryPage(SeekerProfile profile, int index, int revision) {
    if (!mounted ||
        revision != _layoutRevision ||
        !_isCurrent(profile) ||
        (widget.ownPreviewActions?.canAct() ?? widget.profileSwipe?.canAct()) ==
            false ||
        index < 0 ||
        index >= _galleryPageCount(profile) ||
        index == _galleryIndex(profile)) {
      return;
    }
    setState(() {
      _galleryIndices[profile.id] = index;
    });
    final onGallery = widget.onGalleryIndexChanged;
    final onPhoto = widget.onPhotoIndexChanged;
    onGallery?.call(profile.id, index);
    // A caller may withdraw this presenter from its first callback. Never
    // borrow a replacement photo delegate or publish after that withdrawal.
    if (profile.photos.isNotEmpty &&
        index >= 1 &&
        mounted &&
        revision == _layoutRevision &&
        _isCurrent(profile) &&
        _galleryIndex(profile) == index) {
      onPhoto?.call(profile.id, index - 1);
    }
  }

  bool _isCurrent(SeekerProfile profile) =>
      widget.profiles.isNotEmpty &&
      widget
              .profiles[widget.selectedIndex.clamp(
                0,
                widget.profiles.length - 1,
              )]
              .id ==
          profile.id;

  Widget _surface({
    required SeekerProfile profile,
    required Widget child,
    bool selectOnTap = false,
    bool edgeToEdge = false,
  }) {
    // Snapshot the guarded caller delegate for this render. An old card
    // callback must not borrow a newer delegate after Next or a route change.
    final onProfile = widget.readOnlyPreview || !widget.showFeedChrome
        ? null
        : widget.onProfile;
    return ZyraFloatingSurface(
      radius: ZyraCardMetrics.cardRadius,
      child: Material(
        key: _cardAnchors.putIfAbsent(profile.id, GlobalKey.new),
        color: edgeToEdge ? Colors.transparent : ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        clipBehavior: edgeToEdge ? Clip.antiAlias : Clip.none,
        child: Stack(
          children: [
            InkWell(
              key: ValueKey('concept_browse_open_${profile.id}'),
              borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
              onTap: ZyraTapFeedback.onTap(
                context,
                selectOnTap && onProfile != null
                    ? () => onProfile(profile)
                    : null,
              ),
              child: Padding(
                // Portrait uses the same outer bounds, with the photo filling
                // its former inset.
                padding: edgeToEdge
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(ZyraCardMetrics.padding + 1),
                child: child,
              ),
            ),
            if (widget.showFeedChrome)
              Positioned.fill(
                child: ZyraInvitationOutline(
                  key: ValueKey('browse_invitation_outline_${profile.id}'),
                  sent:
                      !widget.readOnlyPreview &&
                      widget.invitationSent?.call(profile) == true,
                  borderRadius: BorderRadius.circular(
                    ZyraCardMetrics.cardRadius,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _studyPhoto(
    SeekerProfile profile,
    int index,
    double height, {
    String keyPrefix = 'concept_browse_photo',
    bool rounded = true,
  }) {
    final photo = profile.photos.isEmpty
        ? ''
        : profile.photos[index.clamp(0, profile.photos.length - 1)];
    final renderedPhoto = widget.photoBuilder(
      context,
      photo,
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
    );
    return SizedBox(
      key: ValueKey('${keyPrefix}_${profile.id}_$index'),
      height: height,
      width: double.infinity,
      child: rounded
          ? ClipRRect(
              borderRadius: BorderRadius.circular(ZyraCardMetrics.thumbRadius),
              child: renderedPhoto,
            )
          : renderedPhoto,
    );
  }

  Widget _swipeGallery(
    SeekerProfile profile,
    double height, {
    bool tapToAdvance = false,
    bool neighbour = false,
  }) {
    final revision = _layoutRevision;
    final swipe = widget.profileSwipe;
    final preview = widget.ownPreviewActions;
    final avatarPhotoSize = ZyraProfileDetailsPage.photoSizeFor(
      profile.seekerPlan,
      showUnverifiedRing: preview == null,
    );
    return _BrowsePhotoPager(
      key: ValueKey('concept_browse_pager_${profile.id}_detailsFirst'),
      profileId: profile.id,
      hapticLevel: widget.hapticLevel,
      photoSources: List<String>.unmodifiable(profile.photos),
      photoCount: _galleryPageCount(profile),
      selectedIndex: neighbour ? 0 : _galleryIndex(profile),
      height: height,
      // Only the outer Current viewport is rounded. Sliding photos retain
      // their existing full bounds and seam geometry.
      photo: (index) => index == 0
          ? ZyraProfileDetailsPage(
              profile: profile,
              showUnverifiedRing: preview == null,
              requestAction: preview == null && swipe == null
                  ? null
                  : _inCardRequest(profile),
              firstPhoto: profile.photos.isEmpty || profile.photos.first.isEmpty
                  ? null
                  : widget.photoBuilder(
                      context,
                      profile.photos.first,
                      width: avatarPhotoSize,
                      height: avatarPhotoSize,
                      alignment: ZyraProfileDetailsPage.photoAlignment,
                    ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                _studyPhoto(profile, index - 1, height, rounded: !tapToAdvance),
              ],
            ),
      onPageChanged: (index) => _selectGalleryPage(profile, index, revision),
      tapToAdvance: tapToAdvance,
      allowPhotoDrag: preview == null && swipe == null,
      canNavigate:
          preview?.canAct ??
          (swipe == null
              ? null
              : () =>
                    _isCurrent(profile) &&
                    !_profileTrack.isMoving &&
                    swipe.canAct()),
    );
  }

  Widget _portraitCard(
    SeekerProfile profile,
    double height, {
    bool neighbour = false,
  }) => _surface(
    profile: profile,
    edgeToEdge: true,
    child: _swipeGallery(
      profile,
      height,
      tapToAdvance: true,
      neighbour: neighbour,
    ),
  );

  Widget _inCardRequest(SeekerProfile profile) {
    final revision = _layoutRevision;
    final preview = widget.ownPreviewActions;
    final request = widget.onRequest;
    final label =
        (preview == null ? widget.requestLabel?.call(profile) : null) ??
        'Request a Journey';
    final sent =
        preview == null && widget.invitationSent?.call(profile) == true;
    final allowed =
        preview != null ||
        request != null && (widget.canRequest?.call(profile) ?? true);
    final shape = StadiumBorder(
      side: BorderSide(
        color: ZyraColors.journeyGold.withValues(alpha: sent ? 1 : .6),
      ),
    );
    final action = ZyraTapFeedback.onTap(
      context,
      preview?.requestInfo ?? (allowed ? () => request!(profile) : null),
      canAct: () =>
          revision == _layoutRevision &&
          _isCurrent(profile) &&
          _galleryIndex(profile) == 0 &&
          (preview?.canAct() ??
              (!_profileTrack.isMoving &&
                  (widget.profileSwipe?.canAct() ?? false))),
      level: widget.hapticLevel == null ? null : () => widget.hapticLevel!,
    );
    return Semantics(
      label:
          (preview == null
              ? widget.requestSemanticLabel?.call(profile)
              : null) ??
          label,
      button: true,
      enabled: allowed,
      onTap: action,
      excludeSemantics: true,
      child: GestureDetector(
        // A disabled request occupies its own tap target. Touching it does
        // not activate the gallery tap behind it.
        excludeFromSemantics: true,
        onTap: action == null ? () {} : null,
        child: DecoratedBox(
          decoration: const ShapeDecoration(
            shape: StadiumBorder(),
            shadows: [
              BoxShadow(
                color: Color(0x143E2E1E),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: ZyraColors.ivoryTop,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('draft_profile_${profile.id}'),
              onTap: action,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style:
                          ZyraText.button(
                            size: 15,
                            color: sent
                                ? const Color(0xFF845F24)
                                : ZyraColors.espresso,
                          ).copyWith(
                            fontWeight: sent
                                ? FontWeight.w500
                                : FontWeight.w400,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileCarousel(
    SeekerProfile profile,
    double cardHeight,
    ZyraProfileSwipe swipe,
  ) {
    final profiles = widget.profiles;
    final previous = swipe.previousIndex;
    final next = swipe.nextIndex;
    final selected = widget.selectedIndex;
    final slots = [previous, selected, next];
    final revision = _layoutRevision;
    bool current() => mounted && revision == _layoutRevision && swipe.canAct();
    final hapticLevel = widget.hapticLevel;
    final settle = ZyraTapFeedback.onChanged<int>(
      context,
      (slot) => (slot == 0 ? widget.onPrevious : widget.onNext)?.call(),
      canAct: current,
      level: hapticLevel == null ? null : () => hapticLevel,
    );
    final blocked = ZyraTapFeedback.onTap(
      context,
      swipe.onBlockedPrevious,
      canAct: current,
      level: hapticLevel == null ? null : () => hapticLevel,
    );
    return Semantics(
      container: true,
      customSemanticsActions: {
        if (previous != null || blocked != null)
          const CustomSemanticsAction(label: 'Previous profile'): () {
            if (!current()) return;
            if (previous != null) {
              _profileTrack.animateTo(0);
            } else {
              blocked!();
            }
          },
        if (next != null)
          const CustomSemanticsAction(label: 'Next profile'): () {
            if (current()) _profileTrack.animateTo(2);
          },
      },
      child: ZyraSwipeTrack(
        key: const ValueKey('concept_profile_swipe_track'),
        controller: _profileTrack,
        index: 1,
        itemCount: slots.length,
        motionIdentity: (
          previous == null ? null : profiles[previous].id,
          profile.id,
          next == null ? null : profiles[next].id,
        ),
        canAct: current,
        canMoveTo: (slot) => slots[slot] != null,
        onBlockedPrevious: blocked,
        onSettled: settle!,
        itemBuilder: (_, slot) {
          final index = slots[slot];
          if (index == null) return const SizedBox.shrink();
          final person = profiles[index];
          return KeyedSubtree(
            key: ValueKey(person.id),
            child: _portraitCard(person, cardHeight, neighbour: slot != 1),
          );
        },
      ),
    );
  }

  Widget _header({Widget? dots}) {
    const key = ValueKey('concept_browse_header');
    final title = Text(
      'Profiles',
      key: const ValueKey('concept_browse_title'),
      textAlign: TextAlign.left,
      style: ZyraText.pageTitle(),
    );
    final action = widget.onBrowseMenu != null
        ? ZyraBrowseOptionsButton(
            alignToContentEdge: widget.alignHeaderActions,
            profile: widget.profiles.isEmpty
                ? null
                : widget.profiles[widget.selectedIndex.clamp(
                    0,
                    widget.profiles.length - 1,
                  )],
            onOpen: widget.onBrowseMenu!,
          )
        : widget.onFilters != null
        ? IconButton(
            key: const ValueKey('concept_filters'),
            tooltip: 'Profile filters',
            onPressed: ZyraTapFeedback.onTap(context, widget.onFilters),
            color: ZyraColors.journeyGold,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.tune, size: 20),
          )
        : null;
    if (dots == null) {
      return Row(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: title),
          ?action,
        ],
      );
    }
    return Stack(
      key: key,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(end: action == null ? 0 : 48),
              child: title,
            ),
            const SizedBox(height: ZyraPreviewSpacing.titleToDots),
            dots,
          ],
        ),
        if (action != null)
          PositionedDirectional(end: 0, top: 0, child: action),
      ],
    );
  }

  Widget _compactFooter(SeekerProfile? profile) {
    // Read-only controls retain the public unsent paint but never evaluate
    // caller decision/eligibility/label delegates, including adversarial ones.
    final onPrevious = widget.readOnlyPreview ? null : widget.onPrevious;
    final onNext = widget.readOnlyPreview ? null : widget.onNext;
    final onRequest = widget.readOnlyPreview ? null : widget.onRequest;
    final requestAllowed =
        profile != null &&
        onRequest != null &&
        (widget.canRequest?.call(profile) ?? true);
    if (widget.requestRowLabels != null && !widget.readOnlyPreview) {
      final label = profile == null
          ? 'Request Journey'
          : widget.requestLabel?.call(profile) ?? 'Request Journey';
      final sent =
          profile != null && widget.invitationSent?.call(profile) == true;
      return ZyraProfilesRequestRow(
        key: const ValueKey('concept_browse_footer'),
        actionKey: ValueKey('draft_profile_${profile?.id ?? 'empty'}'),
        label: label,
        semanticLabel: profile == null
            ? null
            : widget.requestSemanticLabel?.call(profile),
        labels: widget.requestRowLabels!,
        sent: sent,
        onPrevious: onPrevious,
        onNext: onNext,
        onRequest: requestAllowed ? () => onRequest(profile) : null,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        key: const ValueKey('concept_browse_footer'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ZyraProfilesBottomRow(
            previous: zyraProfilesPill(
              key: const ValueKey('concept_previous_profile'),
              label: 'Previous profile · no decision',
              icon: Icons.chevron_left,
              onTap: onPrevious,
            ),
            action: zyraProfilesPill(
              key: ValueKey('draft_profile_${profile?.id ?? 'empty'}'),
              label: widget.readOnlyPreview
                  ? 'Request a Journey'
                  : profile == null
                  ? 'Request Journey'
                  : widget.requestLabel?.call(profile) ?? 'Request Journey',
              semanticLabel: widget.readOnlyPreview || profile == null
                  ? null
                  : widget.requestSemanticLabel?.call(profile),
              primary: true,
              previewEnabledAppearance: widget.readOnlyPreview,
              invitationSent: widget.readOnlyPreview
                  ? false
                  : profile == null
                  ? null
                  : widget.invitationSent?.call(profile),
              minimumHeight:
                  widget.readOnlyPreview ||
                      (profile != null && widget.invitationSent != null)
                  ? _requestPillHeight(profile, constraints.maxWidth)
                  : _pillMinTapHeight,
              onTap: requestAllowed ? () => onRequest(profile) : null,
            ),
            next: zyraProfilesPill(
              key: const ValueKey('concept_next_profile'),
              label: 'Next profile · no decision',
              icon: Icons.chevron_right,
              iconSize: 24,
              onTap: onNext,
              previewEnabledAppearance: widget.readOnlyPreview,
            ),
          ),
        ],
      ),
    );
  }

  double _textHeight(String text, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(1, width));
    final height = painter.height;
    painter.dispose();
    return height;
  }

  TextStyle _requestStyle({Color? color}) => ZyraText.button(
    size: 14,
    color: color,
  ).copyWith(fontWeight: FontWeight.w400, height: 1.25, letterSpacing: .1);

  double _requestTextWidth(double footerWidth) => math.max(
    1.0,
    footerWidth -
        _backPillWidth -
        _nextPillWidth -
        2 * _footerGap -
        _pillBorderExtent -
        2 * _pillHorizontalTextPadding,
  );

  double _requestPillHeight(SeekerProfile? profile, double footerWidth) {
    final labels = widget.readOnlyPreview
        ? const ['Request a Journey', 'Journey invitation sent']
        : [
            profile == null
                ? 'Request Journey'
                : widget.requestLabel?.call(profile) ?? 'Request Journey',
            if (profile != null && widget.invitationSent != null) ...[
              'Request a Journey',
              'Journey invitation sent',
            ],
          ];
    final textHeight = labels
        .map(
          (label) => _textHeight(
            label,
            _requestStyle(),
            _requestTextWidth(footerWidth),
          ),
        )
        .reduce(math.max);
    return math.max(_pillMinTapHeight, 2 * _pillVerticalPadding + textHeight);
  }

  double _identityMinimumHeight(SeekerProfile profile, double width) {
    var height = _textHeight(
      profile.firstName,
      ZyraText.heading(size: 28).copyWith(fontWeight: FontWeight.w600),
      width,
    );
    if (profile.surnameLine?.trim().isNotEmpty ?? false) {
      height +=
          2 +
          _textHeight(
            profile.surnameLine!.trim(),
            ZyraText.heading(size: 16.8).copyWith(fontWeight: FontWeight.w500),
            width,
          );
    }
    height += 4 + _textHeight('28 · City', ZyraText.body(size: 14.924), width);
    for (final detail in [
      if (profile.publicNationality?.trim().isNotEmpty ?? false)
        'Nationality: ${profile.publicNationality!.trim()}',
      if (profile.publicEthnicity?.trim().isNotEmpty ?? false)
        'Ethnicity: ${profile.publicEthnicity!.trim()}',
    ]) {
      height += 4 + _textHeight(detail, ZyraText.body(size: 12), width);
    }
    return height + 72; // Room for pagination and padding above the identity.
  }

  double _footerReserve(BuildContext context) => math.max(
    widget.bottomPadding,
    math.max(
          MediaQuery.paddingOf(context).bottom,
          ZyraNavBarMetrics.bottomInset,
        ) +
        ZyraNavBarMetrics.height +
        12,
  );

  // Use the existing header/card gap so pagination never covers a portrait
  // or shifts its actions. Match the Guardian pager's quiet gold treatment.
  Widget _photoPagination(SeekerProfile? profile) {
    final revision = _layoutRevision;
    bool current() =>
        mounted &&
        revision == _layoutRevision &&
        profile != null &&
        _isCurrent(profile) &&
        (widget.profileSwipe?.canAct() ?? true) &&
        !_profileTrack.isMoving;
    return SizedBox(
      height: 24,
      child: profile == null || _galleryPageCount(profile) < 2
          ? null
          : ZyraProfilesDots(
              key: const ValueKey('concept_browse_photo_pagination'),
              count: _galleryPageCount(profile),
              index: _galleryIndex(profile),
              dotKey: (i) =>
                  ValueKey('concept_browse_photo_dot_${profile.id}_$i'),
              targetKey: (i) => ValueKey('concept_browse_dot_target_$i'),
              canAct: current,
              onSelected: (i) => _selectGalleryPage(profile, i, revision),
            ),
    );
  }

  Widget _portraitPage(SeekerProfile? profile) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final bottom = !widget.showFeedChrome
            ? 0.0
            : widget.fixedTabFooter
            ? widget.bottomPadding
            : _footerReserve(context);
        // The painted dot ends 9 pt before the bottom of its 24 pt target.
        final afterDots = widget.fixedTabFooter ? 3.0 : 0.0;
        final contentWidth = math.max(
          1.0,
          constraints.maxWidth - 2 * ZyraPreviewSpacing.pageMargin,
        );
        final showHeader = widget.showFeedChrome && !widget.readOnlyPreview;
        final profileSwipe = widget.profileSwipe;
        final showFooter = widget.showFeedChrome && profileSwipe == null;
        final lockedSpacing =
            showHeader &&
            (widget.requestRowLabels != null || profileSwipe != null);
        final headerHasDots =
            lockedSpacing && profile != null && _galleryPageCount(profile) >= 2;
        final cardToPill = lockedSpacing ? ZyraPreviewSpacing.cardToPill : 16.0;
        // Ink's one-pixel borders contribute two pixels to each pill/card.
        // Do not measure hidden feed labels: their delegates are outside an
        // inspection owner's authority, even when the result would not paint.
        final footerHeight = showFooter
            ? widget.requestRowLabels != null && !widget.readOnlyPreview
                  ? ZyraProfilesRequestRow.heightFor(
                      context,
                      contentWidth,
                      widget.requestRowLabels!,
                    )
                  : _requestPillHeight(profile, contentWidth) +
                        _pillBorderExtent
            : 0.0;
        final actionWidth =
            widget.onFilters == null && widget.onBrowseMenu == null
            ? 0.0
            : 48.0;
        final titleHeight = showHeader
            ? _textHeight(
                'Profiles',
                headerHasDots
                    ? DefaultTextStyle.of(
                        context,
                      ).style.merge(ZyraText.pageTitle())
                    : ZyraText.pageTitle(),
                contentWidth - (headerHasDots ? actionWidth : 48),
              )
            : 0.0;
        final headerHeight = headerHasDots
            ? titleHeight + ZyraPreviewSpacing.titleToDots
            : math.max(showHeader ? actionWidth : 0.0, titleHeight);
        final fittedHeight =
            constraints.maxHeight -
            24 -
            afterDots -
            bottom -
            headerHeight -
            16 -
            (showFooter ? cardToPill : 0) -
            footerHeight -
            2 * ZyraCardMetrics.padding -
            2;
        final photoHeight = widget.fixedTabFooter
            ? math.max(0.0, fittedHeight)
            : math.max(
                profile == null
                    ? 240.0
                    : math.max(
                        240.0,
                        _identityMinimumHeight(profile, contentWidth - 64),
                      ),
                math.min(620.0, fittedHeight),
              );
        final cardHeight = photoHeight + 2 * ZyraCardMetrics.padding + 2;
        return ZyraShadowScrollView(
          key: const ValueKey('concept_browse_design_scroll'),
          physics: widget.fixedTabFooter
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            ZyraPreviewSpacing.pageMargin,
            16,
            ZyraPreviewSpacing.pageMargin,
            bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (headerHasDots)
                _header(dots: _photoPagination(profile))
              else ...[
                if (showHeader)
                  SizedBox(height: headerHeight, child: _header()),
                _photoPagination(profile),
              ],
              if (afterDots > 0) SizedBox(height: afterDots),
              profile == null
                  ? Text(
                      'No profiles to view right now.',
                      style: ZyraText.body(
                        size: 14,
                        color: ZyraColors.ink(.65),
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('concept_browse_portrait_card'),
                      child: SizedBox(
                        height: cardHeight,
                        child: profileSwipe != null
                            ? _profileCarousel(
                                profile,
                                cardHeight,
                                profileSwipe,
                              )
                            : ZyraFloatingSurface(
                                radius: ZyraCardMetrics.cardRadius,
                                child: ZyraBrowseNextPhotoMotion(
                                  key: const ValueKey(
                                    'concept_browse_next_motion',
                                  ),
                                  profileId: profile.id,
                                  epoch: widget.nextProfileMotionEpoch,
                                  style: widget.nextProfileMotion,
                                  child: _portraitCard(profile, cardHeight),
                                ),
                              ),
                      ),
                    ),
              if (showFooter) ...[
                SizedBox(height: cardToPill),
                _compactFooter(profile),
              ],
            ],
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final profiles = widget.profiles;
    final current = profiles.isEmpty
        ? null
        : profiles[widget.selectedIndex.clamp(0, profiles.length - 1)];
    if (widget.ownPreviewActions != null && current != null) {
      return LayoutBuilder(
        builder: (context, constraints) => KeyedSubtree(
          key: const ValueKey('concept_browse_portrait_card'),
          child: _portraitCard(current, constraints.maxHeight),
        ),
      );
    }
    return _portraitPage(current);
  }
}

/// A local photo pager only. It never moves to another profile or borrows a
/// request delegate. The caller owns index validity and account/route guards.
class _BrowsePhotoPager extends StatefulWidget {
  const _BrowsePhotoPager({
    super.key,
    required this.profileId,
    this.hapticLevel,
    required this.photoSources,
    required this.photoCount,
    required this.selectedIndex,
    required this.height,
    required this.photo,
    required this.onPageChanged,
    this.tapToAdvance = false,
    this.allowPhotoDrag = true,
    this.canNavigate,
  });

  final String profileId;
  final ZyraHapticLevel? hapticLevel;
  final List<String> photoSources;
  final int photoCount;
  final int selectedIndex;
  final double height;
  final Widget Function(int) photo;
  final ValueChanged<int> onPageChanged;
  final bool tapToAdvance;
  final bool allowPhotoDrag;
  final bool Function()? canNavigate;

  @override
  State<_BrowsePhotoPager> createState() => _BrowsePhotoPagerState();
}

class _BrowsePhotoPagerState extends State<_BrowsePhotoPager>
    with SingleTickerProviderStateMixin {
  static const _currentPhotoDuration = Duration(milliseconds: 420);
  late final PageController _controller;
  late final AnimationController _wrapMotion;
  late Animation<Offset> _wrapIncomingOffset;
  late Animation<Offset> _wrapOutgoingOffset;
  Widget? _wrapPhoto;
  int? _tapTargetIndex;
  int _motionEpoch = 0;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.selectedIndex);
    _wrapMotion =
        AnimationController(
          vsync: this,
          duration: _currentPhotoDuration,
          value: 1,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed &&
              mounted &&
              _wrapPhoto != null) {
            setState(() {
              _wrapPhoto = null;
              _tapTargetIndex = null;
            });
          }
        });
    _configureWrapMotion(1);
  }

  void _configureWrapMotion(int direction) {
    final motion = _wrapMotion.drive(CurveTween(curve: Curves.easeInOutCubic));
    _wrapIncomingOffset = motion.drive(
      Tween<Offset>(begin: Offset(direction.toDouble(), 0), end: Offset.zero),
    );
    _wrapOutgoingOffset = motion.drive(
      Tween<Offset>(begin: Offset.zero, end: Offset(-direction.toDouble(), 0)),
    );
  }

  bool get _quiet =>
      MediaQuery.disableAnimationsOf(context) ||
      (widget.tapToAdvance && MediaQuery.accessibleNavigationOf(context));

  void _cancelPhotoMotion() {
    ++_motionEpoch;
    _wrapMotion.stop();
    _wrapPhoto = null;
    _tapTargetIndex = null;
    _wrapMotion.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_quiet || _tapTargetIndex == null) return;
    final target = _tapTargetIndex!;
    _cancelPhotoMotion();
    final epoch = _motionEpoch;
    // A dependency change can occur during parent layout. Finish the owned
    // tap on the next frame, never dispatch a parent selection during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          epoch != _motionEpoch ||
          !_quiet ||
          !_controller.hasClients) {
        return;
      }
      _controller.jumpToPage(target.clamp(0, widget.photoCount - 1));
    });
  }

  @override
  void didUpdateWidget(covariant _BrowsePhotoPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    ++_revision;
    final sourceChanged =
        oldWidget.profileId != widget.profileId ||
        oldWidget.tapToAdvance != widget.tapToAdvance ||
        !listEquals(oldWidget.photoSources, widget.photoSources);
    final externalSelection =
        oldWidget.selectedIndex != widget.selectedIndex &&
        widget.selectedIndex != _tapTargetIndex;
    if (sourceChanged || externalSelection) _cancelPhotoMotion();
    if (!sourceChanged &&
        oldWidget.selectedIndex == widget.selectedIndex &&
        oldWidget.photoCount == widget.photoCount) {
      return;
    }
    final selected = widget.selectedIndex;
    final profileId = widget.profileId;
    final epoch = _motionEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          epoch != _motionEpoch ||
          widget.profileId != profileId ||
          widget.selectedIndex != selected ||
          !_controller.hasClients ||
          (!sourceChanged && _controller.position.isScrollingNotifier.value)) {
        return;
      }
      // A same-count source replacement must terminate the old driven
      // activity even when its fractional position rounds to this index.
      if (sourceChanged || _controller.page?.round() != selected) {
        _controller.jumpToPage(selected);
      }
    });
  }

  @override
  void dispose() {
    _wrapMotion.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _canShowPhoto(int revision, int selected) =>
      mounted &&
      revision == _revision &&
      (widget.canNavigate?.call() ?? true) &&
      widget.photoCount > 1 &&
      _controller.hasClients &&
      _controller.page?.round() == selected &&
      (!widget.tapToAdvance ||
          (!_controller.position.isScrollingNotifier.value &&
              _wrapPhoto == null));

  void _showPhoto(int index, {required int cyclicDirection}) {
    // The bounded pager rebases once at a wrap. Both prepared photos slide
    // across that boundary at the ordinary tap speed, never dissolve or travel
    // through intermediate photos. Identity, markers and actions stay fixed.
    final visible = _controller.page?.round() ?? widget.selectedIndex;
    final wraps =
        widget.tapToAdvance &&
        ((cyclicDirection == 1 &&
                visible == widget.photoCount - 1 &&
                index == 0) ||
            (cyclicDirection == -1 &&
                visible == 0 &&
                index == widget.photoCount - 1));
    if (_quiet) {
      _controller.jumpToPage(index);
    } else if (wraps) {
      ++_motionEpoch;
      setState(() {
        _tapTargetIndex = index;
        _wrapPhoto = widget.photo(visible);
        _configureWrapMotion(cyclicDirection);
      });
      _controller.jumpToPage(index);
      _wrapMotion.forward(from: 0);
    } else {
      _tapTargetIndex = index;
      final epoch = ++_motionEpoch;
      unawaited(
        _controller
            .animateToPage(
              index,
              duration: widget.tapToAdvance
                  ? _currentPhotoDuration
                  : const Duration(milliseconds: 220),
              curve: widget.tapToAdvance
                  ? Curves.easeInOutCubic
                  : Curves.easeOutCubic,
            )
            .whenComplete(() {
              if (mounted && epoch == _motionEpoch) _tapTargetIndex = null;
            }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPageChanged = widget.onPageChanged;
    final revision = _revision;
    final selected = widget.selectedIndex;
    final count = widget.photoCount;
    // Q13/Q15: the physical and accessible actions share the pager's
    // authority and motion guard before the feedback wrapper emits a tick.
    final hapticLevel = widget.hapticLevel;
    final select = ZyraTapFeedback.onChanged<int>(
      context,
      count < 2
          ? null
          : (direction) => _showPhoto(
              (selected + direction) % count,
              cyclicDirection: direction,
            ),
      canAct: () => _canShowPhoto(revision, selected),
      level: hapticLevel == null ? null : () => hapticLevel,
    );
    final advance = select == null ? null : () => select(1);
    Widget pager = PageView.builder(
      key: ValueKey('concept_browse_photo_swipe_${widget.profileId}'),
      controller: _controller,
      itemCount: widget.photoCount,
      physics: widget.allowPhotoDrag
          ? null
          : const NeverScrollableScrollPhysics(),
      onPageChanged: onPageChanged,
      itemBuilder: (_, index) => widget.photo(index),
    );
    if (widget.tapToAdvance) {
      pager = SlideTransition(
        key: ValueKey('concept_browse_photo_wrap_incoming_${widget.profileId}'),
        position: _wrapIncomingOffset,
        // Keep the full viewport interactive while its painted frame slides.
        transformHitTests: false,
        child: pager,
      );
      pager = NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null) {
            setState(_cancelPhotoMotion);
          }
          return false;
        },
        child: pager,
      );
      pager = GestureDetector(
        key: ValueKey('concept_browse_photo_tap_${widget.profileId}'),
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapUp: select == null
            ? null
            : (details) {
                if (!_canShowPhoto(revision, selected)) return;
                final width = _controller.position.viewportDimension;
                final x = details.localPosition.dx;
                if (!width.isFinite || width <= 0 || !x.isFinite) return;
                // Physical halves, not reading direction. Details keeps its
                // tap-to-photos entry; a photo's left half goes back one page.
                select(selected != 0 && x < width / 2 ? -1 : 1);
              },
        child: pager,
      );
    }
    return Semantics(
      label: widget.selectedIndex == 0
          ? 'Profile details'
          : widget.photoSources.isEmpty
          ? 'No photos available'
          : 'Photo ${widget.selectedIndex} of ${widget.photoSources.length}',
      button: widget.tapToAdvance && advance != null,
      onTap: widget.tapToAdvance ? advance : null,
      hint: widget.photoCount > 1
          ? widget.tapToAdvance
                ? widget.allowPhotoDrag
                      ? 'Tap or swipe to view details and photos'
                      : 'Tap to view details and photos'
                : 'Swipe to view details and photos'
          : null,
      customSemanticsActions: select == null
          ? null
          : {
              CustomSemanticsAction(label: 'Previous page'): () => select(-1),
              CustomSemanticsAction(label: 'Next page'): () => select(1),
            },
      child: SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ZyraCardMetrics.thumbRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              pager,
              if (_wrapPhoto != null)
                IgnorePointer(
                  child: ExcludeSemantics(
                    child: SlideTransition(
                      key: ValueKey(
                        'concept_browse_photo_wrap_${widget.profileId}',
                      ),
                      position: _wrapOutgoingOffset,
                      child: _wrapPhoto,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
