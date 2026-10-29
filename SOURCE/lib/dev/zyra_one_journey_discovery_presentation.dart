// Pure presentation for the protected One Journey comparison. The source of
// the visual rules is the current Browse/Connections screen, not a new design.
// No account, service, persistence, matching or permission authority lives here.
// Callers supply only local profiles, images and already-guarded callbacks.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../screens/connections/connections_section_controller.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_invitation_label.dart';
import '../widgets/zyra_press_feedback.dart';
import '../widgets/zyra_profile_name_block.dart';
import '../widgets/zyra_pull_down_back_scope.dart';
import '../widgets/zyra_segmented_toggle.dart';
import '../widgets/floating_nav_bar.dart' show ZyraNavBarMetrics;
import 'zyra_one_journey_card_content.dart';

/// A caller can resolve an existing bundled sample without a network provider.
typedef ZyraOneJourneyPhotoBuilder =
    Widget Function(BuildContext context, String photo);

Widget _profileImage(BuildContext context, String photo) =>
    ZyraProfileImage(photo, width: double.infinity, height: double.infinity);

/// Current edge-to-edge Browse: the same photo, gallery, dots, scrim and public
/// three-line name block. Only the decision verbs are replaced in this draft.
class ZyraOneJourneyBrowsePresentation extends StatefulWidget {
  const ZyraOneJourneyBrowsePresentation({
    super.key,
    required this.profile,
    required this.onMenu,
    this.onPreviousProfile,
    this.onNextProfile,
    this.onRequest,
    this.requestLabel = 'Request Journey',
    this.requestSemanticLabel,
    this.invitationSent,
    this.imageBuilder = _profileImage,
    this.previousKey,
    this.nextKey,
    this.requestKey,
    this.menuKey,
    this.menuButton,
    this.menuLabel = 'Profile options',
    this.menuIcon = Icons.more_horiz,
    this.menuOnLeft = false,
    this.showMenu = true,
    this.identityBottom,
    this.actionsBottom,
    this.showActions = true,
    this.onDismiss,
    this.initialPhotoIndex = 0,
    this.onPhotoIndexChanged,
  });

  final SeekerProfile profile;
  final VoidCallback onMenu;
  final VoidCallback? onPreviousProfile;
  final VoidCallback? onNextProfile;
  final VoidCallback? onRequest;
  final String requestLabel;
  final String? requestSemanticLabel;
  final bool? invitationSent;
  final ZyraOneJourneyPhotoBuilder imageBuilder;
  final Key? previousKey;
  final Key? nextKey;
  final Key? requestKey;
  final Key? menuKey;
  final Widget? menuButton;
  final String menuLabel;
  final IconData menuIcon;
  final bool menuOnLeft;
  final bool showMenu;
  final double? identityBottom;
  final double? actionsBottom;
  final bool showActions;

  /// Opt-in dismissal for a temporary full-photo inspection. The caller owns
  /// the return destination and supplies an already-guarded callback. Other
  /// viewers retain their existing tap-only photo navigation.
  final VoidCallback? onDismiss;

  /// Restored once, before first paint. Profile changes keep the existing
  /// first-photo reset; subsequent seed changes never seek the current photo.
  final int initialPhotoIndex;
  final ValueChanged<int>? onPhotoIndexChanged;

  @override
  State<ZyraOneJourneyBrowsePresentation> createState() =>
      _ZyraOneJourneyBrowsePresentationState();
}

