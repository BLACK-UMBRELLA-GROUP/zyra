import '../../widgets/zyra_developer_title.dart';
import '../../widgets/zyra_confirm_sheet.dart';
import '../../widgets/zyra_floating_surface.dart';
import '../../widgets/zyra_guardian_add_card.dart';
import '../../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';
import '../../dev/zyra_one_journey_monogram_presentation.dart';
import 'dart:math' as math;

import '../../data/zyra_guardian_capacity.dart';
import '../../data/zyra_seeker_plan_limits.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../state/zyra_developer_samples.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_guardian_invitation_dashboard.dart';
import '../../widgets/zyra_guardian_preview_lifetime.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_profiles_components.dart';
import '../../widgets/zyra_swipe_track.dart';

// The roster may rebuild one frame after revocation. Its retained child
// callbacks must independently deny stale preview and asynchronous results.
mixin _GuardianControlLifetime<T extends StatefulWidget> on State<T> {
  bool get guardianPreviewRequested;
  void withdrawGuardianControl();

  late ZyraGuardianPreviewLifetime guardianLifetime;
  int guardianRequest = 0;

  @override
  void initState() {
    super.initState();
    guardianLifetime = ZyraGuardianPreviewLifetime(
      preview: guardianPreviewRequested,
    )..addListener(_withdrawGuardianControl);
  }

  void _withdrawGuardianControl() {
    if (!mounted) return;
    guardianRequest++;
    setState(withdrawGuardianControl);
  }

  void replaceGuardianLifetime() {
    guardianLifetime.removeListener(_withdrawGuardianControl);
    guardianLifetime.revoke();
    guardianLifetime.dispose();
    guardianRequest++;
    guardianLifetime = ZyraGuardianPreviewLifetime(
      preview: guardianPreviewRequested,
    )..addListener(_withdrawGuardianControl);
  }

  bool guardianResultCurrent(
    int request,
    ZyraGuardianPreviewLifetime lifetime,
  ) =>
      mounted &&
      identical(lifetime, guardianLifetime) &&
      request == guardianRequest &&
      lifetime.isCurrent;

  VoidCallback boundGuardianCallback(VoidCallback callback) {
    final lifetime = guardianLifetime;
    return () {
      if (mounted &&
          identical(lifetime, guardianLifetime) &&
          lifetime.isCurrent) {
        callback();
      }
    };
  }

  @override
  void dispose() {
    guardianLifetime
      ..removeListener(_withdrawGuardianControl)
      ..dispose();
    super.dispose();
  }
}

const double _managerPageTopInset = 16;
const double _journeyAccessIdentityGap = 14;

bool _shortGuardianPage(BuildContext context) =>
    MediaQuery.sizeOf(context).height <= 667;

double _guardianNavigationReserve(BuildContext context) =>
    math.max(
      MediaQuery.viewPaddingOf(context).bottom,
      ZyraNavBarMetrics.bottomInset,
    ) +
    ZyraNavBarMetrics.legacyRestingHeight +
    ZyraNavBarMetrics.contentGap;

String _recordedGuardianRole(WaliLinkedPerson person) => [
  if (person.relationshipLabel != null) person.relationshipLabel!,
  person.isMain ? 'Main Guardian' : 'Additional Guardian',
].join(' · ');

/// Founder-approved Seeker-side owner for Guardian relationship management.
///
/// This deliberately does not resolve or render activity on roster cards.
/// Relationship movement belongs to Dashboard Updates; the detail route owns
/// the narrow per-Guardian history allowed by the contract.
class GuardianshipManagerView extends StatelessWidget {
  final List<WaliLinkedPerson> people;
  final bool linksAvailable;
  final VoidCallback onRetryLinks;
  final ValueChanged<WaliLinkedPerson> onOpenGuardian;
  final VoidCallback onAdd;
  final ZyraGuardianCapacity? basicCapacity;
  final VoidCallback? onUpgrade;
  final VoidCallback? onOpenMessages;
  final Widget Function(Widget)? conversationButtonBuilder;
  final GuardianPendingInvitesLoader? pendingInvitesLoader;
  final DateTime? comparisonNow;
  final Alignment titleAlignment;

  /// A presentation-only size override; null retains the ordinary optical size.
  final double? titleSize;

