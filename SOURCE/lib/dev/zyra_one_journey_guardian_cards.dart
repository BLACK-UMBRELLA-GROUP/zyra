// LOCK19 V2: Founder-only Guardian cards. No live transport or entitlement grant.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import '../services/zyra_account_state.dart';
import '../services/zyra_wali_link_service.dart' show WaliLinkedPerson;
import '../screens/wali/seeker_guardian_designs.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
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
    this.photo,
  });
  final String id, name, stage;
  final int? attempt;
  final String? photo;
  final bool view, chat, canChange;
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

  @override
  State<ZyraOneJourneyGuardianCards> createState() => _GuardianCardsState();
}

class _GuardianCardsState extends State<ZyraOneJourneyGuardianCards> {
  int _index = 0, _render = 0;
  bool _access = false;
  double _drag = 0;
  final _invites = <String>{};
  Object? _sheetLease;
  ModalRoute<dynamic>? _sheetRoute;
  final _owner = (ZyraAccountState.userId, ZyraAccountState.generation);

  List<ZyraGuardianCardPerson> get _people {
    final all = List<ZyraGuardianCardPerson>.of(widget.people);
    all.sort((a, b) {
      if (a.person.isMain != b.person.isMain) return a.person.isMain ? -1 : 1;
      return (a.person.linkedAt ?? DateTime(2100)).compareTo(
        b.person.linkedAt ?? DateTime(2100),
      );
    });
    return widget.basic ? all.take(1).toList() : all;
  }

