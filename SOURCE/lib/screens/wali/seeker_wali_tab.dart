// Seeker-side canonical owner for Guardian relationship management.
//
// The Founder-approved production experience is the vertical, Main-first
// Guardian page. Retired comparison designs were removed only after device
// acceptance under the governed promotion gate.

import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';

import '../../dev/zyra_dev_scenario.dart';
import '../../data/zyra_release_gates.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../widgets/zyra_loading.dart';
import 'link_guardian_panel.dart';
import 'family_messaging_screens.dart';
import 'seeker_guardian_designs.dart';

typedef GuardianLinksLoader =
    Future<ZyraSourceResult<List<WaliLinkedPerson>>> Function();
typedef GuardianActivityLoader =
    Future<ZyraSourceResult<Map<String, List<GuardianActivity>>>> Function();
typedef GuardianHistoryConsentLoader =
    Future<ZyraSourceResult<GuardianHistoryConsentState>> Function({
      required String guardianId,
      required bool guardianIsMain,
      bool? enabled,
    });
typedef GuardianJourneyAccessLoader =
    Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> Function({
      required String guardianId,
      String? attemptId,
      bool? enabled,
      bool? chatEnabled,
    });

class SeekerWaliTab extends StatefulWidget {
  final GuardianLinksLoader? linksLoader;
  final GuardianActivityLoader? activityLoader;
  final GuardianHistoryConsentLoader? historyConsentLoader;
  final GuardianJourneyAccessLoader? journeyAccessLoader;
  final Future<ZyraSourceResult<List<PendingInvite>>> Function()?
  pendingInvitesLoader;

  /// Frozen only by governed visual fixtures. Production uses wall time.
  final DateTime? comparisonNow;

  const SeekerWaliTab({
    super.key,
    this.linksLoader,
    this.activityLoader,
    this.historyConsentLoader,
    this.journeyAccessLoader,
    this.pendingInvitesLoader,
    this.comparisonNow,
  });

  @override
  State<SeekerWaliTab> createState() => _SeekerWaliTabState();
}