class _ZyraOneJourneyBrowsePresentationState
    extends State<ZyraOneJourneyBrowsePresentation> {
  int _photoIndex = 0;
  int _renderEpoch = 0;
  bool _dismissCommitted = false;
  int _backRevision = 0;

  @override
  void initState() {
    super.initState();
    _photoIndex = widget.profile.photos.isEmpty
        ? 0
        : widget.initialPhotoIndex.clamp(0, widget.profile.photos.length - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = ZyraBackNavigationPreview.revisionOf(context);
    if (revision != _backRevision) {
      _backRevision = revision;
      ++_renderEpoch;
      _dismissCommitted = false;
    }
  }

  @override
  void didUpdateWidget(covariant ZyraOneJourneyBrowsePresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    ++_renderEpoch;
    _dismissCommitted = false;
    if (oldWidget.profile.id != widget.profile.id ||
        _photoIndex >= widget.profile.photos.length) {
      _photoIndex = 0;
    }
  }

  void _tapPhoto(TapUpDetails details, double width, int epoch) {
    if (!mounted || epoch != _renderEpoch) return;
    final count = widget.profile.photos.length;
    if (count <= 1) return;
    final next = details.localPosition.dx >= width / 2
        ? (_photoIndex + 1) % count
        : (_photoIndex - 1).clamp(0, count - 1);
    if (next == _photoIndex) return;
    setState(() {
      _photoIndex = next;
    });
    widget.onPhotoIndexChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final photos = profile.photos;
    final photo = photos.isEmpty ? '' : photos[_photoIndex];
    final actionsBottom = widget.actionsBottom ?? 85;
    final identityBottom = widget.identityBottom ?? 130;
    final epoch = _renderEpoch;
    final dismiss = widget.onDismiss;
    void buttonBack() {
      if (!mounted ||
          epoch != _renderEpoch ||
          dismiss == null ||
          !identical(dismiss, widget.onDismiss) ||
          _dismissCommitted ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      _dismissCommitted = true;
      dismiss();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final surface = GestureDetector(
          key: const ValueKey('concept_browse_photo_gallery'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _tapPhoto(details, constraints.maxWidth, epoch),
          child: KeyedSubtree(
            key: widget.onDismiss == null
                ? null
                : const ValueKey('concept_browse_photo_dismiss_surface'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.imageBuilder(context, photo),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 340,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x4D000000),
                            Color(0xB3000000),
                          ],
                          stops: [0, .32, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                if (photos.length > 1)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < photos.length; i++)
                            Container(
                              key: ValueKey('concept_browse_photo_dot_$i'),
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .3),
                                  width: .5,
                                ),
                                color: i == _photoIndex
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: .32),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: identityBottom,
                  child: IgnorePointer(
                    child: ZyraProfileNameBlock(profile: profile),
                  ),
                ),
                if (widget.showActions)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: actionsBottom,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ZyraOneJourneyConnectionsActionButton(
                            invitationSent: widget.invitationSent,
                            semanticLabel: widget.requestSemanticLabel,
                            action: ZyraOneJourneyConnectionsAction(
                              key: widget.requestKey,
                              label: widget.requestLabel,
                              icon: Icons.route_outlined,
                              onTap: widget.onRequest,
                            ),
                            primary: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onPreviousProfile != null)
                            _PhotoIcon(
                              key: widget.previousKey,
                              label: 'Previous profile · no decision',
                              icon: Icons.chevron_left,
                              onTap: widget.onPreviousProfile!,
                            ),
                          if (widget.onNextProfile != null)
                            _PhotoIcon(
                              key: widget.nextKey,
                              label: 'Next profile · no decision',
                              icon: Icons.chevron_right,
                              onTap: widget.onNextProfile!,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.showMenu)
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: widget.menuOnLeft
                          ? Alignment.topLeft
                          : Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 8,
                          left: widget.menuOnLeft ? 16 : 0,
                          right: widget.menuOnLeft ? 0 : 16,
                        ),
                        child:
                            widget.menuButton ??
                            _PhotoIcon(
                              key: widget.menuKey,
                              label: widget.menuLabel,
                              icon: widget.menuIcon,
                              onTap: widget.onMenu,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        return widget.onDismiss != null
            ? ZyraPullDownCloseCue(
                enabled: !_dismissCommitted,
                onBack: buttonBack,
                routeIdentity: (profile.id, epoch),
                child: surface,
              )
            : surface;
      },
    );
  }
}

class _PhotoIcon extends StatelessWidget {
  const _PhotoIcon({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
            shadows: const [Shadow(color: Color(0x8C000000), blurRadius: 6)],
          ),
        ),
      ),
    ),
  );
}

