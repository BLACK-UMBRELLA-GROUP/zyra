// LOCK 19: Founder preview Guardian cards.
import 'package:flutter/material.dart';
import '../data/zyra_guardian_capacity.dart';
import '../services/zyra_account_state.dart';
import '../state/app_state.dart' show ZyraPlan;
import '../services/zyra_wali_link_service.dart' show WaliLinkedPerson;
import '../screens/wali/seeker_guardian_designs.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_guardian_add_card.dart';
import 'zyra_one_journey_monogram_presentation.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_profiles_components.dart';
import '../widgets/zyra_tab_title.dart';
import '../widgets/zyra_tap_feedback.dart';
import '../widgets/zyra_swipe_track.dart';
import 'zyra_conversation_unread_badge.dart';
import 'zyra_one_journey_guardian_family_sheet.dart';
import 'zyra_guardian_family_preview.dart';
import '../theme/zyra_preview_spacing.dart';

class ZyraGuardianCardPerson {
  const ZyraGuardianCardPerson({
    required this.person,
    required this.membership,
    required this.history,
    this.familyPlace = false,
  });
  final WaliLinkedPerson person;
  final String membership;
  final bool history, familyPlace;
  bool get basic => membership == 'Guardian Basic';
}

class ZyraGuardianCardJourney {
  const ZyraGuardianCardJourney({
    required this.id,
    required this.attempt,
    required this.name,
    required this.stage,
    required this.stageNumber,
    required this.view,
    required this.chat,
    required this.canChange,
    this.chatCanChange,
    this.photo,
  });
  final String id, name, stage;
  final int? attempt;
  final int stageNumber;
  final String? photo;
  final bool view, chat, canChange;
  final bool? chatCanChange;
}

typedef ZyraGuardianCardPermission =
    void Function(
      String guardianId,
      String journeyId, {
      bool? view,
      bool? chat,
    });

class ZyraOneJourneyGuardianCards extends StatefulWidget {
  const ZyraOneJourneyGuardianCards({
    super.key,
    required this.people,
    required this.journeysFor,
    required this.capacity,
    required this.basic,
    required this.canAct,
    this.canActInOwnedMenu,
    this.onMenuRouteChanged,
    required this.interactionEpoch,
    required this.contextIdentity,
    required this.renderIdentity,
    required this.onPage,
    required this.onHistory,
    required this.onPermission,
    required this.makeMain,
    required this.clearMain,
    required this.remove,
    required this.onAdd,
    this.onUpgrade,
    required this.onCircle,
    required this.unread,
    this.onResume,
    this.initialPage = 0,
    this.familyState = ZyraGuardianFamilyState.noFamily,
    this.familyInvited,
    this.onFamilyInvite,
    this.onFamilyCancel,
    this.previewInvitationNow,
    this.previewInvitationCancelled = false,
    this.onCancelPreviewInvitation,
  });
  final List<ZyraGuardianCardPerson> people;
  final List<ZyraGuardianCardJourney> Function(String id) journeysFor;
  final int capacity, initialPage, unread;
  final bool basic;
  final bool Function() canAct;
  final bool Function()? canActInOwnedMenu;
  final void Function(ModalRoute<dynamic> route, {required bool open})?
  onMenuRouteChanged;
  final Object Function() interactionEpoch;
  final Object contextIdentity, renderIdentity;
  final ValueChanged<int> onPage;
  final void Function(String id, bool enabled) onHistory;
  final ZyraGuardianCardPermission onPermission;
  final GuardianMakeMainAction makeMain;
  final GuardianClearMainAction clearMain;
  final GuardianRemoveAction remove;
  final VoidCallback onAdd, onCircle;
  final VoidCallback? onResume, onUpgrade;
  final ZyraGuardianFamilyState familyState;
  final bool Function(String)? familyInvited;
  final ValueChanged<String>? onFamilyInvite, onFamilyCancel;
  static final previewInvitationSent = DateTime.utc(2026, 11, 2);
  static final previewInvitationExpiry = previewInvitationSent.add(
    ZyraGuardianFamilyInvite.lifetime,
  );
  final DateTime? previewInvitationNow;
  final bool previewInvitationCancelled;
  final VoidCallback? onCancelPreviewInvitation;

  @override
  State<ZyraOneJourneyGuardianCards> createState() => _GuardianCardsState();
}

