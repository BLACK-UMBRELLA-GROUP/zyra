import '../widgets/zyra_floating_surface.dart';
// LOCK 8 V3 / LOCK 15 V2: fictional Guardian presentation only. No service, RPC or member
// authority. The admitted shell owns changes and the lifetime of callbacks.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_tap_feedback.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_focus_dashboard.dart';
import '../screens/wali/family_messaging_screens.dart'
    show ZyraFamilyMessageComposer;

enum ZyraGuardianReview { open, paused, continued }

enum ZyraGuardianConnection { pending, accepted, dismissed, blocked }

class ZyraGuardianTabsSnapshot {
  const ZyraGuardianTabsSnapshot({
    this.review = ZyraGuardianReview.open,
    this.hours = 41,
    this.reviewRevision = 0,
    this.connection = ZyraGuardianConnection.pending,
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
  });
  final ZyraGuardianReview review;
  final ZyraGuardianConnection connection;
  final int hours, seeker, requestSeeker, networkIndex, reviewRevision;
  final bool requestsSent, connectReceived, attentionSeen;
  final Set<String> introduced, sent, consumedFocus;
  final int focusIndex;
}

class ZyraGuardianTabsState {
  ZyraGuardianTabsState([
    ZyraGuardianTabsSnapshot saved = const ZyraGuardianTabsSnapshot(),
  ]) {
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
  String get reviewFocusId =>
      'review-${review == ZyraGuardianReview.paused ? 'paused' : 'open'}-$reviewRevision';
  String get seekerName => seeker == 0 ? 'Adam' : 'Yusuf';
  bool get main => seeker == 0;
  bool get canPrevious => networkIndex > 0;
  bool get canNext => networkIndex < network.length - 1;
  bool get needsYou =>
      review != ZyraGuardianReview.continued ||
      connection == ZyraGuardianConnection.pending;
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
  );
}