/// The current Connections header and swipe-linked segment control. Pages
/// keep independent scroll positions; changing methodology does not replace
/// the app's established page motion with a conditional Column.
class ZyraOneJourneyConnectionsPresentation extends StatefulWidget {
  const ZyraOneJourneyConnectionsPresentation({
    super.key,
    required this.labels,
    required this.pages,
    required this.selectedIndex,
    required this.onChanged,
    this.segmentKeys = const [],
    this.badges = const [],
    this.bottomPadding = 100,
    this.pageTopPadding = 16,
    this.title = 'Connections',
    this.titleAlignment = Alignment.centerLeft,
    this.fillSinglePage = false,
    this.singlePageMaxHeight,
    this.expandedCard,
    this.onBack,
  }) : assert(labels.length == pages.length),
       assert(selectedIndex >= 0 && selectedIndex < labels.length);

  final List<String> labels;
  final List<List<Widget>> pages;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<Key> segmentKeys;
  final List<int> badges;
  final double bottomPadding;
  final double pageTopPadding;
  final String title;
  final Alignment titleAlignment;
  final bool fillSinglePage;
  final double? singlePageMaxHeight;
  final Widget? expandedCard;
  final VoidCallback? onBack;

  @override
  State<ZyraOneJourneyConnectionsPresentation> createState() =>
      _ZyraOneJourneyConnectionsPresentationState();
}