class _GuardianCardsState extends State<ZyraOneJourneyGuardianCards> {
  int _index = 0, _render = 0;
  final _swipe = ZyraSwipeController();
  bool _returningFromMenu = false;
  final _invites = <String>{};
  Object? _sheetLease;
  ModalRoute<dynamic>? _sheetRoute;
  ModalRoute<bool>? _confirmRoute;
  bool Function()? _menuEpochCurrent;
  final _owner = (ZyraAccountState.userId, ZyraAccountState.generation);

  List<ZyraGuardianCardPerson> get _people => _orderedPeople(widget);

  List<ZyraGuardianCardPerson> _orderedPeople(
    ZyraOneJourneyGuardianCards source,
  ) {
    final all = <String, ZyraGuardianCardPerson>{
      for (final person in source.people) person.person.id: person,
    }.values.toList();
    all.sort((a, b) {
      if (a.person.isMain != b.person.isMain) return a.person.isMain ? -1 : 1;
      return (a.person.linkedAt ?? DateTime(2100)).compareTo(
        b.person.linkedAt ?? DateTime(2100),
      );
    });
    return all;
  }

  bool get _canShowInvitation =>
      !widget.basic && _people.isNotEmpty && !widget.previewInvitationCancelled;
  int get _guardianCount => _people.length + (_canShowInvitation ? 1 : 0);
  int get _length => _guardianCount + 1;
  ZyraGuardianCardPerson? get _person =>
      _index < _people.length ? _people[_index] : null;
  bool get _invitedCard => _canShowInvitation && _index == _people.length;
  String get _target =>
      _person?.person.id ?? (_invitedCard ? 'preview-invited-omar' : 'add');

  @override
  void initState() {
    super.initState();
    _index = widget.initialPage.clamp(0, _length - 1);
  }

  @override
  void didUpdateWidget(covariant ZyraOneJourneyGuardianCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPeople = _orderedPeople(oldWidget);
    final oldPerson = _index < oldPeople.length ? oldPeople[_index] : null;
    final changedRender = oldWidget.renderIdentity != widget.renderIdentity;
    if (changedRender || oldWidget.canAct != widget.canAct) _render++;
    final hasAuthority = _menuEpochCurrent == null
        ? widget.canAct
        : widget.canActInOwnedMenu ?? widget.canAct;
    final changedContext =
        oldWidget.contextIdentity != widget.contextIdentity || !hasAuthority();
    final selectedHere =
        oldWidget.initialPage != widget.initialPage &&
        widget.initialPage == _index;
    if (oldWidget.initialPage != widget.initialPage) {
      _index = widget.initialPage;
    }
    _index = _index.clamp(0, _length - 1);
    final changedCard =
        oldPerson?.person.id != _person?.person.id ||
        oldPerson?.person.isMain != _person?.person.isMain ||
        oldWidget.basic != widget.basic ||
        oldWidget.capacity != widget.capacity;
    if (changedContext || changedCard || (changedRender && !selectedHere)) {
      _resetMotion();
      _render++;
    }
    final guardianChanged =
        changedContext || changedCard || (changedRender && _sheetLease != null);
    if (guardianChanged) _invites.clear();
    if (guardianChanged || _menuEpochCurrent?.call() == false) {
      _dismissOwnedSheet();
    }
  }

  void _dismissOwnedSheet() {
    _sheetLease = null;
    _menuEpochCurrent = null;
    final route = _sheetRoute;
    _sheetRoute = null;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
  }