  const GuardianshipManagerView({
    super.key,
    required this.people,
    required this.linksAvailable,
    required this.onRetryLinks,
    required this.onOpenGuardian,
    required this.onAdd,
    this.basicCapacity,
    this.onUpgrade,
    this.onOpenMessages,
    this.conversationButtonBuilder,
    this.pendingInvitesLoader,
    this.comparisonNow,
    this.titleAlignment = Alignment.centerLeft,
    this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered(people);
    final mainPeople = ordered.where((person) => person.isMain).toList();
    final main = mainPeople.isEmpty ? null : mainPeople.first;
    final additional = ordered.where((person) => !person.isMain).toList();

    Widget invitationLifecycle() => ZyraGuardianInvitationDashboard(
      audience: ZyraGuardianInvitationAudience.seeker,
      includeHeading: false,
      surface: ZyraGuardianInvitationSurface.manager,
      pendingInvitesLoader: pendingInvitesLoader,
      comparisonNow: comparisonNow,
    );

    if (linksAvailable && ordered.isEmpty) {
      return CustomScrollView(
        physics: const ScrollPhysics(),
        key: const PageStorageKey('guardianship-manager'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, _managerPageTopInset, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _ManagerHeader(
                onAdd: onAdd,
                onOpenMessages: onOpenMessages,
                conversationButtonBuilder: conversationButtonBuilder,
                titleAlignment: titleAlignment,
                titleSize: titleSize,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(child: invitationLifecycle()),
          ),
          // Keep pending invitations above the card and let the whole tab
          // scroll if the card and invitations exceed the available height.
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                _guardianNavigationReserve(context),
              ),
              child: ZyraGuardianAddCard(
                key: const ValueKey('guardianship-manager-empty'),
                basicCapacity: basicCapacity,
                onAdd: ZyraTapFeedback.onTap(context, onAdd),
                onUpgrade: ZyraTapFeedback.onTap(context, onUpgrade),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const ScrollPhysics(),
      key: const PageStorageKey('guardianship-manager'),
      padding: const EdgeInsets.fromLTRB(20, _managerPageTopInset, 20, 118),
      children: [
        _ManagerHeader(
          onAdd: onAdd,
          onOpenMessages: onOpenMessages,
          conversationButtonBuilder: conversationButtonBuilder,
          titleAlignment: titleAlignment,
          titleSize: titleSize,
        ),
        const SizedBox(height: 22),
        if (!linksAvailable)
          ZyraEmptyState(
            key: const ValueKey('guardian-links-unavailable'),
            icon: Icons.refresh_rounded,
            title: 'Guardians could not be refreshed',
            message: 'Check your connection and try again.',
            ctaLabel: 'Try again',
            onCta: onRetryLinks,
          )
        else ...[
          if (main != null) ...[
            const _ManagerSectionLabel('MAIN GUARDIAN'),
            const SizedBox(height: 10),
            _ManagerGuardianCard(
              person: main,
              onOpen: () => onOpenGuardian(main),
            ),
          ],
          if (additional.isNotEmpty) ...[
            if (main != null) const SizedBox(height: 26),
            const _ManagerSectionLabel('ADDITIONAL GUARDIANS'),
            const SizedBox(height: 10),
            for (var index = 0; index < additional.length; index++) ...[
              _ManagerGuardianCard(
                person: additional[index],
                onOpen: () => onOpenGuardian(additional[index]),
              ),
              if (index < additional.length - 1) const SizedBox(height: 10),
            ],
          ],
        ],
        const SizedBox(height: 28),
        invitationLifecycle(),
      ],
    );
  }
}

class _ManagerHeader extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback? onOpenMessages;
  final Widget Function(Widget)? conversationButtonBuilder;
  final Alignment titleAlignment;
  final double? titleSize;

  const _ManagerHeader({
    required this.onAdd,
    this.onOpenMessages,
    this.conversationButtonBuilder,
    this.titleAlignment = Alignment.centerLeft,
    this.titleSize,
  });

  List<Widget> _actionPaintOrder(List<Widget> reversed) =>
      conversationButtonBuilder == null ? reversed.reversed.toList() : reversed;

  Widget _conversationButton() {
    final button = _HeaderCircleAction(
      key: const ValueKey('guardian-family-messages-top'),
      label: 'Guardian Circle',
      icon: Icons.forum_outlined,
      onTap: onOpenMessages!,
    );
    return conversationButtonBuilder?.call(button) ?? button;
  }

  Widget _title() => Expanded(
    child: ZyraDeveloperTitle(
      tab: 3,
      child: Text(
        'Guardian',
        key: const ValueKey('guardian-manager-title'),
        textAlign: titleAlignment.x > 0 ? TextAlign.right : TextAlign.left,
        style: titleSize == null || titleSize == ZyraText.pageTitleSize
            ? ZyraText.pageTitle()
            : ZyraText.heading(size: titleSize!),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (titleAlignment.x <= 0) _title(),
      // Paint the Add shadow first, then the conversation icon and badge.
      // RTL changes paint order only; the original positions/gaps stay exact.
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: conversationButtonBuilder == null
            ? TextDirection.ltr
            : TextDirection.rtl,
        children: _actionPaintOrder([
          Tooltip(
            message: 'Add a Guardian',
            excludeFromSemantics: true,
            child: Semantics(
              button: true,
              label: 'Add a Guardian',
              child: ZyraFloatingSurface(
                radius: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('guardian-add-top'),
                    customBorder: const CircleBorder(),
                    onTap: ZyraTapFeedback.onTap(context, onAdd),
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(
                        child: ZyraFloatingSurface(
                          circle: true,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ZyraColors.iconButtonBg,
                              border: Border.all(
                                color: ZyraColors.iconButtonBorder,
                              ),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              size: 23,
                              color: ZyraColors.foreground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (onOpenMessages != null) ...[
            const SizedBox(width: 4),
            _conversationButton(),
          ],
        ]),
      ),
      if (titleAlignment.x > 0) ...[const SizedBox(width: 8), _title()],
    ],
  );
}

class _HeaderCircleAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: ZyraFloatingSurface(
      circle: true,
      child: IconButton(
        onPressed: ZyraTapFeedback.onTap(context, onTap),
        icon: Icon(icon, color: ZyraColors.foreground),
        style: IconButton.styleFrom(
          backgroundColor: ZyraColors.iconButtonBg,
          side: BorderSide(color: ZyraColors.iconButtonBorder),
        ),
      ),
    ),
  );
}

class _ManagerSectionLabel extends StatelessWidget {
  final String label;

  const _ManagerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) =>
      Text(label, style: ZyraText.chapterLabel(color: ZyraColors.ink(0.56)));
}

class _ManagerGuardianCard extends StatelessWidget {
  final WaliLinkedPerson person;
  final VoidCallback onOpen;

  const _ManagerGuardianCard({required this.person, required this.onOpen});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open ${person.firstName} Guardian details',
    child: ZyraFloatingSurface(
      radius: 16,
      child: Material(
        key: ValueKey('guardian-manager-card-${person.id}'),
        color: person.isMain
            ? ZyraColors.surfaceEmphasisFill
            : ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: ZyraTapFeedback.onTap(context, onOpen),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: person.isMain
                    ? ZyraColors.surfaceEmphasisBorder
                    : ZyraColors.surfaceBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                zyraGuardianManagerMonogram(name: person.firstName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.firstName, style: ZyraText.heading(size: 18)),
                      const SizedBox(height: 3),
                      Text(
                        _recordedGuardianRole(person),
                        style: ZyraText.subtext(size: 12.25),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        person.isMain
                            ? 'Asked to act on your Journey.'
                            : 'Supports you with your Journey.',
                        style: ZyraText.body(size: 12.25),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        person.linkedDateLabel == null
                            ? 'Linked date not recorded'
                            : 'Linked ${person.linkedDateLabel}',
                        style: ZyraText.subtext(
                          size: 11.25,
                          color: ZyraColors.ink(0.44),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: ZyraColors.ink(0.52)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The existing Guardian-tab monogram, shared with its informational notice.
Widget zyraGuardianManagerMonogram({
  required String name,
  bool guardianOne = false,
}) => ZyraGoldRingMonogram(
  name: name,
  guardianOne: guardianOne,
  size: 48,
  fontSize: 19,
);

List<WaliLinkedPerson> _ordered(List<WaliLinkedPerson> people) {
  final ordered = <WaliLinkedPerson>[];
  for (final person in people) {
    if (person.isMain) {
      ordered.add(person);
      break;
    }
  }
  ordered.addAll(people.where((person) => !person.isMain));
  return ordered;
}

typedef GuardianPageHistoryConsentLoader =
    Future<ZyraSourceResult<GuardianHistoryConsentState>> Function({
      required String guardianId,
      required bool guardianIsMain,
      bool? enabled,
    });
typedef GuardianPageJourneyAccessLoader =
    Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> Function({
      required String guardianId,
      String? attemptId,
      bool? enabled,
      bool? chatEnabled,
    });
typedef GuardianMakeMainAction = Future<bool> Function(String guardianId);
typedef GuardianClearMainAction = Future<bool> Function(String guardianId);
typedef GuardianRemoveAction = Future<String?> Function(String guardianId);

/// Canonical Seeker Guardian page selected by the Founder.
///
/// Horizontal card movement is the sole Guardian-to-Guardian navigation.
/// Each Guardian page is a fixed one-screen layout: Journey access is always
/// visible and vertical scrolling is deliberately not part of this surface.
class SeekerGuardianPage extends StatelessWidget {
  final List<WaliLinkedPerson> people;
  final Map<String, List<GuardianActivity>> activity;
  final bool linksAvailable;
  final bool activityAvailable;
  final VoidCallback onRetry;
  final VoidCallback onAdd;
  final ZyraPlan? seekerPlan;
  final VoidCallback? onUpgrade;
  final VoidCallback? onOpenMessages;
  final Widget Function(Widget)? conversationButtonBuilder;
  final GuardianPendingInvitesLoader? pendingInvitesLoader;
  final GuardianPageHistoryConsentLoader? historyConsentLoader;
  final GuardianPageJourneyAccessLoader? journeyAccessLoader;
  final bool historyConsentPreview;
  final int previewActiveJourneyCount;

  /// Known Basic Guardians only, supplied independently of the Seeker's plan.
  /// This controls presentation; it never creates entitlement or permission.
  final Set<String> viewOnlyGuardianIds;
  final GuardianMakeMainAction? makeMainGuardian;
  final GuardianClearMainAction? clearMainGuardian;
  final GuardianRemoveAction? removeGuardian;
  final VoidCallback? onChanged;
  final DateTime? comparisonNow;

  /// Presentation-only opt-in. No relationship or permission policy changes.
  final Alignment titleAlignment;
  final double? titleSize;

  const SeekerGuardianPage({
    super.key,
    required this.people,
    required this.activity,
    required this.linksAvailable,
    required this.activityAvailable,
    required this.onRetry,
    required this.onAdd,
    this.seekerPlan,
    this.onUpgrade,
    this.onOpenMessages,
    this.conversationButtonBuilder,
    this.pendingInvitesLoader,
    this.historyConsentLoader,
    this.journeyAccessLoader,
    this.historyConsentPreview = false,
    this.previewActiveJourneyCount = 1,
    this.viewOnlyGuardianIds = const {},
    this.makeMainGuardian,
    this.clearMainGuardian,
    this.removeGuardian,
    this.onChanged,
    this.comparisonNow,
    this.titleAlignment = Alignment.centerLeft,
    this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered(people);
    final linkedCount = ordered.map((person) => person.id).toSet().length;
    final basicCapacity = seekerPlan == ZyraPlan.basic
        ? ZyraGuardianCapacity.fromCount(
            plan: ZyraPlan.basic,
            linkedGuardianCount: linkedCount,
          )
        : null;
    if (!linksAvailable || ordered.isEmpty) {
      return GuardianshipManagerView(
        people: ordered,
        linksAvailable: linksAvailable,
        onRetryLinks: onRetry,
        onOpenGuardian: (_) {},
        onAdd: onAdd,
        basicCapacity: basicCapacity,
        onUpgrade: onUpgrade,
        onOpenMessages: onOpenMessages,
        conversationButtonBuilder: conversationButtonBuilder,
        pendingInvitesLoader: pendingInvitesLoader,
        comparisonNow: comparisonNow,
        titleAlignment: titleAlignment,
        titleSize: titleSize,
      );
    }

    return Column(
      key: const ValueKey('guardian-page-quiet-sections'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, _managerPageTopInset, 20, 0),
          child: _ManagerHeader(
            onAdd: onAdd,
            onOpenMessages: onOpenMessages,
            conversationButtonBuilder: conversationButtonBuilder,
            titleAlignment: titleAlignment,
            titleSize: titleSize,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: _guardianNavigationReserve(context),
            ),
            child: _GuardianPager(
              key: const ValueKey('guardian-pager'),
              people: ordered,
              activity: activity,
              activityAvailable: activityAvailable,
              onRetry: onRetry,
              onAdd: linkedCount < ZyraSeekerPlanLimits.maxLinkedGuardians
                  ? onAdd
                  : null,
              basicCapacity: basicCapacity,
              onUpgrade: onUpgrade,
              historyConsentLoader: historyConsentLoader,
              journeyAccessLoader: journeyAccessLoader,
              historyConsentPreview: historyConsentPreview,
              previewActiveJourneyCount: previewActiveJourneyCount,
              viewOnlyGuardianIds: viewOnlyGuardianIds,
              makeMainGuardian: makeMainGuardian,
              clearMainGuardian: clearMainGuardian,
              removeGuardian: removeGuardian,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuardianPager extends StatefulWidget {
  final List<WaliLinkedPerson> people;
  final Map<String, List<GuardianActivity>> activity;
  final bool activityAvailable;
  final VoidCallback onRetry;
  final VoidCallback? onAdd;
  final ZyraGuardianCapacity? basicCapacity;
  final VoidCallback? onUpgrade;
  final GuardianPageHistoryConsentLoader? historyConsentLoader;
  final GuardianPageJourneyAccessLoader? journeyAccessLoader;
  final bool historyConsentPreview;
  final int previewActiveJourneyCount;
  final Set<String> viewOnlyGuardianIds;
  final GuardianMakeMainAction? makeMainGuardian;
  final GuardianClearMainAction? clearMainGuardian;
  final GuardianRemoveAction? removeGuardian;
  final VoidCallback? onChanged;

  const _GuardianPager({
    super.key,
    required this.people,
    required this.activity,
    required this.activityAvailable,
    required this.onRetry,
    required this.onAdd,
    required this.basicCapacity,
    required this.onUpgrade,
    required this.historyConsentLoader,
    required this.journeyAccessLoader,
    required this.historyConsentPreview,
    required this.previewActiveJourneyCount,
    required this.viewOnlyGuardianIds,
    required this.makeMainGuardian,
    required this.clearMainGuardian,
    required this.removeGuardian,
    required this.onChanged,
  });

  @override
  State<_GuardianPager> createState() => _GuardianPagerState();
}

class _GuardianPagerState extends State<_GuardianPager> {
  final _controller = ZyraSwipeController();
  int _page = 0;

  int get _pageCount => widget.people.length + (widget.onAdd != null ? 1 : 0);

  @override
  void didUpdateWidget(covariant _GuardianPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int nextPage;
    if (_page >= oldWidget.people.length) {
      nextPage = _pageCount - 1;
    } else if (widget.people.isEmpty) {
      nextPage = 0;
    } else {
      final currentGuardianId = oldWidget.people[_page].id;
      final sameGuardianPage = widget.people.indexWhere(
        (person) => person.id == currentGuardianId,
      );
      nextPage = sameGuardianPage >= 0
          ? sameGuardianPage
          : _page.clamp(0, widget.people.length - 1);
    }
    _page = nextPage < 0 ? 0 : nextPage;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: _page < widget.people.length
              ? 'Guardian ${_page + 1} of ${widget.people.length}'
              : null,
          child: ZyraProfilesDots(
            count: widget.people.length,
            index: _page,
            activeWidth: 20,
            size: 5,
            lift: -6,
            targetHeight: 17,
            inactiveColor: ZyraColors.ink(.25),
            dotKey: (index) => ValueKey('guardian-page-dot-paint-$index'),
            targetKey: (index) => ValueKey('guardian-page-dot-$index'),
            itemLabel: (index) => 'Show Guardian ${index + 1}',
            onSelected: _controller.animateTo,
            exposeSemanticAction: true,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ZyraSwipeTrack(
              key: const ValueKey('guardian-page-view'),
              controller: _controller,
              index: _page,
              itemCount: _pageCount,
              motionIdentity: widget.people
                  .map((person) => person.id)
                  .join(','),
              canAct: () =>
                  mounted && (ModalRoute.of(context)?.isCurrent ?? true),
              onSettled: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                if (index == widget.people.length) {
                  return ZyraGuardianAddCard(
                    key: const ValueKey('guardian-pager-add'),
                    basicCapacity: widget.basicCapacity,
                    onAdd: ZyraTapFeedback.onTap(context, widget.onAdd),
                    onUpgrade: ZyraTapFeedback.onTap(context, widget.onUpgrade),
                    allowContentScroll: true,
                  );
                }
                final person = widget.people[index];
                final activities = widget.activity[person.id] ?? const [];
                return Semantics(
                  label:
                      'Guardian ${index + 1} of ${widget.people.length}: '
                      '${person.firstName}',
                  child: _GuardianPageContent(
                    person: person,
                    activities: activities,
                    activityAvailable: widget.activityAvailable,
                    onRetry: widget.onRetry,
                    historyConsentLoader: widget.historyConsentLoader,
                    journeyAccessLoader: widget.journeyAccessLoader,
                    historyConsentPreview: widget.historyConsentPreview,
                    previewActiveJourneyCount: widget.previewActiveJourneyCount,
                    showChat: !widget.viewOnlyGuardianIds.contains(person.id),
                    otherGuardians: widget.people
                        .where((candidate) => candidate.id != person.id)
                        .toList(growable: false),
                    makeMainGuardian: widget.makeMainGuardian,
                    clearMainGuardian: widget.clearMainGuardian,
                    removeGuardian: widget.removeGuardian,
                    onChanged: widget.onChanged,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _GuardianPageContent extends StatelessWidget {
  final WaliLinkedPerson person;
  final List<GuardianActivity> activities;
  final bool activityAvailable;
  final VoidCallback onRetry;
  final GuardianPageHistoryConsentLoader? historyConsentLoader;
  final GuardianPageJourneyAccessLoader? journeyAccessLoader;
  final bool historyConsentPreview;
  final int previewActiveJourneyCount;
  final bool showChat;
  final List<WaliLinkedPerson> otherGuardians;
  final GuardianMakeMainAction? makeMainGuardian;
  final GuardianClearMainAction? clearMainGuardian;
  final GuardianRemoveAction? removeGuardian;
  final VoidCallback? onChanged;

  const _GuardianPageContent({
    required this.person,
    required this.activities,
    required this.activityAvailable,
    required this.onRetry,
    required this.historyConsentLoader,
    required this.journeyAccessLoader,
    required this.historyConsentPreview,
    required this.previewActiveJourneyCount,
    required this.showChat,
    required this.otherGuardians,
    required this.makeMainGuardian,
    required this.clearMainGuardian,
    required this.removeGuardian,
    required this.onChanged,
  });

  GuardianActivity? get obligation {
    for (final item in activities) {
      if (item.type == 'review_waiting' && item.line != null) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => FittedBox(
      key: ValueKey('guardian-page-static-${person.id}'),
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: constraints.maxWidth,
        child: IntrinsicHeight(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: _QuietSections(
              person: person,
              obligation: obligation,
              activityAvailable: activityAvailable,
              onRetry: onRetry,
              access: _access(),
              otherGuardians: otherGuardians,
              preview: historyConsentPreview,
              makeMainGuardian: makeMainGuardian,
              clearMainGuardian: clearMainGuardian,
              removeGuardian: removeGuardian,
              onChanged: onChanged,
              compact: constraints.maxHeight < 650,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _access() => person.isMain
      ? _MainGuardianJourneyAccess(
          person: person,
          loader: journeyAccessLoader,
          historyConsentLoader: historyConsentLoader,
          preview: historyConsentPreview,
          previewActiveJourneyCount: previewActiveJourneyCount,
          showChat: showChat,
        )
      : _AdditionalGuardianJourneyAccess(
          person: person,
          loader: journeyAccessLoader,
          historyConsentLoader: historyConsentLoader,
          preview: historyConsentPreview,
          previewActiveJourneyCount: previewActiveJourneyCount,
          showChat: showChat,
        );
}

class _QuietSections extends StatelessWidget {
  final WaliLinkedPerson person;
  final GuardianActivity? obligation;
  final bool activityAvailable;
  final VoidCallback onRetry;
  final Widget access;
  final List<WaliLinkedPerson> otherGuardians;
  final bool preview;
  final GuardianMakeMainAction? makeMainGuardian;
  final GuardianClearMainAction? clearMainGuardian;
  final GuardianRemoveAction? removeGuardian;
  final VoidCallback? onChanged;
  final bool compact;

  const _QuietSections({
    required this.person,
    required this.obligation,
    required this.activityAvailable,
    required this.onRetry,
    required this.access,
    required this.otherGuardians,
    required this.preview,
    required this.makeMainGuardian,
    required this.clearMainGuardian,
    required this.removeGuardian,
    required this.onChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final short = _shortGuardianPage(context);
    return Column(
      key: ValueKey('guardian-quiet-sections-${person.id}'),
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: short
              ? 0
              : compact
              ? 2
              : 4,
        ),
        Row(
          children: [
            _GuardianMonogram(person: person, size: compact ? 58 : 64),
            const SizedBox(width: 14),
            Expanded(child: _GuardianIdentity(person: person)),
          ],
        ),
        SizedBox(
          height: short
              ? 3
              : compact
              ? 10
              : 14,
        ),
        _GuardianDetailsStrip(person: person),
        SizedBox(
          height: short
              ? 3
              : compact
              ? 12
              : 16,
        ),
        Divider(height: 1, color: ZyraColors.ink(.12)),
        SizedBox(height: short ? 3 : 10),
        Expanded(child: access),
        if (!person.isMain && (!activityAvailable || obligation != null))
          _QuietSection(
            label: 'CURRENT OBLIGATION',
            compact: true,
            child: _ActivityTruth(
              available: activityAvailable,
              obligation: obligation,
              onRetry: onRetry,
              compact: true,
            ),
          ),
        SizedBox(height: short ? 3 : 10),
        _QuietSection(
          compact: true,
          child: _GuardianManageActions(
            person: person,
            otherGuardians: otherGuardians,
            preview: preview,
            makeMainGuardian: makeMainGuardian,
            clearMainGuardian: clearMainGuardian,
            removeGuardian: removeGuardian,
            onChanged: onChanged,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _GuardianDetailsStrip extends StatelessWidget {
  final WaliLinkedPerson person;

  const _GuardianDetailsStrip({required this.person});

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 20,
    child: Container(
      key: const ValueKey('guardian-details-strip'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: ZyraColors.journeyGold,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Active',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZyraText.body(size: 12.25),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Linked', style: ZyraText.subtext(size: 10.75)),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    person.linkedDateLabel ?? 'Not recorded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: ZyraText.body(size: 12.25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Guardian card actions return an intent so the card can close its menu first.
Widget zyraGuardianCardManageActions({
  required WaliLinkedPerson person,
  required List<WaliLinkedPerson> otherGuardians,
  required bool Function() canAct,
  required ValueChanged<ZyraGuardianManagementAction> onSelect,
  required VoidCallback closeMenu,
}) => _GuardianManageActions(
  key: ValueKey(('guardian-card-actions', person.id, person.isMain)),
  person: person,
  otherGuardians: otherGuardians,
  preview: true,
  makeMainGuardian: null,
  clearMainGuardian: null,
  removeGuardian: null,
  onChanged: null,
  onSelect: onSelect,
  compact: true,
  closeCardMenu: closeMenu,
  canAct: canAct,
);

class _GuardianManageActions extends StatefulWidget {
  final WaliLinkedPerson person;
  final List<WaliLinkedPerson> otherGuardians;
  final bool preview;
  final GuardianMakeMainAction? makeMainGuardian;
  final GuardianClearMainAction? clearMainGuardian;
  final GuardianRemoveAction? removeGuardian;
  final VoidCallback? onChanged;
  final bool compact;
  final VoidCallback? closeCardMenu;
  final ValueChanged<ZyraGuardianManagementAction>? onSelect;
  bool get cardLayout => closeCardMenu != null;
  final bool Function()? canAct;

  const _GuardianManageActions({
    super.key,
    required this.person,
    required this.otherGuardians,
    required this.preview,
    required this.makeMainGuardian,
    required this.clearMainGuardian,
    required this.removeGuardian,
    required this.onChanged,
    this.compact = false,
    this.closeCardMenu,
    this.onSelect,
    this.canAct,
  });

  @override
  State<_GuardianManageActions> createState() => _GuardianManageActionsState();
}

enum ZyraGuardianManagementAction { makeMain, clearMain, remove }

Future<bool?> showZyraGuardianManagementConfirm({
  required BuildContext context,
  required ZyraGuardianManagementAction action,
  required WaliLinkedPerson person,
  bool Function()? canConfirm,
  void Function(ModalRoute<bool> route)? onOpening,
  VoidCallback? onConfirmedPop,
}) {
  final name = person.firstName;
  final (title, body, confirm, keep, key) = switch (action) {
    ZyraGuardianManagementAction.makeMain => (
      'Make $name your Main Guardian?',
      '$name will become your Main Guardian for your Journeys.',
      'Make Main Guardian',
      'Keep current Guardian',
      'guardian-make-main-confirmation',
    ),
    ZyraGuardianManagementAction.clearMain => (
      'Remove $name as Main Guardian?',
      'Without a Main Guardian no Journey can move on. You can choose a new Main Guardian at any time.',
      'Remove as Main Guardian',
      'Keep as Main Guardian',
      'guardian-clear-main-confirmation',
    ),
    ZyraGuardianManagementAction.remove => (
      'Remove $name?',
      '$name loses all access to your Journeys and the Guardian Circle. You can invite $name again later.',
      'Remove $name',
      'Keep $name',
      'guardian-remove-confirmation',
    ),
  };
  return showZyraConfirm(
    context: context,
    title: title,
    body: body,
    primaryLabel: confirm,
    secondaryLabel: keep,
    personName: name,
    sheetKey: ValueKey(key),
    primaryKey: ValueKey('$key-approve'),
    secondaryKey: ValueKey('$key-keep'),
    canConfirm: canConfirm,
    onOpening: onOpening,
    onConfirmedPop: onConfirmedPop,
  );
}

class _GuardianManageActionsState extends State<_GuardianManageActions> {
  bool _busy = false;
  bool _asking = false;
  int _interactionRevision = 0;

  @override
  void didUpdateWidget(covariant _GuardianManageActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canAct != widget.canAct && widget.cardLayout) {
      _interactionRevision++;
      _asking = false;
      _busy = false;
    }
  }

  bool get _current => mounted && (widget.canAct?.call() ?? true);

  void _failure(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _ask(
    ZyraGuardianManagementAction action,
    Future<void> Function() apply,
  ) async {
    if (_busy || _asking || !_current) return;
    if (widget.onSelect case final select?) {
      select(action);
      return;
    }
    final person = widget.person;
    setState(() => _asking = true);
    final revision = ++_interactionRevision;
    bool sameGuardian() =>
        mounted &&
        revision == _interactionRevision &&
        widget.person.id == person.id &&
        widget.person.isMain == person.isMain;
    try {
      final confirmed = await showZyraGuardianManagementConfirm(
        context: context,
        action: action,
        person: person,
        canConfirm: sameGuardian,
      );
      if (confirmed == true && sameGuardian() && _current) await apply();
    } finally {
      if (mounted && _asking) setState(() => _asking = false);
    }
  }

  Future<void> _makeMain() async {
    if (_busy || !_current) return;
    final action = widget.makeMainGuardian;
    if (action == null) {
      return _failure('Main Guardian could not be changed right now.');
    }
    setState(() {
      _interactionRevision++;
      _busy = true;
    });
    final changed = await action(widget.person.id);
    if (!_current) return;
    setState(() {
      _busy = false;
    });
    if (!changed) return _failure("That didn't go through. Please try again.");
    widget.onChanged?.call();
  }

  Future<void> _clearMain() async {
    if (_busy || !_current) return;
    final action = widget.clearMainGuardian;
    if (action == null) {
      return _failure('Main Guardian status could not be removed right now.');
    }
    setState(() {
      _interactionRevision++;
      _busy = true;
    });
    final changed = await action(widget.person.id);
    if (!_current) return;
    setState(() {
      _busy = false;
    });
    if (!changed) return _failure("That didn't go through. Please try again.");
    widget.onChanged?.call();
  }

  Future<void> _remove() async {
    if (_busy || !_current) return;
    final action = widget.removeGuardian;
    if (action == null) {
      return _failure('This Guardian could not be removed right now.');
    }
    setState(() {
      _interactionRevision++;
      _busy = true;
    });
    final error = await action(widget.person.id);
    if (!_current) return;
    setState(() {
      _busy = false;
    });
    if (error != null) return _failure(error);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (widget.person.isMain) ...[
        _managementAction(
          intent: ZyraGuardianManagementAction.clearMain,
          actionKey: const ValueKey('guardian-clear-main'),
          icon: Icons.shield_outlined,
          label: 'Remove as Main Guardian',
          onConfirm: _clearMain,
        ),
        if (!widget.cardLayout) SizedBox(height: widget.compact ? 6 : 9),
      ],
      if (!widget.person.isMain) ...[
        _managementAction(
          intent: ZyraGuardianManagementAction.makeMain,
          actionKey: const ValueKey('guardian-make-main'),
          icon: Icons.shield_outlined,
          label: 'Make Main Guardian',
          onConfirm: _makeMain,
        ),
        if (!widget.cardLayout) SizedBox(height: widget.compact ? 6 : 9),
      ],
      _managementAction(
        intent: ZyraGuardianManagementAction.remove,
        actionKey: const ValueKey('guardian-remove'),
        icon: Icons.person_remove_outlined,
        label: widget.cardLayout
            ? 'Remove ${widget.person.firstName}'
            : 'Remove Guardian',
        destructive: true,
        onConfirm: _remove,
      ),
    ];
    if (widget.closeCardMenu case final close?) {
      final revision = _interactionRevision;
      actions.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _ManageActionButton(
            key: const ValueKey('guardian-card-menu-cancel'),
            canAct: () => _current && revision == _interactionRevision,
            cardLayout: true,
            pill: true,
            label: 'Cancel',
            onTap: _busy || _asking ? null : close,
          ),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions,
      );
    }
    return Column(children: actions);
  }

  Widget _managementAction({
    required ZyraGuardianManagementAction intent,
    required Key actionKey,
    required IconData icon,
    required String label,
    required Future<void> Function() onConfirm,
    bool destructive = false,
  }) {
    final revision = _interactionRevision;
    return _ManageActionButton(
      canAct: () => _current && revision == _interactionRevision,
      cardLayout: widget.cardLayout,
      key: actionKey,
      icon: icon,
      label: label,
      destructive: destructive,
      compact: widget.compact,
      onTap: _busy || _asking ? null : () => _ask(intent, onConfirm),
    );
  }
}

class _ManageActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool destructive;
  final VoidCallback? onTap;
  final bool compact;
  final bool cardLayout, pill;
  final bool Function()? canAct;

  const _ManageActionButton({
    super.key,
    this.icon,
    required this.label,
    this.destructive = false,
    this.compact = false,
    this.cardLayout = false,
    this.pill = false,
    this.canAct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final signal = destructive ? ZyraColors.destructive : ZyraColors.ink(0.68);
    if (cardLayout) {
      final radius = pill ? BorderRadius.circular(30) : null;
      return InkWell(
        borderRadius: radius,
        onTap: ZyraTapFeedback.onTap(context, onTap, canAct: canAct),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: pill
                ? Border.all(color: ZyraColors.ink(.14))
                : Border(bottom: BorderSide(color: ZyraColors.ink(.10))),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ZyraText.body(
              size: 13,
              color: destructive
                  ? const Color(0xFFAC453E)
                  : ZyraColors.foreground,
            ),
          ),
        ),
      );
    }
    return ZyraFloatingSurface(
      radius: 16,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: ZyraTapFeedback.onTap(context, onTap, canAct: canAct),
          borderRadius: BorderRadius.circular(16),
          child: ZyraFloatingSurface(
            radius: 20,
            child: Container(
              constraints: BoxConstraints(minHeight: compact ? 42 : 49),
              padding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: compact ? 8 : 11,
              ),
              decoration: BoxDecoration(
                color: destructive
                    ? signal.withValues(alpha: 0.06)
                    : ZyraColors.surfaceFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: destructive
                      ? signal.withValues(alpha: 0.30)
                      : ZyraColors.ink(0.16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: signal),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: ZyraText.body(
                        size: 13,
                        color: destructive
                            ? ZyraColors.dangerText
                            : ZyraColors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<GuardianJourneyAccessState> _sampleJourneyAccess(
  ZyraDeveloperSamples samples,
  WaliLinkedPerson person,
) => [
  for (final row in samples.activeRows ?? const <ZyraSampleJourney>[])
    GuardianJourneyAccessState(
      attemptId: row.id,
      matchId: row.id,
      counterpartFirstName: row.person.firstName,
      included: person.isMain || samples.guardianIncluded(person.id, row.id),
      canChange: !person.isMain,
      guardianIsMain: person.isMain,
    ),
];

class _MainGuardianJourneyAccess extends StatefulWidget {
  final WaliLinkedPerson person;
  final GuardianPageJourneyAccessLoader? loader;
  final GuardianPageHistoryConsentLoader? historyConsentLoader;
  final bool preview;
  final int previewActiveJourneyCount;
  final bool showChat;

  const _MainGuardianJourneyAccess({
    required this.person,
    required this.loader,
    required this.historyConsentLoader,
    required this.preview,
    required this.previewActiveJourneyCount,
    required this.showChat,
  });

  @override
  State<_MainGuardianJourneyAccess> createState() =>
      _MainGuardianJourneyAccessState();
}

class _MainGuardianJourneyAccessState extends State<_MainGuardianJourneyAccess>
    with _GuardianControlLifetime<_MainGuardianJourneyAccess> {
  List<GuardianJourneyAccessState>? _confirmed;
  bool _loading = false;
  bool _available = true;

  @override
  bool get guardianPreviewRequested => widget.preview;

  @override
  void withdrawGuardianControl() {
    _confirmed = null;
    _loading = false;
    _available = false;
  }

  @override
  void initState() {
    super.initState();
    _resetAndLoad();
  }

  @override
  void didUpdateWidget(covariant _MainGuardianJourneyAccess oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id ||
        oldWidget.showChat != widget.showChat ||
        oldWidget.person.isMain != widget.person.isMain ||
        oldWidget.preview != widget.preview ||
        oldWidget.previewActiveJourneyCount !=
            widget.previewActiveJourneyCount ||
        oldWidget.loader != widget.loader ||
        oldWidget.historyConsentLoader != widget.historyConsentLoader) {
      replaceGuardianLifetime();
      _resetAndLoad();
    }
  }

  void _resetAndLoad() {
    guardianRequest++;
    _confirmed = null;
    _loading = false;
    _available = true;
    if (widget.preview) {
      if (!guardianLifetime.canPreview) {
        _available = false;
        return;
      }
      _confirmed = _previewJourneyAccessStates(
        widget.previewActiveJourneyCount,
        mainGuardian: true,
        showChat: widget.showChat,
      );
      return;
    }
    if (!guardianLifetime.isCurrent) {
      _available = false;
      return;
    }
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || !guardianLifetime.isCurrent) return;
    final request = ++guardianRequest;
    final lifetime = guardianLifetime;
    final loader = widget.loader;
    if (loader == null) {
      if (!guardianResultCurrent(request, lifetime)) return;
      setState(() {
        _loading = false;
        _available = false;
      });
      return;
    }
    if (!_loading) setState(() => _loading = true);
    ZyraSourceResult<List<GuardianJourneyAccessState>> result;
    try {
      result = await loader(guardianId: widget.person.id);
    } catch (error) {
      debugPrint('ZYRA Main Guardian Journey access read failed — $error');
      if (!guardianResultCurrent(request, lifetime)) return;
      setState(() {
        _loading = false;
        _available = false;
      });
      return;
    }
    if (!guardianResultCurrent(request, lifetime)) return;
    final states = result.valueOrNull;
    final valid =
        result.isAvailable &&
        states != null &&
        states.every(
          (state) => state.guardianIsMain && state.included && !state.canChange,
        );
    setState(() {
      _loading = false;
      _available = valid;
      if (valid) _confirmed = states;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('main-guardian-protected-access'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _GuardianJourneyAccessHeading(),
      SizedBox(height: _shortGuardianPage(context) ? 3 : 6),
      Expanded(child: _buildJourneyAccess()),
      SizedBox(height: _shortGuardianPage(context) ? 3 : 12),
      _GuardianHistoryConsentControl(
        key: ValueKey('guardian-history-consent-${widget.person.id}'),
        person: widget.person,
        loader: widget.historyConsentLoader,
        preview: widget.preview,
      ),
    ],
  );

  Widget _buildJourneyAccess() {
    final samples = ZyraDeveloperSamples.instance;
    final overlay = widget.preview
        ? const <GuardianJourneyAccessState>[]
        : _sampleJourneyAccess(samples, widget.person);
    final replacesOrdinary = !widget.preview && samples.overridesActive;
    final ordinary = _confirmed;
    final states = [if (!replacesOrdinary) ...?ordinary, ...overlay];
    if (replacesOrdinary) {
      return _JourneyAccessSummary(
        states: states,
        requiredAccess: true,
        showChat: widget.showChat,
      );
    }
    if (_loading && ordinary == null) {
      return _JourneyAccessSummary(
        states: states,
        showChat: widget.showChat,
        requiredAccess: true,
        placeholderLabel: 'Loading Journey…',
        statusLabel: 'LOADING JOURNEY ACCESS',
      );
    }
    if (!_available || ordinary == null) {
      return _JourneyAccessSummary(
        states: states,
        showChat: widget.showChat,
        requiredAccess: true,
        placeholderLabel: 'Journey unavailable',
        statusLabel: 'JOURNEY ACCESS UNAVAILABLE',
        onRetry: _loading ? null : boundGuardianCallback(_load),
      );
    }
    return _JourneyAccessSummary(
      states: states,
      requiredAccess: true,
      showChat: widget.showChat,
    );
  }
}

class _GuardianJourneyAccessHeading extends StatelessWidget {
  const _GuardianJourneyAccessHeading();

  @override
  Widget build(BuildContext context) => Align(
    key: const ValueKey('guardian-journey-access-heading'),
    alignment: Alignment.centerLeft,
    child: Text('Active Journey access', style: ZyraText.body(size: 13.25)),
  );
}

List<GuardianJourneyAccessState> _previewJourneyAccessStates(
  int requestedCount, {
  required bool mainGuardian,
  required bool showChat,
}) {
  const names = ['Maryam', 'Aaliyah', 'Sara'];
  final count = requestedCount.clamp(0, 3).toInt();
  return [
    for (var index = 0; index < count; index++)
      GuardianJourneyAccessState(
        attemptId: index == 0
            ? 'dev-active-journey'
            : 'dev-active-journey-${index + 1}',
        matchId: 'dev-match-${index + 1}',
        counterpartFirstName: names[index],
        included: true,
        canChange: !mainGuardian,
        guardianIsMain: mainGuardian,
        chatAvailable: showChat,
        chatEnabled: showChat,
      ),
  ];
}

class _AdditionalGuardianJourneyAccess extends StatefulWidget {
  final WaliLinkedPerson person;
  final GuardianPageJourneyAccessLoader? loader;
  final GuardianPageHistoryConsentLoader? historyConsentLoader;
  final bool preview;
  final int previewActiveJourneyCount;
  final bool showChat;

  const _AdditionalGuardianJourneyAccess({
    required this.person,
    required this.loader,
    required this.historyConsentLoader,
    required this.preview,
    required this.previewActiveJourneyCount,
    required this.showChat,
  });

  @override
  State<_AdditionalGuardianJourneyAccess> createState() =>
      _AdditionalGuardianJourneyAccessState();
}

class _AdditionalGuardianJourneyAccessState
    extends State<_AdditionalGuardianJourneyAccess>
    with _GuardianControlLifetime<_AdditionalGuardianJourneyAccess> {
  List<GuardianJourneyAccessState>? _confirmed;
  bool _loading = false;
  bool _available = true;
  bool _writeFailed = false;
  String? _busyAttempt;

  bool _validAdditionalState(GuardianJourneyAccessState state) {
    if (state.guardianIsMain ||
        (state.chatEnabled && (!state.included || !state.chatAvailable))) {
      return false;
    }
    if (state.requiredByPaidAgreement) {
      return widget.showChat &&
          !state.canChange &&
          state.included &&
          state.chatAvailable &&
          state.chatEnabled;
    }
    return state.canChange;
  }

  @override
  bool get guardianPreviewRequested => widget.preview;

  @override
  void withdrawGuardianControl() {
    _confirmed = null;
    _loading = false;
    _available = false;
    _writeFailed = false;
    _busyAttempt = null;
  }

  @override
  void initState() {
    super.initState();
    _resetAndLoad();
  }

  @override
  void didUpdateWidget(covariant _AdditionalGuardianJourneyAccess oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id ||
        oldWidget.showChat != widget.showChat ||
        oldWidget.person.isMain != widget.person.isMain ||
        oldWidget.preview != widget.preview ||
        oldWidget.previewActiveJourneyCount !=
            widget.previewActiveJourneyCount ||
        oldWidget.loader != widget.loader ||
        oldWidget.historyConsentLoader != widget.historyConsentLoader) {
      replaceGuardianLifetime();
      _resetAndLoad();
    }
  }

  void _resetAndLoad() {
    guardianRequest++;
    _confirmed = null;
    _loading = false;
    _available = true;
    _writeFailed = false;
    _busyAttempt = null;
    if (widget.preview) {
      if (!guardianLifetime.canPreview) {
        _available = false;
        return;
      }
      _confirmed = _previewJourneyAccessStates(
        widget.previewActiveJourneyCount,
        mainGuardian: false,
        showChat: widget.showChat,
      );
      return;
    }
    if (!guardianLifetime.isCurrent) {
      _available = false;
      return;
    }
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || !guardianLifetime.isCurrent) return;
    final request = ++guardianRequest;
    final lifetime = guardianLifetime;
    final loader = widget.loader;
    if (loader == null) {
      if (!guardianResultCurrent(request, lifetime)) return;
      setState(() {
        _loading = false;
        _available = false;
      });
      return;
    }
    if (!_loading) setState(() => _loading = true);
    ZyraSourceResult<List<GuardianJourneyAccessState>> result;
    try {
      result = await loader(guardianId: widget.person.id);
    } catch (error) {
      debugPrint('ZYRA Guardian Journey access read failed — $error');
      if (!guardianResultCurrent(request, lifetime)) return;
      setState(() {
        _loading = false;
        _available = false;
      });
      return;
    }
    if (!guardianResultCurrent(request, lifetime)) return;
    final states = result.valueOrNull;
    final valid =
        result.isAvailable &&
        states != null &&
        states.every(_validAdditionalState);
    setState(() {
      _loading = false;
      _available = valid;
      _writeFailed = false;
      if (valid) _confirmed = states;
    });
  }

  Future<void> _setEnabled(
    GuardianJourneyAccessState state,
    bool enabled,
  ) async {
    if (!mounted ||
        (!widget.preview && ZyraDeveloperSamples.instance.overridesActive) ||
        !state.canChange ||
        state.requiredByPaidAgreement ||
        !guardianLifetime.isCurrent ||
        !(_confirmed?.any((item) => identical(item, state)) ?? false) ||
        _busyAttempt != null ||
        !_available) {
      return;
    }
    if (widget.preview) {
      if (!guardianLifetime.canPreview) return;
      setState(() {
        _confirmed = [
          for (final item in _confirmed ?? const [])
            if (item.attemptId == state.attemptId)
              GuardianJourneyAccessState(
                attemptId: item.attemptId,
                matchId: item.matchId,
                counterpartFirstName: item.counterpartFirstName,
                included: enabled,
                canChange: item.canChange,
                guardianIsMain: item.guardianIsMain,
                chatAvailable: item.chatAvailable,
                chatEnabled: enabled ? item.chatEnabled : false,
                requiredByPaidAgreement: item.requiredByPaidAgreement,
              )
            else
              item,
        ];
      });
      return;
    }
    final loader = widget.loader;
    if (loader == null) return;
    final request = ++guardianRequest;
    final lifetime = guardianLifetime;
    setState(() {
      _busyAttempt = state.attemptId;
      _writeFailed = false;
    });
    ZyraSourceResult<List<GuardianJourneyAccessState>> result;
    try {
      result = await loader(
        guardianId: widget.person.id,
        attemptId: state.attemptId,
        enabled: enabled,
      );
    } catch (error) {
      debugPrint('ZYRA Guardian Journey access write failed — $error');
      result = const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
    final returned = result.valueOrNull;
    final accepted =
        result.isAvailable &&
        returned != null &&
        returned.every(_validAdditionalState) &&
        returned.any(
          (item) =>
              item.attemptId == state.attemptId && item.included == enabled,
        );
    if (!guardianResultCurrent(request, lifetime)) return;
    setState(() {
      _busyAttempt = null;
      _writeFailed = !accepted;
      _available = true;
      if (accepted) _confirmed = returned;
    });
  }

  Future<void> _setChatEnabled(
    GuardianJourneyAccessState state,
    bool enabled,
  ) async {
    if (!mounted ||
        (!widget.preview && ZyraDeveloperSamples.instance.overridesActive) ||
        !widget.showChat ||
        !state.canChange ||
        state.requiredByPaidAgreement ||
        !guardianLifetime.isCurrent ||
        !(_confirmed?.any((item) => identical(item, state)) ?? false) ||
        _busyAttempt != null ||
        !_available ||
        !state.chatAvailable ||
        !state.included) {
      return;
    }
    if (widget.preview) {
      if (!guardianLifetime.canPreview) return;
      setState(() {
        _confirmed = [
          for (final item in _confirmed ?? const [])
            if (item.attemptId == state.attemptId)
              GuardianJourneyAccessState(
                attemptId: item.attemptId,
                matchId: item.matchId,
                counterpartFirstName: item.counterpartFirstName,
                included: item.included,
                canChange: item.canChange,
                guardianIsMain: item.guardianIsMain,
                chatAvailable: item.chatAvailable,
                chatEnabled: enabled,
                requiredByPaidAgreement: item.requiredByPaidAgreement,
              )
            else
              item,
        ];
      });
      return;
    }
    final loader = widget.loader;
    if (loader == null) return;
    final request = ++guardianRequest;
    final lifetime = guardianLifetime;
    setState(() {
      _busyAttempt = state.attemptId;
      _writeFailed = false;
    });
    ZyraSourceResult<List<GuardianJourneyAccessState>> result;
    try {
      result = await loader(
        guardianId: widget.person.id,
        attemptId: state.attemptId,
        chatEnabled: enabled,
      );
    } catch (error) {
      debugPrint('ZYRA Guardian Journey chat access write failed — $error');
      result = const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
    final returned = result.valueOrNull;
    final accepted =
        result.isAvailable &&
        returned != null &&
        returned.every(_validAdditionalState) &&
        returned.any(
          (item) =>
              item.attemptId == state.attemptId && item.chatEnabled == enabled,
        );
    if (!guardianResultCurrent(request, lifetime)) return;
    setState(() {
      _busyAttempt = null;
      _writeFailed = !accepted;
      _available = true;
      if (accepted) _confirmed = returned;
    });
  }

  @override
  Widget build(BuildContext context) {
    final states = _confirmed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GuardianJourneyAccessHeading(),
        SizedBox(height: _shortGuardianPage(context) ? 3 : 6),
        Expanded(child: _buildJourneyAccess(states)),
        SizedBox(height: _shortGuardianPage(context) ? 3 : 12),
        _GuardianHistoryConsentControl(
          key: ValueKey('guardian-history-consent-${widget.person.id}'),
          person: widget.person,
          loader: widget.historyConsentLoader,
          preview: widget.preview,
        ),
      ],
    );
  }

  Widget _buildJourneyAccess(List<GuardianJourneyAccessState>? ordinary) {
    final lifetime = guardianLifetime;
    final samples = ZyraDeveloperSamples.instance;
    final overlay = widget.preview
        ? const <GuardianJourneyAccessState>[]
        : _sampleJourneyAccess(samples, widget.person);
    final replacesOrdinary = !widget.preview && samples.overridesActive;
    final states = [if (!replacesOrdinary) ...?ordinary, ...overlay];
    final lease = samples.generation;
    final guardian = widget.person;
    void changeSample(GuardianJourneyAccessState state, bool enabled) {
      if (mounted &&
          identical(lifetime, guardianLifetime) &&
          lifetime.isCurrent &&
          samples.isCurrentLease(lease) &&
          guardian.id == widget.person.id &&
          !widget.person.isMain) {
        samples.setGuardianIncluded(guardian.id, state.attemptId, enabled);
      }
    }

    if (replacesOrdinary) {
      return _JourneyAccessSummary(
        states: states,
        showChat: widget.showChat,
        onViewChanged: changeSample,
      );
    }
    if (_loading && ordinary == null) {
      return _JourneyAccessSummary(
        states: states,
        showChat: widget.showChat,
        placeholderLabel: 'Loading Journey…',
        statusLabel: 'LOADING JOURNEY ACCESS',
      );
    }
    if (!_available || ordinary == null) {
      return _JourneyAccessSummary(
        states: states,
        showChat: widget.showChat,
        busyAttempt: 'unavailable',
        placeholderLabel: 'Journey unavailable',
        statusLabel: 'JOURNEY ACCESS UNAVAILABLE',
        onRetry: _loading ? null : boundGuardianCallback(_load),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _JourneyAccessSummary(
            states: states,
            showChat: widget.showChat,
            busyAttempt: _busyAttempt,
            onViewChanged: (state, enabled) {
              if (overlay.contains(state)) {
                changeSample(state, enabled);
                return;
              }
              if (identical(lifetime, guardianLifetime) && lifetime.isCurrent) {
                _setEnabled(state, enabled);
              }
            },
            onChatChanged: (state, enabled) {
              if (overlay.contains(state)) return;
              if (identical(lifetime, guardianLifetime) && lifetime.isCurrent) {
                _setChatEnabled(state, enabled);
              }
            },
          ),
        ),
        if (_writeFailed) ...[
          const SizedBox(height: 10),
          ZyraErrorBanner(
            message:
                'That change was not confirmed. Showing the last confirmed '
                'Journey access.',
            onRetry: boundGuardianCallback(_load),
          ),
        ],
      ],
    );
  }
}

class _JourneyAccessSummary extends StatelessWidget {
  final List<GuardianJourneyAccessState> states;
  final String? busyAttempt;
  final void Function(GuardianJourneyAccessState state, bool enabled)?
  onViewChanged;
  final void Function(GuardianJourneyAccessState state, bool enabled)?
  onChatChanged;
  final bool requiredAccess;
  final bool showChat;
  final String placeholderLabel;
  final String? statusLabel;
  final VoidCallback? onRetry;

  const _JourneyAccessSummary({
    required this.states,
    this.busyAttempt,
    this.onViewChanged,
    this.onChatChanged,
    this.requiredAccess = false,
    this.showChat = true,
    this.placeholderLabel = 'Awaiting a Journey',
    this.statusLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final permissionColumnWidth = _JourneyPermissionHeader.columnWidth(context);
    return Semantics(
      label: [
        ?statusLabel,
        if (states.isNotEmpty)
          states.map((state) => state.counterpartFirstName).join(', '),
        !showChat
            ? (requiredAccess
                  ? 'View is required for each active Journey.'
                  : 'View permission is set for each active Journey.')
            : requiredAccess
            ? 'View is required for each active Journey. Chat depends on Journey availability.'
            : states.any((state) => state.requiredByPaidAgreement)
            ? 'View and Chat are required for agreed new Journeys. Other Journey permissions are set separately.'
            : 'View and Chat permissions are set separately for each active Journey.',
      ].join('. '),
      child: ZyraFloatingSurface(
        radius: 20,
        child: Container(
          key: const ValueKey('guardian-journey-access-summary'),
          padding: const EdgeInsets.fromLTRB(14, 11, 10, 8),
          decoration: BoxDecoration(
            color: ZyraColors.surfaceFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (statusLabel != null) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        statusLabel!,
                        style: ZyraText.subtext(
                          size: 9.5,
                          color: ZyraColors.ink(0.54),
                        ).copyWith(letterSpacing: 0.9),
                      ),
                    ),
                    if (onRetry != null)
                      Flexible(
                        flex: 2,
                        child: TextButton(
                          onPressed: ZyraTapFeedback.onTap(context, onRetry),
                          child: const Text('Try again'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel == 'LOADING JOURNEY ACCESS'
                      ? 'Checking your current Journey access…'
                      : 'Journey access could not be refreshed.',
                  style: ZyraText.subtext(size: 10.75),
                ),
                const SizedBox(height: 8),
              ],
              _JourneyPermissionHeader(
                permissionColumnWidth: permissionColumnWidth,
                showChat: showChat,
              ),
              const SizedBox(
                key: ValueKey('guardian-journey-permission-header-gap'),
                height: 8,
              ),
              Divider(
                key: const ValueKey(
                  'guardian-journey-permission-header-divider',
                ),
                height: 1,
                color: ZyraColors.ink(0.10),
              ),
              Expanded(
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < math.max(3, states.length);
                      index++
                    ) ...[
                      Expanded(
                        child: index >= states.length
                            ? _PendingJourneyPermissionRow(
                                slot: index,
                                label: placeholderLabel,
                                showFreePlace: statusLabel == null,
                                permissionColumnWidth: permissionColumnWidth,
                                showChat: showChat,
                              )
                            : _JourneyPermissionTableRow(
                                state: states[index],
                                permissionColumnWidth: permissionColumnWidth,
                                showChat: showChat,
                                busy: busyAttempt != null,
                                requiredAccess:
                                    requiredAccess ||
                                    states[index].requiredByPaidAgreement,
                                onViewChanged: onViewChanged == null
                                    ? null
                                    : (enabled) => onViewChanged!(
                                        states[index],
                                        enabled,
                                      ),
                                onChatChanged: onChatChanged == null
                                    ? null
                                    : (enabled) => onChatChanged!(
                                        states[index],
                                        enabled,
                                      ),
                              ),
                      ),
                      if (index < math.max(3, states.length) - 1)
                        Divider(height: 1, color: ZyraColors.ink(0.08)),
                    ],
                  ],
                ),
              ),
              if (showChat && states.any((state) => !state.chatAvailable)) ...[
                const SizedBox(height: 8),
                Text(
                  'Chat is unavailable for this Journey.',
                  key: const ValueKey('guardian-journey-chat-unavailable'),
                  style: ZyraText.subtext(size: 10.75),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyPermissionHeader extends StatelessWidget {
  const _JourneyPermissionHeader({
    required this.permissionColumnWidth,
    required this.showChat,
  });
  final double permissionColumnWidth;
  final bool showChat;

  static TextStyle get _labelStyle => ZyraText.subtext(size: 12.25);

  // Share one measured width with every row, so enlarged labels remain above
  // their own unchanged controls rather than clipping or drifting sideways.
  static double columnWidth(BuildContext context) {
    var width = 56.0;
    var style = DefaultTextStyle.of(context).style.merge(_labelStyle);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    for (final label in ['View', 'Chat']) {
      final measure = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      )..layout();
      width = math.max(width, measure.width.ceilToDouble() + 12);
      measure.dispose();
    }
    return width;
  }

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('guardian-journey-permission-header'),
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text('Journey', style: _labelStyle)),
        SizedBox(
          width: permissionColumnWidth,
          child: Text('View', textAlign: TextAlign.center, style: _labelStyle),
        ),
        if (showChat)
          SizedBox(
            width: permissionColumnWidth,
            child: Text(
              'Chat',
              textAlign: TextAlign.center,
              style: _labelStyle,
            ),
          ),
      ],
    ),
  );
}

/// A visual capacity slot only: never a Journey record or writable attempt.
class _PendingJourneyPermissionRow extends StatelessWidget {
  const _PendingJourneyPermissionRow({
    required this.slot,
    required this.label,
    required this.showFreePlace,
    required this.permissionColumnWidth,
    required this.showChat,
  });
  final int slot;
  final String label;
  final bool showFreePlace;
  final double permissionColumnWidth;
  final bool showChat;

  @override
  Widget build(BuildContext context) => Row(
    key: ValueKey('guardian-journey-pending-row-$slot'),
    children: [
      if (showFreePlace) ...[
        CustomPaint(
          key: ValueKey('guardian-journey-free-circle-$slot'),
          foregroundPainter: ZyraGuardianDashedBorder(
            20,
            ZyraColors.journeyGold,
          ),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(Icons.add, size: 18, color: ZyraColors.journeyGold),
          ),
        ),
        const SizedBox(width: _journeyAccessIdentityGap),
      ],
      Expanded(child: Text(label, style: ZyraText.subtext(size: 12.25))),
      for (final permission in ['view', if (showChat) 'chat'])
        SizedBox(
          width: permissionColumnWidth,
          child: Center(
            child: _JourneyPermissionCircle(
              controlKey: ValueKey(
                'guardian-journey-pending-$permission-$slot',
              ),
              value: false,
              onChanged: null,
              semanticLabel:
                  '$label, ${permission == 'view' ? 'View' : 'Chat'} unavailable',
            ),
          ),
        ),
    ],
  );
}

class _JourneyPermissionTableRow extends StatelessWidget {
  final GuardianJourneyAccessState state;
  final double permissionColumnWidth;
  final bool busy;
  final bool requiredAccess;
  final bool showChat;
  final ValueChanged<bool>? onViewChanged;
  final ValueChanged<bool>? onChatChanged;

  const _JourneyPermissionTableRow({
    required this.state,
    required this.permissionColumnWidth,
    required this.busy,
    required this.requiredAccess,
    required this.showChat,
    required this.onViewChanged,
    required this.onChatChanged,
  });

  Widget _portrait() {
    final name = state.counterpartFirstName;
    final monogram = ZyraGoldRingMonogram(
      name: name,
      size: 42,
      fontSize: 16,
      textScaler: TextScaler.noScaling,
    );
    // The signed-in Seeker's existing Journey list already owns these photos.
    // Match the permission row's exact Journey and never substitute a sample.
    final journey = AppState.instance.activeJourneys
        .where(
          (item) =>
              !item.isMock &&
              item.matchId == state.matchId &&
              item.profile.id != ZyraAccountState.userId &&
              item.profile.firstName.trim() == name,
        )
        .firstOrNull;
    final photo = journey?.profile.photoUrl ?? '';
    return SizedBox.square(
      key: ValueKey('guardian-journey-portrait-${state.attemptId}'),
      dimension: 42,
      child: photo.isEmpty
          ? monogram
          : ClipOval(
              child: ZyraProfileImageFallback(
                fallback: monogram,
                child: ZyraProfileImage(photo, width: 42, fit: BoxFit.cover),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: _shortGuardianPage(context) ? 0 : 3,
    ),
    child: Row(
      children: [
        _portrait(),
        const SizedBox(width: _journeyAccessIdentityGap),
        Expanded(
          child: Text(
            'Journey with ${state.counterpartFirstName}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ZyraText.body(size: 12.25),
          ),
        ),
        SizedBox(
          width: permissionColumnWidth,
          child: Center(
            child: requiredAccess
                ? _RequiredAccessMark(
                    markKey: ValueKey(
                      'guardian-journey-view-required-${state.attemptId}',
                    ),
                    semanticLabel:
                        'View required for Journey with ${state.counterpartFirstName}',
                  )
                : _JourneyPermissionCircle(
                    controlKey: ValueKey(
                      'guardian-journey-access-toggle-${state.attemptId}',
                    ),
                    value: state.included,
                    onChanged:
                        busy ||
                            !state.canChange ||
                            state.requiredByPaidAgreement
                        ? null
                        : onViewChanged,
                    semanticLabel:
                        'View Journey with ${state.counterpartFirstName}',
                  ),
          ),
        ),
        if (showChat)
          SizedBox(
            width: permissionColumnWidth,
            child: Center(
              child: requiredAccess && state.chatAvailable
                  ? _RequiredAccessMark(
                      markKey: ValueKey(
                        'guardian-journey-chat-required-${state.attemptId}',
                      ),
                      semanticLabel:
                          'Chat required for Journey with ${state.counterpartFirstName}',
                    )
                  : _JourneyPermissionCircle(
                      controlKey: ValueKey(
                        'guardian-journey-chat-toggle-${state.attemptId}',
                      ),
                      value:
                          state.included &&
                          state.chatAvailable &&
                          state.chatEnabled,
                      onChanged:
                          !requiredAccess &&
                              state.canChange &&
                              !state.requiredByPaidAgreement &&
                              state.included &&
                              state.chatAvailable &&
                              !busy
                          ? onChatChanged
                          : null,
                      semanticLabel: state.chatAvailable
                          ? 'Chat in Journey with ${state.counterpartFirstName}'
                          : 'Chat unavailable in Journey with ${state.counterpartFirstName}',
                    ),
            ),
          ),
      ],
    ),
  );
}

class _RequiredAccessMark extends StatelessWidget {
  final Key markKey;
  final String semanticLabel;

  const _RequiredAccessMark({
    required this.markKey,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: _JourneyPermissionFace(faceKey: markKey, value: true),
  );
}

/// The same 26px face for required and chosen access; the interactive wrapper
/// owns the 44px target and never creates or bypasses permission authority.
class _JourneyPermissionFace extends StatelessWidget {
  const _JourneyPermissionFace({
    this.faceKey,
    required this.value,
    this.disabled = false,
  });

  final Key? faceKey;
  final bool value;
  final bool disabled;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 20,
    child: Container(
      key: faceKey,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: value ? ZyraColors.surfaceFill : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: ZyraColors.journeyGold.withValues(
            alpha: value ? (disabled ? 0.30 : 0.52) : (disabled ? 0.14 : 0.28),
          ),
        ),
      ),
      child: value
          ? Icon(
              Icons.check_rounded,
              size: 16,
              color: disabled
                  ? ZyraColors.journeyGold.withValues(alpha: 0.5)
                  : ZyraColors.journeyGold,
            )
          : null,
    ),
  );
}

class _JourneyPermissionCircle extends StatelessWidget {
  const _JourneyPermissionCircle({
    required this.controlKey,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final Key controlKey;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    final toggle = change == null ? null : () => change(!value);
    return Semantics(
      key: controlKey,
      label: semanticLabel,
      button: true,
      toggled: value,
      enabled: change != null,
      onTap: ZyraTapFeedback.onTap(context, toggle),
      excludeSemantics: true,
      child: ZyraFloatingSurface(
        radius: 16,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: ZyraTapFeedback.onTap(context, toggle),
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: _JourneyPermissionFace(
                  value: value,
                  disabled: change == null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactZyraSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final Key? switchKey;
  final double width;
  final double height;

  const _CompactZyraSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.switchKey,
    this.width = 42,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    toggled: value,
    enabled: onChanged != null,
    excludeSemantics: true,
    child: SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          key: switchKey,
          value: value,
          onChanged: ZyraTapFeedback.onChanged(context, onChanged),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeThumbColor: ZyraColors.journeyGold,
          activeTrackColor: ZyraColors.actionFill.withValues(alpha: 0.46),
          inactiveThumbColor: ZyraColors.ink(0.66),
          inactiveTrackColor: ZyraColors.surfaceFill,
          trackOutlineColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? ZyraColors.surfaceBorder.withValues(alpha: 0.55)
                : ZyraColors.journeyGold.withValues(alpha: value ? 0.52 : 0.26),
          ),
        ),
      ),
    ),
  );
}

class _GuardianHistoryConsentControl extends StatefulWidget {
  final WaliLinkedPerson person;
  final GuardianPageHistoryConsentLoader? loader;
  final bool preview;

  const _GuardianHistoryConsentControl({
    super.key,
    required this.person,
    required this.loader,
    required this.preview,
  });

  @override
  State<_GuardianHistoryConsentControl> createState() =>
      _GuardianHistoryConsentControlState();
}

class _GuardianHistoryConsentControlState
    extends State<_GuardianHistoryConsentControl>
    with _GuardianControlLifetime<_GuardianHistoryConsentControl> {
  GuardianHistoryConsentState? _confirmed;
  bool _loading = false;
  bool _busy = false;
  bool _available = true;

  @override
  bool get guardianPreviewRequested => widget.preview;

  @override
  void withdrawGuardianControl() {
    _confirmed = null;
    _loading = false;
    _busy = false;
    _available = false;
  }

  @override
  void initState() {
    super.initState();
    _resetAndLoad();
  }

  @override
  void didUpdateWidget(covariant _GuardianHistoryConsentControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id ||
        oldWidget.person.isMain != widget.person.isMain ||
        oldWidget.preview != widget.preview ||
        oldWidget.loader != widget.loader) {
      replaceGuardianLifetime();
      _resetAndLoad();
    }
  }

  bool _matches(GuardianHistoryConsentState state) =>
      state.activeGuardianLinkId != null &&
      state.guardianId == widget.person.id &&
      state.guardianIsMain == widget.person.isMain;

  void _resetAndLoad() {
    guardianRequest++;
    _confirmed = null;
    _loading = false;
    _busy = false;
    _available = true;
    if (widget.preview) {
      if (!guardianLifetime.canPreview) {
        _available = false;
        return;
      }
      _confirmed = GuardianHistoryConsentState(
        enabled: false,
        activeGuardianLinkId: 'dev-guardian-link-${widget.person.id}',
        guardianId: widget.person.id,
        guardianIsMain: widget.person.isMain,
      );
      return;
    }
    if (!guardianLifetime.isCurrent) {
      _available = false;
      return;
    }
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || !guardianLifetime.isCurrent || _busy) return;
    final request = ++guardianRequest;
    final lifetime = guardianLifetime;
    final loader = widget.loader;
    if (loader == null) {
      if (!guardianResultCurrent(request, lifetime)) return;
      setState(() {
        _loading = false;
        _available = false;
      });
      return;
    }
    if (!_loading) setState(() => _loading = true);
    ZyraSourceResult<GuardianHistoryConsentState> result;
    try {
      result = await loader(
        guardianId: widget.person.id,
        guardianIsMain: widget.person.isMain,
        enabled: null,
      );
    } catch (error) {
      debugPrint('ZYRA Guardian design consent read failed — $error');
      if (!guardianResultCurrent(request, lifetime)) return;
      setState(() {
        _loading = false;
        _available = false;
      });
      return;
    }
    if (!guardianResultCurrent(request, lifetime)) return;
    final next = result.valueOrNull;
    final confirmed = result.isAvailable && next != null && _matches(next);
    setState(() {
      _loading = false;
      _available = confirmed;
      _confirmed = confirmed ? next : null;
    });
  }

  Future<void> _setEnabled(bool enabled) async {
    if (!mounted || !guardianLifetime.isCurrent) return;
    final confirmed = _confirmed;
    if (confirmed == null || _busy || _loading) {
      return;
    }
    if (widget.preview) {
      if (!guardianLifetime.canPreview) return;
      setState(() {
        _confirmed = GuardianHistoryConsentState(
          enabled: enabled,
          activeGuardianLinkId: confirmed.activeGuardianLinkId,
          guardianId: confirmed.guardianId,
          guardianIsMain: confirmed.guardianIsMain,
        );
      });
      return;
    }
    final loader = widget.loader;
    if (loader == null || !_available) return;
    final request = ++guardianRequest;
    final lifetime = guardianLifetime;
    setState(() => _busy = true);
    ZyraSourceResult<GuardianHistoryConsentState> result;
    try {
      result = await loader(
        guardianId: widget.person.id,
        guardianIsMain: widget.person.isMain,
        enabled: enabled,
      );
    } catch (error) {
      debugPrint('ZYRA Guardian design consent write failed — $error');
      if (!guardianResultCurrent(request, lifetime)) return;
      setState(() {
        _busy = false;
        _available = false;
      });
      return;
    }
    if (!guardianResultCurrent(request, lifetime)) return;
    final next = result.valueOrNull;
    final accepted =
        result.isAvailable &&
        next != null &&
        _matches(next) &&
        next.enabled == enabled;
    setState(() {
      _busy = false;
      _available = accepted;
      if (accepted) _confirmed = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = _confirmed;
    final lifetime = guardianLifetime;
    return Column(
      key: const ValueKey('guardian-history-consent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Share past Journey summaries',
                  style: ZyraText.body(size: 13.25),
                ),
              ),
              const SizedBox(width: 4),
              if (confirmed != null)
                Semantics(
                  label:
                      'Share past Journey summaries with '
                      '${widget.person.firstName}',
                  child: _CompactZyraSwitch(
                    width: 48,
                    height: 32,
                    switchKey: const ValueKey(
                      'guardian-history-consent-toggle',
                    ),
                    value: confirmed.enabled,
                    onChanged: _available && !_loading && !_busy
                        ? (enabled) {
                            if (identical(lifetime, guardianLifetime) &&
                                identical(confirmed, _confirmed) &&
                                lifetime.isCurrent) {
                              _setEnabled(enabled);
                            }
                          }
                        : null,
                    semanticLabel:
                        'Share past Journey summaries with '
                        '${widget.person.firstName}',
                  ),
                )
              else
                Flexible(
                  flex: 2,
                  child: Text(
                    _loading ? 'Loading…' : 'Unavailable',
                    style: ZyraText.subtext(
                      size: 11,
                      color: ZyraColors.ink(0.44),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_busy)
          Text('Confirming with ZYRA…', style: ZyraText.subtext(size: 11)),
        if (!_available) ...[
          const SizedBox(height: 8),
          ZyraErrorBanner(
            message: confirmed == null
                ? 'Past-summary permission could not be refreshed.'
                : 'The last change was not confirmed. Showing the last '
                      'server-confirmed state.',
            onRetry: _loading || _busy ? null : boundGuardianCallback(_load),
          ),
        ],
      ],
    );
  }
}

class _ActivityTruth extends StatelessWidget {
  final bool available;
  final GuardianActivity? obligation;
  final VoidCallback onRetry;
  final bool compact;

  const _ActivityTruth({
    required this.available,
    required this.obligation,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!available) {
      return Padding(
        padding: EdgeInsets.only(top: compact ? 0 : 14),
        child: ZyraErrorBanner(
          message: 'Current Guardian activity could not be refreshed.',
          onRetry: onRetry,
        ),
      );
    }
    final current = obligation;
    if (current == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: compact ? 0 : 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: ZyraColors.journeyGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.line!, style: ZyraText.body(size: 13.25)),
                    const SizedBox(height: 3),
                    Text(
                      current.timingLabel ?? '',
                      style: ZyraText.subtext(
                        size: 10.75,
                        color: ZyraColors.ink(0.42),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuardianIdentity extends StatelessWidget {
  final WaliLinkedPerson person;

  const _GuardianIdentity({required this.person});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(person.firstName, style: ZyraText.heading(size: 27)),
      const SizedBox(height: 3),
      Text(
        _recordedGuardianRole(person),
        style: ZyraText.subtext(size: 12.5, color: ZyraColors.ink(0.58)),
      ),
    ],
  );
}

class _GuardianMonogram extends StatelessWidget {
  final WaliLinkedPerson person;
  final double size;

  const _GuardianMonogram({required this.person, required this.size});

  @override
  Widget build(BuildContext context) => ZyraGoldRingMonogram(
    name: person.firstName,
    // Live link rows do not carry the displayed Guardian's plan.
    guardianOne: false,
    size: size,
    fontSize: size * .38,
  );
}

class _QuietSection extends StatelessWidget {
  final String? label;
  final Widget child;
  final bool compact;

  const _QuietSection({this.label, required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(vertical: compact ? 7 : 10, horizontal: 2),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: ZyraColors.ink(0.13))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          _DesignSectionLabel(label!),
          SizedBox(height: compact ? 4 : 6),
        ],
        child,
      ],
    ),
  );
}

class _DesignSectionLabel extends StatelessWidget {
  final String text;

  const _DesignSectionLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: ZyraText.chapterLabel(color: ZyraColors.ink(0.47)));
}
