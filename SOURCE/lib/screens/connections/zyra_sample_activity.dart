import 'package:flutter/material.dart';

import '../../data/zyra_journey_stages.dart';
import '../../dev/zyra_one_journey_discovery_presentation.dart';
import '../../dev/zyra_one_journey_options.dart';
import '../../dev/zyra_request_activity_presentation.dart';
import '../../dev/zyra_request_capacity_choice.dart';
import '../../dev/zyra_view_request_draft_model.dart' show DraftProfile;
import '../../state/app_state.dart';
import '../../state/zyra_developer_samples.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_confirm_sheet.dart';
import '../../widgets/zyra_developer_title.dart';
import '../../widgets/zyra_floating_surface.dart';
import '../../widgets/zyra_profile_image.dart';
import '../profile/seeker_profile_screen.dart';
import 'connections_section_controller.dart';

final _samples = ZyraDeveloperSamples.instance;

bool _foreground(BuildContext context) =>
    context.mounted && (ModalRoute.of(context)?.isCurrent ?? true);

void _showProfile(
  BuildContext context,
  DraftProfile person,
  bool Function() current, {
  String? suggestedBy,
}) {
  if (!_foreground(context) || !current()) return;
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ListenableBuilder(
        listenable: _samples,
        builder: (context, _) => !current()
            ? const Scaffold(body: _SampleBack())
            : SeekerProfileScreen(
                profile: _samples.profileFor(person),
                suggestedBy: suggestedBy,
                swipeDownToDismiss: true,
                canAct: current,
              ),
      ),
    ),
  );
}

void _notice(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(text)));
  }
}

String _date(DateTime date) {
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
  final suffix = date.year == DateTime.now().year ? '' : ' ${date.year}';
  return '${date.day} ${months[date.month - 1]}$suffix';
}

String _name(DraftProfile person) =>
    '${person.firstName} ${person.surname}'.trim();

/// The same three request tabs and grouped Past cards used by LOCK 2 V3.
class ZyraDeveloperJourneyRequestsScreen extends StatefulWidget {
  const ZyraDeveloperJourneyRequestsScreen({
    super.key,
    this.tabClearance = false,
    this.initialTab = 0,
    this.onTabChanged,
    this.wrapTitle,
  });

  final bool tabClearance;
  final int initialTab;
  final ValueChanged<int>? onTabChanged;
  final Widget Function(Widget)? wrapTitle;

  @override
  State<ZyraDeveloperJourneyRequestsScreen> createState() =>
      _ZyraDeveloperJourneyRequestsScreenState();
}

