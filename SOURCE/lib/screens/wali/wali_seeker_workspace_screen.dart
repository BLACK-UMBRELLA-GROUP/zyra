import '../../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';

import '../../services/zyra_account_state.dart';
import '../../services/zyra_guardian_seeker_roster_resolver.dart';
import '../../services/zyra_wali_journey_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_ward_card.dart';
import 'wali_journey_detail_screen.dart';

typedef GuardianAttemptSummaryLoader =
    Future<ZyraSourceResult<List<GuardianAttemptSummary>>> Function(
      String seekerId,
    );

class WaliSeekerWorkspaceScreen extends StatefulWidget {
  final GuardianSeekerRosterEntry entry;
  final bool hasGuardianOne;
  final String photoUrl;
  final GuardianAttemptSummaryLoader? loadSummaries;
  final bool embedded;
  final ValueChanged<WaliJourneyView>? onOpenJourney;
  final VoidCallback? onOpenNetwork;
  final VoidCallback? onOpenFamilyChat;

  const WaliSeekerWorkspaceScreen({
    super.key,
    required this.entry,
    this.hasGuardianOne = false,
    this.photoUrl = '',
    this.loadSummaries,
    this.embedded = false,
    this.onOpenJourney,
    this.onOpenNetwork,
    this.onOpenFamilyChat,
  });

  @override
  State<WaliSeekerWorkspaceScreen> createState() =>
      _WaliSeekerWorkspaceScreenState();
}

class _WaliSeekerWorkspaceScreenState extends State<WaliSeekerWorkspaceScreen> {
  bool _summaryLoading = false;
  bool _summaryUnavailable = false;
  bool _summaryLastKnown = false;
  List<GuardianAttemptSummary> _summaries = const [];
  late final String? _owner;
  late final int _generation;
  bool _revoked = false;
  int _summaryRequest = 0;

  bool get _ownerCurrent =>
      !_revoked &&
      !ZyraAccountState.isSigningOut &&
      ZyraAccountState.userId == _owner &&
      ZyraAccountState.generation == _generation;

  @override
  void initState() {
    super.initState();
    _owner = ZyraAccountState.userId;
    _generation = ZyraAccountState.generation;
    AppState.instance.addListener(_withdrawSupersededAccount);
    _loadSummaries();
  }

  void _withdrawSupersededAccount() {
    if (!mounted || _revoked || _ownerCurrent) return;
    setState(() {
      _revoked = true;
      _summaryRequest++;
      _summaries = const [];
      _summaryLoading = false;
      _summaryUnavailable = false;
      _summaryLastKnown = false;
    });
  }

  @override
  void didUpdateWidget(covariant WaliSeekerWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.person.id != widget.entry.person.id ||
        oldWidget.entry.person.isMain != widget.entry.person.isMain ||
        oldWidget.entry.person.linkedAt != widget.entry.person.linkedAt ||
        oldWidget.loadSummaries != widget.loadSummaries) {
      _summaries = const [];
      _summaryUnavailable = false;
      _summaryLastKnown = false;
      _loadSummaries();
    }
  }

  Future<void> _loadSummaries() async {
    // Every active Guardian receives the same narrow, server-confirmed
    // Journey-summary shape. Main-only actions and richer Journey context
    // remain independently authorised and are not inferred from this read.
    if (!mounted || !_ownerCurrent) return;
    final request = ++_summaryRequest;
    setState(() => _summaryLoading = true);
    final loader =
        widget.loadSummaries ??
        ZyraWaliJourneyService.fetchAttemptSummariesForSeeker;
    final seekerId = widget.entry.person.id;
    ZyraSourceResult<List<GuardianAttemptSummary>> result;
    try {
      result = await loader(seekerId);
    } catch (_) {
      result = const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
    if (!mounted || !_ownerCurrent || request != _summaryRequest) return;
    setState(() {
      _summaryLoading = false;
      if (result.isAvailable) {
        _summaries = result.valueOr(const []);
        _summaryUnavailable = false;
        _summaryLastKnown = false;
      } else {
        _summaryUnavailable = true;
        _summaryLastKnown = _summaries.isNotEmpty;
      }
    });
  }

  bool _bindingCurrent(WaliSeekerWorkspaceScreen binding) =>
      mounted && _ownerCurrent && identical(binding, widget);

  void _openJourney(
    WaliSeekerWorkspaceScreen binding,
    WaliJourneyView journey,
  ) {
    if (!_bindingCurrent(binding)) return;
    final callback = binding.onOpenJourney;
    if (callback != null) {
      callback(journey);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaliJourneyDetailScreen(
          journey: journey,
          hasGuardianOne: binding.hasGuardianOne,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ownerCurrent) {
      return const ZyraEmptyState(
        icon: Icons.lock_outline,
        message: 'Your account changed. Reopen Seekers.',
      );
    }
    final binding = widget;
    return GuardianSeekerWorkspaceView(
      entry: binding.entry,
      hasGuardianOne: binding.hasGuardianOne,
      photoUrl: binding.photoUrl,
      summaries: _summaries,
      summaryLoading: _summaryLoading,
      summaryUnavailable: _summaryUnavailable,
      summaryLastKnown: _summaryLastKnown,
      embedded: binding.embedded,
      onRetrySummary: () {
        if (_bindingCurrent(binding)) _loadSummaries();
      },
      onOpenJourney: (journey) => _openJourney(binding, journey),
      onOpenNetwork: binding.onOpenNetwork == null
          ? null
          : () {
              if (_bindingCurrent(binding)) binding.onOpenNetwork!();
            },
      onOpenFamilyChat: binding.onOpenFamilyChat == null
          ? null
          : () {
              if (_bindingCurrent(binding)) binding.onOpenFamilyChat!();
            },
    );
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_withdrawSupersededAccount);
    _summaryRequest++;
    super.dispose();
  }
}

