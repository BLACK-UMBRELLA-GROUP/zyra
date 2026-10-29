// Shared Portrait Browse with caller-owned identity, selection and actions.
// This presenter owns only per-profile gallery position and layout. It has no
// services, account, matching, admission, entitlement or persistence authority.
// Photo rendering is required and explicitly supplied by the caller; this
// widget has no default image provider or ability to fetch a photo.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/seeker_profile.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';
import 'floating_nav_bar.dart';
import 'zyra_browse_options_button.dart';
import 'zyra_browse_next_photo_motion.dart';
import 'zyra_invitation_label.dart';
import 'zyra_invitation_outline.dart';
import 'zyra_press_feedback.dart';
import 'zyra_profile_details_page.dart';

/// Explicit rendering seam. The caller supplies already-authorised photo
/// references and the renderer; a reference alone never initiates a fetch here.
/// Dimensions and alignment preserve the current bounded photo presentation.
typedef ZyraBrowsePhotoBuilder =
    Widget Function(
      BuildContext context,
      String photo, {
      required double width,
      required double height,
      required Alignment alignment,
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
    this.invitationSent,
    this.canRequest,
    this.bottomPadding = 100,
    this.alignHeaderActions = false,
    this.nextProfileMotion = ZyraBrowseNextMotion.current,
    this.nextProfileMotionEpoch = 0,
    this.hapticLevel,
    this.initialPhotoIndices = const <String, int>{},
    this.onPhotoIndexChanged,
    this.initialGalleryIndices = const <String, int>{},
    this.onGalleryIndexChanged,
  });

  final List<SeekerProfile> profiles;
  final ZyraBrowsePhotoBuilder photoBuilder;

  /// Own-profile presentation only. Shows inert feed controls, without menu;
  /// this flag never supplies profile data or changes disclosure authority.
  final bool readOnlyPreview;

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
  final bool Function(SeekerProfile)? invitationSent;
  final bool Function(SeekerProfile)? canRequest;
  final double bottomPadding;
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
        index < 0 ||
        index >= _galleryPageCount(profile) ||
        index == _galleryIndex(profile)) {
      return;
    }
    unawaited(
      ZyraInteractionStyle.emitSelectionHaptic(level: widget.hapticLevel),
    );
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
    return Material(
      key: _cardAnchors.putIfAbsent(profile.id, GlobalKey.new),
      color: edgeToEdge ? Colors.transparent : ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
      clipBehavior: edgeToEdge ? Clip.antiAlias : Clip.none,
      child: Stack(
        children: [
          InkWell(
            key: ValueKey('concept_browse_open_${profile.id}'),
            borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
            onTap: selectOnTap && onProfile != null
                ? () => onProfile(profile)
                : null,
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
                borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
              ),
            ),
        ],
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
      alignment: Alignment.topCenter,
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
  }) {
    final revision = _layoutRevision;
    return _BrowsePhotoPager(
      key: ValueKey('concept_browse_pager_${profile.id}_detailsFirst'),
      profileId: profile.id,
      photoSources: List<String>.unmodifiable(profile.photos),
      photoCount: _galleryPageCount(profile),
      selectedIndex: _galleryIndex(profile),
      height: height,
      // Only the outer Current viewport is rounded. Sliding photos retain
      // their existing full bounds and seam geometry.
      photo: (index) => index == 0
          ? ZyraProfileDetailsPage(
              profile: profile,
              firstPhoto: profile.photos.isEmpty || profile.photos.first.isEmpty
                  ? null
                  : widget.photoBuilder(
                      context,
                      profile.photos.first,
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
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
    );
  }

  Widget _portraitCard(SeekerProfile profile, double photoHeight) => _surface(
    profile: profile,
    edgeToEdge: true,
    child: _swipeGallery(
      profile,
      photoHeight + 2 * ZyraCardMetrics.padding + 2,
      tapToAdvance: true,
    ),
  );

  Widget _header() => Row(
    key: const ValueKey('concept_browse_header'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          'Profiles',
          key: const ValueKey('concept_browse_title'),
          textAlign: TextAlign.left,
          style: ZyraText.pageTitle(),
        ),
      ),
      if (!widget.readOnlyPreview && widget.onBrowseMenu != null)
        ZyraBrowseOptionsButton(
          alignToContentEdge: widget.alignHeaderActions,
          profile: widget.profiles.isEmpty
              ? null
              : widget.profiles[widget.selectedIndex.clamp(
                  0,
                  widget.profiles.length - 1,
                )],
          onOpen: widget.onBrowseMenu!,
        )
      else if (!widget.readOnlyPreview && widget.onFilters != null)
        IconButton(
          key: const ValueKey('concept_filters'),
          tooltip: 'Profile filters',
          onPressed: widget.onFilters,
          color: ZyraColors.journeyGold,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.tune, size: 20),
        ),
    ],
  );

  Widget _compactPill({
    required Key key,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    double iconSize = 20,
    bool primary = false,
    bool previewEnabledAppearance = false,
    bool? invitationSent,
    double minimumHeight = _pillMinTapHeight,
  }) => Semantics(
    button: true,
    enabled: onTap != null,
    label: invitationSent == true ? '$label. Tap to cancel invitation' : label,
    onTap: onTap,
    excludeSemantics: true,
    child: ZyraPressFeedback(
      enabled: primary && onTap != null,
      child: Material(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: primary
                  ? ZyraColors.journeyGold.withValues(
                      alpha: invitationSent == true ? .85 : .55,
                    )
                  : ZyraColors.surfaceBorder,
            ),
          ),
          child: InkWell(
            key: key,
            onTap: onTap,
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(999),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 48,
                minHeight: minimumHeight,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: icon == null ? _pillHorizontalTextPadding : 8,
                  vertical: _pillVerticalPadding,
                ),
                child: Center(
                  child: icon == null
                      ? invitationSent != null
                            ? ZyraInvitationLabel(
                                label: label,
                                sent: invitationSent,
                                style: _requestStyle(
                                  color: ZyraColors.ink(
                                    onTap == null && !previewEnabledAppearance
                                        ? .34
                                        : .90,
                                  ),
                                ),
                              )
                            : Text(
                                label,
                                textAlign: TextAlign.center,
                                style: primary
                                    ? _requestStyle(
                                        color: ZyraColors.ink(
                                          onTap == null &&
                                                  !previewEnabledAppearance
                                              ? .34
                                              : .90,
                                        ),
                                      )
                                    : ZyraText.button(
                                        size: 12.5,
                                        color: ZyraColors.ink(
                                          onTap == null &&
                                                  !previewEnabledAppearance
                                              ? .34
                                              : .90,
                                        ),
                                      ),
                              )
                      : Icon(
                          icon,
                          size: iconSize,
                          color: onTap == null && !previewEnabledAppearance
                              ? ZyraColors.ink(.34)
                              : ZyraColors.journeyGold,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

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
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        key: const ValueKey('concept_browse_footer'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: _backPillWidth,
                child: _compactPill(
                  key: const ValueKey('concept_previous_profile'),
                  label: 'Previous profile · no decision',
                  icon: Icons.chevron_left,
                  onTap: onPrevious,
                ),
              ),
              const SizedBox(width: _footerGap),
              Expanded(
                child: _compactPill(
                  key: ValueKey('draft_profile_${profile?.id ?? 'empty'}'),
                  label: widget.readOnlyPreview
                      ? 'Request a Journey'
                      : profile == null
                      ? 'Request Journey'
                      : widget.requestLabel?.call(profile) ?? 'Request Journey',
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
              ),
              const SizedBox(width: _footerGap),
              SizedBox(
                width: _nextPillWidth,
                child: _compactPill(
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
  Widget _photoPagination(SeekerProfile? profile) => SizedBox(
    height: 16,
    child: profile == null || _galleryPageCount(profile) < 2
        ? null
        : IgnorePointer(
            child: ExcludeSemantics(
              child: Row(
                key: const ValueKey('concept_browse_photo_pagination'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (
                    var index = 0;
                    index < _galleryPageCount(profile);
                    index++
                  )
                    Transform.translate(
                      // Lift only the marks; keep the card and gap unchanged.
                      offset: const Offset(0, -4),
                      child: AnimatedContainer(
                        key: ValueKey(
                          'concept_browse_photo_dot_${profile.id}_$index',
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        width: index == _galleryIndex(profile) ? 20 : 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == _galleryIndex(profile)
                              ? ZyraColors.journeyGold
                              : ZyraColors.ink(.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
  );

  Widget _portraitPage(SeekerProfile? profile) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final bottom = widget.showFeedChrome ? _footerReserve(context) : 0.0;
        final available = math.max(0.0, constraints.maxHeight - 16 - bottom);
        final contentWidth = math.max(1.0, constraints.maxWidth - 40);
        // Ink's one-pixel borders contribute two pixels to each pill/card.
        // Do not measure hidden feed labels: their delegates are outside an
        // inspection owner's authority, even when the result would not paint.
        final footerHeight = widget.showFeedChrome
            ? _requestPillHeight(profile, contentWidth) + _pillBorderExtent
            : 0.0;
        final headerHeight = widget.readOnlyPreview || !widget.showFeedChrome
            ? 0.0
            : math.max(
                widget.onFilters == null && widget.onBrowseMenu == null
                    ? 0.0
                    : 48.0,
                _textHeight(
                  'Profiles',
                  ZyraText.pageTitle(),
                  contentWidth - 48,
                ),
              );
        final photoHeight = math.max(
          profile == null
              ? 240.0
              : math.max(
                  240.0,
                  _identityMinimumHeight(profile, contentWidth - 64),
                ),
          math.min(
            620.0,
            available -
                headerHeight -
                (widget.showFeedChrome ? 32 : 16) -
                footerHeight -
                2 * ZyraCardMetrics.padding -
                2,
          ),
        );
        return SingleChildScrollView(
          key: const ValueKey('concept_browse_design_scroll'),
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showFeedChrome && !widget.readOnlyPreview)
                SizedBox(height: headerHeight, child: _header()),
              _photoPagination(profile),
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
                        height: photoHeight + 2 * ZyraCardMetrics.padding + 2,
                        child: ZyraBrowseNextPhotoMotion(
                          key: const ValueKey('concept_browse_next_motion'),
                          profileId: profile.id,
                          epoch: widget.nextProfileMotionEpoch,
                          style: widget.nextProfileMotion,
                          child: _portraitCard(profile, photoHeight),
                        ),
                      ),
                    ),
              if (widget.showFeedChrome) ...[
                const SizedBox(height: 16),
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
    return _portraitPage(current);
  }
}

/// A local photo pager only. It never moves to another profile or borrows a
/// request delegate. The caller owns index validity and account/route guards.
class _BrowsePhotoPager extends StatefulWidget {
  const _BrowsePhotoPager({
    super.key,
    required this.profileId,
    required this.photoSources,
    required this.photoCount,
    required this.selectedIndex,
    required this.height,
    required this.photo,
    required this.onPageChanged,
    this.tapToAdvance = false,
  });

  final String profileId;
  final List<String> photoSources;
  final int photoCount;
  final int selectedIndex;
  final double height;
  final Widget Function(int) photo;
  final ValueChanged<int> onPageChanged;
  final bool tapToAdvance;

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

  void _showPhoto(int index, int revision, {int? cyclicDirection}) {
    if (!mounted ||
        revision != _revision ||
        widget.photoCount < 2 ||
        index < 0 ||
        index >= widget.photoCount ||
        !_controller.hasClients ||
        (widget.tapToAdvance &&
            (_controller.position.isScrollingNotifier.value ||
                _wrapPhoto != null))) {
      return;
    }
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
        _configureWrapMotion(cyclicDirection!);
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
    final advance = widget.tapToAdvance && count > 1
        ? () => _showPhoto((selected + 1) % count, revision, cyclicDirection: 1)
        : null;
    Widget pager = PageView.builder(
      key: ValueKey('concept_browse_photo_swipe_${widget.profileId}'),
      controller: _controller,
      itemCount: widget.photoCount,
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
        onTapUp: advance == null
            ? null
            : (details) {
                if (!mounted ||
                    revision != _revision ||
                    !_controller.hasClients) {
                  return;
                }
                final width = _controller.position.viewportDimension;
                final x = details.localPosition.dx;
                if (!width.isFinite || width <= 0 || !x.isFinite) return;
                // Physical halves, not reading direction. Details keeps its
                // tap-to-photos entry; a photo's left half goes back one page.
                final isDetailsPage = selected == 0;
                final direction = !isDetailsPage && x < width / 2 ? -1 : 1;
                _showPhoto(
                  (selected + direction) % count,
                  revision,
                  cyclicDirection: direction,
                );
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
      button: advance != null,
      onTap: advance,
      hint: widget.photoCount > 1
          ? widget.tapToAdvance
                ? 'Tap or swipe to view details and photos'
                : 'Swipe to view details and photos'
          : null,
      customSemanticsActions: widget.photoCount < 2
          ? null
          : {
              CustomSemanticsAction(label: 'Previous page'): () => _showPhoto(
                (selected - 1) % count,
                revision,
                cyclicDirection: -1,
              ),
              CustomSemanticsAction(label: 'Next page'): () => _showPhoto(
                (selected + 1) % count,
                revision,
                cyclicDirection: 1,
              ),
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
