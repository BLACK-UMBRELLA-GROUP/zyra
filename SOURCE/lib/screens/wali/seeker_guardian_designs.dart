import '../../widgets/zyra_floating_surface.dart';
import '../../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../services/zyra_wali_link_service.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_guardian_invitation_dashboard.dart';
import '../../widgets/zyra_guardian_preview_lifetime.dart';
import '../../widgets/floating_nav_bar.dart';

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
const double _guardianPageDotTail = 4;
const double _guardianPageNavigationGap = 20;

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
        key: const PageStorageKey('guardianship-manager'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 72),
              child: Center(child: const _ManagerEmpty()),
            ),
          ),
        ],
      );
    }

    return ListView(
      key: const PageStorageKey('guardianship-manager'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
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
    child: Text(
      'Guardian',
      key: const ValueKey('guardian-manager-title'),
      textAlign: titleAlignment.x > 0 ? TextAlign.right : TextAlign.left,
      style: titleSize == null || titleSize == ZyraText.pageTitleSize
          ? ZyraText.pageTitle()
          : ZyraText.heading(size: titleSize!),
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

class _ManagerEmpty extends StatelessWidget {
  const _ManagerEmpty();

  @override
  Widget build(BuildContext context) => ZyraEmptyState(
    key: const ValueKey('guardianship-manager-empty'),
    icon: Icons.shield_outlined,
    iconWidget: Icon(
      Icons.shield_outlined,
      key: const ValueKey('guardian-empty-shield'),
      color: ZyraColors.ink(.35),
      size: 30,
    ),
    title: 'Add a Guardian',
    message: '',
  );
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
                _ManagerMonogram(name: person.firstName, main: person.isMain),
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
  required bool main,
}) => _ManagerMonogram(name: name, main: main);

class _ManagerMonogram extends StatelessWidget {
  final String name;
  final bool main;

  const _ManagerMonogram({required this.name, required this.main});

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 20,
    child: Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyraColors.surfaceFill,
        border: Border.all(
          color: main
              ? ZyraColors.surfaceEmphasisBorder
              : ZyraColors.surfaceBorder,
        ),
      ),
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: ZyraText.heading(size: 19),
      ),
    ),
  );
}

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
/// Horizontal [PageView] movement is the sole Guardian-to-Guardian navigation.
/// Each Guardian page is a fixed one-screen layout: Journey access is always
/// visible and vertical scrolling is deliberately not part of this surface.
class SeekerGuardianPage extends StatelessWidget {
  final List<WaliLinkedPerson> people;
  final Map<String, List<GuardianActivity>> activity;
  final bool linksAvailable;
  final bool activityAvailable;
  final VoidCallback onRetry;
  final VoidCallback onAdd;
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
    if (!linksAvailable || ordered.isEmpty) {
      return GuardianshipManagerView(
        people: ordered,
        linksAvailable: linksAvailable,
        onRetryLinks: onRetry,
        onOpenGuardian: (_) {},
        onAdd: onAdd,
        onOpenMessages: onOpenMessages,
        conversationButtonBuilder: conversationButtonBuilder,
        pendingInvitesLoader: pendingInvitesLoader,
        comparisonNow: comparisonNow,
        titleAlignment: titleAlignment,
        titleSize: titleSize,
      );
    }

