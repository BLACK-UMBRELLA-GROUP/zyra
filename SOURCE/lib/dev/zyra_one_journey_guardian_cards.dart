// LOCK 19 V6: Founder preview Guardian cards.
import 'package:flutter/gestures.dart' show kTouchSlop;
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
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_conversation_unread_badge.dart';
import 'zyra_one_journey_guardian_family_sheet.dart';
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
  final VoidCallback? onResume, onUpgrade;
  final ZyraGuardianFamilyState familyState;
  final bool Function(String)? familyInvited;
  final ValueChanged<String>? onFamilyInvite, onFamilyCancel;

  @override
  State<ZyraOneJourneyGuardianCards> createState() => _GuardianCardsState();
}

class _GuardianCardsState extends State<ZyraOneJourneyGuardianCards> {
  int _index = 0, _render = 0;
  LocalHistoryEntry? _menuEntry;
  bool Function()? _menuCurrent;
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

  bool get _canShowInvitation => !widget.basic && _people.isNotEmpty;
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
      _clearDrag();
      _render++;
    }
    if (_menuCurrent?.call() == false) _closeMenu();
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
    final entry = _menuEntry;
    _menuEntry = null;
    _menuCurrent = null;
    entry?.remove();
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
      _menuEntry == null &&
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
      _clearDrag();
      _render++;
    });
    widget.onPage(next);
  }

  void _clearDrag() {
    _drag = 0;
    _dragLease = null;
  }

  void _openMenu() {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent || _menuEntry != null) return;
    final authority = widget.canAct;
    final target = _target;
    final epoch = widget.interactionEpoch();
    final identity = widget.contextIdentity;
    final renderIdentity = widget.renderIdentity;
    final wasMain = _person?.person.isMain;
    final basic = widget.basic;
    final capacity = widget.capacity;
    _render++;
    _clearDrag();
    late final LocalHistoryEntry entry;
    var revoked = false;
    _menuCurrent = () {
      if (revoked) return false;
      final current =
          mounted &&
          identical(_menuEntry, entry) &&
          _owner == (ZyraAccountState.userId, ZyraAccountState.generation) &&
          renderIdentity == widget.renderIdentity &&
          wasMain == _person?.person.isMain &&
          basic == widget.basic &&
          capacity == widget.capacity &&
          identity == widget.contextIdentity &&
          epoch == widget.interactionEpoch() &&
          _target == target &&
          route.isCurrent &&
          authority() &&
          widget.canAct();
      if (!current) revoked = true;
      return current;
    };
    entry = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: () {
        if (!identical(_menuEntry, entry)) return;
        setState(() {
          _menuEntry = null;
          _menuCurrent = null;
          _render++;
        });
      },
    );
    setState(() => _menuEntry = entry);
    route.addLocalHistoryEntry(entry);
  }

  void _closeMenu() => _menuEntry?.remove();

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
    final add = person == null && !_invitedCard;
    final textScaler = MediaQuery.textScalerOf(context);
    final scale = textScaler.scale(1);
    final largerText = textScaler.scale(14) > 14;
    final target = _target;
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
    final move = ZyraTapFeedback.onChanged<int>(
      context,
      _move,
      canAct: faceLease,
    )!;
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
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                onSelected: (index) {
                  if (index != _index) _move(index);
                },
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (add)
                      ZyraGuardianAddCard(
                        basicCapacity: basicCapacity,
                        onUpgrade: widget.basic && upgrade != null
                            ? _action(upgrade)
                            : null,
                        allowContentScroll: largerText,
                      )
                    else
                      ExcludeSemantics(
                        excluding: _menuEntry != null,
                        child: _card(person),
                      ),
                    if (!add && _index > 0)
                      _edge(left: true, onTap: () => move(_index - 1)),
                    if (_index + 1 < _guardianCount)
                      _edge(left: false, onTap: () => move(_index + 1)),
                    if (person != null && _menuCurrent != null)
                      Positioned.fill(
                        child: _menu(person, _menuEntry!, _menuCurrent!),
                      ),
                  ],
                ),
              ),
            ),
            if (add) ...[
              const SizedBox(height: ZyraPreviewSpacing.cardToPill),
              _pill('Add a Guardian', 'guardian-card-center', widget.onAdd),
            ],
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

  Widget _menu(
    ZyraGuardianCardPerson person,
    LocalHistoryEntry entry,
    bool Function() current,
  ) {
    void close() {
      if (identical(_menuEntry, entry)) entry.remove();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(
          color: const Color(0x241E1610),
          onDismiss: close,
          semanticsLabel: 'Dismiss Guardian actions',
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            key: const ValueKey('guardian-card-menu-sheet'),
            color: const Color(0xFFF7F2EA),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SingleChildScrollView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(30, 12, 30, 12),
              child: zyraGuardianCardManageActions(
                person: person.person,
                otherGuardians: widget.people
                    .map((p) => p.person)
                    .where((p) => p.id != person.person.id)
                    .toList(),
                canAct: current,
                makeMainGuardian: widget.makeMain,
                clearMainGuardian: widget.clearMain,
                removeGuardian: widget.remove,
                closeMenu: close,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(ZyraGuardianCardPerson? person) => ZyraFloatingSurface(
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
        builder: (context, box) => SingleChildScrollView(
          key: ValueKey('guardian-card-content-$_target'),
          primary: false,
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            // Equal flex rows reserve the largest natural row height when
            // space is tight. Clamping permits movement only on overflow.
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(29, 12, 29, 12),
                child: person == null
                    ? _invited()
                    : _linked(person, box.maxWidth - 58),
              ),
            ),
          ),
        ),
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
            onPressed: _action(_openMenu),
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

  String _date(DateTime? date) {
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Widget _linked(ZyraGuardianCardPerson person, double width) {
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
                ? _journey(person, rows[i], stackChips: stackChips)
                : _freePlace(guardian.firstName, i),
          ),
        _history(person),
      ],
    );
  }

  Widget _history(ZyraGuardianCardPerson person) {
    final id = person.person.id;
    final action = _action(() => widget.onHistory(id, !person.history));
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
        const SizedBox(width: 4),
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
                const SizedBox(width: 4),
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
            21,
            ZyraColors.journeyGold,
          ),
          child: SizedBox.square(
            dimension: 42,
            child: Icon(Icons.add, size: 18, color: ZyraColors.journeyGold),
          ),
        ),
        const SizedBox(width: 4),
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

  Widget _invited() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _top('Omar', 'INVITATION SENT', invited: true),
      const SizedBox(height: 12),
      _detail('Relationship', 'Brother'),
      _detail('Membership', 'Not joined yet'),
      _detail('Status', 'Waiting for Omar'),
      Expanded(
        child: Center(
          child: Text(
            'Access starts once Omar accepts the invitation.',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 14, color: ZyraColors.ink(.55)),
          ),
        ),
      ),
      _pill(
        'Send invitation again',
        'guardian-card-center',
        widget.onAdd,
        invitation: true,
      ),
    ],
  );

  Widget _pill(
    String label,
    String key,
    VoidCallback onTap, {
    bool invitation = false,
  }) {
    final action = _action(onTap);
    const radius = BorderRadius.all(Radius.circular(26));
    final pill = Semantics(
      key: ValueKey(key),
      button: true,
      label: label,
      onTap: action,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFFBF7F0),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: invitation
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
                color: invitation ? ZyraColors.goldText : ZyraColors.espresso,
              ).copyWith(fontWeight: invitation ? FontWeight.w500 : null),
            ),
          ),
        ),
      ),
    );
    return ZyraFloatingSurface(radius: 26, child: pill);
  }
}
