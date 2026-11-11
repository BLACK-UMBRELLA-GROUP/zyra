// LOCK19 V2: Founder-only Guardian cards. No live transport or entitlement grant.
import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;
import 'package:flutter/material.dart';
import '../widgets/zyra_profiles_components.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import '../services/zyra_account_state.dart';
import '../services/zyra_wali_link_service.dart' show WaliLinkedPerson;
import '../screens/wali/seeker_guardian_designs.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_guardian_add_card.dart';
import 'zyra_one_journey_monogram_presentation.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_conversation_unread_badge.dart';
import 'zyra_one_journey_guardian_family_sheet.dart';

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
    required this.view,
    required this.chat,
    required this.canChange,
    this.chatCanChange,
    this.photo,
  });
  final String id, name, stage;
  final int? attempt;
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
    required this.onCircle,
    required this.unread,
    this.onResume,
    this.initialPage = 0,
    this.familyState = ZyraGuardianFamilyState.noFamily,
    this.familyInvited,
    this.onFamilyInvite,
    this.onFamilyCancel,
  });
  final List<ZyraGuardianCardPerson> people;
  final List<ZyraGuardianCardJourney> Function(String id) journeysFor;
  final int capacity, initialPage, unread;
  final bool basic;
  final bool Function() canAct;
  final Object Function() interactionEpoch;
  final Object contextIdentity, renderIdentity;
  final ValueChanged<int> onPage;
  final void Function(String id, bool enabled) onHistory;
  final ZyraGuardianCardPermission onPermission;
  final GuardianMakeMainAction makeMain;
  final GuardianClearMainAction clearMain;
  final GuardianRemoveAction remove;
  final VoidCallback onAdd, onCircle;
  final VoidCallback? onResume;
  final ZyraGuardianFamilyState familyState;
  final bool Function(String)? familyInvited;
  final ValueChanged<String>? onFamilyInvite, onFamilyCancel;

  @override
  State<ZyraOneJourneyGuardianCards> createState() => _GuardianCardsState();
}

class _GuardianCardsState extends State<ZyraOneJourneyGuardianCards> {
  int _index = 0, _render = 0;
  bool _access = false;
  double _drag = 0;
  bool Function()? _dragLease;
  final _invites = <String>{};
  Object? _sheetLease;
  ModalRoute<dynamic>? _sheetRoute;
  final _owner = (ZyraAccountState.userId, ZyraAccountState.generation);

  List<ZyraGuardianCardPerson> get _people => _orderedPeople(widget);

  List<ZyraGuardianCardPerson> _orderedPeople(
    ZyraOneJourneyGuardianCards source,
  ) {
    final all = List<ZyraGuardianCardPerson>.of(source.people);
    all.sort((a, b) {
      if (a.person.isMain != b.person.isMain) return a.person.isMain ? -1 : 1;
      return (a.person.linkedAt ?? DateTime(2100)).compareTo(
        b.person.linkedAt ?? DateTime(2100),
      );
    });
    return source.basic ? all.take(1).toList() : all;
  }