    // Reserve the shared bar's full touch height, not only its smaller idle
    // height. The pager may sit in SafeArea(bottom: false), so retain the
    // actual bottom inset instead of assuming it was already consumed.
    final navigationReserve =
        math.max(
          MediaQuery.paddingOf(context).bottom,
          ZyraNavBarMetrics.bottomInset,
        ) +
        ZyraNavBarMetrics.height +
        _guardianPageNavigationGap -
        _guardianPageDotTail;
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
            padding: EdgeInsets.only(bottom: navigationReserve),
            child: _GuardianPager(
              key: const ValueKey('guardian-pager'),
              people: ordered,
              activity: activity,
              activityAvailable: activityAvailable,
              onRetry: onRetry,
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
  late final PageController _controller = PageController();
  int _page = 0;

  @override
  void didUpdateWidget(covariant _GuardianPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPage = _page.clamp(0, oldWidget.people.length - 1);
    final currentGuardianId = oldWidget.people[oldPage].id;
    final sameGuardianPage = widget.people.indexWhere(
      (person) => person.id == currentGuardianId,
    );
    final nextPage = sameGuardianPage >= 0
        ? sameGuardianPage
        : _page.clamp(0, widget.people.length - 1);
    if (nextPage == _page) return;
    _page = nextPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) _controller.jumpToPage(_page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ZyraVerticalShadowViewport(
            builder: (context, clearance) => PageView.builder(
              key: const ValueKey('guardian-page-view'),
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.people.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final person = widget.people[index];
                final activities = widget.activity[person.id] ?? const [];
                return Padding(
                  padding: clearance,
                  child: Semantics(
                    label:
                        'Guardian ${index + 1} of ${widget.people.length}: '
                        '${person.firstName}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _GuardianPageContent(
                        person: person,
                        activities: activities,
                        activityAvailable: widget.activityAvailable,
                        onRetry: widget.onRetry,
                        historyConsentLoader: widget.historyConsentLoader,
                        journeyAccessLoader: widget.journeyAccessLoader,
                        historyConsentPreview: widget.historyConsentPreview,
                        previewActiveJourneyCount:
                            widget.previewActiveJourneyCount,
                        showChat: !widget.viewOnlyGuardianIds.contains(
                          person.id,
                        ),
                        otherGuardians: widget.people
                            .where((candidate) => candidate.id != person.id)
                            .toList(growable: false),
                        makeMainGuardian: widget.makeMainGuardian,
                        clearMainGuardian: widget.clearMainGuardian,
                        removeGuardian: widget.removeGuardian,
                        onChanged: widget.onChanged,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.people.length > 1) ...[
          const SizedBox(height: 12),
          _GuardianPageDots(count: widget.people.length, selected: _page),
          const SizedBox(height: _guardianPageDotTail),
        ],
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
  Widget build(BuildContext context) => Column(
    key: ValueKey('guardian-quiet-sections-${person.id}'),
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      SizedBox(height: compact ? 2 : 4),
      Row(
        children: [
          _GuardianMonogram(person: person, size: compact ? 58 : 64),
          const SizedBox(width: 14),
          Expanded(child: _GuardianIdentity(person: person)),
        ],
      ),
      SizedBox(height: compact ? 10 : 14),
      _GuardianDetailsStrip(person: person),
      SizedBox(height: compact ? 12 : 16),
      Divider(height: 1, color: ZyraColors.ink(.12)),
      const SizedBox(height: 10),
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
      const SizedBox(height: 10),
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

// LOCK19 reuses the existing inline Cancel/Confirm flow and action delegates.
Widget zyraGuardianCardManageActions({
  required WaliLinkedPerson person,
  required List<WaliLinkedPerson> otherGuardians,
  required bool Function() canAct,
  required GuardianMakeMainAction makeMainGuardian,
  required GuardianClearMainAction clearMainGuardian,
  required GuardianRemoveAction removeGuardian,
}) => _GuardianManageActions(
  key: ValueKey(('guardian-card-actions', person.id, person.isMain)),
  person: person,
  otherGuardians: otherGuardians,
  preview: true,
  makeMainGuardian: makeMainGuardian,
  clearMainGuardian: clearMainGuardian,
  removeGuardian: removeGuardian,
  onChanged: null,
  compact: true,
  cardLayout: true,
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
  final bool cardLayout;
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
    this.cardLayout = false,
    this.canAct,
  });

  @override
  State<_GuardianManageActions> createState() => _GuardianManageActionsState();
}

enum _GuardianManageIntent { makeMain, clearMain, removeGuardian }

class _GuardianManageActionsState extends State<_GuardianManageActions> {
  bool _busy = false;
  _GuardianManageIntent? _confirming;
  int _interactionRevision = 0;

  @override
  void didUpdateWidget(covariant _GuardianManageActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canAct != widget.canAct && widget.cardLayout) {
      _interactionRevision++;
      _confirming = null;
      _busy = false;
    }
  }

  bool get _current => mounted && (widget.canAct?.call() ?? true);

  void _failure(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  void _ask(_GuardianManageIntent intent) {
    if (_busy || !_current) return;
    setState(() {
      _interactionRevision++;
      _confirming = intent;
    });
  }

  void _cancel() {
    if (_busy || !_current) return;
    setState(() {
      _interactionRevision++;
      _confirming = null;
    });
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
      _confirming = changed ? null : _GuardianManageIntent.makeMain;
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
      _confirming = changed ? null : _GuardianManageIntent.clearMain;
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
      _confirming = error == null ? null : _GuardianManageIntent.removeGuardian;
    });
    if (error != null) return _failure(error);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (widget.person.isMain) ...[
        _actionOrConfirmation(
          intent: _GuardianManageIntent.clearMain,
          actionKey: const ValueKey('guardian-clear-main'),
          confirmationKey: const ValueKey('guardian-clear-main-confirmation'),
          icon: Icons.shield_outlined,
          label: widget.cardLayout
              ? 'Remove as Main'
              : 'Remove as Main Guardian',
          onConfirm: _clearMain,
        ),
        if (!widget.cardLayout) SizedBox(height: widget.compact ? 6 : 9),
      ],
      if (!widget.person.isMain) ...[
        _actionOrConfirmation(
          intent: _GuardianManageIntent.makeMain,
          actionKey: const ValueKey('guardian-make-main'),
          confirmationKey: const ValueKey('guardian-make-main-confirmation'),
          icon: Icons.shield_outlined,
          label: widget.cardLayout ? 'Make Main' : 'Make Main Guardian',
          onConfirm: _makeMain,
        ),
        if (!widget.cardLayout) SizedBox(height: widget.compact ? 6 : 9),
      ],
      _actionOrConfirmation(
        intent: _GuardianManageIntent.removeGuardian,
        actionKey: const ValueKey('guardian-remove'),
        confirmationKey: const ValueKey('guardian-remove-confirmation'),
        icon: Icons.person_remove_outlined,
        label: widget.cardLayout ? 'Remove' : 'Remove Guardian',
        destructive: true,
        onConfirm: _remove,
      ),
    ];
    if (!widget.cardLayout) return Column(children: actions);
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 320 &&
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [actions.first, const SizedBox(height: 8), actions.last],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: actions.first),
            const SizedBox(width: 8),
            Expanded(child: actions.last),
          ],
        );
      },
    );
  }

  Widget _actionOrConfirmation({
    required _GuardianManageIntent intent,
    required Key actionKey,
    required Key confirmationKey,
    required IconData icon,
    required String label,
    required Future<void> Function() onConfirm,
    bool destructive = false,
  }) {
    final revision = _interactionRevision;
    bool current() => _current && revision == _interactionRevision;
    final confirming = _confirming == intent;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: confirming
          ? Row(
              key: confirmationKey,
              children: [
                Expanded(
                  child: _ManageActionButton(
                    canAct: current,
                    cardLayout: widget.cardLayout,
                    label: 'Cancel',
                    compact: widget.compact,
                    onTap: _busy ? null : _cancel,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ManageActionButton(
                    canAct: current,
                    cardLayout: widget.cardLayout,
                    label: 'Confirm',
                    destructive: destructive,
                    compact: widget.compact,
                    onTap: _busy ? null : onConfirm,
                  ),
                ),
              ],
            )
          : _ManageActionButton(
              canAct: current,
              cardLayout: widget.cardLayout,
              key: actionKey,
              icon: icon,
              label: label,
              destructive: destructive,
              compact: widget.compact,
              onTap: _busy ? null : () => _ask(intent),
            ),
    );
  }
}