  @override
  void dispose() {
    _dismissOwnedSheet();
    final confirmRoute = _confirmRoute;
    _confirmRoute = null;
    if (confirmRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (confirmRoute.isActive) {
          confirmRoute.navigator?.removeRoute(confirmRoute, false);
        }
      });
    }
    super.dispose();
  }

  bool _current(int render, Object epoch, String target) =>
      mounted &&
      _owner == (ZyraAccountState.userId, ZyraAccountState.generation) &&
      widget.canAct() &&
      render == _render &&
      epoch == widget.interactionEpoch() &&
      _target == target &&
      _sheetLease == null &&
      !_returningFromMenu &&
      ModalRoute.of(context)?.isCurrent == true;

  bool Function() _lease([String? expectedTarget]) {
    final render = _render, epoch = widget.interactionEpoch();
    final target = expectedTarget ?? _target;
    final authority = widget.canAct;
    var revoked = target != _target;
    return () {
      if (revoked) return false;
      if (!authority() || !_current(render, epoch, target)) {
        revoked = true;
        return false;
      }
      return true;
    };
  }

  VoidCallback _action(VoidCallback action, {String? expectedTarget}) {
    final current = _lease(expectedTarget);
    return ZyraTapFeedback.onTap(
      context,
      action,
      canAct: () => !_swipe.isMoving && current(),
    )!;
  }

  void _select(int next) {
    setState(() {
      _index = next;
      _render++;
    });
    widget.onPage(next);
  }

  void _resetMotion() => _swipe.cancel();

  Future<void> _openMenu() async {
    final route = ModalRoute.of(context);
    final person = _person?.person;
    if (person == null || route?.isCurrent != true || _sheetLease != null) {
      return;
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    final onMenuRouteChanged = widget.onMenuRouteChanged;
    final lease = Object();
    final authority = widget.canActInOwnedMenu ?? widget.canAct;
    final identity = widget.contextIdentity;
    final originRender = widget.renderIdentity;
    final basic = widget.basic;
    final capacity = widget.capacity;
    final epoch = widget.interactionEpoch;
    Object? sheetEpoch, confirmedEpoch;
    var confirmed = false;
    late final ModalBottomSheetRoute<ZyraGuardianManagementAction> menuRoute;
    _resetMotion();
    setState(() {
      _sheetLease = lease;
      _render++;
    });

    bool sameGuardian() =>
        mounted &&
        _owner == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        identity == widget.contextIdentity &&
        _target == person.id &&
        _person?.person.isMain == person.isMain &&
        widget.basic == basic &&
        widget.capacity == capacity;

    bool ownsMenu() =>
        identical(_sheetLease, lease) &&
        sameGuardian() &&
        originRender == widget.renderIdentity &&
        authority() &&
        (widget.canActInOwnedMenu ?? widget.canAct)();

    bool current() =>
        ownsMenu() &&
        sheetEpoch == widget.interactionEpoch() &&
        menuRoute.isCurrent;

    // Ignore this route's own push and pop. A route pushed over this
    // still-active sheet invalidates the actions and dismisses only this sheet.
    _menuEpochCurrent = () =>
        sheetEpoch == null ||
        !menuRoute.isActive ||
        sheetEpoch == widget.interactionEpoch();

    final localizations = MaterialLocalizations.of(context);
    menuRoute = ModalBottomSheetRoute<ZyraGuardianManagementAction>(
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      showDragHandle: false,
      barrierLabel: 'Dismiss Guardian actions',
      barrierOnTapHint: localizations.scrimOnTapHint(
        localizations.bottomSheetLabel,
      ),
      modalBarrierColor: const Color(0xFF1E1610).withValues(alpha: .38),
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        bool choose(ZyraGuardianManagementAction action) {
          if (!current() || confirmedEpoch != null) return false;
          Navigator.of(sheetContext).pop(action);
          confirmedEpoch = epoch();
          return true;
        }

        const corners = BorderRadius.vertical(top: Radius.circular(26));
        final sheet = DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: corners,
            boxShadow: [
              BoxShadow(
                color: Color(0x241E1610),
                blurRadius: 24,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Material(
            key: const ValueKey('guardian-card-menu-sheet'),
            color: const Color(0xFFF7F2EA),
            borderRadius: corners,
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 14),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 11, 18, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ZyraColors.ink(.20),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${person.firstName} · ${person.isMain ? 'Main Guardian' : 'Additional Guardian'}',
                      textAlign: TextAlign.center,
                      style: ZyraText.body(
                        size: 12,
                        color: ZyraColors.ink(.55),
                      ),
                    ),
                    const SizedBox(height: 6),
                    zyraGuardianCardManageActions(
                      person: person,
                      otherGuardians: widget.people
                          .map((p) => p.person)
                          .where((p) => p.id != person.id)
                          .toList(),
                      canAct: current,
                      onSelect: choose,
                      closeMenu: () {
                        if (current()) Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final feedback = sheetContext
            .dependOnInheritedWidgetOfExactType<ZyraTapFeedback>();
        return feedback == null
            ? sheet
            : ZyraTapFeedback(
                level: feedback.level,
                canAct: current,
                child: sheet,
              );
      },
    );
    _sheetRoute = menuRoute;
    ZyraGuardianManagementAction? selected;
    try {
      onMenuRouteChanged?.call(menuRoute, open: true);
      final result = navigator.push(menuRoute);
      sheetEpoch = epoch();
      selected = await result;
    } finally {
      onMenuRouteChanged?.call(menuRoute, open: false);
      if (mounted && identical(_sheetLease, lease)) {
        confirmed =
            selected != null &&
            confirmedEpoch == widget.interactionEpoch() &&
            route?.isCurrent == true &&
            ownsMenu();
        setState(() {
          _returningFromMenu = confirmed;
          _menuEpochCurrent = null;
          _sheetLease = null;
          _sheetRoute = null;
          _render++;
        });
        widget.onResume?.call();
      }
    }
    if (!confirmed || selected == null) return;

    final resumeEpoch = widget.interactionEpoch();
    try {
      // The shell binds its actions to its route epoch. After this menu's
      // confirmed pop, allow its requested rebuild to bind the new handlers.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted ||
          !sameGuardian() ||
          !widget.canAct() ||
          route?.isCurrent != true ||
          resumeEpoch != widget.interactionEpoch()) {
        return;
      }
      ModalRoute<bool>? confirmRoute;
      var confirmEpoch = widget.interactionEpoch();
      final confirmRender = widget.renderIdentity;
      try {
        final pending = showZyraGuardianManagementConfirm(
          context: context,
          action: selected,
          person: person,
          onOpening: (opened) {
            _confirmRoute = confirmRoute = opened;
            onMenuRouteChanged?.call(opened, open: true);
          },
          canConfirm: () =>
              sameGuardian() &&
              confirmRender == widget.renderIdentity &&
              confirmEpoch == widget.interactionEpoch() &&
              (widget.canActInOwnedMenu ?? widget.canAct)(),
          onConfirmedPop: () => confirmEpoch = widget.interactionEpoch(),
        );
        confirmEpoch = widget.interactionEpoch();
        if (await pending != true) return;
      } finally {
        if (confirmRoute case final opened?) {
          if (identical(_confirmRoute, opened)) _confirmRoute = null;
          onMenuRouteChanged?.call(opened, open: false);
        }
      }
      if (!sameGuardian() ||
          confirmRender != widget.renderIdentity ||
          route?.isCurrent != true ||
          confirmEpoch != widget.interactionEpoch()) {
        return;
      }
      widget.onResume?.call();
      confirmEpoch = widget.interactionEpoch();
      await WidgetsBinding.instance.endOfFrame;
      if (!sameGuardian() ||
          !widget.canAct() ||
          route?.isCurrent != true ||
          confirmEpoch != widget.interactionEpoch()) {
        return;
      }
      final error = switch (selected) {
        ZyraGuardianManagementAction.makeMain =>
          await widget.makeMain(person.id)
              ? null
              : "That didn't go through. Please try again.",
        ZyraGuardianManagementAction.clearMain =>
          await widget.clearMain(person.id)
              ? null
              : "That didn't go through. Please try again.",
        ZyraGuardianManagementAction.remove => await widget.remove(person.id),
      };
      if (error != null &&
          mounted &&
          sameGuardian() &&
          widget.canAct() &&
          route?.isCurrent == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    } finally {
      if (mounted) setState(() => _returningFromMenu = false);
    }
  }

  Future<void> _family(ZyraGuardianCardPerson person) async {
    if (!person.basic || _sheetLease != null) return;
    final lease = Object(), target = person.person.id;
    final ownerContext = widget.contextIdentity;
    final authority = widget.canAct;
    final originRender = widget.renderIdentity;
    final baseEpoch = widget.interactionEpoch();
    Object? sheetEpoch;
    BuildContext? ownedContext;
    _sheetLease = lease;
    setState(() {
      _render++;
    });
    bool current() =>
        mounted &&
        identical(_sheetLease, lease) &&
        _owner == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        ownerContext == widget.contextIdentity &&
        originRender == widget.renderIdentity &&
        authority() &&
        widget.canAct() &&
        _target == target &&
        sheetEpoch == widget.interactionEpoch() &&
        ownedContext?.mounted == true &&
        ModalRoute.of(ownedContext!)?.isCurrent == true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFFF7F2EA),
        barrierColor: const Color(0xFF1E1610).withValues(alpha: .38),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder: (sheetContext) {
          ownedContext = sheetContext;
          _sheetRoute = ModalRoute.of(sheetContext);
          sheetEpoch ??= widget.interactionEpoch();
          return ZyraGuardianFamilySheet(
            guardianName: person.person.firstName,
            canAct: current,
            invited:
                widget.familyInvited?.call(target) ?? _invites.contains(target),
            familyState: widget.familyState,
            onInvite: () {
              if (current()) {
                setState(() {
                  _invites.add(target);
                  _render++;
                });
                widget.onFamilyInvite?.call(target);
              }
            },
            onCancelInvite: () {
              if (current()) {
                setState(() {
                  _invites.remove(target);
                  _render++;
                });
                widget.onFamilyCancel?.call(target);
              }
            },
            onClose: () {
              if (current()) Navigator.of(sheetContext).pop();
            },
          );
        },
      );
    } finally {
      if (mounted && identical(_sheetLease, lease)) {
        setState(() {
          _sheetLease = null;
          _sheetRoute = null;
          _render++;
        });
        // No permission is replayed after the owned route has closed.
        if (baseEpoch == widget.interactionEpoch()) _resetMotion();
        widget.onResume?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scale = textScaler.scale(1);
    final largerText = textScaler.scale(14) > 14;
    final faceLease = _lease();
    final people = _people;
    final basicCapacity = widget.basic
        ? ZyraGuardianCapacity.fromCount(
            plan: ZyraPlan.basic,
            linkedGuardianCount: people.length,
            linkedBasicGuardianCount: people
                .where((person) => person.basic)
                .length,
          )
        : null;
    final upgrade = widget.onUpgrade;
    final bottom = ZyraNavBarMetrics.contentBottomClearance(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ZyraPreviewSpacing.pageMargin,
          16,
          ZyraPreviewSpacing.pageMargin,
          bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              key: const ValueKey('guardian-manager-title-block'),
              builder: (context, box) {
                const title = ZyraTabTitle(
                  'Guardian',
                  textKey: ValueKey('guardian-manager-title'),
                );
                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ZyraConversationUnreadBadge(
                      unreadCount: widget.unread,
                      backgroundColor: ZyraColors.brandGradient.colors.first,
                      child: _round(
                        'guardian-family-messages-top',
                        Icons.forum_outlined,
                        widget.onCircle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _round('guardian-add-top', Icons.add, widget.onAdd),
                  ],
                );
                if (box.maxWidth < 320 && scale > 1.3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: title),
                    actions,
                  ],
                );
              },
            ),
            if (_guardianCount > 0) ...[
              const SizedBox(height: ZyraPreviewSpacing.titleToDots),
              ZyraProfilesDots(
                count: _guardianCount,
                index: _index < _guardianCount ? _index : -1,
                dotKey: (i) => ValueKey('guardian-card-dot-$i'),
                targetKey: (i) => ValueKey('guardian-card-dot-target-$i'),
                itemLabel: (i) =>
                    i < people.length ? people[i].person.firstName : 'Omar',
                canAct: faceLease,
                canSelect: () => !_swipe.isMoving,
                onSelected: _swipe.animateTo,
                exposeSemanticAction: true,
              ),
              // The visible dot ends 9 pt before its 24 pt tap area.
              const SizedBox(height: 3),
            ] else
              const SizedBox(height: 8),
            Expanded(
              child: ZyraSwipeTrack(
                controller: _swipe,
                index: _index,
                itemCount: _length,
                canAct: faceLease,
                onSettled: _select,
                onDragSettled: ZyraTapFeedback.onTap(
                  context,
                  () {},
                  canAct: faceLease,
                ),
                itemBuilder: (context, index) {
                  final person = index < people.length ? people[index] : null;
                  final isAdd = index == _length - 1;
                  final target =
                      person?.person.id ??
                      (isAdd ? 'add' : 'preview-invited-omar');
                  return Stack(
                    key: ValueKey('guardian-card-$target'),
                    fit: StackFit.expand,
                    children: [
                      if (isAdd)
                        ZyraGuardianAddCard(
                          basicCapacity: basicCapacity,
                          onAdd: _action(widget.onAdd, expectedTarget: target),
                          onUpgrade: widget.basic && upgrade != null
                              ? _action(upgrade, expectedTarget: target)
                              : null,
                          allowContentScroll: largerText,
                        )
                      else
                        _card(person, target),
                      if (!isAdd && index > 0)
                        _edge(
                          left: true,
                          onTap: _action(
                            () => _swipe.animateTo(index - 1),
                            expectedTarget: target,
                          ),
                        ),
                      if (index + 1 < _guardianCount)
                        _edge(
                          left: false,
                          onTap: _action(
                            () => _swipe.animateTo(index + 1),
                            expectedTarget: target,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _edge({required bool left, required VoidCallback onTap}) => Positioned(
    top: 0,
    bottom: 0,
    left: left ? 0 : null,
    right: left ? null : 0,
    width: 26,
    child: GestureDetector(
      key: ValueKey(
        left ? 'guardian-card-edge-left' : 'guardian-card-edge-right',
      ),
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
    ),
  );

  Widget _card(ZyraGuardianCardPerson? person, String target) =>
      ZyraFloatingSurface(
        radius: 22,
        child: Container(
          decoration: BoxDecoration(
            color: ZyraColors.ivoryTop,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: person?.person.isMain == true
                  ? const Color(0xFFE8C98A).withValues(alpha: .6)
                  : ZyraColors.surfaceBorder,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final useNaturalHeight =
                  person == null &&
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              // At compact widths the wider photo gap still leaves enough
              // room for the full stage labels without scrolling the card.
              final compact = box.maxWidth < 360;
              final horizontalInset = person != null && compact ? 25.0 : 29.0;
              final content = Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: 12,
                ),
                child: person == null
                    ? _invited(expandDetails: !useNaturalHeight)
                    : _linked(
                        person,
                        box.maxWidth - 2 * horizontalInset,
                        compact: compact,
                      ),
              );
              return SingleChildScrollView(
                key: ValueKey('guardian-card-content-$target'),
                primary: false,
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  // At larger text the invitation uses the laid-out height,
                  // since intrinsic measurement can undercount wrapped lines.
                  child: useNaturalHeight
                      ? content
                      : IntrinsicHeight(child: content),
                ),
              );
            },
          ),
        ),
      );

  Widget _round(String key, IconData icon, VoidCallback callback) =>
      ZyraFloatingSurface(
        circle: true,
        child: SizedBox.square(
          dimension: 38,
          child: Material(
            color: const Color(0xFFFBF7F0),
            shape: const CircleBorder(),
            child: IconButton(
              key: ValueKey(key),
              onPressed: _action(callback),
              icon: Icon(icon, size: 20, color: ZyraColors.foreground),
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      );

  Widget _top(
    String name,
    String role, {
    bool main = false,
    bool invited = false,
    required bool guardianOne,
    String? guardianId,
  }) => Stack(
    children: [
      Padding(
        padding: EdgeInsets.only(right: invited ? 0 : 44),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Opacity(
              opacity: invited ? .55 : 1,
              child: ZyraGoldRingMonogram(
                name: name,
                guardianOne: guardianOne,
                size: 60,
                fontSize: 28,
                textScaler: TextScaler.noScaling,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: ZyraText.heading(
                      size: 27,
                    ).copyWith(fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: ZyraText.body(
                      size: 11,
                      color: main ? ZyraColors.goldText : ZyraColors.ink(.55),
                    ).copyWith(letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (!invited)
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            key: const ValueKey('guardian-card-menu'),
            tooltip: 'Guardian actions',
            icon: const Icon(Icons.more_horiz, size: 22),
            onPressed: _action(_openMenu, expectedTarget: guardianId),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
        ),
    ],
  );

  Widget _detail(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: ZyraColors.ink(.10))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ZyraText.body(size: 12, color: ZyraColors.ink(.55)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: ZyraText.body(size: 12),
            ),
          ),
        ),
      ],
    ),
  );

  String _date(DateTime? date, {bool short = false}) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString();
    final month = months[date.month - 1];
    return short ? '$day $month' : '${day.padLeft(2, '0')} $month ${date.year}';
  }

  Widget _linked(
    ZyraGuardianCardPerson person,
    double width, {
    required bool compact,
  }) {
    final guardian = person.person;
    final rows = widget.journeysFor(guardian.id).take(widget.capacity).toList();
    final textScaler = MediaQuery.textScalerOf(context);
    final stackChips = width < 245 || textScaler.scale(12) > 16;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _top(
          guardian.firstName,
          guardian.isMain ? 'MAIN GUARDIAN' : 'ADDITIONAL GUARDIAN',
          main: guardian.isMain,
          guardianId: guardian.id,
          guardianOne:
              person.familyPlace || person.membership == 'Guardian One',
        ),
        const SizedBox(height: 12),
        _detail('Relationship', guardian.relationshipLabel ?? 'Guardian'),
        _detail(
          'Membership',
          person.familyPlace
              ? 'Guardian One · Family place'
              : person.membership,
        ),
        _detail('Linked', _date(guardian.linkedAt)),
        const SizedBox(height: 8),
        Text(
          'JOURNEY ACCESS',
          key: const ValueKey('guardian-card-journey-label'),
          style: ZyraText.body(
            size: 11.5,
            color: ZyraColors.goldText,
          ).copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: ZyraPreviewSpacing.labelToCard),
        for (var i = 0; i < widget.capacity; i++)
          Expanded(
            child: i < rows.length
                ? _journey(
                    person,
                    rows[i],
                    stackChips: stackChips,
                    compact: compact,
                  )
                : _freePlace(guardian.firstName, i),
          ),
        _history(person),
      ],
    );
  }

  Widget _history(ZyraGuardianCardPerson person) {
    final id = person.person.id;
    final action = _action(
      () => widget.onHistory(id, !person.history),
      expectedTarget: id,
    );
    return Container(
      key: const ValueKey('guardian-card-summary-row'),
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ZyraColors.ink(.10))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Past Journey summaries',
              style: ZyraText.body(size: 14, color: ZyraColors.ink(.55)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: action,
            excludeFromSemantics: true,
            child: Semantics(
              key: ValueKey('guardian-card-history-$id'),
              label: 'Past Journey summaries',
              toggled: person.history,
              onTap: action,
              child: Container(
                width: 44,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: person.history
                      ? ZyraColors.journeyGold.withValues(alpha: .25)
                      : ZyraColors.ink(.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ZyraColors.ink(.08)),
                ),
                child: Align(
                  alignment: person.history
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: person.history
                          ? ZyraColors.journeyGold
                          : ZyraColors.ink(.55),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _journey(
    ZyraGuardianCardPerson person,
    ZyraGuardianCardJourney journey, {
    required bool stackChips,
    required bool compact,
  }) {
    final firstName = journey.name;
    final identity = Row(
      children: [
        if (journey.photo case final photo?)
          ClipOval(
            child: SizedBox.square(
              dimension: 42,
              child: ZyraProfileImage(photo, fit: BoxFit.cover),
            ),
          )
        else
          ZyraGoldRingMonogram(
            name: firstName,
            size: 42,
            fontSize: 16,
            textScaler: TextScaler.noScaling,
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(firstName, style: ZyraText.body(size: 15)),
              Text(
                journey.stage,
                style: ZyraText.body(
                  size: 11,
                  color: ZyraColors.ink(.55),
                ).copyWith(height: 1.2),
              ),
              const SizedBox(height: 3),
              LinearProgressIndicator(
                value: journey.stageNumber / 8,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
                color: ZyraColors.journeyGold,
                backgroundColor: ZyraColors.ink(.10),
              ),
            ],
          ),
        ),
      ],
    );
    final chips = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _permission(person, journey, chat: false),
        const SizedBox(width: 4),
        _permission(person, journey, chat: true),
      ],
    );
    return _accessRow(
      key: ValueKey('guardian-card-tile-${journey.id}'),
      child: stackChips
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [identity, const SizedBox(height: 4), chips],
            )
          : Row(
              children: [
                Expanded(child: identity),
                SizedBox(width: compact ? 2 : 4),
                chips,
              ],
            ),
    );
  }

  Widget _freePlace(String name, int index) => _accessRow(
    key: ValueKey('guardian-card-free-place-$index'),
    child: Row(
      children: [
        CustomPaint(
          foregroundPainter: ZyraGuardianDashedBorder(
            20,
            ZyraColors.journeyGold,
          ),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(Icons.add, size: 18, color: ZyraColors.journeyGold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Free Journey place', style: ZyraText.body(size: 15)),
              Text(
                "$name's access is set when a Journey begins",
                style: ZyraText.body(size: 11, color: ZyraColors.ink(.55)),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _accessRow({required Key key, required Widget child}) => Container(
    key: key,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(vertical: 3),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: ZyraColors.ink(.10))),
    ),
    child: child,
  );

  Widget _permission(
    ZyraGuardianCardPerson person,
    ZyraGuardianCardJourney journey, {
    required bool chat,
  }) {
    final locked = chat && person.basic;
    final invited =
        locked &&
        (widget.familyInvited?.call(person.person.id) ??
            _invites.contains(person.person.id));
    final enabled = chat ? journey.chat : journey.view;
    final label = chat ? (invited ? 'Invited' : 'Chat') : 'View';
    final canChange =
        locked ||
        ((chat
                ? journey.chatCanChange ?? journey.canChange
                : journey.canChange) &&
            (!chat || journey.view));
    final action = canChange
        ? _action(
            () => locked
                ? _family(person)
                : widget.onPermission(
                    person.person.id,
                    journey.id,
                    view: chat ? null : !journey.view,
                    chat: chat ? !journey.chat : null,
                  ),
            expectedTarget: person.person.id,
          )
        : null;
    return Semantics(
      key: ValueKey(
        'guardian-card-${chat ? 'chat' : 'view'}-${person.person.id}-${journey.id}',
      ),
      label: label,
      button: locked,
      toggled: locked ? null : enabled,
      enabled: canChange,
      onTap: action,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: action ?? () {},
          child: CustomPaint(
            foregroundPainter: locked
                ? ZyraGuardianDashedBorder(20, ZyraColors.ink(.12))
                : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 28),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: enabled
                    ? ZyraColors.journeyGold.withValues(alpha: .12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: locked
                    ? null
                    : Border.all(
                        color: enabled
                            ? ZyraColors.journeyGold
                            : ZyraColors.ink(.08),
                      ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locked || enabled) ...[
                    Icon(
                      locked ? Icons.lock_outline : Icons.check,
                      size: 12,
                      color: locked
                          ? ZyraColors.ink(.5)
                          : ZyraColors.journeyGold,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    label,
                    style: ZyraText.body(
                      size: 11,
                      color: locked || !enabled
                          ? ZyraColors.ink(.55)
                          : const Color(0xFF845F24),
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

  Widget _invited({required bool expandDetails}) {
    final sent = ZyraOneJourneyGuardianCards.previewInvitationSent;
    final expiry = ZyraOneJourneyGuardianCards.previewInvitationExpiry;
    final expired = !(widget.previewInvitationNow ?? sent).isBefore(expiry);
    final sentOn = _date(sent, short: true);
    final expiresOn = _date(expiry, short: true);
    final cancel = widget.onCancelPreviewInvitation;
    final muted = ZyraColors.foregroundMuted;
    final details = CustomPaint(
      foregroundPainter: ZyraGuardianDashedBorder(
        16,
        ZyraColors.journeyGold.withValues(alpha: .3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: expired ? 24 : 34,
              height: expired ? 24 : 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: expired
                    ? Border.all(color: ZyraColors.surfaceBorder)
                    : null,
              ),
              child: expired
                  ? Center(
                      child: Text(
                        '!',
                        style: ZyraText.body(size: 15, color: muted),
                      ),
                    )
                  : CustomPaint(
                      foregroundPainter: ZyraGuardianDashedBorder(
                        17,
                        ZyraColors.journeyGold.withValues(alpha: .55),
                      ),
                      child: Icon(
                        Icons.mail_outline,
                        size: 17,
                        color: ZyraColors.goldText,
                      ),
                    ),
            ),
            const SizedBox(height: 9),
            Text(
              expired
                  ? 'The invitation has expired'
                  : 'Waiting for Omar to accept',
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: 14,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Text(
                expired
                    ? "Omar didn't accept within 14 days (ended $expiresOn)."
                    : 'Invitation sent $sentOn. Omar has until $expiresOn '
                          'to accept in their app. Access starts once they accept.',
                textAlign: TextAlign.center,
                style: ZyraText.body(
                  size: 12.5,
                  color: muted,
                ).copyWith(height: 1.45),
              ),
            ),
            if (!expired && cancel != null) ...[
              const SizedBox(height: 10),
              TextButton(
                key: const ValueKey('guardian-card-cancel-invitation'),
                onPressed: _action(
                  cancel,
                  expectedTarget: 'preview-invited-omar',
                ),
                child: Text(
                  'Cancel invitation',
                  style: ZyraText.body(size: 13, color: muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _top(
          'Omar',
          expired ? 'INVITATION EXPIRED' : 'INVITATION SENT',
          invited: true,
          guardianOne: false,
        ),
        const SizedBox(height: 12),
        _detail('Relationship', 'Brother'),
        _detail('Membership', 'Not joined yet'),
        _detail('Status', expired ? 'Expired $expiresOn' : 'Waiting for Omar'),
        const SizedBox(height: 12),
        if (expandDetails) Expanded(child: details) else details,
      ],
    );
  }
}