/// Pure presentation for the thin role-aware workspace and visual gate.
class GuardianSeekerWorkspaceView extends StatelessWidget {
  final GuardianSeekerRosterEntry entry;
  final bool hasGuardianOne;
  final String photoUrl;
  final List<GuardianAttemptSummary> summaries;
  final bool summaryLoading;
  final bool summaryUnavailable;
  final bool summaryLastKnown;
  final bool embedded;
  final VoidCallback onRetrySummary;
  final ValueChanged<WaliJourneyView>? onOpenJourney;
  final VoidCallback? onOpenNetwork;
  final VoidCallback? onOpenFamilyChat;

  const GuardianSeekerWorkspaceView({
    super.key,
    required this.entry,
    this.hasGuardianOne = false,
    this.photoUrl = '',
    this.summaries = const [],
    this.summaryLoading = false,
    this.summaryUnavailable = false,
    this.summaryLastKnown = false,
    this.embedded = false,
    required this.onRetrySummary,
    this.onOpenJourney,
    this.onOpenNetwork,
    this.onOpenFamilyChat,
  });

  WaliLinkedPerson get _person => entry.person;

  @override
  Widget build(BuildContext context) {
    final relationship =
        _person.relationshipLabel ?? 'Relationship not recorded';
    final linkedDate = _person.linkedDateLabel ?? 'Linked date not recorded';
    if (embedded) {
      return _embeddedWorkspace(
        context,
        relationship: relationship,
        linkedDate: linkedDate,
      );
    }
    return Scaffold(
      body: Container(
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 20, 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: ZyraTapFeedback.onTap(
                        context,
                        () => Navigator.of(context).maybePop(),
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _person.firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZyraText.heading(size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const PageStorageKey('guardian-seeker-workspace'),
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                  children: [
                    ZyraWardCard(
                      name: _person.firstName,
                      photoUrl: photoUrl,
                      statusLine: relationship,
                      detailLine: _person.isMain
                          ? 'Main Guardian · $linkedDate'
                          : 'Additional Guardian · $linkedDate',
                    ),
                    const SizedBox(height: 10),
                    _WorkspaceSection(
                      title: 'ROLE & ACCESS',
                      child: Text(
                        _person.isMain
                            ? 'You are this Seeker’s current Main Guardian. '
                                  'You are always included in their active '
                                  'Journey and lead Guardian decisions.'
                            : 'You are an Additional Guardian. This workspace '
                                  'opens the current Journey only while this '
                                  'Seeker includes you. Their Main Guardian '
                                  'still leads protected decisions.',
                        style: ZyraText.subtext(size: 12.5),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _currentContext(context),
                    if (onOpenFamilyChat != null) ...[
                      const SizedBox(height: 14),
                      _WorkspaceSection(
                        title: 'GUARDIAN CIRCLE',
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: ValueKey('seeker-family-chat-${_person.id}'),
                            onPressed: ZyraTapFeedback.onTap(
                              context,
                              onOpenFamilyChat,
                            ),
                            icon: const Icon(Icons.forum_outlined),
                            label: Text(
                              'Enter ${_person.firstName}’s Guardian Circle',
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _journeySummary(context),
                    if (hasGuardianOne && onOpenNetwork != null) ...[
                      const SizedBox(height: 14),
                      _WorkspaceSection(
                        title: 'GUARDIAN NETWORK',
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: ZyraTapFeedback.onTap(
                              context,
                              onOpenNetwork,
                            ),
                            icon: const Icon(Icons.diversity_3_outlined),
                            label: Text('Open for ${_person.firstName}'),
                          ),
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
    );
  }

  Widget _embeddedWorkspace(
    BuildContext context, {
    required String relationship,
    required String linkedDate,
  }) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      key: PageStorageKey('guardian-seeker-page-scroll-${_person.id}'),
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _EmbeddedSeekerIdentity(
                name: _person.firstName,
                relationship: relationship,
                role: _person.isMain ? 'Main Guardian' : 'Additional Guardian',
                photoUrl: photoUrl,
              ),
              _QuietWorkspaceSection(
                label: 'DETAILS',
                child: Column(
                  children: [
                    const _QuietWorkspacePair(
                      label: 'Status',
                      value: 'Active',
                      signal: true,
                    ),
                    _QuietWorkspacePair(label: 'Linked', value: linkedDate),
                  ],
                ),
              ),
              _QuietWorkspaceSection(
                label: 'JOURNEY ACCESS',
                child: _embeddedJourneyAccess(context),
              ),
              if (onOpenFamilyChat != null)
                _QuietWorkspaceSection(
                  label: 'GUARDIAN CIRCLE',
                  child: _QuietWorkspaceAction(
                    key: ValueKey('seeker-family-chat-${_person.id}'),
                    icon: Icons.forum_outlined,
                    label: 'Enter ${_person.firstName}’s Guardian Circle',
                    onTap: onOpenFamilyChat,
                  ),
                ),
              _QuietWorkspaceSection(
                label: 'JOURNEY SUMMARY',
                child: _journeySummaryBody(context),
              ),
              if (hasGuardianOne && onOpenNetwork != null)
                _QuietWorkspaceSection(
                  label: 'GUARDIAN NETWORK',
                  child: _QuietWorkspaceAction(
                    icon: Icons.diversity_3_outlined,
                    label: 'Open for ${_person.firstName}',
                    onTap: onOpenNetwork,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _embeddedJourneyAccess(BuildContext context) {
    final journey = entry.currentJourney;
    return Column(
      children: [
        _QuietWorkspacePair(
          label: 'Role',
          value: _person.isMain ? 'Main Guardian' : 'Additional Guardian',
        ),
        _QuietWorkspacePair(
          label: 'Current',
          value: journey == null ? 'No current Journey' : entry.contextLine,
        ),
        if (journey != null && onOpenJourney != null) ...[
          const SizedBox(height: 10),
          _QuietWorkspaceAction(
            icon: Icons.route_outlined,
            label: 'Open current Journey',
            onTap: () => onOpenJourney!(journey),
          ),
        ],
      ],
    );
  }

  Widget _currentContext(BuildContext context) {
    final journey = entry.currentJourney;
    return _WorkspaceSection(
      title: 'CURRENT CONTEXT',
      child: journey == null
          ? Text('No current Journey', style: ZyraText.subtext(size: 12.5))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.contextLine, style: ZyraText.body(size: 14)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: ZyraTapFeedback.onTap(
                      context,
                      onOpenJourney == null
                          ? null
                          : () => onOpenJourney!(journey),
                    ),
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Open current Journey'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _journeySummary(BuildContext context) {
    return _WorkspaceSection(
      title: 'JOURNEY SUMMARY',
      child: _journeySummaryBody(context),
    );
  }

  Widget _journeySummaryBody(BuildContext context) {
    final rows = <Widget>[];
    if (summaryUnavailable) {
      rows.add(
        ZyraErrorBanner(
          message: summaryLastKnown
              ? 'Journey summaries could not refresh. Showing last confirmed rows.'
              : 'Journey summaries are unavailable right now.',
          onRetry: onRetrySummary,
        ),
      );
      if (summaryLastKnown) rows.add(const SizedBox(height: 10));
    }
    if (summaryLoading && summaries.isEmpty) {
      rows.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ZyraLoading(label: 'Loading Journey summaries…'),
        ),
      );
    } else if (!summaryUnavailable && summaries.isEmpty) {
      rows.add(
        Text(
          'No Journey summaries are available.',
          style: ZyraText.subtext(size: 12.5),
        ),
      );
    }
    if (summaries.isNotEmpty) {
      rows.addAll([
        for (var index = 0; index < summaries.length; index++) ...[
          _AttemptSummaryCard(
            summary: summaries[index],
            currentJourney: entry.currentJourney,
            onOpenJourney: onOpenJourney,
          ),
          if (index != summaries.length - 1) const SizedBox(height: 8),
        ],
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _EmbeddedSeekerIdentity extends StatelessWidget {
  const _EmbeddedSeekerIdentity({
    required this.name,
    required this.relationship,
    required this.role,
    required this.photoUrl,
  });

  final String name;
  final String relationship;
  final String role;
  final String photoUrl;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        ClipOval(
          child: SizedBox.square(
            dimension: 64,
            child: ZyraProfileImage(photoUrl, width: 64, height: 64),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: ZyraText.heading(size: 26)),
              const SizedBox(height: 3),
              Text(
                '$relationship · $role',
                style: ZyraText.subtext(
                  size: 12.5,
                  color: ZyraColors.ink(0.58),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuietWorkspaceSection extends StatelessWidget {
  const _QuietWorkspaceSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: ZyraColors.ink(0.13))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ZyraText.chapterLabel(color: ZyraColors.ink(0.47))),
        const SizedBox(height: 7),
        child,
      ],
    ),
  );
}

class _QuietWorkspacePair extends StatelessWidget {
  const _QuietWorkspacePair({
    required this.label,
    required this.value,
    this.signal = false,
  });

  final String label;
  final String value;
  final bool signal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ZyraText.subtext(size: 12.5, color: ZyraColors.ink(0.46)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: ZyraText.body(
              size: 13,
              color: signal ? ZyraColors.journeyGold : ZyraColors.foreground,
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuietWorkspaceAction extends StatelessWidget {
  const _QuietWorkspaceAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: ZyraTapFeedback.onTap(context, onTap),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 45),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZyraColors.ink(0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: ZyraColors.ink(0.68)),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: ZyraText.body(size: 13),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WorkspaceSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _WorkspaceSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ZyraColors.surfaceBorder, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ZyraText.subtext(
            size: 10.5,
            color: ZyraColors.foreground.withValues(alpha: 0.58),
          ).copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        child,
      ],
    ),
  );
}

class _AttemptSummaryCard extends StatelessWidget {
  final GuardianAttemptSummary summary;
  final WaliJourneyView? currentJourney;
  final ValueChanged<WaliJourneyView>? onOpenJourney;

  const _AttemptSummaryCard({
    required this.summary,
    required this.currentJourney,
    required this.onOpenJourney,
  });

  bool get _canOpen =>
      !summary.ended &&
      currentJourney?.attemptId == summary.attemptId &&
      onOpenJourney != null;

  @override
  Widget build(BuildContext context) {
    final startLine = summary.startedAt == null
        ? 'Start date not recorded'
        : 'Started ${_absoluteDate(summary.startedAt!)}';
    final endLine = summary.endedAt != null
        ? 'Ended ${_absoluteDate(summary.endedAt!)}'
        : summary.ended
        ? 'End date not recorded'
        : 'Not ended';
    return Material(
      key: ValueKey('guardian-attempt-summary-${summary.attemptId}'),
      color: ZyraColors.foreground.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: ZyraTapFeedback.onTap(
          context,
          _canOpen ? () => onOpenJourney!(currentJourney!) : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ZyraColors.surfaceBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.ended ? 'Ended Journey' : 'Current Journey',
                      style: ZyraText.body(size: 13.5),
                    ),
                    const SizedBox(height: 3),
                    Text(startLine, style: ZyraText.subtext(size: 11.5)),
                    const SizedBox(height: 2),
                    Text(endLine, style: ZyraText.subtext(size: 11.5)),
                  ],
                ),
              ),
              if (_canOpen)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: ZyraColors.foreground.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _absoluteDate(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
