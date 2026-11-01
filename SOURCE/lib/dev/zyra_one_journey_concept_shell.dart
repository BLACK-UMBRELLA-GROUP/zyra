import '../widgets/zyra_floating_surface.dart';
// Disposable methodology comparison using the current app's presentation.
// No production routes/services are called, no member records are loaded,
// and only a device-local education marker is persisted (LOCK 3).
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemUiOverlayStyle, MissingPluginException, PlatformException;

import '../data/zyra_journey_stages.dart';
import '../data/zyra_timeline_milestones.dart';
import '../data/zyra_journey_guardian_selection.dart';
import '../data/journey_questions.dart';
import '../data/zyra_reference_data.dart';
import '../data/zyra_journey_pause_state.dart';
import '../models/seeker_profile.dart';
import '../services/zyra_wali_link_service.dart' show WaliLinkedPerson;
import '../services/zyra_wali_journey_service.dart' show WaliJourneyView;
import '../services/zyra_family_messaging_service.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_guardian_info_service.dart' show GuardianInfo;
import '../screens/wali/family_messaging_screens.dart';
import '../screens/wali/seeker_guardian_designs.dart';
import '../screens/wali/link_guardian_panel.dart';
import '../screens/wali/zyra_code_screen.dart' show ZyraCodeLocalPreview;
import '../screens/settings/help_support_screen.dart';
import '../screens/settings/personalisation_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/compatibility_editors.dart';
import 'zyra_one_journey_filters_presentation.dart';
import 'zyra_one_journey_location.dart';
import 'zyra_one_journey_location_sheet.dart';
import '../screens/profile/edit_photos_screen.dart';
import '../screens/profile/my_profile_preview_screen.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/zyra_browse_options_button.dart';
import '../widgets/zyra_browse_next_photo_motion.dart';
import '../widgets/zyra_guardian_dashboard_profile_card.dart';
import '../widgets/zyra_loading.dart';
import '../widgets/zyra_tap_feedback.dart';
import '../widgets/zyra_glass_dialog.dart';
import '../widgets/zyra_segmented_toggle.dart';
import '../widgets/zyra_shell_navigation.dart';
import '../widgets/zyra_focus_dashboard.dart';
import 'zyra_my_zyra_focus.dart';
import '../widgets/zyra_pull_down_back_scope.dart';
import '../widgets/zyra_state_widgets.dart';
import '../widgets/searchable_list_picker.dart';
import 'dev_onboarding_gold_design.dart';
import 'zyra_app_gold_preview.dart';
import 'zyra_view_request_draft_model.dart';
import 'zyra_preview_navigation_checkpoint.dart';
import 'zyra_local_photo_import.dart';
import 'zyra_browse_filter.dart';
import 'zyra_browse_history.dart';
import 'zyra_browse_photo_renderer.dart';
import 'zyra_draft_compatibility_preview.dart';
import 'zyra_draft_compatibility_access_store.dart';
import 'zyra_draft_timeline_preview.dart';
import 'zyra_draft_timeline_presentation.dart';
import 'zyra_draft_journey_bio_presentation.dart';
import 'zyra_draft_compatibility_presentation.dart';
import 'zyra_draft_compatibility_store_presentation.dart';
import 'zyra_draft_browse_utility_presentation.dart';
import 'zyra_draft_safety_advice_presentation.dart';
import 'zyra_draft_journey_end_presentation.dart';
import 'zyra_draft_journey_block_hide_sheet.dart';
import 'zyra_draft_code_entry.dart';
import 'zyra_request_help_content.dart';
import 'zyra_request_account_session.dart';
import 'zyra_request_capacity_choice.dart';
import 'zyra_guardian_circle_preview.dart';
import 'zyra_circle_topics_presentation.dart';
import 'zyra_guardian_circle_topic_options.dart';
import 'zyra_circle_discussion_archive.dart';
import 'zyra_one_journey_sample_photos.dart';
import 'zyra_one_journey_discovery_presentation.dart';
import 'zyra_request_activity_presentation.dart';
import 'zyra_my_zyra_activity_preview.dart';
import 'zyra_one_journey_browse_designs.dart';
import 'zyra_one_journey_card_content.dart';
import 'zyra_one_journey_options.dart';
import 'zyra_one_journey_options_page.dart';
import 'zyra_one_journey_tab.dart';
import 'zyra_one_journey_guardian_tabs.dart';
import 'zyra_one_journey_guardian_cards.dart';
import 'zyra_journey_peer_guardians_presentation.dart';
import 'zyra_one_journey_account_presentation.dart';
import 'zyra_one_journey_guardian_info_presentation.dart';
import 'zyra_one_journey_switch_signup_preview.dart';
import 'zyra_subscription_wallet_draft.dart';
import 'zyra_subscription_wallet_preview.dart';
import '../widgets/zyra_membership_choices.dart';
import 'zyra_one_journey_settings_details.dart';
import 'zyra_one_journey_phone_access.dart';
import 'zyra_founder_launch_review.dart';
import 'dev_settings_design_state.dart';
import 'zyra_one_journey_journey_presentation.dart';
import '../screens/connections/connections_section_controller.dart';
import 'zyra_dev_hold_to_open.dart';
import 'zyra_dev_personal_code_fixtures.dart';
import 'zyra_dev_control_system.dart' show ZyraDevControlsRouteObserver;
import 'zyra_dev_tool_section.dart';
import '../theme/zyra_interaction_style.dart';
import '../data/zyra_membership_catalog.dart';

class ZyraOneJourneyConceptShell extends StatefulWidget {
  const ZyraOneJourneyConceptShell({
    super.key,
    required this.canAct,
    required this.onExit,
    this.onDeveloperHome,
    this.canActInOwnedDialog,
    this.onRoleChanged,
    this.onPresentationReady,
    this.initialGuardianRole = false,
    this.initialSeekerBasic = false,
    this.initialGuardianBasic = false,
    this.initialCheckpoint,
    this.restoreLocation = true,
    this.onCheckpoint,
    this.localPhotoImport,
    this.compatibilityAccess,
    this.previewClock,
  });
  final bool Function() canAct;
  // Owner admission without route focus, used only by an exact shell-owned modal.
  final bool Function()? canActInOwnedDialog;
  final VoidCallback onExit;
  final VoidCallback? onDeveloperHome;
  final ValueChanged<bool>? onRoleChanged;
  // Presentation only; never publishes or retains access proof.
  final VoidCallback? onPresentationReady;
  final bool initialGuardianRole;
  final bool initialSeekerBasic;
  final bool initialGuardianBasic;
  final ZyraPreviewNavigationCheckpoint? initialCheckpoint;
  final bool restoreLocation;
  final ValueChanged<ZyraPreviewNavigationCheckpoint>? onCheckpoint;
  final ZyraLocalPhotoImport? localPhotoImport;
  final ZyraDraftCompatibilityAccessStore? compatibilityAccess;
  // Bounded fictional presentation clock, never member/server authority.
  final DateTime Function()? previewClock;
  @override
  State<ZyraOneJourneyConceptShell> createState() =>
      _ZyraOneJourneyConceptShellState();
}