class _ZyraDeveloperJourneyRequestsScreenState
    extends State<ZyraDeveloperJourneyRequestsScreen> {
  final _expansion = ZyraConnectionsExpansionController();
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 2);
  }

  @override
  void dispose() {
    _expansion.dispose();
    super.dispose();
  }

  bool _current() => mounted && _foreground(context) && _samples.isAuthorized;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _SamplePageCanvas(
      child: ListenableBuilder(
        listenable: _samples,
        builder: (context, _) => !_samples.isAuthorized
            ? const _SampleBack()
            : ZyraRequestActivityPresentation(
                title: 'Journey requests',
                tabClearance: widget.tabClearance,
                wrapTitle:
                    widget.wrapTitle ??
                    ((title) => _SampleRouteTitle(title: title)),
                labels: const ['Received', 'Sent', 'Past'],
                selectedIndex: _tab,
                canInteract: _current,
                onChanged: (tab) {
                  if (!_current() || tab < 0 || tab > 2 || tab == _tab) return;
                  _expansion.collapseAll();
                  setState(() => _tab = tab);
                  widget.onTabChanged?.call(tab);
                },
                pages: [_pending(true), _pending(false), _past()],
              ),
      ),
    ),
  );

  List<Widget> _pending(bool incoming) {
    final rows =
        (incoming ? _samples.receivedRows : _samples.sentRows) ?? const [];
    if (rows.isEmpty) {
      return [
        ZyraRequestActivityEmpty(
          icon: Icons.mail_outline_rounded,
          title: incoming
              ? 'No received requests yet.'
              : 'No sent requests yet.',
          message: incoming
              ? 'Your Journey requests will appear here.'
              : 'Requests you send will appear here.',
        ),
      ];
    }
    return [for (final request in rows) _requestCard(request)];
  }

  Widget _requestCard(ZyraSampleRequest request) {
    final id = 'sample-request-${request.incoming}-${request.person.id}';
    final lease = _samples.generation;
    bool visible() => _samples.isCurrentLease(lease);
    bool present() => visible() && _samples.isRequestCurrent(request);
    bool current() =>
        _current() && _tab == (request.incoming ? 0 : 1) && present();
    final expiry = request.expiresAt;
    return ZyraRequestActivityCard(
      key: ValueKey(id),
      headerKey: ValueKey('$id-header'),
      profile: _samples.profileFor(request.person),
      subtitle: request.incoming
          ? 'Journey request'
          : expiry == null
          ? 'Waiting for a response'
          : 'Request sent. It expires on ${MaterialLocalizations.of(context).formatMediumDate(expiry.toLocal())}.',
      cardId: id,
      controller: _expansion,
      canInteract: current,
      onToggle: () {
        if (!current()) return;
        if (_expansion.value == id) {
          _expansion.close(id);
        } else {
          _expansion.open(id);
        }
      },
      primary: ZyraOneJourneyConnectionsAction(
        label: 'View profile',
        icon: Icons.visibility_outlined,
        onTap: () => _showProfile(context, request.person, present),
      ),
      actions: [
        if (request.incoming)
          ZyraOneJourneyConnectionsAction(
            label: 'Accept request',
            icon: Icons.check,
            onTap: _samples.canAccept(request)
                ? () {
                    if (current()) _accept(request);
                  }
                : null,
          ),
        ZyraOneJourneyConnectionsAction(
          label: request.incoming ? 'Decline' : 'Cancel request',
          icon: Icons.close,
          onTap: () async {
            if (!current()) return;
            final accepted = await showZyraConfirm(
              context: context,
              title: request.incoming
                  ? 'Decline this request?'
                  : 'Cancel this request?',
              body: request.incoming
                  ? 'This Journey request moves to Past.'
                  : 'Your Journey request moves to Past.',
              primaryLabel: request.incoming ? 'Decline' : 'Cancel request',
              secondaryLabel: 'Keep request',
              canConfirm: present,
              visibilityListenable: _samples,
              isVisible: visible,
            );
            if (accepted == true &&
                current() &&
                _samples.declineOrCancel(request)) {
              _expansion.close(id);
            }
          },
        ),
      ],
    );
  }

  Future<void> _accept(ZyraSampleRequest request) async {
    if (!_samples.canAccept(request)) return;
    if (_samples.hasSparePlace) {
      final preparing = _samples.accept(request);
      if (preparing != null) _showPreparation(preparing);
      return;
    }
    final choices = _samples.capacityChoices(request);
    if (choices.isEmpty) return;
    final expectedGeneration = _samples.generation;
    final expectedCapacity = _samples.capacity;
    final expectedPlaces = _samples.placesUsed;
    final expectedActiveIds = _samples.activeRows
        ?.map((row) => row.id)
        .join(',');
    ZyraSampleJourney? selected;
    final preparing = await Navigator.of(context).push<ZyraSampleJourney>(
      MaterialPageRoute<ZyraSampleJourney>(
        builder: (routeContext) => Scaffold(
          body: ListenableBuilder(
            listenable: _samples,
            builder: (context, _) {
              bool present() =>
                  _samples.isCurrentLease(expectedGeneration) &&
                  _samples.capacity == expectedCapacity &&
                  _samples.placesUsed == expectedPlaces &&
                  _samples.activeRows?.map((row) => row.id).join(',') ==
                      expectedActiveIds &&
                  _samples.isRequestCurrent(request);
              if (!present()) return const _SampleBack();
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: StatefulBuilder(
                    builder: (context, setState) => ZyraRequestCapacityChoice(
                      firstName: request.person.firstName,
                      capacity: _samples.capacity,
                      selectedId: selected?.id,
                      items: [
                        for (final row in choices)
                          ZyraRequestCapacityItem(
                            id: row.id,
                            name: _name(row.person),
                            subtitle: '${row.person.age} · ${row.person.city}',
                            portrait: ZyraProfileImage(
                              _samples.profileFor(row.person).photoUrl,
                              width: 52,
                              height: 52,
                            ),
                          ),
                      ],
                      onSelected: (id) {
                        if (_foreground(context) && present()) {
                          setState(
                            () => selected = choices.firstWhere(
                              (row) => row.id == id,
                            ),
                          );
                        }
                      },
                      onContinue: selected == null
                          ? null
                          : () async {
                              final ending = selected!;
                              if (!_foreground(context) || !present()) return;
                              final confirmed = await showZyraConfirm(
                                context: context,
                                title: 'End this Journey and continue?',
                                body:
                                    'Your Journey with ${ending.person.firstName} ends and a place opens for ${request.person.firstName}.',
                                primaryLabel: 'End and continue',
                                secondaryLabel: 'Keep Journey',
                                canConfirm: present,
                                visibilityListenable: _samples,
                                isVisible: () =>
                                    _samples.isCurrentLease(expectedGeneration),
                              );
                              if (confirmed != true ||
                                  !context.mounted ||
                                  !_foreground(context) ||
                                  !present()) {
                                return;
                              }
                              final preparing = _samples.accept(
                                request,
                                replace: ending,
                              );
                              if (preparing != null) {
                                Navigator.of(context).pop(preparing);
                              }
                            },
                      onCancel: () {
                        if (_foreground(context)) Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    if (preparing != null &&
        mounted &&
        _current() &&
        _samples.isCurrentLease(expectedGeneration)) {
      _showPreparation(preparing);
    }
  }

  void _showPreparation(ZyraSampleJourney row) {
    _expansion.collapseAll();
    _openSampleJourney(context, row);
  }

  List<Widget> _past() {
    final rows = _samples.history ?? const [];
    if (rows.isEmpty) {
      return const [
        ZyraRequestActivityEmpty(
          icon: Icons.history_rounded,
          title: 'No past requests.',
          message:
              'Requests that were declined, expired or cancelled stay here.',
        ),
      ];
    }
    final groups = <(String, bool), List<ZyraSamplePastRequest>>{};
    for (final row in rows) {
      (groups[(row.request.person.id, row.request.incoming)] ??= []).add(row);
    }
    return [for (final group in groups.values) _pastCard(group)];
  }

  Widget _pastCard(List<ZyraSamplePastRequest> group) {
    final generation = _samples.generation;
    final latest = group.first;
    final request = latest.request;
    final id = 'sample-past-${request.person.id}-${request.incoming}';
    final direction = request.incoming ? 'Received' : 'Sent';
    final grouped = group.length > 1;
    final askAgain = grouped ? _samples.pastRequestAskAgainAfter(latest) : null;
    return ZyraPastRequestActivityCard(
      key: ValueKey(id),
      cardId: id,
      profile: _samples.profileFor(request.person),
      subtitle: grouped
          ? 'Last ${direction.toLowerCase()} ${_date(request.date)} · ${group.length} requests'
          : '$direction ${_date(request.date)}',
      status: latest.label,
      controller: grouped ? _expansion : null,
      canInteract: () =>
          _current() &&
          _samples.isCurrentLease(generation) &&
          _tab == 2 &&
          (_samples.history?.contains(latest) ?? false),
      history: grouped
          ? [
              for (final row in group)
                (
                  date: '$direction ${_date(row.request.date)}',
                  status: row.label,
                ),
            ]
          : const [],
      askAgain: askAgain != null
          ? 'You can ask ${request.person.firstName} again from ${_date(askAgain)}.'
          : null,
    );
  }
}

class ZyraSampleEndedJourneyCard extends StatelessWidget {
  const ZyraSampleEndedJourneyCard({super.key, required this.row});
  final ZyraSampleJourney row;

  bool _present() => _samples.endedRows?.contains(row) ?? false;

  Future<void> _options(BuildContext context, int generation) async {
    bool current() => _samples.isCurrentLease(generation) && _present();
    if (!_foreground(context) || !current()) return;
    final action = await showModalBottomSheet<ZyraEndedJourneyAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x611E1610),
      builder: (context) => ListenableBuilder(
        listenable: _samples,
        builder: (context, _) => !current()
            ? const SizedBox.shrink()
            : ZyraEndedJourneyMenu(
                restartEnabled: _samples.mayRestart(row),
                onSelect: (action) {
                  if (_foreground(context) && current()) {
                    Navigator.of(context).pop(action);
                  }
                },
              ),
      ),
    );
    if (!context.mounted ||
        !_foreground(context) ||
        !current() ||
        action == null) {
      return;
    }
    if (action == ZyraEndedJourneyAction.restart) {
      await _restart(context, generation);
      return;
    }
    final confirm = await showZyraConfirm(
      context: context,
      title: 'Remove this Journey?',
      body:
          'It disappears from your Ended Journeys for good, with its Timeline and messages. You can’t undo this. ${row.person.firstName} still sees her copy.',
      primaryLabel: 'Remove Journey',
      secondaryLabel: 'Keep Journey',
      canConfirm: current,
      visibilityListenable: _samples,
      isVisible: current,
    );
    if (confirm == true &&
        context.mounted &&
        _foreground(context) &&
        current() &&
        _samples.removeEnded(row)) {
      _notice(context, 'Removed from your Journeys.');
    }
  }

  Future<void> _restart(BuildContext context, int generation) async {
    bool current() => _samples.isCurrentLease(generation) && _present();
    if (!_foreground(context) || !current() || !_samples.mayRestart(row)) {
      return;
    }
    final confirm = await showZyraConfirm(
      context: context,
      title: 'Request a new Journey?',
      body: 'Send a new Journey request to ${row.person.firstName}.',
      primaryLabel: 'Send request',
      secondaryLabel: 'Keep Journey',
      canConfirm: () => current() && _samples.mayRestart(row),
      visibilityListenable: _samples,
      isVisible: current,
    );
    if (confirm == true &&
        context.mounted &&
        _foreground(context) &&
        current() &&
        _samples.restart(row)) {
      _notice(context, 'Journey request sent.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final generation = _samples.generation;
    bool current() => _samples.isCurrentLease(generation) && _present();
    final actions = ZyraOneJourneyConnectionsActionDeck(
      primary: ZyraOneJourneyConnectionsAction(
        label: 'Request restart',
        icon: null,
        fitLabel: true,
        onTap: _samples.mayRestart(row)
            ? () => _restart(context, generation)
            : null,
      ),
      primaryTrailing: ZyraConceptJourneyOptionsButton(
        onTap: () => _options(context, generation),
      ),
    );
    return ZyraOneJourneyConnectionsActiveCard(
      profile: _samples.profileFor(row.person),
      stateLabel: 'Ended · Timeline kept',
      stageLabel: ZyraJourneyStages.labelFor(row.stage),
      actions: actions,
      primaryAction: actions.primaryRow,
      onPhotoTap: () => _showProfile(context, row.person, current),
      bottomGap: 0,
    );
  }
}

void _openSampleJourney(BuildContext context, ZyraSampleJourney row) {
  if (!_foreground(context) || !(_samples.activeRows?.contains(row) ?? false)) {
    return;
  }
  final lease = _samples.generation;
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => _SampleJourneyScreen(attemptId: row.id, lease: lease),
    ),
  );
}

class _SampleJourneyScreen extends StatelessWidget {
  const _SampleJourneyScreen({required this.attemptId, required this.lease});
  final String attemptId;
  final int lease;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _SamplePageCanvas(
      child: ListenableBuilder(
        listenable: _samples,
        builder: (context, _) {
          final row = _samples.activeRows
              ?.where((row) => row.id == attemptId)
              .firstOrNull;
          if (row == null || !_samples.isCurrentLease(lease)) {
            return const _SampleBack();
          }
          final person = row.person;
          final ownReady = _samples.ready(row, peer: false);
          final peerReady = _samples.ready(row, peer: true);
          final stage = ZyraJourneyStages.of(row.stage);
          bool present() =>
              _samples.isCurrentLease(lease) &&
              (_samples.activeRows?.contains(row) ?? false);
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 10),
                  child: Row(
                    children: [
                      const BackButton(),
                      Expanded(
                        child: ZyraDeveloperTitle(
                          child: Text(
                            'Journey with ${person.firstName}',
                            style: ZyraText.pageTitle(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const ScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (row.preparing) ...[
                        Text(
                          'Choose to begin, together.',
                          style: ZyraText.heading(size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You both accepted the invitation. Each person still chooses to begin. Until then, no conversation or private compatibility result opens.',
                          style: ZyraText.subtext(size: 14),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You: ${ownReady ? 'ready' : 'not yet confirmed'}',
                          style: ZyraText.body(
                            size: 14,
                            color: ZyraColors.accentOnCanvas,
                          ),
                        ),
                        Text(
                          '${person.firstName}: ${peerReady ? 'ready' : 'waiting'}',
                          style: ZyraText.subtext(size: 14),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: ownReady
                              ? null
                              : () {
                                  if (_foreground(context) && present()) {
                                    _samples.markReady(row, peer: false);
                                  }
                                },
                          child: Text(
                            ownReady ? 'You are ready' : 'I’m ready to begin',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: peerReady
                              ? null
                              : () {
                                  if (_foreground(context) && present()) {
                                    _samples.markReady(row, peer: true);
                                  }
                                },
                          child: Text(
                            'Demo: ${person.firstName} confirms readiness',
                          ),
                        ),
                        FilledButton(
                          onPressed: ownReady && peerReady
                              ? () {
                                  if (_foreground(context) && present()) {
                                    _samples.begin(row);
                                  }
                                }
                              : null,
                          child: const Text('Begin your Journey'),
                        ),
                      ] else if (stage != null) ...[
                        Text(stage.label, style: ZyraText.heading(size: 26)),
                        const SizedBox(height: 12),
                        Text(
                          stage.introduction,
                          style: ZyraText.subtext(size: 14),
                        ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () async {
                          if (!_foreground(context) || !present()) return;
                          final confirmed = await _confirmEnd(
                            context,
                            row,
                            present,
                            lease,
                          );
                          if (confirmed &&
                              context.mounted &&
                              _foreground(context) &&
                              present() &&
                              _samples.endActive(row)) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('End Journey'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Future<bool> _confirmEnd(
  BuildContext context,
  ZyraSampleJourney row,
  bool Function() present,
  int lease,
) async =>
    await showZyraConfirm(
      context: context,
      title: 'End this Journey?',
      body: row.preparing
          ? 'Your Journey with ${row.person.firstName} ends before it begins. Your place is free.'
          : 'Your Journey with ${row.person.firstName} will move to Ended Journeys.',
      primaryLabel: 'End Journey',
      secondaryLabel: 'Keep Journey',
      canConfirm: present,
      visibilityListenable: _samples,
      isVisible: () => _samples.isCurrentLease(lease),
    ) ==
    true;

class _SampleRouteTitle extends StatelessWidget {
  const _SampleRouteTitle({required this.title});
  final Widget title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const BackButton(),
      Expanded(child: ZyraDeveloperTitle(child: title)),
    ],
  );
}

class _SampleBack extends StatelessWidget {
  const _SampleBack();

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.ivoryTop,
    child: const SafeArea(
      child: Align(alignment: Alignment.topLeft, child: BackButton()),
    ),
  );
}

class _SamplePageCanvas extends StatelessWidget {
  const _SamplePageCanvas({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: ZyraColors.genderGradient(AppState.instance.gender),
    ),
    child: child,
  );
}

class ZyraSampleActiveJourneyCard extends StatelessWidget {
  const ZyraSampleActiveJourneyCard({super.key, required this.row});
  final ZyraSampleJourney row;

  @override
  Widget build(BuildContext context) {
    final lease = _samples.generation;
    bool present() =>
        _samples.isCurrentLease(lease) &&
        (_samples.activeRows?.contains(row) ?? false);
    return ZyraOneJourneyConnectionsActiveCard(
      profile: _samples.profileFor(row.person),
      stageLabel: row.preparing
          ? 'Preparing'
          : ZyraJourneyStages.labelFor(row.stage),
      primaryAction: OutlinedButton(
        onPressed: () {
          if (present()) _openSampleJourney(context, row);
        },
        child: const Text('Continue Journey'),
      ),
      actions: Row(
        children: [
          TextButton(
            onPressed: () => _showProfile(context, row.person, present),
            child: const Text('View profile'),
          ),
          TextButton(
            onPressed: () async {
              if (!_foreground(context) || !present()) return;
              final confirmed = await _confirmEnd(context, row, present, lease);
              if (confirmed &&
                  context.mounted &&
                  _foreground(context) &&
                  present()) {
                _samples.endActive(row);
              }
            },
            child: const Text('End Journey'),
          ),
        ],
      ),
    );
  }
}

class ZyraSampleIntroductionsList extends StatelessWidget {
  const ZyraSampleIntroductionsList({
    super.key,
    required this.wrapTitle,
    this.tabClearance = false,
  });
  final Widget Function(Widget) wrapTitle;
  final bool tabClearance;

  @override
  Widget build(BuildContext context) {
    final lease = _samples.generation;
    final rows = _samples.introductionRows ?? const [];
    const guardians = [
      'Hassan · Father',
      'Khadija · Mother',
      'Yusuf · Brother',
    ];
    return _SamplePageCanvas(
      child: ZyraRequestActivityPresentation(
        title: 'Introductions',
        wrapTitle: wrapTitle,
        tabClearance: tabClearance,
        labels: const ['Introductions'],
        selectedIndex: 0,
        onChanged: (_) {},
        pages: [
          [
            if (rows.isEmpty)
              const ZyraRequestActivityEmpty(
                icon: Icons.groups_outlined,
                title: 'No introductions yet',
                message: 'People your Guardians put forward will appear here.',
              ),
            for (final (index, person) in rows.indexed)
              _SamplePersonCard(
                person: person,
                subtitle: 'Put forward by ${guardians[index]}',
                detail: index == 0
                    ? 'New introduction'
                    : 'Introduced ${9 - index} Nov',
                accentDetail: index == 0,
                onOpen: () => _showProfile(
                  context,
                  person,
                  () =>
                      _samples.isCurrentLease(lease) &&
                      _samples.hasIntroduction(person),
                  suggestedBy: guardians[index],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SamplePersonCard extends StatelessWidget {
  const _SamplePersonCard({
    required this.person,
    required this.subtitle,
    required this.onOpen,
    this.detail,
    this.accentDetail = false,
  });
  final DraftProfile person;
  final String subtitle;
  final String? detail;
  final bool accentDetail;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 26,
    circle: false,
    gold: false,
    child: Material(
      color: ZyraColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: ZyraColors.surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipOval(
                child: ZyraProfileImage(
                  _samples.profileFor(person).photoUrl,
                  width: 58,
                  height: 58,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name(person), style: ZyraText.heading(size: 21)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: ZyraText.subtext(size: 12)),
                    if (detail != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        detail!,
                        style: ZyraText.subtext(
                          size: 12,
                          color: accentDetail
                              ? ZyraColors.accentOnCanvas
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