class _ManageActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool destructive;
  final VoidCallback? onTap;
  final bool compact;
  final bool cardLayout;
  final bool Function()? canAct;

  const _ManageActionButton({
    super.key,
    this.icon,
    required this.label,
    this.destructive = false,
    this.compact = false,
    this.cardLayout = false,
    this.canAct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final signal = destructive ? ZyraColors.destructive : ZyraColors.ink(0.68);
    if (cardLayout) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: ZyraFloatingSurface.standardShadows,
        ),
        child: Material(
          color: const Color(0xFFFBF7F0),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: ZyraTapFeedback.onTap(context, onTap, canAct: canAct),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              constraints: const BoxConstraints(minHeight: 42),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: ZyraText.body(
                  size: 13,
                  color: destructive
                      ? const Color(0xFFB84A42)
                      : ZyraColors.foreground,
                ),
              ),
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
                            ? ZyraColors.destructive
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
      const SizedBox(height: 6),
      Expanded(child: _buildJourneyAccess()),
      const SizedBox(height: 12),
      _GuardianHistoryConsentControl(
        key: ValueKey('guardian-history-consent-${widget.person.id}'),
        person: widget.person,
        loader: widget.historyConsentLoader,
        preview: widget.preview,
      ),
    ],
  );

  Widget _buildJourneyAccess() {
    final states = _confirmed;
    if (_loading && states == null) {
      return _JourneyAccessSummary(
        states: [],
        showChat: widget.showChat,
        requiredAccess: true,
        placeholderLabel: 'Loading Journey…',
        statusLabel: 'LOADING JOURNEY ACCESS',
      );
    }
    if (!_available || states == null) {
      return _JourneyAccessSummary(
        states: states ?? const [],
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
        const SizedBox(height: 6),
        Expanded(child: _buildJourneyAccess(states)),
        const SizedBox(height: 12),
        _GuardianHistoryConsentControl(
          key: ValueKey('guardian-history-consent-${widget.person.id}'),
          person: widget.person,
          loader: widget.historyConsentLoader,
          preview: widget.preview,
        ),
      ],
    );
  }

  Widget _buildJourneyAccess(List<GuardianJourneyAccessState>? states) {
    final lifetime = guardianLifetime;
    if (_loading && states == null) {
      return _JourneyAccessSummary(
        states: [],
        showChat: widget.showChat,
        placeholderLabel: 'Loading Journey…',
        statusLabel: 'LOADING JOURNEY ACCESS',
      );
    }
    if (!_available || states == null) {
      return _JourneyAccessSummary(
        states: states ?? const [],
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
              if (identical(lifetime, guardianLifetime) && lifetime.isCurrent) {
                _setEnabled(state, enabled);
              }
            },
            onChatChanged: (state, enabled) {
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
    required this.permissionColumnWidth,
    required this.showChat,
  });
  final int slot;
  final String label;
  final double permissionColumnWidth;
  final bool showChat;

  @override
  Widget build(BuildContext context) => Row(
    key: ValueKey('guardian-journey-pending-row-$slot'),
    children: [
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

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
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

// WaliLinkedPerson has no gender field. Copy follows only an explicit gendered
// relationship code in that record; a name or unrecorded/neutral relationship
// never implies pronouns. This does not validate or change relationship policy.
({String subject, String object, bool plural}) _guardianHistoryPronouns(
  WaliLinkedPerson person,
) => switch (person.relationship?.trim().toLowerCase()) {
  'father' ||
  'brother' ||
  'son' ||
  'grandfather' ||
  'uncle' ||
  'nephew' ||
  'father_in_law' ||
  'brother_in_law' => (subject: 'he', object: 'him', plural: false),
  'mother' ||
  'sister' ||
  'daughter' ||
  'grandmother' ||
  'aunt' ||
  'niece' ||
  'mother_in_law' ||
  'sister_in_law' => (subject: 'she', object: 'her', plural: false),
  _ => (subject: 'they', object: 'them', plural: true),
};

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
  bool _explanationOpen = false;

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

  Future<void> _showExplanation() async {
    if (!mounted ||
        !guardianLifetime.isCurrent ||
        _explanationOpen ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final lifetime = guardianLifetime;
    final person = widget.person;
    final pronouns = _guardianHistoryPronouns(person);
    final subject = pronouns.subject;
    final capitalizedSubject =
        '${subject[0].toUpperCase()}${subject.substring(1)}';
    _explanationOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => ZyraGuardianPreviewRouteBoundary(
          authority: lifetime,
          child: ZyraShadowScrollView(
            key: const ValueKey('guardian-history-consent-explanation-scroll'),
            child: SafeArea(
              top: false,
              child: ZyraFloatingSurface(
                radius: 20,
                child: Container(
                  key: const ValueKey('guardian-history-consent-explanation'),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  decoration: BoxDecoration(
                    color: ZyraColors.waliSheetBg,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: ZyraColors.surfaceBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ZyraColors.ink(0.22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Past Journey summaries',
                        style: ZyraText.heading(size: 20),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Right now ${person.firstName} only sees Journeys '
                        'from the day $subject ${pronouns.plural ? 'were' : 'was'} '
                        'linked onwards. Turn this on to also show '
                        '${pronouns.object} the ones before that.',
                        style: ZyraText.subtext(size: 12.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$capitalizedSubject ${pronouns.plural ? 'see' : 'sees'} '
                        'start date, end date and status — nothing else. Never '
                        'names, messages, answers, reasons, notes or safety information.',
                        style: ZyraText.subtext(
                          size: 12.5,
                          color: ZyraColors.ink(0.56),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      _explanationOpen = false;
    }
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
              IconButton(
                key: const ValueKey('guardian-history-consent-details-toggle'),
                tooltip: 'About sharing past Journey summaries',
                visualDensity: VisualDensity.compact,
                iconSize: 19,
                color: ZyraColors.ink(0.58),
                onPressed: ZyraTapFeedback.onTap(
                  context,
                  boundGuardianCallback(_showExplanation),
                ),
                icon: const Icon(Icons.info_outline_rounded),
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
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 20,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyraColors.surfaceFill,
        border: Border.all(color: ZyraColors.surfaceEmphasisBorder),
      ),
      child: Text(
        person.firstName.trim().isEmpty
            ? '?'
            : person.firstName.trim()[0].toUpperCase(),
        style: ZyraText.heading(size: size * 0.38),
      ),
    ),
  );
}

class _GuardianPageDots extends StatelessWidget {
  final int count;
  final int selected;

  const _GuardianPageDots({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Guardian ${selected + 1} of $count',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            key: ValueKey('guardian-page-dot-$index'),
            duration: const Duration(milliseconds: 180),
            width: index == selected ? 20 : 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: index == selected
                  ? ZyraColors.journeyGold
                  : ZyraColors.ink(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
      ],
    ),
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