  int get _length => _people.length + (widget.basic ? 1 : 2);
  ZyraGuardianCardPerson? get _person =>
      _index < _people.length ? _people[_index] : null;
  bool get _invitedCard => !widget.basic && _index == _people.length;
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
    _index = _index.clamp(0, _length - 1);
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
      _render++;
    });
    widget.onPage(next);
  }

  void _flip() {
    if (_person == null) return;
    setState(() {
      _access = !_access;
      _render++;
    });
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
            invited: _invites.contains(target),
            familyState: widget.familyState,
            onInvite: () {
              if (current()) {
                setState(() {
                  _invites.add(target);
                  _render++;
                });
              }
            },
            onCancelInvite: () {
              if (current()) {
                setState(() {
                  _invites.remove(target);
                  _render++;
                });
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
        if (baseEpoch == widget.interactionEpoch()) _drag = 0;
        widget.onResume?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    final linked = person != null;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final render = _render, epoch = widget.interactionEpoch(), target = _target;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 86),
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
            SizedBox(
              height: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < (linked ? 2 : 1); i++)
                    Container(
                      key: ValueKey('guardian-card-dot-$i'),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: i == (linked && _access ? 1 : 0) ? 30 : 6,
                      decoration: BoxDecoration(
                        color: i == (linked && _access ? 1 : 0)
                            ? ZyraColors.journeyGold
                            : ZyraColors.ink(.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final minimum = linked && _access
                      ? 98 +
                            widget.capacity *
                                (scale > 1.3
                                    ? (box.maxWidth < 340 ? 360.0 : 260.0)
                                    : 142.0) *
                                math.max(1, scale / 1.6)
                      : (box.maxWidth < 340 && scale > 1.3 ? 650 : 520) *
                            math.max(1, scale / 1.3);
                  return SingleChildScrollView(
                    key: const ValueKey('guardian-card-scroll'),
                    child: SizedBox(
                      height: math.max(box.maxHeight, minimum).toDouble(),
                      width: box.maxWidth,
                      child: GestureDetector(
                        key: ValueKey('guardian-card-$target'),
                        behavior: HitTestBehavior.opaque,
                        onTap: linked ? _action(_flip) : null,
                        onHorizontalDragStart: (_) {
                          if (_current(render, epoch, target)) _drag = 0;
                        },
                        onHorizontalDragUpdate: (d) {
                          if (_current(render, epoch, target)) {
                            _drag += d.delta.dx;
                          }
                        },
                        onHorizontalDragEnd: (_) {
                          if (!_current(render, epoch, target)) return;
                          if (_drag.abs() >= kTouchSlop) {
                            _action(
                              () => _move(_index + (_drag < 0 ? 1 : -1)),
                            )();
                          }
                          _drag = 0;
                        },
                        child: ZyraFloatingSurface(
                          radius: 22,
                          child: CustomPaint(
                            foregroundPainter: !linked && !_invitedCard
                                ? _DashedBorder(
                                    22,
                                    ZyraColors.journeyGold.withValues(
                                      alpha: .6,
                                    ),
                                  )
                                : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EDE3),
                                borderRadius: BorderRadius.circular(22),
                                border: linked || _invitedCard
                                    ? Border.all(
                                        color: person?.person.isMain == true
                                            ? const Color(
                                                0xFFE8C98A,
                                              ).withValues(alpha: .6)
                                            : ZyraColors.surfaceBorder,
                                      )
                                    : null,
                              ),
                              child: linked
                                  ? (_access ? _back(person) : _front(person))
                                  : (_invitedCard ? _invited() : _add()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _pager(
              linked
                  ? (_access ? 'Details' : 'Journey access')
                  : (_invitedCard
                        ? 'Send invitation again'
                        : widget.basic
                        ? 'View Seeker One'
                        : 'Add a Guardian'),
            ),
          ],
        ),
      ),
    );
  }

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
    child: Container(
      width: 110 * math.min(1.5, MediaQuery.textScalerOf(context).scale(1)),
      height: 110 * math.min(1.5, MediaQuery.textScalerOf(context).scale(1)),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFA9792E).withValues(alpha: .7),
        ),
      ),
      child: Text(
        name.substring(0, 1),
        style: ZyraText.heading(
          size: 52,
          color: ZyraColors.journeyGold,
        ).copyWith(fontWeight: FontWeight.w200),
      ),
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

  Widget _back(ZyraGuardianCardPerson person) {
    final rows = widget
        .journeysFor(person.person.id)
        .take(widget.capacity)
        .toList();
    final target = _target;
    final current = _lease();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
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
                  ? _journey(person, rows[i])
                  : CustomPaint(
                      foregroundPainter: _DashedBorder(16, ZyraColors.ink(.08)),
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
  ) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      key: ValueKey('guardian-card-tile-${journey.id}'),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE4DA),
        border: Border.all(color: ZyraColors.ink(.06)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: math.min(150, box.maxWidth * .34),
              child: journey.photo == null
                  ? const SizedBox()
                  : ZyraProfileImage(journey.photo!, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(journey.name, style: ZyraText.body(size: 16)),
                    const SizedBox(height: 2),
                    Text(
                      journey.stage,
                      style: ZyraText.body(
                        size: 12,
                        color: ZyraColors.ink(.55),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (box.maxWidth < 300 &&
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
            ),
          ],
        ),
      ),
    ),
  );
  Widget _permission(
    ZyraGuardianCardPerson person,
    ZyraGuardianCardJourney journey, {
    required bool chat,
  }) {
    final locked = chat && person.basic;
    final invited = locked && _invites.contains(person.person.id);
    final enabled = chat ? journey.chat : journey.view;
    final label = chat ? (invited ? 'Invited' : 'Chat') : 'View';
    final canChange = locked || (journey.canChange && (!chat || journey.view));
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
                ? _DashedBorder(20, ZyraColors.ink(.12))
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
  Widget _add() => Padding(
    padding: EdgeInsets.all(
      MediaQuery.sizeOf(context).width < 360 &&
              MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? 18
          : 34,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ZyraColors.ink(.08),
          ),
          child: Icon(
            widget.basic ? Icons.lock_outline : Icons.add,
            color: ZyraColors.journeyGold,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          widget.basic ? 'Add more Guardians' : 'Add a Guardian',
          textAlign: TextAlign.center,
          style: ZyraText.heading(size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          widget.basic
              ? 'Seeker Basic includes 1 Guardian. Seeker One lets you add up to 10.'
              : 'Share your ZYRA Code, or scan theirs. You choose who joins.',
          textAlign: TextAlign.center,
          style: ZyraText.body(size: 13, color: ZyraColors.ink(.55)),
        ),
      ],
    ),
  );
  Widget _pager(String label) => ZyraFloatingSurface(
    radius: 28,
    child: Material(
      color: const Color(0xFFFBF7F0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: ZyraColors.surfaceBorder),
      ),
      child: Row(
        children: [
          _arrow(false),
          Container(width: 1, height: 22, color: ZyraColors.ink(.06)),
          Expanded(
            child: InkWell(
              key: const ValueKey('guardian-card-center'),
              onTap: _action(_person != null ? _flip : widget.onAdd),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: ZyraText.body(size: 14, color: ZyraColors.espresso),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 22, color: ZyraColors.ink(.06)),
          _arrow(true),
        ],
      ),
    ),
  );
  Widget _arrow(bool next) {
    final enabled = next ? _index < _length - 1 : _index > 0;
    return Opacity(
      opacity: enabled ? 1 : .35,
      child: IconButton(
        key: ValueKey('guardian-card-${next ? 'next' : 'previous'}'),
        onPressed: enabled
            ? _action(() => _move(_index + (next ? 1 : -1)))
            : null,
        icon: Icon(
          next ? Icons.chevron_right : Icons.chevron_left,
          size: 20,
          color: ZyraColors.journeyGold,
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.radius, this.color);
  final double radius;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 5) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 2.5, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