  bool get _canShowInvitation => !widget.basic && _people.isNotEmpty;
  bool get _needsUpgrade => widget.basic && _people.isNotEmpty;
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
    if (oldWidget.renderIdentity != widget.renderIdentity) {
      _render++;
      if (_sheetLease != null) {
        _invites.clear();
        _dismissOwnedSheet();
      }
    } else if (oldWidget.canAct != widget.canAct) {
      _render++;
    }
    if (oldWidget.contextIdentity != widget.contextIdentity ||
        !widget.canAct()) {
      _invites.clear();
      _dismissOwnedSheet();
      _render++;
    }
    if (oldWidget.initialPage != widget.initialPage) {
      _index = widget.initialPage;
    }
    _index = _index.clamp(0, _length - 1);
    if (oldPerson?.person.id != _person?.person.id ||
        oldPerson?.person.isMain != _person?.person.isMain ||
        oldWidget.basic != widget.basic ||
        oldWidget.capacity != widget.capacity) {
      _access = false;
      _clearDrag();
      _render++;
    }
  }

  void _dismissOwnedSheet() {
    _sheetLease = null;
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
      ModalRoute.of(context)?.isCurrent == true;

  bool Function() _lease() {
    final render = _render, epoch = widget.interactionEpoch(), target = _target;
    final authority = widget.canAct;
    var revoked = false;
    return () {
      if (revoked) return false;
      if (!authority() || !_current(render, epoch, target)) {
        revoked = true;
        return false;
      }
      return true;
    };
  }

  VoidCallback _action(VoidCallback action) {
    final current = _lease();
    return ZyraTapFeedback.onTap(context, () {
      if (current()) action();
    }, canAct: current)!;
  }

  void _move(int next) {
    if (next < 0 || next >= _length || next == _index) return;
    setState(() {
      _index = next;
      _access = false;
      _clearDrag();
      _render++;
    });
    widget.onPage(next);
  }

  void _clearDrag() {
    _drag = 0;
    _dragLease = null;
  }

  void _showAccess(bool access) {
    if (_person == null || access == _access) return;
    setState(() {
      _access = access;
      _render++;
    });
  }

  void _selectGuardian(int index) {
    if (index == _index) {
      _showAccess(false);
    } else {
      _move(index);
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
        if (baseEpoch == widget.interactionEpoch()) _clearDrag();
        widget.onResume?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    final linked = person != null;
    final textScaler = MediaQuery.textScalerOf(context);
    final scale = textScaler.scale(1);
    final largerText = textScaler.scale(14) > 14;
    final target = _target;
    final faceLease = _lease();
    final people = _people;
    final bottom = ZyraNavBarMetrics.contentBottomClearance(context);
    final move = ZyraTapFeedback.onChanged<int>(
      context,
      _move,
      canAct: faceLease,
    )!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final title = Text(
                  'Guardian',
                  key: const ValueKey('guardian-manager-title'),
                  style: ZyraText.pageTitle(),
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
                if (box.maxWidth < 340 && scale > 1.3) {
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
                  children: [
                    Expanded(child: title),
                    actions,
                  ],
                );
              },
            ),
            if (_guardianCount > 0) ...[
              ZyraProfilesDots(
                count: _guardianCount,
                index: _index < _guardianCount ? _index : -1,
                dotKey: (i) => ValueKey('guardian-card-dot-$i'),
                targetKey: (i) => ValueKey('guardian-card-dot-target-$i'),
                itemLabel: (i) =>
                    i < people.length ? people[i].person.firstName : 'Omar',
                canAct: faceLease,
                onSelected: _selectGuardian,
                exposeSemanticAction: true,
              ),
              // The visible dot ends 9 pt before its 24 pt tap area.
              const SizedBox(height: 3),
            ] else
              const SizedBox(height: 8),
            Expanded(
              child: GestureDetector(
                key: ValueKey('guardian-card-$target'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragDown: (_) {
                  if (!faceLease()) return;
                  _drag = 0;
                  _dragLease = faceLease;
                },
                onHorizontalDragUpdate: (event) {
                  if (faceLease() && _dragLease?.call() == true) {
                    _drag += event.delta.dx;
                  }
                },
                onHorizontalDragCancel: () {
                  if (faceLease()) _clearDrag();
                },
                onHorizontalDragEnd: (_) {
                  final current = _dragLease?.call() == true;
                  final drag = _drag;
                  if (!faceLease()) return;
                  _clearDrag();
                  if (!current) return;
                  if (drag.abs() < kTouchSlop) return;
                  final next = _index + (drag < 0 ? 1 : -1);
                  if (next >= 0 && next < _length) move(next);
                },
                child: !linked && !_invitedCard
                    ? ZyraGuardianAddCard(
                        needsUpgrade: _needsUpgrade,
                        allowContentScroll: largerText,
                      )
                    : _card(person, largerText: largerText),
              ),
            ),
            const SizedBox(height: 12),
            if (linked)
              Semantics(
                role: SemanticsRole.tabBar,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _pill(
                          'Details',
                          'guardian-card-details',
                          () => _showAccess(false),
                          selected: !_access,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _pill(
                          'Journey access',
                          'guardian-card-access',
                          () => _showAccess(true),
                          selected: _access,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _pill(
                _invitedCard
                    ? 'Send invitation again'
                    : _needsUpgrade
                    ? 'View Seeker One'
                    : 'Add a Guardian',
                'guardian-card-center',
                widget.onAdd,
                invitation: _invitedCard,
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(ZyraGuardianCardPerson? person, {required bool largerText}) =>
      ZyraFloatingSurface(
        radius: 22,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3EDE3),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: person?.person.isMain == true
                  ? const Color(0xFFE8C98A).withValues(alpha: .6)
                  : ZyraColors.surfaceBorder,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final access = person != null && _access;
              final content = person == null
                  ? _invited()
                  : access
                  ? _back(person, box, largerText: largerText)
                  : _front(person);
              final legacyCompact =
                  MediaQuery.sizeOf(context).width < 375 && box.maxHeight < 390;
              if (!largerText && !legacyCompact) return content;
              // Preserve reading and action reachability on the older compact
              // viewport, where the existing default-size card does not fit.
              // The frame and bottom controls stay still at every text size.
              return SingleChildScrollView(
                key: ValueKey('guardian-card-content-$_target-$_access'),
                primary: false,
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: access ? IntrinsicHeight(child: content) : content,
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

  Widget _monogram(String name, {bool faded = false}) => Opacity(
    opacity: faded ? .55 : 1,
    child: ZyraGoldRingMonogram(
      name: name,
      size: 110 * math.min(1.5, MediaQuery.textScalerOf(context).scale(1)),
      fontSize: 52,
    ),
  );
  Widget _row(IconData icon, String text) => Container(
    constraints: const BoxConstraints(minHeight: 43),
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: ZyraColors.ink(.10))),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: ZyraColors.journeyGold),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: ZyraText.body(size: 14))),
      ],
    ),
  );
  String _date(DateTime? d) {
    if (d == null) return 'Linked';
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
    return 'Linked ${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  Widget _front(ZyraGuardianCardPerson person) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal:
          MediaQuery.sizeOf(context).width < 360 &&
              MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? 4
          : 34,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _monogram(person.person.firstName),
        const SizedBox(height: 18),
        Text(
          person.person.firstName,
          style: ZyraText.heading(
            size: 34,
          ).copyWith(fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 4),
        Text(
          person.person.isMain ? 'MAIN GUARDIAN' : 'ADDITIONAL GUARDIAN',
          style: ZyraText.body(
            size: 11.5,
            color: person.person.isMain
                ? ZyraColors.goldText
                : ZyraColors.ink(.55),
          ).copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 22),
        _row(
          Icons.person_outline,
          (person.person.relationshipLabel ?? 'Guardian'),
        ),
        _row(
          Icons.shield_outlined,
          person.familyPlace
              ? 'Guardian One · Family place'
              : person.membership,
        ),
        _row(Icons.check, _date(person.person.linkedAt)),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: ZyraColors.ink(.10)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Past Journey summaries',
                  style: ZyraText.body(size: 14, color: ZyraColors.ink(.55)),
                ),
              ),
              GestureDetector(
                onTap: _action(
                  () => widget.onHistory(person.person.id, !person.history),
                ),
                child: Semantics(
                  key: ValueKey('guardian-card-history-${person.person.id}'),
                  label: 'Past Journey summaries',
                  toggled: person.history,
                  onTap: _action(
                    () => widget.onHistory(person.person.id, !person.history),
                  ),
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
        ),
      ],
    ),
  );

  Widget _back(
    ZyraGuardianCardPerson person,
    BoxConstraints box, {
    required bool largerText,
  }) {
    final width = box.maxWidth - 36;
    final compact = !largerText && box.maxHeight < 460;
    final rows = widget
        .journeysFor(person.person.id)
        .take(widget.capacity)
        .toList();
    final target = _target;
    final current = _lease();
    return Padding(
      padding: EdgeInsets.fromLTRB(18, compact ? 12 : 20, 18, compact ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'JOURNEY ACCESS',
            style: ZyraText.body(
              size: 11.5,
              color: ZyraColors.goldText,
            ).copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.capacity; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Expanded(
              child: i < rows.length
                  ? _journey(person, rows[i], width - 2, compact: compact)
                  : CustomPaint(
                      foregroundPainter: ZyraGuardianDashedBorder(
                        16,
                        ZyraColors.ink(.08),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            "Free place · ${person.person.firstName}'s access is set when a Journey begins",
                            textAlign: TextAlign.center,
                            style: ZyraText.body(
                              size: 12,
                              color: ZyraColors.ink(.55),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
          const SizedBox(height: 12),
          zyraGuardianCardManageActions(
            person: person.person,
            stackActions:
                width < 320 && MediaQuery.textScalerOf(context).scale(1) > 1.3,
            otherGuardians: widget.people
                .map((p) => p.person)
                .where((p) => p.id != target)
                .toList(),
            canAct: current,
            makeMainGuardian: widget.makeMain,
            clearMainGuardian: widget.clearMain,
            removeGuardian: widget.remove,
          ),
        ],
      ),
    );
  }

  Widget _journey(
    ZyraGuardianCardPerson person,
    ZyraGuardianCardJourney journey,
    double width, {
    required bool compact,
  }) {
    final photoWidth = math.min(150.0, width * .34);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        key: ValueKey('guardian-card-tile-${journey.id}'),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE4DA),
          border: Border.all(color: ZyraColors.ink(.06)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (journey.photo != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: photoWidth,
                child: ZyraProfileImage(journey.photo!, fit: BoxFit.cover),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                photoWidth + 12,
                // A 98 pt compact tile still fits the wrapped stage, name and
                // original permission targets when the spare inset is removed.
                compact ? 0 : 12,
                12,
                compact ? 0 : 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(journey.name, style: ZyraText.body(size: 16)),
                  const SizedBox(height: 2),
                  Text(
                    journey.stage,
                    style: ZyraText.body(size: 12, color: ZyraColors.ink(.55)),
                  ),
                  SizedBox(height: compact ? 2 : 10),
                  if (width < 300 &&
                      MediaQuery.textScalerOf(context).scale(1) > 1.3)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _permission(person, journey, chat: false),
                        const SizedBox(height: 6),
                        _permission(person, journey, chat: true),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _permission(person, journey, chat: false),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _permission(person, journey, chat: true),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (locked || enabled) ...[
                    Icon(
                      locked ? Icons.lock_outline : Icons.check,
                      size: 13,
                      color: locked
                          ? ZyraColors.ink(.5)
                          : ZyraColors.journeyGold,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: ZyraText.body(
                        size: 12,
                        color: locked || !enabled
                            ? ZyraColors.ink(.5)
                            : ZyraColors.goldText,
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

  Widget _invited() => Padding(
    padding: EdgeInsets.symmetric(
      horizontal:
          MediaQuery.sizeOf(context).width < 360 &&
              MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? 18
          : 34,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _monogram('Omar', faded: true),
        const SizedBox(height: 18),
        Text(
          'Omar',
          style: ZyraText.heading(
            size: 34,
          ).copyWith(fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 4),
        Text(
          'INVITATION SENT',
          style: ZyraText.body(
            size: 11.5,
            color: ZyraColors.ink(.55),
          ).copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 22),
        _row(Icons.person_outline, 'Brother'),
        _row(Icons.shield_outlined, 'Not joined yet'),
        _row(Icons.check, 'Waiting for Omar'),
      ],
    ),
  );
  Widget _pill(
    String label,
    String key,
    VoidCallback onTap, {
    bool? selected,
    bool invitation = false,
  }) {
    final action = _action(onTap);
    final gold = selected == true || invitation;
    const radius = BorderRadius.all(Radius.circular(26));
    final pill = Semantics(
      key: ValueKey(key),
      role: selected == null ? null : SemanticsRole.tab,
      button: selected == null ? true : null,
      selected: selected,
      label: label,
      onTap: action,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFFBF7F0),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: gold
                ? ZyraColors.journeyGold.withValues(alpha: .6)
                : ZyraColors.surfaceBorder,
          ),
        ),
        child: InkWell(
          onTap: action,
          excludeFromSemantics: true,
          borderRadius: radius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: 14,
                color: gold
                    ? ZyraColors.goldText
                    : selected == null
                    ? ZyraColors.espresso
                    : ZyraColors.ink(.55),
              ).copyWith(fontWeight: gold ? FontWeight.w500 : null),
            ),
          ),
        ),
      ),
    );
    return gold || selected == null
        ? ZyraFloatingSurface(radius: 26, child: pill)
        : pill;
  }
}