class _ZyraOneJourneyConnectionsPresentationState
    extends State<ZyraOneJourneyConnectionsPresentation> {
  late final PageController _pager;
  late double _position;
  int _renderRevision = 0;
  int _selectionRevision = 0;

  @override
  void initState() {
    super.initState();
    _position = widget.selectedIndex.toDouble();
    _pager = PageController(initialPage: widget.selectedIndex, keepPage: false);
    _pager.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _pager.page;
    if (page != null && mounted && page != _position) {
      setState(() => _position = page);
    }
  }

  void _select(int index) {
    if (!mounted ||
        !_pager.hasClients ||
        index < 0 ||
        index >= widget.pages.length) {
      return;
    }
    _selectionRevision++;
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _pager.jumpToPage(index);
    } else {
      unawaited(ZyraSegmentedMotion.animateToPage(_pager, index));
    }
  }

  @override
  void didUpdateWidget(covariant ZyraOneJourneyConnectionsPresentation old) {
    super.didUpdateWidget(old);
    final selection = ++_selectionRevision;
    final target = widget.selectedIndex;
    if (old.selectedIndex != widget.selectedIndex &&
        _position.round() != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            selection == _selectionRevision &&
            target == widget.selectedIndex) {
          _select(target);
        }
      });
    }
  }

  @override
  void dispose() {
    _pager.removeListener(_onScroll);
    _pager.dispose();
    super.dispose();
  }

  Widget _filledPage(BuildContext context, BoxConstraints constraints) {
    // Reserve the expanded bar, not just its resting height, so a press cannot
    // cover the last card. Content uses the real remaining viewport height.
    final bottom =
        math.max(
          MediaQuery.paddingOf(context).bottom,
          ZyraNavBarMetrics.bottomInset,
        ) +
        ZyraNavBarMetrics.height +
        12;
    final available = math.max(
      0.0,
      constraints.maxHeight - widget.pageTopPadding - bottom,
    );
    final minimum = math.min(
      available,
      widget.singlePageMaxHeight ?? available,
    );
    return SingleChildScrollView(
      key: const PageStorageKey('concept_connections_page_0'),
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, widget.pageTopPadding, 20, bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minimum),
        child: IntrinsicHeight(
          // Equal cards fill the viewport when readable content fits. Intrinsic
          // height wins on short screens/large text, preserving real scrolling
          // rather than clipping, overflowing or reducing the user's font.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final child in widget.pages.single)
                if (child is SizedBox) child else Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _expandedPage(BuildContext context) {
    final bottom =
        math.max(
          MediaQuery.paddingOf(context).bottom,
          ZyraNavBarMetrics.bottomInset,
        ) +
        ZyraNavBarMetrics.height +
        12;
    final quiet =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    // One finite card viewport replaces the whole list; no outgoing cards
    // remain mounted, interactive or exposed to assistive technology.
    return Padding(
      padding: EdgeInsets.fromLTRB(20, widget.pageTopPadding, 20, bottom),
      child: quiet
          ? widget.expandedCard
          : TweenAnimationBuilder<double>(
              key: const ValueKey('journey_card_options_expansion'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, (1 - value) * 8),
                child: Opacity(opacity: .9 + value * .1, child: child),
              ),
              child: widget.expandedCard,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revision = ++_renderRevision;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: widget.titleAlignment,
                    child: Text(
                      widget.title,
                      key: const ValueKey('concept_connections_title'),
                      textAlign: widget.titleAlignment.x > 0
                          ? TextAlign.right
                          : TextAlign.left,
                      style: ZyraText.pageTitle(),
                    ),
                  ),
                ),
                if (widget.onBack != null)
                  IconButton(
                    key: const ValueKey('concept_activity_back'),
                    tooltip: 'Back',
                    onPressed: widget.onBack,
                    icon: Icon(
                      Icons.arrow_back,
                      color: ZyraColors.accentOnCanvas,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.labels.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: ZyraSegmentedToggle(
                labels: widget.labels,
                position: _position,
                badges: widget.badges,
                segmentKeys: widget.segmentKeys,
                onChanged: (index) {
                  if (mounted && revision == _renderRevision) _select(index);
                },
              ),
            ),
          Expanded(
            child: widget.expandedCard != null
                ? _expandedPage(context)
                : widget.fillSinglePage && widget.pages.length == 1
                ? LayoutBuilder(
                    builder: (context, constraints) =>
                        _filledPage(context, constraints),
                  )
                : PageView(
                    controller: _pager,
                    physics: ZyraSegmentedMotion.pagePhysics,
                    onPageChanged: widget.onChanged,
                    children: [
                      for (var index = 0; index < widget.pages.length; index++)
                        ListView(
                          key: PageStorageKey(
                            'concept_connections_page_$index',
                          ),
                          padding: EdgeInsets.fromLTRB(
                            20,
                            widget.pageTopPadding,
                            20,
                            widget.bottomPadding,
                          ),
                          children: widget.pages[index],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Current Connections accent-marker section heading, including its text case.
class ZyraOneJourneyConnectionsSectionHeading extends StatelessWidget {
  const ZyraOneJourneyConnectionsSectionHeading({
    super.key,
    required this.title,
    this.emphasised = false,
  });

  final String title;
  final bool emphasised;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 28,
        decoration: BoxDecoration(
          color: ZyraColors.accentOnCanvas.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          title,
          style: ZyraText.body(
            size: emphasised ? 16 : 14.5,
            color: emphasised ? ZyraColors.foreground : ZyraColors.ink(.82),
          ),
        ),
      ),
    ],
  );
}

class ZyraOneJourneyConnectionsAction {
  const ZyraOneJourneyConnectionsAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.key,
    this.fitLabel = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Key? key;
  final bool fitLabel;
}

/// The live Compact Chips action, with caller-owned draft callbacks.
class ZyraOneJourneyConnectionsActionButton extends StatelessWidget {
  const ZyraOneJourneyConnectionsActionButton({
    super.key,
    required this.action,
    this.primary = false,
    this.invitationSent,
    this.semanticLabel,
  });

  final ZyraOneJourneyConnectionsAction action;
  final bool primary;
  final bool? invitationSent;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tint = action.onTap == null
        ? ZyraColors.ink(.34)
        : primary
        ? ZyraColors.foreground
        : ZyraColors.ink(.80);
    final button = Material(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: invitationSent == true
                ? ZyraColors.journeyGold.withValues(alpha: .85)
                : ZyraColors.surfaceBorder,
            width: primary ? 1 : .6,
          ),
        ),
        child: InkWell(
          key: action.key,
          borderRadius: BorderRadius.circular(999),
          onTap: action.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: primary ? 14 : 10,
              vertical: primary ? 11 : 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: 14, color: tint),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: action.fitLabel
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            action.label,
                            maxLines: 1,
                            softWrap: false,
                            style: ZyraText.button(
                              size: primary ? 12.5 : 10.5,
                              color: tint,
                            ),
                          ),
                        )
                      : invitationSent != null
                      ? ZyraInvitationLabel(
                          label: action.label,
                          sent: invitationSent!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZyraText.button(
                            size: primary ? 12.5 : 10.5,
                            color: tint,
                          ),
                        )
                      : Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZyraText.button(
                            size: primary ? 12.5 : 10.5,
                            color: tint,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (invitationSent == null && semanticLabel == null) return button;
    return Semantics(
      button: true,
      enabled: action.onTap != null,
      label:
          semanticLabel ??
          (invitationSent == true
              ? '${action.label}. Tap to cancel invitation'
              : action.label),
      onTap: action.onTap,
      excludeSemantics: true,
      child: ZyraPressFeedback(enabled: action.onTap != null, child: button),
    );
  }
}

class ZyraOneJourneyConnectionsActionDeck extends StatelessWidget {
  const ZyraOneJourneyConnectionsActionDeck({
    super.key,
    required this.primary,
    this.actions = const [],
    this.journeyReference,
    this.primaryTrailing,
  });

  final ZyraOneJourneyConnectionsAction primary;
  final List<ZyraOneJourneyConnectionsAction> actions;
  final Widget? journeyReference;
  final Widget? primaryTrailing;

  Widget get primaryRow => primaryTrailing == null
      ? ZyraOneJourneyConnectionsActionButton(action: primary, primary: true)
      : Row(
          children: [
            Expanded(
              child: ZyraOneJourneyConnectionsActionButton(
                action: primary,
                primary: true,
              ),
            ),
            const SizedBox(width: 7),
            primaryTrailing!,
          ],
        );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      primaryRow,
      if (journeyReference != null) ...[
        const SizedBox(height: 10),
        journeyReference!,
      ],
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = actions.length.clamp(1, 3);
            final width = (constraints.maxWidth - 7 * (columns - 1)) / columns;
            return Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: width,
                    child: ZyraOneJourneyConnectionsActionButton(
                      action: action,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ],
  );
}

