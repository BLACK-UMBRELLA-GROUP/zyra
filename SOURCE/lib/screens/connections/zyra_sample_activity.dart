import 'package:flutter/material.dart';

import '../../data/zyra_journey_stages.dart';
import '../../dev/zyra_draft_timeline_presentation.dart';
import '../../dev/zyra_full_profile_preview.dart';
import '../../dev/zyra_draft_browse_utility_presentation.dart';
import '../../dev/zyra_draft_compatibility_presentation.dart';
import '../../dev/zyra_draft_compatibility_preview.dart';
import '../../dev/zyra_help_safety_preview.dart';
import '../../dev/zyra_draft_timeline_preview.dart';
import '../../dev/zyra_one_journey_discovery_presentation.dart';
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
import 'connections_section_controller.dart';

final _samples = ZyraDeveloperSamples.instance;

void _sampleCompatibility(
  BuildContext context,
  DraftProfile person,
  bool Function() current,
) {
  if (!current()) return;
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: _SamplePageCanvas(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: ZyraDraftCompatibilityPresentation(
                personName: person.firstName,
                balance: 0,
                overallScore: ZyraDraftCompatibilityPreview(
                  person.id,
                  balance: 0,
                ).overallScore,
                revealed: false,
                canAct: current,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _sampleProfileOption(
  BuildContext profileContext,
  BuildContext originContext,
  DraftProfile person,
  ZyraFullProfileOption option,
  bool Function() current,
) async {
  if (!current() || !_samples.isSampleProfileVisible(person.id)) return;
  final lease = _samples.generation;
  if (option == ZyraFullProfileOption.report) {
    Navigator.of(profileContext).push<void>(
      MaterialPageRoute<void>(
        builder: (reportContext) => Scaffold(
          body: _SamplePageCanvas(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: ZyraDraftReportPresentation(
                  profile: _samples.profileFor(person),
                  ownerIdentity: (_samples.generation, person.id),
                  canSelect: current,
                  onSubmit: () {
                    if (!current()) return;
                    Navigator.of(reportContext).push<void>(
                      MaterialPageRoute<void>(
                        builder: (doneContext) => Scaffold(
                          body: _SamplePageCanvas(
                            child: ZyraHelpSafetyPreview(
                              screen: ZyraHelpSafetyScreen.reportSent,
                              guardian: false,
                              firstName: '',
                              reportedName: person.firstName,
                              onReportDone: () {
                                if (!current()) return;
                                Navigator.of(doneContext).pop();
                                Navigator.of(reportContext).pop();
                              },
                              onBlockReported: () {
                                if (!current()) return;
                                Navigator.of(doneContext).pop();
                                Navigator.of(reportContext).pop();
                                _sampleProfileOption(
                                  profileContext,
                                  originContext,
                                  person,
                                  ZyraFullProfileOption.block,
                                  current,
                                );
                              },
                              onContactSent: () {},
                              onOpenData: () {},
                              onOpenDelete: () {},
                              onRequestData: () {},
                              onDelete: () {},
                              onClose: () {},
                              onDone: () {},
                              onLegal: (_) {},
                              onSubscriptions: () {},
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  final hide = option == ZyraFullProfileOption.hide;
  final journey = (_samples.activeRows ?? const <ZyraSampleJourney>[])
      .where((row) => row.person.id == person.id)
      .firstOrNull;
  if (journey != null) {
    final confirmed = await showZyraConfirm(
      context: profileContext,
      title:
          '${hide ? 'Hide' : 'Block'} ${person.firstName} and end your Journey?',
      body: hide
          ? 'Hiding ends this Journey permanently first. Your Timeline stays. ${person.firstName} won’t appear again. You can undo this in Settings → Hidden and blocked.'
          : 'Blocking ends this Journey permanently first. Your Timeline stays. ${person.firstName} can’t see or contact you and won’t be told you blocked them.',
      primaryLabel: hide ? 'End Journey and hide' : 'End Journey and block',
      secondaryLabel: 'Keep this Journey',
      canConfirm: () =>
          current() && (_samples.activeRows?.contains(journey) ?? false),
      visibilityListenable: _samples,
      isVisible: current,
    );
    if (!profileContext.mounted ||
        confirmed != true ||
        !current() ||
        !_samples.endActive(journey)) {
      return;
    }
  }
  if (!profileContext.mounted || !_samples.isCurrentLease(lease)) {
    return;
  }
  final changed = hide
      ? _samples.hideSampleProfile(person)
      : _samples.blockSampleProfile(person);
  if (!changed) return;
  Navigator.of(profileContext).pop();
  if (originContext.mounted) {
    _notice(
      originContext,
      journey == null
          ? hide
                ? 'Hidden. You can show them again in Settings → Hidden and blocked.'
                : 'Blocked. They can no longer see you or contact you.'
          : hide
          ? 'Your Journey with ${person.firstName} has ended. ${person.firstName} won’t appear again.'
          : 'Your Journey with ${person.firstName} has ended and ${person.firstName} is blocked.',
    );
  }
}

bool _foreground(BuildContext context) =>
    context.mounted && (ModalRoute.of(context)?.isCurrent ?? true);

void _showProfile(
  BuildContext context,
  DraftProfile person,
  bool Function() current, {
  String? suggestedBy,
  ZyraFullProfileSituation situation = ZyraFullProfileSituation.general,
  VoidCallback? onAction,
  ValueChanged<BuildContext>? onActionFromProfile,
  VoidCallback? onSecondary,
}) {
  if (!_foreground(context) || !current()) return;
  final originContext = context;
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: false,
      builder: (_) => ListenableBuilder(
        listenable: _samples,
        builder: (context, _) => !current()
            ? const Scaffold(body: _SampleBack())
            : ZyraFullProfilePreview(
                profile: _samples.profileFor(person),
                situation: situation,
                introductionByline: suggestedBy,
                canAct: current,
                photoBuilder:
                    (
                      context,
                      source, {
                      required width,
                      required height,
                      required alignment,
                    }) => ZyraProfileImage(
                      source.startsWith('data:image/') ? source : '',
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      alignment: alignment,
                    ),
                onAction: onActionFromProfile == null
                    ? onAction
                    : () => onActionFromProfile(context),
                onSecondary: onSecondary,
                onCompatibility: () =>
                    _sampleCompatibility(context, person, current),
                onOption: (option) => _sampleProfileOption(
                  context,
                  originContext,
                  person,
                  option,
                  current,
                ),
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
    this.sentCount,
    this.additionalSent,
  });

  final bool tabClearance;
  final int initialTab;
  final ValueChanged<int>? onTabChanged;
  final Widget Function(Widget)? wrapTitle;
  final Widget Function()? sentCount;
  final List<Widget> Function()? additionalSent;

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
    final count = incoming ? null : widget.sentCount?.call();
    final extra = incoming
        ? const <Widget>[]
        : widget.additionalSent?.call() ?? const [];
    if (rows.isEmpty && extra.isEmpty) {
      return [
        ?count,
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
    return [
      ?count,
      ...extra,
      for (final request in rows) _requestCard(request),
    ];
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
          ? request.suggestedByOwnGuardian
                ? 'Suggested by ${request.person.firstName}’s Guardian'
                : 'Journey request'
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
        onTap: () => _showProfile(
          context,
          request.person,
          present,
          situation: request.incoming
              ? ZyraFullProfileSituation.received
              : ZyraFullProfileSituation.sent,
          onAction: request.incoming && _samples.canAccept(request)
              ? () {
                  if (!present()) return;
                  Navigator.of(context).pop();
                  _accept(request);
                }
              : null,
          onSecondary: request.incoming
              ? () async {
                  if (!present()) return;
                  final confirmed = await showZyraConfirm(
                    context: context,
                    title: 'Decline this request?',
                    body: 'This Journey request moves to Past.',
                    primaryLabel: 'Decline',
                    secondaryLabel: 'Keep request',
                    canConfirm: present,
                    visibilityListenable: _samples,
                    isVisible: visible,
                  );
                  if (!mounted ||
                      !context.mounted ||
                      confirmed != true ||
                      !present()) {
                    return;
                  }
                  if (_samples.declineOrCancel(request)) {
                    Navigator.of(context).pop();
                    _expansion.close(id);
                  }
                }
              : null,
        ),
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
          icon: Icons.history_outlined,
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
  const ZyraSampleEndedJourneyCard({
    super.key,
    required this.row,
    required this.controller,
    this.onViewArchive,
    this.admitRestart,
  });
  final ZyraSampleJourney row;
  final ZyraConnectionsExpansionController controller;
  final VoidCallback? onViewArchive;
  final bool Function(BuildContext)? admitRestart;

  bool _present() => _samples.endedRows?.contains(row) ?? false;

  Future<void> _remove(BuildContext context, int generation) async {
    bool current() => _samples.isCurrentLease(generation) && _present();
    if (!_foreground(context) || !current()) return;
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

  void _archive(BuildContext context, int generation) {
    if (!_foreground(context) ||
        !_samples.isCurrentLease(generation) ||
        !_present()) {
      return;
    }
    if (onViewArchive case final open?) {
      open();
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: ZyraSampleEndedJourneyArchive(
            row: row,
            wrapTitle: (title) => _SampleRouteTitle(title: title),
          ),
        ),
      ),
    );
  }

  Future<void> _restart(BuildContext context, int generation) async {
    bool current() => _samples.isCurrentLease(generation) && _present();
    if (!_foreground(context) ||
        !current() ||
        !_samples.mayRestart(row) ||
        admitRestart?.call(context) == false) {
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
        admitRestart?.call(context) != false &&
        _samples.restart(row)) {
      _notice(context, 'Journey request sent.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final generation = _samples.generation;
    bool current() => _samples.isCurrentLease(generation) && _present();
    final id = 'sample-ended-${row.id}';
    return ZyraRequestActivityCard(
      key: ValueKey(id),
      headerKey: ValueKey('$id-header'),
      profile: _samples.profileFor(row.person),
      subtitle: 'Journey ended · Timeline kept',
      cardId: id,
      controller: controller,
      canInteract: () => _foreground(context) && current(),
      onToggle: () {
        if (!_foreground(context) || !current()) return;
        if (controller.value == id) {
          controller.close(id);
        } else {
          controller.open(id);
        }
      },
      primary: ZyraOneJourneyConnectionsAction(
        label: 'View Timeline',
        icon: Icons.history_outlined,
        onTap: () => _archive(context, generation),
      ),
      actions: [
        ZyraOneJourneyConnectionsAction(
          label: 'Request a new Journey',
          icon: Icons.people_outline,
          onTap: _samples.mayRestart(row)
              ? () => _restart(context, generation)
              : null,
        ),
        ZyraOneJourneyConnectionsAction(
          label: 'Remove from my Journeys',
          icon: Icons.close,
          dangerLabel: true,
          onTap: () => _remove(context, generation),
        ),
      ],
    );
  }
}

/// The caller owns the archive route and its real navigation. Only this
/// selected sample attempt is projected; a later attempt cannot replace it.
class ZyraSampleEndedJourneyArchive extends StatefulWidget {
  const ZyraSampleEndedJourneyArchive({
    super.key,
    required this.row,
    required this.wrapTitle,
    this.tabClearance = false,
    this.canInteract,
  });
  final ZyraSampleJourney row;
  final Widget Function(Widget) wrapTitle;
  final bool tabClearance;
  final bool Function()? canInteract;

  @override
  State<ZyraSampleEndedJourneyArchive> createState() =>
      _ZyraSampleEndedJourneyArchiveState();
}

class _ZyraSampleEndedJourneyArchiveState
    extends State<ZyraSampleEndedJourneyArchive> {
  late final ZyraSampleJourney row;
  late final int generation;
  final _sourceLifetime = ValueNotifier(true);
  late final _archiveListenable = Listenable.merge([_samples, _sourceLifetime]);

  @override
  void initState() {
    super.initState();
    row = widget.row;
    generation = _samples.generation;
  }

  bool _present() =>
      mounted &&
      _sourceLifetime.value &&
      identical(widget.row, row) &&
      (_samples.endedRows?.contains(row) ?? false);

  @override
  void dispose() {
    final lifetime = _sourceLifetime;
    // A detail route can outlive its source page. Withdraw it after the
    // source's frame is unlocked rather than notifying during disposal.
    // The value remains owned by any pushed detail until that route retires.
    Future<void>.microtask(() {
      lifetime.value = false;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SamplePageCanvas(
    child: ListenableBuilder(
      listenable: _samples,
      builder: (context, _) =>
          !_samples.isCurrentLease(generation) || !_present()
          ? const _SampleBack()
          : ZyraEndedJourneyArchivePresentation(
              profile: _samples.profileFor(row.person),
              wrapTitle: widget.wrapTitle,
              tabClearance: widget.tabClearance,
              canInteract: () =>
                  _foreground(context) &&
                  (widget.canInteract?.call() ?? true) &&
                  _samples.isCurrentLease(generation) &&
                  _present(),
              onTimeline: () => _archiveDetail(context, generation, 0),
              onBio: () => _archiveDetail(context, generation, 1),
              onGuardians: () => _archiveDetail(context, generation, 2),
            ),
    ),
  );

  void _archiveDetail(BuildContext context, int generation, int page) {
    bool present() => _samples.isCurrentLease(generation) && _present();
    if (!_foreground(context) ||
        !present() ||
        widget.canInteract?.call() == false) {
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: _SamplePageCanvas(
            child: ListenableBuilder(
              listenable: _archiveListenable,
              builder: (context, _) {
                if (!present()) return const _SampleBack();
                if (page == 0) {
                  return SafeArea(
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton(),
                        ),
                        Expanded(
                          child: ZyraDraftTimelinePresentation(
                            subjectId: row.id,
                            firstName: row.person.firstName,
                            ownedViewport: true,
                            view: ZyraDraftTimelineView(
                              frozen: true,
                              entries: [
                                ZyraDraftTimelineEntry(
                                  type: 'journey_ended',
                                  occurredOn: row.endedAt,
                                  attemptId: row.id,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final bio = page == 1;
                return SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    children: [
                      _SampleRouteTitle(
                        title: Text(
                          bio ? 'Journey Bio' : 'Guardians',
                          style: ZyraText.pageTitle(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ZyraFloatingSurface(
                        circle: false,
                        gold: false,
                        radius: 22,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: ZyraColors.cardSurface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: ZyraColors.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bio
                                    ? 'Not shared in this Journey'
                                    : 'No saved Guardian details',
                                style: ZyraText.heading(size: 23),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                bio
                                    ? 'Journey Bio was not shared before this Journey ended. '
                                          'Opening its archive does not unlock private details.'
                                    : 'No Guardian details were saved in this archive. '
                                          'Today’s Guardian list is not a record of this past Journey.',
                                style: ZyraText.body(size: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
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
            onPressed: () => _showProfile(
              context,
              row.person,
              present,
              situation: ZyraFullProfileSituation.journey,
              onAction: () {
                if (!present()) return;
                Navigator.of(context).pop();
                _openSampleJourney(context, row);
              },
            ),
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

class ZyraSampleIntroductionsList extends StatefulWidget {
  const ZyraSampleIntroductionsList({
    super.key,
    required this.wrapTitle,
    this.tabClearance = false,
    this.admitRequest,
  });
  final Widget Function(Widget) wrapTitle;
  final bool tabClearance;
  final bool Function(BuildContext)? admitRequest;

  @override
  State<ZyraSampleIntroductionsList> createState() =>
      _ZyraSampleIntroductionsListState();
}

class _ZyraSampleIntroductionsListState
    extends State<ZyraSampleIntroductionsList> {
  final _expansion = ZyraConnectionsExpansionController();
  int _tab = 0;

  @override
  void dispose() {
    _expansion.dispose();
    super.dispose();
  }

  bool _current() => mounted && _foreground(context) && _samples.isAuthorized;

  @override
  Widget build(BuildContext context) => _SamplePageCanvas(
    child: ListenableBuilder(
      listenable: _samples,
      builder: (context, _) => !_samples.isAuthorized
          ? const _SampleBack()
          : ZyraRequestActivityPresentation(
              title: 'Introductions',
              selectedTabFill: ZyraColors.frostSelectedFill,
              wrapTitle: widget.wrapTitle,
              tabClearance: widget.tabClearance,
              labels: const ['Received', 'Past'],
              selectedIndex: _tab,
              canInteract: _current,
              onChanged: (tab) {
                if (!_current() || tab < 0 || tab > 1 || tab == _tab) return;
                _expansion.collapseAll();
                setState(() => _tab = tab);
              },
              pages: [_received(), _past()],
            ),
    ),
  );

  List<Widget> _received() {
    final rows = _samples.receivedIntroductions;
    if (rows.isEmpty) {
      return const [
        ZyraRequestActivityEmpty(
          icon: Icons.groups_outlined,
          title: 'No introductions yet',
          message: 'People your Guardians put forward will appear here.',
        ),
      ];
    }
    return [for (final introduction in rows) _receivedCard(introduction)];
  }

  Widget _receivedCard(ZyraSampleIntroduction introduction) {
    final person = introduction.person;
    final id = 'sample-introduction-${person.id}';
    final lease = _samples.generation;
    bool present() =>
        _samples.isCurrentLease(lease) && _samples.hasIntroduction(person);
    bool current() => _current() && _tab == 0 && present();
    return ZyraRequestActivityCard(
      key: ValueKey(id),
      headerKey: ValueKey('$id-header'),
      profile: _samples.profileFor(person),
      subtitle:
          'Put forward by ${introduction.guardianName} · ${introduction.relation}',
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
        onTap: () => _showProfile(
          context,
          person,
          present,
          suggestedBy:
              '${introduction.guardianName} · ${introduction.relation}',
          situation: ZyraFullProfileSituation.introduction,
          onActionFromProfile: (profileContext) {
            if (!present() ||
                !_samples.canRequestIntroduction(person) ||
                widget.admitRequest?.call(profileContext) == false ||
                !_samples.requestIntroduction(person)) {
              return;
            }
            Navigator.of(profileContext).pop();
            _expansion.collapseAll();
            _notice(
              context,
              'Request sent to ${person.firstName}. It’s in Journey requests → Sent.',
            );
          },
          onSecondary: () {
            if (!present() || !_samples.declineIntroduction(person)) return;
            Navigator.of(context).pop();
            _expansion.collapseAll();
            _notice(
              context,
              'Declined. ${introduction.guardianName} sees “Not taken forward”.',
            );
          },
        ),
      ),
      actions: [
        ZyraOneJourneyConnectionsAction(
          label: 'Request a Journey',
          icon: Icons.check,
          onTap: _samples.canRequestIntroduction(person)
              ? () {
                  if (!current() ||
                      !_samples.canRequestIntroduction(person) ||
                      widget.admitRequest?.call(context) == false ||
                      !_samples.requestIntroduction(person)) {
                    return;
                  }
                  _expansion.collapseAll();
                  _notice(
                    context,
                    'Request sent to ${person.firstName}. It’s in Journey requests → Sent.',
                  );
                }
              : null,
        ),
        ZyraOneJourneyConnectionsAction(
          label: 'Decline',
          icon: Icons.close,
          onTap: () {
            if (!current() || !_samples.declineIntroduction(person)) return;
            _expansion.collapseAll();
            _notice(
              context,
              'Declined. ${introduction.guardianName} sees “Not taken forward”.',
            );
          },
        ),
      ],
    );
  }

  List<Widget> _past() {
    final rows = _samples.pastIntroductions;
    if (rows.isEmpty) {
      return const [
        ZyraRequestActivityEmpty(
          icon: Icons.history_outlined,
          title: 'No past introductions.',
          message: 'Introductions you declined or took forward stay here.',
        ),
      ];
    }
    return [
      for (final row in rows)
        ZyraPastRequestActivityCard(
          key: ValueKey('sample-past-introduction-${row.sequence}'),
          cardId: 'sample-past-introduction-${row.sequence}',
          profile: _samples.profileFor(row.introduction.person),
          subtitle:
              'Introduced ${_date(row.introduction.introducedAt)} · from ${row.introduction.guardianName}',
          status: row.label,
        ),
    ];
  }
}