class _SeekerWaliTabState extends State<SeekerWaliTab> {
  bool _loading = true;
  bool _linksAvailable = true;
  bool _activityAvailable = true;
  List<WaliLinkedPerson> _linked = const [];
  Map<String, List<GuardianActivity>> _activity = const {};
  List<WaliLinkedPerson>? _previewPeople;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    ZyraDevScenario.instance.addListener(_onScenarioChange);
    ZyraDeveloperAccess.authorizationChanges.addListener(_onAuthorityChange);
    ZyraWaliLinkService.linkRevision.addListener(_onLinkRevision);
    _load();
  }

  @override
  void dispose() {
    ZyraDevScenario.instance.removeListener(_onScenarioChange);
    ZyraDeveloperAccess.authorizationChanges.removeListener(_onAuthorityChange);
    ZyraWaliLinkService.linkRevision.removeListener(_onLinkRevision);
    super.dispose();
  }

  void _onScenarioChange() {
    _onAuthorityChange();
  }

  void _onAuthorityChange() {
    if (!mounted) return;
    // Withdraw fixture display and outstanding results before refreshing.
    setState(() {
      _previewPeople = null;
      _linked = const [];
      _activity = const {};
    });
    _load();
  }

  void _onLinkRevision() {
    if (mounted) _load();
  }

  List<WaliLinkedPerson> get _people {
    final dev = ZyraDevScenario.instance;
    if (!dev.guardianOverride) return _linked;
    final locallyManaged = _previewPeople;
    if (locallyManaged != null) return locallyManaged;
    final count = dev.guardianCount;
    if (count == 0) return const [];
    final start = dev.mainGuardian ? 0 : 1;
    return [
      for (
        var index = start;
        index < start + count && index < ZyraDevScenario.fakeGuardians.length;
        index++
      )
        WaliLinkedPerson(
          id: 'dev-guardian-$index',
          firstName: ZyraDevScenario.fakeGuardians[index].name,
          relationship: ZyraDevScenario.fakeGuardians[index].relationship,
          isMain: dev.mainGuardian && index == 0,
          linkedAt: DateTime(2026, 7, 12 + index),
        ),
    ];
  }

  WaliLinkedPerson _withMainStatus(
    WaliLinkedPerson person, {
    required bool isMain,
  }) => WaliLinkedPerson(
    id: person.id,
    firstName: person.firstName,
    isMain: isMain,
    relationship: person.relationship,
    linkedAt: person.linkedAt,
  );

  Future<bool> _previewMakeMain(String guardianId) async {
    if (!mounted || !ZyraDevScenario.instance.guardianOverride) return false;
    final people = List<WaliLinkedPerson>.of(_people);
    if (!people.any((person) => person.id == guardianId)) return false;
    setState(() {
      _previewPeople = [
        for (final person in people)
          _withMainStatus(person, isMain: person.id == guardianId),
      ];
    });
    return true;
  }

  Future<bool> _previewClearMain(String guardianId) async {
    if (!mounted || !ZyraDevScenario.instance.guardianOverride) return false;
    final people = List<WaliLinkedPerson>.of(_people);
    final target = people.where((person) => person.id == guardianId);
    if (target.isEmpty || !target.first.isMain) return false;
    setState(() {
      _previewPeople = [
        for (final person in people)
          _withMainStatus(
            person,
            isMain: person.id == guardianId ? false : person.isMain,
          ),
      ];
    });
    return true;
  }

  Future<String?> _previewRemove(String guardianId) async {
    if (!mounted || !ZyraDevScenario.instance.guardianOverride) {
      return 'This Guardian preview is no longer available.';
    }
    final people = List<WaliLinkedPerson>.of(_people);
    if (!people.any((person) => person.id == guardianId)) {
      return 'This Guardian could not be removed right now.';
    }
    setState(() {
      _previewPeople = people
          .where((person) => person.id != guardianId)
          .toList(growable: false);
    });
    return null;
  }

  List<GuardianActivity> _activityFor(WaliLinkedPerson person) {
    if (ZyraDevScenario.instance.guardianOverride) {
      return ZyraDevScenario.fakeActivityFor(person.id);
    }
    return _activity[person.id] ?? const [];
  }

  GuardianHistoryConsentLoader get _consentLoader =>
      widget.historyConsentLoader ?? ZyraWaliLinkService.guardianHistoryConsent;

  GuardianJourneyAccessLoader get _journeyAccessLoader =>
      widget.journeyAccessLoader ?? ZyraWaliLinkService.guardianJourneyAccess;

  Future<void> _load() async {
    final request = ++_loadGeneration;
    final accountGeneration = ZyraAccountState.generation;
    final accountId = ZyraAccountState.userId;
    bool canPublish() =>
        mounted &&
        request == _loadGeneration &&
        !ZyraAccountState.isSigningOut &&
        accountGeneration == ZyraAccountState.generation &&
        accountId == ZyraAccountState.userId &&
        !ZyraDevScenario.instance.guardianOverride;
    if (ZyraDevScenario.instance.guardianOverride) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final linksResult =
        await (widget.linksLoader?.call() ??
            ZyraWaliLinkService.fetchLinkedPeopleResult(asWali: false));
    if (!canPublish()) return;

    if (linksResult.isUnavailable) {
      setState(() {
        _linksAvailable = false;
        _activityAvailable = true;
        _linked = const [];
        _activity = const {};
        _loading = false;
      });
      return;
    }

    final linked = linksResult.valueOr(const []);
    if (linked.isEmpty) {
      setState(() {
        _linksAvailable = true;
        _activityAvailable = true;
        _linked = const [];
        _activity = const {};
        _loading = false;
      });
      return;
    }

    final activityResult =
        await (widget.activityLoader?.call() ??
            ZyraWaliLinkService.fetchActivityResult());
    if (!canPublish()) return;
    setState(() {
      _linksAvailable = true;
      _activityAvailable = activityResult.isAvailable;
      _linked = linked;
      _activity = activityResult.valueOr(const {});
      _loading = false;
    });
  }

  void _openAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LinkGuardianScreen(
          onLinked: _load,
          gender: AppState.instance.gender,
        ),
      ),
    );
  }

  bool get _familyMessagingVisible =>
      ZyraReleaseGates.familyMessagingEnabled ||
      ZyraDevScenario.instance.guardianOverride;

  void _openFamilyMessages() {
    if (!_familyMessagingVisible) return;
    final preview = !ZyraReleaseGates.familyMessagingEnabled;
    final seekerId = ZyraAuth.currentUser?.id ?? 'dev-seeker-adam';
    final seekerName = AppState.instance.name?.trim().isNotEmpty == true
        ? AppState.instance.name!.trim()
        : 'Adam';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ZyraGuardianCircleScreen(
          seekerId: seekerId,
          seekerFirstName: seekerName,
          viewerIsSeeker: true,
          preview: preview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = ZyraDevScenario.instance.guardianOverride;
    final showSpinner = _loading && !preview;
    return Container(
      decoration: ZyraAppGoldDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: SafeArea(
        child: showSpinner
            ? const ZyraLoading()
            : SeekerGuardianPage(
                people: _people,
                activity: {
                  for (final person in _people) person.id: _activityFor(person),
                },
                linksAvailable: preview || _linksAvailable,
                activityAvailable: preview || _activityAvailable,
                onRetry: _load,
                onAdd: _openAdd,
                onOpenMessages: _familyMessagingVisible && _people.isNotEmpty
                    ? _openFamilyMessages
                    : null,
                pendingInvitesLoader: widget.pendingInvitesLoader,
                historyConsentLoader: preview ? null : _consentLoader,
                journeyAccessLoader: preview ? null : _journeyAccessLoader,
                historyConsentPreview: preview,
                previewActiveJourneyCount: preview
                    ? ZyraDevScenario.instance.guardianPreviewActiveJourneyCount
                    : 1,
                makeMainGuardian: preview
                    ? _previewMakeMain
                    : ZyraWaliLinkService.setMainGuardian,
                clearMainGuardian: preview
                    ? _previewClearMain
                    : ZyraWaliLinkService.clearMainGuardian,
                removeGuardian: preview
                    ? _previewRemove
                    : ZyraWaliLinkService.removeGuardian,
                onChanged: preview ? null : _load,
                comparisonNow: widget.comparisonNow,
              ),
      ),
    );
  }
}