/// Current persistent identity row with an inline expanding action deck. A
/// shared optional controller retains the production one-open-card behaviour.
class ZyraOneJourneyConnectionsPersonCard extends StatefulWidget {
  const ZyraOneJourneyConnectionsPersonCard({
    super.key,
    required this.profile,
    required this.subtitle,
    required this.actions,
    required this.cardId,
    this.controller,
    this.imageBuilder = _profileImage,
    this.onReport,
    this.headerKey,
    this.dimmed = false,
  });

  final SeekerProfile profile;
  final String subtitle;
  final Widget actions;
  final String cardId;
  final ZyraConnectionsExpansionController? controller;
  final ZyraOneJourneyPhotoBuilder imageBuilder;
  final VoidCallback? onReport;
  final Key? headerKey;
  final bool dimmed;

  @override
  State<ZyraOneJourneyConnectionsPersonCard> createState() =>
      _ZyraOneJourneyConnectionsPersonCardState();
}

class _ZyraOneJourneyConnectionsPersonCardState
    extends State<ZyraOneJourneyConnectionsPersonCard> {
  final GlobalKey _cardKey = GlobalKey();
  late final ZyraConnectionsExpansionController _ownController;
  Timer? _settleTimer;

  ZyraConnectionsExpansionController get _controller =>
      widget.controller ?? _ownController;

  @override
  void initState() {
    super.initState();
    _ownController = ZyraConnectionsExpansionController();
  }

  void _ensureVisible() {
    final target = _cardKey.currentContext;
    if (!mounted || target == null || _controller.value != widget.cardId) {
      return;
    }
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0,
      ),
    );
  }

  void _toggle() {
    _settleTimer?.cancel();
    if (_controller.value == widget.cardId) {
      _controller.close(widget.cardId);
    } else {
      _controller.open(widget.cardId);
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
      _settleTimer = Timer(const Duration(milliseconds: 240), _ensureVisible);
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _ownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: _controller,
    builder: (context, selected, _) {
      final open = selected == widget.cardId;
      final profile = widget.profile;
      final reduceMotion =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      return Opacity(
        opacity: widget.dimmed && !open ? .65 : 1,
        child: Padding(
          key: _cardKey,
          padding: const EdgeInsets.only(bottom: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: open
                  ? ZyraColors.surfaceEmphasisFill
                  : ZyraColors.surfaceFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: open
                    ? ZyraColors.surfaceEmphasisBorder
                    : ZyraColors.surfaceBorder,
                width: open ? 1 : .5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  InkWell(
                    key: widget.headerKey,
                    borderRadius: BorderRadius.circular(14),
                    onTap: _toggle,
                    child: Padding(
                      padding: const EdgeInsets.all(ZyraCardMetrics.padding),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ZyraCardMetrics.thumbRadius,
                            ),
                            child: SizedBox(
                              width: ZyraCardMetrics.thumb,
                              height: ZyraCardMetrics.thumb,
                              child: widget.imageBuilder(
                                context,
                                profile.photoUrl,
                              ),
                            ),
                          ),
                          const SizedBox(width: ZyraCardMetrics.gap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.age > 0
                                      ? '${profile.firstName}, ${profile.age}'
                                      : profile.firstName,
                                  style: ZyraText.body(
                                    size: 14,
                                    color: ZyraColors.foreground,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.subtitle,
                                  style: ZyraText.subtext(size: 11.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!open)
                            SizedBox(
                              width: 32,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: ZyraColors.ink(.38),
                                size: 20,
                              ),
                            )
                          else if (widget.onReport != null)
                            _ReportFlag(
                              firstName: profile.firstName,
                              onTap: widget.onReport!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (reduceMotion)
                    if (open)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: widget.actions,
                      )
                    else
                      const SizedBox(width: double.infinity)
                  else
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: open
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.all(12),
                        child: widget.actions,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Current Active Journey card, compact only for a multi-Journey overview.
/// Its normal single-Journey geometry remains unchanged. The person header is
/// not a disguised navigation target: only supplied labelled actions act.
class ZyraOneJourneyConnectionsActiveCard extends StatelessWidget {
  const ZyraOneJourneyConnectionsActiveCard({
    super.key,
    required this.profile,
    required this.actions,
    this.imageBuilder = _profileImage,
    this.onReport,
    this.stateLabel,
    this.compact = false,
    this.fillHeight = false,
    this.cardDesign = ZyraOneJourneyCardDesign.portraitSplit,
    this.primaryAction,
    this.stageLabel,
    this.inlineOptions,
    this.inlineOptionsFillHeight = true,
  });

  final SeekerProfile profile;
  final Widget actions;
  final ZyraOneJourneyPhotoBuilder imageBuilder;
  final VoidCallback? onReport;
  final String? stateLabel;
  final bool compact;
  final bool fillHeight;
  final ZyraOneJourneyCardDesign cardDesign;
  final Widget? primaryAction;
  final String? stageLabel;
  final Widget? inlineOptions;
  final bool inlineOptionsFillHeight;

  double _originalSingleInteriorHeight(BuildContext context, double width) {
    // Measure the existing single-card text, including its real inherited
    // line metrics and wrapping. This preserves its envelope without fixing
    // a pixel height that only works for one font or text scale.
    double textHeight(
      String text,
      TextStyle style,
      double maxWidth, {
      bool singleLine = false,
    }) {
      var inherited = DefaultTextStyle.of(context).style.merge(style);
      if (MediaQuery.boldTextOf(context)) {
        inherited = inherited.merge(
          const TextStyle(fontWeight: FontWeight.bold),
        );
      }
      final painter = TextPainter(
        text: TextSpan(text: text, style: inherited),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: singleLine ? 1 : null,
        ellipsis: singleLine ? '…' : null,
      )..layout(maxWidth: math.max(1, maxWidth));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    // The locked layout retains its original reference envelope even after
    // moving Report into options. Removing that visible glyph must not shrink
    // the natural single-card rectangle through wider reference text wrapping.
    final referenceReportWidth = onReport != null
        ? _ReportFlag.tapTargetExtent
        : 0;
    final identityWidth = width - 96 - 16 - referenceReportWidth;
    var identity = textHeight(
      profile.firstName,
      ZyraText.heading(size: 19),
      identityWidth,
    );
    if ((profile.surnameLine ?? '').trim().isNotEmpty) {
      identity += textHeight(
        profile.surnameLine!.trim(),
        ZyraText.heading(size: 15),
        identityWidth,
      );
    }
    identity +=
        6 +
        textHeight(
          '${profile.age} · ${profile.city}',
          ZyraText.subtext(size: 12.5),
          identityWidth,
        );
    if (stateLabel != null) {
      identity +=
          8 +
          textHeight(stateLabel!, ZyraText.subtext(size: 11), identityWidth);
    }
    final deck = actions;
    final label = deck is ZyraOneJourneyConnectionsActionDeck
        ? deck.primary.label
        : 'View Journey';
    final button =
        math.max(
          14.0,
          textHeight(
            label,
            ZyraText.button(size: 12.5),
            width - 50,
            singleLine: true,
          ),
        ) +
        24; // 22px explicit padding + Ink's 1px border on each edge.
    final reference = stageLabel == null
        ? 0.0
        : 10 + textHeight(stageLabel!, ZyraText.subtext(size: 11), width);
    return math.max(96.0, identity) + 16 + button + reference;
  }

  Widget _alternateContent(BuildContext context) {
    final deck = actions;
    final content = ZyraOneJourneyCardContent(
      design: cardDesign,
      profile: profile,
      photo: imageBuilder(context, profile.photoUrl),
      action: primaryAction ?? actions,
      primaryButton: deck is ZyraOneJourneyConnectionsActionDeck
          ? ZyraOneJourneyConnectionsActionButton(
              action: deck.primary,
              primary: true,
            )
          : null,
      optionsButton: deck is ZyraOneJourneyConnectionsActionDeck
          ? deck.primaryTrailing
          : null,
      fillHeight: fillHeight || !compact,
      stateLabel: stateLabel,
      stageLabel: stageLabel,
      inlineOptions: inlineOptions,
      inlineOptionsFillHeight: inlineOptionsFillHeight,
      report: onReport == null
          ? null
          : _ReportFlag(firstName: profile.firstName, onTap: onReport!),
    );
    // Only a single natural-height card uses this measurement. Multi-card
    // interiors remain compatible with the page's IntrinsicHeight layout.
    // Natural-height expanded options lay out as a reading column. Their
    // LayoutBuilder must not be queried through IntrinsicHeight.
    return !compact && !fillHeight && inlineOptions == null
        ? LayoutBuilder(
            builder: (context, constraints) => IntrinsicHeight(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: _originalSingleInteriorHeight(
                    context,
                    constraints.maxWidth,
                  ),
                ),
                child: content,
              ),
            ),
          )
        : content;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 0 : 14),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ZyraColors.surfaceEmphasisBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Builder(builder: _alternateContent),
        ),
      ),
    ),
  );
}

class _ReportFlag extends StatelessWidget {
  const _ReportFlag({required this.firstName, required this.onTap});

  static const double tapTargetExtent = 44;

  final String firstName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: 'Report $firstName',
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: SizedBox(
        width: tapTargetExtent,
        height: tapTargetExtent,
        // The same 15px glyph stays at the header's original top-right edge;
        // only the invisible hit area grows downwards and towards the identity.
        child: Align(
          alignment: Alignment.topRight,
          child: Icon(
            Icons.flag_outlined,
            size: 15,
            color: ZyraColors.ink(.75),
          ),
        ),
      ),
    ),
  );
}