class ZyraGuardianTabsPresentation extends StatelessWidget {
  const ZyraGuardianTabsPresentation({
    super.key,
    required this.state,
    required this.page,
    required this.onAction,
    required this.photoFor,
    this.linked = true,
    this.paid = true,
    this.adamMain = true,
    this.focusItems,
    this.notificationCount = 0,
  });
  final ZyraGuardianTabsState state;
  final String page;
  final ValueChanged<String> onAction;
  final String? Function(String) photoFor;
  final bool linked, paid, adamMain;
  final List<ZyraFocusItem>? focusItems;
  final int notificationCount;
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
  Widget _title(String text, {double size = 28}) => Text(
    text,
    key: text == 'Profile' ? const ValueKey('concept_profile_title') : null,
    style: ZyraText.heading(
      size: size,
    ).copyWith(fontWeight: FontWeight.w300, height: 1.2),
  );
  Widget _label(String text, {bool gold = false}) =>
      _text(text, size: 11, muted: !gold, gold: gold);
  Widget _button(
    String label,
    String action, {
    bool gold = false,
    bool network = false,
  }) => Builder(
    builder: (context) => ConstrainedBox(
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
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ZyraText.body(
              size: 13,
              color: gold && !network
                  ? ZyraColors.goldText
                  : ZyraColors.foreground,
            ).copyWith(height: network ? 1.35 : 1.45),
          ),
        ),
      ),
    ),
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
  Widget _tile(String title, String detail, IconData icon, String action) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
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
                      child: Icon(
                        icon,
                        color: ZyraColors.journeyGold,
                        size: 20,
                      ),
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
  Widget _header(String title, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        Expanded(child: _title(title)),
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
  Widget _avatar(String name, {double size = 56, Color? color}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color ?? ZyraColors.avatarDeepSand,
      border: Border.all(color: ZyraColors.journeyGold.withValues(alpha: .6)),
    ),
    child: Center(child: _text(name[0], size: size * .35)),
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
      SafeArea(
        bottom: false,
        child: scroll
            ? ZyraShadowScrollView(
                key: PageStorageKey('guardian_tabs_$page'),
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
                child: child,
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: child,
              ),
      );
  Widget _quiet(String title, String detail, IconData icon) => Expanded(
    child: Align(
      alignment: const Alignment(0, -.35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 25, color: ZyraColors.ink(.55)),
          const SizedBox(height: 13),
          _text(title),
          const SizedBox(height: 5),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 13).copyWith(height: 1.45),
          ),
        ],
      ),
    ),
  );

  List<ZyraFocusItem> get _homeFocusItems {
    final review = state.review;
    final hours = state.hours;
    return [
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
    final hasRequest = linked && adamMain;
    final hasConnect =
        linked &&
        paid &&
        adamMain &&
        state.connection == ZyraGuardianConnection.pending;
    final items = (focusItems ?? _homeFocusItems)
        .where((item) => !state.consumedFocus.contains(item.id))
        .toList(growable: false);
    return ZyraFocusDashboard(
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
          status: hasRequest ? '1 new' : 'None',
          icon: Icons.inbox_outlined,
          isNew: hasRequest,
          onTap: () => onAction('requests'),
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
          onTap: () => onAction(paid ? 'connect' : 'membership'),
        ),
        ZyraFocusTile(
          id: 'guardian_introductions',
          label: 'Introductions',
          status: paid ? '${state.introduced.length} made' : 'Guardian One',
          icon: Icons.groups_outlined,
          locked: !paid,
          onTap: () => onAction(paid ? 'introductions' : 'membership'),
        ),
        ZyraFocusTile(
          id: 'guardian_notifications',
          label: 'Notifications',
          status: notificationCount > 0
              ? '$notificationCount new'
              : 'Nothing new',
          icon: Icons.notifications_none,
          isNew: notificationCount > 0,
          onTap: () => onAction('notifications'),
        ),
      ],
    );
  }

  Widget _requests() => _viewport(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          'Journey requests',
          trailing: _switcher(
            const ['All Seekers', 'for Adam', 'for Yusuf'][state.requestSeeker],
            'request_seeker',
          ),
        ),
        _segments(
          const ['Received', 'Sent'],
          state.requestsSent ? 1 : 0,
          'requests_tab_',
        ),
        if (linked && adamMain && state.requestSeeker != 2) ...[
          _box(
            Row(
              children: [
                _photo(state.requestsSent ? 'sara' : 'amira'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(
                        state.requestsSent ? 'Sara Ahmed' : 'Amira Rahman',
                        size: 18,
                      ),
                      _text(
                        state.requestsSent
                            ? '27 · Birmingham'
                            : '28 · Manchester',
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
          const SizedBox(height: 10),
          _text(
            'You see these as their Main Guardian. Each Seeker decides on their own requests.',
            size: 12,
            muted: true,
          ),
        ] else
          _text('Main Guardian only', muted: true),
      ],
    ),
  );
  Widget _connect() {
    final received = state.connectReceived;
    final empty = received
        ? (!linked || !adamMain || state.receivedCount == 0)
        : state.sent.isEmpty;
    return _viewport(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header('Connect with Guardian'),
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
            )
          else ...[
            if (received)
              _connectionCard(
                'noor',
                accepted: state.connection == ZyraGuardianConnection.accepted,
              )
            else
              for (final id in state.sent) ...[
                _connectionCard(id),
                const SizedBox(height: 10),
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
              _header("Introductions you've made"),
              _quiet(
                'No introductions yet.',
                'Find someone in Network and choose Introduce to ${state.seekerName}.',
                Icons.groups_outlined,
              ),
            ],
          ),
          scroll: false,
        )
      : _viewport(
          Column(
            children: [
              _header("Introductions you've made"),
              for (final entry in state.introduced.where(
                (id) => id.startsWith('${state.seekerName.toLowerCase()}:'),
              ))
                _tile(
                  entry.split(':').last == 'aisha' ? 'Aisha' : 'Noor',
                  'Suggested to ${state.seekerName}',
                  Icons.groups_outlined,
                  'network',
                ),
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

  Widget _network(BuildContext context) {
    if (!linked) {
      return _viewport(
        Column(
          children: [
            _header('Network'),
            _tile(
              'Invite your Seeker',
              'Support someone on their journey.',
              Icons.add,
              'invite',
            ),
          ],
        ),
      );
    }
    final scroll =
        MediaQuery.sizeOf(context).height < 900 ||
        MediaQuery.textScalerOf(context).scale(14) > 14;
    final person = ZyraGuardianTabsState.network[state.networkIndex];
    return _viewport(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(
            'Network',
            trailing: _switcher('for ${state.seekerName}', 'seeker'),
          ),
          Flexible(
            flex: scroll ? 0 : 1,
            child: SizedBox(
              height: scroll
                  ? 652 * (MediaQuery.textScalerOf(context).scale(14) / 14)
                  : null,
              child: _box(
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ZyraColors.journeyGold.withValues(
                                alpha: .7,
                              ),
                            ),
                          ),
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: ZyraColors.avatarDeepSand,
                            ),
                            child: Center(
                              child: Text(
                                person.name[0],
                                style: ZyraText.body(
                                  size: 22,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _title('${person.name[0]}., ${person.age}', size: 40),
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
          const SizedBox(height: 14),
          Row(
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
                  state.sent.contains(person.id)
                      ? 'Request sent'
                      : 'Connect with\nGuardian',
                  'connect_confirm',
                  gold: true,
                  network: true,
                ),
              ),
              const SizedBox(width: 10),
              _networkArrow(true),
            ],
          ),
          const SizedBox(height: 95),
        ],
      ),
      scroll: scroll,
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
    return _viewport(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(
            introduction
                ? 'Introduce to ${state.seekerName}'
                : 'Connect with Guardian',
          ),
          const SizedBox(height: 8),
          _title(
            introduction
                ? 'Put ${person.name} forward to ${state.seekerName}?'
                : "${person.name}'s Main Guardian",
            size: 22,
          ),
          const SizedBox(height: 8),
          _text(
            introduction
                ? '${state.seekerName} sees ${person.name} in his Introductions, marked "Suggested by Hassan". ${state.seekerName} decides whether to send a Journey request. ${person.name} and her family are not told.'
                : 'Send a request to the Main Guardian supporting this Seeker. They choose whether to respond.',
            size: 13,
          ),
          const Spacer(),
          _button(
            introduction ? 'Introduce' : 'Send request',
            introduction ? 'introduce_send' : 'connect_send',
            gold: true,
          ),
          Builder(
            builder: (context) => TextButton(
              onPressed: ZyraTapFeedback.onTap(context, () => onAction('back')),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _text(introduction ? 'Not now' : 'Not yet', size: 13),
            ),
          ),
          const SizedBox(height: 23),
        ],
      ),
      scroll: false,
    );
  }

  Widget _journeys() => _viewport(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          'Journeys',
          trailing: _switcher('for ${state.seekerName}', 'seeker'),
        ),
        if (linked && state.main)
          _box(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 170,
                  decoration: BoxDecoration(
                    color: ZyraColors.avatarSand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: _text('S', size: 40, muted: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 170),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _text('Adam & Sara', size: 18),
                        _text(
                          'Sara Ahmed · 27 · Birmingham',
                          size: 12,
                          muted: true,
                        ),
                        const SizedBox(height: 6),
                        _text(state.stageLine, size: 12, gold: true),
                        const SizedBox(height: 5),
                        _text(
                          'You: Main Guardian · View and Chat',
                          size: 11,
                          muted: true,
                        ),
                        const SizedBox(height: 30),
                        _button('Open Journey', 'journey'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            gold: true,
            padding: const EdgeInsets.all(12),
          )
        else
          _text('No current Journey', muted: true),
        const SizedBox(height: 10),
        if (linked)
          _tile(
            'Ended Journeys',
            'Only what ${state.seekerName} shares with you',
            Icons.history,
            'ended',
          ),
      ],
    ),
  );
  Widget _seekers() => _viewport(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          'Seekers',
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
              padding: const EdgeInsets.only(bottom: 10),
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
                        _avatar(
                          i == 0 ? 'Adam' : 'Yusuf',
                          size: 62,
                          color: i == 0 ? null : ZyraColors.avatarWarmSand,
                        ),
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
  );
  Widget _seeker() => _viewport(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(state.seekerName),
        _box(
          Row(
            children: [
              _text('✓ Active', size: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _text(
                    'Linked  ${state.main ? '20 Sep 2026' : '02 Oct 2026'}',
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        const SizedBox(height: 16),
        _label('YOUR ACCESS'),
        const SizedBox(height: 4),
        _info(
          'Role',
          state.main && adamMain ? 'Main Guardian' : 'Additional Guardian',
          rule: false,
        ),
        _info(
          'Journeys',
          state.main && adamMain
              ? 'View and Chat'
              : 'As ${state.seekerName} allows, Journey by Journey',
          rule: false,
        ),
        _info(
          'Journey requests',
          state.main && adamMain ? 'You see them' : 'Main Guardian only',
          rule: false,
        ),
        _info('Past summaries', 'Not shared', rule: false),
        const SizedBox(height: 16),
        _label('JOURNEY'),
        const SizedBox(height: 4),
        _info(
          'Current',
          state.main ? 'With Sara · ${state.stage}' : 'None',
          rule: false,
        ),
        const SizedBox(height: 2),
        if (state.main && adamMain) ...[
          _button('Open Journey', 'journey', gold: true),
          const SizedBox(height: 8),
        ],
        _button("Enter ${state.seekerName}'s Guardian Circle", 'circle'),
      ],
    ),
  );
  Widget _profile() => _viewport(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('Profile'),
        Row(
          children: [
            _avatar('Hassan', size: 64, color: Colors.transparent),
            const SizedBox(width: 14),
            Expanded(child: _text('Hassan Rahman', size: 20)),
            KeyedSubtree(
              key: const ValueKey('draft_role_seeker'),
              child: _switcher(
                'Switch',
                'switch',
                chevron: false,
                icon: Icons.swap_horiz,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('MEMBERSHIP'),
        _profileRow(
          paid ? 'Guardian One' : 'Guardian Basic',
          Icons.verified_user_outlined,
          'membership',
          detail: 'Manage membership',
        ),
        _profileRow(
          'Your subscriptions',
          Icons.inbox_outlined,
          'subscriptions',
        ),
        const SizedBox(height: 16),
        _label('ABOUT ME'),
        _info('Relationship', 'Father', rule: false),
        _info('Linked Seekers', linked ? '2' : '0', rule: false),
        const SizedBox(height: 16),
        _label('SAFETY & SHARING'),
        _profileRow('Safety & advice', Icons.outlined_flag, 'safety'),
        _profileRow('Invite someone to ZYRA', Icons.add, 'invite_zyra'),
        const SizedBox(height: 16),
        _label('PERSONALISATION'),
        _profileRow(
          'Appearance & haptics',
          Icons.grid_view_outlined,
          'personalisation',
        ),
        _profileRow('Settings', Icons.tune, 'settings'),
        _profileRow('Sign out', Icons.history, 'sign_out'),
      ],
    ),
  );
  Widget _profileRow(
    String title,
    IconData icon,
    String action, {
    String? detail,
  }) => Builder(
    builder: (context) => KeyedSubtree(
      key: ValueKey('concept_${action == 'safety' ? 'safetyAdvice' : action}'),
      child: InkWell(
        key: ValueKey('guardian_$action'),
        onTap: ZyraTapFeedback.onTap(context, () => onAction(action)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: ZyraColors.surfaceBorder)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ZyraColors.journeyGold),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text(title, size: 15),
                    if (detail != null) _text(detail, size: 12, gold: true),
                  ],
                ),
              ),
              _text('›', muted: true),
            ],
          ),
        ),
      ),
    ),
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
    'journeys' => _journeys(),
    'seekers' => _seekers(),
    'seeker' => _seeker(),
    'profile' => _profile(),
    _ => const SizedBox.shrink(),
  };
}