class _ZyraOneJourneyConceptShellState extends State<ZyraOneJourneyConceptShell>
    with SingleTickerProviderStateMixin {
  late final ViewRequestDraftModel _model;
  late final ScrollController _scroll;
  late final ZyraPreviewPositionBucket _positions;
  final _browsePhotoIndices = <String, int>{};
  final _browseGalleryIndices = <String, int>{};
  final _message = TextEditingController();
  final _messages = <String, List<String>>{};
  final _pages = <String>[];
  final _expansion = ZyraConnectionsExpansionController();
  ZyraOneJourneySamplePhotos? _photos;
  final _browsePhotoRenderer = ZyraBrowseLocalPhotoRenderer();
  bool _photoLoadFailed = false;
  int _tab = 0;
  int _requestsTab = 0;
  int _journeyTabIndex = 0;
  bool _personSafetyConfirmationOpen = false;
  int _myZyraLastOpenedRevision = 0;
  int _myZyraFocusIndex = 0;
  final _myZyraConsumedFocusTokens = <String>{};
  final _circleReadMessageKeys = <String>{};
  final _tabBarCollapseRevision = ValueNotifier<int>(0);
  int _browseIndex = 1;
  // Session-only viewing order, never a visibility or request permission.
  final _seenBrowseProfileIds = <String>{};
  final _browseHistory = ZyraBrowseHistory();
  // The approved portrait card is the single active Browse direction.
  static const _browseDesign = ZyraOneJourneyBrowseDesign.portraitCard;
  ZyraBrowseNextMotion _browseNextMotion = ZyraBrowseNextMotion.current;
  int _browseNextMotionEpoch = 0;
  int _uiRevision = 0;
  bool _browseOptionsOpen = false;
  bool _browseHideConfirmation = false;
  String? _browseOptionsPersonId;
  int _guardianPage = 0;
  int _networkTab = 0;
  ZyraGuardianTabsState _guardianTabs = ZyraGuardianTabsState();
  String? _personId;
  String? _guardianJourneyId;
  String? _confirmation;
  ({String id, int revision, int controlsEpoch, int navigatorStamp})?
  _hiddenProfileRestore;
  ({String id, int revision, int controlsEpoch, int navigatorStamp})?
  _hiddenProfileBlock;
  bool _journeyOptionsOpen = false;
  String? _expandedJourneyOptionsId;
  ({String id, bool incoming})? _capacityRequest;
  String? _capacityEndingId;
  bool _capacityConfirmOpen = false;
  String _heldTitle = '';
  String _heldDetail = '';
  String? _noticeValue;
  Timer? _noticeTimer;
  String? get _notice => _noticeValue;
  set _notice(String? value) {
    _noticeTimer?.cancel();
    _noticeValue = value;
    if (value != null) {
      _noticeTimer = Timer(const Duration(seconds: 3), () {
        if (_allowed && _noticeValue == value) {
          setState(() => _noticeValue = null);
        }
      });
    }
  }

  bool _guardianRole = false;
  // Fictional, owner-bound inventory only. Never a paid-access authority.
  late ZyraSubscriptionWalletDraft _subscriptionWallet =
      ZyraSubscriptionWalletDraft.sample(
        ownerId: 'concept-wallet-${identityHashCode(this)}',
      );
  ZyraWalletRole? _walletSetupRole;
  // Explicit fictional payment record, independent of the selected role/plan.
  ZyraMembershipPaymentHistory _membershipPaymentHistory =
      ZyraMembershipPaymentHistory.paidBefore;
  bool _shareHistory = false;
  bool _guardianInfoSeen = false;
  bool _phoneAccessSeen = false;
  static const _guardianInfoSeenKey = 'zyra_preview_guardian_info_seen_v1';

  Future<void> _loadPhoneAccessSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted && _allowed && !_phoneAccessSeen) {
        setState(
          () => _phoneAccessSeen =
              prefs.getBool('zyra_phone_access_seen_v1') ?? false,
        );
      }
    } on MissingPluginException {
      // A missing education receipt leaves NEW visible.
    } on PlatformException {
      // A failed receipt read never grants access.
    }
  }

  Future<void> _savePhoneAccessSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('zyra_phone_access_seen_v1', true);
    } on MissingPluginException {
      // The in-memory receipt still lasts for this shell.
    } on PlatformException {
      // NEW may reappear after restarting if the receipt cannot be saved.
    }
  }

  Future<void> _loadGuardianInfoSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted && _allowed && !_guardianInfoSeen) {
        setState(
          () =>
              _guardianInfoSeen = prefs.getBool(_guardianInfoSeenKey) ?? false,
        );
      }
    } on MissingPluginException {
      // Education remains usable when local preferences are unavailable.
    } on PlatformException {
      // A failed marker read leaves NEW visible; it never grants access.
    }
  }

  Future<void> _saveGuardianInfoSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guardianInfoSeenKey, true);
    } on MissingPluginException {
      // The in-memory seen state still lasts for this preview lifetime.
    } on PlatformException {
      // A failed marker write may show NEW again after restart.
    }
  }

  bool _gold = ZyraDevAppGold.instance.renderingEnabled;
  late final _goldMotion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  String _seekerMembership = 'Seeker One';
  String _guardianMembership = 'Guardian One';
  String get _membership =>
      _guardianRole ? _guardianMembership : _seekerMembership;

  late final ZyraOneJourneyLocation _location;
  // 0 closed, 1 choose, 2 explain; no Navigator cover of the admitted host.
  int _locationSheet = 0, _locationFlow = 0;
  ZyraBrowseFilter _browseFilter = const ZyraBrowseFilter();
  ZyraBrowseFilter _editingBrowseFilter = const ZyraBrowseFilter();
  ZyraConceptAccountAction? _accountDestination;
  ZyraConceptSettingsDetail? _settingsDetail;
  ZyraMembershipDraft _membershipDraft = ZyraMembershipDraft();
  ZyraMembershipReviewRequest? _membershipReview;
  // Used viewer/profile access is independent of both route and Journey ID.
  // The normal Founder host owns it across disposable UI proof epochs.
  late final _compatibilityAccess =
      widget.compatibilityAccess ??
      ZyraDraftCompatibilityAccessStore(canAct: () => _allowed);
  Object? _compatibilityRoute;
  String? _endedCompatibilityAttemptId;
  Timer? _endedReadTimer;
  DateTime? _endedReadDeadline;
  Object? _endedReadScope;
  ZyraDraftTimelinePreview? _timelinePreview;
  Widget? _scanEntryView;
  int _scanEntryRevision = -1;
  late final ZyraRequestAccountSession _accountSession;
  GlobalKey<NavigatorState>? _accountNavigator;
  Widget? _accountLeafView;
  int _accountLeafRevision = -1;
  Widget? _ownProfilePreviewView;
  int _ownProfilePreviewRevision = -1;
  Widget? _guardianInviteView;
  int _guardianInviteRevision = -1;
  Widget? _circleEntryView;
  int _circleEntryRevision = -1;
  GlobalKey<NavigatorState>? _circleNavigator;
  int _circleScopeRevision = 0;
  // The launcher, floating container and gold-outline send button are locked.
  // Only the bubble-interior studies remain session-local, not member preferences.
  final _circleBubbleDesign = ValueNotifier(ZyraCircleBubbleDesign.current);
  bool _devControlsVisible = false;
  int _devControlsEpoch = 0;
  // Explicit disposable rehearsal, never serialized or a domain/ack grant.
  ZyraMyZyraActivityExample? _activityExample;
  final _reviewedActivityExamples = <ZyraMyZyraActivityExample>{};
  bool _activityChecklistExpanded = false;
  int _activityPreviewEpoch = 0;
  ({
    String personId,
    Set<String> linkedIds,
    String? mainId,
    Set<String> paidIds,
  })?
  _paidGuardianAgreement;
  final _devControlsScroll = ScrollController();
  bool _buildingDevControls = false;
  bool _devRouteRefreshScheduled = false;
  int get _devRouteStamp => ZyraDevControlsRouteObserver.navigationRevision;

  void _devRouteChanged() {
    _closeLocationFlow();
    _cancelEndedReadDeadline();
    _hiddenProfileRestore = null;
    if (_devRouteRefreshScheduled) return;
    _devRouteRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _devRouteRefreshScheduled = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  final _circleVisibility = ValueNotifier(false);
  final _tapContextKey = GlobalKey();
  BuildContext get _tapContext => _tapContextKey.currentContext ?? context;

  VoidCallback? _tap(VoidCallback? action) => ZyraTapFeedback.onTap(
    context,
    action,
    level: () => _accountSession.hapticLevel,
    canAct: () => _allowed,
  );

  ValueChanged<T>? _tapChange<T>(ValueChanged<T>? action) =>
      ZyraTapFeedback.onChanged(
        context,
        action,
        level: () => _accountSession.hapticLevel,
        canAct: () => _allowed,
      );

  bool get _allowed => mounted && widget.canAct();
  String? get _page => _pages.isEmpty ? null : _pages.last;
  String? get _pageOptionsSource => _page;
  bool get _hasCircleDiscussionOptions =>
      _pageOptionsSource == 'guardian_circle' ||
      (_pageOptionsSource == null && _tab == 3);
  String get _pageOptionsTitle => switch (_pageOptionsSource) {
    'settings' || 'settings_detail' => 'Settings',
    'phone_access' => 'Phone access',
    'account_action' =>
      _accountDestination == null
          ? 'Settings'
          : _accountActionLabel(_accountDestination!),
    'edit_profile' => 'Edit profile',
    'manage_photos' => 'Photos',
    'own_profile_preview' => 'My profile',
    'switch_account_signup' || 'switch_account_setup' => 'Switch account',
    'subscriptions' => 'Your subscriptions',
    'membership' || 'membership_review' => 'Membership',
    'guardian_linked_profile' => 'Seeker profile',
    'guardian_network_profile' || 'profile' => 'View profile',
    'bio' || 'bio_locked' || 'ended_bio' => 'Journey Bio',
    'journey_guardians' || 'ended_guardians' => 'Guardians',
    'ended_restart' => 'Request restart',
    'activity_preview_detail' => 'Activity',
    'guardian_access_agreement' => 'Guardian access',
    'journey_compatibility' ||
    'journey_compatibility_locked' => 'Compatibility score',
    'help_support' => 'Help & support',
    'safety' => 'Report profile',
    'safety_advice' => 'Safety & advice',
    'scan' => 'Find by ZYRA Code',
    'guardian_circle' => 'Guardian Circle',
    'compatibility' || 'ended_compatibility' => 'Compatibility score',
    'timeline' => 'Timeline',
    'journey' =>
      _personId != null && _model.isBioStepOpen(_personId!)
          ? 'Journey Bio'
          : 'Journey',
    'requests' =>
      'Journey requests · ${const ['Received', 'Sent', 'Past'][_requestsTab]}',
    'introductions' => 'Introductions',
    'ended' || 'past_journeys' => 'Ended Journeys',
    _ =>
      _guardianRole
          ? const ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile'][_tab]
          : const [
              'Profiles',
              'Journey',
              'My ZYRA',
              'Guardian',
              'Profile',
            ][_tab],
  };

  bool get _canOpenDevControls =>
      _allowed &&
      !_devControlsVisible &&
      _confirmation == null &&
      !_browseOptionsOpen &&
      !_journeyOptionsOpen &&
      !_capacityConfirmOpen;

  void _openDevControls() {
    if (!_canOpenDevControls) return;
    _closeLocationFlow();
    _cancelEndedReadDeadline();
    widget.localPhotoImport?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _devControlsVisible = true;
      _hiddenProfileRestore = null;
      _devControlsEpoch++;
      _circleVisibility.value = false;
    });
  }

  void _closeDevControls() {
    if (!_allowed || !_devControlsVisible) return;
    setState(() {
      _devControlsVisible = false;
      _devControlsEpoch++;
      _circleVisibility.value = _page == 'guardian_circle';
    });
    _publishCheckpoint();
  }

  bool get _isPhotoPage => const [
    'profile',
    'own_profile_preview',
    'guardian_linked_profile',
    'guardian_network_profile',
  ].contains(_page);
  DraftProfile? get _person => _personId == null
      ? null
      : draftProfiles.where((p) => p.id == _personId).firstOrNull;
  List<DraftProfile> get _currentJourneys => draftProfiles.where((p) {
    final s = _model.stateFor(p.id);
    return s == DraftJourneyState.preparing || s == DraftJourneyState.active;
  }).toList();
  DraftProfile? get _focus => _currentJourneys.firstOrNull;

  bool _canAddressJourneyDisclosure(String? id) =>
      _allowed &&
      !_guardianRole &&
      id != null &&
      _profileIds.contains(id) &&
      !_model.isBlocked(id) &&
      _currentJourneys.any((person) => person.id == id);

  bool _canViewJourneyBio(String? id) =>
      _canAddressJourneyDisclosure(id) &&
      (_model.canViewJourneyBio(id!) || _compatibilityAccess.isUnlocked(id));

  bool _canViewJourneyCompatibility(String? id) =>
      _canAddressJourneyDisclosure(id) &&
      (_model.canViewJourneyCompatibility(id!) ||
          _compatibilityAccess.isUnlocked(id));

  bool get _endedHistoryRoot =>
      !_guardianRole &&
      _tab == 2 &&
      _pages.any((page) => page == 'ended' || page == 'past_journeys');

  bool _canAddressEndedJourney(String? id) =>
      _allowed &&
      _endedHistoryRoot &&
      id != null &&
      _profileIds.contains(id) &&
      !_model.isBlocked(id) &&
      _model.stateFor(id) == DraftJourneyState.ended;

  DateTime get _previewNow => (widget.previewClock ?? DateTime.now)().toUtc();

  bool _endedReadWindowOpen(String id) =>
      _model.currentEndedAttemptFor(id)?.hasReadWindow(_previewNow) == true;

  DraftEndedJourneyAttempt? _endedAttempt(String id, String? attemptId) =>
      attemptId == null
      ? _model.currentEndedAttemptFor(id)
      : _model
            .endedAttemptsFor(id)
            .where((attempt) => attempt.id == attemptId)
            .firstOrNull;

  bool _canViewEndedCompatibility(String id, {String? attemptId}) {
    if (!_canAddressEndedJourney(id)) return false;
    final attempt = _endedAttempt(id, attemptId);
    if (attempt == null) return false;
    if (_compatibilityAccess.isUnlocked(id)) return true;
    final progress = attempt.progress;
    return attempt.hasReadWindow(_previewNow) &&
        progress.compatibilityConsent &&
        progress.peerCompatibilityConsent;
  }

  bool _canRequestEndedRestart(String id) =>
      _canAddressEndedJourney(id) && !_model.isHidden(id);

  void _cancelEndedReadDeadline() {
    _endedReadTimer?.cancel();
    _endedReadTimer = null;
    _endedReadDeadline = null;
    _endedReadScope = null;
  }

  // Only an actually visible private Journey reader needs a deadline timer.
  // Lists, Profiles, empty Guardian snapshots and metadata-only Timeline do not.
  // The captured owner / route epoch can only withdraw, never supply access.
  void _syncEndedReadDeadline() {
    DraftEndedJourneyAttempt? attempt;
    final id = _personId;
    if (_allowed &&
        !_devControlsVisible &&
        ModalRoute.of(context)?.isCurrent == true &&
        id != null &&
        _canAddressEndedJourney(id)) {
      if (_page == 'ended_bio' && _canViewEndedBio(id)) {
        attempt = _model.currentEndedAttemptFor(id);
      } else if (_page == 'ended_compatibility' &&
          !_compatibilityAccess.isUnlocked(id) &&
          _canViewEndedCompatibility(
            id,
            attemptId: _endedCompatibilityAttemptId,
          )) {
        attempt = _endedAttempt(id, _endedCompatibilityAttemptId);
      }
    }
    final next = DraftEndedJourneyReadWindow.expiresAt(attempt?.endedAt);
    final now = _previewNow;
    if (attempt == null ||
        !attempt.hasReadWindow(now) ||
        next == null ||
        !next.isAfter(now)) {
      _cancelEndedReadDeadline();
      return;
    }
    final scope = (
      _uiRevision,
      _devControlsEpoch,
      _devRouteStamp,
      _page,
      id,
      attempt.id,
    );
    if (next == _endedReadDeadline && scope == _endedReadScope) return;
    _cancelEndedReadDeadline();
    final fresh = _accountFreshGuard();
    final remaining = next.difference(_previewNow);
    if (remaining <= Duration.zero) return;
    _endedReadDeadline = next;
    _endedReadScope = scope;
    _endedReadTimer = Timer(remaining, () {
      final sameScope = _endedReadScope == scope;
      _cancelEndedReadDeadline();
      if (sameScope && fresh() && !_devControlsVisible) _act(() {});
    });
  }

  // Read the preserved completed mutual choice, never infer an archive grant
  // from a paid Unlock, the menu's presence or today's Guardian roster.
  bool _canViewEndedBio(String id) =>
      _canAddressEndedJourney(id) &&
      _endedReadWindowOpen(id) &&
      _model.hasCompletedCompatibilityStep(id) &&
      _model.hasCompletedBioStep(id) &&
      _model.bioRevealed(id) &&
      !_model.isBioStepOpen(id);

  // One read projection for cards, counts, badges and updates. Blocking hides
  // an invitation here without deleting its underlying fictional record.
  // Hide is deliberately different: it only removes the peer from Browse.
  List<DraftProfile> _visibleRequests(DraftJourneyState state) => draftProfiles
      .where(
        (person) =>
            !_model.isBlocked(person.id) && _model.stateFor(person.id) == state,
      )
      .toList(growable: false);

  bool get _hasNewMyZyraTabActivity =>
      _visibleRequests(DraftJourneyState.received).any(
        (person) =>
            _model.hasUnseenReceivedRequest(person.id) &&
            (_model.receivedRequestRevision(person.id) ?? 0) >
                _myZyraLastOpenedRevision,
      );

  // A request/preparation is not a current Journey disclosure to Guardians.
  List<DraftProfile> get _guardianJourneys => draftProfiles.where((p) {
    final s = _model.stateFor(p.id);
    return !_model.isBlocked(p.id) && s == DraftJourneyState.active;
  }).toList();
  List<DraftProfile> get _permittedGuardianJourneys => !_conceptHassanLinked
      ? const []
      : _guardianJourneys
            .where(
              (p) =>
                  _conceptLinkedSeeker.isMain ||
                  _conceptAccessFor('draft-guardian-hassan', p.id).view,
            )
            .toList();
  DraftProfile? get _guardianFocus =>
      _permittedGuardianJourneys
          .where((p) => p.id == _guardianJourneyId)
          .firstOrNull ??
      _permittedGuardianJourneys.firstOrNull;

  @override
  void initState() {
    super.initState();
    _location = ZyraOneJourneyLocation(canAct: () => _allowed)
      ..addListener(_locationChanged);
    ZyraDevControlsRouteObserver.navigationChanges.addListener(
      _devRouteChanged,
    );
    _guardianRole = widget.initialGuardianRole;
    _membershipDraft = ZyraMembershipDraft(
      section: ZyraMembershipSection.current,
    );
    // A warm timeout returns to My ZYRA, not the fresh-launch Browse tab.
    // The host still owns elapsed-time and fresh-admission decisions.
    _tab = _guardianRole || !widget.restoreLocation ? 2 : 0;
    final checkpoint = widget.initialCheckpoint;
    final sameRole = checkpoint?.guardian == _guardianRole;
    _model = sameRole
        ? ViewRequestDraftModel.fromSnapshot(
            checkpoint!.model,
            clock: widget.previewClock,
          )
        : ViewRequestDraftModel(capacity: 3, clock: widget.previewClock);
    if (sameRole) _restoreCheckpoint(checkpoint!);
    if (_guardianRole && _tab == 2 && _page == null) {
      _guardianTabs.attentionSeen = true;
    }
    if (_allowed && !_guardianRole && _tab == 2 && _page == null) {
      // A warm timeout can visibly open My ZYRA without a navigation tap.
      _myZyraLastOpenedRevision = _model.receivedActivityRevision;
    }
    final offset = sameRole && widget.restoreLocation
        ? checkpoint!.scrollOffset
        : 0.0;
    _scroll = ScrollController(
      initialScrollOffset: offset.isFinite ? offset.clamp(0, 1000000) : 0,
    )..addListener(_publishCheckpoint);
    _positions = ZyraPreviewPositionBucket(
      canWrite: () => _allowed,
      onChanged: _publishCheckpoint,
      initial: sameRole && widget.restoreLocation
          ? checkpoint!.positions
          : const {},
    );
    _accountSession = ZyraRequestAccountSession(
      canAct: () => _allowed,
      palette: ZyraColors.devPalette,
      hapticLevel: ZyraInteractionStyle.hapticLevel,
      goldEnabled: _gold,
    )..addListener(_accountChanged);
    _syncLocationOrigins();
    if (!sameRole && widget.initialSeekerBasic) {
      _model.setCapacity(1);
      _seekerMembership = 'Seeker Basic';
      _subscriptionWallet = _subscriptionWallet.withRole(
        ZyraWalletRole.seeker,
        coverage: ZyraWalletCoverage.basic,
      );
    }
    if (!sameRole && widget.initialGuardianBasic) {
      _guardianMembership = 'Guardian Basic';
      _subscriptionWallet = _subscriptionWallet.withRole(
        ZyraWalletRole.guardian,
        coverage: ZyraWalletCoverage.basic,
      );
      _model.setSampleGuardianMembership(
        'draft-guardian-hassan',
        DraftGuardianMembership.basic,
      );
    }
    unawaited(_loadBrowsePhotos());
    unawaited(_loadGuardianInfoSeen());
    unawaited(_loadPhoneAccessSeen());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Restoring a list is not evidence that every request was viewed.
      _publishCheckpoint();
    });
  }

  static final _profileIds = draftProfiles.map((p) => p.id).toSet();
  static final _guardianIds = draftGuardians.map((g) => g.id).toSet();
  static const _settingsOverviewActions = {
    ZyraConceptAccountAction.signInSecurity,
    ZyraConceptAccountAction.appLock,
    ZyraConceptAccountAction.advanced,
    ZyraConceptAccountAction.visibility,
    ZyraConceptAccountAction.hiddenProfiles,
    ZyraConceptAccountAction.guardianPrivacy,
    ZyraConceptAccountAction.notificationSettings,
    ZyraConceptAccountAction.feedback,
    ZyraConceptAccountAction.privacyData,
  };

  bool _canRestoreSettingsOverview(ZyraConceptAccountAction? action) =>
      action != null &&
      _settingsOverviewActions.contains(action) &&
      (_guardianRole
          ? action != ZyraConceptAccountAction.hiddenProfiles
          : action != ZyraConceptAccountAction.guardianPrivacy);

  bool _canRestoreSettingsDetail(
    ZyraConceptAccountAction? action,
    ZyraConceptSettingsDetail? detail,
  ) =>
      _canRestoreSettingsOverview(action) &&
      switch (action) {
        ZyraConceptAccountAction.signInSecurity =>
          detail == ZyraConceptSettingsDetail.recovery,
        ZyraConceptAccountAction.appLock =>
          detail == ZyraConceptSettingsDetail.appLock,
        ZyraConceptAccountAction.advanced =>
          detail == ZyraConceptSettingsDetail.deleteAccount ||
              detail == ZyraConceptSettingsDetail.resetProfile,
        ZyraConceptAccountAction.visibility ||
        ZyraConceptAccountAction.guardianPrivacy =>
          detail == ZyraConceptSettingsDetail.discovery,
        ZyraConceptAccountAction.hiddenProfiles =>
          detail == ZyraConceptSettingsDetail.hiddenProfiles,
        ZyraConceptAccountAction.notificationSettings =>
          detail == ZyraConceptSettingsDetail.notifications,
        ZyraConceptAccountAction.feedback =>
          detail == ZyraConceptSettingsDetail.feedback,
        ZyraConceptAccountAction.privacyData =>
          detail == ZyraConceptSettingsDetail.privacyPolicy ||
              detail == ZyraConceptSettingsDetail.terms,
        _ => false,
      };

  void _restoreCheckpoint(ZyraPreviewNavigationCheckpoint saved) {
    _guardianTabs = ZyraGuardianTabsState(saved.guardianTabs);
    _myZyraConsumedFocusTokens.addAll(saved.myZyraConsumedFocusTokens);
    _circleReadMessageKeys.addAll(saved.circleReadMessageKeys);
    _myZyraFocusIndex = widget.restoreLocation ? saved.myZyraFocusIndex : 0;

    // Only the detached fictional model survives a long absence. Navigation
    // below is restored only inside the approved short-return window.
    _seekerMembership = saved.seekerMembership == 'Seeker Basic'
        ? 'Seeker Basic'
        : 'Seeker One';
    final openedRevision = saved.myZyraLastOpenedRevision;
    _myZyraLastOpenedRevision =
        openedRevision >= 0 && openedRevision <= _model.receivedActivityRevision
        ? openedRevision
        : 0;
    _guardianMembership = saved.guardianMembership == 'Guardian Basic'
        ? 'Guardian Basic'
        : 'Guardian One';
    _subscriptionWallet = _subscriptionWallet
        .withRole(
          ZyraWalletRole.seeker,
          readiness: saved.seekerReadiness,
          coverage: _seekerMembership == 'Seeker Basic'
              ? ZyraWalletCoverage.basic
              : ZyraWalletCoverage.assignedFamily,
        )
        .withRole(
          ZyraWalletRole.guardian,
          coverage: _guardianMembership == 'Guardian Basic'
              ? ZyraWalletCoverage.basic
              : ZyraWalletCoverage.individualOne,
        );
    if (_guardianIds.contains(saved.mainGuardianId)) {
      _conceptMainGuardianId = saved.mainGuardianId;
    }
    _conceptRemovedGuardians.addAll(
      saved.removedGuardians.where(_guardianIds.contains),
    );
    _conceptGuardianHistory.addEntries(
      saved.guardianHistory.entries.where(
        (e) =>
            _guardianIds.contains(e.key) &&
            !_conceptRemovedGuardians.contains(e.key),
      ),
    );
    _conceptNetworkSent.addAll(saved.networkSent.where(_profileIds.contains));
    if (!widget.restoreLocation) return;
    _tab = saved.tab.clamp(0, 4);
    _requestsTab = saved.requestsTab.clamp(0, 2);
    final pendingMain = saved.pendingMainGuardianNoticeId;
    if (!_guardianRole &&
        _model.ownMainGuardianPresent &&
        pendingMain == _conceptMainGuardianId &&
        _guardianIds.contains(pendingMain) &&
        !_conceptRemovedGuardians.contains(pendingMain)) {
      _pendingMainGuardianNoticeId = pendingMain;
    }
    _journeyTabIndex = saved.journeyPlaceIndex.clamp(0, _model.capacity - 1);
    _guardianPage = saved.guardianPage.clamp(0, draftGuardians.length + 1);
    _networkTab = saved.networkTab.clamp(0, 1);
    _personId = _profileIds.contains(saved.personId) ? saved.personId : null;
    _guardianJourneyId = _profileIds.contains(saved.guardianJourneyId)
        ? saved.guardianJourneyId
        : null;
    _browseFilter = saved.browseFilter.isValid
        ? saved.browseFilter
        : const ZyraBrowseFilter();
    _editingBrowseFilter = _browseFilter;
    final eligible = _browseFilter.apply(_model.discoverableProfiles);
    for (final id in saved.browseHistory.where(_profileIds.contains)) {
      _browseHistory.appendFrontier(id);
    }
    final cursor = saved.browseCursor.clamp(0, _browseHistory.ids.length);
    while (_browseHistory.canBack && _browseHistory.cursor > cursor) {
      _browseHistory.back();
    }
    _browseHistory.reconcile(
      eligible.map((p) => p.id),
      fallbackId: saved.browseId,
    );
    final index = eligible.indexWhere((p) => p.id == _browseHistory.currentId);
    if (index >= 0) _browseIndex = index;
    _browsePhotoIndices.addEntries(
      saved.photoIndices.entries.where(
        (e) => _profileIds.contains(e.key) && e.value >= 0 && e.value < 6,
      ),
    );
    _browseGalleryIndices.addEntries(
      saved.galleryIndices.entries.where(
        (e) => _profileIds.contains(e.key) && e.value >= 0 && e.value < 7,
      ),
    );
    // Restore the Photos parent after a brief app switch, using a fresh
    // admitted editor and the existing photo-readiness gate. Never replay a
    // camera/crop child, decision sheet, checkout or pending operation.
    const common = {
      'settings',
      'personalisation',
      'own_profile_preview',
      'guardian_circle',
      'manage_photos',
      // This is a read-only catalogue, never a checkout. Selection is
      // ephemeral and is not represented by the checkpoint.
      'compatibility_store',
    };
    const seeker = {
      'requests',
      'introductions',
      'ended',
      'past_journeys',
      'profile',
      'bio',
      'timeline',
      'journey',
      'journey_options',
      'journey_compatibility',
      'journey_guardians',
      'compatibility',
      'ended_bio',
      'ended_guardians',
      'ended_compatibility',
    };
    const guardianPages = {
      'guardian_requests',
      'guardian_connect',
      'guardian_introductions',
      'guardian_seeker',
      'guardian_private_chat',
      'guardian',
      'network_request',
      'guardian_introduce',
    };
    final accountDestination = ZyraConceptAccountAction.values
        .where((action) => action.name == saved.accountDestination)
        .firstOrNull;
    final settingsDetail = ZyraConceptSettingsDetail.values
        .where((detail) => detail.name == saved.settingsDetail)
        .firstOrNull;
    for (final savedPage in saved.pages) {
      final page = savedPage;
      if (page == 'controls') break;
      if (_guardianRole && guardianPages.contains(page)) {
        if (page == 'guardian_private_chat' &&
            _guardianTabs.connection != ZyraGuardianConnection.accepted) {
          break;
        }
        _pages.add(page);
        continue;
      }
      if (page == 'guardian_main_notice') {
        if (_guardianRole ||
            _tab != 3 ||
            _pages.isNotEmpty ||
            _pendingMainGuardianNoticeId == null) {
          break;
        }
        _pages.add(page);
        continue;
      }
      if (page == 'account_action') {
        if (_pages.lastOrNull != 'settings' ||
            !_canRestoreSettingsOverview(accountDestination)) {
          break;
        }
        _accountDestination = accountDestination;
        _pages.add(page);
        continue;
      }
      if (page == 'settings_detail') {
        final storeTerms =
            _pages.lastOrNull == 'compatibility_store' &&
            accountDestination == ZyraConceptAccountAction.privacyData &&
            settingsDetail == ZyraConceptSettingsDetail.terms;
        if (!storeTerms &&
            (_pages.lastOrNull != 'account_action' ||
                !_canRestoreSettingsDetail(
                  _accountDestination,
                  settingsDetail,
                ))) {
          break;
        }
        if (storeTerms) _accountDestination = accountDestination;
        _settingsDetail = settingsDetail;
        _pages.add(page);
        continue;
      }
      if (page == 'safety_advice') {
        if (_tab != 4 || _pages.isNotEmpty) break;
        _personId = null;
        _pages.add(page);
        continue;
      }
      if (page == 'safety' && _pages.lastOrNull == 'safety_advice') {
        _personId = null;
        _pages.add(page);
        continue;
      }
      if (page == 'help_support') {
        final profileRoot = _pages.isEmpty && _tab == 4;
        if (!profileRoot &&
            !const {
              'settings',
              'phone_access',
              'account_action',
              'settings_detail',
              'edit_profile',
              'safety_advice',
            }.contains(_pages.lastOrNull)) {
          break;
        }
        // Recreate empty-search Help with fresh owner callbacks. No old
        // query, expanded FAQ controller or contact operation is retained.
        _pages.add(page);
        continue;
      }
      if (page == 'guardian_info') {
        if (_guardianRole || _tab != 4 || _pages.isNotEmpty) break;
        _pages.add(page);
        continue;
      }
      if (page == 'edit_profile') {
        if (_guardianRole || _tab != 4 || _pages.isNotEmpty) break;
        // This is only the fresh Seeker hub. Its nested editors and private
        // drafts have no checkpoint representation and are never replayed.
        _pages.add(page);
        continue;
      }
      if (common.contains(page)) {
        _pages.add(page);
        continue;
      }
      if (_guardianRole || !seeker.contains(page)) break;
      if (page == 'introductions' && (_tab != 2 || _pages.isNotEmpty)) break;
      final addressed = !{
        'requests',
        'introductions',
        'ended',
        'past_journeys',
      }.contains(page);
      if (addressed && (_personId == null || _model.isBlocked(_personId!))) {
        break;
      }
      if ({
            'ended_bio',
            'ended_guardians',
            'ended_compatibility',
          }.contains(page) &&
          !_canAddressEndedJourney(_personId)) {
        break;
      }
      if ({
            'journey',
            'journey_options',
            'journey_compatibility',
            'journey_guardians',
            'bio',
          }.contains(page) &&
          !_currentJourneys.any((p) => p.id == _personId)) {
        break;
      }
      // A remembered page is not a disclosure grant. The detached model must
      // still prove this person's completed step and independent consent.
      if (page == 'bio' && !_canViewJourneyBio(_personId)) break;
      if (page == 'timeline' && !_canViewTimeline(_personId)) break;
      if (page == 'journey_compatibility' &&
          !_canViewJourneyCompatibility(_personId)) {
        break;
      }
      _pages.add(page);
    }
    if ((_pages.contains('compatibility') ||
            _pages.contains('ended_compatibility')) &&
        _personId != null) {
      // Position-only restoration. Only the current owner's live store may
      // supply an earlier used grant; saved revealed/balance flags cannot.
      _compatibilityRoute = Object();
      if (_page == 'ended_compatibility') {
        _endedCompatibilityAttemptId = _model
            .currentEndedAttemptFor(_personId!)
            ?.id;
      }
    }
    if (_page == 'guardian_circle') _markCurrentCircleRead();
    _circleVisibility.value = _page == 'guardian_circle';
  }

  void _publishCheckpoint() {
    if (!_allowed || widget.onCheckpoint == null) return;
    final offset = _scroll.hasClients
        ? _scroll.offset
        : _scroll.initialScrollOffset;
    widget.onCheckpoint!(
      ZyraPreviewNavigationCheckpoint(
        guardian: _guardianRole,
        model: _model.snapshot(),
        tab: _tab,
        pages: _pages,
        personId: _personId,
        requestsTab: _requestsTab,
        journeyPlaceIndex: _journeyTabIndex.clamp(0, _model.capacity - 1),
        myZyraLastOpenedRevision: _myZyraLastOpenedRevision,
        seekerReadiness: _subscriptionWallet
            .forRole(ZyraWalletRole.seeker)
            .readiness,
        myZyraConsumedFocusTokens: _myZyraConsumedFocusTokens,
        circleReadMessageKeys: _circleReadMessageKeys,
        myZyraFocusIndex: _myZyraFocusIndex,
        guardianPage: _guardianPage,
        networkTab: _networkTab,
        guardianJourneyId: _guardianJourneyId,
        browseId: _browseHistory.currentId,
        browseFilter: _browseFilter.withOrigin(_homeTownPoint),
        browseHistory: _browseHistory.ids,
        browseCursor: _browseHistory.cursor,
        photoIndices: _browsePhotoIndices,
        galleryIndices: _browseGalleryIndices,
        positions: _positions.snapshot,
        scrollOffset: offset.isFinite ? offset.clamp(0, 1000000) : 0,
        mainGuardianId: _conceptMainGuardianId,
        pendingMainGuardianNoticeId: _pendingMainGuardianNoticeId,
        removedGuardians: _conceptRemovedGuardians,
        guardianHistory: _conceptGuardianHistory,
        networkSent: _conceptNetworkSent,
        seekerMembership: _seekerMembership,
        guardianMembership: _guardianMembership,
        guardianTabs: _guardianTabs.snapshot,
        compatibilityBalance: _compatibilityAccess.balance,
        compatibilityRevealed:
            _personId != null && _compatibilityAccess.isUnlocked(_personId!),
        accountDestination:
            _pages.contains('account_action') ||
                (_pages.contains('compatibility_store') &&
                    _pages.contains('settings_detail'))
            ? _accountDestination?.name
            : null,
        settingsDetail: _pages.contains('settings_detail')
            ? _settingsDetail?.name
            : null,
      ),
    );
  }

  void _rememberPhoto(String id, int index) {
    if (!_allowed || !_profileIds.contains(id) || index < 0 || index >= 6) {
      return;
    }
    _browsePhotoIndices[id] = index;
    _publishCheckpoint();
  }

  void _rememberGallery(String id, int index) {
    if (!_allowed || !_profileIds.contains(id) || index < 0 || index >= 7) {
      return;
    }
    _browseGalleryIndices[id] = index;
    _publishCheckpoint();
  }

  Future<void> _loadBrowsePhotos() async {
    try {
      final value = await ZyraOneJourneySamplePhotos.load();
      if (!_allowed) return;
      // Publish this bounded offline deck only after its first image frames
      // are ready. Person and photo identity then change together, without a
      // blank decode frame or retaining another person's photograph.
      final ready = await _browsePhotoRenderer.prepare(
        value.sets.expand((group) => group),
      );
      if (!_allowed) return;
      setState(() {
        if (ready) {
          _photos = value;
          _accountSession.seedPhotos(false, [value.seekerPhoto]);
          _accountSession.seedPhotos(true, [value.guardianPhoto]);
        } else {
          _photoLoadFailed = true;
        }
      });
      widget.onPresentationReady?.call();
    } catch (_) {
      if (_allowed) {
        setState(() => _photoLoadFailed = true);
        widget.onPresentationReady?.call();
      }
    }
  }

  void _act(VoidCallback change, {bool preserveCircle = false}) {
    if (!_allowed) return;
    _closeLocationFlow();
    _cancelEndedReadDeadline();
    setState(() {
      _browseOptionsOpen = false;
      _browseHideConfirmation = false;
      _browseOptionsPersonId = null;
      _hiddenProfileRestore = null;
      _hiddenProfileBlock = null;
      change();
      if (_expandedJourneyOptionsId case final id?) {
        if (!_journeyCardOptionsContext(id)) {
          _expandedJourneyOptionsId = null;
        }
      }
      if (_capacityRequest case final request?) {
        if (_guardianRole ||
            _tab != 2 ||
            _page != 'request_capacity' ||
            _model.isBlocked(request.id) ||
            !_capacityRequestAdmitted(request)) {
          _capacityRequest = null;
          _capacityEndingId = null;
        }
      }
      _uiRevision++;
      if (!preserveCircle) _circleScopeRevision++;
      _circleVisibility.value =
          !_devControlsVisible && _page == 'guardian_circle';
    });
    _syncGoldMotion();
    _publishCheckpoint();
  }

  void _move(VoidCallback change, {bool preserveCircle = false}) {
    _act(() {
      _devControlsVisible = false;
      _devControlsEpoch++;
      _confirmation = null;
      _notice = null;
      _expandedJourneyOptionsId = null;
      _capacityRequest = null;
      _capacityEndingId = null;
      change();
      if (_guardianRole ||
          !(_pages.contains('compatibility') ||
              _pages.contains('ended_compatibility'))) {
        _compatibilityRoute = null;
        _endedCompatibilityAttemptId = null;
      }
      if (_guardianRole || !_pages.contains('timeline')) {
        _timelinePreview = null;
      }
    }, preserveCircle: preserveCircle);
    if (_allowed && _scroll.hasClients) _scroll.jumpTo(0);
  }

  void _tabTo(int index) {
    if (!_allowed || index < 0 || index > 4) return;
    _move(() {
      _tab = index;
      if (_guardianRole && index == 2) _guardianTabs.attentionSeen = true;
      if (!_guardianRole && index == 2) {
        _myZyraLastOpenedRevision = _model.receivedActivityRevision;
      }
      _expansion.collapseAll();
      if (!_guardianRole && index == 3) {
        _guardianPage = 0;
        _consumeFocusTarget('guardian');
      }
      _pages.clear();
    });
  }

  bool _rootPageScrolled(ScrollNotification notification) {
    if (!_allowed ||
        _devControlsVisible ||
        _browseOptionsOpen ||
        _page != null) {
      return false;
    }
    final moved =
        notification is ScrollUpdateNotification &&
            (notification.scrollDelta ?? 0) != 0 ||
        notification is OverscrollNotification &&
            notification.overscroll != 0 ||
        notification is ScrollStartNotification &&
            notification.dragDetails != null;
    if (moved) _tabBarCollapseRevision.value++;
    // Observe nested root lists and photo/page views without consuming any
    // of their own scrolling, paging or back-navigation notifications.
    return false;
  }

  void _open(String page, {String? person}) {
    var target = page;
    if ({
      'ended_bio',
      'ended_guardians',
      'ended_restart',
      'ended_compatibility',
    }.contains(page)) {
      final id = person ?? _personId;
      if (!_canAddressEndedJourney(id)) return;
      if (page == 'ended_restart' && !_canRequestEndedRestart(id!)) return;
      person = id;
    }
    if (page == 'bio' || page == 'journey_compatibility') {
      final id = person ?? _personId;
      if (!_canAddressJourneyDisclosure(id)) return;
      person = id;
      if (page == 'bio' && !_canViewJourneyBio(id)) target = 'bio_locked';
      if (page == 'journey_compatibility' &&
          !_canViewJourneyCompatibility(id)) {
        target = 'journey_compatibility_locked';
      }
    }
    if (page == 'timeline' && !_canViewTimeline(person ?? _personId)) return;
    if (page == 'journey_guardians' &&
        (!_allowed ||
            _guardianRole ||
            person == null ||
            _model.isBlocked(person) ||
            !_currentJourneys.any((p) => p.id == person))) {
      return;
    }
    if (page == 'scan' &&
        (!_allowed || _guardianRole || _tab != 0 || !_model.canBrowse)) {
      return;
    }
    if (page == 'compatibility' &&
        (!_allowed ||
            _guardianRole ||
            !draftProfiles.any((p) => p.id == person) ||
            _model.isBlocked(person!))) {
      return;
    }
    final preserveCircle = page == 'controls' && _page == 'guardian_circle';
    final receivedBeingOpened =
        page == 'profile' &&
            !_guardianRole &&
            _tab == 2 &&
            _page == 'requests' &&
            _requestsTab == 0 &&
            person != null &&
            _visibleRequests(
              DraftJourneyState.received,
            ).any((p) => p.id == person)
        ? person
        : null;
    _move(() {
      _consumeFocusTarget(page, personId: person);
      if (page == 'guardian_circle') _markCurrentCircleRead();
      if (receivedBeingOpened != null) {
        _model.acknowledgeReceivedRequests([receivedBeingOpened]);
      }
      if (person != null) _personId = person;
      if (page == 'timeline') _timelinePreview = null;
      if (page == 'compatibility' || page == 'ended_compatibility') {
        _compatibilityRoute = Object();
        _endedCompatibilityAttemptId = page == 'ended_compatibility'
            ? _model.currentEndedAttemptFor(person!)?.id
            : null;
      }
      if (page == 'filters') _editingBrowseFilter = _browseFilter;
      _pages.add(target);
    }, preserveCircle: preserveCircle);
  }

  void _back() {
    if (_locationSheet != 0) {
      setState(_closeLocationFlow);
      return;
    }
    if (_page == 'guardian_main_notice' && !_devControlsVisible) {
      _closeMainGuardianNotice();
      return;
    }
    if (_devControlsVisible) {
      _closeDevControls();
      return;
    }
    if (_expandedJourneyOptionsId != null && _page == null) {
      _act(() => _expandedJourneyOptionsId = null);
      return;
    }
    if (_isRetainedAccountPage &&
        (_accountNavigator?.currentState?.canPop() ?? false)) {
      _accountNavigator!.currentState!.pop();
      return;
    }
    if (_page == 'guardian_circle' &&
        (_circleNavigator?.currentState?.canPop() ?? false)) {
      _circleNavigator!.currentState!.pop();
      // The outer return control consumed its exact one-use child binding.
      // Rebind it for the revealed parent, without changing the Circle lease,
      // UI revision, draft or conversation data.
      if (_allowed) setState(() {});
      return;
    }
    if (_browseOptionsOpen) {
      if (_browseHideConfirmation) {
        _openBrowseOptions(_browseOptionsPersonId);
        return;
      }
      _act(() {});
      return;
    }
    final hiddenBlock = _hiddenProfileBlock;
    if (hiddenBlock != null &&
        _isCurrentHiddenInspection(hiddenBlock.id) &&
        hiddenBlock.revision == _uiRevision &&
        hiddenBlock.controlsEpoch == _devControlsEpoch &&
        hiddenBlock.navigatorStamp == _devRouteStamp) {
      _act(() {});
      return;
    }
    final preserveCircle =
        _page == 'controls' && _pageOptionsSource == 'guardian_circle';
    _move(() {
      if (_page == 'filters') _editingBrowseFilter = _browseFilter;
      if (_pages.isNotEmpty) _pages.removeLast();
    }, preserveCircle: preserveCircle);
  }

  bool _canOpenBrowseOptions(String? id) =>
      _allowed &&
      !_guardianRole &&
      _tab == 0 &&
      (_page == null || _page == 'profile') &&
      _model.canBrowse &&
      (id == null ||
          (_page == 'profile'
                  ? _model.discoverableProfiles
                  : _browseFilter.apply(_model.discoverableProfiles))
              .any((person) => person.id == id));

  void _openBrowseOptions(String? id) {
    if (!_canOpenBrowseOptions(id)) return;
    _act(() {
      _browseOptionsOpen = true;
      _browseOptionsPersonId = id;
    });
  }

  Widget _browseOptionsButton(DraftProfile person) {
    final open = _bound(() => _openBrowseOptions(person.id));
    return ZyraBrowseOptionsButton(
      alignToContentEdge: true,
      profile: _displayProfile(person),
      onOpen: (_) => open(),
    );
  }

  Widget _browseOptionsNavigation() {
    final revision = _uiRevision;
    final page = _page;
    final id = _browseOptionsPersonId;
    bool current() =>
        _browseOptionsOpen &&
        revision == _uiRevision &&
        page == _page &&
        id == _browseOptionsPersonId &&
        _canOpenBrowseOptions(id);
    if (_browseHideConfirmation) {
      return FloatingNavConfirmationBar(
        key: const ValueKey('concept_browse_hide_confirmation'),
        showOuterSurface: false,
        contentEdgeInset: 20,
        hapticLevel: _accountSession.hapticLevel,
        onCancel: () {
          // The confirmation pill owns this press's single feedback tick.
          if (current()) _openBrowseOptions(id);
        },
        onConfirm: () {
          if (!current() || id == null) return;
          final person = draftProfiles.where((p) => p.id == id).firstOrNull;
          if (person == null ||
              _warnBeforePersonSafety(person, hide: true, canAct: current)) {
            return;
          }
          _move(() {
            if (!_model.hide(id)) return;
            _pages.clear();
            _personId = null;
          });
        },
      );
    }
    final navigation = ZyraShellNavigation(
      key: const ValueKey('concept_browse_options_navigation'),
      commitOnRelease: true,
      contentEdgeInset: 20,
      hapticLevel: _accountSession.hapticLevel,
      currentIndex: 0,
      items: [
        for (final action in ZyraBrowseAction.values)
          FloatingNavItem(
            icon: action.icon,
            label: action.label,
            dimmed:
                id == null &&
                action != ZyraBrowseAction.scan &&
                action != ZyraBrowseAction.filters,
          ),
      ],
      onTap: (index) {
        if (!current() ||
            index < 0 ||
            index >= ZyraBrowseAction.values.length) {
          return;
        }
        final action = ZyraBrowseAction.values[index];
        final person = draftProfiles.where((p) => p.id == id).firstOrNull;
        if (person == null &&
            action != ZyraBrowseAction.scan &&
            action != ZyraBrowseAction.filters) {
          return;
        }
        switch (action) {
          case ZyraBrowseAction.compatibility:
            _open('compatibility', person: person!.id);
          case ZyraBrowseAction.scan:
            _open('scan');
          case ZyraBrowseAction.hide:
            if (_warnBeforePersonSafety(person!, hide: true, canAct: current)) {
              return;
            }
            _act(() {
              _browseOptionsOpen = true;
              _browseOptionsPersonId = person.id;
              _browseHideConfirmation = true;
            });
          case ZyraBrowseAction.filters:
            _open('filters');
          case ZyraBrowseAction.report:
            _open('safety', person: person!.id);
        }
      },
    );
    // Navigation resolves to Positioned; keep it directly under a Stack.
    // The separate cue never owns touch, semantics or destination authority.
    return _BrowseOptionsNavigationCue(
      key: ValueKey(('browse-options-cue', revision, page, id)),
      navigation: navigation,
    );
  }

  void _result(bool success) {
    // The changed page/card is the confirmation. Keep only a genuine refusal
    // visible; ordinary successful actions must not cover the next screen.
    _notice = success ? null : 'This is no longer available. Nothing changed.';
  }

  void _journey(String id) => _open('journey', person: id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGoldMotion();
  }

  void _syncGoldMotion() {
    final reduce =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final fullPhoto = _isPhotoPage;
    if (reduce || !_gold || fullPhoto) {
      _goldMotion.stop();
      _goldMotion.value = 0;
    } else if (!_goldMotion.isAnimating) {
      _goldMotion.repeat();
    }
  }

  @override
  void dispose() {
    ZyraDevControlsRouteObserver.navigationChanges.removeListener(
      _devRouteChanged,
    );
    _location.removeListener(_locationChanged);
    _location.dispose();
    _noticeTimer?.cancel();
    _cancelEndedReadDeadline();
    _browsePhotoRenderer.dispose();
    _expansion.dispose();
    _goldMotion.dispose();
    _scroll.removeListener(_publishCheckpoint);
    _scroll.dispose();
    _devControlsScroll.dispose();
    _message.dispose();
    _accountSession.removeListener(_accountChanged);
    _accountSession.dispose();
    if (widget.compatibilityAccess == null) _compatibilityAccess.close();
    _circleBubbleDesign.dispose();
    _circleVisibility.dispose();
    _tabBarCollapseRevision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncLocationOrigins();
    _syncEndedReadDeadline();
    final devRoutes = _devRouteStamp;
    final navigationRevision = _uiRevision;
    final navigationGuardian = _guardianRole;
    final navigationControlsEpoch = _devControlsEpoch;
    final names = _guardianRole
        ? ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile']
        : ['Profiles', 'Journey', 'My ZYRA', 'Guardian', 'Profile'];
    final icons = _guardianRole
        ? [
            Icons.diversity_3_outlined,
            Icons.people_outline,
            Icons.grid_view_outlined,
            Icons.gpp_good_outlined,
            Icons.person_outline,
          ]
        : [
            Icons.search,
            Icons.route_outlined,
            Icons.dashboard_outlined,
            Icons.gpp_good_outlined,
            Icons.person_outline,
          ];
    final fullPhoto = _isPhotoPage;
    final ownsViewport =
        _page == null ||
        fullPhoto ||
        [
          'filters',
          'filter_preferences',
          'settings',
          'phone_access',
          'personalisation',
          'edit_profile',
          'manage_photos',
          'membership',
          'membership_review',
          'subscriptions',
          'journey',
          'journey_options',
          'journey_action',
          'bio',
          'bio_locked',
          'journey_compatibility',
          'journey_compatibility_locked',
          'request_capacity',
          'journey_guardians',
          'ended_bio',
          'ended_guardians',
          'ended_compatibility',
          'ended_restart',
          'guardian_access_agreement',
          'guardian_circle',
          'guardian_invite',
          'guardian_main_notice',
          'guardian_info',
          'account_action',
          'settings_detail',
          'guardian_linked_profile',
          'guardian_network_profile',
          'guardian_requests',
          'guardian_connect',
          'guardian_introductions',
          'guardian_seeker',
          'guardian_private_chat',
          'guardian_introduce',
          'network_request',
          'requests',
          'introductions',
          'saved',
          'paused',
          'ended',
          'own_profile_preview',
          'past_journeys',
          'switch_account_signup',
          'switch_account_setup',
          'compatibility',
          'timeline',
          'compatibility_store',
          'scan',
          'help_support',
          'safety',
          'safety_advice',
        ].contains(_page);
    final founderPageId = switch (_page) {
      'account_action' when _accountDestination != null =>
        'overview_${_accountDestination!.name}',
      'settings_detail' when _settingsDetail != null =>
        'detail_${_settingsDetail!.name}',
      _ => null,
    };
    final founderPending = const ZyraFounderLaunchReview().pendingFor(
      founderPageId,
      internalReview: _allowed && !_devControlsVisible,
    );
    final founderWhite = founderPending.isNotEmpty;
    final content = ownsViewport
        ? _content()
        : SafeArea(
            bottom: false,
            child: ZyraShadowScrollView(
              key: const ValueKey('draft_scroll'),
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              child: _content(),
            ),
          );
    final rootContent = NotificationListener<ScrollNotification>(
      onNotification: _rootPageScrolled,
      child: content,
    );
    return ZyraTapFeedback(
      level: () => _accountSession.hapticLevel,
      canAct: () => _allowed,
      child: Builder(
        key: _tapContextKey,
        builder: (context) => ZyraBackNavigationPreview(
          revision: _uiRevision,
          child: ZyraDevHoldToOpen(
            enabled: _canOpenDevControls,
            identity: (
              _uiRevision,
              _tab,
              _guardianRole,
              _page,
              _personId,
              _devControlsEpoch,
              devRoutes,
            ),
            canOpen: () => _canOpenDevControls && devRoutes == _devRouteStamp,
            onOpen: _openDevControls,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: founderWhite
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light,
              child: PopScope(
                canPop:
                    _locationSheet == 0 &&
                    !_devControlsVisible &&
                    _pages.isEmpty &&
                    !_browseOptionsOpen &&
                    _expandedJourneyOptionsId == null,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop && _allowed) _back();
                },
                child: Scaffold(
                  backgroundColor: founderWhite
                      ? ZyraColors.foreground
                      : ZyraColors.ivoryTop,
                  extendBody: true,
                  body: DecoratedBox(
                    decoration: BoxDecoration(
                      color: founderWhite ? ZyraColors.foreground : null,
                      gradient: founderWhite
                          ? null
                          : _accountSession.palette.gradient,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Offstage(
                          offstage: _devControlsVisible,
                          child: ExcludeFocus(
                            excluding: _devControlsVisible,
                            child: TickerMode(
                              enabled: !_devControlsVisible,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_gold && !fullPhoto && !founderWhite)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: AnimatedBuilder(
                                          animation: _goldMotion,
                                          builder: (context, _) => CustomPaint(
                                            painter: ZyraOnboardingGoldPainter(
                                              ZyraOnboardingGoldDesign
                                                  .diagonalDust,
                                              motion: ZyraOnboardingGoldMotion
                                                  .liveDrift,
                                              motionValue: _goldMotion.value,
                                              reducedMotion:
                                                  MediaQuery.disableAnimationsOf(
                                                    context,
                                                  ) ||
                                                  MediaQuery.accessibleNavigationOf(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if ((_pages.isNotEmpty ||
                                          _expandedJourneyOptionsId != null) &&
                                      !_isRetainedAccountPage &&
                                      _page != 'own_profile_preview' &&
                                      _page != 'guardian_main_notice')
                                    ZyraPullDownBackScope(
                                      key: const ValueKey(
                                        'concept_pull_down_back_scope',
                                      ),
                                      // A root card expansion only collapses inline content.
                                      // The resting close cue belongs to actual pushed pages.
                                      inlineBackHeader:
                                          _page == null ||
                                          _page == 'guardian_invite' ||
                                          _page == 'guardian_circle',
                                      paintBackground: !founderWhite,
                                      returnForegroundColor: founderWhite
                                          ? ZyraFounderLaunchPageStyle
                                                .darkGoldInk
                                          : null,
                                      routeIdentity: (
                                        List<String>.of(_pages).join('/'),
                                        _tab,
                                        _guardianRole,
                                        _personId,
                                        _uiRevision,
                                        _expandedJourneyOptionsId,
                                      ),
                                      enabled:
                                          _allowed &&
                                          !_browseOptionsOpen &&
                                          _confirmation == null,
                                      onBack: _bound(() {
                                        // A sheet can open before the parent rebuilds. Recheck
                                        // current decision ownership at dispatch, not just build.
                                        if (!_browseOptionsOpen &&
                                            !_journeyOptionsOpen &&
                                            !_capacityConfirmOpen &&
                                            _confirmation == null) {
                                          _back();
                                        }
                                      }),
                                      child: ZyraFounderLaunchPageStyle(
                                        pending: founderPending,
                                        child: PageStorage(
                                          bucket: _positions,
                                          child: rootContent,
                                        ),
                                      ),
                                    )
                                  else
                                    PageStorage(
                                      bucket: _positions,
                                      child: rootContent,
                                    ),
                                  if (_browseOptionsOpen)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        key: const ValueKey(
                                          'concept_browse_options_dismiss',
                                        ),
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _tap(_bound(() => _act(() {}))),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                  if (_browseOptionsOpen)
                                    _browseOptionsNavigation()
                                  else if (_page == null ||
                                      _page == 'journey_options')
                                    ValueListenableBuilder<int>(
                                      valueListenable: _tabBarCollapseRevision,
                                      builder: (context, collapseRevision, _) =>
                                          ZyraShellNavigation(
                                            key: ValueKey((
                                              'concept_root_navigation',
                                              _guardianRole,
                                            )),
                                            hapticLevel:
                                                _accountSession.hapticLevel,
                                            contentEdgeInset: 20,
                                            compactWhenIdle: true,
                                            compactV2: true,
                                            collapseRevision: collapseRevision,
                                            interactionEnabled:
                                                _allowed &&
                                                !_devControlsVisible,
                                            items: [
                                              for (
                                                var i = 0;
                                                i < names.length;
                                                i++
                                              )
                                                FloatingNavItem(
                                                  icon: icons[i],
                                                  label: names[i],
                                                  useJourneyGlyph: i == 1,
                                                  dot:
                                                      i == 2 &&
                                                      (_guardianRole
                                                          ? !_guardianTabs
                                                                    .attentionSeen &&
                                                                _guardianTabs
                                                                    .needsYou
                                                          : _hasNewMyZyraTabActivity),
                                                ),
                                            ],
                                            currentIndex: _tab,
                                            onTap: (index) {
                                              if (_allowed &&
                                                  navigationRevision ==
                                                      _uiRevision &&
                                                  navigationGuardian ==
                                                      _guardianRole &&
                                                  navigationControlsEpoch ==
                                                      _devControlsEpoch &&
                                                  devRoutes == _devRouteStamp &&
                                                  (ModalRoute.of(
                                                        context,
                                                      )?.isCurrent ??
                                                      false) &&
                                                  !_devControlsVisible &&
                                                  !_browseOptionsOpen &&
                                                  (_page == null ||
                                                      _page ==
                                                          'journey_options')) {
                                                _tabTo(index);
                                              }
                                            },
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_locationSheet != 0 && _locationFlowCurrent())
                          _locationOverlay(),
                        if (_devControlsVisible) _devControlsPage(),
                        if (_notice != null)
                          Positioned(
                            left: 20,
                            right: 48,
                            bottom: MediaQuery.paddingOf(context).bottom + 82,
                            child: Semantics(
                              liveRegion: true,
                              child: IgnorePointer(
                                child: Material(
                                  color: ZyraColors.modalSheetSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: _body(_notice!, small: true),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _devControlsPage() {
    final close = _bound(_closeDevControls, developerControl: true);
    return Container(
      key: const ValueKey('dev_controls_page'),
      decoration: BoxDecoration(gradient: _accountSession.palette.gradient),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  key: const ValueKey('dev_controls_close'),
                  tooltip: 'Close developer controls',
                  onPressed: _tap(close),
                  icon: Icon(Icons.close, color: ZyraColors.unlockText),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      key: const ValueKey('draft_close'),
                      onPressed: _tap(
                        _bound(() {
                          (widget.onDeveloperHome ?? widget.onExit)();
                        }, developerControl: true),
                      ),
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('Developer Home'),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ZyraShadowScrollView(
                key: const ValueKey('dev_controls_scroll'),
                controller: _devControlsScroll,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
                child: _buildDevControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevControls() {
    _buildingDevControls = true;
    try {
      return _controls();
    } finally {
      _buildingDevControls = false;
    }
  }

  Widget _content() => switch (_page) {
    'controls' => _controls(),
    'profile' => _profileView(),
    'journey' => _journeyView(),
    'journey_options' => _journeyOptionsPage(),
    'journey_action' => _journeyActionConfirmation(),
    'request_capacity' => _requestCapacityView(),
    'journey_compatibility' => _journeyCompatibility(),
    'journey_compatibility_locked' => _journeyDisclosureLocked(bio: false),
    'journey_guardians' => _journeyGuardians(),
    'ended_bio' => _endedJourneyDetail(bio: true),
    'ended_guardians' => _endedJourneyDetail(bio: false),
    'ended_restart' => _endedRestart(),
    'ended_compatibility' => _endedCompatibility(),
    'guardian_access_agreement' => _guardianAccessAgreement(),
    'guardian_circle' => _guardianCircle(),
    'guardian_invite' => _guardianInvite(),
    'guardian_main_notice' => _mainGuardianNotice(),
    'guardian_info' => _guardianInfo(),
    'network_request' => _guardianTabsView('connect_confirm'),
    'guardian_introduce' => _guardianTabsView('introduce_confirm'),
    'guardian_requests' => _guardianTabsView('requests'),
    'guardian_connect' => _guardianTabsView('connect'),
    'guardian_introductions' => _guardianTabsView('introductions'),
    'guardian_seeker' => _guardianTabsView('seeker'),
    'guardian_private_chat' => _guardianPrivateChat(),
    'guardian_chat_report' => _guardianChatReport(),
    'held_action' => _heldPreviewAction(),
    'own_profile_preview' => _ownProfilePreview(),
    'switch_account_signup' => _switchSignupView(setupOverview: false),
    'switch_account_setup' => _switchSignupView(setupOverview: true),
    'past_journeys' => _activityPage('Ended Journeys', _history()),
    'requests' => _requestActivity(),
    'introductions' => _introductionsActivity(),
    'saved' || 'paused' => _unavailable(),
    'ended' => _historyActivity(),
    'guardian' => _guardianDetail(),
    'guardian_linked_profile' => _guardianLinkedProfile(),
    'guardian_network_profile' => _guardianNetworkProfile(),
    'settings' => _settings(),
    'phone_access' => _phoneAccess(),
    'personalisation' => _personalisation(),
    'edit_profile' ||
    'manage_photos' ||
    'filter_preferences' => _retainedAccountLeaf(),
    'membership' => _membershipView(),
    'membership_review' => _membershipReviewView(),
    'subscriptions' => _subscriptionsView(),
    'bio' => _bio(),
    'bio_locked' => _journeyDisclosureLocked(bio: true),
    'compatibility' => _compatibilityInfo(),
    'compatibility_store' => _compatibilityStore(),
    'notifications' => _notificationsView(),
    'filters' => _filters(),
    'scan' => _scanEntry(),
    'help_support' => _helpSupport(),
    'safety' => _safety(),
    'safety_advice' => _safetyAdvice(),
    'timeline' => _timeline(_personId ?? ''),
    'account_action' => _accountActionView(),
    'settings_detail' => _settingsDetailView(),
    _ =>
      _guardianRole
          ? switch (_tab) {
              0 => _guardianTabsView('network'),
              1 => _guardianTabsView('journeys'),
              2 => _guardianTabsView('my_zyra'),
              3 => _guardianTabsView('seekers'),
              _ => _ownProfile(),
            }
          : switch (_tab) {
              0 => _discover(),
              1 => _connections(),
              2 => _dashboard(),
              3 => _guardians(),
              _ => _ownProfile(),
            },
  };

  VoidCallback _bound(VoidCallback action, {bool developerControl = false}) {
    final controls = developerControl || _buildingDevControls;
    final controlsEpoch = _devControlsEpoch;
    final revision = _uiRevision;
    final page = _page;
    final tab = _tab;
    final guardian = _guardianRole;
    return () {
      if (!_allowed ||
          (controls ? !_devControlsVisible : _devControlsVisible) ||
          (controls && controlsEpoch != _devControlsEpoch) ||
          revision != _uiRevision ||
          page != _page ||
          tab != _tab ||
          guardian != _guardianRole) {
        ZyraInteractionStyle.cancelSelectionTap();
        return;
      }
      action();
    };
  }

  Widget _scanEntry() {
    // Keep the adapter callbacks stable through harmless bundled-photo/theme
    // repaints. A new page/role/revision gets an independent entry lifetime.
    if (_scanEntryView != null && _scanEntryRevision == _uiRevision) {
      return _scanEntryView!;
    }
    final revision = _uiRevision;
    _scanEntryRevision = revision;
    bool current() =>
        _allowed &&
        !_guardianRole &&
        _tab == 0 &&
        _page == 'scan' &&
        revision == _uiRevision &&
        _model.canBrowse;
    bool eligible(DraftProfile person) =>
        draftProfiles.any((known) => identical(known, person)) &&
        _model.discoverableProfiles.any((known) => known.id == person.id);
    return _scanEntryView = ZyraDraftCodeEntry(
      key: ValueKey(('draft_code_entry', revision)),
      canAct: current,
      lookupCode: (code) async {
        if (!current()) return null;
        final person = ZyraDraftKnownPersonCodes.resolve(code);
        return person != null && eligible(person) ? person : null;
      },
      onViewProfile: (person) {
        if (!current() || !eligible(person)) return;
        _open('profile', person: person.id);
      },
    );
  }

  Widget _helpSupport() => HelpSupportScreen.preview(
    canAct: _accountFreshGuard(),
    categories: zyraRequestHelpCategories,
  );

  SeekerProfile _displayProfile(DraftProfile p) => SeekerProfile(
    id: p.id,
    firstName: p.firstName,
    surnameLine: p.surname,
    age: p.age,
    city: p.city,
    publicNationality: zyraBrowseNationalityLabel(p.nationalityCode),
    publicEthnicity: zyraBrowseEthnicityLabel(p.ethnicityCode),
    gender: 'female',
    photos: _photos?.forIndex(draftProfiles.indexOf(p)) ?? const [],
  );

  bool _canToggleInvitation(String id) =>
      !_guardianRole &&
      !_model.isBlocked(id) &&
      (_model.stateFor(id) == DraftJourneyState.sent || _model.canRequest(id));

  String _invitationLabel(String id) => switch (_model.stateFor(id)) {
    null => 'Request a Journey',
    DraftJourneyState.sent => 'Request sent',
    DraftJourneyState.acceptedWaiting => 'Accepted · waiting for confirmation',
    DraftJourneyState.ended => 'Journey archived',
    final state => _stateLabel(state),
  };

  void _toggleInvitation(String id) {
    if (!_allowed || !_canToggleInvitation(id)) return;

    _act(() {
      _seenBrowseProfileIds.add(id);
      if (_model.stateFor(id) == DraftJourneyState.sent) {
        _model.cancel(id);
      } else {
        _model.request(id);
      }
    });
  }

  Widget _photoSurface(DraftProfile p) => Stack(
    fit: StackFit.expand,
    children: [
      ZyraOneJourneyBrowsePresentation(
        key: ValueKey(('prepared-profile', p.id, _photos != null)),
        profile: _displayProfile(p),
        initialPhotoIndex: _browsePhotoIndices[p.id] ?? 0,
        onPhotoIndexChanged: (index) => _rememberPhoto(p.id, index),
        onMenu: _bound(() => _open('safety', person: p.id)),
        menuKey: const ValueKey('draft_safety'),
        menuButton: !_guardianRole && _tab == 0 && _page == 'profile'
            ? _browseOptionsButton(p)
            : null,
        previousKey: const ValueKey('draft_browse_previous'),
        nextKey: const ValueKey('draft_browse_next'),
        requestKey: const ValueKey('draft_request'),
        requestLabel: _invitationLabel(p.id),
        requestSemanticLabel: _model.stateFor(p.id) == DraftJourneyState.sent
            ? 'Request sent. Tap to cancel request'
            : null,
        invitationSent: _model.stateFor(p.id) == DraftJourneyState.sent,
        onRequest: _canToggleInvitation(p.id)
            ? _bound(() => _toggleInvitation(p.id))
            : null,
      ),
      if (_photoLoadFailed)
        Positioned(
          top: 100,
          left: 20,
          right: 60,
          child: _body(
            'Photos could not load. No member photo was accessed.',
            small: true,
          ),
        ),
    ],
  );

  int _browseSelectionIndex(List<DraftProfile> people) {
    if (people.isEmpty) {
      _browseHistory.reconcile(const []);
      return 0;
    }
    final fallback =
        ((_browseIndex % people.length) + people.length) % people.length;
    _browseHistory.reconcile(
      people.map((person) => person.id),
      fallbackId: people[fallback].id,
    );
    final current = people.indexWhere(
      (person) => person.id == _browseHistory.currentId,
    );
    return _browseIndex = current < 0 ? fallback : current;
  }

  void _previousBrowseProfile() {
    final people = _browseFilter.apply(_model.discoverableProfiles);
    if (!_model.canBrowse || people.isEmpty) return;
    _browseSelectionIndex(people);
    final previous = _browseHistory.back();
    if (previous == null) return;

    _browseIndex = people.indexWhere((person) => person.id == previous);
    _browsePhotoIndices[previous] = 0;
    _browseGalleryIndices[previous] = 0;
  }

  void _nextBrowseProfile() {
    final people = _browseFilter.apply(_model.discoverableProfiles);
    if (!_model.canBrowse || people.isEmpty) return;

    final current = _browseSelectionIndex(people);
    final replay = _browseHistory.forwardReplay();
    if (replay != null) {
      _browseIndex = people.indexWhere((person) => person.id == replay);
      _browsePhotoIndices[replay] = 0;
      _browseGalleryIndices[replay] = 0;
      if (_browseIndex >= 0 && replay != people[current].id) {
        ++_browseNextMotionEpoch;
      }
      return;
    }
    _seenBrowseProfileIds.add(people[current].id);
    // Walk the freshly eligible deck. Sent invitations remain in this deck;
    // hidden/blocked/occupied people never enter it, even on a later cycle.
    var next = (current + 1) % people.length;
    for (var offset = 1; offset < people.length; offset++) {
      final candidate = (current + offset) % people.length;
      if (!_seenBrowseProfileIds.contains(people[candidate].id)) {
        next = candidate;
        break;
      }
    }
    _browseIndex = next;
    _browsePhotoIndices[people[next].id] = 0;
    _browseGalleryIndices[people[next].id] = 0;
    if (people[next].id != people[current].id) ++_browseNextMotionEpoch;
    _seenBrowseProfileIds.add(people[next].id);
    _browseHistory.appendFrontier(people[next].id);
  }

  Widget _discover() {
    final people = _browseFilter.apply(_model.discoverableProfiles);
    if (!_model.canBrowse) {
      return SafeArea(
        child: ZyraShadowScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mainHeading('Profiles'),
              _title(
                _model.capacity == 1
                    ? 'Your Journey has your focus.'
                    : 'Your Journey places are full.',
                size: 24,
              ),
              const SizedBox(height: 12),
              _body(
                _model.capacity == 1
                    ? 'You are out of search while your Journey place is reserved or active.'
                    : 'You are out of search while all ${_model.capacity} Journey places are reserved or active.',
              ),
              if (_focus != null) ...[
                const SizedBox(height: 24),
                _button(
                  'draft_focus_journey',
                  _model.capacity == 1
                      ? 'Continue your Journey'
                      : 'View your Journeys',
                  () => _currentJourneys.length == 1
                      ? _journey(_focus!.id)
                      : _tabTo(1),
                  primary: true,
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (people.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mainHeading('Profiles'),
              Expanded(
                child: LayoutBuilder(
                  key: const ValueKey('concept_profiles_empty_viewport'),
                  builder: (context, constraints) => ZyraShadowScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ZyraEmptyState(
                            icon: Icons.search,
                            title: 'No profiles in this view.',
                            message: _browseFilter.isValid
                                ? 'Try widening your filters. Occupied profiles stay out of this view.'
                                : 'The selected distance origin is unavailable. Clear the radius or reset your filters.',
                          ),
                          const SizedBox(height: 20),
                          _button(
                            'concept_clear_filters',
                            'Clear filters',
                            () => _act(() {
                              _browseFilter = const ZyraBrowseFilter();
                              _editingBrowseFilter = _browseFilter;
                              _browseIndex = 0;
                              _browseHistory.reset();
                            }),
                          ),
                          const SizedBox(height: 12),
                          _button(
                            'concept_edit_filters',
                            'Adjust filters',
                            () => _open('filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final index = _browseSelectionIndex(people);
    final revision = _uiRevision;
    bool current(SeekerProfile profile) =>
        _allowed &&
        revision == _uiRevision &&
        !_guardianRole &&
        _tab == 0 &&
        _page == null &&
        _model.canBrowse &&
        people.any((person) => person.id == profile.id);
    final displayed = _displayProfile(people[index]);
    // Record actual exposure after rendering, including filter selections.
    // This bookkeeping never triggers a rebuild or changes the selection.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (current(displayed) && _seenBrowseProfileIds.add(displayed.id)) {
        _publishCheckpoint();
      }
    });
    return ZyraOneJourneyBrowseDesigns(
      key: ValueKey(('prepared-browse', _photos != null)),
      requestRowLabels: const [
        'Request a Journey',
        'Request sent',
        'Received request',
        'Journey archived',
      ],
      profiles: people.map(_displayProfile).toList(growable: false),
      selectedIndex: index,
      design: _browseDesign,
      photoBuilder: _browsePhotoRenderer.build,
      initialGalleryIndices: _browseGalleryIndices,
      onPhotoIndexChanged: _rememberPhoto,
      onGalleryIndexChanged: _rememberGallery,
      alignHeaderActions: true,
      nextProfileMotion: _browseNextMotion,
      nextProfileMotionEpoch: _browseNextMotionEpoch,
      hapticLevel: _accountSession.hapticLevel,
      bottomPadding: _browseOptionsOpen && _browseHideConfirmation
          ? (FloatingNavConfirmationBar.layoutHeight(
                      context,
                      viewportWidth: MediaQuery.sizeOf(context).width,
                      showOuterSurface: false,
                      contentEdgeInset: 20,
                    ) +
                    MediaQuery.paddingOf(context).bottom.clamp(
                      ZyraNavBarMetrics.bottomInset,
                      double.infinity,
                    ) +
                    12)
                .clamp(100, double.infinity)
                .toDouble()
          : 100,
      onFilters: _bound(() {
        _open('filters');
      }),
      onBrowseMenu: (profile) {
        if (profile == null) {
          if (_allowed &&
              revision == _uiRevision &&
              !_guardianRole &&
              _tab == 0 &&
              _page == null) {
            _openBrowseOptions(null);
          }
        } else if (current(profile)) {
          _openBrowseOptions(profile.id);
        }
      },
      onPrevious: _browseHistory.canBack
          ? _bound(() => _act(_previousBrowseProfile))
          : null,
      onNext: _bound(() => _act(_nextBrowseProfile)),
      canRequest: (profile) => _canToggleInvitation(profile.id),
      requestLabel: (profile) => _invitationLabel(profile.id),
      requestSemanticLabel: (profile) =>
          _model.stateFor(profile.id) == DraftJourneyState.sent
          ? 'Request sent. Tap to cancel request'
          : _invitationLabel(profile.id),
      invitationSent: (profile) =>
          _model.stateFor(profile.id) == DraftJourneyState.sent,
      // Photo browsing stays inside the approved bounded card.
      onProfile: null,
      onRequest: (profile) {
        if (!current(profile)) {
          ZyraInteractionStyle.cancelSelectionTap();
          return;
        }
        _toggleInvitation(profile.id);
      },
    );
  }

  Widget _profileView() {
    final p = _person;
    if (p == null) return _unavailable();
    if (_model.isBlocked(p.id)) return _userNotFoundView();
    final fromHiddenProfiles =
        _tab == 4 &&
        _pages.length >= 2 &&
        _pages[_pages.length - 2] == 'account_action' &&
        _accountDestination == ZyraConceptAccountAction.hiddenProfiles;
    if (fromHiddenProfiles) {
      // Inspection never removes Hide or borrows the ordinary profile's
      // invitation actions. A withdrawn hidden context fails closed.
      if (_guardianRole ||
          !_profileIds.contains(p.id) ||
          !_model.isHidden(p.id)) {
        return _unavailable();
      }
      return _hiddenProfileInspection(p);
    }
    // Nested return is owned by the shared viewport scope, not this photo's
    // horizontal pager or a second competing vertical dismissal recognizer.
    return _photoSurface(p);
  }

  bool _isCurrentHiddenInspection(String id) =>
      _allowed &&
      !_guardianRole &&
      _tab == 4 &&
      _page == 'profile' &&
      _personId == id &&
      _pages.length >= 2 &&
      _pages[_pages.length - 2] == 'account_action' &&
      _accountDestination == ZyraConceptAccountAction.hiddenProfiles &&
      _profileIds.contains(id) &&
      _model.isHidden(id) &&
      !_model.isBlocked(id);

  Widget _hiddenProfileInspection(DraftProfile person) {
    final fresh = _accountFreshGuard();
    bool current() =>
        fresh() &&
        !_devControlsVisible &&
        _isCurrentHiddenInspection(person.id);
    final pending = _hiddenProfileBlock;
    bool confirming() =>
        current() &&
        pending != null &&
        _hiddenProfileBlock == pending &&
        pending.id == person.id &&
        pending.revision == _uiRevision &&
        pending.controlsEpoch == _devControlsEpoch &&
        pending.navigatorStamp == _devRouteStamp;
    void finish(bool block) {
      if (!current() || (block && !confirming())) return;
      if (block &&
          _warnBeforePersonSafety(person, hide: false, canAct: confirming)) {
        return;
      }
      _move(() {
        final changed = block
            ? _model.block(person.id)
            : _model.unhide(person.id);
        if (changed) _pages.removeLast();
      });
    }

    final isConfirming = confirming();
    final first = _button(
      isConfirming
          ? 'concept_hidden_inspection_cancel'
          : 'concept_hidden_inspection_unhide',
      isConfirming ? 'Cancel' : 'Unhide profile',
      () {
        if (!current()) return;
        if (isConfirming) {
          if (confirming()) _act(() {});
        } else {
          finish(false);
        }
      },
      primary: !isConfirming,
    );
    final second = _button(
      isConfirming
          ? 'concept_hidden_inspection_confirm_block'
          : 'concept_hidden_inspection_block',
      'Block profile',
      () {
        if (!current()) return;
        if (_warnBeforePersonSafety(person, hide: false, canAct: current)) {
          return;
        }
        if (isConfirming) {
          finish(true);
        } else {
          _act(() {
            _hiddenProfileBlock = (
              id: person.id,
              revision: _uiRevision + 1,
              controlsEpoch: _devControlsEpoch,
              navigatorStamp: _devRouteStamp,
            );
          });
        }
      },
      primary: isConfirming,
    );
    return SafeArea(
      key: ValueKey('concept_hidden_inspection_${person.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _mainHeading('Profile'),
          ),
          Expanded(
            child: ZyraOneJourneyBrowseDesigns(
              key: ValueKey((
                'hidden-current-card',
                person.id,
                _photos != null,
              )),
              profiles: [_displayProfile(person)],
              selectedIndex: 0,
              design: _browseDesign,
              showFeedChrome: false,
              photoBuilder: _browsePhotoRenderer.build,
              initialGalleryIndices: _browseGalleryIndices,
              onPhotoIndexChanged: (id, index) {
                if (current() && id == person.id) _rememberPhoto(id, index);
              },
              onGalleryIndexChanged: (id, index) {
                if (current() && id == person.id) _rememberGallery(id, index);
              },
              hapticLevel: _accountSession.hapticLevel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isConfirming) ...[
                  Text(
                    'Block ${person.firstName}?',
                    key: const ValueKey(
                      'concept_hidden_inspection_block_prompt',
                    ),
                    textAlign: TextAlign.center,
                    style: ZyraText.body(size: 15),
                  ),
                  const SizedBox(height: 10),
                ],
                if (MediaQuery.textScalerOf(context).scale(1) > 1.3) ...[
                  first,
                  const SizedBox(height: 10),
                  second,
                ] else
                  Row(
                    children: [
                      Expanded(child: first),
                      const SizedBox(width: 10),
                      Expanded(child: second),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Only this tab sorts by real local activity; other screens keep their defaults.
  List<DraftProfile> get _tabJourneys => _currentJourneys
    ..sort((a, b) {
      final aAt = _model.lastActivityFor(a.id);
      final bAt = _model.lastActivityFor(b.id);
      final order = aAt == null
          ? (bAt == null ? 0 : 1)
          : bAt == null
          ? -1
          : bAt.compareTo(aAt);
      return order != 0
          ? order
          : draftProfiles.indexOf(a).compareTo(draftProfiles.indexOf(b));
    });

  String _journeyNextStep(DraftProfile person) {
    final id = person.id;
    if (_model.isBlocked(id)) return 'User not found';
    if (!_model.ownMainGuardianPresent) {
      return 'Your turn: add your Main Guardian';
    }
    if (!_model.peerMainGuardianPresentFor(id)) {
      return 'Waiting for ${person.firstName}';
    }
    if (_model.stateFor(id) == DraftJourneyState.preparing) {
      if (_model.isReady(id) && _model.peerIsReady(id)) {
        return 'Your turn: begin Journey';
      }
      return _model.isReady(id)
          ? 'Waiting for ${person.firstName}'
          : 'Your turn: I’m ready to begin';
    }
    final stage = _model.stageFor(id);
    // The existing Seeker model has no Family Review deadline. Do not copy the
    // separate Guardian fixture's timer or the master's illustrative 41 hours.
    if (_model.isBioStepOpen(id)) {
      if (_model.canChooseBioContinue(id) || _model.canCompleteBioStep(id)) {
        return 'Your turn: continue';
      }
    } else if (_model.canAdvanceStage(id) ||
        (stage?.kind == ZyraStageKind.threshold &&
            _model.canChooseStageContinue(id))) {
      return 'Your turn: continue';
    }
    final waiting = switch (stage?.value) {
      'salam_exchange' => _model.hasSentSalam(id),
      'compatibility_reveal' =>
        _model.isBioStepOpen(id)
            ? _model.hasChosenBioReveal(id)
            : _model.hasChosenCompatibilityReveal(id),
      'conversation' => false,
      _ => _model.hasChosenStageContinue(id),
    };
    if (waiting) {
      return 'Waiting for ${person.firstName}';
    }
    final action = switch (stage?.value) {
      'salam_exchange' => 'send Salam',
      'compatibility_reveal' => 'choose to reveal',
      'wali_gate' => 'continue',
      'family_stage' => 'answer Family Compatibility',
      'conversation' => 'open the conversation',
      _ => 'answer ${stage?.label ?? ''}',
    };
    return 'Your turn: $action';
  }

  Widget _connections() {
    final journeys = _tabJourneys;
    final index = _journeyTabIndex.clamp(0, _model.capacity - 1);
    final person = index < journeys.length ? journeys[index] : null;
    final fresh = _accountFreshGuard();
    bool current() =>
        fresh() &&
        !_devControlsVisible &&
        !_guardianRole &&
        _tab == 1 &&
        _page == null &&
        _journeyTabIndex.clamp(0, _model.capacity - 1) == index &&
        (person == null ||
            _tabJourneys.elementAtOrNull(index)?.id == person.id);
    void dispatch(VoidCallback action) {
      if (!current()) {
        ZyraInteractionStyle.cancelSelectionTap();
        return;
      }
      action();
    }

    return ZyraOneJourneyTab(
      journeys: [
        for (final p in journeys)
          ZyraJourneyTabCard(
            id: p.id,
            firstName: p.firstName,
            details: '${p.age} · ${p.city}',
            stageNumber: _model.stateFor(p.id) == DraftJourneyState.preparing
                ? 0
                : (_model.stageFor(p.id)?.order ?? 1),
            stageLabel: _model.stateFor(p.id) == DraftJourneyState.preparing
                ? _stateLabel(DraftJourneyState.preparing)
                : _model.stageFor(p.id)?.label ??
                      _stateLabel(_model.stateFor(p.id)!),
            nextStep: _journeyNextStep(p),
            unavailable: _model.isBlocked(p.id),
            photo: _photos == null || _model.isBlocked(p.id)
                ? null
                : AssetImage(
                    'assets/dev/one_journey_photos/${ZyraOneJourneySamplePhotos.seeds[draftProfiles.indexOf(p)].first}.jpg',
                  ),
          ),
      ],
      capacity: _model.capacity,
      index: index,
      sessionIdentity: (
        _uiRevision,
        _devControlsEpoch,
        _devRouteStamp,
        journeys.map((p) => p.id).join('/'),
      ),
      onIndexChanged: (value) => dispatch(() {
        if (value >= 0 && value < _model.capacity) {
          _act(() => _journeyTabIndex = value);
        }
      }),
      onContinue: () => dispatch(() {
        if (person != null && !_model.isBlocked(person.id)) _journey(person.id);
      }),
      onOptions: () => dispatch(() {
        if (person != null && !_model.isBlocked(person.id)) {
          _open('journey_options', person: person.id);
        }
      }),
      onEndUnavailable: person != null && _model.isBlocked(person.id)
          ? () => dispatch(() => _showJourneyAction(person, 'end'))
          : null,
      onBrowse: () => dispatch(() => _tabTo(0)),
      onPlans: () =>
          dispatch(() => _accountDispatch(ZyraConceptAccountAction.membership)),
    );
  }

  Widget _journeyOptionsPage() {
    final person = _person;
    if (person == null || !_canAddressJourneyDisclosure(person.id)) {
      return _unavailable();
    }
    final fresh = _accountFreshGuard();
    bool current() =>
        fresh() &&
        !_devControlsVisible &&
        _page == 'journey_options' &&
        _personId == person.id &&
        _canAddressJourneyDisclosure(person.id);
    void dispatch(VoidCallback action) {
      if (!current()) {
        ZyraInteractionStyle.cancelSelectionTap();
        return;
      }
      action();
    }

    return ZyraOneJourneyOptionsPage(
      id: person.id,
      firstName: person.firstName,
      surname: person.surname,
      details: '${person.age} · ${person.city}',
      nationality: zyraBrowseNationalityLabel(person.nationalityCode) ?? '—',
      stageNumber: _model.stateFor(person.id) == DraftJourneyState.preparing
          ? 0
          : (_model.stageFor(person.id)?.order ?? 1),
      stageLabel: _model.stateFor(person.id) == DraftJourneyState.preparing
          ? _stateLabel(DraftJourneyState.preparing)
          : _model.stageFor(person.id)?.label ??
                _stateLabel(_model.stateFor(person.id)!),
      photo: _photos?.forIndex(draftProfiles.indexOf(person)).firstOrNull,
      onContinue: () => dispatch(() => _journey(person.id)),
      options: ZyraConceptJourneyOptions(
        id: person.id,
        firstName: person.firstName,
        inline: true,
        lockedPage: true,
        canEnd: true,
        canViewBio: _canViewJourneyBio(person.id),
        canViewCompatibility: _canViewJourneyCompatibility(person.id),
        onSelected: (choice) =>
            dispatch(() => _selectJourneyOption(person, choice)),
        onCancel: () {},
      ),
    );
  }

  void _activity(
    String page, {
    int requestsTab = 0,
    String? viewedReceivedRequestId,
  }) {
    if (!_allowed ||
        _guardianRole ||
        !const {'requests', 'introductions', 'ended'}.contains(page) ||
        requestsTab < 0 ||
        requestsTab > 2) {
      return;
    }
    final viewedId = viewedReceivedRequestId;
    if (viewedId != null &&
        (page != 'requests' ||
            requestsTab != 0 ||
            !_activityRoot ||
            _devControlsVisible ||
            !_profileIds.contains(viewedId) ||
            _model.isBlocked(viewedId) ||
            !_model.hasUnseenReceivedRequest(viewedId) ||
            !_visibleRequests(
              DraftJourneyState.received,
            ).any((person) => person.id == viewedId))) {
      return;
    }
    _move(() {
      _consumeFocusTarget(
        page == 'requests' && requestsTab == 2 ? 'requests_past' : page,
      );
      // Opening an addressed highlight consumes only that item's attention,
      // never its pending request. Generic list entry remains unacknowledged.
      if (viewedId != null) _model.acknowledgeReceivedRequests([viewedId]);
      _tab = 2;
      _requestsTab = requestsTab;
      _expansion.collapseAll();
      _pages
        ..clear()
        ..add(page);
    });
  }

  Widget _activityPage(String title, List<Widget> content) =>
      ZyraRequestActivityPresentation(
        key: ValueKey('concept_activity_$_page'),
        title: title,
        labels: [title],
        pages: [content],
        selectedIndex: 0,
        onChanged: (_) {},
      );

  Widget _requestActivity() {
    final revision = _uiRevision;
    return ZyraRequestActivityPresentation(
      key: const ValueKey('concept_activity_requests'),
      canInteract: () =>
          _allowed &&
          !_devControlsVisible &&
          revision == _uiRevision &&
          !_guardianRole &&
          _tab == 2 &&
          _page == 'requests',
      labels: const ['Received', 'Sent', 'Past'],
      segmentKeys: const [
        ValueKey('draft_requests_0'),
        ValueKey('draft_requests_1'),
        ValueKey('draft_requests_2'),
      ],
      pages: [_requests(0), _requests(1), _pastRequests()],
      selectedIndex: _requestsTab,
      onChanged: (i) {
        if (!_allowed ||
            _devControlsVisible ||
            revision != _uiRevision ||
            _guardianRole ||
            _tab != 2 ||
            _page != 'requests' ||
            i < 0 ||
            i > 2 ||
            i == _requestsTab) {
          return;
        }
        _act(() {
          _requestsTab = i;
          _expansion.collapseAll();
        });
      },
    );
  }

  Widget _introductionsActivity() => ZyraRequestActivityPresentation(
    key: const ValueKey('concept_activity_introductions'),
    title: 'Introductions',
    labels: const ['Introductions'],
    pages: const [
      [
        ZyraRequestActivityEmpty(
          icon: Icons.groups_outlined,
          title: 'No introductions yet',
          message: 'People your Guardians put forward will appear here.',
        ),
      ],
    ],
    selectedIndex: 0,
    onChanged: (_) {},
  );

  Widget _historyActivity() => _activityPage('Ended Journeys', _history());

  ZyraOneJourneyConnectionsAction _connectionAction(
    String key,
    String label,
    IconData? icon,
    VoidCallback? action, {
    bool fitLabel = false,
  }) => ZyraOneJourneyConnectionsAction(
    key: ValueKey(key),
    label: label,
    icon: icon,
    fitLabel: fitLabel,
    onTap: action == null ? null : _bound(action),
  );

  Widget _personRow(
    DraftProfile p,
    String detail,
    String id,
    VoidCallback action,
  ) => ZyraOneJourneyConnectionsPersonCard(
    profile: _displayProfile(p),
    subtitle: detail,
    cardId: id,
    controller: _expansion,
    headerKey: ValueKey('${id}_header'),
    onReport: _bound(() => _open('safety', person: p.id)),
    actions: ZyraOneJourneyConnectionsActionDeck(
      primary: _connectionAction(
        id,
        'View Journey',
        Icons.route_outlined,
        action,
      ),
    ),
  );

  List<Widget> _pastRequests() {
    final history = _model.pastRequests
        .where((entry) => !_model.isBlocked(entry.profileId))
        .toList(growable: false);
    if (history.isEmpty) {
      return const [
        ZyraRequestActivityEmpty(
          icon: Icons.history_rounded,
          title: 'No past requests.',
          message:
              'Requests that were declined, expired or cancelled stay here.',
        ),
      ];
    }
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
    return [
      for (final entry in history)
        ZyraPastRequestActivityCard(
          profile: _displayProfile(
            draftProfiles.firstWhere((person) => person.id == entry.profileId),
          ),
          subtitle:
              '${entry.incoming ? 'Received' : 'Sent'} '
              '${entry.requestedAt.day} ${months[entry.requestedAt.month - 1]}',
          status: switch (entry.outcome) {
            DraftPastRequestOutcome.notTakenUp => 'Not taken up',
            DraftPastRequestOutcome.cancelled => 'Cancelled',
            DraftPastRequestOutcome.youDeclined => 'You declined',
            DraftPastRequestOutcome.youLetItGo => 'You let it go',
          },
          cardId: 'past_request_${entry.id}',
        ),
    ];
  }

  List<Widget> _requests(int tab) {
    final revision = _uiRevision;
    final fresh = _accountFreshGuard();
    bool current() =>
        fresh() &&
        !_devControlsVisible &&
        revision == _uiRevision &&
        !_guardianRole &&
        _tab == 2 &&
        _page == 'requests' &&
        _requestsTab == tab;
    VoidCallback visibleAction(VoidCallback action) => _bound(() {
      if (current()) {
        action();
      }
    });
    VoidCallback requestAction(DraftProfile p, VoidCallback action) {
      final state = _model.stateFor(p.id);
      final intent = _model.acceptanceIntentRevision(p.id);
      final arrival = _model.receivedRequestRevision(p.id);
      return visibleAction(() {
        if (_model.stateFor(p.id) == state &&
            _model.acceptanceIntentRevision(p.id) == intent &&
            _model.receivedRequestRevision(p.id) == arrival) {
          action();
        }
      });
    }

    final expected = tab == 0
        ? DraftJourneyState.received
        : DraftJourneyState.sent;
    final people = draftProfiles
        .where(
          (p) =>
              !_model.isBlocked(p.id) &&
              (_model.stateFor(p.id) == expected ||
                  (_model.isAcceptedWaiting(p.id) &&
                      _model.waitingIsIncoming(p.id) == (tab == 0))),
        )
        .toList();
    if (people.isEmpty) {
      return [
        ZyraRequestActivityEmpty(
          icon: Icons.mail_outline_rounded,
          title: tab == 0
              ? 'No received requests yet.'
              : 'No sent requests yet.',
          message: tab == 0
              ? 'Your Journey requests will appear here.'
              : 'Requests you send will appear here.',
        ),
      ];
    }
    return [
      for (final p in people) ...[
        ZyraRequestActivityCard(
          profile: _displayProfile(p),
          subtitle: _model.isAcceptedWaiting(p.id)
              ? tab == 0
                    ? 'You accepted · waiting for ${p.firstName}'
                    : 'Accepted · choose a place'
              : tab == 0
              ? 'Journey request'
              : 'Waiting for a response',
          detail: _model.isAcceptedWaiting(p.id) && tab == 0
              ? _waitingRequestDetail(p)
              : null,
          cardId: 'request_${p.id}',
          controller: _expansion,
          headerKey: ValueKey('concept_request_${p.id}_header'),
          canInteract: current,
          onToggle: requestAction(p, () {
            if (_expansion.value == 'request_${p.id}') {
              _expansion.close('request_${p.id}');
            } else {
              _expansion.open('request_${p.id}');
            }
          }),
          onReport: requestAction(p, () => _open('safety', person: p.id)),
          primary: _connectionAction(
            'concept_request_profile_${p.id}',
            'View profile',
            Icons.visibility_outlined,
            requestAction(p, () => _open('profile', person: p.id)),
          ),
          actions: _model.isAcceptedWaiting(p.id)
              ? tab == 0
                    ? [
                        _connectionAction(
                          'draft_waiting_confirm_${p.id}',
                          'Demo: ${p.firstName} confirms',
                          Icons.check,
                          requestAction(p, () => _completeWaitingRequest(p)),
                        ),
                        _connectionAction(
                          'draft_waiting_decline_${p.id}',
                          "Demo: ${p.firstName} doesn't go ahead",
                          Icons.close,
                          requestAction(
                            p,
                            () => _act(() => _model.letAcceptedRequestGo(p.id)),
                          ),
                        ),
                      ]
                    : [
                        _connectionAction(
                          'draft_choose_place_${p.id}',
                          'Choose a place',
                          Icons.check,
                          requestAction(p, () => _openAcceptedCapacity(p.id)),
                        ),
                        _connectionAction(
                          'draft_let_go_${p.id}',
                          'Let it go',
                          Icons.close,
                          requestAction(
                            p,
                            () => _act(() => _model.letAcceptedRequestGo(p.id)),
                          ),
                        ),
                      ]
              : tab == 0
              ? [
                  _connectionAction(
                    'draft_accept_${p.id}',
                    'Accept request',
                    Icons.check,
                    _model.canAttemptAccept(p.id)
                        ? requestAction(p, () => _accept(p, true))
                        : null,
                  ),
                  _connectionAction(
                    'draft_decline_${p.id}',
                    'Decline',
                    Icons.close,
                    requestAction(
                      p,
                      () => _act(() => _result(_model.declineReceived(p.id))),
                    ),
                  ),
                ]
              : [
                  _connectionAction(
                    'draft_recipient_${p.id}',
                    'Demo: ${p.firstName} accepts',
                    Icons.check,
                    _model.canAttemptAccept(p.id)
                        ? requestAction(p, () => _accept(p, false))
                        : null,
                  ),
                  _connectionAction(
                    'draft_cancel_${p.id}',
                    'Cancel request',
                    Icons.close,
                    requestAction(
                      p,
                      () => _act(() => _result(_model.cancel(p.id))),
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 14),
      ],
    ];
  }

  void _accept(DraftProfile p, bool incoming) {
    final expected = incoming
        ? DraftJourneyState.received
        : DraftJourneyState.sent;
    if (!_allowed ||
        _guardianRole ||
        _tab != 2 ||
        _page != 'requests' ||
        _requestsTab != (incoming ? 0 : 1) ||
        _model.stateFor(p.id) != expected ||
        !_model.canAttemptAccept(p.id)) {
      return;
    }
    if (incoming && !_model.hasCapacity) {
      _move(() {
        _personId = p.id;
        _capacityRequest = (id: p.id, incoming: incoming);
        _capacityEndingId = null;
        _pages.add('request_capacity');
      });
      return;
    }
    _act(() {
      final ok = incoming
          ? _model.acceptReceived(p.id)
          : _model.simulateRecipientAccept(p.id);
      _result(ok);
      if (ok && _model.stateFor(p.id) == DraftJourneyState.preparing) {
        _personId = p.id;
        _pages.add('journey');
      }
    });
  }

  String _waitingRequestDetail(DraftProfile p) {
    final held = _model.heldEndingId(p.id);
    final chosen = draftProfiles.where((p) => p.id == held).firstOrNull;
    return chosen == null
        ? 'Waiting for ${p.firstName} to confirm. Nothing changes for you until then.'
        : 'Waiting for ${p.firstName} to confirm. Your Journey with ${chosen.firstName} ends only when she confirms.';
  }

  void _completeWaitingRequest(DraftProfile p) {
    if (!_model.isAcceptedWaiting(p.id) || !_model.waitingIsIncoming(p.id)) {
      return;
    }
    _act(() {
      if (_model.confirmWaitingRequest(p.id)) {
        _personId = p.id;
        _pages.add('journey');
      }
    });
  }

  void _openAcceptedCapacity(String id) {
    if (!_allowed ||
        _guardianRole ||
        _devControlsVisible ||
        !_model.isAcceptedWaiting(id) ||
        _model.waitingIsIncoming(id) ||
        _model.isBlocked(id)) {
      return;
    }
    _move(() {
      _consumeFocusTarget('request_capacity', personId: id);
      _tab = 2;
      _requestsTab = 1;
      _personId = id;
      if (_model.hasCapacity && _model.confirmWaitingRequest(id)) {
        _pages
          ..clear()
          ..addAll(['requests', 'journey']);
      } else {
        _pages
          ..clear()
          ..addAll(['requests', 'request_capacity']);
        _capacityRequest = (id: id, incoming: false);
      }
    });
  }

  bool _capacityRequestAdmitted(({String id, bool incoming}) request) =>
      request.incoming
      ? _model.stateFor(request.id) == DraftJourneyState.received
      : _model.isAcceptedWaiting(request.id) &&
            !_model.waitingIsIncoming(request.id);

  bool _currentCapacityRequest(
    ({String id, bool incoming}) request,
    int revision,
  ) =>
      _allowed &&
      !_guardianRole &&
      _tab == 2 &&
      _page == 'request_capacity' &&
      _personId == request.id &&
      _capacityRequest == request &&
      _uiRevision == revision &&
      !_model.isBlocked(request.id) &&
      _capacityRequestAdmitted(request);

  Widget _requestCapacityView() {
    final request = _capacityRequest;
    final person = _person;
    if (request == null || person == null || request.id != person.id) {
      return _unavailable();
    }
    final revision = _uiRevision;
    final fresh = _accountFreshGuard();
    final intent = _model.acceptanceIntentRevision(request.id);
    bool current() =>
        fresh() &&
        !_devControlsVisible &&
        _model.acceptanceIntentRevision(request.id) == intent &&
        _currentCapacityRequest(request, revision);
    final choices = _currentJourneys;
    final ending = choices
        .where((candidate) => candidate.id == _capacityEndingId)
        .firstOrNull;
    final choice = ZyraRequestCapacityChoice(
      key: ValueKey('request_capacity_${request.id}'),
      firstName: person.firstName,
      capacity: _model.capacity,
      holdEnding: request.incoming && _model.peerOccupied(request.id),
      acceptedSent: !request.incoming,
      selectedId: ending?.id,
      items: [
        for (final choice in choices)
          ZyraRequestCapacityItem(
            id: choice.id,
            name: _model.isBlocked(choice.id)
                ? 'User not found'
                : '${choice.firstName} ${choice.surname}'.trim(),
            subtitle: _model.isBlocked(choice.id)
                ? null
                : '${choice.age} · ${choice.city}',
            portrait: _model.isBlocked(choice.id)
                ? null
                : _browsePhotoRenderer.build(
                    context,
                    _displayProfile(choice).photoUrl,
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                  ),
          ),
      ],
      onSelected: (id) {
        if (!current() ||
            _capacityConfirmOpen ||
            !choices.any((choice) => choice.id == id)) {
          return;
        }

        _act(() => _capacityEndingId = id);
      },
      onContinue:
          ending == null ||
              _capacityConfirmOpen ||
              !_model.canReplaceJourneyForRequest(
                request.id,
                ending.id,
                incoming: request.incoming,
              )
          ? null
          : () {
              if (!current()) return;
              if (request.incoming && _model.peerOccupied(request.id)) {
                _act(() {
                  if (_model.replaceJourneyForRequest(
                    request.id,
                    ending.id,
                    incoming: true,
                  )) {
                    _pages.removeLast();
                    _expansion.open('request_${request.id}');
                  }
                });
              } else {
                _confirmCapacityReplacement(request, ending);
              }
            },
      onCancel: () {
        if (!current() || _capacityConfirmOpen) return;

        _act(() {
          if (!request.incoming) _model.letAcceptedRequestGo(request.id);
          _pages.removeLast();
          _capacityRequest = null;
          _capacityEndingId = null;
        });
      },
    );
    return SafeArea(
      child: Padding(padding: const EdgeInsets.all(20), child: choice),
    );
  }

  Future<void> _confirmCapacityReplacement(
    ({String id, bool incoming}) request,
    DraftProfile ending,
  ) async {
    final revision = _uiRevision;
    final endingState = _model.stateFor(ending.id);
    var expectedStamp = _devRouteStamp;
    final fresh = _accountFreshGuard(
      expectedNavigatorStamp: () => expectedStamp,
    );
    final endingAttempt = _model.snapshot().attemptRevisions[ending.id];
    int? dialogStamp;
    var consumed = false;
    final intent = _model.acceptanceIntentRevision(request.id);
    bool current() =>
        fresh() &&
        !_devControlsVisible &&
        _model.acceptanceIntentRevision(request.id) == intent &&
        _currentCapacityRequest(request, revision) &&
        _capacityEndingId == ending.id &&
        _model.stateFor(ending.id) == endingState &&
        _model.snapshot().attemptRevisions[ending.id] == endingAttempt &&
        _model.canReplaceJourneyForRequest(
          request.id,
          ending.id,
          incoming: request.incoming,
        );
    if (_capacityConfirmOpen || !current()) return;
    final target = _person!;
    final endingName = _model.isBlocked(ending.id)
        ? 'the unavailable Journey'
        : 'your Journey with ${ending.firstName}';
    _capacityConfirmOpen = true;

    try {
      final confirmed = await showZyraGlassDialog<bool>(
        context: _tapContext,
        builder: (dialogContext) {
          dialogStamp ??= _devRouteStamp;
          void choose(bool value) {
            if (!consumed &&
                dialogContext.mounted &&
                ModalRoute.of(dialogContext)?.isCurrent == true) {
              consumed = true;
              final unchanged =
                  dialogStamp == _devRouteStamp &&
                  (widget.canActInOwnedDialog?.call() ?? _allowed);
              Navigator.of(dialogContext).pop(value && unchanged);
              // Admit only this exact dialog's own pop. Extra route changes
              // while it was open refuse confirmation above and below.
              expectedStamp = _devRouteStamp;
            }
          }

          return ZyraTapFeedback(
            level: () => _accountSession.hapticLevel,
            canAct: () =>
                dialogContext.mounted &&
                !consumed &&
                ModalRoute.of(dialogContext)?.isCurrent == true,
            child: Builder(
              builder: (actionContext) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'End Journey & accept request?',
                    style: ZyraText.heading(size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This permanently ends $endingName. Your history stays. '
                    'You and ${target.firstName} can then prepare to begin together.',
                    style: ZyraText.subtext(),
                  ),
                  const SizedBox(height: 20),
                  ZyraFloatingSurface(
                    radius: 999,
                    circle: false,
                    gold: false,
                    child: OutlinedButton(
                      key: const ValueKey('request_capacity_confirm'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        side: BorderSide(color: ZyraColors.destructive),
                      ),
                      onPressed: ZyraTapFeedback.onTap(
                        actionContext,
                        () => choose(true),
                        level: () => _accountSession.hapticLevel,
                      ),
                      child: Text(
                        request.incoming
                            ? 'End & accept request'
                            : 'End & begin with ${target.firstName}',
                        style: ZyraText.button(color: ZyraColors.destructive),
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('request_capacity_keep'),
                    onPressed: ZyraTapFeedback.onTap(
                      actionContext,
                      () => choose(false),
                      level: () => _accountSession.hapticLevel,
                    ),
                    child: Text('Keep my Journeys', style: ZyraText.button()),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (confirmed != true || !current()) return;
      _act(() {
        final replaced = _model.replaceJourneyForRequest(
          request.id,
          ending.id,
          incoming: request.incoming,
        );
        if (!replaced) return;
        _pages
          ..removeLast()
          ..add('journey');
        _capacityRequest = null;
        _capacityEndingId = null;
      });
    } finally {
      _capacityConfirmOpen = false;
      if (_allowed) setState(() {});
    }
  }

  Widget _connectionCard(
    DraftProfile p, {
    bool compact = false,
    bool fillHeight = false,
    bool expandedOptions = false,
    bool inlineOptionsFillHeight = true,
  }) {
    final state = _model.stateFor(p.id)!;
    final controlsEpoch = _devControlsEpoch;
    final navigatorStamp = _devRouteStamp;
    bool currentCard() =>
        _allowed &&
        !_devControlsVisible &&
        controlsEpoch == _devControlsEpoch &&
        navigatorStamp == _devRouteStamp &&
        ModalRoute.of(context)?.isCurrent == true &&
        !_model.isBlocked(p.id) &&
        _model.stateFor(p.id) == state;
    if (_model.isBlocked(p.id)) {
      return _card([
        Text(
          'User not found',
          key: ValueKey('concept_blocked_journey_${p.id}'),
          style: ZyraText.heading(size: 18),
        ),
        _body(
          'This Journey place is retained. The profile and conversation are unavailable.',
          small: true,
        ),
        _button(
          'draft_end_${p.id}',
          'End Journey',
          () => _showJourneyAction(p, 'end'),
        ),
      ]);
    }
    final ended = state == DraftJourneyState.ended;
    final primary = _connectionAction(
      ended ? 'draft_restart_${p.id}' : 'draft_journey_${p.id}',
      ended ? 'Request restart' : 'Continue Journey',
      null,
      ended && !_canRequestEndedRestart(p.id)
          ? null
          : () {
              if (!currentCard()) return;
              ended ? _open('ended_restart', person: p.id) : _journey(p.id);
            },
      fitLabel: true,
    );
    final stageLabel = _model.stageFor(p.id)?.label ?? _stateLabel(state);
    final actions = ZyraOneJourneyConnectionsActionDeck(
      primary: primary,
      primaryTrailing: ZyraConceptJourneyOptionsButton(
        key: ValueKey('draft_journey_options_${p.id}'),
        isExpandable: true,
        expanded: expandedOptions,
        onTap: _bound(() {
          if (currentCard()) _toggleJourneyCardOptions(p);
        }),
      ),
    );
    if (state == DraftJourneyState.active ||
        state == DraftJourneyState.preparing ||
        ended) {
      return ZyraOneJourneyConnectionsActiveCard(
        profile: _displayProfile(p),
        stateLabel: _stateLabel(state),
        actions: actions,
        compact: compact,
        fillHeight: fillHeight,
        cardDesign: ZyraOneJourneyCardDesign.portraitSplit,
        stageLabel: stageLabel,
        primaryAction: actions.primaryRow,
        inlineOptions: expandedOptions ? _inlineJourneyOptions(p) : null,
        inlineOptionsFillHeight: inlineOptionsFillHeight,
      );
    }
    return _personRow(
      p,
      _stateLabel(state),
      'draft_journey_${p.id}',
      () => _journey(p.id),
    );
  }

  bool _journeyCardOptionsContext(String id) =>
      !_guardianRole &&
      !_model.isBlocked(id) &&
      ((_tab == 1 &&
              _page == null &&
              _currentJourneys.any((person) => person.id == id)) ||
          (_endedHistoryRoot &&
              (_page == 'ended' || _page == 'past_journeys') &&
              _model.stateFor(id) == DraftJourneyState.ended));

  bool _canExpandJourneyCard(String id) =>
      _allowed &&
      !_devControlsVisible &&
      ModalRoute.of(context)?.isCurrent == true &&
      !_journeyOptionsOpen &&
      _journeyCardOptionsContext(id);

  void _toggleJourneyCardOptions(DraftProfile person) {
    if (!_canExpandJourneyCard(person.id)) return;

    _act(() {
      _expandedJourneyOptionsId = _expandedJourneyOptionsId == person.id
          ? null
          : person.id;
    });
  }

  Widget _inlineJourneyOptions(DraftProfile person) {
    final revision = _uiRevision;
    final controlsEpoch = _devControlsEpoch;
    final navigatorStamp = _devRouteStamp;
    final fresh = _accountFreshGuard();
    final state = _model.stateFor(person.id);
    bool current() =>
        fresh() &&
        controlsEpoch == _devControlsEpoch &&
        navigatorStamp == _devRouteStamp &&
        revision == _uiRevision &&
        _expandedJourneyOptionsId == person.id &&
        _canExpandJourneyCard(person.id) &&
        _model.stateFor(person.id) == state;
    return ZyraConceptJourneyOptions(
      id: person.id,
      firstName: person.firstName,
      inline: true,
      archived: state == DraftJourneyState.ended,
      canViewBio: state == DraftJourneyState.ended
          ? _canViewEndedBio(person.id)
          : _canViewJourneyBio(person.id),
      canViewCompatibility: state == DraftJourneyState.ended
          ? _canViewEndedCompatibility(person.id)
          : _canViewJourneyCompatibility(person.id),
      canViewGuardians:
          state != DraftJourneyState.ended || _endedReadWindowOpen(person.id),
      endedReadWindowOpen:
          state == DraftJourneyState.ended && _endedReadWindowOpen(person.id),
      canEnd: state != null && state != DraftJourneyState.ended,
      onSelected: (choice) {
        if (!current()) return;

        _selectJourneyOption(person, choice);
      },
      onCancel: () {
        if (current()) _act(() => _expandedJourneyOptionsId = null);
      },
    );
  }

  void _selectJourneyOption(
    DraftProfile person,
    ZyraConceptJourneyOption choice,
  ) {
    final ended = _model.stateFor(person.id) == DraftJourneyState.ended;
    if (ended && !_canAddressEndedJourney(person.id)) return;
    switch (choice) {
      case ZyraConceptJourneyOption.profile:
        _open('profile', person: person.id);
      case ZyraConceptJourneyOption.timeline:
        _open('timeline', person: person.id);
      case ZyraConceptJourneyOption.bio:
        _open(ended ? 'ended_bio' : 'bio', person: person.id);
      case ZyraConceptJourneyOption.compatibility:
        _open(
          ended ? 'ended_compatibility' : 'journey_compatibility',
          person: person.id,
        );
      case ZyraConceptJourneyOption.guardians:
        _open(
          ended ? 'ended_guardians' : 'journey_guardians',
          person: person.id,
        );
      case ZyraConceptJourneyOption.report:
        _open('safety', person: person.id);
      case ZyraConceptJourneyOption.end:
        if (!ended) _showJourneyAction(person, 'end');
    }
  }

  Future<void> _openJourneyOptions(DraftProfile person) async {
    if (!_allowed || _guardianRole || _journeyOptionsOpen) return;
    final state = _model.stateFor(person.id);
    if (state == null) return;
    final fresh = _accountFreshGuard();
    // The owned sheet makes its parent route non-current. Capture only its
    // display state while the parent is current; the returned intent still
    // rechecks fresh ownership and the live disclosure gate after dismissal.
    final canViewBio = _canViewJourneyBio(person.id);
    final canViewCompatibility = _canViewJourneyCompatibility(person.id);
    _journeyOptionsOpen = true;
    try {
      final choice = await showModalBottomSheet<ZyraConceptJourneyOption>(
        context: _tapContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black38,
        builder: (sheetContext) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
          ),
          child: ZyraConceptJourneyOptions(
            id: person.id,
            firstName: person.firstName,
            canViewBio: canViewBio,
            canViewCompatibility: canViewCompatibility,
            canEnd: state != DraftJourneyState.ended,
            onSelected: (value) {
              if (!sheetContext.mounted ||
                  ModalRoute.of(sheetContext)?.isCurrent != true) {
                return;
              }
              // The owned modal temporarily makes the parent route non-current.
              // This only returns an intent; recheck owner/revision/state below,
              // after dismissal restores the parent route. Never mutate here.
              Navigator.pop(sheetContext, value);
            },
            onCancel: () {
              if (!sheetContext.mounted ||
                  ModalRoute.of(sheetContext)?.isCurrent != true) {
                return;
              }
              Navigator.pop(sheetContext);
            },
          ),
        ),
      );
      if (!fresh() || choice == null || _model.stateFor(person.id) != state) {
        return;
      }
      _selectJourneyOption(person, choice);
    } finally {
      _journeyOptionsOpen = false;
    }
  }

  void _showJourneyAction(DraftProfile person, String action) {
    if (action != 'end') return;
    _move(() {
      _personId = person.id;
      _confirmation = action;
      _pages.add('journey_action');
    });
  }

  Widget _journeyCompatibility() {
    final person = _person;
    if (person == null || !_canAddressJourneyDisclosure(person.id)) {
      return _unavailable();
    }
    if (!_canViewJourneyCompatibility(person.id)) {
      return _journeyDisclosureLocked(bio: false);
    }
    final result = _compatibilityAccess.resultFor(person.id);
    if (result != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: ZyraDraftCompatibilityPresentation(
            key: ValueKey(('draft_journey_compatibility', person.id)),
            personName: person.firstName,
            balance: _compatibilityAccess.balance,
            overallScore: result.overallScore,
            revealed: true,
          ),
        ),
      );
    }
    return _pageScroll([
      _heading('Compatibility score', ''),
      _card([
        _eyebrow('COMPATIBILITY REVEAL COMPLETE'),
        _title('Your result', size: 25),
        _body('You both chose to reveal. Your result is not available yet.'),
      ]),
    ]);
  }

  Widget _journeyDisclosureLocked({required bool bio}) {
    final person = _person;
    if (person == null || !_canAddressJourneyDisclosure(person.id)) {
      return _unavailable();
    }
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    final page = _page;
    final waitingOnMain =
        _model.stateFor(person.id) == DraftJourneyState.active &&
        !_model.canParticipateInJourney(person.id);
    final message = waitingOnMain
        ? 'This Journey is waiting for its Main Guardians before you can continue.'
        : bio
        ? 'Complete Journey Bio together to view it here.'
        : 'Complete Compatibility Reveal together to view your result.';
    return SafeArea(
      key: ValueKey(
        'draft_${bio ? 'bio' : 'journey_compatibility'}_locked_${person.id}',
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => ZyraShadowScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heading(
                    bio ? 'Journey Bio' : 'Compatibility score',
                    bio ? 'You and ${person.firstName}' : '',
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 34,
                            color: ZyraColors.journeyGold,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            bio
                                ? 'A little further together'
                                : 'Your result stays private',
                            style: ZyraText.heading(size: 23),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            // Keep the completion explanation clear of the
                            // existing developer rail at the screen edge.
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              message,
                              style: ZyraText.subtext(size: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _button(
                    'draft_disclosure_continue_${person.id}',
                    'Continue Journey',
                    () {
                      if (fresh() &&
                          revision == _uiRevision &&
                          page == _page &&
                          _personId == person.id &&
                          _canAddressJourneyDisclosure(person.id)) {
                        _journey(person.id);
                      }
                    },
                    primary: true,
                    fitLabel: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _journeyGuardians() {
    final person = _person;
    if (!_allowed ||
        _guardianRole ||
        _page != 'journey_guardians' ||
        person == null ||
        _model.isBlocked(person.id) ||
        !_currentJourneys.any((p) => p.id == person.id)) {
      return _unavailable();
    }
    // This protected local shell uses the SAME fictional other-family fixture
    // as the retained Active Journey preview, never the owner's management
    // roster. These DTOs confer no real disclosure/reveal authority and never
    // fall back from a failed live lookup. Production adapters stay held.
    return ZyraJourneyPeerGuardiansPresentation(
      key: ValueKey('draft_journey_guardians_${person.id}'),
      subjectId: person.id,
      firstName: person.firstName,
      guardians: [
        for (final guardian
            in ZyraJourneyGuardianSelection.otherGuardianPreview)
          GuardianInfo(
            firstName: guardian.firstName,
            relationship: guardian.relationship,
            isMain: guardian.isMain,
          ),
      ],
    );
  }

  Widget _journeyActionConfirmation() {
    final person = _person;
    if (person == null || _confirmation != 'end') {
      return _unavailable();
    }
    final id = person.id;
    final state = _model.stateFor(id);
    final allowed = state != null && state != DraftJourneyState.ended;
    final blocked = _model.isBlocked(id);
    final profile = blocked ? null : _displayProfile(person);
    return KeyedSubtree(
      key: ValueKey('draft_journey_action_$id'),
      child: ZyraDraftJourneyEndPresentation(
        subjectId: id,
        title: blocked ? 'End this Journey?' : 'End with ${person.firstName}?',
        name: blocked ? null : '${person.firstName} ${person.surname}',
        portrait: profile == null || profile.photos.isEmpty
            ? null
            : _browsePhotoRenderer.build(
                context,
                profile.photos.first,
                width: 104,
                height: 128,
                alignment: Alignment.topCenter,
              ),
        onConfirm: !allowed
            ? null
            : _bound(
                () => _act(() {
                  final ok = _model.end(id);
                  _result(ok);
                  if (ok) {
                    _confirmation = null;
                    _message.clear();
                    _pages.removeLast();
                  }
                }),
              ),
        onKeep: _bound(_back),
      ),
    );
  }

  List<Widget> _history() {
    final people = draftProfiles.where((p) {
      final s = _model.stateFor(p.id);
      return s == DraftJourneyState.ended;
    }).toList();
    return people.isEmpty
        ? [
            ZyraRequestActivityEmpty(
              icon: Icons.route_outlined,
              title: 'No ended Journeys.',
              message: '',
            ),
          ]
        : [
            for (final p in people) ...[
              if (_model.isBlocked(p.id))
                _card([
                  Text(
                    'User not found',
                    key: ValueKey('concept_blocked_archive_${p.id}'),
                    style: ZyraText.heading(size: 18),
                  ),
                  _body(
                    'This ended Journey remains archived. Its profile and messages are unavailable.',
                    small: true,
                  ),
                  _button(
                    'draft_journey_${p.id}',
                    'View archive',
                    () => _journey(p.id),
                  ),
                ])
              else
                KeyedSubtree(
                  key: ValueKey('draft_journey_${p.id}_header'),
                  child: _connectionCard(
                    p,
                    expandedOptions: _expandedJourneyOptionsId == p.id,
                    inlineOptionsFillHeight: false,
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ];
  }

  Widget _endedJourneyDetail({required bool bio}) {
    final person = _person;
    if (person == null || !_canAddressEndedJourney(person.id)) {
      return _unavailable();
    }
    if (bio && _canViewEndedBio(person.id)) {
      return KeyedSubtree(
        key: ValueKey('draft_ended_bio_${person.id}'),
        child: ZyraDraftJourneyBioPresentation(
          subjectId: person.id,
          firstName: person.firstName,
          projection: ZyraDraftJourneyBioProjection.fixtureFor(
            person.id,
            useLegacyFixture: true,
          ),
          portrait: _journeyBioPortrait(person),
        ),
      );
    }
    return _pageScroll([
      _heading(bio ? 'Journey Bio' : 'Guardians', ''),
      _card([
        _title(
          !_endedReadWindowOpen(person.id)
              ? 'Journey access has ended'
              : bio
              ? 'Not shared in this Journey'
              : 'No saved Guardian details',
          size: 23,
        ),
        _body(
          !_endedReadWindowOpen(person.id)
              ? 'Journey Bio and Guardian details are available for three months after a Journey ends. A new Journey needs a new accepted request.'
              : bio
              ? 'Journey Bio was not shared before this Journey ended. '
                    'Opening its archive does not unlock private details.'
              : 'No Guardian details were saved in this archive. '
                    'Today’s Guardian list is not a record of this past Journey.',
        ),
      ]),
    ], key: ValueKey('draft_ended_${bio ? 'bio' : 'guardians'}_${person.id}'));
  }

  Widget _endedRestart() {
    final person = _person;
    if (person == null || !_canRequestEndedRestart(person.id)) {
      return _unavailable();
    }
    return _pageScroll([
      _heading('Request restart', 'You and ${person.firstName}'),
      _card([
        _title('A new Journey, not a reopened one', size: 23),
        _body(
          '${person.firstName} would need to accept a new request. '
          'Your ended Journey and its archive stay unchanged.',
        ),
        _body(
          'Restart requests are not available in this preview. '
          'No request has been sent.',
          small: true,
        ),
        _button(
          'draft_restart_send_${person.id}',
          'Request restart',
          null,
          primary: true,
          fitLabel: true,
        ),
      ]),
    ], key: ValueKey('draft_ended_restart_${person.id}'));
  }

  Widget _journeyView() {
    final p = _person;
    if (p == null || _model.stateFor(p.id) == null) return _unavailable();
    if (_model.isBlocked(p.id)) return _userNotFoundView();
    if (_model.stateFor(p.id) == DraftJourneyState.ended) {
      return _archiveView(p);
    }
    final stage = _model.stageFor(p.id);
    final state = _model.stateFor(p.id);
    if (_model.isBioStepOpen(p.id) && _model.canParticipateInJourney(p.id)) {
      return _journeyBioStep(p);
    }
    final actions = ZyraShadowScrollView(
      key: const ValueKey('draft_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      child: _journeyLocalActions(),
    );
    if (stage == null || state != DraftJourneyState.active) {
      return SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Journey with ${p.firstName}',
                    textAlign: TextAlign.center,
                    style: ZyraText.heading(size: 16),
                  ),
                ),
                IconButton(
                  key: const ValueKey('concept_journey_timeline'),
                  tooltip: 'Timeline',
                  onPressed: _tap(_bound(() => _open('timeline'))),
                  icon: const Icon(Icons.history),
                ),
                IconButton(
                  tooltip: 'Journey options',
                  onPressed: _tap(_bound(() => _openJourneyOptions(p))),
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
            Expanded(child: actions),
          ],
        ),
      );
    }
    return ZyraConceptJourneyPresentation(
      key: ValueKey('concept_journey_${p.id}'),
      firstName: p.firstName,
      stage: stage,
      localActionBody: actions,
      onBack: _bound(_back),
      showBackButton: false,
      onTimeline: _bound(() => _open('timeline')),
      onBio: _bound(() => _open('bio')),
      options: IconButton(
        key: const ValueKey('concept_journey_menu'),
        tooltip: 'Journey options',
        onPressed: _tap(_bound(() => _openJourneyOptions(p))),
        icon: Icon(Icons.more_horiz, color: ZyraColors.foregroundMuted),
      ),
    );
  }

  Widget _archiveView(DraftProfile person) => SafeArea(
    key: ValueKey('concept_archive_${person.id}'),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Journey with ${person.firstName}',
                textAlign: TextAlign.center,
                style: ZyraText.heading(size: 16),
              ),
            ),
          ],
        ),
        Expanded(
          child: ZyraShadowScrollView(
            key: const ValueKey('draft_scroll'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _title('A chapter kept, not reopened.', size: 25),
                _body(
                  'This ended Journey is read-only. No messages or new request can reopen this attempt.',
                ),
                const SizedBox(height: 16),
                _timeline(person.id),
                const SizedBox(height: 16),
                _title('Messages', size: 18),
                _body('No real conversation is loaded.', small: true),
                for (final message in _messages[person.id] ?? <String>[])
                  _body('You · $message'),
                if ((_messages[person.id] ?? <String>[]).isEmpty)
                  _body('No messages in this archive.', small: true),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _userNotFoundView() => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: ZyraEmptyState(
            key: ValueKey('concept_user_not_found'),
            icon: Icons.person_off_outlined,
            title: 'User not found',
            message: 'This profile and conversation are unavailable.',
          ),
        ),
      ],
    ),
  );

  Widget _journeyLocalActions() {
    final p = _person;
    if (p == null || _model.stateFor(p.id) == null) return _unavailable();
    final id = p.id;
    final state = _model.stateFor(id)!;
    final stage = _model.stageFor(id);
    final freshBegin = _accountFreshGuard();
    final beginControlsEpoch = _devControlsEpoch;
    final beginRouteStamp = _devRouteStamp;
    void begin() {
      if (!freshBegin() ||
          _devControlsVisible ||
          beginControlsEpoch != _devControlsEpoch ||
          beginRouteStamp != _devRouteStamp ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      _beginWithGuardianAgreement(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state == DraftJourneyState.preparing)
          _card([
            _title('Choose to begin, together.', size: 26),
            _body(
              'You both accepted the invitation. Each person still chooses '
              'to begin. Until then, no conversation or private compatibility result opens.',
            ),
            _body(
              'You: ${_model.isReady(id) ? 'ready' : 'not yet confirmed'}',
              gold: true,
            ),
            _body(
              '${p.firstName}: ${_model.peerIsReady(id) ? 'ready' : 'waiting'}',
            ),
            _button(
              'draft_ready_$id',
              _model.isReady(id) ? 'You are ready' : 'I’m ready to begin',
              _model.isReady(id)
                  ? null
                  : () => _act(() => _model.markReady(id)),
              primary: true,
            ),
            _button(
              'draft_peer_ready_$id',
              'Demo: ${p.firstName} confirms readiness',
              _model.peerIsReady(id)
                  ? null
                  : () => _act(() => _model.simulatePeerReady(id)),
            ),
            _button(
              'draft_begin_$id',
              'Begin your Journey',
              _model.isReady(id) && _model.peerIsReady(id) ? begin : null,
              primary: true,
            ),
          ])
        else if (state == DraftJourneyState.ended)
          _card([
            _title('A chapter kept, not reopened.', size: 25),
            _body(
              'This attempt has ended. Its Timeline remains read-only. '
              'No messages or new request can reopen this attempt.',
            ),
          ])
        else if (stage != null) ...[
          _stageContent(p, stage),
        ],
        const SizedBox(height: 24),
        if (state == DraftJourneyState.preparing ||
            state == DraftJourneyState.active) ...[
          const SizedBox(height: 10),
          _button(
            'draft_end_$id',
            'End Journey',
            () => _showJourneyAction(p, 'end'),
          ),
        ],
      ],
    );
  }

  Widget _stageContent(DraftProfile p, ZyraJourneyStage stage) {
    final id = p.id;
    final active = _model.canParticipateInJourney(id);
    final mine = _model.hasSentSalam(id);
    final theirs = _model.peerHasSentSalam(id);
    final revealMine = _model.hasChosenCompatibilityReveal(id);
    final revealTheirs = _model.peerHasChosenCompatibilityReveal(id);
    late final Widget ordinary;
    if (!active && _model.stateFor(id) == DraftJourneyState.active) {
      final waitingOnOther = _model.ownMainGuardianPresent;
      ordinary = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 42),
        child: Column(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 34,
              color: ZyraColors.journeyGold,
            ),
            const SizedBox(height: 18),
            Text(
              waitingOnOther
                  ? 'This Journey is waiting'
                  : 'Choose a Main Guardian',
              style: ZyraText.heading(size: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              waitingOnOther
                  ? '${p.firstName} needs to choose a Main Guardian before this Journey can continue.'
                  : 'This Journey is held until you choose the Guardian who leads.',
              style: ZyraText.subtext(size: 13),
              textAlign: TextAlign.center,
            ),
            if (!waitingOnOther) ...[
              const SizedBox(height: 24),
              _button(
                'concept_missing_main',
                'Go to Guardian',
                () => _tabTo(3),
              ),
            ],
          ],
        ),
      );
    } else if (stage.value == 'salam_exchange') {
      ordinary = ZyraConceptJourneyThresholdBody(
        firstName: p.firstName,
        mine: mine,
        theirs: theirs,
        salam: true,
        selfPhoto: _accountData.photoAsset,
        otherPhoto: _displayProfile(p).photoUrl,
        headline: mine && theirs
            ? stage.completionHeading
            : theirs
            ? '${p.firstName} sent Salam'
            : mine
            ? 'Salam sent'
            : 'Assalamu alaikum',
        body: mine && theirs
            ? stage.completionLine
            : theirs
            ? 'Wa alaikum assalam.'
            : mine
            ? "We'll let you know when ${p.firstName} returns it."
            : 'Send Salam to ${p.firstName} to begin.',
        actionKey: ValueKey('draft_salam_$id'),
        actionLabel: mine
            ? null
            : theirs
            ? 'Return Salam'
            : 'Send Salam',
        onAction: active && !mine
            ? _bound(() => _act(() => _model.sendSalam(id)))
            : null,
      );
    } else if (stage.value == 'compatibility_reveal') {
      ordinary = _model.compatibilityRevealed(id)
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 36),
              child: Column(
                children: [
                  Text(
                    stage.completionHeading,
                    style: ZyraText.heading(size: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You both chose to reveal.',
                    style: ZyraText.subtext(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '—',
                    style: ZyraText.heading(
                      size: 44,
                      color: ZyraColors.ink(0.38),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'There is not enough between you yet to work out a figure. '
                    'It appears here once you have both covered more ground.',
                    style: ZyraText.subtext(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            )
          : ZyraConceptJourneyThresholdBody(
              firstName: p.firstName,
              mine: revealMine,
              theirs: revealTheirs,
              selfPhoto: _accountData.photoAsset,
              otherPhoto: _displayProfile(p).photoUrl,
              headline: revealMine ? 'Reveal chosen' : stage.label,
              body: revealMine
                  ? 'Waiting for ${p.firstName}. You open the result together.'
                  : 'Neither of you sees the result until you both choose to reveal.',
              actionKey: ValueKey('draft_reveal_$id'),
              actionLabel: revealMine ? null : 'Reveal Compatibility',
              actionIcon: Icons.visibility_outlined,
              onAction: active && !revealMine
                  ? _bound(
                      () => _act(() => _model.chooseCompatibilityReveal(id)),
                    )
                  : null,
            );
    } else if (stage.value == 'wali_gate') {
      ordinary = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 42),
        child: Column(
          children: [
            Text(
              stage.completionHeading,
              style: ZyraText.heading(size: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              stage.completionLine,
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _button(
              'concept_stage_guardians',
              'Go to Guardian',
              () => _tabTo(3),
            ),
          ],
        ),
      );
    } else if (stage.value.startsWith('phase_')) {
      ordinary = ZyraConceptJourneyFirstQuestion(
        key: ValueKey('concept_phase_first_${stage.value}'),
        stage: stage,
      );
    } else if (stage.value == 'family_stage') {
      ordinary = Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stage.label, style: ZyraText.heading(size: 18)),
            const SizedBox(height: 6),
            Text(
              'Your families meet your Journey here. '
              "${p.firstName}'s Guardian asks you their questions; "
              'yours asks theirs. Answer as if they were sitting across from you — they are.',
              style: ZyraText.subtext(),
            ),
            const SizedBox(height: 18),
            Text(
              "${p.firstName}'s family asks:",
              style: ZyraText.body(size: 13, color: ZyraColors.ink(0.70)),
            ),
            const SizedBox(height: 10),
            for (final q in JourneyQuestions.waliToSeeker) ...[
              Text(q.text, style: ZyraText.body(size: 14)),
              const SizedBox(height: 6),
              TextField(
                key: ValueKey('concept_family_display_${q.id}'),
                readOnly: true,
                maxLines: 3,
                style: TextStyle(color: ZyraColors.foreground),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ZyraColors.foreground.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Your answer…',
                  hintStyle: TextStyle(color: ZyraColors.ink(0.38)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      );
    } else {
      ordinary = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Column(
          children: [
            Text(
              stage.completionHeading,
              style: ZyraText.heading(size: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '${stage.completionLine} Your Timeline keeps going, and your Guardians remain part of it.',
              style: ZyraText.subtext(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _tap(_bound(() => _open('timeline'))),
              child: Text(
                'Read your story so far',
                style: ZyraText.subtext(size: 12),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ordinary,
        const SizedBox(height: 28),
        Divider(
          height: 1,
          color: ZyraColors.foreground.withValues(alpha: 0.12),
        ),
        const SizedBox(height: 18),
        _eyebrow('LOCAL PREVIEW CONTROLS'),
        _body(
          'These controls simulate the other person and chapter checkpoints. '
          'Question fields are display-only here. No messages, private answers, credits '
          'or Family Review decisions are sent or approved.',
          small: true,
        ),
        if (stage.value == 'salam_exchange')
          _button(
            'draft_peer_salam_$id',
            theirs
                ? 'Sample Salam received'
                : 'Demo: ${p.firstName} sends Salam',
            active && !theirs
                ? () => _act(() => _model.simulatePeerSalam(id))
                : null,
          ),
        if (stage.value == 'compatibility_reveal') ...[
          _button(
            'draft_peer_reveal_$id',
            'Demo: ${p.firstName} also chooses reveal',
            active && !revealTheirs
                ? () => _act(() => _model.simulatePeerCompatibilityReveal(id))
                : null,
          ),
          _body(
            'This local preview has no score or private result. '
            'Your real answers, credit balance and results are untouched.',
            small: true,
          ),
        ],
        if (stage.value == 'conversation') ...[
          for (final message in _messages[id] ?? <String>[])
            _body('You · $message'),
          TextField(
            key: const ValueKey('concept_message'),
            controller: _message,
            style: ZyraText.body(),
            maxLength: 280,
            enabled: _model.conversationOpen(id),
            decoration: const InputDecoration(labelText: 'Sample message'),
          ),
          _button(
            'concept_send_message',
            'Add sample message',
            _model.conversationOpen(id)
                ? () => _act(() {
                    if (!_model.conversationOpen(id)) return;
                    final text = _message.text.trim();
                    if (text.isEmpty) return;
                    (_messages[id] ??= []).add(text);
                    _model.markJourneyActivity(id);
                    _message.clear();
                  })
                : null,
            primary: true,
          ),
        ] else ...[
          _button(
            'draft_stage_ready_$id',
            _model.hasChosenStageContinue(id)
                ? 'You chose to continue'
                : 'I’m ready for the next step',
            _model.canChooseStageContinue(id)
                ? () => _act(() => _result(_model.chooseStageContinue(id)))
                : null,
          ),
          _button(
            'draft_stage_peer_ready_$id',
            _model.peerHasChosenStageContinue(id)
                ? '${p.firstName} is ready · demo'
                : 'Demo: ${p.firstName} is also ready',
            _model.canPeerChooseStageContinue(id)
                ? () =>
                      _act(() => _result(_model.simulatePeerStageContinue(id)))
                : null,
          ),
          _button(
            'draft_stage_next_$id',
            'Continue together',
            _model.canAdvanceStage(id)
                ? () => _act(
                    () => _result(
                      stage.value == 'compatibility_reveal'
                          ? _model.beginBioStep(id)
                          : _model.advanceStage(id),
                    ),
                  )
                : null,
            primary: true,
          ),
          _body(
            'The demo still requires both choices and the current threshold. '
            'Phase review is simulated, not a server approval.',
            small: true,
          ),
        ],
      ],
    );
  }

  bool _canViewTimeline(String? id) =>
      _allowed &&
      !_guardianRole &&
      id != null &&
      _profileIds.contains(id) &&
      !_model.isBlocked(id) &&
      const {
        DraftJourneyState.preparing,
        DraftJourneyState.active,
        DraftJourneyState.ended,
      }.contains(_model.stateFor(id));

  ZyraDraftTimelinePreview _makeTimelinePreview(DraftProfile person) =>
      ZyraDraftTimelinePreview(
        person.id,
        firstName: person.firstName,
        journeyState: _model.stateFor(person.id),
        stageValue: _model.stageFor(person.id)?.value,
        compatibilityRevealed: _model.compatibilityRevealed(person.id),
        endedAttempts: _model.endedAttemptsFor(person.id),
      );

  Widget _timeline(String id) {
    if (!_canViewTimeline(id)) return _unavailable();
    final person = draftProfiles.firstWhere((p) => p.id == id);
    final standalone = _page == 'timeline';
    final interactive =
        standalone && _model.stateFor(id) != DraftJourneyState.ended;
    final preview = standalone
        ? (_timelinePreview ??= _makeTimelinePreview(person))
        : _makeTimelinePreview(person);
    if (preview.subjectId != id) return _unavailable();
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    final controlsEpoch = _devControlsEpoch;
    final navigatorStamp = _devRouteStamp;
    bool current() =>
        fresh() &&
        !_devControlsVisible &&
        controlsEpoch == _devControlsEpoch &&
        navigatorStamp == _devRouteStamp &&
        ModalRoute.of(context)?.isCurrent == true &&
        _uiRevision == revision &&
        _page == 'timeline' &&
        _personId == id &&
        identical(_timelinePreview, preview) &&
        _canViewTimeline(id);
    VoidCallback action(bool Function() change) => _bound(() {
      if (current()) {
        _act(() {
          change();
        });
      }
    });
    return ZyraDraftTimelinePresentation(
      key: ValueKey(('draft_timeline', id, preview)),
      subjectId: id,
      firstName: person.firstName,
      view: preview.view,
      ownedViewport: standalone,
      showContext: standalone,
      onRetry: standalone ? action(preview.retry) : null,
      onConfirm: interactive ? action(preview.confirm) : null,
      onNotYet: interactive ? action(preview.notYet) : null,
      onPropose: interactive
          ? (type) {
              if (current()) {
                _act(() {
                  preview.propose(type);
                });
              }
            }
          : null,
      // This door retains the existing Journey's own mutual-reveal check.
      // Selecting a test milestone is never a disclosure/credit grant.
      onViewCompatibility:
          standalone && _model.stateFor(id) != DraftJourneyState.ended
          ? _bound(() {
              if (current()) _open('journey_compatibility', person: id);
            })
          : null,
      readableCompatibilityAttemptIds: {
        for (final attempt in _model.endedAttemptsFor(id))
          if (_canViewEndedCompatibility(id, attemptId: attempt.id)) attempt.id,
      },
      onViewAttemptCompatibility:
          standalone && _model.stateFor(id) == DraftJourneyState.ended
          ? (attemptId) {
              if (!current() ||
                  !_canViewEndedCompatibility(id, attemptId: attemptId)) {
                return;
              }
              _open('ended_compatibility', person: id);
              // Fresh attempt identity is ephemeral route context, not proof.
              if (_page == 'ended_compatibility') {
                _act(() => _endedCompatibilityAttemptId = attemptId);
              }
            }
          : null,
    );
  }

  Set<String> get _linkedSampleGuardianIds =>
      _conceptGuardianPeople.map((person) => person.id).toSet();

  String? get _sampleMainGuardianId =>
      _conceptGuardianPeople.where((person) => person.isMain).firstOrNull?.id;

  Set<String> get _paidSampleAdditionalGuardianIds => {
    for (final person in _conceptGuardianPeople)
      if (!person.isMain && _model.canUseSampleGuardianChat(person.id))
        person.id,
  };

  void _beginWithGuardianAgreement(DraftProfile person) {
    if (!_allowed ||
        _guardianRole ||
        _devControlsVisible ||
        _personId != person.id ||
        _model.isBlocked(person.id) ||
        _model.stateFor(person.id) != DraftJourneyState.preparing) {
      return;
    }
    final linked = Set<String>.unmodifiable(_linkedSampleGuardianIds);
    final main = _sampleMainGuardianId;
    final paid = Set<String>.unmodifiable(_paidSampleAdditionalGuardianIds);
    if (paid.isEmpty) {
      _act(
        () => _result(
          _model.beginPreparedJourney(
            person.id,
            linkedGuardianIds: linked,
            mainGuardianId: main,
          ),
        ),
      );
      return;
    }
    _move(() {
      _paidGuardianAgreement = (
        personId: person.id,
        linkedIds: linked,
        mainId: main,
        paidIds: paid,
      );
      _pages.add('guardian_access_agreement');
    });
  }

  Widget _guardianAccessAgreement() {
    final agreement = _paidGuardianAgreement;
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    final controlsEpoch = _devControlsEpoch;
    final routeStamp = _devRouteStamp;
    bool sameSet(Set<String> a, Set<String> b) =>
        a.length == b.length && a.containsAll(b);
    bool current() =>
        agreement != null &&
        fresh() &&
        !_guardianRole &&
        !_devControlsVisible &&
        _page == 'guardian_access_agreement' &&
        _personId == agreement.personId &&
        revision == _uiRevision &&
        controlsEpoch == _devControlsEpoch &&
        routeStamp == _devRouteStamp &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        identical(agreement, _paidGuardianAgreement) &&
        !_model.isBlocked(agreement.personId) &&
        _model.stateFor(agreement.personId) == DraftJourneyState.preparing &&
        _model.isReady(agreement.personId) &&
        _model.peerIsReady(agreement.personId) &&
        agreement.mainId == _sampleMainGuardianId &&
        sameSet(agreement.linkedIds, _linkedSampleGuardianIds) &&
        sameSet(agreement.paidIds, _paidSampleAdditionalGuardianIds);
    if (!current()) return _unavailable();
    final agreed = agreement!;
    return _pageScroll([
      _heading('Guardian access', ''),
      _card([
        _title('For this new Journey', size: 25),
        _body(
          'These paid Additional Guardians will be able to view this Journey '
          'and join its conversation when Chat becomes available:',
        ),
        for (final guardian in _conceptGuardianPeople)
          if (agreed.paidIds.contains(guardian.id))
            _body(guardian.firstName, gold: true),
        _body(
          'View and Chat will stay on while they are linked and eligible. '
          'Existing Journeys and old conversations are not changed.',
        ),
        _body('Begin only if you agree to this access for the new Journey.'),
        _button(
          'draft_agree_guardian_access_${agreed.personId}',
          'Agree and begin',
          () {
            if (!current()) return;
            _act(() {
              final begun = _model.beginPreparedJourney(
                agreed.personId,
                linkedGuardianIds: agreed.linkedIds,
                mainGuardianId: agreed.mainId,
                agreedPaidAdditionalGuardianIds: agreed.paidIds,
              );
              if (!begun) {
                _notice = 'Nothing changed. Review this Journey again.';
                return;
              }
              _paidGuardianAgreement = null;
              _pages.removeLast();
              _notice = null;
            });
          },
          primary: true,
        ),
      ]),
    ], key: const ValueKey('draft_guardian_access_agreement'));
  }

  bool get _activityRoot => !_guardianRole && _tab == 2 && _page == null;

  void _clearActivityRehearsal() {
    _activityExample = null;
    _reviewedActivityExamples.clear();
    _activityChecklistExpanded = false;
    _activityPreviewEpoch++;
  }

  VoidCallback _activityAction(VoidCallback action, {bool controls = false}) {
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    final controlsEpoch = _devControlsEpoch;
    final routeStamp = _devRouteStamp;
    final epoch = _activityPreviewEpoch;
    return () {
      if (!fresh() ||
          !_activityRoot ||
          controls != _devControlsVisible ||
          revision != _uiRevision ||
          controlsEpoch != _devControlsEpoch ||
          routeStamp != _devRouteStamp ||
          epoch != _activityPreviewEpoch ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      action();
    };
  }

  void _selectActivityExample(ZyraMyZyraActivityExample? example) => _move(() {
    _activityExample = example;
    _myZyraFocusIndex = 0;
    if (example != null) _reviewedActivityExamples.add(example);
    _activityPreviewEpoch++;
  });

  void _stepActivityExample(int delta) {
    final values = ZyraMyZyraActivityExample.values;
    final next = ((_activityExample?.index ?? 0) + delta) % values.length;
    _selectActivityExample(values[next]);
  }

  bool _activityItemVisible(ZyraMyZyraActivityItem item) =>
      item.personId == null ||
      (_profileIds.contains(item.personId) &&
          !_model.isBlocked(item.personId!));

  String _receivedFocusToken(String id) =>
      'received:$id:${_model.receivedRequestRevision(id)}';

  List<ZyraFocusEvent> _focusEvents({bool includeConsumed = false}) {
    final events = <ZyraFocusEvent>[];
    final example = _activityExample;
    final fixtureRequests =
        example == ZyraMyZyraActivityExample.requestReceived ||
        example == ZyraMyZyraActivityExample.severalRequests;
    final incoming = _visibleRequests(DraftJourneyState.received)
        .where(
          (p) =>
              _model.hasUnseenReceivedRequest(p.id) &&
              (includeConsumed ||
                  !_myZyraConsumedFocusTokens.contains(
                    _receivedFocusToken(p.id),
                  )),
        )
        .toList();
    final requested = _model.snapshot().pendingRequestedAt;
    incoming.sort((a, b) {
      final time = (requested[b.id] ?? DateTime.utc(1970)).compareTo(
        requested[a.id] ?? DateTime.utc(1970),
      );
      return time != 0
          ? time
          : (_model.receivedRequestRevision(b.id) ?? 0).compareTo(
              _model.receivedRequestRevision(a.id) ?? 0,
            );
    });
    if (example != ZyraMyZyraActivityExample.quiet &&
        !fixtureRequests &&
        incoming.isNotEmpty) {
      final names = incoming.map((p) => p.firstName).toList();
      events.add(
        ZyraFocusEvent(
          tokens: incoming.map((p) => _receivedFocusToken(p.id)).toList(),
          target: 'requests',
          title: incoming.length == 1
              ? 'Journey request from ${names.first}'
              : '${incoming.length} Journey requests',
          detail:
              '${zyraFocusRequestNames(names)} would like to begin a Journey with you.',
          action: incoming.length == 1 ? 'View request' : 'View requests',
          icon: Icons.mail_outline,
          occurredAt: requested[incoming.first.id] ?? DateTime.utc(1970),
          order: _model.receivedRequestRevision(incoming.first.id) ?? 0,
        ),
      );
    }
    if (example == null) {
      // The current Circle fixture explicitly marks this fixed response unread
      // for the Seeker (the Guardian view does not). No message-read write here.
      final circleSender = _conceptGuardianPeople.firstOrNull;
      if (circleSender != null) {
        events.add(
          ZyraFocusEvent(
            tokens: ['circle:response:${circleSender.id}'],
            target: 'guardian_circle',
            title: 'New message in Guardian Circle',
            detail:
                '${circleSender.firstName} has added to your Circle conversation.',
            action: 'Open Circle',
            icon: Icons.forum_outlined,
            occurredAt: DateTime.utc(2026, 10, 12, 0, 12),
          ),
        );
      }
      for (final p in draftProfiles.where(
        (p) =>
            _currentJourneys.any((j) => j.id == p.id) ||
            (_model.isAcceptedWaiting(p.id) && !_model.waitingIsIncoming(p.id)),
      )) {
        final waiting = _model.isAcceptedWaiting(p.id);
        final at = _model.outgoingRequestAcceptedAt(p.id);
        if (at != null && !_model.isBlocked(p.id)) {
          events.add(
            ZyraFocusEvent(
              tokens: [
                'accepted:${p.id}:${_model.outgoingRequestAcceptedRevision(p.id)}:${at.microsecondsSinceEpoch}',
              ],
              target: waiting ? 'request_capacity' : 'journey',
              personId: p.id,
              occurredAt: at,
              order: _model.outgoingRequestAcceptedRevision(p.id) ?? 0,
              title: waiting
                  ? '${p.firstName} accepted your request'
                  : '${p.firstName} accepted your Journey request',
              detail: waiting
                  ? 'Your Journey places are full. Choose a Journey to end, or let the request go.'
                  : 'Review the next step before beginning together.',
              action: waiting ? 'Choose a place' : 'View Journey',
              icon: Icons.check,
            ),
          );
        }
      }
      for (final person in _visibleRequests(DraftJourneyState.ended)) {
        final attempt = _model.currentEndedAttemptFor(person.id);
        final at = attempt?.endedAt;
        // An undated history example does not manufacture a new ending event.
        if (attempt == null || at == null) continue;
        events.add(
          ZyraFocusEvent(
            tokens: ['ended:${attempt.id}'],
            target: 'ended',
            personId: person.id,
            occurredAt: at,
            title: 'Your Journey with ${person.firstName} has ended',
            detail: 'It stays in your read-only Ended Journeys.',
            action: 'View Ended Journeys',
            icon: Icons.history,
          ),
        );
      }
    } else if (example != ZyraMyZyraActivityExample.quiet) {
      final samples = example.items.where(_activityItemVisible).toList();
      if (fixtureRequests && samples.isNotEmpty) {
        final names = samples
            .map(
              (x) =>
                  draftProfiles.firstWhere((p) => p.id == x.personId).firstName,
            )
            .toList();
        events.add(
          ZyraFocusEvent(
            tokens: samples
                .map((x) => 'fixture:$_activityPreviewEpoch:${x.id}')
                .toList(),
            target: 'requests',
            occurredAt: DateTime.utc(1970),
            title: names.length == 1
                ? 'Journey request from ${names.first}'
                : '${names.length} Journey requests',
            detail:
                '${zyraFocusRequestNames(names)} would like to begin a Journey with you.',
            action: names.length == 1 ? 'View request' : 'View requests',
            icon: Icons.mail_outline,
          ),
        );
      } else {
        for (final item in samples) {
          final id = item.personId;
          final state = id == null ? null : _model.stateFor(id);
          final target = switch (example) {
            ZyraMyZyraActivityExample.requestAccepted ||
            ZyraMyZyraActivityExample.journeyReady ||
            ZyraMyZyraActivityExample.familyReviewOpened => 'journey',
            ZyraMyZyraActivityExample.milestoneToConfirm => 'timeline',
            ZyraMyZyraActivityExample.requestDeclined => 'requests_past',
            ZyraMyZyraActivityExample.introductionReceived => 'introductions',
            ZyraMyZyraActivityExample.journeyEnded => 'ended',
            ZyraMyZyraActivityExample.guardianUpdate ||
            ZyraMyZyraActivityExample.guardianInvitationExpiring => 'guardian',
            ZyraMyZyraActivityExample.circleMessage => 'guardian_circle',
            _ => '',
          };
          // A selected fictional event cannot invent its target's current access.
          if (target == 'journey' &&
              !(state == DraftJourneyState.active ||
                  state == DraftJourneyState.preparing)) {
            continue;
          }
          if (target == 'timeline' && !_canViewTimeline(id)) continue;
          if ((target == 'guardian_circle' || target == 'guardian') &&
              _conceptGuardianPeople.isEmpty) {
            continue;
          }
          events.add(
            ZyraFocusEvent(
              tokens: ['fixture:$_activityPreviewEpoch:${item.id}'],
              target: target,
              personId: id,
              occurredAt: DateTime.utc(1970),
              title: item.title,
              detail: target == 'ended'
                  ? 'It stays in your read-only Ended Journeys.'
                  : item.detail,
              action: target == 'ended'
                  ? 'View Ended Journeys'
                  : item.actionLabel,
              icon: switch (target) {
                'requests_past' => Icons.close,
                'introductions' => Icons.groups_outlined,
                'journey' => switch (example) {
                  ZyraMyZyraActivityExample.requestAccepted => Icons.check,
                  ZyraMyZyraActivityExample.familyReviewOpened =>
                    Icons.verified_user_outlined,
                  _ => Icons.people_outline,
                },
                'timeline' => Icons.check,
                'ended' => Icons.history,
                'guardian' => Icons.verified_user_outlined,
                _ => Icons.forum_outlined,
              },
            ),
          );
        }
      }
    }
    final visible = events
        .where(
          (e) =>
              includeConsumed ||
              e.tokens.any(
                (token) => !_myZyraConsumedFocusTokens.contains(token),
              ),
        )
        .toList();
    visible.sort((a, b) {
      final time = b.occurredAt.compareTo(a.occurredAt);
      if (time != 0) return time;
      final order = b.order.compareTo(a.order);
      return order != 0 ? order : a.tokens.first.compareTo(b.tokens.first);
    });
    return visible;
  }

  void _consumeFocusTarget(String target, {String? personId}) {
    if (_guardianRole) return;
    for (final event in _focusEvents(includeConsumed: true)) {
      if (event.target == target &&
          (event.personId == null ||
              personId == null ||
              event.personId == personId)) {
        _myZyraConsumedFocusTokens.addAll(event.tokens);
      }
    }
  }

  void _openFocusEvent(ZyraFocusEvent event) {
    if (!_activityRoot || _devControlsVisible || !_allowed) return;
    if (!_focusEvents().any(
      (current) => current.tokens.join('|') == event.tokens.join('|'),
    )) {
      return;
    }
    final id = event.personId;
    if (id != null && (!_profileIds.contains(id) || _model.isBlocked(id))) {
      return;
    }
    switch (event.target) {
      case 'requests':
        _activity('requests');
      case 'requests_past':
        _activity('requests', requestsTab: 2);
      case 'introductions':
        _activity('introductions');
      case 'ended':
        _activity('ended');
      case 'request_capacity':
        if (id != null) _openAcceptedCapacity(id);
      case 'journey':
        if (id != null && _currentJourneys.any((p) => p.id == id)) _journey(id);
      case 'guardian':
        _tabTo(3);
      case 'guardian_circle':
        if (_conceptGuardianPeople.isNotEmpty) _open('guardian_circle');
      case 'timeline':
        if (id != null && _canViewTimeline(id)) _open('timeline', person: id);
    }
  }

  Widget _dashboard() {
    final events = _focusEvents();
    final incoming = _visibleRequests(
      DraftJourneyState.received,
    ).where((p) => _model.hasUnseenReceivedRequest(p.id)).length;
    final sent = _visibleRequests(DraftJourneyState.sent).length;
    final ended = _visibleRequests(DraftJourneyState.ended).length;
    final introductions = events
        .where((event) => event.target == 'introductions')
        .length;
    final fresh = _accountFreshGuard();
    final revision = _uiRevision,
        controls = _devControlsEpoch,
        routes = _devRouteStamp,
        epoch = _activityPreviewEpoch;
    VoidCallback action(VoidCallback callback) => () {
      if (!fresh() ||
          !_activityRoot ||
          _devControlsVisible ||
          revision != _uiRevision ||
          controls != _devControlsEpoch ||
          routes != _devRouteStamp ||
          epoch != _activityPreviewEpoch ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      callback();
    };
    final setup =
        _subscriptionWallet.forRole(ZyraWalletRole.seeker).readiness ==
        ZyraWalletReadiness.ready;
    return ZyraFocusPermissionStatus(
      canAct: () => _allowed && _activityRoot && !_devControlsVisible,
      builder: (notificationsAllowed) => FutureBuilder(
        future: _accountSession.compatibility.load('draft-self'),
        builder: (context, snapshot) {
          final preferences = ZyraCompatibilityDraft.fromSnapshot(
            gender: 'male',
            snapshot: snapshot.data,
          );
          final set = preferences.preferenceAnswerCount,
              total = preferences.preferenceOptionCount;
          return ZyraFocusDashboard(
            initialIndex: _myZyraFocusIndex,
            onIndexChanged: (index) => action(() {
              _myZyraFocusIndex = index;
              _publishCheckpoint();
            })(),
            previewControls: _activityExample == null
                ? null
                : ZyraMyZyraActivityPreviewBar(
                    example: _activityExample!,
                    onPrevious: _activityAction(() => _stepActivityExample(-1)),
                    onNext: _activityAction(() => _stepActivityExample(1)),
                    onChecklist: _activityAction(() {
                      _activityChecklistExpanded = true;
                      _openDevControls();
                    }),
                    onCurrent: _activityAction(
                      () => _selectActivityExample(null),
                    ),
                  ),
            items: [
              for (final event in events)
                ZyraFocusItem(
                  id: event.tokens.join('|'),
                  icon: event.icon,
                  title: event.title,
                  detail: event.detail,
                  actionLabel: event.action,
                  actionKey:
                      event.target == 'requests' && event.tokens.length == 1
                      ? 'concept-request-draft-amira'
                      : 'focus-open-${event.target}',
                  onAction: action(() => _openFocusEvent(event)),
                ),
            ],
            chips: [
              if (!setup)
                ZyraFocusChip(
                  id: 'focus-setup',
                  label: 'Finish setup',
                  icon: Icons.person_outline,
                  onTap: action(() => _walletSetup(ZyraWalletRole.seeker)),
                ),
              if (_conceptGuardianPeople.isEmpty)
                ZyraFocusChip(
                  id: 'focus-guardian',
                  label: 'No Guardian yet',
                  icon: Icons.verified_user_outlined,
                  onTap: action(() => _tabTo(3)),
                ),
              if (setup)
                ZyraFocusChip(
                  id: 'focus-places',
                  label:
                      '${_model.occupiedCount} of ${_model.capacity} ${_model.capacity == 1 ? 'place' : 'places'} in use',
                  icon: Icons.people_outline,
                  onTap: action(() => _tabTo(1)),
                ),
              if (notificationsAllowed == false)
                ZyraFocusChip(
                  id: 'focus-notifications-off',
                  label: 'Notifications off',
                  icon: Icons.notifications_none,
                  onTap: action(() {
                    _open('settings');
                    _open('phone_access');
                  }),
                ),
              if (set < total)
                ZyraFocusChip(
                  id: 'focus-preferences',
                  label: 'Preferences $set/$total',
                  icon: Icons.tune,
                  onTap: action(() => _open('filter_preferences')),
                ),
            ],
            tiles: [
              ZyraFocusTile(
                id: 'concept-my-requests',
                label: 'Journey\nrequests',
                status: incoming > 0
                    ? '$incoming new'
                    : sent > 0
                    ? '$sent sent'
                    : 'None',
                isNew: incoming > 0,
                icon: Icons.inbox_outlined,
                onTap: action(() => _activity('requests')),
              ),
              ZyraFocusTile(
                id: 'concept-my-introductions',
                label: 'Introductions',
                status: introductions > 0 ? '$introductions new' : 'None yet',
                isNew: introductions > 0,
                icon: Icons.groups_outlined,
                onTap: action(() => _activity('introductions')),
              ),
              ZyraFocusTile(
                id: 'concept-my-ended',
                label: 'Ended\nJourneys',
                status: ended > 0 ? '$ended ended' : 'None',
                icon: Icons.history,
                onTap: action(() => _activity('ended')),
              ),
              ZyraFocusTile(
                id: 'focus-notifications',
                label: 'Notifications',
                status: events.isNotEmpty
                    ? '${events.length} new'
                    : 'Nothing new',
                isNew: events.isNotEmpty,
                icon: Icons.notifications_none,
                onTap: action(() => _open('notifications')),
              ),
            ],
          );
        },
      ),
    );
  }

  // Relationship and permission changes below are disposable local fixtures.
  // They never establish an account role, link, consent or Journey authority.
  String _conceptMainGuardianId = 'draft-guardian-hassan';
  String? _pendingMainGuardianNoticeId;

  void _closeMainGuardianNotice() {
    if (!_allowed ||
        _guardianRole ||
        _devControlsVisible ||
        _tab != 3 ||
        _page != 'guardian_main_notice' ||
        _pendingMainGuardianNoticeId == null) {
      return;
    }
    _move(() {
      _pendingMainGuardianNoticeId = null;
      _pages.removeLast();
    });
  }

  Widget _guardianInfo() {
    if (_guardianRole || _tab != 4) return _unavailable();
    final main = _conceptGuardianPeople
        .where((person) => person.isMain)
        .firstOrNull;
    return ZyraGuardianInfoPresentation(
      mainGuardian: main == null
          ? 'You have no Main Guardian yet'
          : '${main.firstName} · ${main.relationshipLabel}',
      canAct: _accountFreshGuard(),
      onMove: () {},
      onManage: _bound(() => _tabTo(3)),
    );
  }

  Widget _mainGuardianNotice() {
    final id = _pendingMainGuardianNoticeId;
    final guardian = draftGuardians
        .where((person) => person.id == id)
        .firstOrNull;
    if (_guardianRole ||
        guardian == null ||
        !_model.ownMainGuardianPresent ||
        id != _conceptMainGuardianId ||
        _conceptRemovedGuardians.contains(id)) {
      return _unavailable();
    }
    final fresh = _accountFreshGuard();
    final name = guardian.firstName;
    return SafeArea(
      key: const ValueKey('concept_main_guardian_notice'),
      child: LayoutBuilder(
        builder: (context, constraints) => ZyraShadowScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 40).clamp(0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: zyraGuardianManagerMonogram(name: name, main: true),
                ),
                const SizedBox(height: 18),
                Text(
                  '$name will be your Main Guardian',
                  textAlign: TextAlign.center,
                  style: ZyraText.heading(size: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  '$name is part of every Journey you begin. $name will also see '
                  'your Journey requests — the ones you send and the ones you '
                  'receive — and who each is with. $name sees that person\'s '
                  'profile as anyone browsing would. Nothing more.',
                  textAlign: TextAlign.center,
                  style: ZyraText.body(size: 14).copyWith(height: 1.4),
                ),
                const SizedBox(height: 24),
                _button('concept_main_guardian_continue', 'Continue', () {
                  if (fresh() && _pendingMainGuardianNoticeId == id) {
                    _closeMainGuardianNotice();
                  }
                }, primary: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final _conceptRemovedGuardians = <String>{};
  final _conceptGuardianHistory = <String, bool>{};
  final _conceptNetworkSent = <String>{};

  bool get _conceptHassanLinked =>
      !_conceptRemovedGuardians.contains('draft-guardian-hassan');

  List<WaliLinkedPerson> get _conceptGuardianPeople => [
    for (final guardian in draftGuardians)
      if (!_conceptRemovedGuardians.contains(guardian.id))
        WaliLinkedPerson(
          id: guardian.id,
          firstName: guardian.firstName,
          relationship: guardian.relationshipCode,
          linkedAt: guardian.linkedAt,
          isMain:
              _model.ownMainGuardianPresent &&
              guardian.id == _conceptMainGuardianId,
        ),
  ];

  SeekerProfile get _conceptLinkedSeekerProfile =>
      _accountSession.ownProfile(false);

  WaliLinkedPerson get _conceptLinkedSeeker => WaliLinkedPerson(
    id: 'draft-self',
    firstName: 'Adam',
    relationship: draftGuardians.first.relationshipCode,
    linkedAt: draftGuardians.first.linkedAt,
    isMain:
        _model.ownMainGuardianPresent &&
        _conceptMainGuardianId == 'draft-guardian-hassan' &&
        !_conceptRemovedGuardians.contains('draft-guardian-hassan'),
  );

  WaliJourneyView? get _conceptGuardianJourney {
    if (!_conceptHassanLinked) return null;
    final focus =
        _guardianFocus ??
        (_guardianRole && _guardianTabs.main
            ? draftProfiles.firstWhere((p) => p.id == 'draft-sara')
            : null);
    if (focus == null) return null;
    final main = _conceptLinkedSeeker.isMain;
    final access = _conceptAccessFor('draft-guardian-hassan', focus.id);
    if (!main && !access.view) return null;
    return WaliJourneyView(
      attemptId: 'draft-attempt-${focus.id}',
      matchId: 'draft-match-${focus.id}',
      linkedSeekerId: 'draft-self',
      linkedSeekerName: 'Adam',
      partner: SeekerProfile(
        id: focus.id,
        firstName: focus.firstName,
        age: focus.age,
        city: '—',
        gender: 'female',
        photos: const [],
      ),
      counterpartGuardianName: _model.peerMainGuardianPresentFor(focus.id)
          ? 'Main Guardian'
          : null,
      counterpartGuardianSurname: null,
      status: 'active',
      journeyStage: _model.stageFor(focus.id)?.value,
      pause: ZyraJourneyPauseState.active,
      isMock: true,
    );
  }

  ({bool view, bool chat}) _conceptAccessFor(
    String guardianId,
    String focusId,
  ) => _model.sampleGuardianAccessFor(
    guardianId,
    focusId,
    isMain:
        _model.ownMainGuardianPresent && _conceptMainGuardianId == guardianId,
  );

  String _sharedPastJourneyLabel(int index) {
    const names = [
      'Elif',
      'Noor',
      'Hafsa',
      'Zainab',
      'Huda',
      'Safiya',
      'Mariam',
      'Amina',
      'Khadija',
      'Sumayya',
      'Layla',
      'Yasmin',
    ];
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
    final end = DateTime.utc(2026, 10, 10).subtract(Duration(days: index * 15));
    final start = end.subtract(const Duration(days: 21));
    final startLabel = start.month == end.month && start.year == end.year
        ? '${start.day}'
        : start.year == end.year
        ? '${start.day} ${months[start.month - 1]}'
        : '${start.day} ${months[start.month - 1]} ${start.year}';
    return 'Adam & ${names[index]} · $startLabel–${end.day} ${months[end.month - 1]} ${end.year}';
  }

  // One caller-owned fixture feeds both the icon and the admitted reader.
  // No notification total, Focus dismissal or unrelated message list is used.
  ZyraGuardianCirclePreviewData? _currentCircleData() {
    if (!_allowed || (_guardianRole && !_conceptHassanLinked)) return null;
    final guardian = _guardianRole;
    final circleYusuf = guardian && _guardianTabs.seeker == 1;
    final people = circleYusuf
        ? [
            WaliLinkedPerson(
              id: 'draft-guardian-hassan',
              firstName: 'Hassan',
              relationship: 'father',
              isMain: false,
            ),
          ]
        : _seekerMembership == 'Seeker Basic'
        ? _conceptGuardianPeople.take(1).toList()
        : _conceptGuardianPeople;
    if (people.isEmpty) return null;
    final senderId = guardian ? 'draft-guardian-hassan' : 'draft-self';
    final contexts = [
      for (final person
          in guardian ? _permittedGuardianJourneys : _guardianJourneys)
        if ((!guardian || _guardianTabs.main) &&
            _model.stateFor(person.id) == DraftJourneyState.active)
          ZyraFamilyMessageContext(
            referenceId: person.id,
            firstName: person.firstName,
            kind: ZyraFamilyMessageContextKind.active,
          ),
    ];
    // LOCK20 / answered question6: local fixture writing is per member.
    // This neither admits a live member nor changes a service/server guard.
    final funded = guardian
        ? _guardianMembership == 'Guardian One'
        : _seekerMembership == 'Seeker One' ||
              _seekerMembership == 'Seeker Basic';
    final circleSeekerId = circleYusuf ? 'draft-linked-yusuf' : 'draft-self';
    final circleSeekerName = circleYusuf ? 'Yusuf' : 'Adam';
    return ZyraGuardianCirclePreviewData(
      seekerId: circleSeekerId,
      senderId: senderId,
      canSend: people.isNotEmpty && funded,
      participants: [
        ZyraFamilyCircleParticipant(
          userId: circleSeekerId,
          firstName: circleSeekerName,
          memberRole: 'seeker',
          isMainGuardian: false,
          isCurrentUser: !guardian,
        ),
        for (final person in people)
          ZyraFamilyCircleParticipant(
            userId: person.id,
            firstName: person.firstName,
            memberRole: 'guardian',
            isMainGuardian: person.isMain,
            isCurrentUser: guardian && person.id == senderId,
          ),
      ],
      messages: [
        ZyraFamilyMessage(
          id: 'draft-circle-welcome',
          senderId: circleSeekerId,
          senderFirstName: circleSeekerName,
          senderRoleLabel: 'Seeker',
          body: 'Assalaamu alaikum. Let’s discuss the journey together.',
          createdAt: DateTime.utc(2026, 10, 12, 0, 10),
          readBy: [
            for (final person in people)
              ZyraFamilyMessageReader(
                userId: person.id,
                firstName: person.firstName,
                roleLabel: person.isMain
                    ? 'Main Guardian'
                    : 'Additional Guardian',
                readAt: DateTime.utc(2026, 10, 12, 0, 11),
              ),
          ],
        ),
        if (people.isNotEmpty)
          ZyraFamilyMessage(
            id: 'draft-circle-response',
            senderId: people.first.id,
            senderFirstName: people.first.firstName,
            senderRelationship: people.first.relationship,
            senderRoleLabel: people.first.isMain
                ? 'Main Guardian'
                : 'Additional Guardian',
            body: 'Wa alaikum assalaam. We’re here to support you.',
            createdAt: DateTime.utc(2026, 10, 12, 0, 12),
            unreadForMe:
                !guardian &&
                !_circleReadMessageKeys.contains(
                  '$circleSeekerId:$senderId:draft-circle-response:${people.first.id}',
                ),
            readBy: [
              ZyraFamilyMessageReader(
                userId: circleSeekerId,
                firstName: circleSeekerName,
                roleLabel: 'Seeker',
                readAt: DateTime.utc(2026, 10, 12, 0, 14),
              ),
              for (final person in people.skip(1))
                ZyraFamilyMessageReader(
                  userId: person.id,
                  firstName: person.firstName,
                  roleLabel: person.isMain
                      ? 'Main Guardian'
                      : 'Additional Guardian',
                  readAt: DateTime.utc(2026, 10, 12, 0, 14),
                ),
            ],
          ),
      ],
      contexts: contexts,
    );
  }

  String _circleMessageKey(
    ZyraGuardianCirclePreviewData data,
    ZyraFamilyMessage message,
  ) => '${data.seekerId}:${data.senderId}:${message.id}:${message.senderId}';

  int get _currentCircleUnreadCount {
    final data = _currentCircleData();
    if (data == null ||
        !data.validFor(data.seekerId, viewerIsSeeker: !_guardianRole)) {
      return 0;
    }
    return data.messages.where((message) => message.unreadForMe).length;
  }

  void _markCurrentCircleRead() {
    final data = _currentCircleData();
    if (data == null ||
        !data.validFor(data.seekerId, viewerIsSeeker: !_guardianRole)) {
      return;
    }
    _circleReadMessageKeys.addAll(
      data.messages
          .where((message) => message.unreadForMe)
          .map((message) => _circleMessageKey(data, message)),
    );
  }

  Widget _guardianCircle() {
    if (_guardianRole && !_conceptHassanLinked) return _unavailable();
    if (_circleEntryView != null &&
        _circleEntryRevision == _circleScopeRevision) {
      return _circleEntryView!;
    }
    final revision = _circleScopeRevision;
    final guardian = _guardianRole;
    final circleYusuf = guardian && _guardianTabs.seeker == 1;
    final tab = _tab;
    final senderId = guardian ? 'draft-guardian-hassan' : 'draft-self';
    bool canReadPast() =>
        !guardian ||
        (_conceptHassanLinked && _conceptGuardianHistory[senderId] == true);
    final pastShared = (!guardian || _guardianTabs.main) && canReadPast();
    String linkStamp() => [
      _seekerMembership,
      _guardianMembership,
      _guardianTabs.seeker,
      _conceptMainGuardianId,
      _model.ownMainGuardianPresent,
      for (final person in _conceptGuardianPeople) ...[
        person.id,
        person.isMain,
        _model.sampleGuardianMembershipFor(person.id),
        _conceptGuardianHistory[person.id] ?? _shareHistory,
        for (final journey in _guardianJourneys) ...[
          journey.id,
          _model.attemptRevisionFor(journey.id),
          _model.stateFor(journey.id),
          _model.isBlocked(journey.id),
          _conceptAccessFor(person.id, journey.id).view,
          _conceptAccessFor(person.id, journey.id).chat,
        ],
      ],
    ].join('|');
    final stamp = linkStamp();
    bool current() =>
        _allowed &&
        revision == _circleScopeRevision &&
        guardian == _guardianRole &&
        tab == _tab &&
        (_page == 'guardian_circle' ||
            (_page == 'controls' && _pageOptionsSource == 'guardian_circle')) &&
        stamp == linkStamp() &&
        pastShared == ((!guardian || _guardianTabs.main) && canReadPast()) &&
        (!guardian || _conceptHassanLinked);

    final data = _currentCircleData();
    if (data == null) return _unavailable();
    final contexts = data.contexts;
    final circleSeekerName = circleYusuf ? 'Yusuf' : 'Adam';
    // Snapshot lazily after the existing bundled photo reader is ready. A
    // fast Circle entry must not freeze an empty photo list, and once exposed
    // each profile keeps its identity for this owned child-route lifetime.
    final discussionProfiles = <String, SeekerProfile>{};
    final navigator = GlobalKey<NavigatorState>();
    _circleNavigator = navigator;
    _circleEntryRevision = revision;
    final ownerGuard = current;
    bool foreground() => current() && _page == 'guardian_circle';
    final currentTopicExamples = List<ZyraCircleDiscussionTopic>.unmodifiable([
      if (!circleYusuf)
        for (final name in const ['Sara', 'Aisha', 'Maryam'])
          ZyraCircleDiscussionTopic(
            id: 'draft-circle-current-${name.toLowerCase()}',
            firstName: name,
            kind: ZyraCircleTopicKind.current,
          ),
    ]);
    final pastTopics = List<ZyraCircleDiscussionTopic>.unmodifiable([
      if (pastShared)
        for (var index = 0; index < 12; index++)
          ZyraCircleDiscussionTopic(
            id: 'draft-circle-past-$index',
            firstName: const [
              'Elif',
              'Noor',
              'Hafsa',
              'Zainab',
              'Huda',
              'Safiya',
              'Mariam',
              'Amina',
              'Khadija',
              'Sumayya',
              'Layla',
              'Yasmin',
            ][index],
            kind: ZyraCircleTopicKind.past,
            sharedSummaryLabel: guardian
                ? _sharedPastJourneyLabel(index)
                : null,
            endedOn: DateTime.utc(
              2026,
              10,
              10,
            ).subtract(Duration(days: index * 15)),
          ),
    ]);
    // Explicit dates for detached past examples, not real archive/history
    // access. Never derive a profile or message lookup from a picker label.
    final pastArchives = <String, ZyraCircleDiscussionArchive>{
      for (final topic in pastTopics)
        topic.id: ZyraCircleDiscussionArchive(
          topicId: topic.id,
          firstName: topic.firstName,
          sharedSummaryLabel: topic.sharedSummaryLabel,
          startedOn: topic.endedOn!.subtract(const Duration(days: 21)),
          endedOn: topic.endedOn!,
        ),
    };
    ZyraCircleDiscussionArchive? discussionArchiveFor(
      ZyraCircleDiscussionTopic topic,
    ) {
      if (!current() ||
          !canReadPast() ||
          !pastTopics.any((known) => identical(known, topic))) {
        return null;
      }
      return pastArchives[topic.id];
    }

    // Capture one resolver for this exact Circle lifetime. A Theme rebuild
    // may replay the route builder; a newly created closure would correctly
    // be rejected as a different caller by the retained chat's owner guard.
    SeekerProfile? discussionProfileFor(ZyraFamilyMessageContext context) {
      if (!current() ||
          _page != 'guardian_circle' ||
          !contexts.any(
            (allowed) =>
                allowed.referenceId == context.referenceId &&
                allowed.firstName == context.firstName &&
                allowed.kind == context.kind,
          ) ||
          context.kind != ZyraFamilyMessageContextKind.active ||
          _model.isBlocked(context.referenceId) ||
          _model.stateFor(context.referenceId) != DraftJourneyState.active) {
        return null;
      }
      final person = _guardianJourneys
          .where(
            (person) =>
                person.id == context.referenceId &&
                person.firstName == context.firstName,
          )
          .firstOrNull;
      if (person == null || _photos == null) return null;
      return discussionProfiles.putIfAbsent(
        person.id,
        () => _displayProfile(person),
      );
    }

    final topicsPreview = ZyraCircleTopicsPreview(
      guardianBasic: guardian && _guardianMembership == 'Guardian Basic',
      readOnlyParticipantIds: [
        for (final participant in data.participants)
          if (participant.memberRole == 'guardian' &&
              (guardian && participant.userId == senderId
                  ? _guardianMembership == 'Guardian Basic'
                  : _model.sampleGuardianMembershipFor(participant.userId) ==
                        DraftGuardianMembership.basic))
            participant.userId,
      ],
      tiles: [
        for (final context in contexts)
          for (final person in _guardianJourneys)
            if (person.id == context.referenceId)
              ZyraCircleTopicTile(
                id: context.referenceId,
                name: context.firstName,
                stage:
                    'Stage ${_model.stageFor(person.id)?.order ?? 1} of 8 · ${_model.stageFor(person.id)?.label ?? 'Salam Exchange'}',
                photo: _photos
                    ?.forIndex(draftProfiles.indexOf(person))
                    .firstOrNull,
              ),
        for (var index = 0; index < pastTopics.length; index++)
          ZyraCircleTopicTile(
            id: pastTopics[index].id,
            name: pastTopics[index].firstName,
            photo: guardian ? null : _photos?.forIndex(index).firstOrNull,
          ),
      ],
      onManageGuardians: () {
        if (current() && foreground() && !guardian) {
          _move(() {
            _pages.clear();
            _tab = 3;
          });
        }
      },
      onMembership: () {
        if (current() && foreground() && guardian) {
          _membershipDraft = _membershipDraft.copyWith(
            section: ZyraMembershipSection.guardian,
          );
          _open('membership');
        }
      },
    );

    return _circleEntryView = Navigator(
      observers: [ZyraDevControlsRouteObserver()],
      key: navigator,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => ZyraGuardianCircleScreen(
          key: ValueKey(('request-guardian-circle', revision, senderId)),
          seekerId: data.seekerId,
          seekerFirstName: circleSeekerName,
          viewerIsSeeker: !guardian,
          preview: true,
          previewData: data,
          previewTopics: topicsPreview,
          previewBubbleDesign: _circleBubbleDesign,
          previewForeground: foreground,
          previewVisibility: _circleVisibility,
          previewCurrentTopics: currentTopicExamples,
          previewPastTopics: pastTopics,
          // A topic is not permission to look up a profile. Only this bound
          // Seeker caller can return an already admitted current example.
          // Guardian/Past comparisons never gain a full-profile capability.
          previewDiscussionProfileFor: guardian ? null : discussionProfileFor,
          previewDiscussionArchiveFor: discussionArchiveFor,
          canAct: ownerGuard,
          onBack: () {
            if (current() && _page == 'guardian_circle') _back();
          },
          onOpenContext: (context) {
            if (!current() ||
                _page != 'guardian_circle' ||
                !contexts.any(
                  (allowed) =>
                      allowed.referenceId == context.referenceId &&
                      allowed.kind == context.kind,
                ) ||
                _model.isBlocked(context.referenceId) ||
                _model.stateFor(context.referenceId) !=
                    DraftJourneyState.active) {
              return;
            }
            if (guardian) {
              _move(() {
                _guardianJourneyId = context.referenceId;
                _pages.add('guardian');
              });
            } else {
              _journey(context.referenceId);
            }
          },
        ),
      ),
    );
  }

  Widget _guardians() {
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final session = _accountSession;
    final revision = _uiRevision;
    final controls = _devControlsEpoch;
    final navigatorStamp = _devRouteStamp;
    final journeys = _guardianJourneys;
    final people = [..._conceptGuardianPeople]
      ..sort((a, b) {
        if (a.isMain != b.isMain) return a.isMain ? -1 : 1;
        return (a.linkedAt ?? DateTime(2100)).compareTo(
          b.linkedAt ?? DateTime(2100),
        );
      });
    String permissionStamp() => [
      _conceptMainGuardianId,
      _model.ownMainGuardianPresent,
      _seekerMembership,
      for (final person in people) ...[
        person.id,
        _conceptRemovedGuardians.contains(person.id),
        _model.sampleGuardianMembershipFor(person.id),
        _conceptGuardianHistory[person.id] ?? _shareHistory,
        for (final p in _guardianJourneys) ...[
          p.id,
          _model.attemptRevisionFor(p.id),
          _model.stateFor(p.id),
          _conceptAccessFor(person.id, p.id),
          _model.hasRequiredPaidGuardianAccess(person.id, p.id),
        ],
      ],
    ].join('|');
    final stamp = permissionStamp();
    bool current() =>
        mounted &&
        _allowed &&
        !_devControlsVisible &&
        session.current &&
        identical(session, _accountSession) &&
        account == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        revision == _uiRevision &&
        controls == _devControlsEpoch &&
        !_guardianRole &&
        _tab == 3 &&
        _page == null &&
        permissionStamp() == stamp;
    bool currentAction() =>
        current() &&
        navigatorStamp == _devRouteStamp &&
        ModalRoute.of(context)?.isCurrent == true;
    WaliLinkedPerson? target(String id) {
      if (!currentAction()) return null;
      final visible = _seekerMembership.contains('Basic')
          ? people.take(1).toList()
          : people;
      if (_guardianPage >= visible.length ||
          _guardianPage < 0 ||
          visible[_guardianPage].id != id) {
        return null;
      }
      return visible[_guardianPage];
    }

    return ZyraOneJourneyGuardianCards(
      key: ValueKey(('guardian-cards', account, identityHashCode(session))),
      people: [
        for (final p in people)
          ZyraGuardianCardPerson(
            person: p,
            membership: _model.canUseSampleGuardianChat(p.id)
                ? 'Guardian One'
                : 'Guardian Basic',
            history: _conceptGuardianHistory[p.id] ?? _shareHistory,
          ),
      ],
      journeysFor: (id) => [
        for (final p in journeys)
          ZyraGuardianCardJourney(
            id: p.id,
            attempt: _model.attemptRevisionFor(p.id),
            name: p.firstName,
            stage:
                'Stage ${_model.stageFor(p.id)?.order ?? 1} of 8 · ${_model.stageFor(p.id)?.label ?? 'Salam Exchange'}',
            photo: _photos?.forIndex(draftProfiles.indexOf(p)).firstOrNull,
            view: _conceptAccessFor(id, p.id).view,
            chat: _conceptAccessFor(id, p.id).chat,
            canChange:
                people.where((g) => g.id == id).firstOrNull?.isMain != true &&
                !_model.hasRequiredPaidGuardianAccess(id, p.id),
          ),
      ],
      capacity: _seekerMembership.contains('Basic') ? 1 : _model.capacity,
      basic: _seekerMembership.contains('Basic'),
      initialPage: _guardianPage,
      canAct: current,
      interactionEpoch: () => (_uiRevision, _devControlsEpoch, _devRouteStamp),
      contextIdentity: (
        account,
        identityHashCode(session),
        _guardianRole,
        _seekerMembership,
        stamp,
      ),
      renderIdentity: (_uiRevision, _devControlsEpoch),
      unread: _currentCircleUnreadCount,
      onPage: (page) {
        if (currentAction()) _act(() => _guardianPage = page);
      },
      onCircle: () {
        if (currentAction()) _open('guardian_circle');
      },
      onResume: () {
        if (current() && ModalRoute.of(context)?.isCurrent == true) _act(() {});
      },
      onAdd: () {
        if (!currentAction()) return;
        if (_seekerMembership.contains('Basic')) {
          _accountDispatch(ZyraConceptAccountAction.membership);
        } else {
          _open('guardian_invite');
        }
      },
      onHistory: (id, enabled) {
        if (target(id) == null) return;
        _act(() => _conceptGuardianHistory[id] = enabled);
      },
      onPermission: (id, journeyId, {view, chat}) {
        final guardian = target(id);
        if (guardian == null ||
            guardian.isMain ||
            !journeys.any((p) => p.id == journeyId) ||
            _model.hasRequiredPaidGuardianAccess(id, journeyId)) {
          return;
        }
        final old = _conceptAccessFor(id, journeyId);
        if (chat == true &&
            (!_model.canUseSampleGuardianChat(id) || !(view ?? old.view))) {
          return;
        }
        _act(
          () => _model.setSampleGuardianJourneyAccess(
            id,
            journeyId,
            viewEnabled: view,
            chatEnabled: chat,
          ),
        );
      },
      makeMain: (id) async {
        final guardian = target(id);
        if (guardian == null || guardian.isMain) return false;
        _act(() {
          _conceptMainGuardianId = id;
          _model.setOwnMainGuardianPresent(true);
          _guardianPage = 0;
          _pendingMainGuardianNoticeId = id;
          _pages.add('guardian_main_notice');
        });
        return true;
      },
      clearMain: (id) async {
        if (target(id)?.isMain != true) return false;
        _act(() => _model.setOwnMainGuardianPresent(false));
        return true;
      },
      remove: (id) async {
        if (target(id) == null) {
          return 'This is no longer available. Nothing changed.';
        }
        _act(() {
          _model.revokeSampleGuardianAccess(id);
          _conceptRemovedGuardians.add(id);
          _conceptGuardianHistory.remove(id);
          if (id == _conceptMainGuardianId) {
            _model.setOwnMainGuardianPresent(false);
          }
          _guardianPage = 0;
        });
        return null;
      },
    );
  }

  Widget _guardianDetail() => _guardianPermittedJourney();

  Widget _guardianPermittedJourney() {
    final journey = _conceptGuardianJourney;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _mainHeading('Journey'),
        if (_permittedGuardianJourneys.length > 1) ...[
          const SizedBox(height: 14),
          _guardianJourneySelector(),
        ],
        const SizedBox(height: 20),
        if (_conceptHassanLinked)
          GuardianDashboardProfileCard(
            person: _conceptLinkedSeeker,
            profile: _conceptLinkedSeekerProfile,
            onViewProfile: _bound(() => _open('guardian_linked_profile')),
          ),
        const SizedBox(height: 20),
        if (journey == null)
          const ZyraEmptyState(
            icon: Icons.route_outlined,
            message: 'No current Journey',
          )
        else
          _card([
            _title('Adam & ${journey.partner.firstName}', size: 25),
            _body(
              _model.stageFor(journey.partner.id)?.label ?? _guardianTabs.stage,
            ),
            if (journey.isJourneyLocked)
              _body(
                'The Journey is waiting for a shared decision.',
                small: true,
              ),
            if (!_model.ownMainGuardianPresent)
              _body(
                'A Main Guardian is needed before the Journey can continue.',
              ),
          ]),
      ],
    );
  }

  Widget _guardianLinkedProfile() => !_conceptHassanLinked
      ? _conceptUnavailableGuardianProfile()
      : ZyraOneJourneyBrowsePresentation(
          profile: _conceptLinkedSeekerProfile,
          onMenu: _bound(_back),
          menuKey: const ValueKey('concept_guardian_linked_profile_back'),
          menuLabel: 'Back',
          menuIcon: Icons.arrow_back_ios_new,
          menuOnLeft: true,
          showMenu: false,
          showActions: false,
          identityBottom: 100,
        );

  Widget _guardianNetworkProfile() {
    if (!_conceptHassanLinked) return _conceptUnavailableGuardianProfile();
    final person = _person;
    if (person == null) return Center(child: _body('Profile unavailable'));
    if (_model.isBlocked(person.id)) return _userNotFoundView();
    // Same bounded display identity/photos as the current Network card.
    // No surname, exact place, private answer, history or Journey data.
    final profile = SeekerProfile(
      id: person.id,
      firstName: '${person.firstName[0]}., ${person.age}',
      age: 0,
      city: '',
      gender: 'female',
      photos: _photos?.forIndex(draftProfiles.indexOf(person)) ?? const [],
    );
    return ZyraOneJourneyBrowsePresentation(
      profile: profile,
      onMenu: _bound(_back),
      menuKey: const ValueKey('concept_guardian_network_profile_back'),
      menuLabel: 'Back',
      menuIcon: Icons.arrow_back_ios_new,
      menuOnLeft: true,
      showMenu: false,
      showActions: false,
      identityBottom: 100,
    );
  }

  void _switchRole(bool guardian) {
    if (!_allowed) return;
    _move(() {
      _clearActivityRehearsal();
      _paidGuardianAgreement = null;
      _guardianRole = guardian;
      _tab = guardian ? 2 : 0;
      _pages.clear();
    });
    widget.onRoleChanged?.call(guardian);
    _publishCheckpoint();
  }

  Widget _conceptUnavailableGuardianProfile() => const SafeArea(
    child: ZyraEmptyState(
      key: ValueKey('concept_guardian_profile_unavailable'),
      icon: Icons.people_outline_rounded,
      message: 'This Seeker is not available in your linked roster.',
    ),
  );

  Widget _guardianJourneySelector() {
    final people = _permittedGuardianJourneys;
    final selected = people.indexWhere((p) => p.id == _guardianFocus?.id);
    final callbacks = [
      for (final p in people)
        _bound(() => _move(() => _guardianJourneyId = p.id)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JOURNEY WITH',
          style: ZyraText.chapterLabel(color: ZyraColors.ink(.54)),
        ),
        const SizedBox(height: 5),
        TweenAnimationBuilder<double>(
          tween: Tween(end: selected < 0 ? 0.0 : selected.toDouble()),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : ZyraSegmentedMotion.selectionDuration,
          curve: ZyraSegmentedMotion.selectionCurve,
          builder: (context, position, _) => ZyraSegmentedToggle(
            labels: people.map((p) => p.firstName).toList(),
            position: position,
            segmentKeys: [
              for (final p in people)
                ValueKey('concept_guardian_journey_${p.id}'),
            ],
            onChanged: (i) {
              if (i >= 0 && i < callbacks.length) callbacks[i]();
            },
          ),
        ),
      ],
    );
  }

  Widget _guardianTabsView(String page) => ZyraGuardianTabsPresentation(
    state: _guardianTabs,
    page: page,
    linked: _conceptHassanLinked,
    paid: _guardianMembership == 'Guardian One',
    adamMain: _conceptLinkedSeeker.isMain,
    photoFor: (id) {
      final index = draftProfiles.indexWhere((p) => p.id == 'draft-$id');
      return index < 0 ? null : _photos?.forIndex(index).firstOrNull;
    },
    notificationCount: _conceptHassanLinked
        ? (_guardianTabs.review != ZyraGuardianReview.continued ? 1 : 0) +
              (_guardianMembership == 'Guardian One' &&
                      _guardianTabs.connection ==
                          ZyraGuardianConnection.pending &&
                      !_guardianTabs.consumedFocus.contains('connect-pending')
                  ? 1
                  : 0)
        : 0,
    onAction: _boundGuardianAction(page),
  );

  ValueChanged<String> _boundGuardianAction(String source) {
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final ownerPage = _page;
    final ownerTab = _tab;
    final revision = _uiRevision;
    final controls = _devControlsEpoch;
    final routes = _devRouteStamp;
    return (action) {
      if (!_allowed ||
          account != (ZyraAccountState.userId, ZyraAccountState.generation) ||
          !_guardianRole ||
          _devControlsVisible ||
          revision != _uiRevision ||
          controls != _devControlsEpoch ||
          routes != _devRouteStamp ||
          ownerPage != _page ||
          ownerTab != _tab) {
        return;
      }
      _guardianTabsAction(action);
    };
  }

  void _guardianTabsAction(String action) {
    final state = _guardianTabs;
    final paid = _guardianMembership == 'Guardian One';
    if (action.startsWith('focus_index_')) {
      final index = int.tryParse(action.substring('focus_index_'.length));
      if (index != null && index >= 0 && index < 2) {
        state.focusIndex = index;
        _publishCheckpoint();
      }
      return;
    }
    if (action == 'notifications') {
      _open('notifications');
      return;
    }
    if (action == 'focus_adam') {
      if (!_conceptHassanLinked) return;
      _move(() {
        state.seeker = 0;
        state.consumedFocus.add(state.reviewFocusId);
        _pages.add('guardian');
      });
      return;
    }
    if (action == 'focus_yusuf') {
      if (_conceptHassanLinked) _tabTo(3);
      return;
    }
    if ((action == 'previous' && !state.canPrevious) ||
        (action == 'next' && !state.canNext)) {
      return;
    }
    if (action == 'back') {
      _back();
      return;
    }
    if (action == 'seeker' ||
        action == 'request_seeker' ||
        action.startsWith('requests_tab_') ||
        action.startsWith('connect_tab_') ||
        action == 'next' ||
        action == 'previous') {
      _act(() {
        if (action == 'seeker') state.seeker = 1 - state.seeker;
        if (action == 'request_seeker') {
          state.requestSeeker = (state.requestSeeker + 1) % 3;
        }
        if (action.startsWith('requests_tab_')) {
          state.requestsSent = action.endsWith('1');
        }
        if (action.startsWith('connect_tab_')) {
          state.connectReceived = action.endsWith('1');
          if (state.connectReceived) state.consumedFocus.add('connect-pending');
        }
        if (action == 'next' || action == 'previous') {
          state.networkIndex += action == 'next' ? 1 : -1;
        }
      });
      return;
    }
    if (action == 'continue' || action == 'pause' || action == 'reopen') {
      if (!_conceptHassanLinked || !_conceptLinkedSeeker.isMain) return;
      if (action == 'reopen'
          ? state.review != ZyraGuardianReview.paused
          : state.review != ZyraGuardianReview.open) {
        return;
      }
      _act(() {
        state.review = action == 'pause'
            ? ZyraGuardianReview.paused
            : action == 'continue'
            ? ZyraGuardianReview.continued
            : ZyraGuardianReview.open;
        if (action == 'reopen') state.hours = 48;
        if (action == 'pause' || action == 'reopen') state.reviewRevision++;
        state.focusIndex = 0;
        state.consumedFocus.remove(state.reviewFocusId);
        _notice = action == 'continue'
            ? 'The Journey continues to Building a Life.'
            : action == 'pause'
            ? 'Paused. Adam and Sara are told their families are taking more time.'
            : 'Review reopened. 48 hours from now.';
      });
      return;
    }
    if (action == 'accept' || action == 'dismiss') {
      if (!_conceptHassanLinked || !_conceptLinkedSeeker.isMain) return;
      if (!paid || state.connection != ZyraGuardianConnection.pending) return;
      _act(() {
        state.connection = action == 'accept'
            ? ZyraGuardianConnection.accepted
            : ZyraGuardianConnection.dismissed;
        if (action == 'dismiss') _notice = 'Not taken up';
      });
      return;
    }
    if (action == 'seeker_0' || action == 'seeker_1') {
      if (!_conceptHassanLinked) return;
      _move(() {
        state.seeker = action.endsWith('0') ? 0 : 1;
        _pages.add('guardian_seeker');
      });
      return;
    }
    if (action == 'requests') {
      _move(() {
        state.requestSeeker = 0;
        state.requestsSent = false;
        _pages.add('guardian_requests');
      });
      return;
    }
    if (action == 'received' || action == 'connect') {
      if (!paid) return;
      _move(() {
        state.connectReceived = action == 'received';
        if (state.connectReceived) state.consumedFocus.add('connect-pending');
        _pages.add('guardian_connect');
      });
      return;
    }
    if (action == 'introductions') {
      _open('guardian_introductions');
      return;
    }
    if (action == 'introduce_confirm' || action == 'connect_confirm') {
      if (!paid || !_conceptHassanLinked) return;
      if (action == 'introduce_confirm' && state.introducedForCurrent()) return;
      if (action == 'connect_confirm' &&
          state.sent.contains(
            ZyraGuardianTabsState.network[state.networkIndex].id,
          )) {
        return;
      }
      _open(
        action == 'introduce_confirm'
            ? 'guardian_introduce'
            : 'network_request',
      );
      return;
    }
    if (action == 'introduce_send' || action == 'connect_send') {
      if (!paid || !_conceptHassanLinked) return;
      _act(() {
        if (action == 'introduce_send') {
          state.introduced.add(state.introducedKey);
        } else {
          state.sent.add(ZyraGuardianTabsState.network[state.networkIndex].id);
        }
        _pages.removeLast();
      });
      return;
    }
    if (action == 'chat') {
      if (paid && state.connection == ZyraGuardianConnection.accepted) {
        _open('guardian_private_chat');
      }
      return;
    }
    if (action == 'journey') {
      if (state.main && _conceptHassanLinked) {
        state.consumedFocus.add(state.reviewFocusId);
        _open('guardian');
      }
      return;
    }
    if (action == 'circle') {
      _open('guardian_circle');
      return;
    }
    if (action == 'network') {
      _tabTo(0);
      return;
    }
    if (action == 'ended') {
      _holdPreviewAction(
        'Ended Journeys',
        'Only what ${state.seekerName} shares with you. Past summaries are not shared.',
      );
      return;
    }
    if (action == 'invite') {
      _holdPreviewAction(
        'Invite your Seeker',
        'Support someone on their journey. Invitations stay in the current app; no real invitation is sent from this comparison.',
      );
      return;
    }
    if (action == 'switch') {
      _open('switch_account_signup');
      return;
    }
    final accountAction = switch (action) {
      'membership' => ZyraConceptAccountAction.membership,
      'subscriptions' => ZyraConceptAccountAction.subscriptions,
      'safety' => ZyraConceptAccountAction.safetyAdvice,
      'invite_zyra' => ZyraConceptAccountAction.invite,
      'personalisation' => ZyraConceptAccountAction.personalisation,
      'settings' => ZyraConceptAccountAction.settings,
      'sign_out' => ZyraConceptAccountAction.signOut,
      _ => null,
    };
    if (accountAction != null) _accountDispatch(accountAction);
  }

  bool Function() _guardianPrivateGuard(
    String page, {
    int Function()? expectedNavigatorStamp,
    bool ownedModal = false,
  }) {
    final revision = _uiRevision,
        controls = _devControlsEpoch,
        routes = _devRouteStamp,
        tab = _tab;
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final connection = _guardianTabs;
    var revoked = false;
    return () {
      if (revoked) return false;
      final admitted =
          mounted &&
          (ownedModal
              ? (widget.canActInOwnedDialog?.call() ?? _allowed)
              : _allowed) &&
          (ownedModal || _accountSession.current) &&
          account == (ZyraAccountState.userId, ZyraAccountState.generation) &&
          identical(connection, _guardianTabs) &&
          _guardianRole &&
          !_devControlsVisible &&
          _conceptHassanLinked &&
          _conceptLinkedSeeker.isMain &&
          _guardianMembership == 'Guardian One' &&
          _guardianTabs.connection == ZyraGuardianConnection.accepted &&
          revision == _uiRevision &&
          controls == _devControlsEpoch &&
          (expectedNavigatorStamp?.call() ?? routes) == _devRouteStamp &&
          tab == _tab &&
          (ownedModal || ModalRoute.of(context)?.isCurrent == true) &&
          _page == page;
      if (!admitted) revoked = true;
      return admitted;
    };
  }

  void _blockGuardianConnection() => _act(() {
    _guardianTabs.connection = ZyraGuardianConnection.blocked;
    _pages.removeWhere(
      (p) => p == 'guardian_private_chat' || p == 'guardian_chat_report',
    );
  });

  Future<void> _guardianChatOptions() async {
    var expectedStamp = _devRouteStamp;
    final current = _guardianPrivateGuard(
      'guardian_private_chat',
      expectedNavigatorStamp: () => expectedStamp,
    );
    final owned = _guardianPrivateGuard(
      'guardian_private_chat',
      expectedNavigatorStamp: () => expectedStamp,
      ownedModal: true,
    );
    if (!current()) return;
    int? sheetStamp;
    var consumed = false;
    final pending = showModalBottomSheet<String>(
      context: _tapContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (sheetContext) {
        bool admitted() =>
            sheetContext.mounted &&
            !consumed &&
            ModalRoute.of(sheetContext)?.isCurrent == true &&
            sheetStamp == _devRouteStamp &&
            owned();
        void choose(String action) {
          if (!admitted()) return;
          consumed = true;
          Navigator.of(sheetContext).pop(action);
          expectedStamp = _devRouteStamp;
        }

        return ZyraTapFeedback(
          level: () => _accountSession.hapticLevel,
          canAct: admitted,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .9,
            ),
            child: ZyraGuardianChatOptions(
              onReport: () => choose('report'),
              onBlock: () => choose('block'),
              onDone: () => choose('done'),
            ),
          ),
        );
      },
    );
    sheetStamp = _devRouteStamp;
    expectedStamp = sheetStamp;
    final action = await pending;
    if (mounted) setState(() {});
    if (!current()) return;
    if (action == 'report') _open('guardian_chat_report');
    if (action == 'block') _blockGuardianConnection();
  }

  Widget _guardianChatReport() {
    final current = _guardianPrivateGuard('guardian_chat_report');
    if (!current()) return _unavailable();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ZyraDraftReportPresentation(
          profile: SeekerProfile(
            id: 'local-noor-guardian',
            photos: const [],
            firstName: "Noor’s Main Guardian",
            age: 0,
            city: '',
            gender: 'female',
          ),
          canSelect: current,
          onBlock: () {
            if (!current()) return;
            _blockGuardianConnection();
          },
        ),
      ),
    );
  }

  Widget _guardianPrivateChat() {
    final current = _guardianPrivateGuard('guardian_private_chat');
    if (!_guardianPrivateGuard('guardian_private_chat', ownedModal: true)()) {
      return _unavailable();
    }
    return ZyraGuardianPrivateChat(
      // Ephemeral transcript/draft belong to this account generation and exact
      // accepted sample connection, never the globally selected Seeker/person.
      key: ValueKey((
        ZyraAccountState.userId,
        ZyraAccountState.generation,
        _guardianTabs,
        'adam:noor',
      )),
      canAct: current,
      onOptions: () {
        if (current()) unawaited(_guardianChatOptions());
      },
      onSend: () {
        if (current()) _act(() {});
      },
      onReport: () {
        if (current()) _open('guardian_chat_report');
      },
    );
  }

  void _holdPreviewAction(String title, String detail) => _move(() {
    _heldTitle = title;
    _heldDetail = detail;
    _pages.add('held_action');
  });

  Widget _guardianInvite() {
    if (_guardianInviteView != null && _guardianInviteRevision == _uiRevision) {
      return _guardianInviteView!;
    }
    final revision = _uiRevision;
    _guardianInviteRevision = revision;
    bool current() =>
        _allowed &&
        revision == _uiRevision &&
        !_guardianRole &&
        _tab == 3 &&
        _page == 'guardian_invite' &&
        _accountSession.current;
    return _guardianInviteView = LinkGuardianScreen(
      // Local confirmation never invokes the ordinary link callback.
      onLinked: () {},
      previewLeading: const ZyraInlineBackButton(),
      localPreview: ZyraCodeLocalPreview(
        canAct: current,
        canInteract: () => current() && !_devControlsVisible,
        interactionEpoch: () => _devControlsEpoch + _devRouteStamp,
        personalCode: ZyraDevPersonalCodeFixtures.forPersona(
          asGuardian: false,
          gender: _accountSession.ownProfile(false).gender,
        ),
        lookupCode: (code) async => current()
            ? ZyraDevPersonalCodeFixtures.previewEntryCode(
                code,
                asGuardian: false,
              )
            : null,
      ),
    );
  }

  Widget _heldPreviewAction() => Column(
    key: const ValueKey('concept_held_action'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(_heldTitle, ''),
      _card([_body(_heldDetail)]),
    ],
  );

  Widget _ownProfilePreview() {
    if (_photos == null && !_photoLoadFailed) {
      return const ZyraLoading();
    }
    if (_ownProfilePreviewView != null &&
        _ownProfilePreviewRevision == _uiRevision) {
      return _ownProfilePreviewView!;
    }
    final fresh = _accountFreshGuard();
    _ownProfilePreviewRevision = _uiRevision;
    return _ownProfilePreviewView = MyProfilePreviewScreen.preview(
      key: ValueKey(('retained-own-profile', _uiRevision, _guardianRole)),
      profile: _accountSession.ownProfile(_guardianRole),
      hapticLevel: _accountSession.hapticLevel,
      canAct: fresh,
      onBack: () {
        if (fresh()) _back();
      },
    );
  }

  // These are explicitly synthetic presentation facts. They do not read a
  // member account, establish verification or grant any purchased access.
  ZyraConceptAccountData get _accountData => ZyraConceptAccountData(
    guardian: _guardianRole,
    guardianInfoSeen: _guardianInfoSeen,
    phoneAccessSeen: _phoneAccessSeen,
    name: _guardianRole ? 'Hassan Rahman' : 'Adam Khan',
    age: _guardianRole ? '54' : '30',
    gender: 'Male',
    location: 'London',
    membership: _membership,
    isOne: !_membership.contains('Basic'),
    relationship: 'Father',
    linkedSeekers: _conceptHassanLinked ? '2' : '0',
    linkedSeekerSummary: _conceptHassanLinked ? 'Adam, Yusuf' : null,
    guardianCount: '${_conceptGuardianPeople.length}',
    signedInWith: 'Apple',
    backgroundLabel: _accountSession.palette.label.replaceAll(' · Current', ''),
    hapticLabel: _accountSession.hapticLevel.label,
    gold: _gold,
    plusUnlocks: _compatibilityAccess.balance,
    photoAsset: _accountSession.photos(_guardianRole).firstOrNull,
    smoothSettings:
        ZyraDevSettingsDesign.current == ZyraSettingsDesign.smoothCards,
    membershipPaymentHistory: _membershipPaymentHistory,
  );

  bool Function() _accountFreshGuard({int Function()? expectedNavigatorStamp}) {
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final revision = _uiRevision;
    final guardian = _guardianRole;
    final page = _page;
    final tab = _tab;
    final controlsEpoch = _devControlsEpoch;
    final navigatorStamp = _devRouteStamp;
    return () =>
        _allowed &&
        account == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        controlsEpoch == _devControlsEpoch &&
        (expectedNavigatorStamp?.call() ?? navigatorStamp) == _devRouteStamp &&
        ModalRoute.of(context)?.isCurrent == true &&
        revision == _uiRevision &&
        guardian == _guardianRole &&
        page == _page &&
        tab == _tab;
  }

  bool Function() _controlsFreshGuard() {
    final fresh = _accountFreshGuard();
    final epoch = _devControlsEpoch;
    return () => _devControlsVisible && epoch == _devControlsEpoch && fresh();
  }

  void _accountDispatch(ZyraConceptAccountAction action) {
    if (_devControlsVisible) return;
    switch (action) {
      case ZyraConceptAccountAction.yourSeekers:
        if (_guardianRole) _tabTo(3);
      case ZyraConceptAccountAction.previewProfile:
        _open('own_profile_preview');
      case ZyraConceptAccountAction.pastJourneys:
        // Ended Journeys live only in My ZYRA in the new methodology.
        return;
      case ZyraConceptAccountAction.personalisation:
        _open('personalisation');
      case ZyraConceptAccountAction.phoneAccess:
        _phoneAccessSeen = true;
        unawaited(_savePhoneAccessSeen());
        _open('phone_access');
      case ZyraConceptAccountAction.settings:
        _open('settings');
      case ZyraConceptAccountAction.membership:
        _membershipDraft = _membershipDraft.copyWith(
          section: _membership.contains('Basic')
              ? (_guardianRole
                    ? ZyraMembershipSection.guardian
                    : ZyraMembershipSection.seeker)
              : ZyraMembershipSection.current,
        );
        _open('membership');
      case ZyraConceptAccountAction.subscriptions:
        _open('subscriptions');
      case ZyraConceptAccountAction.compatibilityStore:
        _open('compatibility_store');
      case ZyraConceptAccountAction.guardianInfo:
        if (_guardianRole || _tab != 4 || _pages.isNotEmpty) return;
        _guardianInfoSeen = true;
        unawaited(_saveGuardianInfoSeen());
        _open('guardian_info');
      case ZyraConceptAccountAction.safetyAdvice:
        _move(() {
          _personId = null;
          _pages.add('safety_advice');
        });
      case ZyraConceptAccountAction.signOut:
        // Leaving the disposable preview never signs out the live account.
        if (_allowed) widget.onExit();
      case ZyraConceptAccountAction.helpSupport:
        _open('help_support');
      case ZyraConceptAccountAction.editProfile:
        if (!_guardianRole) _open('edit_profile');
      case ZyraConceptAccountAction.managePhotos:
        _open('manage_photos');
      default:
        _move(() {
          _accountDestination = action;
          _pages.add('account_action');
        });
    }
  }

  ZyraWalletRole get _walletRole =>
      _guardianRole ? ZyraWalletRole.guardian : ZyraWalletRole.seeker;

  bool Function() _walletGuard() {
    final fresh = _accountFreshGuard();
    final wallet = _subscriptionWallet;
    return () =>
        fresh() &&
        !_devControlsVisible &&
        identical(wallet, _subscriptionWallet);
  }

  void _cacheWallet(ZyraSubscriptionWalletDraft draft) {
    if (!_allowed ||
        _devControlsVisible ||
        draft.ownerId != _subscriptionWallet.ownerId ||
        draft.revision <= _subscriptionWallet.revision) {
      return;
    }
    _act(() {
      _subscriptionWallet = draft;
      for (final role in ZyraWalletRole.values) {
        final facts = draft.forRole(role);
        if (!facts.isCovered) continue;
        final label = '${role.label} ${facts.isOne ? 'One' : 'Basic'}';
        if (role == ZyraWalletRole.seeker) {
          _seekerMembership = label;
          if (facts.isOne) _model.setCapacity(3);
        } else {
          _guardianMembership = label;
        }
      }
    });
  }

  void _walletSwitch(ZyraWalletRole role) {
    if (!_allowed ||
        _devControlsVisible ||
        _subscriptionWallet.nextStep(role) !=
            ZyraWalletNextStep.switchProfile) {
      return;
    }
    final facts = _subscriptionWallet.forRole(role);
    if (role == ZyraWalletRole.seeker &&
        !_model.setCapacity(facts.isOne ? 3 : 1)) {
      _act(
        () => _notice =
            'Choose the 1 Journey sample before testing Basic. Existing sample Journeys are unchanged.',
      );
      return;
    }
    final label = '${role.label} ${facts.isOne ? 'One' : 'Basic'}';
    if (role == ZyraWalletRole.seeker) {
      _seekerMembership = label;
    } else {
      _guardianMembership = label;
      _model.setSampleGuardianMembership(
        'draft-guardian-hassan',
        facts.isOne
            ? DraftGuardianMembership.one
            : DraftGuardianMembership.basic,
      );
    }
    _switchRole(role == ZyraWalletRole.guardian);
  }

  void _walletSetup(ZyraWalletRole role) {
    if (!_allowed ||
        _devControlsVisible ||
        !{
          ZyraWalletNextStep.finishSetup,
          ZyraWalletNextStep.startSetup,
        }.contains(_subscriptionWallet.nextStep(role))) {
      return;
    }
    _walletSetupRole = role;
    _open('switch_account_setup');
  }

  void _walletMembership(ZyraWalletRole role) {
    if (!_allowed ||
        _devControlsVisible ||
        _subscriptionWallet.nextStep(role) !=
            ZyraWalletNextStep.chooseMembership) {
      return;
    }
    _membershipDraft = _membershipDraft.copyWith(
      section: role == ZyraWalletRole.seeker
          ? ZyraMembershipSection.seeker
          : ZyraMembershipSection.guardian,
    );
    _open('membership');
  }

  Widget _ownProfile() {
    final fresh = _accountFreshGuard();
    return ZyraConceptProfilePresentation(
      data: _accountData,
      simplifiedMethodology: true,
      onAction: (action) {
        if (fresh()) _accountDispatch(action);
      },
      onSwitchRole: () {
        if (fresh() && !_devControlsVisible) _open('switch_account_signup');
      },
    );
  }

  Widget _subscriptionsView() {
    final fresh = _walletGuard();
    return ZyraSubscriptionWalletPreview(
      draft: _subscriptionWallet,
      currentRole: _walletRole,
      showBackButton: false,
      canAct: fresh,
      onChanged: (draft) {
        if (fresh()) _cacheWallet(draft);
      },
      onSwitch: (role) {
        if (fresh()) _walletSwitch(role);
      },
      onSetup: (role) {
        if (fresh()) _walletSetup(role);
      },
      onMembership: (role) {
        if (fresh()) _walletMembership(role);
      },
      onBack: () {
        if (fresh()) _back();
      },
    );
  }

  Widget _switchSignupView({required bool setupOverview}) {
    final fresh = _walletGuard();
    if (!setupOverview) {
      return ZyraSubscriptionSwitchPreview(
        draft: _subscriptionWallet,
        currentRole: _walletRole,
        showBackButton: false,
        canAct: fresh,
        onChanged: (draft) {
          if (fresh()) _cacheWallet(draft);
        },
        onSwitch: (role) {
          if (fresh()) _walletSwitch(role);
        },
        onSetup: (role) {
          if (fresh()) _walletSetup(role);
        },
        onMembership: (role) {
          if (fresh()) _walletMembership(role);
        },
        onBack: () {
          if (fresh()) _back();
        },
      );
    }
    final target = _walletSetupRole ?? _walletRole.other;
    return ZyraSwitchSignupPreview(
      guardian: target == ZyraWalletRole.seeker,
      setupOverview: true,
      currentMembership: _membership,
      onStartSetup: () {},
      onReturnToProfile: () {
        if (fresh()) _move(_pages.clear);
      },
    );
  }

  Set<ZyraMembershipProduct> get _coveredWalletProducts => {
    for (final role in ZyraWalletRole.values)
      if (_subscriptionWallet.forRole(role).isCovered)
        switch ((role, _subscriptionWallet.forRole(role).isOne)) {
          (ZyraWalletRole.seeker, true) => ZyraMembershipProduct.seekerOne,
          (ZyraWalletRole.seeker, false) => ZyraMembershipProduct.seekerBasic,
          (ZyraWalletRole.guardian, true) => ZyraMembershipProduct.guardianOne,
          (ZyraWalletRole.guardian, false) =>
            ZyraMembershipProduct.guardianBasic,
        },
  };

  Widget _membershipView() {
    final fresh = _accountFreshGuard();
    bool allowed() => fresh() && !_devControlsVisible;
    bool unlocksCurrent() =>
        allowed() && _membershipDraft.section == ZyraMembershipSection.unlocks;
    return ZyraConceptMembershipPresentation(
      data: _accountData,
      initialDraft: _membershipDraft,
      currentProducts: _coveredWalletProducts,
      currentDetail: _subscriptionWallet
          .forRole(_walletRole)
          .coverageLabel(_walletRole),
      unlocksContent: ZyraDraftCompatibilityStorePresentation(
        isSeekerOne: _seekerMembership == 'Seeker One',
        canAct: unlocksCurrent,
        balance: _guardianRole ? null : _compatibilityAccess.balance,
        onTerms: _bound(() {
          if (!unlocksCurrent()) return;
          _move(() {
            _accountDestination = ZyraConceptAccountAction.privacyData;
            _settingsDetail = ZyraConceptSettingsDetail.terms;
            _pages.add('settings_detail');
          });
        }),
      ),
      canAct: allowed,
      showBackButton: false,
      onAction: (action) {
        if (!allowed()) return;
        if (action == ZyraConceptAccountAction.cancelMembership &&
            _membershipDraft.section != ZyraMembershipSection.current) {
          return;
        }
        _accountDispatch(action);
      },
      onDraftChanged: (draft) {
        if (!allowed()) return;
        if (draft.section != _membershipDraft.section) {
          // Section-owned actions must expire permanently on leaving, not
          // revive when the member later returns to the same section.
          setState(() {
            _uiRevision++;
            _membershipDraft = draft;
          });
        } else {
          // Keep the role pager's controller attached while it is swiping.
          _membershipDraft = draft;
        }
      },
      onReview: (request) {
        if (!allowed()) return;
        final current = ZyraMembershipReviewRequest.fromDraft(
          _membershipDraft,
          currentProducts: _coveredWalletProducts,
          paymentHistory: _membershipPaymentHistory,
        );
        if (current == null ||
            current.kind != request.kind ||
            current.products.length != request.products.length ||
            !current.products.containsAll(request.products) ||
            current.familyQuote?.seekers != request.familyQuote?.seekers ||
            current.familyQuote?.guardians != request.familyQuote?.guardians) {
          return;
        }
        _membershipReview = current;
        _open('membership_review');
      },
      onBack: () {
        if (allowed()) _back();
      },
    );
  }

  Widget _membershipReviewView() {
    final request = _membershipReview;
    if (request == null) return _unavailable();
    final fresh = _accountFreshGuard();
    return SafeArea(
      child: ZyraMembershipReviewPresentation(
        request: request,
        paymentHistory: _membershipPaymentHistory,
        canAct: () => fresh() && !_devControlsVisible,
      ),
    );
  }

  Widget _phoneAccess() {
    final fresh = _accountFreshGuard();
    return ZyraPhoneAccessPage(
      key: ValueKey((
        'phone_access',
        _uiRevision,
        _devControlsEpoch,
        _devRouteStamp,
      )),
      canAct: () => fresh() && !_devControlsVisible,
      onBack: () {
        if (fresh()) _back();
      },
    );
  }

  Widget _settings() {
    final fresh = _accountFreshGuard();
    return ZyraConceptSettingsPresentation(
      data: _accountData,
      showBackButton: false,
      onAction: (action) {
        if (fresh()) _accountDispatch(action);
      },
      onBack: () {
        if (fresh()) _back();
      },
    );
  }

  Widget _personalisation() => _retainedAccountLeaf();

  bool get _isRetainedAccountPage => const [
    'edit_profile',
    'filter_preferences',
    'manage_photos',
    'personalisation',
  ].contains(_page);

  void _accountChanged() {
    if (!_allowed) _cancelEndedReadDeadline();
    if (!_allowed) return;
    // Local presentation updates are not navigation epochs. Keeping this
    // lifetime stable lets the retained choice sheet return to its own page.
    setState(() => _gold = _accountSession.goldEnabled);
    _syncGoldMotion();
  }

  Widget _retainedAccountLeaf() {
    if (_page == 'manage_photos' && _photos == null && !_photoLoadFailed) {
      return const ZyraLoading();
    }
    if (_accountLeafView != null && _accountLeafRevision == _uiRevision) {
      return _accountLeafView!;
    }
    final revision = _uiRevision;
    final guardian = _guardianRole;
    final page = _page;
    final tab = _tab;
    final preferences = page == 'filter_preferences'
        ? _accountSession.compatibility.load('draft-self')
        : null;
    final navigator = GlobalKey<NavigatorState>();
    _accountNavigator = navigator;
    _accountLeafRevision = revision;
    bool current() =>
        _allowed &&
        revision == _uiRevision &&
        guardian == _guardianRole &&
        page == _page &&
        tab == _tab &&
        _accountSession.current;
    void back() {
      if (current() && !_devControlsVisible) _back();
    }

    void support() {
      if (current() && !_devControlsVisible) _open('help_support');
    }

    // Publication rebuilds the leaf. Keep its admitted callbacks stable for
    // this route epoch rather than accidentally revoking its own editor.
    void photosChanged(List<String> photos) {
      if (current()) _accountSession.setPhotos(guardian, photos);
    }

    void avatarChanged(Offset alignment) {
      if (current()) _accountSession.setAvatar(guardian, alignment);
    }

    void hapticChanged(ZyraHapticLevel level) {
      if (!current() ||
          _devControlsVisible ||
          !_accountSession.setHapticLevel(level)) {
        return;
      }
    }

    void goldChanged(bool enabled) {
      if (current() && !_devControlsVisible) {
        _accountSession.setGoldEnabled(enabled);
      }
    }

    // The retained hub owns its ordinary child routes in this Navigator.
    // Covering the hub with its own editor or picker does not cover the
    // admitted Founder route or grant a stale page permission to save.
    return _accountLeafView = Navigator(
      observers: [ZyraDevControlsRouteObserver()],
      key: navigator,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => ZyraPullDownBackScope(
          key: const ValueKey('concept_pull_down_back_scope'),
          // This shell already paints the full-viewport local palette and
          // gold. A global cue fill would hide both behind the retained leaf.
          paintBackground: false,
          routeIdentity: ('retained-account', revision, guardian, page, tab),
          onBack: back,
          child: ListenableBuilder(
            listenable: _accountSession,
            builder: (_, _) => switch (page) {
              'filter_preferences' => FutureBuilder(
                future: preferences,
                builder: (_, snapshot) =>
                    snapshot.connectionState != ConnectionState.done
                    ? const ZyraLoading()
                    : CompatibilityEditorScreen.preview(
                        kind: CompatibilityEditorKind.trafficLights,
                        initialDraft: ZyraCompatibilityDraft.fromSnapshot(
                          gender: 'male',
                          snapshot: snapshot.data,
                        ),
                        onPreviewReturn: (_) => back(),
                        canAct: current,
                        canActChanges: _accountSession,
                        onPersist: (draft) async =>
                            current() &&
                            await _accountSession.compatibility.save(
                              'draft-self',
                              draft,
                            ) &&
                            current(),
                      ),
              ),
              'edit_profile' => EditProfileScreen.preview(
                repository: _accountSession.compatibility,
                canAct: current,
                gender: 'male',
                age: 30,
                onSupport: support,
              ),
              'manage_photos' => EditPhotosScreen.preview(
                canAct: current,
                localPhotoImport: widget.localPhotoImport,
                initialPhotos: _accountSession.photos(guardian),
                gender: 'male',
                hapticLevel: _accountSession.hapticLevel,
                initialAlignmentX: _accountSession.avatar(guardian).dx,
                initialAlignmentY: _accountSession.avatar(guardian).dy,
                onPhotosChanged: photosChanged,
                onAvatarChanged: avatarChanged,
              ),
              _ => PersonalisationScreen.preview(
                canAct: current,
                palette: _accountSession.palette,
                hapticLevel: _accountSession.hapticLevel,
                goldEnabled: _accountSession.goldEnabled,
                onHapticChanged: hapticChanged,
                onGoldChanged: goldChanged,
              ),
            },
          ),
        ),
      ),
    );
  }

  String _accountActionLabel(ZyraConceptAccountAction action) =>
      switch (action) {
        ZyraConceptAccountAction.yourSeekers => 'Your Seekers',
        ZyraConceptAccountAction.previewProfile => 'Preview my profile',
        ZyraConceptAccountAction.editProfile => 'Edit profile',
        ZyraConceptAccountAction.managePhotos => 'Manage photos',
        ZyraConceptAccountAction.compatibilityStore => 'Compatibility Unlocks',
        ZyraConceptAccountAction.pastJourneys => 'Past Journeys',
        ZyraConceptAccountAction.guardianInfo => 'What Guardians can do',
        ZyraConceptAccountAction.safetyAdvice => 'Safety & advice',
        ZyraConceptAccountAction.invite => 'Invite someone to ZYRA',
        ZyraConceptAccountAction.personalisation => 'Personalisation',
        ZyraConceptAccountAction.settings => 'Settings',
        ZyraConceptAccountAction.signOut => 'Sign out',
        ZyraConceptAccountAction.signInSecurity => 'Sign-in & security',
        ZyraConceptAccountAction.appLock => 'App lock',
        ZyraConceptAccountAction.phoneAccess => 'Phone access',
        ZyraConceptAccountAction.advanced => 'Advanced',
        ZyraConceptAccountAction.guardianPrivacy => 'Guardian privacy',
        ZyraConceptAccountAction.visibility => 'Pause My Profile',
        ZyraConceptAccountAction.hiddenProfiles => 'Hidden profiles',
        ZyraConceptAccountAction.notificationSettings =>
          'Notifications & emails',
        ZyraConceptAccountAction.membership => 'Membership',
        ZyraConceptAccountAction.helpSupport => 'Help & support',
        ZyraConceptAccountAction.feedback => 'Send feedback',
        ZyraConceptAccountAction.privacyData => 'Privacy & data',
        ZyraConceptAccountAction.background => 'Background',
        ZyraConceptAccountAction.haptics => 'Haptic feel',
        ZyraConceptAccountAction.cancelMembership => 'Cancel membership',
        ZyraConceptAccountAction.subscriptions => 'Your subscriptions',
      };

  Widget _accountActionView() {
    final action = _accountDestination;
    if (_settingsOverviewActions.contains(action)) {
      final fresh = _accountFreshGuard();
      final pending = _hiddenProfileRestore;
      bool currentHidden(String id) =>
          fresh() &&
          !_devControlsVisible &&
          !_guardianRole &&
          _accountDestination == ZyraConceptAccountAction.hiddenProfiles &&
          _profileIds.contains(id) &&
          _model.isHidden(id);
      bool currentRestore() =>
          pending != null &&
          currentHidden(pending.id) &&
          _hiddenProfileRestore == pending &&
          pending.revision == _uiRevision &&
          pending.controlsEpoch == _devControlsEpoch &&
          pending.navigatorStamp == _devRouteStamp;
      return ZyraConceptSettingsOverview(
        action: action!,
        data: _accountData,
        hiddenProfiles:
            action == ZyraConceptAccountAction.hiddenProfiles && !_guardianRole
            ? [
                for (final person in draftProfiles)
                  if (_model.isHidden(person.id))
                    ZyraConceptHiddenProfile(
                      id: person.id,
                      name: '${person.firstName} ${person.surname}'.trim(),
                      detail: '${person.age} · ${person.city}',
                      thumbnail: _hiddenProfileThumbnail(person),
                    ),
              ]
            : null,
        onUnhide: (id) {
          if (!currentHidden(id)) return;
          _act(() {
            _hiddenProfileRestore = (
              id: id,
              revision: _uiRevision + 1,
              controlsEpoch: _devControlsEpoch,
              navigatorStamp: _devRouteStamp,
            );
          });
        },
        confirmingHiddenProfileId: currentRestore() ? pending!.id : null,
        onViewHiddenProfile: pending != null && _model.isBlocked(pending.id)
            ? null
            : () {
                final id = pending?.id;
                if (id == null || !currentRestore() || _model.isBlocked(id)) {
                  return;
                }
                _open('profile', person: id);
              },
        onCancelUnhide: () {
          if (currentRestore()) _act(() {});
        },
        onConfirmUnhide: () {
          if (!currentRestore()) return;
          _act(() => _model.unhide(pending!.id));
        },
        onOpenDetail: (detail) {
          if (!fresh() || _devControlsVisible) return;
          _move(() {
            _settingsDetail = detail;
            _pages.add('settings_detail');
          });
        },
        onHelp: () {
          if (fresh() && !_devControlsVisible) _open('help_support');
        },
      );
    }
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      action == null
                          ? 'Unavailable'
                          : _accountActionLabel(action),
                      style: ZyraText.heading(size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('concept_account_action_scroll'),
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 100),
                children: [
                  Text(
                    'This action is not available here. It does not open your live account, edit member records, change security or device preferences, send invitations or feedback, or manage billing.',
                    style: ZyraText.subtext(size: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _hiddenProfileThumbnail(DraftProfile person) {
    // Only this admitted fictional deck may supply a thumbnail. Never recover
    // a hidden member's photograph from URLs, identifiers or cached summaries.
    if (!_allowed ||
        _guardianRole ||
        !_model.isHidden(person.id) ||
        _model.isBlocked(person.id)) {
      return null;
    }
    final index = draftProfiles.indexWhere((known) => identical(known, person));
    if (index < 0) return null;
    final photos = _photos?.forIndex(index);
    if (photos == null || photos.isEmpty) return null;
    final source = photos.first;
    if (!_browsePhotoRenderer.isReady(source)) return null;
    return _browsePhotoRenderer.build(
      context,
      source,
      width: 50,
      height: 50,
      alignment: Alignment.topCenter,
    );
  }

  Widget _settingsDetailView() {
    final detail = _settingsDetail;
    if (detail == null) return _unavailable();
    final fresh = _accountFreshGuard();
    return ZyraConceptSettingsDetailPresentation(
      detail: detail,
      guardian: _guardianRole,
      overviewAction: _accountDestination,
      onHelp: () {
        if (fresh() && !_devControlsVisible) _open('help_support');
      },
    );
  }

  Widget? _journeyBioPortrait(DraftProfile person) {
    final source = _displayProfile(person).photoUrl;
    if (source.isEmpty || !_browsePhotoRenderer.isReady(source)) return null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: _browsePhotoRenderer.build(
        context,
        source,
        width: 104,
        height: 132,
        alignment: Alignment.topCenter,
      ),
    );
  }

  Widget _bio() {
    final person = _person;
    if (person == null || !_canAddressJourneyDisclosure(person.id)) {
      return _unavailable();
    }
    if (!_canViewJourneyBio(person.id)) {
      return _journeyDisclosureLocked(bio: true);
    }
    if (!_model.canViewJourneyBio(person.id)) {
      // Earlier paid/profile access opens the destination, never another
      // person's private Bio or the independent mutual-sharing choice.
      return _pageScroll([
        _heading('Journey Bio', 'You and ${person.firstName}'),
        _card([
          _eyebrow('ACCESS ALREADY UNLOCKED'),
          _title('Ready when you both are', size: 23),
          _body(
            'Your earlier Compatibility Unlock is still active. '
            'Biography details will appear when you both choose to share.',
          ),
        ]),
      ], key: ValueKey('draft_journey_bio_waiting_${person.id}'));
    }
    // Only an explicitly addressed offline projection enters this view. The
    // signed-in owner's saved Bio is never substituted for the other person.
    return ZyraDraftJourneyBioPresentation(
      key: ValueKey('draft_journey_bio_${person.id}'),
      subjectId: person.id,
      firstName: person.firstName,
      projection: ZyraDraftJourneyBioProjection.fixtureFor(
        person.id,
        useLegacyFixture: true,
      ),
      portrait: _journeyBioPortrait(person),
    );
  }

  VoidCallback _bioStepAction(DraftProfile person, bool Function() change) {
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    final page = _page;
    return _bound(() {
      final correctPage =
          page == 'journey' ||
          (page == 'controls' && _pageOptionsSource == 'journey');
      if (fresh() &&
          correctPage &&
          page == _page &&
          revision == _uiRevision &&
          _personId == person.id &&
          _canAddressJourneyDisclosure(person.id) &&
          _model.canParticipateInJourney(person.id) &&
          _model.isBioStepOpen(person.id)) {
        _act(() {
          change();
        });
      }
    });
  }

  Widget _journeyBioStep(DraftProfile person) {
    final id = person.id;
    final revealed = _model.bioRevealed(id);
    final mine = _model.hasChosenBioReveal(id);
    final ready = _model.hasChosenBioContinue(id);
    final peerReady = _model.peerHasChosenBioContinue(id);
    return SafeArea(
      key: ValueKey('draft_journey_bio_step_$id'),
      child: ZyraShadowScrollView(
        key: const ValueKey('draft_scroll'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heading('Journey Bio', 'You and ${person.firstName}'),
            if (revealed)
              ZyraDraftJourneyBioPresentation(
                subjectId: id,
                firstName: person.firstName,
                projection: ZyraDraftJourneyBioProjection.fixtureFor(
                  id,
                  useLegacyFixture: true,
                ),
                portrait: _journeyBioPortrait(person),
                ownedViewport: false,
                showTitle: false,
              )
            else
              _card([
                const Icon(
                  Icons.notes_outlined,
                  size: 32,
                  color: ZyraColors.journeyGold,
                ),
                const SizedBox(height: 16),
                _title(
                  mine
                      ? 'Your choice is shared'
                      : 'Meet the person behind the profile',
                  size: 24,
                ),
                _body(
                  mine
                      ? 'Waiting for ${person.firstName} to share. Your stories open together.'
                      : 'Your biographies open only when you both choose to share. Only selected details are included.',
                ),
                if (!mine)
                  _button(
                    'draft_bio_reveal_$id',
                    'Share Journey Bio',
                    _bioStepAction(person, () => _model.chooseBioReveal(id)),
                    primary: true,
                  ),
              ]),
            if (revealed) ...[
              const SizedBox(height: 22),
              if (ready && !peerReady)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Waiting for ${person.firstName} to continue.',
                    style: ZyraText.subtext(),
                    textAlign: TextAlign.center,
                  ),
                ),
              _button(
                'draft_bio_continue_$id',
                ready && !peerReady
                    ? 'Waiting for ${person.firstName}'
                    : 'Continue Journey',
                !ready || _model.canCompleteBioStep(id)
                    ? _bioStepAction(person, () {
                        final changed = !ready && _model.chooseBioContinue(id);
                        if (_model.canCompleteBioStep(id)) {
                          return _model.completeBioStep(id);
                        }
                        return changed;
                      })
                    : null,
                primary: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _endedCompatibility() {
    final person = _person;
    final route = _compatibilityRoute;
    final attemptId = _endedCompatibilityAttemptId;
    if (person == null ||
        route == null ||
        attemptId == null ||
        !_canAddressEndedJourney(person.id)) {
      return _unavailable();
    }
    if (!_canViewEndedCompatibility(person.id, attemptId: attemptId)) {
      return _pageScroll([
        _heading('Compatibility score', ''),
        _card([
          _title('Compatibility score is private', size: 23),
          _body(
            'Journey access lasts for three months after that Journey ends, '
            'and only includes a result you revealed together. A used profile '
            'Unlock stays permanent. Unused Unlocks do not open this history.',
          ),
        ]),
      ], key: ValueKey('draft_ended_compatibility_locked_${person.id}'));
    }
    // No reveal, debit, purchase or stage mutation belongs to this reader.
    // The exact current caller-owned used grant is independently re-read.
    final used = _compatibilityAccess.resultFor(person.id);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: ZyraDraftCompatibilityPresentation(
          key: ValueKey(('draft_ended_compatibility', route, attemptId)),
          personName: person.firstName,
          balance: 0,
          overallScore:
              used?.overallScore ??
              ZyraDraftCompatibilityPreview(person.id, balance: 0).overallScore,
          revealed: true,
          onUnlock: null,
          onBuyMore: null,
        ),
      ),
    );
  }

  Widget _compatibilityInfo() {
    final route = _compatibilityRoute;
    final person = _person;
    final controlsEpoch = _devControlsEpoch;
    final navigatorStamp = _devRouteStamp;
    final hostRoute = ModalRoute.of(context);
    if (!_allowed ||
        _guardianRole ||
        route == null ||
        person == null ||
        _model.isBlocked(person.id)) {
      return _unavailable();
    }
    bool current() =>
        _allowed &&
        controlsEpoch == _devControlsEpoch &&
        navigatorStamp == _devRouteStamp &&
        hostRoute?.isCurrent == true &&
        !_guardianRole &&
        _page == 'compatibility' &&
        identical(route, _compatibilityRoute) &&
        _personId == person.id &&
        !_model.isBlocked(person.id);
    VoidCallback? unlock() {
      if (_compatibilityAccess.isUnlocked(person.id) ||
          _compatibilityAccess.balance == 0) {
        return null;
      }
      return _bound(() {
        if (current()) {
          _act(() {
            _compatibilityAccess.unlock(person.id);
          });
        }
      });
    }

    return SafeArea(
      child: Padding(
        // No bottom navigation is shown on this temporary result page.
        // Give its original-theme card the actual available phone viewport.
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: ZyraDraftCompatibilityPresentation(
          key: ValueKey(('draft_compatibility', route)),
          canAct: current,
          personName: person.firstName,
          balance: _compatibilityAccess.balance,
          overallScore:
              _compatibilityAccess.resultFor(person.id)?.overallScore ??
              ZyraDraftCompatibilityPreview(person.id, balance: 0).overallScore,
          revealed: _compatibilityAccess.isUnlocked(person.id),
          onUnlock: unlock(),
          onBuyMore: _bound(() {
            if (current()) _open('compatibility_store');
          }),
        ),
      ),
    );
  }

  Widget _compatibilityStore() {
    final fresh = _accountFreshGuard();
    final controlsEpoch = _devControlsEpoch;
    final navigatorStamp = _devRouteStamp;
    final hostRoute = ModalRoute.of(context);
    bool current() =>
        fresh() &&
        !_devControlsVisible &&
        controlsEpoch == _devControlsEpoch &&
        navigatorStamp == _devRouteStamp &&
        hostRoute?.isCurrent == true &&
        _page == 'compatibility_store';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: ZyraDraftCompatibilityStorePresentation(
          isSeekerOne: _seekerMembership == 'Seeker One',
          canAct: current,
          balance: _guardianRole ? null : _compatibilityAccess.balance,
          onTerms: _bound(() {
            if (!current()) return;
            _move(() {
              _accountDestination = ZyraConceptAccountAction.privacyData;
              _settingsDetail = ZyraConceptSettingsDetail.terms;
              _pages.add('settings_detail');
            });
          }),
        ),
      ),
    );
  }

  Widget _compatibilityCreditChoices() {
    final balance = _compatibilityAccess.balance;
    return Row(
      children: [
        for (final count in const [0, 1, 5]) ...[
          if (count != 0) const SizedBox(width: 8),
          Expanded(
            child: _previewAction(
              'draft_compatibility_unlock_$count',
              '$count',
              () => _act(() {
                if (_guardianRole) return;
                // One viewer balance; assigning a test preset never clears
                // already-used per-profile access or advances Journey consent.
                _compatibilityAccess.setBalance(count: count);
              }),
              selected: balance == count,
              centered: true,
              showChevron: false,
              semanticLabel:
                  'Set Compatibility Unlock sample credits to $count',
            ),
          ),
        ],
      ],
    );
  }

  Widget _notificationsView() => _card([
    _title('Only what matters to you.', size: 26),
    _body(
      _currentJourneys.length > 1
          ? '${_currentJourneys.length} Journeys are in progress. Open Journey to choose one.'
          : _focus == null
          ? _visibleRequests(DraftJourneyState.received).isNotEmpty
                ? 'A Journey invitation is waiting in My ZYRA.'
                : 'No Journey requests need your attention right now.'
          : _model.isBlocked(_focus!.id)
          ? 'This Journey is unavailable. Its place is retained until you end it.'
          : 'Your Journey with ${_focus!.firstName} is ${_stateLabel(_model.stateFor(_focus!.id)!)}.',
    ),
    _button(
      'concept_updates_connections',
      _focus == null
          ? 'View requests'
          : _currentJourneys.length > 1
          ? 'View your Journeys'
          : 'Open your Journey',
      () => _focus == null
          ? _activity('requests')
          : _currentJourneys.length > 1
          ? _tabTo(1)
          : _journey(_focus!.id),
    ),
    _body(
      'No real notifications are fetched, marked read or sent.',
      small: true,
    ),
  ]);
  Future<void> _pickBrowseCountry() async {
    if (!_allowed || _page != 'filters') return;
    final revision = _uiRevision;
    final guardian = _guardianRole;
    final result = await showSingleSearchPicker(context, [
      for (final c in zyraCountries) c.name,
    ], current: zyraBrowseCountryLabel(_editingBrowseFilter.countryCode));
    if (!_allowed ||
        revision != _uiRevision ||
        guardian != _guardianRole ||
        _page != 'filters' ||
        result == null) {
      return;
    }
    final code = zyraCountries.where((c) => c.name == result).firstOrNull?.code;
    if (code != null) {
      _act(() => _editingBrowseFilter = _editingBrowseFilter.withCountry(code));
    }
  }

  Future<void> _applyBrowseFilter() async {
    if (!_allowed || _page != 'filters') return;
    if (_location.point != null) {
      final fresh = _accountFreshGuard();
      await _location.recheck();
      if (!fresh()) return;
    }
    _syncLocationOrigins();
    _move(() {
      _browseFilter = _editingBrowseFilter;
      _browseIndex = 0;
      _browseHistory.reset();
      _pages.removeLast();
    });
  }

  Widget _filters() {
    final revision = _uiRevision;
    final guardian = _guardianRole;
    bool current() =>
        _allowed &&
        !_devControlsVisible &&
        revision == _uiRevision &&
        guardian == _guardianRole &&
        _page == 'filters' &&
        _locationSheet == 0;
    return ZyraOneJourneyFiltersPresentation(
      filter: _editingBrowseFilter,
      homeTown: _homeTown,
      paintWhileCovered: _locationSheet != 0,
      currentArea: _location.point != null,
      canAct: () => current() && _locationSheet == 0,
      onChanged: (filter) {
        if (current()) _act(() => _editingBrowseFilter = filter);
      },
      onApply: () {
        if (current()) _applyBrowseFilter();
      },
      onCountry: () {
        if (current()) _pickBrowseCountry();
      },
      onOrigin: () {
        if (current()) _openFilterOrigin();
      },
      onPreferences: () {
        if (current()) _open('filter_preferences');
      },
    );
  }

  String get _homeTown => _accountSession.ownProfile(false).city;
  ZyraBrowsePoint? get _homeTownPoint => zyraSampleTownPoint(_homeTown);

  void _syncLocationOrigins() {
    final origin = _location.point ?? _homeTownPoint;
    _browseFilter = _browseFilter.withOrigin(origin);
    _editingBrowseFilter = _editingBrowseFilter.withOrigin(origin);
  }

  void _locationChanged() {
    if (!mounted) return;
    setState(_syncLocationOrigins);
    _publishCheckpoint();
  }

  int _locationRevision = 0, _locationRoute = 0;
  bool _locationGuardian = false;
  bool _locationFlowCurrent() =>
      _allowed &&
      _location.current &&
      !_devControlsVisible &&
      _locationRevision == _uiRevision &&
      _locationRoute == _devRouteStamp &&
      _locationGuardian == _guardianRole &&
      !_guardianRole &&
      _page == 'filters' &&
      _editingBrowseFilter.where == ZyraBrowseWhere.nearMe;

  void _closeLocationFlow() {
    _locationFlow++;
    _locationSheet = 0;
    _location.cancelPending();
  }

  void _openFilterOrigin() {
    if (!_allowed || _page != 'filters' || _guardianRole) return;
    _locationRevision = _uiRevision;
    _locationRoute = _devRouteStamp;
    _locationGuardian = _guardianRole;
    _locationFlow++;
    setState(() => _locationSheet = 1);
  }

  Widget _locationOverlay() {
    final flow = _locationFlow;
    bool current() => flow == _locationFlow && _locationFlowCurrent();
    return ZyraOneJourneyLocationSheet(
      explain: _locationSheet == 2,
      town: _homeTown,
      currentArea: _location.point != null,
      canAct: current,
      onClose: () {
        if (current()) setState(_closeLocationFlow);
      },
      onHome: () {
        if (!current()) return;
        _location.clear();
      },
      onCurrent: () {
        if (!current()) return;
        if (_location.point != null) {
          setState(_closeLocationFlow);
        } else if (!_location.explained && !_location.refused) {
          setState(() => _locationSheet = 2);
        } else {
          _requestLocation(flow);
        }
      },
      onContinue: () {
        if (current()) _requestLocation(flow);
      },
    );
  }

  Future<void> _requestLocation(int flow) async {
    if (!_locationFlowCurrent() || flow != _locationFlow) return;
    setState(() => _locationSheet = 0);
    final settings = _location.refused;
    bool current() => flow == _locationFlow && _locationFlowCurrent();
    final allowed = await _location.request(current);
    if (!current()) return;
    setState(() {
      _syncLocationOrigins();
      if (!allowed && !settings) _notice = zyraLocationFallback;
    });
  }

  Widget _safetyAdvice() {
    final fresh = _accountFreshGuard();
    return ZyraDraftSafetyAdvicePresentation(
      guardian: _guardianRole,
      canAct: fresh,
      onReport: () {
        if (fresh()) _open('safety');
      },
      onHelp: () {
        if (fresh()) _open('help_support');
      },
    );
  }

  // A waiting acceptance does not occupy a place, even when it holds an
  // ending against a different person. Only this person's current attempt
  // may be ended by this deliberate confirmation.
  bool _warnBeforePersonSafety(
    DraftProfile person, {
    required bool hide,
    required bool Function() canAct,
  }) {
    if (_guardianRole) return false;
    final state = _model.stateFor(person.id);
    if (state != DraftJourneyState.preparing &&
        state != DraftJourneyState.active) {
      return false;
    }
    if (!_personSafetyConfirmationOpen && canAct()) {
      unawaited(
        _confirmJourneyPersonSafety(person, hide: hide, canAct: canAct),
      );
    }
    return true;
  }

  Future<void> _confirmJourneyPersonSafety(
    DraftProfile person, {
    required bool hide,
    required bool Function() canAct,
  }) async {
    var expectedStamp = _devRouteStamp;
    final fresh = _accountFreshGuard(
      expectedNavigatorStamp: () => expectedStamp,
    );
    final attempt = _model.attemptRevisionFor(person.id);
    final safetyRevision = _model.personSafetyRevision;
    final sourcePersonId = _personId;
    final sourceAccount = (
      ZyraAccountState.userId,
      ZyraAccountState.generation,
    );
    final sourceRevision = _uiRevision;
    final sourceControlsEpoch = _devControlsEpoch;
    bool current() =>
        fresh() &&
        _personId == sourcePersonId &&
        !_guardianRole &&
        !_devControlsVisible &&
        _model.canApplyPersonSafety(
          person.id,
          hide: hide,
          expectedAttemptRevision: attempt,
          expectedSafetyRevision: safetyRevision,
          endCurrentJourney: true,
        );
    if (!canAct() || !current() || _personSafetyConfirmationOpen) return;
    _personSafetyConfirmationOpen = true;
    int? sheetStamp;
    var consumed = false;
    try {
      final pending = showModalBottomSheet<bool>(
        context: _tapContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black38,
        builder: (sheetContext) {
          bool modalCurrent() =>
              sheetContext.mounted &&
              !consumed &&
              ModalRoute.of(sheetContext)?.isCurrent == true &&
              sheetStamp == _devRouteStamp &&
              (widget.canActInOwnedDialog?.call() ?? _allowed) &&
              sourceAccount ==
                  (ZyraAccountState.userId, ZyraAccountState.generation) &&
              sourceRevision == _uiRevision &&
              sourceControlsEpoch == _devControlsEpoch &&
              !_guardianRole &&
              !_devControlsVisible &&
              _personId == sourcePersonId &&
              _model.canApplyPersonSafety(
                person.id,
                hide: hide,
                expectedAttemptRevision: attempt,
                expectedSafetyRevision: safetyRevision,
                endCurrentJourney: true,
              );
          void choose(bool value) {
            if (consumed ||
                !sheetContext.mounted ||
                ModalRoute.of(sheetContext)?.isCurrent != true) {
              return;
            }
            final unchanged = modalCurrent();
            consumed = true;
            Navigator.of(sheetContext).pop(value && unchanged);
            // Only this sheet's own pop may advance the captured route stamp.
            expectedStamp = _devRouteStamp;
          }

          return ZyraTapFeedback(
            level: () => _accountSession.hapticLevel,
            canAct: modalCurrent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .90,
              ),
              child: ZyraDraftJourneyBlockHideSheet(
                firstName: person.firstName,
                hide: hide,
                onKeep: () => choose(false),
                onConfirm: () => choose(true),
              ),
            ),
          );
        },
      );
      // Capture synchronously after our push, before any unrelated navigation
      // can be mistaken for this owned modal's first presentation.
      sheetStamp = _devRouteStamp;
      final confirmed = await pending;
      if (confirmed != true || !current()) return;
      // The model validates the complete transaction again before either
      // mutation. No asynchronous work separates ending from hide/block.
      _move(() {
        if (!_model.applyPersonSafety(
          person.id,
          hide: hide,
          expectedAttemptRevision: attempt,
          expectedSafetyRevision: safetyRevision,
          endCurrentJourney: true,
        )) {
          return;
        }
        _pages.clear();
        _personId = null;
        _tab = 1;
        _journeyTabIndex = 0;
        _notice = hide
            ? "Your Journey with ${person.firstName} has ended. ${person.firstName} won't appear again."
            : 'Your Journey with ${person.firstName} has ended and ${person.firstName} is blocked.';
      });
    } finally {
      _personSafetyConfirmationOpen = false;
    }
  }

  Widget _safety() {
    final person = _person;
    final canSelect = _accountFreshGuard();
    VoidCallback? localAction(bool hide) => person == null
        ? null
        : _bound(() {
            if (!canSelect() || _personId != person.id) return;
            if (_warnBeforePersonSafety(
              person,
              hide: hide,
              canAct: () => canSelect() && _personId == person.id,
            )) {
              return;
            }
            _move(() {
              final changed = hide
                  ? _model.hide(person.id)
                  : _model.block(person.id);
              if (!changed) return;
              _pages.clear();
              _tab = 0;
              _personId = null;
              _browseIndex = 0;
              _notice = null;
            });
          });
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: ZyraDraftReportPresentation(
          key: ValueKey(('draft_report', person?.id, _guardianRole)),
          ownerIdentity: (
            ZyraAccountState.userId,
            ZyraAccountState.generation,
            _guardianRole,
          ),
          profile: person == null ? null : _displayProfile(person),
          canSelect: canSelect,
          onHide: localAction(true),
          onBlock: localAction(false),
        ),
      ),
    );
  }

  void _showJourneyCount(int count, {int tab = 1}) => _move(() {
    if (!_model.seedJourneys(count)) return;
    _myZyraConsumedFocusTokens.clear();
    _myZyraFocusIndex = 0;
    _messages.clear();
    _message.clear();
    _conceptGuardianHistory.clear();
    _conceptRemovedGuardians.clear();
    _conceptMainGuardianId = 'draft-guardian-hassan';
    _shareHistory = false;
    _guardianJourneyId = null;
    _personId = null;
    _expansion.collapseAll();
    _guardianPage = 0;
    _guardianRole = false;
    _tab = tab;
    _pages.clear();
    widget.onRoleChanged?.call(false);
  });

  void _sampleSeekerMembership(bool basic) => _act(() {
    if (!_model.setCapacity(basic ? 1 : 3)) {
      _notice =
          'Choose the 1 Journey sample first. Existing sample Journeys have not been removed.';
      return;
    }
    _seekerMembership = basic ? 'Seeker Basic' : 'Seeker One';
    _subscriptionWallet = _subscriptionWallet.withRole(
      ZyraWalletRole.seeker,
      coverage: basic
          ? ZyraWalletCoverage.basic
          : ZyraWalletCoverage.individualOne,
    );
  });

  Widget _controls() {
    final sourcePage = _pageOptionsSource;
    final mainPage = sourcePage == null;
    final browse = mainPage && !_guardianRole && _tab == 0;
    final journey = mainPage && !_guardianRole && _tab == 1;
    final myZyra =
        !_guardianRole &&
        ((mainPage && _tab == 2) ||
            sourcePage == 'ended' ||
            sourcePage == 'past_journeys');
    final guardian = mainPage && !_guardianRole && _tab == 3;
    final profile = mainPage && _tab == 4;
    final activityChoices = <ZyraMyZyraActivityExample?, VoidCallback>{
      if (_activityRoot)
        for (final example in <ZyraMyZyraActivityExample?>[
          null,
          ...ZyraMyZyraActivityExample.values,
        ])
          example: _activityAction(
            () => _selectActivityExample(example),
            controls: true,
          ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Page options', size: 18),
        const SizedBox(height: 8),
        Text(
          _pageOptionsTitle,
          key: const ValueKey('concept_page_options_context'),
          style: ZyraText.heading(size: 15),
        ),
        const SizedBox(height: 14),
        if (_hasCircleDiscussionOptions) ...[
          _controlSection([
            _title('Floating bubble action', size: 13),
            _circleAppearancePicker(
              keyName: 'concept_circle_bubble_design',
              selected: _circleBubbleDesign,
              values: ZyraCircleBubbleDesign.values,
              label: (design) => design.label,
            ),
          ]),
          const SizedBox(height: 12),
        ],
        if (sourcePage == 'timeline' && _canViewTimeline(_personId)) ...[
          _timelineControls(),
          const SizedBox(height: 12),
        ],
        if (sourcePage == 'journey' &&
            _person != null &&
            _canAddressJourneyDisclosure(_personId) &&
            _model.isBioStepOpen(_personId!)) ...[
          _controlSection([
            _title('Journey Bio', size: 13),
            _button(
              'draft_peer_bio_reveal_$_personId',
              '${_person!.firstName}: share Bio',
              !_model.peerHasChosenBioReveal(_personId!)
                  ? _bioStepAction(
                      _person!,
                      () => _model.simulatePeerBioReveal(_personId!),
                    )
                  : null,
            ),
            _button(
              'draft_peer_bio_ready_$_personId',
              '${_person!.firstName}: ready to continue',
              _model.canPeerChooseBioContinue(_personId!)
                  ? _bioStepAction(
                      _person!,
                      () => _model.simulatePeerBioContinue(_personId!),
                    )
                  : null,
            ),
          ]),
          const SizedBox(height: 12),
        ],
        if (!_guardianRole && (browse || sourcePage == 'compatibility')) ...[
          _controlSection([
            _title('Compatibility Unlock', size: 13),
            _compatibilityCreditChoices(),
          ]),
          const SizedBox(height: 12),
        ],
        if (browse) ...[
          const SizedBox(height: 12),
          _controlSection([
            _title('Next animation', size: 13),
            _nextMotionPicker(),
          ]),
        ],
        if (journey) ...[
          const SizedBox(height: 12),
          _controlSection([
            _title('Journey preview', size: 13),
            Row(
              children: [
                for (final count in [1, 2, 3]) ...[
                  if (count > 1) const SizedBox(width: 8),
                  Expanded(
                    child: _previewAction(
                      'concept_journey_preview_$count',
                      '$count',
                      count <= _model.capacity
                          ? () => _showJourneyCount(count)
                          : null,
                      showChevron: false,
                      centered: true,
                      semanticLabel:
                          'Show $count sample ${count == 1 ? 'Journey' : 'Journeys'}',
                    ),
                  ),
                ],
              ],
            ),
          ]),
        ],
        if (profile) ...[
          const SizedBox(height: 12),
          _controlSection([
            _title('Switch account', size: 13),
            _previewAction(
              'concept_switch_ready',
              'Other profile ready',
              () => _act(() {
                _subscriptionWallet = _subscriptionWallet.withRole(
                  _walletRole.other,
                  readiness: ZyraWalletReadiness.ready,
                );
              }),
              selected:
                  _subscriptionWallet.forRole(_walletRole.other).readiness ==
                  ZyraWalletReadiness.ready,
              icon: Icons.swap_horiz_rounded,
            ),
            _previewAction(
              'concept_switch_needs_signup',
              'Needs sign-up',
              () => _act(() {
                _subscriptionWallet = _subscriptionWallet.withRole(
                  _walletRole.other,
                  readiness: ZyraWalletReadiness.missing,
                );
              }),
              selected:
                  _subscriptionWallet.forRole(_walletRole.other).readiness ==
                  ZyraWalletReadiness.missing,
              icon: Icons.person_add_alt_1_outlined,
            ),
            Text(
              'Close these controls, then tap Switch on your Profile.',
              style: ZyraText.subtext(size: 11.5),
            ),
            const SizedBox(height: 12),
            _title('Other role coverage · local examples', size: 13),
            for (final coverage in [
              ZyraWalletCoverage.individualOne,
              ZyraWalletCoverage.assignedFamily,
              ZyraWalletCoverage.basic,
              ZyraWalletCoverage.none,
              ZyraWalletCoverage.unavailable,
            ])
              _previewAction(
                'concept_wallet_coverage_${coverage.name}',
                switch (coverage) {
                  ZyraWalletCoverage.individualOne =>
                    'Already covered individually',
                  ZyraWalletCoverage.assignedFamily =>
                    'Already covered by Family',
                  ZyraWalletCoverage.basic => 'Basic access confirmed',
                  ZyraWalletCoverage.none => 'No membership or spare place',
                  ZyraWalletCoverage.unavailable => 'Coverage unavailable',
                },
                () => _act(() {
                  final target = _walletRole.other;
                  _subscriptionWallet = _subscriptionWallet
                      .withRole(target, coverage: coverage)
                      .copyWith(
                        places: _subscriptionWallet.places.where(
                          (place) =>
                              place.role != target ||
                              place.state != ZyraWalletPlaceState.available,
                        ),
                      );
                }),
              ),
            _previewAction(
              'concept_wallet_spare_place',
              'Available Family place for the other role',
              () => _act(() {
                _subscriptionWallet = _subscriptionWallet
                    .withRole(
                      _walletRole.other,
                      coverage: ZyraWalletCoverage.none,
                    )
                    .copyWith(
                      places: ZyraSubscriptionWalletDraft.sample().places,
                      inventoryAvailable: true,
                    );
              }),
            ),
            Text(
              'Fictional places only. No payment, account or invitation changes.',
              style: ZyraText.subtext(size: 11.5),
            ),
          ]),
        ],
        if (sourcePage == 'membership') ...[
          const SizedBox(height: 12),
          _controlSection([
            _title('Membership payment history', size: 13),
            for (final history in [
              ZyraMembershipPaymentHistory.paidBefore,
              ZyraMembershipPaymentHistory.neverPaid,
              ZyraMembershipPaymentHistory.unknown,
            ])
              _previewAction(
                'concept_membership_history_${history.name}',
                switch (history) {
                  ZyraMembershipPaymentHistory.paidBefore =>
                    'Previously paid for membership',
                  ZyraMembershipPaymentHistory.neverPaid =>
                    'Never paid for membership',
                  ZyraMembershipPaymentHistory.unknown =>
                    'Payment history unavailable',
                },
                () => _act(() {
                  _membershipPaymentHistory = history;
                  // A different sample history invalidates the old fee quote.
                  _membershipDraft = _membershipDraft.copyWith(
                    selectedProducts: _membershipDraft.selectedProducts.where(
                      (product) => !ZyraMembershipCatalog.isBasic(product),
                    ),
                  );
                  _membershipReview = null;
                }),
                selected: _membershipPaymentHistory == history,
              ),
            Text(
              'Sample records only. Selecting a plan never proves payment.',
              style: ZyraText.subtext(size: 11.5),
            ),
          ]),
        ],
        if (profile && !_guardianRole) ...[
          const SizedBox(height: 12),
          _controlSection([
            _title('Sample membership', size: 13),
            _previewAction(
              'draft_membership_seeker_basic',
              'Basic · 1 place',
              () => _sampleSeekerMembership(true),
              selected: _model.capacity == 1,
              icon: Icons.person_outline,
            ),
            _previewAction(
              'draft_membership_seeker_one',
              'Monthly · 3 places',
              () => _sampleSeekerMembership(false),
              selected: _model.capacity == 3,
              icon: Icons.workspace_premium_outlined,
            ),
          ]),
        ],
        if (guardian) ...[
          const SizedBox(height: 12),
          _controlSection([
            for (final guardian in draftGuardians) ...[
              if (guardian != draftGuardians.first) const SizedBox(height: 8),
              _choices(
                ['${guardian.firstName}: Basic', '${guardian.firstName}: One'],
                _model.sampleGuardianMembershipFor(guardian.id) ==
                        DraftGuardianMembership.basic
                    ? 0
                    : 1,
                (index) {
                  _model.setSampleGuardianMembership(
                    guardian.id,
                    index == 0
                        ? DraftGuardianMembership.basic
                        : DraftGuardianMembership.one,
                  );
                  if (guardian.id == 'draft-guardian-hassan') {
                    _guardianMembership = index == 0
                        ? 'Guardian Basic'
                        : 'Guardian One';
                    _subscriptionWallet = _subscriptionWallet.withRole(
                      ZyraWalletRole.guardian,
                      coverage: index == 0
                          ? ZyraWalletCoverage.basic
                          : ZyraWalletCoverage.individualOne,
                    );
                  }
                },
                'concept_guardian_plan_${guardian.id}',
              ),
            ],
          ]),
        ],
        if (!_guardianRole && sourcePage == 'requests') ...[
          const SizedBox(height: 12),
          _controlSection([
            _choices(
              const ['Received', 'Sent', 'Past'],
              _requestsTab,
              (index) => _requestsTab = index,
              'concept_requests_controls',
            ),
          ]),
        ],
        if (_activityRoot) ...[
          const SizedBox(height: 12),
          _controlSection([
            _previewAction(
              'concept_activity_checklist',
              'Activity checklist',
              _activityAction(
                () => _act(() {
                  _activityChecklistExpanded = !_activityChecklistExpanded;
                }),
                controls: true,
              ),
              selected: _activityChecklistExpanded,
              icon: Icons.fact_check_outlined,
            ),
            if (_activityChecklistExpanded) ...[
              const SizedBox(height: 12),
              ZyraMyZyraActivityChecklist(
                selected: _activityExample,
                reviewed: Set.unmodifiable(_reviewedActivityExamples),
                onSelected: (example) => activityChoices[example]?.call(),
              ),
            ],
          ]),
        ],
        if (myZyra) ...[
          const SizedBox(height: 12),
          _controlSection([
            _previewAction(
              'draft_history',
              'Add Ended history',
              () => _act(() {
                _model.seedHistory();
              }),
              icon: Icons.history,
            ),
          ]),
        ],
        const SizedBox(height: 12),
        _controlSection([
          _previewAction(
            'draft_reset',
            'Reset preview',
            () => _move(() {
              _clearActivityRehearsal();
              _paidGuardianAgreement = null;
              _model.setCapacity(3);
              _model.reset();
              _seenBrowseProfileIds.clear();
              _browseHistory.reset();
              _messages.clear();
              _message.clear();
              _conceptNetworkSent.clear();
              _conceptGuardianHistory.clear();
              _conceptRemovedGuardians.clear();
              _conceptMainGuardianId = 'draft-guardian-hassan';
              _shareHistory = false;
              _gold = _accountSession.goldEnabled;
              _browseFilter = const ZyraBrowseFilter();
              _editingBrowseFilter = _browseFilter;
              _seekerMembership = 'Seeker One';
              _guardianMembership = 'Guardian One';
              _requestsTab = 0;
              _membershipDraft = ZyraMembershipDraft();
              _membershipReview = null;
              _subscriptionWallet = ZyraSubscriptionWalletDraft.sample(
                ownerId: _subscriptionWallet.ownerId,
              );
              _walletSetupRole = null;
              _compatibilityAccess.reset();
              _compatibilityRoute = null;
              _circleBubbleDesign.value = ZyraCircleBubbleDesign.current;
              _accountDestination = null;
              _settingsDetail = null;
              _membershipPaymentHistory =
                  ZyraMembershipPaymentHistory.paidBefore;
              _expansion.collapseAll();
              _guardianPage = _networkTab = 0;
              _browseIndex = 1;
              _personId = null;
              _guardianJourneyId = null;
              _guardianRole = false;
              _tab = 0;
              _pages.clear();
              widget.onRoleChanged?.call(false);
            }),
            icon: Icons.restart_alt,
          ),
        ]),
        const SizedBox(height: 12),
        _controlSection([
          _title('Account preview', size: 13),
          _previewAction(
            'draft_role_guardian',
            'Guardian',
            () => _switchRole(true),
            selected: _guardianRole,
            icon: Icons.gpp_good_outlined,
          ),
          _previewAction(
            'draft_role_seeker',
            'Seeker',
            () => _switchRole(false),
            selected: !_guardianRole,
            icon: Icons.person_outline,
          ),
        ]),
      ],
    );
  }

  Widget _timelineControls() {
    final person = _person!;
    final preview = _timelinePreview ??= _makeTimelinePreview(person);
    final fresh = _controlsFreshGuard();
    final revision = _uiRevision;
    bool current() =>
        fresh() &&
        _uiRevision == revision &&
        _devControlsVisible &&
        _pageOptionsSource == 'timeline' &&
        _personId == person.id &&
        preview.subjectId == person.id &&
        identical(preview, _timelinePreview) &&
        _canViewTimeline(person.id);
    void select(VoidCallback change) {
      if (!current()) return;

      _act(change);
    }

    return _controlSection([
      _title('Timeline examples', size: 13),
      _timelinePicker<ZyraDraftTimelineScenario>(
        'scenario',
        preview.scenario,
        [
          for (final scenario in ZyraDraftTimelineScenario.values)
            (scenario, scenario.label),
        ],
        (value) => select(() {
          preview.selectScenario(value);
        }),
      ),
      const SizedBox(height: 12),
      _title('Individual event', size: 13),
      _timelinePicker<String>(
        'event',
        preview.selectedEvent,
        [
          for (final type in ZyraDraftTimelinePreview.supportedEvents)
            (type, ZyraTimelineMilestones.labelFor(type)),
        ],
        (value) => select(() {
          preview.selectEvent(value);
        }),
      ),
      const SizedBox(height: 12),
      _title('Stage and road ahead', size: 13),
      _timelinePicker<String>(
        'stage',
        preview.selectedStage,
        [for (final stage in ZyraJourneyStages.all) (stage.value, stage.label)],
        (value) => select(() {
          preview.selectStage(value);
        }),
      ),
    ]);
  }

  Widget _timelinePicker<T extends Object>(
    String kind,
    T value,
    List<(T, String)> choices,
    ValueChanged<T> onChanged,
  ) => DropdownButtonFormField<T>(
    key: ValueKey(('concept_timeline_${kind}_dropdown', value)),
    initialValue: value,
    isExpanded: true,
    menuMaxHeight: 320,
    dropdownColor: ZyraColors.modalSheetSurface,
    icon: Icon(Icons.expand_more, color: ZyraColors.unlockText, size: 20),
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: ZyraColors.surfaceFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ZyraColors.surfaceBorder, width: .6),
      ),
    ),
    items: [
      for (final choice in choices)
        DropdownMenuItem<T>(
          key: ValueKey('concept_timeline_${kind}_${choice.$1}'),
          value: choice.$1,
          child: Text(choice.$2, style: ZyraText.body(size: 13)),
        ),
    ],
    onChanged: _tapChange((choice) {
      if (choice != null) onChanged(choice);
    }),
  );

  Widget _circleAppearancePicker<T extends Enum>({
    required String keyName,
    required ValueNotifier<T> selected,
    required List<T> values,
    required String Function(T) label,
  }) {
    final fresh = _controlsFreshGuard();
    final sourcePage = _pageOptionsSource;
    final guardianRole = _guardianRole;
    final sourceTab = _tab;
    return DropdownButtonFormField<T>(
      key: ValueKey((keyName, selected.value)),
      initialValue: selected.value,
      isExpanded: true,
      menuMaxHeight: 320,
      dropdownColor: ZyraColors.modalSheetSurface,
      icon: Icon(Icons.expand_more, color: ZyraColors.unlockText, size: 20),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: ZyraColors.surfaceFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ZyraColors.surfaceBorder, width: .6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ZyraColors.unlockText, width: .8),
        ),
      ),
      items: [
        for (final style in values)
          DropdownMenuItem(
            key: ValueKey('${keyName}_${style.name}'),
            value: style,
            child: Text(label(style), style: ZyraText.body(size: 13)),
          ),
      ],
      onChanged: _tapChange((style) {
        if (style == null ||
            !fresh() ||
            !_hasCircleDiscussionOptions ||
            _pageOptionsSource != sourcePage ||
            _guardianRole != guardianRole ||
            _tab != sourceTab) {
          return;
        }

        _act(
          () => selected.value = style,
          preserveCircle: sourcePage == 'guardian_circle',
        );
      }),
    );
  }

  Widget _nextMotionPicker() {
    final fresh = _controlsFreshGuard();
    return DropdownButtonFormField<ZyraBrowseNextMotion>(
      key: ValueKey(('concept_next_motion_dropdown', _browseNextMotion)),
      initialValue: _browseNextMotion,
      isExpanded: true,
      menuMaxHeight: 320,
      dropdownColor: ZyraColors.modalSheetSurface,
      icon: Icon(Icons.expand_more, color: ZyraColors.unlockText, size: 20),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: ZyraColors.surfaceFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ZyraColors.surfaceBorder, width: .6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ZyraColors.unlockText, width: .8),
        ),
      ),
      items: [
        for (final motion in ZyraBrowseNextMotion.values)
          DropdownMenuItem(
            key: ValueKey('concept_browse_next_motion_${motion.name}'),
            value: motion,
            child: Text(motion.label, style: ZyraText.body(size: 13)),
          ),
      ],
      onChanged: _tapChange((motion) {
        if (motion != null && fresh()) {
          _act(() => _browseNextMotion = motion);
        }
      }),
    );
  }

  Widget _unavailable() => _card([
    _title('Nothing to open here.', size: 23),
    _button('concept_return_connections', 'Go to Journey', () => _tabTo(1)),
  ]);
  Widget _mainHeading(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Align(
      alignment: Alignment.topLeft,
      child: Text(
        title,
        key: ValueKey('concept_main_title_$title'),
        style: ZyraText.pageTitle(),
        textAlign: TextAlign.left,
      ),
    ),
  );
  Widget _heading(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(title, size: 26),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          _body(description, small: true),
        ],
      ],
    ),
  );
  Widget _eyebrow(String label) => Text(
    label,
    style: ZyraText.chapterLabel(
      color: ZyraColors.foregroundMuted.withValues(alpha: .7),
    ),
  );
  Widget _title(String text, {double size = 24}) =>
      Text(text, style: ZyraText.heading(size: size));
  Widget _body(String text, {bool small = false, bool gold = false}) => Text(
    text,
    style: ZyraText.body(
      size: small ? 12 : 15,
      color: gold ? ZyraColors.goldText : ZyraColors.foregroundMuted,
    ),
  );
  Widget _controlSection(List<Widget> children) => ZyraDevToolSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ],
    ),
  );
  // Developer controls use compact current-theme rows. Member-facing actions
  // continue to use _button below; this never changes their size or behavior.
  Widget _previewAction(
    String id,
    String label,
    VoidCallback? action, {
    bool? selected,
    IconData? icon,
    bool showChevron = true,
    bool centered = false,
    String? semanticLabel,
  }) {
    final enabled = action != null;
    final color = enabled
        ? ZyraColors.foreground
        : ZyraColors.foregroundMuted.withValues(alpha: .5);
    return Semantics(
      selected: selected,
      child: ZyraFloatingSurface(
        radius: 9,
        circle: false,
        gold: false,
        child: OutlinedButton(
          key: ValueKey(id),
          onPressed: _tap(enabled ? _bound(action) : null),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            foregroundColor: color,
            backgroundColor: selected == true
                ? ZyraColors.surfaceEmphasisFill
                : Colors.transparent,
            side: BorderSide(
              color: selected == true
                  ? ZyraColors.surfaceEmphasisBorder
                  : ZyraColors.surfaceBorder,
              width: selected == true ? 1 : .6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: color.withValues(alpha: .65)),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  label,
                  semanticsLabel: semanticLabel,
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: ZyraText.body(size: 12.5, color: color),
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 17,
                  color: color.withValues(alpha: .4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageScroll(List<Widget> children, {Key? key}) => SafeArea(
    key: key,
    child: ZyraShadowScrollView(
      key: const ValueKey('draft_scroll'),
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );

  Widget _card(List<Widget> children) => ZyraFloatingSurface(
    radius: ZyraCardMetrics.cardRadius,
    circle: false,
    gold: false,
    child: Container(
      padding: EdgeInsets.all(ZyraCardMetrics.padding),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 13),
            children[i],
          ],
        ],
      ),
    ),
  );
  Widget _button(
    String id,
    String label,
    VoidCallback? action, {
    bool primary = false,
    IconData? icon,
    bool alignStart = false,
    bool fitLabel = false,
  }) => ZyraFloatingSurface(
    radius: 999,
    circle: false,
    gold: false,
    child: OutlinedButton(
      key: ValueKey(id),
      onPressed: _tap(action == null ? null : _bound(action)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        foregroundColor: ZyraColors.foreground,
        disabledForegroundColor: ZyraColors.foregroundMuted.withValues(
          alpha: .5,
        ),
        backgroundColor: primary
            ? ZyraColors.surfaceEmphasisFill
            : ZyraColors.surfaceFill,
        side: BorderSide(
          color: primary
              ? ZyraColors.surfaceEmphasisBorder
              : ZyraColors.surfaceBorder,
        ),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: alignStart ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: alignStart
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: fitLabel
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: ZyraText.button(
                        size: 14,
                        color: action == null
                            ? ZyraColors.foregroundMuted.withValues(alpha: .5)
                            : ZyraColors.foreground,
                      ),
                    ),
                  )
                : label.contains('\n')
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.split('\n').first,
                        style: ZyraText.button(
                          size: 14,
                          color: ZyraColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label.substring(label.indexOf('\n') + 1),
                        style: ZyraText.subtext(size: 12),
                      ),
                    ],
                  )
                : Text(
                    label,
                    textAlign: alignStart ? TextAlign.start : TextAlign.center,
                    style: ZyraText.button(
                      size: 14,
                      color: action == null
                          ? ZyraColors.foregroundMuted.withValues(alpha: .5)
                          : ZyraColors.foreground,
                    ),
                  ),
          ),
          if (alignStart) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ],
      ),
    ),
  );
  Widget _choices(
    List<String> labels,
    int selected,
    ValueChanged<int> change,
    String id,
  ) {
    final callbacks = [
      for (var i = 0; i < labels.length; i++)
        _bound(() => _act(() => change(i))),
    ];
    return labels.length <= 4
        ? TweenAnimationBuilder<double>(
            tween: Tween<double>(end: selected.toDouble()),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : ZyraSegmentedMotion.selectionDuration,
            curve: ZyraSegmentedMotion.selectionCurve,
            builder: (context, position, _) => ZyraSegmentedToggle(
              labels: labels,
              position: position,
              labelSize: labels.length == 2 ? 13 : 11.5,
              segmentKeys: [
                for (var i = 0; i < labels.length; i++) ValueKey('${id}_$i'),
              ],
              onChanged: (i) {
                if (i >= 0 && i < callbacks.length) callbacks[i]();
              },
            ),
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < labels.length; i++)
                Semantics(
                  selected: selected == i,
                  child: _button(
                    '${id}_$i',
                    labels[i],
                    () => _act(() => change(i)),
                    primary: selected == i,
                  ),
                ),
            ],
          );
  }

  String _stateLabel(DraftJourneyState state) => switch (state) {
    DraftJourneyState.received => 'Received request',
    DraftJourneyState.sent => 'Request sent',
    DraftJourneyState.acceptedWaiting => 'Accepted · waiting for confirmation',
    DraftJourneyState.preparing => 'Preparing together · place reserved',
    DraftJourneyState.active => 'Active Journey',
    DraftJourneyState.ended => 'Ended Journey · history retained',
  };
}

/// Touch ends the opening cue before the bar begins its existing breathing
/// interaction. The Listener observes only child hits and owns no gesture.
class _BrowseOptionsNavigationCue extends StatefulWidget {
  const _BrowseOptionsNavigationCue({super.key, required this.navigation});

  final Widget navigation;

  @override
  State<_BrowseOptionsNavigationCue> createState() =>
      _BrowseOptionsNavigationCueState();
}

class _BrowseOptionsNavigationCueState
    extends State<_BrowseOptionsNavigationCue> {
  bool _cueVisible = true;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.deferToChild,
    onPointerDown: (_) {
      if (_cueVisible) setState(() => _cueVisible = false);
    },
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.navigation,
        if (_cueVisible) const _BrowseOptionsBarCue(),
      ],
    ),
  );
}

/// A single, decorative opening cue on Browse's edge-aligned action-navigation
/// pill. Quiet-motion modes show a stable subtle gold edge instead of a pulse.
class _BrowseOptionsBarCue extends StatelessWidget {
  const _BrowseOptionsBarCue();

  @override
  Widget build(BuildContext context) {
    final quiet =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    Widget decoration(double strength) => DecoratedBox(
      key: const ValueKey('concept_browse_options_cue'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ZyraNavBarMetrics.radius),
        border: Border.all(
          color: ZyraColors.journeyGold.withValues(alpha: .58 * strength),
          width: 1.5,
        ),
        color: ZyraColors.journeyGold.withValues(alpha: .06 * strength),
        boxShadow: quiet
            ? const []
            : [
                BoxShadow(
                  color: ZyraColors.journeyGold.withValues(
                    alpha: .18 * strength,
                  ),
                  blurRadius: 10,
                ),
              ],
      ),
      child: const SizedBox.expand(),
    );
    return Positioned(
      left: 20,
      right: 20,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: ZyraNavBarMetrics.bottomInset),
        child: SizedBox(
          height: ZyraNavBarMetrics.restingHeight,
          child: IgnorePointer(
            child: ExcludeSemantics(
              // The quiet branch disposes an in-flight pulse immediately.
              child: quiet
                  ? decoration(.5)
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 850),
                      builder: (context, value, child) {
                        final strength = value <= .25
                            ? Curves.easeOutCubic.transform(value / .25)
                            : 1 -
                                  Curves.easeInOut.transform(
                                    (value - .25) / .75,
                                  );
                        return decoration(strength);
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// The existing Guardian page's horizontal presentation, with an owned local
// controller. Revisiting a page restores the local selection; reset starts at
// the first Guardian without reusing a stale PageStorage offset.