class ZyraGuardianPrivateChat extends StatefulWidget {
  const ZyraGuardianPrivateChat({
    super.key,
    required this.onSend,
    required this.onReport,
    required this.canAct,
  });
  final VoidCallback onSend, onReport;
  final bool Function() canAct;
  @override
  State<ZyraGuardianPrivateChat> createState() =>
      _ZyraGuardianPrivateChatState();
}

class _ZyraGuardianPrivateChatState extends State<ZyraGuardianPrivateChat> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Noor's Main Guardian",
                style: ZyraText.heading(
                  size: 28,
                ).copyWith(fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 6),
              Text('About Adam and Noor', style: ZyraText.subtext(size: 12)),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          key: const ValueKey('guardian_chat_report'),
          onLongPress: ZyraTapFeedback.onTap(context, widget.onReport),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 21,
                  color: ZyraColors.journeyGold,
                ),
                const SizedBox(height: 14),
                Text(
                  'A private chat between the two Main Guardians. Only you two see it. Keep it respectful — you can report anything here.',
                  textAlign: TextAlign.center,
                  style: ZyraText.subtext(size: 13).copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        ZyraFamilyMessageComposer(
          controller: _controller,
          busy: !widget.canAct(),
          contextEnabled: false,
          selectedContext: null,
          onChooseContext: () {},
          onRemoveContext: () {},
          onOpenContext: null,
          hint: 'Message',
          privateGuardian: true,
          onSend: () {
            if (widget.canAct() && _controller.text.trim().isNotEmpty) {
              widget.onSend();
              _controller.clear();
            }
          },
        ),
      ],
    ),
  );
}
