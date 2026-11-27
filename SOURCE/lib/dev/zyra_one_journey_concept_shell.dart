import '../widgets/zyra_floating_surface.dart';
// Disposable methodology comparison using the current app's presentation.
// No production routes/services are called, no member records are loaded,
// and only device-local education receipts are persisted (LOCK 3 / LOCK 36).
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'zyra_developer_focus_presets.dart';
import 'zyra_full_profile_preview.dart';
import 'zyra_limits_preview.dart';
import 'zyra_pause_private_preview.dart';
import 'zyra_pause_private_preview_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        SystemUiOverlayStyle,
        MissingPluginException,
        PlatformException,
        rootBundle,
        Clipboard,
        ClipboardData;

import '../data/zyra_journey_stages.dart';
import '../data/zyra_seeker_basic_policy.dart';
import '../data/zyra_seeker_plan_limits.dart';
import '../data/zyra_journey_guardian_selection.dart';
import '../data/journey_questions.dart';
import '../data/zyra_reference_data.dart';
import '../data/zyra_journey_pause_state.dart';
import '../models/seeker_profile.dart';
import '../services/zyra_wali_link_service.dart' show WaliLinkedPerson;
import '../services/zyra_wali_journey_service.dart' show WaliJourneyView;
import '../services/zyra_family_messaging_service.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_app_lock.dart';
import '../services/zyra_local_prefs.dart';
import '../services/zyra_profile_video_service.dart';
import '../services/zyra_guardian_info_service.dart' show GuardianInfo;
import '../screens/wali/family_messaging_screens.dart';
import '../screens/wali/link_guardian_panel.dart';
import '../screens/wali/zyra_code_screen.dart' show ZyraCodeLocalPreview;
import '../screens/settings/help_support_screen.dart';
import '../screens/onboarding/identity_verification_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/onboarding/bio_onboarding_flow.dart';
import '../models/journey_bio.dart';
import '../widgets/zyra_edit_profile_presentation.dart';
import '../screens/profile/compatibility_editors.dart';
import 'zyra_one_journey_filters_presentation.dart';
import 'zyra_one_journey_location.dart';
import 'zyra_one_journey_location_sheet.dart';
import '../screens/profile/edit_photos_screen.dart';
import '../screens/profile/my_profile_preview_screen.dart';
import '../theme/zyra_card_metrics.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_preview_spacing.dart';
import '../theme/zyra_text.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/zyra_browse_options_button.dart';
import '../widgets/zyra_browse_next_photo_motion.dart';
import '../widgets/zyra_guardian_dashboard_profile_card.dart';
import '../widgets/zyra_loading.dart';
import '../widgets/zyra_full_screen_profile_gallery.dart';
import '../widgets/zyra_profile_video_player.dart';
import '../widgets/zyra_tab_title.dart';
import '../widgets/zyra_developer_title.dart';
import '../state/zyra_developer_samples.dart';
import '../models/zyra_developer_preview.dart';
import '../models/zyra_error_state.dart';
import '../widgets/zyra_full_screen_error.dart';
import '../screens/connections/zyra_sample_activity.dart';
import 'zyra_developer_inactivity_email.dart';
import 'zyra_signup_preview.dart';
import 'zyra_signup_preview_controller.dart';
import 'zyra_signup_preferences_preview.dart';
import 'zyra_first_tour_overlay.dart';
import 'zyra_first_tour_steps.dart';
import 'zyra_first_tour_store.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/zyra_tap_feedback.dart';
import '../widgets/zyra_confirm_sheet.dart';
import '../widgets/zyra_shell_navigation.dart';
import '../widgets/zyra_segmented_toggle.dart';
import '../widgets/zyra_focus_dashboard.dart';
import 'zyra_my_zyra_focus.dart';
import '../widgets/zyra_pull_down_back_scope.dart';
import '../widgets/zyra_state_widgets.dart';
import '../widgets/searchable_list_picker.dart';
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
import 'zyra_compatibility_demo.dart';
import 'zyra_draft_compatibility_score_designs.dart';
import 'zyra_draft_compatibility_store_presentation.dart';
import 'zyra_draft_browse_utility_presentation.dart';
import 'zyra_help_safety_preview.dart';
import 'zyra_profile_small_pages_preview.dart';
import 'zyra_privacy_security_preview.dart';
import 'zyra_email_settings_preview.dart';
import 'zyra_draft_safety_advice_presentation.dart';
import 'zyra_draft_code_entry.dart';
import '../data/help_content.dart';
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
import 'zyra_one_journey_options.dart';
import 'zyra_one_journey_options_page.dart';
import 'zyra_one_journey_tab.dart';
import 'zyra_one_journey_guardian_tabs.dart';
import 'zyra_one_journey_guardian_cards.dart';
import 'zyra_one_journey_guardian_action.dart';
import 'zyra_one_journey_guardian_family_sheet.dart';
import 'zyra_guardian_family_preview.dart';
import 'zyra_journey_peer_guardians_presentation.dart';
import 'zyra_one_journey_account_presentation.dart';
import 'zyra_membership_preview.dart';
import 'zyra_offers_preview.dart';
import '../models/zyra_offers_preview.dart';
import 'zyra_one_journey_guardian_info_presentation.dart';
import 'zyra_one_journey_switch_signup_preview.dart';
import 'zyra_subscription_wallet_draft.dart';
import 'zyra_subscription_wallet_preview.dart';
import '../widgets/zyra_membership_choices.dart';
import '../widgets/zyra_seeker_avatar.dart';
import '../widgets/zyra_profile_details_page.dart';
import 'zyra_one_journey_settings_details.dart';
import 'zyra_one_journey_phone_access.dart';
import 'zyra_founder_launch_review.dart';
import 'zyra_one_journey_journey_presentation.dart';
import '../screens/connections/connections_section_controller.dart';
import 'zyra_dev_personal_code_fixtures.dart';
import '../theme/zyra_interaction_style.dart';
import '../data/zyra_membership_catalog.dart';
import '../screens/subscription/zyra_one_upgrade_page.dart';

typedef _GuardianCompatibilityTarget = ({
  String subjectId,
  int? activeRevision,
  String? archiveId,
});

/// Code-only sample inputs for captures and widget tests. The app supplies no
/// fixture and exposes no action for changing these values.
class ZyraOneJourneyShellFixture {
  const ZyraOneJourneyShellFixture({
    this.firstTourIndex,
    this.model,
    this.changes,
    this.wallet,
    this.membershipPaymentHistory = ZyraMembershipPaymentHistory.paidBefore,
    this.membershipRecords,
    this.offerChoices,
    this.activityExample,
    this.timeline,
    this.browseNextMotion = ZyraBrowseNextMotion.current,
    this.profileVideoLoader,
    this.circleBubbleDesign = ZyraCircleBubbleDesign.current,
    this.circleArrivalsFor,
    this.guardianTabs,
    this.readState,
    this.onAttached,
    this.onCaptureGuardAttached,
    this.onModelAttached,
    this.compatibilityAccess,
    this.onCompatibilityAccessAttached,
    this.onStateAttached,
    this.onCheckpoint,
    this.profileVideoStore,
    this.profileVideoMedia = const ZyraProfileVideoMedia(),
    this.legacyAmberQuickCheck = false,
    this.seekerPhotos,
    this.confirmSensitiveAction,
    this.profileSmallPageSample,
    this.seededWaitingRequests = 0,
    this.seededViewedProfiles = 0,
  });

  final ViewRequestDraftModel? model;
  // Code-only capture input; never supplied by the running app.
  final int? firstTourIndex;
  final ZyraProfileVideoLoader? profileVideoLoader;
  // The caller owns model mutation and notification; these never supply access.
  final Listenable? changes;
  final ZyraSubscriptionWalletDraft? wallet;
  final ZyraMembershipPaymentHistory membershipPaymentHistory;
  final Map<ZyraWalletRole, ZyraMembershipPreviewRecord?>? membershipRecords;
  final ZyraPreviewOfferChoices? offerChoices;
  final ZyraMyZyraActivityExample? activityExample;
  final ZyraDraftTimelinePreview Function(String subjectId)? timeline;
  final ZyraBrowseNextMotion browseNextMotion;
  final ZyraCircleBubbleDesign circleBubbleDesign;
  final ZyraCirclePreviewArrivals? circleArrivalsFor;
  final ZyraGuardianTabsSnapshot? guardianTabs;
  final ZyraOneJourneyShellFixtureState? Function()? readState;
  final void Function(bool Function() isCurrent)? onAttached;
  // Retained fixture callbacks use the same owner/page epoch as member actions.
  final ValueChanged<bool Function() Function()>? onCaptureGuardAttached;
  final ValueChanged<ViewRequestDraftModel>? onModelAttached;
  final ZyraDraftCompatibilityAccessStore? compatibilityAccess;
  final ValueChanged<ZyraDraftCompatibilityAccessStore>?
  onCompatibilityAccessAttached;
  final ValueChanged<ZyraOneJourneyShellFixtureState>? onStateAttached;
  final ValueChanged<ZyraPreviewNavigationCheckpoint>? onCheckpoint;
  final ZyraProfileVideoStore? profileVideoStore;
  final ZyraProfileVideoMedia profileVideoMedia;
  final bool legacyAmberQuickCheck;
  final List<String>? seekerPhotos;

  /// Test-only native-auth boundary; the running preview uses the OS prompt.
  final Future<bool> Function()? confirmSensitiveAction;
  final ZyraProfileSmallPageSample? profileSmallPageSample;
  // These stand in for other fictional history in test-owned policy state.
  final int seededWaitingRequests;
  final int seededViewedProfiles;
}

/// One caller-owned fixture update. No account or disclosure grant is carried.
class ZyraOneJourneyShellFixtureState {
  const ZyraOneJourneyShellFixtureState({
    this.guardianRole,
    this.tab,
    this.requestsTab,
    this.checkpoint,
    this.wallet,
    this.membershipPaymentHistory,
    this.seekerMembership,
    this.guardianMembership,
    this.activityExample,
    this.replaceActivity = false,
    this.browseNextMotion,
    this.circleBubbleDesign,
    this.timeline,
    this.replaceTimeline = false,
  });

  final bool? guardianRole;
  final int? tab, requestsTab;
  final ZyraPreviewNavigationCheckpoint? checkpoint;
  final ZyraSubscriptionWalletDraft? wallet;
  final ZyraMembershipPaymentHistory? membershipPaymentHistory;
  final String? seekerMembership, guardianMembership;
  final ZyraMyZyraActivityExample? activityExample;
  final bool replaceActivity;
  final ZyraBrowseNextMotion? browseNextMotion;
  final ZyraCircleBubbleDesign? circleBubbleDesign;
  final ZyraDraftTimelinePreview? timeline;
  final bool replaceTimeline;
}

class ZyraOneJourneyConceptShell extends StatefulWidget {
  const ZyraOneJourneyConceptShell({
    super.key,
    required this.canAct,
    required this.onExit,
    this.canActInOwnedDialog,
    this.onRoleChanged,
    this.onPresentationReady,
    this.initialGuardianRole = false,
    this.initialSeekerBasic = false,
    this.initialGuardianBasic = false,
    this.initialTab,
    this.initialCheckpoint,
    this.restoreLocation = true,
    this.onCheckpoint,
    this.localPhotoImport,
    this.compatibilityAccess,
    this.previewClock,
    this.fixture,
  });
  @visibleForTesting
  final ZyraOneJourneyShellFixture? fixture;
  final bool Function() canAct;
  // Owner admission without route focus, used only by an exact shell-owned modal.
  final bool Function()? canActInOwnedDialog;
  final VoidCallback onExit;
  final ValueChanged<bool>? onRoleChanged;
  // Presentation only; never publishes or retains access proof.
  final VoidCallback? onPresentationReady;
  final bool initialGuardianRole;
  final bool initialSeekerBasic;
  final bool initialGuardianBasic;
  final int? initialTab;
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

class _ZyraOneJourneyConceptShellState
    extends State<ZyraOneJourneyConceptShell> {
  late ViewRequestDraftModel _model;
  ZyraDeveloperPreviewBridge? _developerBridge;
  final _developerSamples = ZyraDeveloperSamples.instance;
  ViewRequestDraftSnapshot? _developerBaseline;
  ZyraPreviewNavigationCheckpoint? _developerCheckpointBaseline;
  Map<String, List<String>>? _developerMessagesBaseline;
  TextEditingValue? _developerMessageDraftBaseline;
  DateTime? _developerWelcomeBackBaseline;
  Object? _developerSelectionFingerprint;
  ZyraSubscriptionWalletDraft? _developerWalletBaseline;
  String? _developerSeekerBaseline, _developerGuardianBaseline;
  bool? _developerRoleBaseline;
  String _developerJourneySignature = '';
  final _developerStoreAttempts = <String, String>{};
  ZyraDeveloperViewAs? _developerLastView;
  int _developerNavigation = 0, _developerLastNotice = 0;
  int _developerNoticeEpoch = 0, _developerPresetEpoch = 0;
  int _developerEmailCount = 2;
  int _developerProfileSmallPageEpoch = 0;

  ZyraSignupPreviewController? _signup;
  ZyraSignupPreviewController? _addedRoleSignup;
  ZyraCompatibilityDraft? _signupPreferences;
  Widget? _signupSurface, _signupPreferenceSurface;
  Object? _signupLease;
  String? _signupPhoto;
  bool _signupPhotoLoading = false;
  bool _signupHasEntered = false;
  late final ZyraFirstTourStore _firstTourStore;
  final _firstTourViewport = GlobalKey();
  int? _firstTourIndex;
  bool _firstTourPending = false;
  ({int tab, List<String> pages, String? quickAccess, double offset})?
  _firstTourOrigin;

  bool get _firstTourCurrent =>
      _allowed &&
      _fixtureAccount ==
          (ZyraAccountState.userId, ZyraAccountState.generation) &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  Future<void> _firstSignupTour() async {
    final fresh = _accountFreshGuard();
    setState(() => _firstTourPending = true);
    try {
      final first = await _firstTourStore.claimFirstEntry();
      if (first && fresh()) _startFirstTour();
    } finally {
      if (mounted) setState(() => _firstTourPending = false);
    }
  }

  void _startFirstTour({int index = 0}) {
    if (!_firstTourCurrent || _firstTourIndex != null) return;
    _firstTourOrigin = (
      tab: _tab,
      pages: List.of(_pages),
      quickAccess: _myZyraQuickAccessPage,
      offset: _scroll.hasClients ? _scroll.offset : 0,
    );
    _showFirstTour(index);
  }

  void _showFirstTour(int index) {
    if (!_firstTourCurrent) return;
    final steps = _guardianRole ? zyraGuardianTourSteps : zyraSeekerTourSteps;
    if (index > steps.length + 1) {
      final origin = _firstTourOrigin;
      _move(() {
        _firstTourIndex = null;
        _firstTourOrigin = null;
        if (origin != null) {
          _tab = origin.tab;
          _pages
            ..clear()
            ..addAll(origin.pages);
          _myZyraQuickAccessPage = origin.quickAccess;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_firstTourCurrent && origin != null && _scroll.hasClients) {
          _scroll.jumpTo(
            origin.offset.clamp(0, _scroll.position.maxScrollExtent),
          );
        }
      });
      return;
    }
    _move(() {
      _firstTourIndex = index.clamp(0, steps.length + 1);
      _pages.clear();
      _myZyraQuickAccessPage = null;
      _notice = null;
      if (index > 0 && index <= steps.length) _tab = steps[index - 1].tab;
      _expansion.collapseAll();
    });
  }

  Rect? _firstTourRect(String target) {
    final viewport = _firstTourViewport.currentContext;
    final root = viewport?.findRenderObject();
    if (viewport == null || root is! RenderBox || !root.hasSize) return null;
    final keys = switch (target) {
      'tour_profiles_card' => {'concept_browse_portrait_card'},
      'tour_profiles_request' => {'draft_profile_${_browseHistory.currentId}'},
      'tour_guardian_actions' => {
        'guardian-family-messages-top',
        'guardian-add-top',
      },
      'tour_seekers_actions' => {'guardian_seekers_chat', 'guardian_invite'},
      _ => {target},
    };
    Rect? result;
    void visit(Element element) {
      if (element.widget case Offstage(offstage: true)) return;
      final key = element.widget.key;
      final value = key is ValueKey<String> ? key.value : null;
      final access =
          target == 'tour_guardian_access' &&
          value != null &&
          (value == 'guardian-card-journey-label' ||
              value.startsWith('guardian-card-tile-') ||
              value.startsWith('guardian-card-free-place-'));
      if (value != null && (keys.contains(value) || access)) {
        final box = element.findRenderObject();
        if (box is RenderBox &&
            box.attached &&
            box.hasSize &&
            !box.size.isEmpty) {
          final offset = box.localToGlobal(Offset.zero, ancestor: root);
          final rect = offset & box.size;
          final bounds = Offset.zero & root.size;
          if (bounds.contains(rect.center)) {
            final visible = rect.intersect(bounds);
            result = result?.expandToInclude(visible) ?? visible;
          }
        }
      }
      element.visitChildElements(visit);
    }

    (viewport as Element).visitChildElements(visit);
    return result;
  }

  double _firstTourBarTop() =>
      _firstTourRect('compact-nav-surface')?.top ??
      (MediaQuery.sizeOf(context).height -
          ZyraNavBarMetrics.contentBottomClearance(context) +
          ZyraNavBarMetrics.contentGap);
  bool get _signupUnverified => _hasDeveloperPreview
      ? _developerSamples.unverified
      : (_signup?.hasAccount == true && !_signup!.verified);
  bool get _signupIncomplete => _hasDeveloperPreview
      ? _developerSamples.setupUnfinished
      : (_signup?.hasAccount == true && !_signup!.setupComplete);

  bool get _signupProtectedPage => const {
    'profile',
    'guardian_linked_profile',
    'guardian_network_profile',
    'guardian_seeker',
    'network_request',
    'scan',
  }.contains(_page);

  bool get _hasDeveloperPreview =>
      _developerBridge?.canPresent == true &&
      _developerBridge?.viewAs != null &&
      _developerSamples.hasSamples;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bridge = ZyraDeveloperSeekerScope.bridgeOf(context);
    if (identical(bridge, _developerBridge)) return;
    _developerBridge?.detach(this);
    _developerBridge = bridge;
    bridge?.attach(
      owner: this,
      samplesChanged: _syncDeveloperSamples,
      canSendRequest: () => _profilePrivacy.canSendRequest,
      showError: _showDeveloperError,
      continueSetup: _resumeSignup,
      startSignup: _startSignup,
    );
  }

  Future<void> _startSignup() async {
    if (!_allowed || _developerBridge?.canPresent != true) return;
    _signup?.dispose();
    _signup = ZyraSignupPreviewController(now: widget.previewClock)..start();
    _signupHasEntered = false;
    _signupPreferences = null;
    _signupSurface = _signupPreferenceSurface = null;
    _signupLease = Object();
    _open('signup');
    unawaited(_loadSignupPhoto());
  }

  Future<void> _loadSignupPhoto() async {
    if (_signupPhoto != null || _signupPhotoLoading) return;
    _signupPhotoLoading = true;
    try {
      final data = await rootBundle.load(
        'assets/dev/one_journey_photos/seeker_self.jpg',
      );
      final photo =
          'data:image/jpeg;base64,${base64Encode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes))}';
      if (mounted && (_allowed || _developerBridge?.canPresent == true)) {
        setState(() {
          _signupPhoto = photo;
          _signupSurface = null;
        });
      }
    } finally {
      _signupPhotoLoading = false;
    }
  }

  Future<void> _resumeSignup() async {
    if (!_allowed || !_signupIncomplete) return;
    if (_signup == null ||
        !_signup!.hasAccount ||
        _signup!.setupComplete ||
        _signup!.guardian != _guardianRole) {
      _signup?.dispose();
      final profile = _accountSession.ownProfile(_guardianRole);
      _signup = ZyraSignupPreviewController(now: widget.previewClock)
        ..seedSetup(
          guardian: _guardianRole,
          verified: !_signupUnverified,
          firstName: profile.firstName,
          surname: profile.surnameLine ?? '',
        );
      // This path resumes an existing preview account, rather than creating
      // the first signup entry that owns the automatic walkthrough.
      _signupHasEntered = true;
      _signup!.setGender(profile.gender);
      final today = (widget.previewClock ?? DateTime.now)();
      _signup!
        ..setDay('1')
        ..setMonth('1')
        ..setYear('${today.year - profile.age}')
        ..setLocation(profile.city)
        ..setNationality(profile.publicNationality);
      for (final value in (profile.publicEthnicity ?? '').split(',')) {
        if (value.trim().isNotEmpty) _signup!.toggleEthnicity(value.trim());
      }
      for (final photo in profile.photos) {
        _signup!.addPhoto(photo);
      }
    }
    final controller = _signup!;
    if (_hasDeveloperPreview) {
      controller.setPreviewVerified(!_developerSamples.unverified);
    }
    final lease = _signupLease = Object();
    final snapshot = await _accountSession.compatibility.load('draft-self');
    if (!_allowed ||
        !identical(controller, _signup) ||
        !identical(lease, _signupLease)) {
      return;
    }
    _signupPreferences = ZyraCompatibilityDraft.fromSnapshot(
      gender: controller.gender ?? 'male',
      snapshot: snapshot,
    );
    final about = controller.guardian
        ? _accountSession.signupAbout(true)
        : _signupPreferences!.answers['bio_about_me'];
    if (about is String) controller.setAboutYou(about);
    _signupSurface = _signupPreferenceSurface = null;
    controller.resumeSetup();
    _open('signup');
    unawaited(_loadSignupPhoto());
  }

  bool _signupCurrent(
    ZyraSignupPreviewController controller,
    Object lease, {
    bool retain = false,
  }) =>
      mounted &&
      identical(controller, _signup) &&
      identical(lease, _signupLease) &&
      _page == 'signup' &&
      (retain ? (_allowed || _developerBridge?.canPresent == true) : _allowed);

  void _leaveSignup(ZyraSignupPreviewController controller, Object lease) {
    if (!_signupCurrent(controller, lease) || !controller.hasAccount) return;
    if (identical(_addedRoleSignup, controller)) _addedRoleSignup = null;
    final firstEntry = !_signupHasEntered;
    _signupHasEntered = true;
    controller.pauseSetup();
    final gender = controller.gender ?? 'male';
    final prefs =
        (_signupPreferences ??
                ZyraCompatibilityDraft.fromSnapshot(
                  gender: gender,
                  snapshot: null,
                ))
            .copy();
    prefs.answers['bio_about_me'] = controller.aboutYou;
    _signupPreferences = prefs;
    _accountSession.applySignup(
      guardian: controller.guardian,
      firstName: controller.firstName.trim().isEmpty
          ? 'Adam'
          : controller.firstName,
      surname: controller.surname,
      age: controller.age ?? 30,
      gender: gender,
      city: controller.location ?? 'London',
      nationality: controller.nationality,
      ethnicities: controller.ethnicities.toList(),
      photos: controller.photos,
      preferences: prefs,
    );
    if (_developerBridge?.canPresent == true) {
      final basic = controller.guardian
          ? _guardianMembership == 'Guardian Basic'
          : _seekerMembership == 'Seeker Basic';
      _developerSamples.setViewAs(
        controller.guardian
            ? (basic
                  ? ZyraDeveloperViewAs.guardianBasic
                  : ZyraDeveloperViewAs.guardianOne)
            : (basic
                  ? ZyraDeveloperViewAs.seekerBasic
                  : ZyraDeveloperViewAs.seekerOne),
      );
      _developerSamples.setUnverified(!controller.verified);
      _developerSamples.setSetupUnfinished(!controller.setupComplete);
    }
    _move(() {
      // A new detached signup has no Journeys. Continuation and replay retain
      // the current pages and never clear an existing member's state.
      if (firstEntry) _model.reset();
      _guardianRole = controller.guardian;
      _tab = 2;
      _pages.clear();
    });
    widget.onRoleChanged?.call(controller.guardian);
    if (firstEntry) unawaited(_firstSignupTour());
  }

  Widget _signupView() {
    final controller = _signup;
    final lease = _signupLease;
    if (controller == null || lease == null) return const SizedBox.shrink();
    if (_signupSurface != null) return _signupSurface!;
    bool current() => _signupCurrent(controller, lease);
    bool retained() => _signupCurrent(controller, lease, retain: true);
    Widget preferences(BuildContext _) {
      if (_signupPreferenceSurface != null) return _signupPreferenceSurface!;
      final draft = _signupPreferences ??= ZyraCompatibilityDraft.fromSnapshot(
        gender: controller.gender ?? 'male',
        snapshot: null,
      );
      return _signupPreferenceSurface = ZyraSignupPreferencesPreview(
        initialDraft: draft,
        bridge: _developerBridge,
        canAct: () =>
            current() && controller.step == ZyraSignupStep.preferences,
        canRetain: () =>
            retained() && controller.step == ZyraSignupStep.preferences,
        onChanged: (value) {
          if (current() && controller.step == ZyraSignupStep.preferences) {
            _signupPreferences = value.copy();
          }
        },
        onNext: () {
          if (current()) controller.advance();
        },
        onBack: () {
          if (current()) controller.setStep(ZyraSignupStep.accountReady);
        },
        onLater: () {
          if (current()) _leaveSignup(controller, lease);
        },
      );
    }

    return _signupSurface = ZyraSignupPreview(
      controller: controller,
      canAct: current,
      preferencesBuilder: preferences,
      samplePhotos: [
        if (_photos != null) _photos!.seekerPhoto else ?_signupPhoto,
      ],
      ownCode: 'ZYRA-7Q4M-K2XD-9P3L-W8RT-F6NB',
      onPause: () => _leaveSignup(controller, lease),
      onVerifyIdentity: () => _verifyDeveloperIdentity(fromSetup: true),
      onEnter: () {
        if (current() && controller.enterZyra()) {
          _leaveSignup(controller, lease);
        }
      },
      onShareCode: () {
        if (!current()) return;
        final box = context.findRenderObject();
        final origin = box is RenderBox
            ? box.localToGlobal(Offset.zero) & box.size
            : null;
        unawaited(
          SharePlus.instance.share(
            ShareParams(
              text:
                  'ZYRA Developer Preview code:\nZYRA-7Q4M-K2XD-9P3L-W8RT-F6NB\n\n'
                  'This sample code cannot connect real accounts.',
              subject: 'My ZYRA Code',
              sharePositionOrigin: origin,
            ),
          ),
        );
      },
    );
  }

  ZyraFocusItem _signupFocus(VoidCallback onResume) => ZyraFocusItem(
    id: 'signup-setup',
    icon: Icons.tune,
    title: 'Finish setting up',
    detail:
        "You can't start a Journey until your profile is complete. It only takes a few minutes.",
    actionLabel: 'Continue setting up',
    actionKey: 'signup_continue_setup',
    onAction: onResume,
  );

  Future<void> _showDeveloperError(ZyraErrorKind kind) async {
    final bridge = _developerBridge;
    final lifetime = bridge?.verifiedLifetime;
    if (!mounted || bridge?.canPresent != true || lifetime == null) return;
    late final MaterialPageRoute<void> route;
    bool current() =>
        mounted &&
        identical(bridge, _developerBridge) &&
        bridge!.canPresent &&
        bridge.verifiedLifetime == lifetime;
    route = MaterialPageRoute<void>(
      builder: (_) => ListenableBuilder(
        listenable: bridge!,
        builder: (context, _) => !current()
            ? const SizedBox.shrink()
            : ZyraFullScreenError(
                kind: kind,
                referenceCode: 'ZY-PREVIEW',
                onPrimary: () async {
                  if (current() && route.isCurrent) route.navigator?.pop();
                },
              ),
      ),
    );
    void withdraw() {
      if (current()) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }

    bridge!.addListener(withdraw);
    try {
      await Navigator.of(context, rootNavigator: true).push(route);
    } finally {
      bridge.removeListener(withdraw);
    }
  }

  void _syncDeveloperSamples() {
    final bridge = _developerBridge;
    if (!mounted || bridge?.canPresent != true) return;
    final samples = _developerSamples;
    if (!samples.hasSamples) {
      final baseline = _developerBaseline;
      if (baseline == null) return;
      _signup?.dispose();
      _signup = null;
      _signupLease = null;
      _signupSurface = _signupPreferenceSurface = null;
      _signupPreferences = null;
      _accountSession.clearSignup();
      setState(() {
        _model.peerDepartures.removeListener(_peerDeparted);
        _model = ViewRequestDraftModel.fromSnapshot(
          baseline,
          clock: widget.previewClock,
        );
        _model.peerDepartures.addListener(_peerDeparted);
        final checkpoint = _developerCheckpointBaseline!;
        _guardianRole = checkpoint.guardian;
        _myZyraConsumedFocusTokens.clear();
        _circleReadMessageKeys.clear();
        _circleTabSeenKeys.clear();
        _circleMuteKeys.clear();
        _circleSuppressedAttentionKeys.clear();
        _circleObservedArrivalKeys.clear();
        _circleArrivalChatIds.clear();
        _conceptRemovedGuardians.clear();
        _conceptNetworkSent.clear();
        _browsePhotoIndices.clear();
        _browseGalleryIndices.clear();
        _pages.clear();
        _restoreCheckpoint(checkpoint);
        _messages
          ..clear()
          ..addAll(
            _developerMessagesBaseline!.map(
              (id, messages) => MapEntry(id, messages.toList()),
            ),
          );
        _message.value = _developerMessageDraftBaseline!;
        _subscriptionWallet = _developerWalletBaseline!;
        _seekerMembership = _developerSeekerBaseline!;
        _guardianMembership = _developerGuardianBaseline!;
        _guardianRole = _developerRoleBaseline!;
        _pages.clear();
        _tab = _guardianRole ? 2 : 0;
        _developerBaseline = null;
        _developerCheckpointBaseline = null;
        _developerMessagesBaseline = null;
        _developerMessageDraftBaseline = null;
        _developerWalletBaseline = null;
        _developerSeekerBaseline = null;
        _developerGuardianBaseline = null;
        _developerRoleBaseline = null;
        _developerSelectionFingerprint = null;
        _developerJourneySignature = '';
        _developerStoreAttempts.clear();
        _developerLastView = null;
        _developerLastNotice = 0;
        _acceptedRetentionOffers.clear();
        _enteredRamadanDraw = false;
        _welcomeBackAt = _developerWelcomeBackBaseline;
        _developerWelcomeBackBaseline = null;
        _developerNavigation = bridge!.journeyNavigationEpoch;
        _developerNoticeEpoch = bridge.noticeNavigationEpoch;
        _developerPresetEpoch = bridge.presetSelectionEpoch;
        _circleScopeRevision++;
        _circleEntryView = null;
        _circleEntryRevision = -1;
        _circleVisibility.value = false;
        _accountLeafView = null;
        _accountLeafRevision = -1;
        _uiRevision++;
      });
      return;
    }
    // Q173 uses an explicitly local Seeker One sample when real membership is absent.
    final view = bridge!.viewAs;
    if (view == null || bridge.journeyPlaces == 0) return;
    final rows = samples.activeRows;
    final fingerprint = (
      samples.generation,
      bridge.verifiedLifetime,
      view,
      bridge.journeyPlaces,
      samples.unverified,
      samples.setupUnfinished,
      rows?.map((row) => '${row.id}:${row.stage}').join('|'),
      samples.endedRows?.map((row) => '${row.id}:${row.endedAt}').join('|'),
      samples.receivedRows
          ?.map((row) => '${row.person.id}:${row.date}')
          .join('|'),
      samples.sentRows?.map((row) => '${row.person.id}:${row.date}').join('|'),
      samples.history
          ?.map(
            (row) => '${row.request.person.id}:${row.status}:${row.movedAt}',
          )
          .join('|'),
      samples.introductionRows?.map((person) => person.id).join('|'),
      samples.preset,
      samples.profileSmallPage,
      samples.profileSmallPageEpoch,
      samples.notice,
      samples.offers,
      bridge.journeyNavigationEpoch,
      bridge.noticeNavigationEpoch,
      bridge.presetSelectionEpoch,
    );
    if (fingerprint == _developerSelectionFingerprint) {
      // Photos and a healthy proof refresh may repaint a title, but must not
      // retire its currently admitted editor or pending title-tap callback.
      setState(() {});
      return;
    }
    _developerSelectionFingerprint = fingerprint;
    if (_developerBaseline == null) {
      _developerBaseline = _model.snapshot();
      _developerCheckpointBaseline = _captureCheckpoint();
      _developerMessagesBaseline = {
        for (final entry in _messages.entries) entry.key: entry.value.toList(),
      };
      _developerMessageDraftBaseline = _message.value;
      _developerWelcomeBackBaseline = _welcomeBackAt;
    }
    _developerWalletBaseline ??= _subscriptionWallet;
    _developerSeekerBaseline ??= _seekerMembership;
    _developerGuardianBaseline ??= _guardianMembership;
    _developerRoleBaseline ??= _guardianRole;
    setState(() {
      if (_developerLastView != view) {
        final first = _developerLastView == null;
        final roleChanged = _guardianRole != view.guardian;
        _guardianRole = view.guardian;
        if (!first || roleChanged) {
          _tab = view.guardian ? 2 : 0;
          _pages.clear();
        }
        if (view.guardian) {
          _guardianMembership = view.label;
          _developerLastNotice = 0;
          _welcomeBackAt = null;
        } else {
          _seekerMembership = view.label;
        }
        _subscriptionWallet = _subscriptionWallet.withRole(
          view.guardian ? ZyraWalletRole.guardian : ZyraWalletRole.seeker,
          coverage:
              view == ZyraDeveloperViewAs.seekerBasic ||
                  view == ZyraDeveloperViewAs.guardianBasic
              ? ZyraWalletCoverage.basic
              : ZyraWalletCoverage.individualOne,
        );
        _developerLastView = view;
      }
      final rows = samples.activeRows;
      final signature = rows == null
          ? ''
          : 'set:${rows.map((r) => '${r.id}:${r.stage}').join('|')}';
      final places = bridge.journeyPlaces;
      if (_model.capacity != places) {
        // A smaller explicit sample plan cannot retain extra occupied places.
        if (_model.occupiedCount > places) _model.replacePreviewJourneys([]);
        _model.setCapacity(places);
      }
      if (rows != null && signature != _developerJourneySignature) {
        final journeys = [
          for (final row in rows) (profileId: row.person.id, stage: row.stage),
        ];
        final preserve =
            _developerJourneySignature.isNotEmpty &&
            rows.every(
              (row) =>
                  !_developerStoreAttempts.containsKey(row.person.id) ||
                  _developerStoreAttempts[row.person.id] == row.id,
            );
        var synchronized = _model.replacePreviewJourneys(
          journeys,
          preserveUnchanged: preserve,
        );
        if (!synchronized) {
          // A fixed sample person may already be a native request or ended
          // attempt. Keep that untouched in the captured baseline and use an
          // isolated working model for this explicit Journey override.
          final working = ViewRequestDraftModel(
            capacity: places,
            clock: widget.previewClock,
          );
          synchronized = working.replacePreviewJourneys(journeys);
          if (synchronized) {
            _model.peerDepartures.removeListener(_peerDeparted);
            _model = working;
            _model.peerDepartures.addListener(_peerDeparted);
          }
        }
        if (synchronized) {
          _developerJourneySignature = signature;
          _developerStoreAttempts
            ..clear()
            ..addEntries(rows.map((row) => MapEntry(row.person.id, row.id)));
        }
      }
      if (bridge.journeyNavigationEpoch != _developerNavigation) {
        _developerNavigation = bridge.journeyNavigationEpoch;
        final selected = rows
            ?.where((r) => r.id == samples.selectedJourneyId)
            .firstOrNull;
        if (selected != null) {
          _pages
            ..clear()
            ..add('journey');
          _tab = 1;
          _personId = selected.person.id;
          _guardianJourneyId = selected.person.id;
          _guardianJourneyAttemptRevision = _model.attemptRevisionFor(
            selected.person.id,
          );
        }
      }
      if (_developerPresetEpoch != bridge.presetSelectionEpoch) {
        _developerPresetEpoch = bridge.presetSelectionEpoch;
        final preset = samples.preset;
        final presetLifetime = bridge.verifiedLifetime;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              bridge.canPresent &&
              bridge.verifiedLifetime == presetLifetime &&
              samples.preset == preset) {
            samples.setSetupUnfinished(
              preset == ZyraDeveloperPreset.newMember ||
                  preset == ZyraDeveloperPreset.everything,
            );
          }
        });
        if (_signup?.setupComplete == true &&
            (preset == ZyraDeveloperPreset.newMember ||
                preset == ZyraDeveloperPreset.everything)) {
          _signup?.dispose();
          _signup = null;
          _signupLease = null;
          _signupSurface = _signupPreferenceSurface = null;
        }
        if (preset == ZyraDeveloperPreset.allCaughtUp ||
            preset == ZyraDeveloperPreset.typicalDay) {
          final lifetime = bridge.verifiedLifetime;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                bridge.canPresent &&
                bridge.verifiedLifetime == lifetime &&
                samples.preset == preset) {
              samples.setReceived(
                preset == ZyraDeveloperPreset.typicalDay ? 1 : 0,
              );
              samples.setIntroductions(0);
            }
          });
        }
        _myZyraFocusIndex = 0;
        _myZyraConsumedFocusTokens.clear();
        if (samples.preset != null && !_guardianRole) {
          _pages.clear();
          _tab = 2;
        }
      }
      if (_developerProfileSmallPageEpoch != samples.profileSmallPageEpoch) {
        _developerProfileSmallPageEpoch = samples.profileSmallPageEpoch;
        if (samples.profileSmallPage case final sample?) {
          _tab = 4;
          _pages
            ..clear()
            ..add(
              sample == ZyraProfileSmallPageSample.guardianNoSeekers
                  ? 'subscriptions'
                  : 'switch_account_signup',
            );
          _personId = null;
        }
      }
      if (_developerNoticeEpoch != bridge.noticeNavigationEpoch) {
        _developerNoticeEpoch = bridge.noticeNavigationEpoch;
        _developerLastNotice = samples.notice;
        _developerEmailCount = (samples.ended ?? 0) > 0 ? samples.ended! : 2;
        final notice = samples.notice;
        final lifetime = bridge.verifiedLifetime;
        if (notice > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                !bridge.canPresent ||
                bridge.verifiedLifetime != lifetime ||
                samples.notice != notice) {
              return;
            }
            if (notice == 5) {
              samples.setEnded(0);
            } else if ((samples.ended ?? 0) == 0) {
              samples.setEnded(2);
            }
          });
        }
        _pages.clear();
        _tab = 2;
        if (samples.notice >= 1 && samples.notice <= 5) {
          _pages.add('developer_inactivity_email');
        }
        _welcomeBackAt = samples.notice == 6 ? _previewNow : null;
        _myZyraFocusIndex = 0;
      }
      if (samples.unverified && _signupProtectedPage) {
        _pages.clear();
        _tab = 0;
      }
      _uiRevision++;
      _expandedJourneyOptionsId = null;
      _capacityRequest = null;
      _capacityEndingId = null;
    });
  }

  void _verifyDeveloperIdentity({bool fromSetup = false}) {
    if (!fromSetup &&
        _signup?.hasAccount == true &&
        _signup!.guardian == _guardianRole &&
        _allowed) {
      _signup!.setStep(ZyraSignupStep.verify);
      _signupSurface = _signupPreferenceSurface = null;
      _signupLease = Object();
      _open('signup');
      return;
    }
    final bridge = _developerBridge;
    final access = bridge?.access;
    final lifetime = bridge?.verifiedLifetime;
    if (!_allowed || access == null || lifetime == null) return;
    late final MaterialPageRoute<void> route;
    bool current() =>
        mounted &&
        identical(bridge, _developerBridge) &&
        bridge!.canPresent &&
        bridge.verifiedLifetime == lifetime;
    route = MaterialPageRoute<void>(
      builder: (_) => InitialIdentityCheckScreen(
        devPreview: true,
        developerPanelAccess: access,
        onContinue: (context) async {
          if (current() && route.isCurrent) {
            if (fromSetup && _signup?.step == ZyraSignupStep.addGuardian) {
              _signup!.setPreviewVerified(true);
            }
            _developerSamples.setUnverified(false);
            route.navigator?.pop();
          }
        },
      ),
    );
    Navigator.of(context, rootNavigator: true).push(route);
  }

  Widget _developerEmail() => ZyraDeveloperInactivityEmail(
    number: _developerLastNotice.clamp(1, 5),
    endedCount: _developerEmailCount,
    firstName: _accountSession.ownProfile(_guardianRole).firstName,
    removalDate: DateTime(2026, 11, 26),
    onBack: _bound(_back),
    onOpen: _guardianRole && _developerLastNotice < 5
        ? null
        : _bound(() {
            final kept = _developerLastNotice < 5;
            _move(() {
              _pages.clear();
              _tab = 2;
              _developerLastNotice = kept ? 6 : 0;
              _welcomeBackAt = kept ? _previewNow : null;
              _myZyraFocusIndex = 0;
            });
            _developerSamples.setNotice(kept ? 6 : 0);
          }),
  );

  List<ZyraFocusEvent>? _developerFocusEvents(
    List<ZyraFocusEvent> native, {
    bool includeConsumed = false,
  }) {
    if (!_hasDeveloperPreview || _guardianRole) return null;
    final preset = _developerSamples.preset;
    if (preset != null) {
      return zyraDeveloperFocusPreset(preset, now: _previewNow)
          .where(
            (event) =>
                includeConsumed ||
                event.tokens.any(
                  (token) => !_myZyraConsumedFocusTokens.contains(token),
                ),
          )
          .toList();
    }
    final received = _developerSamples.receivedRows;
    final introductions = _developerSamples.introductionRows;
    final events = <ZyraFocusEvent>[
      if (preset == null)
        ...native.where(
          (event) =>
              !(received != null && event.target == 'requests') &&
              !(introductions != null && event.target == 'introductions') &&
              event.target != 'welcome_back',
        ),
      if (_welcomeBackAt case final at?)
        ZyraFocusEvent(
          tokens: ['developer-welcome:${at.microsecondsSinceEpoch}'],
          target: 'welcome_back',
          title: 'Welcome back, ${_accountSession.ownProfile(false).firstName}',
          detail:
              'You were away for a while. Your Ended Journeys are kept — nothing was removed.',
          action: 'View Ended Journeys',
          icon: Icons.history_outlined,
          occurredAt: at,
        ),
      if (received != null && received.isNotEmpty)
        ZyraFocusEvent(
          tokens: [
            'developer-received:${received.map((r) => r.date.toIso8601String()).join(',')}',
          ],
          target: 'requests',
          title: received.length == 1
              ? 'Journey request from ${received.first.person.firstName}'
              : '${received.length} Journey requests',
          detail:
              '${zyraFocusRequestNames(received.map((r) => r.person.firstName).toList())} '
              'would like to begin a Journey with you.',
          action: received.length == 1 ? 'View request' : 'View requests',
          icon: Icons.mail_outline,
          occurredAt: _previewNow,
        ),
      if (introductions != null && introductions.isNotEmpty)
        ZyraFocusEvent(
          tokens: [
            'developer-introductions:${introductions.map((p) => p.id).join(',')}',
          ],
          target: 'introductions',
          title: 'Hassan introduced ${introductions.first.firstName}',
          detail: 'Review the person your Guardian has put forward.',
          action: 'View introduction',
          icon: Icons.groups_outlined,
          occurredAt: _previewNow,
        ),
    ];
    return events
        .where(
          (e) =>
              includeConsumed ||
              e.tokens.any((t) => !_myZyraConsumedFocusTokens.contains(t)),
        )
        .toList();
  }

  late final ScrollController _scroll;
  late final ZyraPreviewPositionBucket _positions;
  final _browsePhotoIndices = <String, int>{};
  final _browseGalleryIndices = <String, int>{};
  final _message = TextEditingController();
  final _messages = <String, List<String>>{};
  final _pages = <String>[];
  ({String ownerId, String page, int revision})? _bioGallery;
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
  DateTime? _welcomeBackAt;
  bool _backgroundedSinceReturn = false;
  late final AppLifecycleListener _inactivityLifecycle;
  String? _myZyraQuickAccessPage;
  final _myZyraConsumedFocusTokens = <String>{};
  final _circleReadMessageKeys = <String>{};
  final _circleTabSeenKeys = <String>{};
  final _circleMuteKeys = <ZyraCirclePreviewMuteKey>{};
  final _circleSuppressedAttentionKeys = <String>{};
  final _circleObservedArrivalKeys = <String>{};
  final _circleArrivalChatIds = <String, String>{};
  final _circleSentMessages =
      <ZyraCirclePreviewMuteKey, List<ZyraFamilyMessage>>{};
  int _circleSentSequence = 0;
  ZyraCircleMainUnreadHint? _pendingMainUnreadOnEntry;
  final _circleArrivals = ValueNotifier<ZyraGuardianCirclePreviewData?>(null);
  int _browseIndex = 1;
  // Session-only viewing order, never a visibility or request permission.
  final _seenBrowseProfileIds = <String>{};
  late ZyraPreviewBrowseWindow _profilesWindow =
      switch (widget.fixture?.seededViewedProfiles ?? 0) {
        0 => ZyraPreviewBrowseWindow(),
        final count => ZyraPreviewBrowseWindow(
          startedAt: _previewNow,
          seededViews: count,
        ),
      };
  bool _waitingRequestsSheetOpen = false;
  ModalRoute<ZyraRequestLimitChoice>? _waitingRequestsSheetRoute;
  final _browseHistory = ZyraBrowseHistory();
  // The approved portrait card is the single active Browse direction.
  static const _browseDesign = ZyraOneJourneyBrowseDesign.portraitCard;
  bool _browseBackSheetOpen = false;
  int _uiRevision = 0;
  bool _browseOptionsOpen = false;
  String? _browseOptionsPersonId;
  int _guardianPage = 0;
  bool _makeMainCheckStopped = false;
  bool _guardianInvitationCancelled = false;
  late DateTime _guardianInvitationClockStart = widget.previewClock == null
      ? _previewNow
      : ZyraOneJourneyGuardianCards.previewInvitationSent;
  ModalRoute<dynamic>? _guardianOptionsRoute;
  ModalRoute<bool>? _ownedConfirmRoute;
  List<String> _confirmPeerIds = const [];
  String? _journeyOptionsPersonId;
  ModalRoute<dynamic>? _journeyOptionsRoute;
  int _networkTab = 0;
  late ZyraGuardianTabsState _guardianTabs = ZyraGuardianTabsState(
    widget.fixture?.guardianTabs ?? const ZyraGuardianTabsSnapshot.quiet(),
  );
  String? _personId;
  String? _guardianJourneyId;
  int? _guardianJourneyAttemptRevision;
  _GuardianCompatibilityTarget? _guardianCompatibilityTarget;
  ({String id, int revision, int navigatorStamp})? _hiddenProfileRestore;
  bool _otherSampleDevicesPresent = true;
  final _privacyDates = <String, String>{
    'draft-zainab': '12 Nov',
    'draft-hana': '18 Nov',
    'draft-safiya': '2 Nov',
  };
  bool _journeyOptionsOpen = false;
  String? _expandedJourneyOptionsId;
  String? _sampleEndedArchiveAttemptId;
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
      widget.fixture?.wallet ??
      ZyraSubscriptionWalletDraft.sample(
        ownerId: 'concept-wallet-${identityHashCode(this)}',
      );
  ZyraWalletRole? _walletSetupRole;
  // Explicit fictional payment record, independent of the selected role/plan.
  late ZyraMembershipPaymentHistory _membershipPaymentHistory =
      widget.fixture?.membershipPaymentHistory ??
      ZyraMembershipPaymentHistory.paidBefore;
  final bool _shareHistory = false;
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

  String _seekerMembership = 'Seeker One';
  String _guardianMembership = 'Guardian One';
  ZyraGuardianFamilyPreview _guardianFamily = ZyraGuardianFamilyPreview();
  Timer? _guardianFamilyDeadline;
  String get _membership =>
      _guardianRole ? _guardianMembership : _seekerMembership;

  late final ZyraOneJourneyLocation _location;
  // 0 closed, 1 choose, 2 explain; no Navigator cover of the admitted host.
  int _locationSheet = 0, _locationFlow = 0;
  ZyraBrowseFilter _browseFilter = const ZyraBrowseFilter();
  ZyraBrowseFilter _editingBrowseFilter = const ZyraBrowseFilter();
  int _filtersCardIndex = 0;
  bool get _hasAllBrowseFilters => _seekerMembership != 'Seeker Basic';
  ZyraBrowseFilter get _activeBrowseFilter =>
      _hasAllBrowseFilters ? _browseFilter : _browseFilter.withoutHeritage();

  ZyraBrowseFilter _keepingSavedOneFilters(
    ZyraBrowseFilter filter,
    ZyraBrowseFilter saved,
  ) => _hasAllBrowseFilters ? filter : filter.withHeritageFrom(saved);
  ZyraConceptAccountAction? _accountDestination;
  ZyraConceptSettingsDetail? _settingsDetail;
  DateTime? _helpDataRequestedAt;
  DateTime? _helpClosedAt;
  ZyraMembershipDraft _membershipDraft = ZyraMembershipDraft();
  ZyraMembershipReviewRequest? _membershipReview;
  // Used viewer/profile access is independent of both route and Journey ID.
  // The normal Founder host owns it across disposable UI proof epochs.
  late final _compatibilityAccess =
      widget.fixture?.compatibilityAccess ??
      widget.compatibilityAccess ??
      ZyraDraftCompatibilityAccessStore(canAct: () => _allowed);
  Object? _compatibilityRoute;
  String? _endedCompatibilityAttemptId;
  Timer? _timeRuleTimer;
  DateTime? _timeRuleDeadline;
  ZyraDraftTimelinePreview? _timelinePreview;
  Widget? _scanEntryView;
  int _scanEntryRevision = -1;
  late final ZyraRequestAccountSession _accountSession;
  late final ZyraPausePrivatePreviewState _profilePrivacy;
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
  late final _circleBubbleDesign = ValueNotifier(
    widget.fixture?.circleBubbleDesign ?? ZyraCircleBubbleDesign.current,
  );
  // Fixed caller-owned display fixture, never a domain or acknowledgement grant.
  late ZyraMyZyraActivityExample? _activityExample =
      widget.fixture?.activityExample;
  int _activityFixtureRevision = 0;
  ({
    String personId,
    Set<String> linkedIds,
    String? mainId,
    Set<String> paidIds,
  })?
  _paidGuardianAgreement;
  late final _fixtureOwner = widget.fixture;
  late final Object _fixtureAccount;
  bool _routeRefreshScheduled = false;
  Widget? _retainedJourneyOptions;
  int get _routeStamp => ZyraPreviewRouteObserver.navigationRevision;

  void _routeChanged() {
    _closeLocationFlow();
    _cancelTimeRuleTimer();
    _hiddenProfileRestore = null;
    if (_routeRefreshScheduled) return;
    _routeRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeRefreshScheduled = false;
      if (!mounted) return;
      if (_activityRoot && ModalRoute.isCurrentOf(context) == false) {
        _dismissWelcomeBack();
      }
      if (_allowed) {
        _refreshTimeRules();
      } else {
        setState(() {});
      }
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

  bool get _allowed => mounted && widget.canAct();
  String? get _page => _pages.isEmpty ? null : _pages.last;
  bool _isMyZyraQuickPage(String? page) => _guardianRole
      ? page == 'guardian_requests' ||
            page == 'notifications' ||
            (_guardianMembership == 'Guardian One' &&
                (page == 'guardian_connect' ||
                    page == 'guardian_introductions'))
      : const {
          'requests',
          'introductions',
          'ended',
          'notifications',
        }.contains(page);

  bool get _quickAccessTabBar =>
      _tab == 2 &&
      ((_pages.length == 1 &&
              _page == _myZyraQuickAccessPage &&
              _isMyZyraQuickPage(_page)) ||
          // Q164: the read-only archive hub keeps My ZYRA navigation.
          (!_guardianRole && _endedHistoryRoot && _page == 'ended_archive') ||
          // Q80: keep the My ZYRA bar on this read-only Notifications child.
          (_guardianRole &&
              _myZyraQuickAccessPage == 'notifications' &&
              _pages.length == 2 &&
              _pages.first == 'notifications' &&
              _page == 'guardian_requests'));

  bool get _showRootTabBar =>
      _page == null || _page == 'journey_options' || _quickAccessTabBar;
  bool get _isPhotoPage => const [
    'profile',
    'own_profile_preview',
    'guardian_linked_profile',
    'guardian_network_profile',
  ].contains(_page);
  DraftProfile? get _person {
    final id = _personId;
    if (id == null || _model.hasDeparted(id)) return null;
    return draftProfiles.where((p) => p.id == id).firstOrNull;
  }

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
      _model.hasVisibleEndedJourney(id);

  ZyraSampleJourney? _sampleEndedFor(String? id) =>
      _hasDeveloperPreview && id != null
      ? _developerSamples.endedRows
            ?.where(
              (row) =>
                  row.person.id == id && row.id == _sampleEndedArchiveAttemptId,
            )
            .firstOrNull
      : null;

  bool _canAddressEndedArchive(String? id) =>
      _canAddressEndedJourney(id) ||
      (_allowed &&
          _endedHistoryRoot &&
          id != null &&
          !_model.hasDeparted(id) &&
          !_model.isBlocked(id) &&
          _sampleEndedFor(id) != null);

  DateTime get _previewNow => (widget.previewClock ?? DateTime.now)().toUtc();

  DateTime get _guardianInvitationNow => ZyraOneJourneyGuardianCards
      .previewInvitationSent
      .add(_previewNow.difference(_guardianInvitationClockStart));

  bool _hasRecordedEnd(String id) =>
      _model.currentEndedAttemptFor(id)?.hasRecordedEnd(_previewNow) == true;

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
    if (attempt == null || !_model.canSeeEndedAttempt(attempt)) return false;
    if (_compatibilityAccess.isUnlocked(id)) return true;
    final progress = attempt.progress;
    return attempt.hasRecordedEnd(_previewNow) &&
        progress.compatibilityConsent &&
        progress.peerCompatibilityConsent;
  }

  bool _canRequestEndedRestart(String id) =>
      _canAddressEndedJourney(id) && !_model.isHidden(id);

  void _cancelTimeRuleTimer() {
    _timeRuleTimer?.cancel();
    _timeRuleTimer = null;
    _timeRuleDeadline = null;
  }

  void _refreshTimeRules() {
    final changed = _model.advanceTimeRules();
    if (_hasDeveloperPreview) _developerSamples.advanceWaitingRequests();
    setState(() {});
    if (changed) _publishCheckpoint();
  }

  void _syncTimeRuleTimer() {
    var deadline = _model.nextTimeRuleDeadline;
    final previewExpiry = _hasDeveloperPreview
        ? _developerSamples.nextWaitingRequestExpiry
        : null;
    if (previewExpiry != null &&
        (deadline == null || previewExpiry.isBefore(deadline))) {
      deadline = previewExpiry;
    }
    final refill = _profilesWindow.refillAt;
    if (!_guardianRole &&
        _seekerMembership == 'Seeker Basic' &&
        _tab == 0 &&
        _page == null &&
        refill != null &&
        _profilesWindow.activeAt(_previewNow) &&
        (deadline == null || refill.isBefore(deadline))) {
      deadline = refill;
    }
    final routeCurrent = ModalRoute.isCurrentOf(context) == true;
    if (!_allowed || !routeCurrent || deadline == null) {
      _cancelTimeRuleTimer();
      return;
    }
    if (deadline == _timeRuleDeadline) return;
    _cancelTimeRuleTimer();
    _timeRuleDeadline = deadline;
    _timeRuleTimer = Timer(_model.timeUntil(deadline), () {
      _cancelTimeRuleTimer();
      if (_allowed) _refreshTimeRules();
    });
  }

  // Read the preserved completed mutual choice, never infer an archive grant
  // from a paid Unlock, the menu's presence or today's Guardian roster.
  bool _canViewEndedBio(String id) =>
      _canAddressEndedJourney(id) &&
      _hasRecordedEnd(id) &&
      _model.hasCompletedCompatibilityStep(id) &&
      _model.hasCompletedBioStep(id) &&
      _model.bioRevealed(id) &&
      !_model.isBioStepOpen(id);

  // One read projection for cards, counts, badges and updates. Blocking hides
  // an invitation here without deleting its underlying fictional record.
  // Hide is deliberately different: it only removes the peer from Browse.
  List<DraftProfile> _visibleRequests(DraftJourneyState state) => draftProfiles
      .where(
        (person) => state == DraftJourneyState.ended
            ? _model.hasVisibleEndedJourney(person.id)
            : !_model.isBlocked(person.id) &&
                  _model.stateFor(person.id) == state,
      )
      .toList(growable: false);

  bool get _hasNewMyZyraTabActivity =>
      _hasCircleTabActivity ||
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

  // The model belongs to Adam. Yusuf's existing sample has no current Journey.
  // Preserve the View projection and apply the Seeker tab's activity ordering.
  List<DraftProfile> get _guardianTabJourneyPeople {
    if (!_guardianTabs.main) return const [];
    final permitted = _permittedGuardianJourneys.map((p) => p.id).toSet();
    return _tabJourneys.where((p) => permitted.contains(p.id)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fixtureAccount = (ZyraAccountState.userId, ZyraAccountState.generation);
    _profilePrivacy = ZyraPausePrivatePreviewState(
      canAct: () =>
          mounted &&
          _fixtureAccount ==
              (ZyraAccountState.userId, ZyraAccountState.generation),
      seekerOne: () => _seekerMembership == 'Seeker One',
    )..addListener(_accountChanged);
    _firstTourStore = ZyraFirstTourStore(
      ownerId: ZyraAccountState.userId,
      canAct: () => _firstTourCurrent,
    );
    _location = ZyraOneJourneyLocation(canAct: () => _allowed)
      ..addListener(_locationChanged);
    ZyraPreviewRouteObserver.navigationChanges.addListener(_routeChanged);
    _guardianRole = widget.initialGuardianRole;
    _membershipDraft = ZyraMembershipDraft(
      section: ZyraMembershipSection.current,
    );
    // A warm timeout returns to My ZYRA, not the fresh-launch Browse tab.
    // The host still owns elapsed-time and fresh-admission decisions.
    _tab =
        widget.initialTab?.clamp(0, 4) ??
        (_guardianRole || !widget.restoreLocation ? 2 : 0);
    final checkpoint = widget.initialCheckpoint;
    final sameRole = checkpoint?.guardian == _guardianRole;
    _model =
        widget.fixture?.model ??
        (sameRole
            ? ViewRequestDraftModel.fromSnapshot(
                checkpoint!.model,
                clock: widget.previewClock,
              )
            : ViewRequestDraftModel(capacity: 3, clock: widget.previewClock));
    _model.peerDepartures.addListener(_peerDeparted);
    _model.advanceTimeRules();
    if (sameRole) _restoreCheckpoint(checkpoint!);
    if (_allowed && !_guardianRole) {
      _welcomeBackAt = _model.recordInactivityReturn();
      if (_welcomeBackAt != null) _myZyraFocusIndex = 0;
    }
    _inactivityLifecycle = AppLifecycleListener(
      onHide: () => _backgroundedSinceReturn = true,
      onResume: _resumeInactivityNotice,
    );
    if (_guardianRole && _tab == 2 && _page == null) {
      _seeGuardianTabActivity();
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
      canAct: () =>
          _allowed ||
          (_developerBridge?.canPresent == true) ||
          ((_guardianOptionsRoute?.isCurrent == true ||
                  _ownedConfirmRoute?.isCurrent == true) &&
              (widget.canActInOwnedDialog?.call() ?? false)),
      palette: ZyraColors.devPalette,
      hapticLevel: ZyraInteractionStyle.hapticLevel,
      goldEnabled: false,
      legacyAmberQuickCheck: _fixtureOwner?.legacyAmberQuickCheck == true,
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
    _fixtureOwner?.onModelAttached?.call(_model);
    _fixtureOwner?.onCompatibilityAccessAttached?.call(_compatibilityAccess);
    _fixtureOwner?.onStateAttached?.call(
      ZyraOneJourneyShellFixtureState(
        guardianRole: _guardianRole,
        wallet: _subscriptionWallet,
        membershipPaymentHistory: _membershipPaymentHistory,
        seekerMembership: _seekerMembership,
        guardianMembership: _guardianMembership,
      ),
    );
    _fixtureOwner?.changes?.addListener(_fixtureChanged);
    _fixtureOwner?.onAttached?.call(_fixtureIsCurrent);
    _fixtureOwner?.onCaptureGuardAttached?.call(() => _accountFreshGuard());
    unawaited(_loadBrowsePhotos());
    _armGuardianFamilyExpiry();
    unawaited(_loadGuardianInfoSeen());
    unawaited(_loadPhoneAccessSeen());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Restoring a list is not evidence that every request was viewed.
      _publishCheckpoint();
      if (_fixtureOwner?.firstTourIndex case final index?) {
        _startFirstTour(index: index);
      }
    });
  }

  static final _profileIds = draftProfiles.map((p) => p.id).toSet();
  static final _guardianIds = draftGuardians.map((g) => g.id).toSet();
  static const _settingsOverviewActions = {
    ZyraConceptAccountAction.signInSecurity,
    ZyraConceptAccountAction.appLock,
    ZyraConceptAccountAction.advanced,
    ZyraConceptAccountAction.visibility,
    ZyraConceptAccountAction.privateMode,
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
          ? action != ZyraConceptAccountAction.visibility &&
                action != ZyraConceptAccountAction.privateMode &&
                action != ZyraConceptAccountAction.guardianPrivacy
          : action != ZyraConceptAccountAction.guardianPrivacy);

  bool _canRestoreSettingsDetail(
    ZyraConceptAccountAction? action,
    ZyraConceptSettingsDetail? detail,
  ) =>
      _canRestoreSettingsOverview(action) &&
      switch (action) {
        ZyraConceptAccountAction.signInSecurity => false,
        ZyraConceptAccountAction.appLock =>
          detail == ZyraConceptSettingsDetail.appLock,
        ZyraConceptAccountAction.advanced =>
          detail == ZyraConceptSettingsDetail.deleteAccount ||
              detail == ZyraConceptSettingsDetail.resetProfile,
        ZyraConceptAccountAction.visibility ||
        ZyraConceptAccountAction.privateMode => false,
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
    _pendingMainUnreadOnEntry = null;
    _guardianCompatibilityTarget = null;
    _guardianJourneyAttemptRevision = null;
    _myZyraQuickAccessPage = null;
    _guardianFamily = ZyraGuardianFamilyPreview(snapshot: saved.guardianFamily);
    _guardianFamily.expire(_previewNow);
    _guardianTabs = ZyraGuardianTabsState(saved.guardianTabs);
    _myZyraConsumedFocusTokens.addAll(saved.myZyraConsumedFocusTokens);
    _circleReadMessageKeys.addAll(saved.circleReadMessageKeys);
    _circleTabSeenKeys.addAll(saved.circleTabSeenKeys);
    _circleMuteKeys.addAll(saved.circleMuteKeys);
    _circleSuppressedAttentionKeys.addAll(saved.circleSuppressedAttentionKeys);
    _circleObservedArrivalKeys.addAll(saved.circleObservedArrivalKeys);
    _circleArrivalChatIds.addAll(saved.circleArrivalChatIds);
    _circleSentSequence = saved.circleSentSequence;
    _circleSentMessages
      ..clear()
      ..addAll(
        saved.circleSentMessages.map(
          (key, messages) => MapEntry(key, messages.toList()),
        ),
      );
    _myZyraFocusIndex = widget.restoreLocation ? saved.myZyraFocusIndex : 0;

    // Restore the saved account choices before the short-return check.
    // Navigation below is restored only inside that window.
    _seekerMembership = saved.seekerMembership == 'Seeker Basic'
        ? 'Seeker Basic'
        : 'Seeker One';
    final openedRevision = saved.myZyraLastOpenedRevision;
    _myZyraLastOpenedRevision =
        openedRevision >= 0 && openedRevision <= _model.receivedActivityRevision
        ? openedRevision
        : 0;
    _guardianMembership = saved.guardianMembership;
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
          coverage: switch (_guardianMembership) {
            'Guardian Basic' => ZyraWalletCoverage.basic,
            'Guardian One' => ZyraWalletCoverage.individualOne,
            _ => ZyraWalletCoverage.unavailable,
          },
        );
    if (_guardianIds.contains(saved.mainGuardianId)) {
      _conceptMainGuardianId = saved.mainGuardianId;
    }
    _conceptRemovedGuardians.addAll(
      saved.removedGuardians.where(_guardianIds.contains),
    );
    _conceptGuardianHistory
      ..clear()
      ..addEntries(
        saved.guardianHistory.entries.where(
          (e) =>
              _guardianIds.contains(e.key) &&
              !_conceptRemovedGuardians.contains(e.key),
        ),
      );
    _conceptNetworkSent.addAll(saved.networkSent.where(_profileIds.contains));
    _guardianInvitationCancelled = saved.guardianInvitationCancelled;
    final invitationClockStart = saved.guardianInvitationClockStart;
    if (invitationClockStart != null) {
      _guardianInvitationClockStart = invitationClockStart;
    }
    if (saved.profilesWindow case final window?) {
      _profilesWindow = ZyraPreviewBrowseWindow.fromSnapshot(window);
    }
    _seenBrowseProfileIds
      ..clear()
      ..addAll(saved.browseHistory.where(_profileIds.contains))
      ..addAll(saved.seenBrowseProfiles.where(_profileIds.contains));
    if (!widget.restoreLocation) {
      final heritage = const ZyraBrowseFilter().withHeritageFrom(
        saved.browseFilter,
      );
      if (heritage.isValid) {
        _browseFilter = _browseFilter.withHeritageFrom(heritage);
        _editingBrowseFilter = _browseFilter;
      }
      return;
    }
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
    final savedPerson = saved.personId;
    _personId =
        savedPerson != null &&
            _profileIds.contains(savedPerson) &&
            !_model.hasDeparted(savedPerson)
        ? savedPerson
        : null;
    _guardianJourneyId = _profileIds.contains(saved.guardianJourneyId)
        ? saved.guardianJourneyId
        : null;
    _guardianJourneyAttemptRevision = saved.guardianJourneyAttemptRevision;
    _browseFilter = saved.browseFilter.isValid
        ? saved.browseFilter
        : const ZyraBrowseFilter();
    _editingBrowseFilter = _browseFilter;
    final eligible = _activeBrowseFilter.apply(_model.discoverableProfiles);
    _browseHistory.reset();
    for (final id in saved.browseHistory.where(_profileIds.contains)) {
      _browseHistory.appendFrontier(id);
    }
    final cursor = saved.browseCursor.clamp(0, _browseHistory.ids.length);
    while (_browseHistory.canBack && _browseHistory.cursor > cursor) {
      _browseHistory.back();
    }
    if (_seekerMembership == 'Seeker Basic') {
      final savedId = saved.browseId;
      if (_browseHistory.currentId == null &&
          savedId != null &&
          _profileIds.contains(savedId)) {
        _browseHistory.appendFrontier(savedId);
      }
    } else {
      _browseHistory.reconcile(
        eligible.map((p) => p.id),
        fallbackId: saved.browseId,
      );
    }
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
    _purgeDepartedPreviewState();
    // Restore the Photos parent after a brief app switch, using a fresh
    // admitted editor and the existing photo-readiness gate. Never replay a
    // camera/crop child, decision sheet, checkout or pending operation.
    const common = {
      'settings',
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
      'ended_archive',
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
      'guardian_family_offer',
      'guardian_free_place_invite',
      'guardian_family_identity',
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
      if (_pages.isEmpty && page == saved.myZyraQuickAccessPage) {
        if (_tab != 2 || !_isMyZyraQuickPage(page)) break;
        if (page == 'notifications') {
          _pages.add(page);
          continue;
        }
      }
      if (_guardianRole && guardianPages.contains(page)) {
        if (page == 'guardian_introduce') {
          final peer =
              ZyraGuardianTabsState.network[_guardianTabs.networkIndex].id;
          if (_model.hasDeparted('draft-$peer')) break;
        }
        if (page == 'guardian_free_place_invite' &&
            (_tab != 2 ||
                _pages.isNotEmpty ||
                _pendingGuardianFreePlace == null)) {
          break;
        }
        if (page.startsWith('guardian_family_') &&
            (_tab != 2 || _pendingGuardianFamilyOffer == null)) {
          break;
        }
        if (page == 'guardian_private_chat' &&
            _guardianTabs.connection != ZyraGuardianConnection.accepted) {
          break;
        }
        _pages.add(page);
        continue;
      }
      // LOCK46 supersedes the old post-change Continue page.
      if (page == 'guardian_main_notice') break;
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
            'ended_archive',
            'ended_bio',
            'ended_guardians',
            'ended_compatibility',
          }.contains(page) &&
          !(page == 'ended_archive'
              ? _canAddressEndedArchive(_personId)
              : _canAddressEndedJourney(_personId))) {
        break;
      }
      if ({
            'journey',
            'journey_options',
            'journey_compatibility',
            'journey_guardians',
            'bio',
          }.contains(page) &&
          !_currentJourneys.any((p) => p.id == _personId) &&
          !(page == 'journey' && _canAddressEndedJourney(_personId))) {
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
    final quick = saved.myZyraQuickAccessPage;
    if (_tab == 2 && _pages.firstOrNull == quick && _isMyZyraQuickPage(quick)) {
      _myZyraQuickAccessPage = quick;
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

  ZyraPreviewNavigationCheckpoint _captureCheckpoint() {
    final offset = _scroll.hasClients
        ? _scroll.offset
        : _scroll.initialScrollOffset;
    return ZyraPreviewNavigationCheckpoint(
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
      circleTabSeenKeys: _circleTabSeenKeys,
      circleMuteKeys: _circleMuteKeys,
      circleSuppressedAttentionKeys: _circleSuppressedAttentionKeys,
      circleObservedArrivalKeys: _circleObservedArrivalKeys,
      circleArrivalChatIds: _circleArrivalChatIds,
      circleSentSequence: _circleSentSequence,
      circleSentMessages: _circleSentMessages,
      myZyraFocusIndex: _myZyraFocusIndex,
      myZyraQuickAccessPage: _myZyraQuickAccessPage,
      guardianPage: _guardianPage,
      guardianInvitationCancelled: _guardianInvitationCancelled,
      guardianInvitationClockStart: _guardianInvitationClockStart,
      networkTab: _networkTab,
      guardianJourneyId: _guardianJourneyId,
      guardianJourneyAttemptRevision: _guardianJourneyAttemptRevision,
      browseId: _browseHistory.currentId,
      browseFilter: _browseFilter.withOrigin(_homeTownPoint),
      browseHistory: _browseHistory.ids,
      seenBrowseProfiles: _seenBrowseProfileIds,
      profilesWindow: _profilesWindow.snapshot(),
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
      guardianFamily: _guardianFamily.snapshot,
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
    );
  }

  void _publishCheckpoint() {
    if (!_allowed ||
        _firstTourIndex != null ||
        (widget.onCheckpoint == null && widget.fixture?.onCheckpoint == null)) {
      return;
    }
    final checkpoint = _captureCheckpoint();
    widget.onCheckpoint?.call(checkpoint);
    widget.fixture?.onCheckpoint?.call(checkpoint);
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
          _accountSession.seedPhotos(
            false,
            _fixtureOwner?.seekerPhotos ?? [value.seekerPhoto],
          );
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
    _guardianFamily.expire(_previewNow);
    _model.advanceTimeRules();
    _closeLocationFlow();
    _cancelTimeRuleTimer();
    setState(() {
      final wasMyZyra = _activityRoot;
      _browseOptionsOpen = false;
      _browseOptionsPersonId = null;
      _hiddenProfileRestore = null;
      if (!preserveCircle) _pendingMainUnreadOnEntry = null;
      change();
      _profilePrivacy.synchronizePlan(notify: false);
      if (wasMyZyra && !_activityRoot) _dismissWelcomeBack();
      if (_tab != 2 ||
          _pages.firstOrNull != _myZyraQuickAccessPage ||
          !_isMyZyraQuickPage(_myZyraQuickAccessPage)) {
        _myZyraQuickAccessPage = null;
      }
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
      if (_page != 'guardian_circle') _pendingMainUnreadOnEntry = null;
      _circleVisibility.value = _page == 'guardian_circle';
    });
    _mirrorDeveloperJourneys();
    _publishCheckpoint();
  }

  void _mirrorDeveloperJourneys() {
    if (!_hasDeveloperPreview) return;
    final bridge = _developerBridge!;
    final lifetime = bridge.verifiedLifetime;
    final revision = _uiRevision;
    final rows = _developerSamples.activeRows;
    if (rows == null || lifetime == null) return;
    final changes = [
      for (final row in rows)
        if (_model.stateFor(row.person.id) == DraftJourneyState.ended ||
            (_model.stateFor(row.person.id) == DraftJourneyState.active &&
                (_model.isBioStepOpen(row.person.id)
                        ? ZyraJourneyStages.lifeSnapshotPreview.value
                        : _model.stageFor(row.person.id)?.value) !=
                    row.stage))
          (
            row: row,
            ended: _model.stateFor(row.person.id) == DraftJourneyState.ended,
            stage: _model.isBioStepOpen(row.person.id)
                ? ZyraJourneyStages.lifeSnapshotPreview.value
                : _model.stageFor(row.person.id)?.value,
          ),
    ];
    if (changes.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !identical(bridge, _developerBridge) ||
          !bridge.canPresent ||
          bridge.verifiedLifetime != lifetime ||
          revision != _uiRevision) {
        return;
      }
      for (final change in changes) {
        if (!(_developerSamples.activeRows?.contains(change.row) ?? false)) {
          continue;
        }
        if (change.ended) {
          _developerSamples.endActive(change.row);
        } else if (change.stage case final stage?) {
          _developerSamples.setJourneyStage(change.row.id, stage);
        }
      }
    });
  }

  void _move(VoidCallback change, {bool preserveCircle = false}) {
    _act(() {
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
      if (!_guardianRole || !_pages.contains('guardian_compatibility')) {
        _guardianCompatibilityTarget = null;
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
      if (_guardianRole && (_tab == 2 || index == 2)) {
        _seeGuardianTabActivity();
      }
      if (_tab == 2 || index == 2) {
        final circle = _currentCircleData();
        if (circle != null) {
          _circleTabSeenKeys.addAll(
            _circleAttention(
              circle,
            ).map((message) => _circleMessageKey(circle, message)),
          );
        }
      }
      _tab = index;
      if (!_guardianRole && index == 1) _consumeFocusTarget('journey_tab');
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

  void _open(String page, {String? person}) {
    if (_signupUnverified &&
        const {
          'profile',
          'guardian_linked_profile',
          'guardian_network_profile',
          'guardian_seeker',
          'network_request',
          'scan',
        }.contains(page)) {
      _tabTo(0);
      return;
    }
    if (person != null && _model.hasDeparted(person)) return;
    var target = page;
    if ({
      'ended_archive',
      'ended_bio',
      'ended_guardians',
      'ended_restart',
      'ended_compatibility',
    }.contains(page)) {
      final id = person ?? _personId;
      if (!(page == 'ended_archive'
          ? _canAddressEndedArchive(id)
          : _canAddressEndedJourney(id))) {
        return;
      }
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
      if (page == 'guardian_circle') _markCurrentCircleRead();
      if (page != 'guardian_circle' || _activityExample != null) {
        _consumeFocusTarget(page, personId: person);
      }
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
      if (page == 'filters') {
        _editingBrowseFilter = _browseFilter;
        _filtersCardIndex = 0;
      }
      _pages.add(target);
    }, preserveCircle: _pages.contains('guardian_circle'));
  }

  void _openMyZyraQuickPage(String page) {
    if (!_allowed || _tab != 2 || _page != null || !_isMyZyraQuickPage(page)) {
      return;
    }
    _move(() {
      _consumeFocusTarget(page);
      _pages.add(page);
      _myZyraQuickAccessPage = page;
    });
  }

  void _back() {
    if (_firstTourPending) return;
    if (_firstTourIndex case final index?) {
      _showFirstTour(index - 1);
      return;
    }
    if (_page == 'signup' && _signup != null) {
      if (_signup!.canGoBack) {
        _signup!.back();
      } else if (identical(_signup, _addedRoleSignup)) {
        _signup!.dispose();
        _signup = _addedRoleSignup = null;
        _signupLease = null;
        _signupPreferences = null;
        _signupSurface = _signupPreferenceSurface = null;
        _move(_pages.removeLast);
      } else if (_signup!.hasAccount) {
        _leaveSignup(_signup!, _signupLease!);
      } else {
        _move(_pages.clear);
      }
      return;
    }
    if (_currentBioGallery != null) {
      setState(() => _bioGallery = null);
      return;
    }
    if (_locationSheet != 0) {
      setState(_closeLocationFlow);
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
      _act(() {});
      return;
    }
    final retainingCircle =
        _page != 'guardian_circle' && _pages.contains('guardian_circle');
    _move(() {
      if (_page == 'filters') _editingBrowseFilter = _browseFilter;
      if (_pages.isNotEmpty) _pages.removeLast();
    }, preserveCircle: retainingCircle);
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
                  : _activeBrowseFilter.apply(_model.discoverableProfiles))
              .any((person) => person.id == id));

  void _openBrowseOptions(String? id) {
    if (!_canOpenBrowseOptions(id)) return;
    _act(() {
      _browseOptionsOpen = true;
      _browseOptionsPersonId = id;
    });
  }

  Future<void> _confirmBrowseHide(DraftProfile person) async {
    final revision = _uiRevision;
    final safetyRevision = _model.personSafetyRevision;
    final attempt = _model.attemptRevisionFor(person.id);
    final name = person.firstName;
    bool samePerson() =>
        _browseOptionsPersonId == person.id &&
        revision == _uiRevision &&
        _model.canBrowse &&
        _model.canApplyPersonSafety(
          person.id,
          hide: true,
          expectedAttemptRevision: attempt,
          expectedSafetyRevision: safetyRevision,
          endCurrentJourney: false,
        );
    if (_ownedConfirmRoute != null || !samePerson()) return;
    setState(() => _browseOptionsOpen = false);
    if (await _confirmConceptAction(
      title: 'Hide $name?',
      body:
          '$name won’t appear in your Profiles again. You can show her again from Settings → Hidden and blocked.',
      primaryLabel: 'Hide profile',
      secondaryLabel: 'Keep profile',
      personName: name,
      peerIds: [person.id],
      sheetKey: const ValueKey('concept_browse_hide_confirmation'),
      primaryKey: const ValueKey('browse-hide-confirm'),
      secondaryKey: const ValueKey('browse-hide-cancel'),
      canCommit: samePerson,
    )) {
      _move(() {
        if (!_model.hide(person.id)) return;
        _markPrivacyDate(person.id);
        _pages.clear();
        _personId = null;
      });
    } else if (_allowed && samePerson()) {
      setState(() => _browseOptionsOpen = true);
    }
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
            unawaited(_confirmBrowseHide(person));
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

  bool _fixtureIsCurrent() =>
      _allowed &&
      identical(widget.fixture, _fixtureOwner) &&
      _fixtureAccount ==
          (ZyraAccountState.userId, ZyraAccountState.generation) &&
      ModalRoute.of(context)?.isCurrent == true;

  ZyraProfileVideoLoader? get _fixtureProfileVideoLoader =>
      identical(widget.fixture, _fixtureOwner) &&
          _fixtureOwner?.profileVideoLoader != null
      ? _loadFixtureProfileVideo
      : null;

  Future<ZyraProfileVideoPlayback?> _loadFixtureProfileVideo(
    String ownerId,
  ) async {
    if (!_fixtureIsCurrent()) return null;
    final video = await _fixtureOwner?.profileVideoLoader?.call(ownerId);
    return _fixtureIsCurrent() ? video : null;
  }

  void _peerDeparted() {
    if (!mounted) return;
    final person = _personId;
    final selectedPeerDeparted = person != null && _model.hasDeparted(person);
    final optionsPeer = _journeyOptionsPersonId;
    final options = optionsPeer != null && _model.hasDeparted(optionsPeer)
        ? _journeyOptionsRoute
        : null;
    final confirm = _confirmPeerIds.any(_model.hasDeparted)
        ? _ownedConfirmRoute
        : null;
    final keepDialog =
        (confirm == null && _ownedConfirmRoute != null) ||
        (options == null && _journeyOptionsRoute != null);

    setState(() {
      _purgeDepartedPreviewState();
      if (selectedPeerDeparted) {
        _personId = null;
        _message.clear();
        _timelinePreview = null;
        _bioGallery = null;
        _compatibilityRoute = null;
        _endedCompatibilityAttemptId = null;
        _paidGuardianAgreement = null;
        final addressed = _pages.indexWhere(
          const {
            'profile',
            'safety',
            'journey',
            'journey_options',
            'request_capacity',
            'timeline',
            'bio',
            'bio_locked',
            'journey_compatibility',
            'journey_compatibility_locked',
            'journey_guardians',
            'compatibility',
            'ended_archive',
            'ended_bio',
            'ended_guardians',
            'ended_restart',
            'ended_compatibility',
            'guardian_access_agreement',
            'guardian_network_profile',
            'guardian_introduce',
          }.contains,
        );
        if (addressed >= 0) _pages.removeRange(addressed, _pages.length);
      }
      final guardianPeer = _guardianJourneyId;
      if (guardianPeer != null && _model.hasDeparted(guardianPeer)) {
        _guardianJourneyId = null;
        _guardianJourneyAttemptRevision = null;
      }
      final guardianCompatibility = _guardianCompatibilityTarget;
      if (guardianCompatibility != null &&
          _model.hasDeparted(guardianCompatibility.subjectId)) {
        _guardianCompatibilityTarget = null;
        _pages.removeWhere(
          (page) =>
              page == 'guardian_compatibility' ||
              page == 'guardian_compatibility_upgrade',
        );
      }
      final expanded = _expandedJourneyOptionsId;
      if (expanded != null && _model.hasDeparted(expanded)) {
        _expandedJourneyOptionsId = null;
      }
      final ending = _capacityEndingId;
      if (ending != null && _model.hasDeparted(ending)) {
        _capacityEndingId = null;
      }
      final browsePeer = _browseOptionsPersonId;
      if (browsePeer != null && _model.hasDeparted(browsePeer)) {
        _browseOptionsOpen = false;
        _browseOptionsPersonId = null;
      }
      final capacity = _capacityRequest;
      if (capacity != null && !_capacityRequestAdmitted(capacity)) {
        _capacityRequest = null;
        _capacityEndingId = null;
        _pages.remove('request_capacity');
      }
      _myZyraFocusIndex = 0;
      if (!keepDialog) _uiRevision++;
      _circleScopeRevision++;
      _circleEntryView = null;
      _pendingMainUnreadOnEntry = null;
      _circleVisibility.value = _page == 'guardian_circle';
    });
    if (confirm != null && confirm.isActive) {
      confirm.navigator?.removeRoute(confirm, false);
    }
    if (options != null && options.isActive) {
      options.navigator?.removeRoute(options);
    }
    _publishCheckpoint();
  }

  void _purgeDepartedPreviewState() {
    final departed = draftProfiles
        .where((profile) => _model.hasDeparted(profile.id))
        .map((profile) => profile.id)
        .toSet();
    if (departed.isEmpty) return;
    _messages.removeWhere((id, _) => departed.contains(id));
    _browsePhotoIndices.removeWhere((id, _) => departed.contains(id));
    _browseGalleryIndices.removeWhere((id, _) => departed.contains(id));
    _seenBrowseProfileIds.removeAll(departed);
    _conceptNetworkSent.removeAll(departed);
    _browseHistory.reconcile(
      _browseHistory.ids.where((id) => !departed.contains(id)),
    );
    _myZyraConsumedFocusTokens.removeWhere(
      (token) => token.split(':').any(departed.contains),
    );
    bool departedChat(ZyraCirclePreviewMuteKey key) => departed.any(
      (id) => key.$3?.startsWith('draft-circle-attempt-$id-') ?? false,
    );
    _circleMuteKeys.removeWhere(departedChat);
    _circleSentMessages.removeWhere((key, _) => departedChat(key));
    _guardianTabs.introduced.removeWhere(
      (key) => departed.contains('draft-${key.split(':').last}'),
    );
  }

  void _fixtureChanged() {
    if (!_fixtureIsCurrent()) return;
    final next = _fixtureOwner?.readState?.call();
    final oldRole = _guardianRole;
    _move(() {
      if (next?.guardianRole case final guardian?) {
        _guardianRole = guardian;
        _tab = guardian ? 2 : 0;
        _pages.clear();
        _clearActivityFixture();
      }
      if (next?.tab case final tab?) {
        _tab = tab.clamp(0, 4);
        _pages.clear();
      }
      if (next?.requestsTab case final tab?) _requestsTab = tab.clamp(0, 2);
      if (next?.checkpoint case final checkpoint?) {
        _guardianRole = checkpoint.guardian;
        _restoreCheckpoint(checkpoint);
      }
      if (next?.wallet case final wallet?) _subscriptionWallet = wallet;
      if (next?.seekerMembership case final membership?) {
        _seekerMembership = membership == 'Seeker Basic'
            ? 'Seeker Basic'
            : 'Seeker One';
      }
      if (next?.guardianMembership case final membership?) {
        _guardianMembership = membership;
        if (!_hasGuardianCompatibilityPlan) {
          _subscriptionWallet = _subscriptionWallet.withRole(
            ZyraWalletRole.guardian,
            coverage: ZyraWalletCoverage.unavailable,
          );
        }
      }
      if (next?.membershipPaymentHistory case final history?) {
        _membershipPaymentHistory = history;
        _membershipDraft = _membershipDraft.copyWith(
          selectedProducts: _membershipDraft.selectedProducts.where(
            (product) => !ZyraMembershipCatalog.isBasic(product),
          ),
        );
        _membershipReview = null;
      }
      if (next?.replaceActivity == true) {
        _activityExample = next?.activityExample;
        _activityFixtureRevision++;
        _myZyraFocusIndex = 0;
      }
      if (next?.circleBubbleDesign case final design?) {
        _circleBubbleDesign.value = design;
      }
      if (next?.replaceTimeline == true) _timelinePreview = next?.timeline;
    }, preserveCircle: _page == 'guardian_circle');
    final circle = _currentCircleData();
    if (_page == 'guardian_circle') {
      _circleArrivals.value = circle;
    }
    if (oldRole != _guardianRole) widget.onRoleChanged?.call(_guardianRole);
  }

  @override
  void dispose() {
    _profilePrivacy.removeListener(_accountChanged);
    _profilePrivacy.dispose();
    _firstTourStore.close();
    _developerBridge?.detach(this);
    _inactivityLifecycle.dispose();
    _model.peerDepartures.removeListener(_peerDeparted);
    final confirmRoute = _ownedConfirmRoute;
    _ownedConfirmRoute = null;
    if (confirmRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (confirmRoute.isActive) {
          confirmRoute.navigator?.removeRoute(confirmRoute, false);
        }
      });
    }
    _fixtureOwner?.changes?.removeListener(_fixtureChanged);
    _guardianFamilyDeadline?.cancel();
    ZyraPreviewRouteObserver.navigationChanges.removeListener(_routeChanged);
    _location.removeListener(_locationChanged);
    _location.dispose();
    _noticeTimer?.cancel();
    _cancelTimeRuleTimer();
    _browsePhotoRenderer.dispose();
    _expansion.dispose();
    _scroll.removeListener(_publishCheckpoint);
    _scroll.dispose();
    _message.dispose();
    _accountSession.removeListener(_accountChanged);
    _accountSession.dispose();
    _signup?.dispose();
    if (widget.fixture?.compatibilityAccess == null &&
        widget.compatibilityAccess == null) {
      _compatibilityAccess.close();
    }
    _circleBubbleDesign.dispose();
    _circleVisibility.dispose();
    _circleArrivals.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _profilePrivacy.synchronizePlan(notify: false);
    _model.ownProfilePrivacy = _profilePrivacy;
    _syncLocationOrigins();
    _syncTimeRuleTimer();
    final navigationRouteStamp = _routeStamp;
    final navigationRevision = _uiRevision;
    final navigationGuardian = _guardianRole;
    final names = _guardianRole
        ? ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile']
        : ['Profiles', 'Journey', 'My ZYRA', 'Guardian', 'Profile'];
    const icons = [
      Icons.search,
      Icons.route_outlined,
      Icons.dashboard_outlined,
      Icons.gpp_good_outlined,
      Icons.person_outline,
    ];
    final fullPhoto = _isPhotoPage;
    final ownsViewport =
        _page == 'developer_inactivity_email' ||
        _page == null ||
        (_page == 'held_action' &&
            _guardianRole &&
            _heldTitle == 'Ended Journeys') ||
        fullPhoto ||
        [
          'filters',
          'filter_preferences',
          'preference_quick_check',
          'settings',
          'phone_access',
          'edit_profile',
          'manage_photos',
          'membership',
          'one_upgrade',
          'membership_review',
          'eid_gift_preview',
          'ramadan_draw_preview',
          'subscriptions',
          'journey',
          'journey_options',
          'bio',
          'bio_locked',
          'journey_compatibility',
          'journey_compatibility_locked',
          'guardian_compatibility',
          'guardian_compatibility_upgrade',
          'request_capacity',
          'journey_guardians',
          'ended_archive',
          'ended_bio',
          'ended_guardians',
          'ended_compatibility',
          'ended_restart',
          'guardian_access_agreement',
          'guardian_circle',
          'guardian_invite',
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
          'guardian_family_offer',
          'guardian_free_place_invite',
          'guardian_family_identity',
          'requests',
          'introductions',
          'saved',
          'paused',
          'ended',
          'own_profile_preview',
          'past_journeys',
          'switch_account_signup',
          'switch_account_setup',
          'signup',
          'compatibility',
          'timeline',
          'compatibility_store',
          'scan',
          'help_support',
          'help_contact',
          'help_contact_sent',
          'help_report_sent',
          'help_advanced',
          'help_data',
          'help_delete',
          'help_closed',
          'help_privacy',
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
      internalReview: _allowed,
    );
    final founderWhite = founderPending.isNotEmpty;
    final onCircle = _page == 'guardian_circle';
    final onJourneyOptions = _page == 'journey_options';
    if (onJourneyOptions) {
      _retainedJourneyOptions = _journeyOptionsPage();
    } else if (!_pages.contains('journey_options')) {
      _retainedJourneyOptions = null;
    }
    final leaves = onCircle || onJourneyOptions
        ? null
        : ownsViewport
        ? _content()
        : SafeArea(
            bottom: false,
            child: ZyraShadowScrollView(
              key: const ValueKey('draft_scroll'),
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                _quickAccessTabBar
                    ? ZyraNavBarMetrics.contentBottomClearance(context)
                    : 110,
              ),
              child: _content(),
            ),
          );
    final circle = onCircle
        ? _guardianCircle()
        : _pages.contains('guardian_circle') &&
              _circleEntryRevision == _circleScopeRevision
        ? _circleEntryView
        : null;
    final content = Stack(
      fit: StackFit.expand,
      children: [
        ?leaves,
        if (_retainedJourneyOptions case final options?)
          Offstage(
            key: const ValueKey('journey-options-parent'),
            offstage: !onJourneyOptions,
            child: TickerMode(
              enabled: onJourneyOptions,
              child: ExcludeFocus(excluding: !onJourneyOptions, child: options),
            ),
          ),
        if (circle != null)
          Offstage(
            key: const ValueKey('circle-topics-parent'),
            offstage: !onCircle,
            child: TickerMode(
              enabled: onCircle,
              child: ExcludeFocus(excluding: !onCircle, child: circle),
            ),
          ),
      ],
    );
    final bioGallery = _currentBioGallery;
    final rootContent = _bioGalleryEnabled
        ? ExcludeFocus(excluding: bioGallery != null, child: content)
        : content;
    return ZyraTapFeedback(
      level: () => _accountSession.hapticLevel,
      canAct: () => _allowed,
      child: Builder(
        key: _tapContextKey,
        builder: (context) => ZyraBackNavigationPreview(
          revision: _uiRevision,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: PopScope(
              canPop:
                  _firstTourIndex == null &&
                  !_firstTourPending &&
                  _locationSheet == 0 &&
                  _pages.isEmpty &&
                  !_browseOptionsOpen &&
                  _expandedJourneyOptionsId == null,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && _allowed) _back();
              },
              child: Scaffold(
                backgroundColor: ZyraColors.ivoryTop,
                extendBody: true,
                body: DecoratedBox(
                  decoration: BoxDecoration(
                    color: founderWhite ? ZyraColors.ivoryTop : null,
                    gradient: founderWhite
                        ? null
                        : _accountSession.palette.gradient,
                  ),
                  child: Stack(
                    key: _firstTourViewport,
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          if ((_pages.isNotEmpty ||
                                  _expandedJourneyOptionsId != null) &&
                              !_isRetainedAccountPage &&
                              _page != 'own_profile_preview' &&
                              _page != 'guardian_main_notice' &&
                              (_page != 'signup' || _addedRoleSignup != null))
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
                                  ? ZyraFounderLaunchPageStyle.darkGoldInk
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
                                  bioGallery == null &&
                                  _allowed &&
                                  !_browseOptionsOpen &&
                                  _ownedConfirmRoute == null,
                              onBack: _bound(() {
                                // A sheet can open before the parent rebuilds. Recheck
                                // current decision ownership at dispatch, not just build.
                                if (!_browseOptionsOpen &&
                                    !_journeyOptionsOpen &&
                                    !_capacityConfirmOpen &&
                                    _ownedConfirmRoute == null) {
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
                            PageStorage(bucket: _positions, child: rootContent),
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
                          else if (_showRootTabBar)
                            KeyedSubtree(
                              key: const ValueKey('concept_tour_navigation'),
                              child: ZyraShellNavigation(
                                key: ValueKey((
                                  'concept_root_navigation',
                                  _guardianRole,
                                )),
                                hapticLevel: _accountSession.hapticLevel,
                                contentEdgeInset: 20,
                                lockedTabBar: true,
                                interactionEnabled: _allowed,
                                items: [
                                  for (var i = 0; i < names.length; i++)
                                    FloatingNavItem(
                                      icon: icons[i],
                                      label: names[i],
                                      useJourneyGlyph: i == 1,
                                      dot:
                                          i == 2 &&
                                          (_guardianRole
                                              ? _hasGuardianMyZyraTabActivity
                                              : _hasNewMyZyraTabActivity),
                                    ),
                                ],
                                currentIndex: _tab,
                                onTap: (index) {
                                  if (_allowed &&
                                      navigationRevision == _uiRevision &&
                                      navigationGuardian == _guardianRole &&
                                      navigationRouteStamp == _routeStamp &&
                                      (ModalRoute.of(context)?.isCurrent ??
                                          false) &&
                                      !_browseOptionsOpen &&
                                      _showRootTabBar &&
                                      (index != _tab || _page != null)) {
                                    _tabTo(index);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                      if (_locationSheet != 0 && _locationFlowCurrent())
                        _locationOverlay(),
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
                      if (bioGallery != null)
                        Positioned.fill(
                          child: BlockSemantics(
                            child: FocusScope(
                              autofocus: true,
                              child: _journeyBioGallery(bioGallery),
                            ),
                          ),
                        ),
                      if (_firstTourPending)
                        const Positioned.fill(
                          child: AbsorbPointer(child: SizedBox.expand()),
                        ),
                      if (_firstTourIndex case final index?)
                        Positioned.fill(
                          child: ZyraFirstTourOverlay(
                            index: index,
                            guardian: _guardianRole,
                            firstName: _accountSession
                                .ownProfile(_guardianRole)
                                .firstName,
                            onNext: _bound(() {
                              if (_firstTourIndex == index) {
                                _showFirstTour(index + 1);
                              }
                            }),
                            onBack: _bound(() {
                              if (_firstTourIndex == index) {
                                _showFirstTour(index - 1);
                              }
                            }),
                            targetRect: _firstTourRect,
                            navBarTop: _firstTourBarTop,
                            canAct: () => _firstTourCurrent,
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
    );
  }

  Widget _content() => switch (_page) {
    'signup' => _signupView(),
    'developer_inactivity_email' => _developerEmail(),
    'profile' => _profileView(),
    'journey' => _journeyView(),
    'request_capacity' => _requestCapacityView(),
    'journey_compatibility' => _journeyCompatibility(),
    'guardian_compatibility' => _guardianCompatibilityReader(),
    'guardian_compatibility_upgrade' => _guardianCompatibilityUpgrade(),
    'journey_compatibility_locked' => _journeyDisclosureLocked(bio: false),
    'journey_guardians' => _journeyGuardians(),
    'ended_archive' => _endedJourneyArchive(),
    'ended_bio' => _endedJourneyDetail(bio: true),
    'ended_guardians' => _endedJourneyDetail(bio: false),
    'ended_restart' => _endedRestart(),
    'ended_compatibility' => _endedCompatibility(),
    'guardian_access_agreement' => _guardianAccessAgreement(),
    'guardian_invite' => _guardianInvite(),
    'guardian_info' => _guardianInfo(),
    'network_request' => _guardianTabsView('connect_confirm'),
    'guardian_introduce' => _guardianTabsView('introduce_confirm'),
    'guardian_family_offer' => _guardianTabsView('family_offer'),
    'guardian_free_place_invite' => _guardianFreePlaceInvite(),
    'guardian_family_identity' => _guardianFamilyIdentity(),
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
    'edit_profile' ||
    'manage_photos' ||
    'preference_quick_check' ||
    'filter_preferences' => _retainedAccountLeaf(),
    'membership' => _membershipView(),
    'one_upgrade' => ZyraOneUpgradePage(
      guardian: _guardianRole,
      strongBasicComparisonDisclosure: _guardianRole
          ? _guardianMembership == 'Guardian Basic'
          : _seekerMembership == 'Seeker Basic',
      founderPreview: true,
      seekerFirstName: _conceptGuardianJourney?.linkedSeekerName ?? 'Adam',
      includesPreviewComparisons: true,
      includesProfileVideo:
          identical(widget.fixture, _fixtureOwner) &&
          (_fixtureOwner?.profileVideoLoader != null ||
              _fixtureOwner?.profileVideoStore != null),
      canContinue: _accountFreshGuard(),
      childCanAct: _accountFreshGuard(allowOwnedChildRoute: true),
      onBack: _bound(_back),
    ),
    'membership_review' => _membershipReviewView(),
    'eid_gift_preview' || 'ramadan_draw_preview' => _offersView(),
    'subscriptions' => _subscriptionsView(),
    'bio' => _bio(),
    'bio_locked' => _journeyDisclosureLocked(bio: true),
    'compatibility' => _compatibilityInfo(),
    'compatibility_store' => _compatibilityStore(),
    'notifications' => _notificationsView(),
    'filters' => _filters(),
    'scan' => _scanEntry(),
    'help_support' => _helpSupport(),
    'help_contact' ||
    'help_contact_sent' ||
    'help_report_sent' ||
    'help_advanced' ||
    'help_data' ||
    'help_delete' ||
    'help_closed' ||
    'help_privacy' => _helpSafetyView(),
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

  VoidCallback _bound(VoidCallback action) {
    final revision = _uiRevision;
    final page = _page;
    final tab = _tab;
    final guardian = _guardianRole;
    return () {
      if (!_allowed ||
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

  Widget _helpSupport() {
    final fresh = _accountFreshGuard();
    return HelpSupportScreen.preview(
      canAct: fresh,
      categories: zyraHelpCategories,
      onContact: () {
        if (fresh()) _open('help_contact');
      },
    );
  }

  SeekerProfile _displayProfile(DraftProfile p) => SeekerProfile(
    id: p.id,
    firstName: p.firstName,
    surnameLine: _signupUnverified ? null : p.surname,
    age: p.age,
    city: _signupUnverified ? 'Verify to see' : p.city,
    publicNationality: zyraBrowseNationalityLabel(p.nationalityCode),
    publicEthnicity: zyraBrowseEthnicityLabel(p.ethnicityCode),
    seekerPlan: ZyraPlan.one,
    mainGuardianRelationship: 'Father',
    gender: 'female',
    photos: _photos?.forIndex(draftProfiles.indexOf(p)) ?? const [],
  );

  Widget _memberBrowsePhoto(
    BuildContext context,
    String source, {
    required double width,
    required double height,
    required Alignment alignment,
  }) {
    final photo = _browsePhotoRenderer.build(
      context,
      source,
      width: width,
      height: height,
      alignment: alignment,
    );
    if (!_signupUnverified) return photo;
    return ClipRect(
      key: const ValueKey('unverified_member_photo_frame'),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: photo,
      ),
    );
  }

  bool _hasSentInvitation(String id) => _hasDeveloperPreview
      ? _developerSamples.hasPreviewSent(id)
      : _model.stateFor(id) == DraftJourneyState.sent;

  bool _canToggleInvitation(String id) =>
      _profilePrivacy.canSendRequest &&
      !_guardianRole &&
      !_model.isBlocked(id) &&
      (_signupUnverified ||
          (_hasDeveloperPreview
              ? _hasSentInvitation(id) ||
                    (_developerSamples.setupUnfinished &&
                        _model.canRequest(id)) ||
                    _developerSamples.canSendPreviewRequest(id)
              : _hasSentInvitation(id) || _model.canRequest(id)));

  String _invitationLabel(String id) {
    if (_signupUnverified) return 'Verify to request a Journey';
    if (_hasDeveloperPreview) {
      if (_hasSentInvitation(id)) return 'Request sent';
      final cooldown = _developerSamples.previewRequestCooldown(id);
      if (cooldown != null && cooldown.isAfter(_previewNow)) {
        return 'Ask again from ${_requestDate(cooldown)}';
      }
      final state = _model.stateFor(id);
      return state == null || state == DraftJourneyState.sent
          ? 'Request a Journey'
          : _stateLabel(state);
    }
    final state = _model.stateFor(id);
    final cooldown =
        state == null &&
            !_guardianRole &&
            !_model.isHidden(id) &&
            !_model.isBlocked(id)
        ? _model.requestCooldownUntil(id)
        : null;
    return switch (state) {
      null =>
        cooldown == null
            ? 'Request a Journey'
            : 'Ask again from ${_requestDate(cooldown)}',
      DraftJourneyState.sent => 'Request sent',
      DraftJourneyState.acceptedWaiting =>
        'Accepted · waiting for confirmation',
      DraftJourneyState.ended => 'Journey archived',
      final state => _stateLabel(state),
    };
  }

  bool get _basicRequestPlan => _seekerMembership == 'Seeker Basic';

  ZyraSeekerPlanLimits get _requestPlanLimits =>
      _basicRequestPlan ? ZyraSeekerPlanLimits.basic : ZyraSeekerPlanLimits.one;

  int get _sentRequestsWaiting =>
      {
        ..._model.waitingSentProfileIds,
        if (_hasDeveloperPreview) ..._developerSamples.waitingSentProfileIds,
      }.length +
      (widget.fixture?.seededWaitingRequests ?? 0);

  Widget _sentCount() => ZyraSentRequestCount(
    key: const ValueKey('lock48_sent_waiting'),
    waiting: _sentRequestsWaiting,
    cap: _requestPlanLimits.waitingRequests,
  );

  bool _admitWaitingRequest(BuildContext origin) {
    final ownsForeground =
        origin.mounted &&
        ModalRoute.isCurrentOf(origin) == true &&
        ModalRoute.of(context)?.isActive == true &&
        (_allowed || widget.canActInOwnedDialog?.call() == true);
    if (!ownsForeground ||
        _guardianRole ||
        !_profilePrivacy.canSendRequest ||
        _waitingRequestsSheetOpen) {
      return false;
    }
    if (_requestPlanLimits.hasWaitingRequestSpace(_sentRequestsWaiting)) {
      return true;
    }
    unawaited(_showWaitingRequestsFull(origin));
    return false;
  }

  Future<void> _showWaitingRequestsFull(BuildContext origin) async {
    _waitingRequestsSheetOpen = true;
    final cap = _requestPlanLimits.waitingRequests;
    final basic = _basicRequestPlan;
    final owner = (ZyraAccountState.userId, ZyraAccountState.generation);
    final revision = _uiRevision;
    final originRoute = ModalRoute.of(origin);
    final shellRoute = ModalRoute.of(context);
    bool sameOwner() =>
        mounted &&
        !_guardianRole &&
        revision == _uiRevision &&
        owner == (ZyraAccountState.userId, ZyraAccountState.generation);
    try {
      final choice = await showModalBottomSheet<ZyraRequestLimitChoice>(
        context: origin,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x611E1610),
        builder: (sheet) {
          _waitingRequestsSheetRoute = ModalRoute.of(sheet);
          bool current() =>
              sheet.mounted &&
              sameOwner() &&
              ModalRoute.of(sheet)?.isCurrent == true &&
              (widget.canActInOwnedDialog?.call() ?? _allowed);
          void select(ZyraRequestLimitChoice? value) {
            if (current()) Navigator.of(sheet).pop(value);
          }

          return ZyraTapFeedback(
            level: () => _accountSession.hapticLevel,
            canAct: current,
            child: ZyraRequestsFullSheet(
              cap: cap,
              basic: basic,
              onSent: () => select(ZyraRequestLimitChoice.sent),
              onUpgrade: () => select(ZyraRequestLimitChoice.upgrade),
              onDismiss: () => select(null),
            ),
          );
        },
      );
      if (choice == null ||
          !origin.mounted ||
          !sameOwner() ||
          originRoute?.isCurrent != true) {
        return;
      }
      if (originRoute != shellRoute) {
        Navigator.of(origin).pop();
      }
      if (!_allowed || !sameOwner() || shellRoute?.isCurrent != true) return;
      switch (choice) {
        case ZyraRequestLimitChoice.sent:
          _activity('requests', requestsTab: 1);
        case ZyraRequestLimitChoice.upgrade:
          _open('one_upgrade');
      }
    } finally {
      _waitingRequestsSheetOpen = false;
      _waitingRequestsSheetRoute = null;
    }
  }

  void _toggleInvitation(String id) {
    if (!_allowed ||
        !_profilePrivacy.canSendRequest ||
        !_canToggleInvitation(id)) {
      return;
    }
    if (_signupUnverified) {
      _verifyDeveloperIdentity();
      return;
    }
    if (_signupIncomplete && !_hasSentInvitation(id)) {
      setState(
        () => _notice = 'Finish setting up your profile to start a Journey.',
      );
      return;
    }
    if (!_hasSentInvitation(id) && !_admitWaitingRequest(_tapContext)) return;
    if (_hasDeveloperPreview) {
      if (_developerSamples.setupUnfinished && !_hasSentInvitation(id)) {
        setState(
          () => _notice = 'Finish setting up your profile to start a Journey.',
        );
      } else {
        _seenBrowseProfileIds.add(id);
        _developerSamples.togglePreviewRequest(id);
      }
      return;
    }
    _act(() {
      _seenBrowseProfileIds.add(id);
      if (_hasSentInvitation(id)) {
        _model.cancel(id);
      } else {
        _model.request(id);
      }
    });
  }

  int? _browseSelectionIndex(
    List<DraftProfile> people, {
    required bool seekerBasic,
  }) {
    if (people.isEmpty) {
      _browseHistory.reset();
      return null;
    }
    final fallback =
        ((_browseIndex % people.length) + people.length) % people.length;
    if (seekerBasic &&
        !people.any((person) => person.id == _browseHistory.currentId)) {
      final next = !_seenBrowseProfileIds.contains(people[fallback].id)
          ? fallback
          : _nextUnseenBrowseIndex(people, fallback);
      if (next == null) {
        _browseHistory.reset();
        return null;
      }
      _browseHistory.reconcile(people.map((person) => person.id));
      _browseHistory.discardForwardReplay();
      _browseHistory.appendFrontier(people[next].id);
      return _browseIndex = next;
    }
    _browseHistory.reconcile(
      people.map((person) => person.id),
      fallbackId: people[fallback].id,
    );
    final current = people.indexWhere(
      (person) => person.id == _browseHistory.currentId,
    );
    return _browseIndex = current < 0 ? fallback : current;
  }

  int? _nextUnseenBrowseIndex(List<DraftProfile> people, int current) {
    // Scan once in the existing deck order. The last unseen visit ends the
    // track, even when more eligible people are retained in viewing history.
    for (var offset = 1; offset < people.length; offset++) {
      final candidate = (current + offset) % people.length;
      if (!_seenBrowseProfileIds.contains(people[candidate].id)) {
        return candidate;
      }
    }
    return null;
  }

  void _showBrowseVisit(int index, String id) {
    _browseIndex = index;
    _browsePhotoIndices[id] = 0;
    _browseGalleryIndices[id] = 0;
    _seenBrowseProfileIds.add(id);
  }

  Future<void> _openBrowseBackSheet() async {
    var expectedStamp = _routeStamp;
    final fresh = _accountFreshGuard(
      expectedNavigatorStamp: () => expectedStamp,
    );
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final revision = _uiRevision;
    bool basicBrowse() =>
        mounted &&
        revision == _uiRevision &&
        account == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        !_guardianRole &&
        _tab == 0 &&
        _page == null &&
        _model.canBrowse &&
        _seekerMembership == 'Seeker Basic';
    if (_browseBackSheetOpen || !fresh() || !basicBrowse()) return;
    _browseBackSheetOpen = true;
    var consumed = false;
    try {
      final pending = showModalBottomSheet<bool>(
        context: _tapContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x611E1610),
        sheetAnimationStyle:
            MediaQuery.disableAnimationsOf(context) ||
                MediaQuery.accessibleNavigationOf(context)
            ? AnimationStyle.noAnimation
            : null,
        builder: (sheetContext) {
          bool current() =>
              sheetContext.mounted &&
              !consumed &&
              basicBrowse() &&
              expectedStamp == _routeStamp &&
              ModalRoute.of(sheetContext)?.isCurrent == true &&
              (widget.canActInOwnedDialog?.call() ?? _allowed);
          void choose(bool upgrade) {
            if (!current()) return;
            consumed = true;
            Navigator.of(sheetContext).pop(upgrade);
            expectedStamp = _routeStamp;
          }

          return ZyraTapFeedback(
            level: () => _accountSession.hapticLevel,
            canAct: current,
            child: ZyraBrowseBackUpgradeSheet(
              onUpgrade: () => choose(true),
              onDismiss: () => choose(false),
            ),
          );
        },
      );
      expectedStamp = _routeStamp;
      if (await pending == true && fresh() && basicBrowse()) {
        _open('one_upgrade');
      }
    } finally {
      _browseBackSheetOpen = false;
      if (_allowed) setState(() {});
    }
  }

  Widget _discover() {
    if (_profilePrivacy.paused) {
      final current = _bound(() {
        if (_profilePrivacy.showProfile()) {
          _act(() => _notice = 'Your profile is visible again.');
        }
      });
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            ZyraNavBarMetrics.contentBottomClearance(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mainHeading('Profiles'),
              Expanded(child: ZyraPausedProfilesCard(onShowProfile: current)),
            ],
          ),
        ),
      );
    }
    final people = _activeBrowseFilter
        .apply(_model.discoverableProfiles)
        .where(
          (person) => !_developerSamples.isSampleProfileExcluded(person.id),
        )
        .toList(growable: false);
    final seekerBasic = _seekerMembership == 'Seeker Basic';
    final clearance = ZyraNavBarMetrics.contentBottomClearance(context);
    if (!_model.canBrowse) {
      return SafeArea(
        bottom: false,
        child: ZyraShadowScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, clearance),
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
    final now = _previewNow;
    final viewed = _profilesWindow.countAt(now);
    final refillAt = _profilesWindow.activeAt(now)
        ? _profilesWindow.refillAt!
        : now.add(ZyraSeekerBasicPolicy.swipeWindow);
    final refillTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(refillAt.toLocal())).toLowerCase();
    final limitBar = seekerBasic
        ? ZyraProfilesLimitBar(
            key: const ValueKey('lock48_profiles_count'),
            count: viewed,
            refillTime: refillTime,
          )
        : null;
    if (seekerBasic && ZyraSeekerBasicPolicy.swipeLimitReached(viewed)) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, clearance),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: ZyraTabTitle('Profiles')),
                  ZyraBrowseOptionsButton(
                    profile: null,
                    alignToContentEdge: true,
                    onOpen: (_) => _openBrowseOptions(null),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              limitBar!,
              const SizedBox(height: 14),
              Expanded(
                child: ZyraProfilesLimitCard(
                  key: const ValueKey('lock48_profiles_refill'),
                  refillTime: refillTime,
                  onUpgrade: _bound(() => _open('one_upgrade')),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final index = _browseSelectionIndex(people, seekerBasic: seekerBasic);
    if (index == null) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, clearance),
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
                            message: _activeBrowseFilter.isValid
                                ? 'Try widening your filters. Occupied profiles stay out of this view.'
                                : 'The selected distance origin is unavailable. Clear the radius or reset your filters.',
                          ),
                          const SizedBox(height: 20),
                          _button(
                            'concept_clear_filters',
                            'Clear filters',
                            () => _act(() {
                              _browseFilter = _keepingSavedOneFilters(
                                const ZyraBrowseFilter(),
                                _browseFilter,
                              );
                              _editingBrowseFilter = _browseFilter;
                              _browseIndex = 0;
                              if (!seekerBasic) _browseHistory.reset();
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
    final history = _browseHistory.ids;
    final cursor = _browseHistory.cursor;
    final previous = !seekerBasic && _browseHistory.canBack
        ? people.indexWhere((person) => person.id == history[cursor - 1])
        : null;
    final replays = !seekerBasic && _browseHistory.hasForwardReplay;
    final next = replays
        ? people.indexWhere((person) => person.id == history[cursor + 1])
        : _nextUnseenBrowseIndex(people, index);
    final revision = _uiRevision;
    final navigatorStamp = _routeStamp;
    final displayed = _displayProfile(people[index]);
    bool current() =>
        _allowed &&
        revision == _uiRevision &&
        navigatorStamp == _routeStamp &&
        !_guardianRole &&
        _tab == 0 &&
        _page == null &&
        _model.canBrowse &&
        _browseHistory.currentId == displayed.id;
    // Record actual exposure after rendering, including filter selections.
    // Refresh the visible count without changing the current selection.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!current()) return;
      final newVisit = _seenBrowseProfileIds.add(displayed.id);
      var recorded = false;
      if (seekerBasic && _seekerMembership == 'Seeker Basic') {
        final exposedAt = _previewNow;
        if (!_profilesWindow.activeAt(exposedAt)) {
          _profilesWindow = ZyraPreviewBrowseWindow(startedAt: exposedAt);
        }
        recorded = _profilesWindow.record(displayed.id, exposedAt);
        if (recorded) setState(() {});
      }
      if (newVisit || recorded) _publishCheckpoint();
    });
    return ZyraProfileVideoAccess(
      ownerId: displayed.id,
      load: _fixtureProfileVideoLoader,
      builder: (context, video) => ZyraOneJourneyBrowseDesigns(
        key: ValueKey(('prepared-browse', _photos != null)),
        profileVideo: video,
        verifyPhotosPill: _signupUnverified,
        profileSwipe: (
          previousIndex: previous,
          nextIndex: next,
          onBlockedPrevious: seekerBasic ? _openBrowseBackSheet : null,
          canAct: () =>
              current() && !_browseOptionsOpen && !_browseBackSheetOpen,
        ),
        profiles: people.map(_displayProfile).toList(growable: false),
        selectedIndex: index,
        design: _browseDesign,
        photoBuilder: _memberBrowsePhoto,
        initialGalleryIndices: _browseGalleryIndices,
        onPhotoIndexChanged: _rememberPhoto,
        onGalleryIndexChanged: _rememberGallery,
        alignHeaderActions: true,
        hapticLevel: _accountSession.hapticLevel,
        bottomPadding: ZyraNavBarMetrics.contentBottomClearance(context),
        fixedTabFooter: true,
        headerAccessory: limitBar,
        headerAccessoryHeight: limitBar?.heightFor(context) ?? 0,
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
          } else if (current() && profile.id == displayed.id) {
            _openBrowseOptions(profile.id);
          }
        },
        onPrevious: previous == null
            ? null
            : _bound(
                () => _act(() {
                  final id = _browseHistory.back();
                  if (id != null) _showBrowseVisit(previous, id);
                }),
              ),
        onNext: next == null
            ? null
            : _bound(
                () => _act(() {
                  final id = people[next].id;
                  if (replays) {
                    _browseHistory.forwardReplay();
                  } else {
                    _browseHistory.discardForwardReplay();
                    _browseHistory.appendFrontier(id);
                  }
                  _showBrowseVisit(next, id);
                }),
              ),
        canRequest: (profile) => _canToggleInvitation(profile.id),
        requestLabel: (profile) => _invitationLabel(profile.id),
        requestSemanticLabel: (profile) => _hasSentInvitation(profile.id)
            ? 'Request sent. Tap to cancel request'
            : _invitationLabel(profile.id),
        invitationSent: (profile) => _hasSentInvitation(profile.id),
        // Photo browsing stays inside the approved bounded card.
        onProfile: null,
        onCompatibility: (profile) {
          if (current() && profile.id == displayed.id) {
            _open('compatibility', person: profile.id);
          }
        },
        onRequest: (profile) {
          if (!current() || profile.id != displayed.id) {
            ZyraInteractionStyle.cancelSelectionTap();
            return;
          }
          _toggleInvitation(profile.id);
        },
      ),
    );
  }

  Widget _profileView() {
    final p = _person;
    if (p == null) return _unavailable();
    if (_model.isBlocked(p.id) ||
        _developerSamples.isSampleProfileExcluded(p.id)) {
      return _userNotFoundView();
    }
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
    final fresh = _accountFreshGuard();
    bool current() =>
        fresh() &&
        _page == 'profile' &&
        _personId == p.id &&
        !_model.isBlocked(p.id) &&
        !_developerSamples.isSampleProfileExcluded(p.id);
    final owner = (ZyraAccountState.userId, ZyraAccountState.generation);
    final revision = _uiRevision;
    bool presentBehindLimitSheet() =>
        mounted &&
        _waitingRequestsSheetRoute?.isCurrent == true &&
        owner == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        revision == _uiRevision &&
        !_guardianRole &&
        _page == 'profile' &&
        _personId == p.id &&
        !_model.isBlocked(p.id) &&
        !_developerSamples.isSampleProfileExcluded(p.id) &&
        (widget.canActInOwnedDialog?.call() ?? _allowed);
    final state = _model.stateFor(p.id);
    final situation = _signupUnverified
        ? ZyraFullProfileSituation.unverified
        : state == DraftJourneyState.preparing ||
              state == DraftJourneyState.active
        ? ZyraFullProfileSituation.journey
        : state == DraftJourneyState.received
        ? ZyraFullProfileSituation.received
        : state == DraftJourneyState.sent || _hasSentInvitation(p.id)
        ? ZyraFullProfileSituation.sent
        : ZyraFullProfileSituation.general;
    return ZyraFullProfilePreview(
      key: ValueKey(('full-profile', p.id, _uiRevision)),
      profile: _displayProfile(p),
      situation: situation,
      photoBuilder: _memberBrowsePhoto,
      canAct: current,
      canPresentBackdrop: presentBehindLimitSheet,
      initialPage: _browseGalleryIndices[p.id] ?? 0,
      onPageChanged: (index) {
        if (current()) _rememberGallery(p.id, index);
      },
      onCompatibility: () {
        if (current()) _open('compatibility', person: p.id);
      },
      onAction: () {
        if (!current()) return;
        switch (situation) {
          case ZyraFullProfileSituation.journey:
            _journey(p.id);
          case ZyraFullProfileSituation.received:
            _back();
            _accept(p, true);
          case ZyraFullProfileSituation.unverified:
            _verifyDeveloperIdentity();
          case ZyraFullProfileSituation.general:
            _toggleInvitation(p.id);
          case ZyraFullProfileSituation.sent ||
              ZyraFullProfileSituation.introduction:
            break;
        }
      },
      onSecondary: situation == ZyraFullProfileSituation.received
          ? () {
              if (!current()) return;
              _back();
              _act(() => _result(_model.declineReceived(p.id)));
            }
          : null,
      onOption: (option) {
        if (!current()) return;
        if (option == ZyraFullProfileOption.report) {
          _open('safety', person: p.id);
          return;
        }
        final hide = option == ZyraFullProfileOption.hide;
        if (_warnBeforePersonSafety(p, hide: hide, canAct: current)) return;
        _move(() {
          final changed = hide ? _model.hide(p.id) : _model.block(p.id);
          if (!changed) return;
          if (_developerSamples.hasSamples) {
            if (hide) {
              _developerSamples.hideSampleProfile(p);
            } else {
              _developerSamples.blockSampleProfile(p);
            }
          }
          _markPrivacyDate(p.id);
          if (_pages.isNotEmpty) _pages.removeLast();
          _notice = hide
              ? 'Hidden. You can show them again in Settings → Hidden and blocked.'
              : 'Blocked. They can no longer see you or contact you.';
        });
      },
    );
  }

  bool _isCurrentHiddenInspection(String id, {bool ownedModal = false}) =>
      (ownedModal || _allowed) &&
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
    bool current() => fresh() && _isCurrentHiddenInspection(person.id);
    final first = _button(
      'concept_hidden_inspection_unhide',
      'Unhide profile',
      () {
        if (!current()) return;
        _move(() {
          if (_model.unhide(person.id)) {
            _privacyDates.remove(person.id);
            _pages.removeLast();
          }
        });
      },
      primary: true,
    );
    final second = _button(
      'concept_hidden_inspection_block',
      'Block profile',
      () async {
        if (!current() ||
            _warnBeforePersonSafety(person, hide: false, canAct: current)) {
          return;
        }
        final safetyRevision = _model.personSafetyRevision;
        final attempt = _model.attemptRevisionFor(person.id);
        if (await _confirmConceptAction(
          title: 'Block ${person.firstName}?',
          body: 'You won’t see each other again. They won’t be told.',
          personName: person.firstName,
          primaryLabel: 'Block profile',
          secondaryLabel: 'Keep profile',
          peerIds: [person.id],
          sheetKey: const ValueKey('concept_hidden_inspection_block_prompt'),
          primaryKey: const ValueKey('concept_hidden_inspection_confirm_block'),
          secondaryKey: const ValueKey('concept_hidden_inspection_cancel'),
          canCommit: () =>
              _isCurrentHiddenInspection(person.id, ownedModal: true) &&
              _model.canApplyPersonSafety(
                person.id,
                hide: false,
                expectedAttemptRevision: attempt,
                expectedSafetyRevision: safetyRevision,
                endCurrentJourney: false,
              ),
        )) {
          _move(() {
            if (_model.block(person.id)) {
              _markPrivacyDate(person.id);
              _pages.removeLast();
            }
          });
        }
      },
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
        _routeStamp,
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
      onEndUnavailable: () => dispatch(() {
        if (person != null && _model.isBlocked(person.id)) {
          _confirmJourneyEnd(person);
        }
      }),
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
    bool quickAccess = false,
    bool consumeFocus = true,
  }) {
    if (!_allowed ||
        _guardianRole ||
        !const {'requests', 'introductions', 'ended'}.contains(page) ||
        requestsTab < 0 ||
        requestsTab > 2) {
      return;
    }
    if (quickAccess && !_activityRoot) return;
    final viewedId = viewedReceivedRequestId;
    if (viewedId != null &&
        (page != 'requests' ||
            requestsTab != 0 ||
            !_activityRoot ||
            !_profileIds.contains(viewedId) ||
            _model.isBlocked(viewedId) ||
            !_model.hasUnseenReceivedRequest(viewedId) ||
            !_visibleRequests(
              DraftJourneyState.received,
            ).any((person) => person.id == viewedId))) {
      return;
    }
    _move(() {
      if (consumeFocus) {
        _consumeFocusTarget(
          page == 'requests' && requestsTab == 2 ? 'requests_past' : page,
        );
      }
      // Opening an addressed highlight consumes only that item's attention,
      // never its pending request. Generic list entry remains unacknowledged.
      if (viewedId != null) _model.acknowledgeReceivedRequests([viewedId]);
      _tab = 2;
      _requestsTab = requestsTab;
      _expansion.collapseAll();
      _pages
        ..clear()
        ..add(page);
      _myZyraQuickAccessPage = quickAccess ? page : null;
    });
  }

  Widget _activityPage(String title, List<Widget> content) =>
      ZyraRequestActivityPresentation(
        key: ValueKey('concept_activity_$_page'),
        wrapTitle: (title) => ZyraDeveloperTitle(child: title),
        title: title,
        labels: [title],
        pages: [content],
        tabClearance: _quickAccessTabBar,
        selectedIndex: 0,
        onChanged: (_) {},
      );

  Widget _requestActivity() {
    final revision = _uiRevision;
    if (_hasDeveloperPreview &&
        (_developerSamples.receivedRows != null ||
            _developerSamples.sentRows != null ||
            _developerSamples.history != null)) {
      return ZyraDeveloperJourneyRequestsScreen(
        tabClearance: _quickAccessTabBar,
        initialTab: _requestsTab,
        sentCount: _sentCount,
        additionalSent: () => _draftPendingRestartCards(
          () =>
              _allowed &&
              revision == _uiRevision &&
              !_guardianRole &&
              _tab == 2 &&
              _page == 'requests' &&
              _requestsTab == 1,
        ),
        onTabChanged: (tab) {
          if (_allowed) _requestsTab = tab;
        },
        wrapTitle: (title) => ZyraDeveloperTitle(child: title),
      );
    }
    return ZyraRequestActivityPresentation(
      key: const ValueKey('concept_activity_requests'),
      wrapTitle: (title) => ZyraDeveloperTitle(child: title),
      canInteract: () =>
          _allowed &&
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
      tabClearance: _quickAccessTabBar,
      selectedIndex: _requestsTab,
      onChanged: (i) {
        if (!_allowed ||
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

  Widget _introductionsActivity() {
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    bool current() =>
        fresh() &&
        revision == _uiRevision &&
        !_guardianRole &&
        _page == 'introductions';
    return _hasDeveloperPreview && _developerSamples.introductionRows != null
        ? ZyraSampleIntroductionsList(
            tabClearance: _quickAccessTabBar,
            wrapTitle: (title) => ZyraDeveloperTitle(child: title),
            admitRequest: _admitWaitingRequest,
          )
        : ZyraRequestActivityPresentation(
            key: const ValueKey('concept_activity_introductions'),
            wrapTitle: (title) => ZyraDeveloperTitle(child: title),
            title: 'Introductions',
            tabClearance: _quickAccessTabBar,
            selectedTabFill: ZyraColors.frostSelectedFill,
            labels: const ['Received', 'Past'],
            pages: const [
              [
                ZyraRequestActivityEmpty(
                  icon: Icons.groups_outlined,
                  title: 'No introductions yet',
                  message:
                      'People your Guardians put forward will appear here.',
                ),
              ],
              [
                ZyraRequestActivityEmpty(
                  icon: Icons.history_outlined,
                  title: 'No past introductions.',
                  message:
                      'Introductions you declined or took forward stay here.',
                ),
              ],
            ],
            selectedIndex: _requestsTab.clamp(0, 1),
            canInteract: current,
            onChanged: (index) {
              if (current()) {
                _act(() => _requestsTab = index);
              }
            },
          );
  }

  Widget _historyActivity() => _activityPage('Ended Journeys', _history());

  ZyraOneJourneyConnectionsAction _connectionAction(
    String key,
    String label,
    IconData? icon,
    VoidCallback? action, {
    bool fitLabel = false,
    bool dangerLabel = false,
  }) => ZyraOneJourneyConnectionsAction(
    key: ValueKey(key),
    label: label,
    icon: icon,
    fitLabel: fitLabel,
    dangerLabel: dangerLabel,
    onTap: action == null ? null : _bound(action),
  );

  String _requestDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]}';
  }

  String _pastRequestStatus(DraftPastRequest entry) => switch (entry.outcome) {
    DraftPastRequestOutcome.notTakenUp => 'Not taken up',
    DraftPastRequestOutcome.cancelled => 'Cancelled',
    DraftPastRequestOutcome.youDeclined => 'You declined',
    DraftPastRequestOutcome.youLetItGo => 'You let it go',
  };

  List<Widget> _pastRequests() {
    // Insertion order preserves the most recent Past transition for each pair
    // and direction. Each group's entries keep the same newest-first order.
    final groups = <(String, bool), List<DraftPastRequest>>{};
    for (final entry in _model.pastRequests) {
      if (_model.isBlocked(entry.profileId)) continue;
      (groups[(entry.profileId, entry.incoming)] ??= []).add(entry);
    }
    if (groups.isEmpty) {
      return const [
        ZyraRequestActivityEmpty(
          icon: Icons.history_outlined,
          title: 'No past requests.',
          message:
              'Requests that were declined, expired or cancelled stay here.',
        ),
      ];
    }
    final revision = _uiRevision;
    final fresh = _accountFreshGuard();
    return [
      for (final group in groups.values)
        _pastRequestCard(
          group,
          canInteract: () =>
              fresh() &&
              revision == _uiRevision &&
              !_guardianRole &&
              _tab == 2 &&
              _page == 'requests' &&
              _requestsTab == 2 &&
              !_model.isBlocked(group.first.profileId) &&
              !_model.hasDeparted(group.first.profileId),
        ),
    ];
  }

  Widget _pastRequestCard(
    List<DraftPastRequest> group, {
    required bool Function() canInteract,
  }) {
    final latest = group.first;
    final person = draftProfiles.firstWhere(
      (person) => person.id == latest.profileId,
    );
    final profile = _displayProfile(person);
    final date = _requestDate(latest.requestedAt);
    final status = _pastRequestStatus(latest);
    if (group.length == 1) {
      return ZyraPastRequestActivityCard(
        profile: profile,
        subtitle: '${latest.incoming ? 'Received' : 'Sent'} $date',
        status: status,
        cardId: 'past_request_${latest.id}',
      );
    }
    final direction = latest.incoming ? 'received' : 'sent';
    final cardId = 'past_request_${latest.profileId}_$direction';
    final askAgain = _model.pastRequestAskAgainAfter(latest);
    return ZyraPastRequestActivityCard(
      key: ValueKey(cardId),
      profile: profile,
      subtitle: 'Last $direction $date · ${group.length} requests',
      status: status,
      cardId: cardId,
      controller: _expansion,
      canInteract: canInteract,
      history: [
        for (final entry in group)
          (
            date: 'Sent ${_requestDate(entry.requestedAt)}',
            status: _pastRequestStatus(entry),
          ),
      ],
      askAgain: askAgain == null
          ? null
          : 'You can ask ${person.firstName} again from ${_requestDate(askAgain)}.',
    );
  }

  List<Widget> _draftPendingRestartCards(bool Function() current) => [
    for (final p in draftProfiles)
      if (_model.restartExpiresAt(p.id) != null && !_model.isBlocked(p.id))
        ZyraRequestActivityCard(
          controller: _expansion,
          profile: _displayProfile(p),
          subtitle: 'Waiting for a response',
          cardId: 'lock48_restart_${p.id}',
          canInteract: current,
          onToggle: _bound(() {
            if (!current()) return;
            final id = 'lock48_restart_${p.id}';
            if (_expansion.value == id) {
              _expansion.close(id);
            } else {
              _expansion.open(id);
            }
          }),
          primary: _connectionAction(
            'lock48_restart_profile_${p.id}',
            'View profile',
            Icons.visibility_outlined,
            _bound(() {
              if (current() && _model.restartExpiresAt(p.id) != null) {
                _open('profile', person: p.id);
              }
            }),
          ),
          actions: [
            ZyraOneJourneyConnectionsAction(
              label: 'Cancel request',
              icon: Icons.close,
              onTap: _bound(() {
                if (current()) _act(() => _model.cancelRestart(p.id));
              }),
            ),
          ],
        ),
  ];

  List<Widget> _requests(int tab) {
    final revision = _uiRevision;
    final fresh = _accountFreshGuard();
    bool current() =>
        fresh() &&
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
    final restartCards = tab == 1
        ? _draftPendingRestartCards(current)
        : <Widget>[];
    if (people.isEmpty && restartCards.isEmpty) {
      return [
        if (tab == 1) _sentCount(),
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
      if (tab == 1) _sentCount(),
      ...restartCards,
      for (final p in people)
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
                    dangerLabel: true,
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
      if (_model.confirmWaitingRequest(
        p.id,
        mainGuardianId: _conceptMainGuardianId,
      )) {
        _personId = p.id;
        _pages.add('journey');
      }
    });
  }

  void _openAcceptedCapacity(String id) {
    if (!_allowed ||
        _guardianRole ||
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
    int revision, {
    bool ownedModal = false,
  }) =>
      (ownedModal || _allowed) &&
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
    final endingAttempt = _model.snapshot().attemptRevisions[ending.id];
    final intent = _model.acceptanceIntentRevision(request.id);
    bool sameSelection() =>
        _model.acceptanceIntentRevision(request.id) == intent &&
        _currentCapacityRequest(request, revision, ownedModal: true) &&
        _capacityEndingId == ending.id &&
        _model.stateFor(ending.id) == endingState &&
        _model.snapshot().attemptRevisions[ending.id] == endingAttempt &&
        _model.canReplaceJourneyForRequest(
          request.id,
          ending.id,
          incoming: request.incoming,
        );
    if (!_allowed || _capacityConfirmOpen || !sameSelection()) return;
    final target = _person!;
    final endingName = _model.isBlocked(ending.id)
        ? 'the unavailable Journey'
        : 'your Journey with ${ending.firstName}';
    _capacityConfirmOpen = true;

    try {
      if (!await _confirmConceptAction(
        title: 'End Journey & accept request?',
        body:
            'This permanently ends $endingName. Your history stays. '
            'You and ${target.firstName} can then prepare to begin together.',
        personName: _model.isBlocked(ending.id) ? null : ending.firstName,
        icon: Icons.route_outlined,
        primaryLabel: request.incoming
            ? 'End & accept request'
            : 'End & begin with ${target.firstName}',
        secondaryLabel: 'Keep my Journeys',
        peerIds: [ending.id, target.id],
        primaryKey: const ValueKey('request_capacity_confirm'),
        secondaryKey: const ValueKey('request_capacity_keep'),
        canCommit: sameSelection,
      )) {
        return;
      }
      _act(() {
        final replaced = _model.replaceJourneyForRequest(
          request.id,
          ending.id,
          incoming: request.incoming,
          mainGuardianId: _conceptMainGuardianId,
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

  bool _journeyCardOptionsContext(String id) =>
      !_guardianRole &&
      !_model.isBlocked(id) &&
      ((_tab == 1 &&
              _page == null &&
              _currentJourneys.any((person) => person.id == id)) ||
          (_endedHistoryRoot &&
              (_page == 'ended' || _page == 'past_journeys') &&
              _model.stateFor(id) == DraftJourneyState.ended));

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
        if (!ended) _confirmJourneyEnd(person);
    }
  }

  bool _attachJourneyOptionsRoute(BuildContext context, String id) {
    final route = ModalRoute.of(context);
    _journeyOptionsRoute = route;
    if (!_model.hasDeparted(id)) return true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route != null && route.isActive) route.navigator?.removeRoute(route);
    });
    return false;
  }

  Future<void> _openJourneyOptions(DraftProfile person) async {
    if (!_allowed || _guardianRole || _journeyOptionsOpen) return;
    final state = _model.stateFor(person.id);
    if (state == null) return;
    final attempt = _model.attemptRevisionFor(person.id);
    var expectedStamp = _routeStamp;
    final fresh = _accountFreshGuard(
      expectedNavigatorStamp: () => expectedStamp,
    );
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final revision = _uiRevision;
    // The owned sheet makes its parent route non-current. Capture only its
    // display state while the parent is current; the returned intent still
    // rechecks fresh ownership and the live disclosure gate after dismissal.
    final canViewBio = _canViewJourneyBio(person.id);
    final canViewCompatibility = _canViewJourneyCompatibility(person.id);
    _journeyOptionsOpen = true;
    _journeyOptionsPersonId = person.id;
    try {
      final pending = showModalBottomSheet<ZyraConceptJourneyOption>(
        context: _tapContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black38,
        builder: (sheetContext) {
          if (!_attachJourneyOptionsRoute(sheetContext, person.id)) {
            return const SizedBox.shrink();
          }
          final route = ModalRoute.of(sheetContext);
          bool ownsSheet() =>
              sheetContext.mounted &&
              identical(_journeyOptionsRoute, route) &&
              route?.isCurrent == true &&
              revision == _uiRevision &&
              expectedStamp == _routeStamp &&
              account ==
                  (ZyraAccountState.userId, ZyraAccountState.generation) &&
              (widget.canActInOwnedDialog?.call() ?? _allowed);
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
            ),
            child: ZyraTapFeedback(
              level: () => _accountSession.hapticLevel,
              canAct: ownsSheet,
              child: ZyraConceptJourneyOptions(
                id: person.id,
                firstName: person.firstName,
                canViewBio: canViewBio,
                canViewCompatibility: canViewCompatibility,
                canEnd: state != DraftJourneyState.ended,
                onSelected: (value) {
                  if (!ownsSheet()) return;
                  Navigator.pop(sheetContext, value);
                  expectedStamp = _routeStamp;
                },
                onCancel: () {
                  if (ownsSheet()) Navigator.pop(sheetContext);
                },
              ),
            ),
          );
        },
      );
      expectedStamp = _routeStamp;
      final choice = await pending;
      if (!fresh() ||
          choice == null ||
          _model.stateFor(person.id) != state ||
          _model.attemptRevisionFor(person.id) != attempt) {
        return;
      }
      _selectJourneyOption(person, choice);
    } finally {
      _journeyOptionsOpen = false;
      _journeyOptionsPersonId = null;
      _journeyOptionsRoute = null;
    }
  }

  Future<void> _confirmJourneyEnd(DraftProfile person) async {
    final id = person.id;
    final state = _model.stateFor(id);
    final attempt = _model.attemptRevisionFor(id);
    final blocked = _model.isBlocked(id);
    bool sameJourney() =>
        !_guardianRole &&
        state != null &&
        state != DraftJourneyState.ended &&
        _model.stateFor(id) == state &&
        _model.attemptRevisionFor(id) == attempt &&
        _model.isBlocked(id) == blocked;
    if (!await _confirmConceptAction(
      title: blocked ? 'End this Journey?' : 'End with ${person.firstName}?',
      body:
          'This Journey ends for both of you and cannot be reopened. '
          'Your Timeline stays.',
      personName: blocked ? null : person.firstName,
      icon: Icons.route_outlined,
      primaryLabel: 'End Journey',
      secondaryLabel: 'Keep this Journey',
      peerIds: [id],
      sheetKey: ValueKey('draft_journey_action_$id'),
      primaryKey: ValueKey('draft_confirm_end_$id'),
      secondaryKey: ValueKey('draft_cancel_journey_action_$id'),
      canCommit: sameJourney,
    )) {
      return;
    }
    _act(() {
      final ok = _model.end(id, mainGuardianId: _conceptMainGuardianId);
      _result(ok);
      if (ok) _message.clear();
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
    if (result == null && _seekerMembership == 'Seeker One') {
      return _pageScroll([
        _heading('Compatibility score', ''),
        _card([
          _eyebrow('COMPATIBILITY REVEAL COMPLETE'),
          _title('Your result', size: 25),
          _body('You both chose to reveal. Your result is not available yet.'),
        ]),
      ]);
    }
    final attempt = _model.attemptRevisionFor(person.id);
    final areaGate = _seekerCompatibilityAreaGate(
      person,
      canView: () =>
          _model.attemptRevisionFor(person.id) == attempt &&
          _canViewJourneyCompatibility(person.id),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: ZyraDraftCompatibilityPresentation(
          key: ValueKey(('draft_journey_compatibility', person.id, attempt)),
          personName: person.firstName,
          balance: _compatibilityAccess.balance,
          overallScore:
              result?.overallScore ??
              ZyraDraftCompatibilityPreview(person.id, balance: 0).overallScore,
          revealed: true,
          areaGate: areaGate,
          areaBands: areaGate == null ? result?.areaBands : null,
        ),
      ),
    );
  }

  ZyraCompatibilityAreaGate? _seekerCompatibilityAreaGate(
    DraftProfile person, {
    required bool Function() canView,
  }) {
    if (_seekerMembership != 'Seeker Basic' ||
        _compatibilityAccess.isUnlocked(person.id)) {
      return null;
    }
    final fresh = _accountFreshGuard();
    bool current() =>
        fresh() &&
        !_guardianRole &&
        _seekerMembership == 'Seeker Basic' &&
        _personId == person.id &&
        canView() &&
        !_compatibilityAccess.isUnlocked(person.id);
    final balance = _compatibilityAccess.balance;
    return ZyraCompatibilityAreaGate(
      guardian: false,
      balance: balance,
      canAct: current,
      onUnlock: () {
        if (!current() || _compatibilityAccess.balance == 0) return;
        _act(() {
          if (_compatibilityAccess.unlock(person.id)) {
            _notice = 'Every area is now open for ${person.firstName}.';
          }
        });
      },
      onBuyMore: () {
        if (current()) _open('compatibility_store');
      },
      onUpgrade: () {
        if (current()) _open('one_upgrade');
      },
    );
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
                            // member navigation at the screen edge.
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

  List<Widget> _history() {
    final rows = _hasDeveloperPreview ? _developerSamples.endedRows : null;
    if (rows != null && rows.isNotEmpty) {
      return [
        for (final row in rows)
          ZyraSampleEndedJourneyCard(
            row: row,
            controller: _expansion,
            admitRestart: _admitWaitingRequest,
            onViewArchive: _bound(() {
              if (_allowed &&
                  _endedHistoryRoot &&
                  (_developerSamples.endedRows?.contains(row) ?? false)) {
                _sampleEndedArchiveAttemptId = row.id;
                _open('ended_archive', person: row.person.id);
              }
            }),
          ),
      ];
    }
    if (rows != null) {
      return const [
        ZyraRequestActivityEmpty(
          icon: Icons.history_outlined,
          title: 'No ended Journeys',
          message: "When a Journey ends, it's kept here with its Timeline.",
        ),
      ];
    }
    final people = _visibleRequests(DraftJourneyState.ended);
    return people.isEmpty
        ? [
            ZyraRequestActivityEmpty(
              icon: Icons.history_outlined,
              title: 'No ended Journeys',
              message: "When a Journey ends, it's kept here with its Timeline.",
            ),
          ]
        : [for (final p in people) _endedJourneyCard(p)];
  }

  Widget _endedJourneyCard(DraftProfile person) {
    final id = person.id;
    final attempt = _model.currentEndedAttemptFor(id);
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    final page = _page;
    bool current() =>
        fresh() &&
        revision == _uiRevision &&
        page == _page &&
        _canAddressEndedJourney(id) &&
        attempt != null &&
        _model.currentEndedAttemptFor(id)?.id == attempt.id;
    return ZyraRequestActivityCard(
      profile: _displayProfile(person),
      subtitle: 'Journey ended · Timeline kept',
      cardId: 'ended_$id',
      controller: _expansion,
      headerKey: ValueKey('draft_journey_${id}_header'),
      canInteract: current,
      onToggle: () {
        if (!current()) return;
        if (_expansion.value == 'ended_$id') {
          _expansion.close('ended_$id');
        } else {
          _expansion.open('ended_$id');
        }
      },
      primary: _connectionAction(
        'draft_ended_view_$id',
        'View Timeline',
        Icons.history_outlined,
        () {
          if (current()) {
            _sampleEndedArchiveAttemptId = null;
            _open('ended_archive', person: id);
          }
        },
      ),
      actions: [
        _connectionAction(
          'draft_ended_restart_$id',
          'Request a new Journey',
          Icons.people_outline,
          _canRequestEndedRestart(id)
              ? () {
                  if (current()) _open('ended_restart', person: id);
                }
              : null,
        ),
        _connectionAction(
          'draft_ended_remove_$id',
          'Remove from my Journeys',
          Icons.close,
          () {
            if (current()) _removeEndedJourney(person);
          },
          dangerLabel: true,
        ),
      ],
    );
  }

  Future<void> _removeEndedJourney(DraftProfile person) async {
    final id = person.id;
    if (!_canAddressEndedJourney(id)) return;
    final attempt = _model.currentEndedAttemptFor(id);
    if (attempt == null) return;
    final owner = (ZyraAccountState.userId, ZyraAccountState.generation);
    final revision = _uiRevision;
    final page = _page;
    bool currentAttempt() =>
        mounted &&
        owner == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        revision == _uiRevision &&
        page == _page &&
        _endedHistoryRoot &&
        _model.hasVisibleEndedJourney(id) &&
        _model.currentEndedAttemptFor(id)?.id == attempt.id;
    final confirmed = await _confirmConceptAction(
      title: 'Remove this Journey?',
      body:
          'It disappears from your Ended Journeys for good, with its '
          'Timeline and messages. You can’t undo this. ${person.firstName} still sees her copy.',
      primaryLabel: 'Remove Journey',
      secondaryLabel: 'Keep Journey',
      personName: person.firstName,
      peerIds: [id],
      icon: Icons.info_outline,
      canCommit: currentAttempt,
    );
    if (!confirmed) return;
    _act(() {
      if (_model.removeEndedJourney(id, attempt.id)) {
        _expansion.collapseAll();
        _notice = 'Removed from your Journeys.';
      }
    });
  }

  Widget _endedJourneyArchive() {
    final sample = _sampleEndedFor(_personId);
    if (sample != null && _canAddressEndedArchive(_personId)) {
      final fresh = _accountFreshGuard();
      final revision = _uiRevision;
      final lease = _developerSamples.generation;
      return ZyraSampleEndedJourneyArchive(
        row: sample,
        tabClearance: _quickAccessTabBar,
        wrapTitle: (title) => ZyraDeveloperTitle(child: title),
        canInteract: () =>
            fresh() &&
            revision == _uiRevision &&
            _page == 'ended_archive' &&
            _personId == sample.person.id &&
            _developerSamples.isCurrentLease(lease) &&
            _sampleEndedFor(sample.person.id) == sample,
      );
    }

    if (_sampleEndedArchiveAttemptId != null) return _unavailable();
    final person = _person;
    if (person == null || !_canAddressEndedJourney(person.id)) {
      return _unavailable();
    }
    final id = person.id;
    final attempt = _model.currentEndedAttemptFor(id)?.id;
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    bool current() =>
        fresh() &&
        revision == _uiRevision &&
        _page == 'ended_archive' &&
        _personId == id &&
        _canAddressEndedJourney(id) &&
        attempt != null &&
        _model.currentEndedAttemptFor(id)?.id == attempt;
    void open(String page) {
      if (current()) _open(page, person: id);
    }

    return ZyraEndedJourneyArchivePresentation(
      key: ValueKey('draft_ended_archive_$id'),
      profile: _displayProfile(person),
      keyPrefix: 'draft_ended',
      wrapTitle: (title) => ZyraDeveloperTitle(child: title),
      canInteract: current,
      tabClearance: _quickAccessTabBar,
      onTimeline: () => open('timeline'),
      onBio: () => open('ended_bio'),
      onGuardians: () => open('ended_guardians'),
    );
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
          galleryButton: _journeyBioGalleryButton(person),
        ),
      );
    }
    return _pageScroll([
      _heading(bio ? 'Journey Bio' : 'Guardians', ''),
      _card([
        _title(
          bio ? 'Not shared in this Journey' : 'No saved Guardian details',
          size: 23,
        ),
        _body(
          bio
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
    final expiresAt = _model.restartExpiresAt(person.id);
    final eligible =
        _seekerMembership == 'Seeker One' &&
        _model.isRecentEndedJourney(person.id);
    final canSend = eligible && _model.canRequestEndedJourney(person.id);
    final fresh = _accountFreshGuard();
    return ZyraRequestRestartPreview(
      key: ValueKey('draft_ended_restart_${person.id}'),
      name: person.firstName,
      subjectId: person.id,
      sent: expiresAt != null,
      unavailableReason: expiresAt != null || canSend
          ? null
          : eligible
          ? 'You can ask 24 hours after the Journey ends. The request lasts 30 days.'
          : 'Restart requests are not available in this preview.',
      onRequest: () {
        if (!fresh() ||
            !canSend ||
            _seekerMembership != 'Seeker One' ||
            !_canRequestEndedRestart(person.id) ||
            !_model.canRequestEndedJourney(person.id)) {
          return;
        }
        if (_signupUnverified) {
          _tabTo(0);
          return;
        }
        if (_signupIncomplete) {
          _act(
            () =>
                _notice = 'Finish setting up your profile to start a Journey.',
          );
          return;
        }
        if (!_admitWaitingRequest(_tapContext)) return;
        _act(() {
          if (_model.requestEndedJourney(person.id)) {
            _notice =
                'Request sent. ${person.firstName} will see it in ${_displayProfile(person).gender.toLowerCase() == 'female' ? 'her' : 'his'} requests.';
          }
        });
      },
    );
  }

  Widget _journeyView() {
    final p = _person;
    if (p == null) return _unavailable();
    if (_model.stateFor(p.id) == null) {
      final close = _model.latestReadyCloseFor(p.id);
      if (close == null) return _unavailable();
      final askAgain = _model.pastRequestAskAgainAfter(close);
      return _pageScroll([
        _card([
          _title('Not taken up', size: 23),
          if (askAgain != null)
            _body(
              'You can ask again after ${askAgain.difference(close.movedAt).inDays} days.',
            ),
        ]),
      ]);
    }
    if (_model.isBlocked(p.id)) return _userNotFoundView();
    if (_model.stateFor(p.id) == DraftJourneyState.ended) {
      return _model.hasVisibleEndedJourney(p.id)
          ? _archiveView(p)
          : _unavailable();
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
                  child: ZyraDeveloperTitle(
                    child: Text(
                      'Journey with ${p.firstName}',
                      textAlign: TextAlign.center,
                      style: ZyraText.heading(size: 16),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('concept_journey_timeline'),
                  tooltip: 'Timeline',
                  onPressed: _tap(_bound(() => _open('timeline'))),
                  icon: const Icon(Icons.history_outlined),
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
              child: ZyraDeveloperTitle(
                child: Text(
                  'Journey with ${person.firstName}',
                  textAlign: TextAlign.center,
                  style: ZyraText.heading(size: 16),
                ),
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
    final beginRouteStamp = _routeStamp;
    void begin() {
      if (!freshBegin() ||
          beginRouteStamp != _routeStamp ||
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
              _model.isReady(id) &&
                      _model.readyReminderAt(id, forPeer: true) != null
                  ? 'Waiting for ${p.firstName}'
                  : '${p.firstName}: ${_model.peerIsReady(id) ? 'ready' : 'waiting'}',
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
          _button('draft_end_$id', 'End Journey', () => _confirmJourneyEnd(p)),
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
        selfAvatarAlignment: _accountData.avatarAlignment,
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
              selfAvatarAlignment: _accountData.avatarAlignment,
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
                  fillColor: ZyraColors.ivoryTop,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Your answer…',
                  hintStyle: TextStyle(color: ZyraColors.secondaryText),
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
      }.contains(_model.stateFor(id)) &&
      (_model.stateFor(id) != DraftJourneyState.ended ||
          _model.hasVisibleEndedJourney(id));

  ZyraDraftTimelinePreview _makeTimelinePreview(DraftProfile person) =>
      widget.fixture?.timeline?.call(person.id) ??
      ZyraDraftTimelinePreview(
        person.id,
        firstName: person.firstName,
        journeyState: _model.stateFor(person.id),
        stageValue: _model.stageFor(person.id)?.value,
        compatibilityRevealed: _model.compatibilityRevealed(person.id),
        endedAttempts: _model
            .endedAttemptsFor(person.id)
            .where(_model.canSeeEndedAttempt)
            .toList(),
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
    final navigatorStamp = _routeStamp;
    bool current() =>
        fresh() &&
        navigatorStamp == _routeStamp &&
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
    final routeStamp = _routeStamp;
    bool sameSet(Set<String> a, Set<String> b) =>
        a.length == b.length && a.containsAll(b);
    bool current() =>
        agreement != null &&
        fresh() &&
        !_guardianRole &&
        _page == 'guardian_access_agreement' &&
        _personId == agreement.personId &&
        revision == _uiRevision &&
        routeStamp == _routeStamp &&
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

  void _dismissWelcomeBack() {
    if (_welcomeBackAt == null) return;
    _welcomeBackAt = null;
    _myZyraFocusIndex = 0;
  }

  void _resumeInactivityNotice() {
    if (!_backgroundedSinceReturn) return;
    _backgroundedSinceReturn = false;
    final at = _allowed && !_guardianRole
        ? _model.recordInactivityReturn()
        : null;
    if (_welcomeBackAt == null && at == null) return;
    setState(() {
      _welcomeBackAt = at;
      _myZyraFocusIndex = 0;
    });
    _publishCheckpoint();
  }

  void _clearActivityFixture() {
    _activityExample = null;
    _activityFixtureRevision++;
  }

  bool _activityItemVisible(ZyraMyZyraActivityItem item) =>
      item.personId == null ||
      (_profileIds.contains(item.personId) &&
          !_model.isBlocked(item.personId!) &&
          !_model.hasDeparted(item.personId!));

  String _receivedFocusToken(String id) =>
      'received:$id:${_model.receivedRequestRevision(id)}';

  List<ZyraFocusEvent> _focusEvents({bool includeConsumed = false}) {
    final native = _nativeFocusEvents(includeConsumed: includeConsumed);
    return _developerFocusEvents(native, includeConsumed: includeConsumed) ??
        native;
  }

  List<ZyraFocusEvent> _nativeFocusEvents({bool includeConsumed = false}) {
    final events = <ZyraFocusEvent>[
      if (_welcomeBackAt case final at? when !_guardianRole)
        ZyraFocusEvent(
          tokens: ['welcome-back:${at.microsecondsSinceEpoch}'],
          target: 'welcome_back',
          title: 'Welcome back, ${_accountSession.ownProfile(false).firstName}',
          detail:
              'You were away for a while. Your Ended Journeys are kept — nothing was removed.',
          action: 'View Ended Journeys',
          icon: Icons.history_outlined,
          occurredAt: at,
        ),
      for (final notice in _model.departureNotices.entries)
        ZyraFocusEvent(
          tokens: ['departure:${notice.key}'],
          target: 'journey_tab',
          title: 'One of your Journeys has ended',
          detail:
              'This profile is no longer active. Your place is free for a new Journey.',
          action: 'Open Journey',
          icon: Icons.history_outlined,
          occurredAt: notice.value,
          order: notice.key,
        ),
    ];
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
      for (final person in _currentJourneys) {
        final at = _model.readyReminderAt(person.id);
        if (at == null) continue;
        events.add(
          ZyraFocusEvent(
            tokens: [
              'ready:${person.id}:${_model.attemptRevisionFor(person.id)}',
            ],
            target: 'ready',
            personId: person.id,
            occurredAt: at,
            title: 'Your Journey with ${person.firstName} is waiting',
            detail: "Tap I'm ready to begin within 24 hours to start.",
            action: "I'm ready to begin",
            icon: Icons.schedule,
          ),
        );
      }
      final circle = _currentCircleData();
      if (circle != null &&
          circle.validFor(circle.seekerId, viewerIsSeeker: true)) {
        for (final message in _circleAttention(circle)) {
          events.add(
            ZyraFocusEvent(
              tokens: ['circle:${_circleMessageKey(circle, message)}'],
              target: 'guardian_circle',
              title: 'New message in Guardian Circle',
              detail:
                  '${message.senderFirstName} has added to your Circle conversation.',
              action: 'Open Circle',
              icon: Icons.forum_outlined,
              occurredAt: message.createdAt,
            ),
          );
        }
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
            icon: Icons.history_outlined,
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
                .map((x) => 'fixture:$_activityFixtureRevision:${x.id}')
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
              tokens: ['fixture:$_activityFixtureRevision:${item.id}'],
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
                'ended' => Icons.history_outlined,
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
      if (a.target != b.target) {
        if (a.target == 'welcome_back') return -1;
        if (b.target == 'welcome_back') return 1;
      }
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
    if (!_activityRoot || !_allowed) return;
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
      case 'welcome_back':
        _activity('ended', quickAccess: true, consumeFocus: false);
      case 'request_capacity':
        if (id != null) _openAcceptedCapacity(id);
      case 'ready':
        if (id != null && _model.readyReminderAt(id) != null) {
          _act(() => _model.markReady(id));
          if (_model.isReady(id)) _journey(id);
        }
      case 'journey':
        if (id != null && _currentJourneys.any((p) => p.id == id)) _journey(id);
      case 'journey_tab':
        _tabTo(1);
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
    final developerPreset = _hasDeveloperPreview
        ? _developerSamples.preset
        : null;
    final incoming = _hasDeveloperPreview
        ? _developerSamples.received ??
              _visibleRequests(
                DraftJourneyState.received,
              ).where((p) => _model.hasUnseenReceivedRequest(p.id)).length
        : _visibleRequests(
            DraftJourneyState.received,
          ).where((p) => _model.hasUnseenReceivedRequest(p.id)).length;
    final sent = _hasDeveloperPreview
        ? _developerSamples.sent ??
              _visibleRequests(DraftJourneyState.sent).length
        : _visibleRequests(DraftJourneyState.sent).length;
    final ended = _hasDeveloperPreview
        ? _developerSamples.ended ??
              _visibleRequests(DraftJourneyState.ended).length
        : _visibleRequests(DraftJourneyState.ended).length;
    final introductions = _hasDeveloperPreview
        ? _developerSamples.introductions ??
              events.where((event) => event.target == 'introductions').length
        : events.where((event) => event.target == 'introductions').length;
    final fresh = _accountFreshGuard();
    final revision = _uiRevision,
        routes = _routeStamp,
        epoch = _activityFixtureRevision;
    bool current() =>
        fresh() &&
        _activityRoot &&
        revision == _uiRevision &&
        routes == _routeStamp &&
        epoch == _activityFixtureRevision;
    VoidCallback action(VoidCallback callback) => () {
      if (!current()) {
        ZyraInteractionStyle.cancelSelectionTap();
        return;
      }
      callback();
    };
    final setup =
        _subscriptionWallet.forRole(ZyraWalletRole.seeker).readiness ==
        ZyraWalletReadiness.ready;
    return ZyraFocusPermissionStatus(
      canAct: () => _allowed && _activityRoot,
      builder: (notificationsAllowed) => FutureBuilder(
        future: _accountSession.compatibility.load('draft-self'),
        builder: (context, snapshot) {
          final preferences = ZyraCompatibilityDraft.fromSnapshot(
            gender: _accountSession.ownProfile(false).gender,
            snapshot: snapshot.data,
          );
          final set = preferences.preferenceAnswerCount,
              total = preferences.preferenceOptionCount;
          return ZyraFocusDashboard(
            canInteract: current,
            initialIndex: _myZyraFocusIndex,
            onIndexChanged: (index) => action(() {
              _myZyraFocusIndex = index;
              _publishCheckpoint();
            })(),
            items: [
              ..._seasonalOfferFocus(current),
              if (_signupIncomplete)
                _signupFocus(
                  action(() {
                    unawaited(_resumeSignup());
                  }),
                ),
              if (!_guardianRole &&
                  _accountSession.compatibility.hasPreferencesToCheck &&
                  developerPreset == null)
                ZyraFocusItem(
                  id: 'preference-quick-check',
                  icon: Icons.check,
                  title: 'A few preferences need a quick check',
                  detail:
                      'The amber light now means “Open to this”. Tap each one again so it counts.',
                  actionLabel: 'Check now',
                  actionKey: 'focus-open-preference-quick-check',
                  onAction: action(() => _open('preference_quick_check')),
                ),
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
              if (_signupIncomplete || (developerPreset == null && !setup))
                ZyraFocusChip(
                  id: 'focus-setup',
                  label: 'Finish setup',
                  icon: Icons.person_outline,
                  onTap: action(() {
                    if (_signupIncomplete) {
                      unawaited(_resumeSignup());
                    } else {
                      _walletSetup(ZyraWalletRole.seeker);
                    }
                  }),
                ),
              if (developerPreset == ZyraDeveloperPreset.newMember ||
                  developerPreset == ZyraDeveloperPreset.everything ||
                  (developerPreset == null && _conceptGuardianPeople.isEmpty))
                ZyraFocusChip(
                  id: 'focus-guardian',
                  label: 'No Guardian yet',
                  icon: Icons.verified_user_outlined,
                  onTap: action(() => _tabTo(3)),
                ),
              if (developerPreset != ZyraDeveloperPreset.newMember &&
                  (developerPreset != null || setup))
                ZyraFocusChip(
                  id: 'focus-places',
                  label:
                      '${_model.occupiedCount} of ${_model.capacity} ${_model.capacity == 1 ? 'place' : 'places'} in use',
                  icon: Icons.people_outline,
                  onTap: action(() => _tabTo(1)),
                ),
              if ((developerPreset == null && notificationsAllowed == false) ||
                  developerPreset == ZyraDeveloperPreset.typicalDay ||
                  developerPreset == ZyraDeveloperPreset.newMember ||
                  developerPreset == ZyraDeveloperPreset.everything)
                ZyraFocusChip(
                  id: 'focus-notifications-off',
                  label: 'Notifications off',
                  icon: Icons.notifications_none,
                  onTap: action(() {
                    _open('settings');
                    _open('phone_access');
                  }),
                ),
              if (developerPreset == ZyraDeveloperPreset.typicalDay ||
                  developerPreset == ZyraDeveloperPreset.everything ||
                  (developerPreset == null && set < total))
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
                onTap: action(() => _activity('requests', quickAccess: true)),
              ),
              ZyraFocusTile(
                id: 'concept-my-introductions',
                label: 'Introductions',
                status: introductions > 0 ? '$introductions new' : 'None yet',
                isNew: introductions > 0,
                icon: Icons.groups_outlined,
                onTap: action(
                  () => _activity('introductions', quickAccess: true),
                ),
              ),
              ZyraFocusTile(
                id: 'concept-my-ended',
                label: 'Ended\nJourneys',
                status: ended > 0 ? '$ended ended' : 'None',
                icon: Icons.history_outlined,
                onTap: action(() => _activity('ended', quickAccess: true)),
              ),
              ZyraFocusTile(
                id: 'focus-notifications',
                label: 'Notifications',
                status: events.isNotEmpty
                    ? '${events.length} new'
                    : 'Nothing new',
                isNew: events.isNotEmpty,
                icon: Icons.notifications_none,
                onTap: action(() => _openMyZyraQuickPage('notifications')),
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

  final _conceptRemovedGuardians = <String>{};
  final _conceptGuardianHistory = <String, bool>{};
  final _conceptNetworkSent = <String>{};

  ZyraProfileSmallPageSample? get _profileSmallPageSample =>
      widget.fixture?.profileSmallPageSample ??
      (_hasDeveloperPreview ? _developerSamples.profileSmallPage : null);

  bool get _conceptHassanLinked =>
      (!_guardianRole ||
          _profileSmallPageSample !=
              ZyraProfileSmallPageSample.guardianNoSeekers) &&
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
    final end = DateTime.utc(2026, 10, 10).subtract(Duration(days: index * 15));
    final start = end.subtract(const Duration(days: 21));
    return _circlePastSummaryLabel(names[index], start, end);
  }

  String _circlePastSummaryLabel(String name, DateTime start, DateTime end) {
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
    final startLabel = start.month == end.month && start.year == end.year
        ? '${start.day}'
        : start.year == end.year
        ? '${start.day} ${months[start.month - 1]}'
        : '${start.day} ${months[start.month - 1]} ${start.year}';
    return 'Adam & $name · $startLabel–${end.day} ${months[end.month - 1]} ${end.year}';
  }

  Map<
    String,
    ({ZyraCircleDiscussionTopic topic, DateTime startedAt, int photo})
  >
  _circlePastTopics(bool guardian) {
    final pastShared =
        !guardian ||
        (_guardianTabs.main &&
            _conceptHassanLinked &&
            _conceptGuardianHistory['draft-guardian-hassan'] == true);
    const pastExamples = [
      (name: 'Elif', peer: null),
      (name: 'Noor', peer: 'draft-noor'),
      (name: 'Hafsa', peer: null),
      (name: 'Zainab', peer: 'draft-zainab'),
      (name: 'Huda', peer: null),
      (name: 'Safiya', peer: 'draft-safiya'),
      (name: 'Mariam', peer: null),
      (name: 'Amina', peer: null),
      (name: 'Khadija', peer: null),
      (name: 'Sumayya', peer: null),
      (name: 'Layla', peer: null),
      (name: 'Yasmin', peer: null),
    ];
    if (!pastShared) return {};
    final past =
        <
          String,
          ({ZyraCircleDiscussionTopic topic, DateTime startedAt, int photo})
        >{};
    for (final (index, example) in pastExamples.indexed) {
      if (example.peer != null && _model.hasDeparted(example.peer!)) continue;
      final id = 'draft-circle-past-$index';
      final end = DateTime.utc(
        2026,
        10,
        10,
      ).subtract(Duration(days: index * 15));
      past[id] = (
        topic: ZyraCircleDiscussionTopic(
          id: id,
          firstName: example.name,
          kind: ZyraCircleTopicKind.past,
          sharedSummaryLabel: guardian ? _sharedPastJourneyLabel(index) : null,
          endedOn: end,
        ),
        startedAt: end.subtract(const Duration(days: 21)),
        photo: index,
      );
    }
    for (final (index, person) in draftProfiles.indexed) {
      for (final attempt in _model.endedAttemptsFor(person.id)) {
        final id = attempt.circleChatId;
        if (id == null ||
            !attempt.hasRecordedEnd(_previewNow) ||
            !_model.canSeeEndedAttempt(attempt) ||
            (guardian &&
                !attempt.guardiansWithView.contains('draft-guardian-hassan'))) {
          continue;
        }
        final end = attempt.endedAt!;
        final start = attempt.startedAt ?? end;
        past[id] = (
          topic: ZyraCircleDiscussionTopic(
            id: id,
            firstName: person.firstName,
            kind: ZyraCircleTopicKind.past,
            sharedSummaryLabel: guardian
                ? _circlePastSummaryLabel(person.firstName, start, end)
                : null,
            endedOn: end,
          ),
          startedAt: start,
          photo: index,
        );
      }
    }
    return past;
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
    final mainChatId = ZyraCircleDiscussionTopic.mainChatId(circleSeekerId);
    final currentChatIds = <String, String>{
      for (final context in contexts)
        context.referenceId: ?_model.circleChatIdFor(context.referenceId),
    };
    final journeyTopics = {
      for (final context in contexts.where(
        (context) => currentChatIds.containsKey(context.referenceId),
      ))
        currentChatIds[context.referenceId]!: ZyraCircleDiscussionTopic(
          id: currentChatIds[context.referenceId]!,
          firstName: context.firstName,
          kind: ZyraCircleTopicKind.current,
        ),
      for (final entry in _circlePastTopics(guardian).entries)
        entry.key: entry.value.topic,
    };
    final circleSeekerName = circleYusuf ? 'Yusuf' : 'Adam';
    final fixtureOwnsCircle =
        identical(widget.fixture, _fixtureOwner) &&
        _fixtureAccount ==
            (ZyraAccountState.userId, ZyraAccountState.generation);
    final departedIds = <String>{
      if (!circleYusuf)
        for (final person in draftProfiles)
          if (_model.hasDeparted(person.id)) person.id,
    };
    final arrivalsFor = _fixtureOwner?.circleArrivalsFor;
    final arrived = <ZyraFamilyMessage>[];
    final messageTopics = <String, ZyraCircleDiscussionTopic>{};
    if (arrivalsFor != null && fixtureOwnsCircle) {
      final senderIds = {circleSeekerId, ...people.map((p) => p.id)};
      final seen = {'draft-circle-welcome', 'draft-circle-response'};
      for (final message in arrivalsFor(circleSeekerId, senderId)) {
        if (message.senderId == senderId ||
            !senderIds.contains(message.senderId) ||
            message.lifecycle ||
            message.id.startsWith('draft-circle-sent-') ||
            seen.contains(message.id)) {
          continue;
        }
        final context = message.context;
        var chatId = mainChatId;
        if (context != null) {
          final arrivalKey =
              '$circleSeekerId:$senderId:${context.referenceId}:${message.id}:${message.senderId}';
          // Older fixture deliveries addressed the profile. Resolve it once,
          // so replay after a restart cannot relabel an earlier delivery.
          final legacyId = context.kind == ZyraFamilyMessageContextKind.active
              ? currentChatIds[context.referenceId]
              : null;
          final topic =
              journeyTopics[context.referenceId] ??
              (context.kind == ZyraFamilyMessageContextKind.active &&
                      _profileIds.contains(context.referenceId)
                  ? journeyTopics[_circleArrivalChatIds[arrivalKey] ?? legacyId]
                  : null);
          if (topic == null ||
              topic.firstName != context.firstName ||
              (context.kind != ZyraFamilyMessageContextKind.active &&
                  context.kind != ZyraFamilyMessageContextKind.ended) ||
              (context.kind == ZyraFamilyMessageContextKind.ended &&
                  !topic.isPast)) {
            continue;
          }
          chatId = topic.id;
          if (context.referenceId != chatId) {
            _circleArrivalChatIds[arrivalKey] = chatId;
          }
          messageTopics[message.id] = topic;
        }
        seen.add(message.id);
        arrived.add(
          ZyraFamilyMessage(
            id: message.id,
            senderId: message.senderId,
            senderFirstName: message.senderFirstName,
            senderRelationship: message.senderRelationship,
            senderRoleLabel: message.senderRoleLabel,
            body: message.body,
            createdAt: message.createdAt,
            readBy: message.readBy,
            context: contexts
                .where((known) => currentChatIds[known.referenceId] == chatId)
                .firstOrNull,
            unreadForMe:
                message.unreadForMe &&
                !_circleReadMessageKeys.contains(
                  ZyraGuardianCirclePreviewData.scopedMessageKey(
                    circleSeekerId,
                    senderId,
                    chatId,
                    message,
                  ),
                ),
          ),
        );
      }
    }
    final data = ZyraGuardianCirclePreviewData(
      seekerId: circleSeekerId,
      senderId: senderId,
      mainChatId: mainChatId,
      currentChatIds: currentChatIds,
      admittedTopics: journeyTopics.values,
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
            unreadForMe: false,
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
        ...arrived,
        for (final chatId in [mainChatId, ...journeyTopics.keys])
          for (final message
              in _circleSentMessages[(circleSeekerId, senderId, chatId)] ??
                  const <ZyraFamilyMessage>[])
            message,
      ],
      contexts: contexts,
      messageTopics: {
        ...messageTopics,
        for (final topic in journeyTopics.values)
          for (final message
              in _circleSentMessages[(circleSeekerId, senderId, topic.id)] ??
                  const <ZyraFamilyMessage>[])
            message.id: topic,
      },
      departedMemberIds: departedIds,
    );
    _recordSuppressedCircleAttention(data);
    return data;
  }

  String _circleMessageKey(
    ZyraGuardianCirclePreviewData data,
    ZyraFamilyMessage message,
  ) => data.messageKey(data.chatFor(message), message);

  bool _isCircleChatMuted(ZyraGuardianCirclePreviewData data, String? chatId) =>
      _circleMuteKeys.contains(data.muteKey(chatId)) ||
      (chatId == data.mainChatId &&
          _circleMuteKeys.contains(
            data.muteKey(ZyraCircleDiscussionTopic.general.id),
          ));

  void _recordSuppressedCircleAttention(ZyraGuardianCirclePreviewData data) {
    final circleMuted = _isCircleChatMuted(data, null);
    for (final message in data.messages.where(data.isUnread)) {
      final key = _circleMessageKey(data, message);
      if (_circleObservedArrivalKeys.add(key) &&
          (circleMuted || _isCircleChatMuted(data, data.chatFor(message)))) {
        _circleSuppressedAttentionKeys.add(key);
      }
    }
  }

  Iterable<ZyraFamilyMessage> _circleAttention(
    ZyraGuardianCirclePreviewData data,
  ) {
    if (!data.validFor(data.seekerId, viewerIsSeeker: !_guardianRole)) {
      return const [];
    }
    final chats = data.listChats(
      admittedTopics: data.admittedTopics,
      messages: data.messages,
      chatFor: data.chatFor,
      isUnread: data.isUnread,
      isMuted: (id) => _isCircleChatMuted(data, id),
    );
    return data.messages.where(
      (message) =>
          data.isUnread(message) &&
          chats[data.chatFor(message)]?.countsTowardTotal == true &&
          !_circleSuppressedAttentionKeys.contains(
            _circleMessageKey(data, message),
          ),
    );
  }

  bool get _hasCircleTabActivity {
    if (_tab == 2) return false;
    final data = _currentCircleData();
    return data != null &&
        _circleAttention(data).any(
          (message) =>
              !_circleTabSeenKeys.contains(_circleMessageKey(data, message)),
        );
  }

  int get _currentCircleUnreadCount {
    final data = _currentCircleData();
    if (data == null ||
        !data.validFor(data.seekerId, viewerIsSeeker: !_guardianRole)) {
      return 0;
    }
    // Whole-Circle mute keeps the existing visible Circle-button counts.
    return data.messages
        .where(
          (message) =>
              data.isUnread(message) &&
              !_isCircleChatMuted(data, data.chatFor(message)),
        )
        .length;
  }

  void _rememberCircleReads(
    ZyraGuardianCirclePreviewData data,
    String chatId,
    Iterable<ZyraFamilyMessage> messages,
  ) {
    for (final message in messages) {
      final key = data.messageKey(chatId, message);
      _circleReadMessageKeys.add(key);
      if (!_guardianRole) _myZyraConsumedFocusTokens.add('circle:$key');
    }
  }

  void _markCurrentCircleRead() {
    final data = _currentCircleData();
    if (data == null ||
        !data.validFor(data.seekerId, viewerIsSeeker: !_guardianRole)) {
      return;
    }
    final reads = data.messages.where(
      (message) =>
          data.isUnread(message) && data.chatFor(message) == data.mainChatId,
    );
    ZyraFamilyMessage? firstUnread;
    for (final message in reads) {
      if (message.senderId != null &&
          message.senderId != data.senderId &&
          !message.lifecycle &&
          (firstUnread == null ||
              message.createdAt.isBefore(firstUnread.createdAt))) {
        firstUnread = message;
      }
    }
    if (firstUnread case final message?) {
      _pendingMainUnreadOnEntry = (
        seekerId: data.seekerId,
        viewerId: data.senderId,
        messageId: message.id,
        senderId: message.senderId!,
      );
    }
    _rememberCircleReads(data, data.mainChatId, reads);
  }

  Widget _guardianCircle() {
    final mainUnreadOnEntry = _pendingMainUnreadOnEntry;
    _pendingMainUnreadOnEntry = null;
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
        mounted &&
        (widget.canActInOwnedDialog?.call() ?? _allowed) &&
        revision == _circleScopeRevision &&
        guardian == _guardianRole &&
        tab == _tab &&
        _pages.contains('guardian_circle') &&
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
    bool foreground() => _allowed && current() && _page == 'guardian_circle';
    final currentTopicExamples = List<ZyraCircleDiscussionTopic>.unmodifiable([
      if (!circleYusuf)
        for (final name in const ['Sara', 'Aisha', 'Maryam'])
          if (!_model.hasDeparted('draft-${name.toLowerCase()}'))
            ZyraCircleDiscussionTopic(
              id: 'draft-circle-current-${name.toLowerCase()}',
              firstName: name,
              kind: ZyraCircleTopicKind.current,
            ),
    ]);
    final pastTopicsById = _circlePastTopics(guardian);
    final pastTopics = List<ZyraCircleDiscussionTopic>.unmodifiable(
      pastTopicsById.values.map((entry) => entry.topic),
    );
    // Explicit dates for detached past examples, not real archive/history
    // access. Never derive a profile or message lookup from a picker label.
    final pastArchives = <String, ZyraCircleDiscussionArchive>{
      for (final entry in pastTopicsById.values)
        entry.topic.id: ZyraCircleDiscussionArchive(
          topicId: entry.topic.id,
          firstName: entry.topic.firstName,
          sharedSummaryLabel: entry.topic.sharedSummaryLabel,
          startedOn: entry.startedAt,
          endedOn: entry.topic.endedOn!,
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
      if (!foreground() ||
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
      arrivals: _circleArrivals,
      mutedChats: _circleMuteKeys,
      nextSentId: () => 'draft-circle-sent-${++_circleSentSequence}',
      onSent: (chatId, message) {
        if (!foreground()) return;
        (_circleSentMessages[data.muteKey(chatId)] ??= []).add(message);
        _publishCheckpoint();
      },
      mainUnreadOnEntry: mainUnreadOnEntry,
      onRead: (chatId, messages) {
        if (!foreground()) return;
        _rememberCircleReads(data, chatId, messages);
        _publishCheckpoint();
      },
      onMuteChanged: () {
        if (!foreground()) return;
        setState(() {});
        _publishCheckpoint();
      },
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
      oneParticipantIds: [
        for (final participant in data.participants)
          if (participant.memberRole == 'guardian' &&
              (guardian && participant.userId == senderId
                  ? _guardianMembership == 'Guardian One'
                  : _model.sampleGuardianMembershipFor(participant.userId) ==
                        DraftGuardianMembership.one))
            participant.userId,
      ],
      tiles: [
        for (final context in contexts)
          for (final person in _guardianJourneys)
            if (person.id == context.referenceId)
              ZyraCircleTopicTile(
                id: data.currentChatId(context.referenceId),
                name: context.firstName,
                journeyReferenceId: context.referenceId,
                stage:
                    'Stage ${_model.stageFor(person.id)?.order ?? 1} of 8 · ${_model.stageFor(person.id)?.label ?? 'Salam Exchange'}',
                photo: _photos
                    ?.forIndex(draftProfiles.indexOf(person))
                    .firstOrNull,
              ),
        for (final entry in pastTopicsById.values)
          ZyraCircleTopicTile(
            id: entry.topic.id,
            name: entry.topic.firstName,
            photo: guardian ? null : _photos?.forIndex(entry.photo).firstOrNull,
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
          _accountDispatch(ZyraConceptAccountAction.membership);
        }
      },
    );

    Widget seekerAvatar(double size) => ListenableBuilder(
      listenable: _accountSession,
      builder: (_, _) => ZyraSeekerAvatar(
        photo: current() && !circleYusuf ? _ownSeekerPhoto : null,
        size: size,
        alignmentX: _ownSeekerAvatarAlignment.dx,
        alignmentY: _ownSeekerAvatarAlignment.dy,
      ),
    );
    return _circleEntryView = ZyraDeveloperOwnedNavigatorScope(
      bridge: _developerBridge,
      navigatorKey: navigator,
      canPresent: foreground,
      child: Navigator(
        observers: [ZyraPreviewRouteObserver()],
        key: navigator,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => ZyraGuardianCircleScreen(
            key: ValueKey(('request-guardian-circle', revision, senderId)),
            seekerId: data.seekerId,
            seekerFirstName: circleSeekerName,
            viewerIsSeeker: !guardian,
            preview: true,
            previewData: data,
            previewSeekerAvatar: seekerAvatar,
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
              if (foreground()) _back();
            },
            onOpenContext: (context) {
              if (!foreground() ||
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
                  _selectGuardianJourney(context.referenceId);
                  _pages.add('guardian');
                }, preserveCircle: true);
              } else {
                _journey(context.referenceId);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _guardians() {
    _guardianFamily.expire(_previewNow);
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final session = _accountSession;
    final revision = _uiRevision;
    final navigatorStamp = _routeStamp;
    final journeys = _guardianJourneys;
    final people =
        _signupUnverified ? <WaliLinkedPerson>[] : [..._conceptGuardianPeople]
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
    bool current({bool ownedMenu = false}) =>
        mounted &&
        (ownedMenu
            ? (widget.canActInOwnedDialog?.call() ?? _allowed)
            : _allowed) &&
        session.current &&
        identical(session, _accountSession) &&
        account == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        revision == _uiRevision &&
        !_guardianRole &&
        _tab == 3 &&
        _page == null &&
        permissionStamp() == stamp;
    bool currentAction() =>
        current() &&
        navigatorStamp == _routeStamp &&
        ModalRoute.of(context)?.isCurrent == true;
    WaliLinkedPerson? target(String id) {
      if (!currentAction()) return null;
      if (_guardianPage >= people.length ||
          _guardianPage < 0 ||
          people[_guardianPage].id != id) {
        return null;
      }
      return people[_guardianPage];
    }

    bool invitationWaiting() =>
        !_guardianInvitationCancelled &&
        _guardianPage == people.length &&
        _guardianInvitationNow.isBefore(
          ZyraOneJourneyGuardianCards.previewInvitationExpiry,
        );

    Future<void> cancelInvitation() async {
      if (!currentAction()) return;
      if (!invitationWaiting()) {
        setState(() {});
        return;
      }
      final confirmed = await _confirmConceptAction(
        title: 'Cancel Omar’s invitation?',
        body:
            'Omar won’t be able to accept it. You can invite him again at any time.',
        primaryLabel: 'Cancel invitation',
        secondaryLabel: 'Keep invitation',
        personName: 'Omar',
        primaryKey: const ValueKey('guardian-card-confirm-cancel-invitation'),
        canCommit: () => current(ownedMenu: true) && invitationWaiting(),
      );
      if (confirmed) {
        _act(() {
          _guardianInvitationCancelled = true;
          _notice = 'Invitation cancelled.';
        });
      } else if (current()) {
        setState(() {});
      }
    }

    return ZyraOneJourneyGuardianCards(
      verifyFirst: _signupUnverified,
      key: ValueKey(('guardian-cards', account, identityHashCode(session))),
      people: [
        for (final p in people)
          ZyraGuardianCardPerson(
            person: p,
            membership: _model.canUseSampleGuardianChat(p.id)
                ? 'Guardian One'
                : 'Guardian Basic',
            history: _conceptGuardianHistory[p.id] ?? _shareHistory,
            familyPlace:
                _guardianFamily.inviteFor(p.id)?.status ==
                    ZyraGuardianFamilyInviteStatus.accepted &&
                _model.canUseSampleGuardianChat(p.id),
          ),
      ],
      journeysFor: (id) => [
        for (final p in journeys)
          ZyraGuardianCardJourney(
            id: p.id,
            attempt: _model.attemptRevisionFor(p.id),
            name: p.firstName,
            stageNumber: _model.stageFor(p.id)?.order ?? 1,
            stage:
                'Stage ${_model.stageFor(p.id)?.order ?? 1} of 8 · ${_model.stageFor(p.id)?.label ?? 'Salam Exchange'}',
            photo: _photos?.forIndex(draftProfiles.indexOf(p)).firstOrNull,
            view: _conceptAccessFor(id, p.id).view,
            chat: _conceptAccessFor(id, p.id).chat,
            canChange:
                people.where((g) => g.id == id).firstOrNull?.isMain != true &&
                !_model.hasRequiredPaidGuardianAccess(id, p.id),
            chatCanChange:
                !_model.hasRequiredPaidGuardianAccess(id, p.id) &&
                (people.where((g) => g.id == id).firstOrNull?.isMain != true ||
                    _guardianFamily.inviteFor(id)?.status ==
                        ZyraGuardianFamilyInviteStatus.accepted),
          ),
      ],
      capacity: _seekerMembership.contains('Basic') ? 1 : _model.capacity,
      basic: !_signupUnverified && _seekerMembership.contains('Basic'),
      initialPage: _guardianPage,
      previewInvitationNow: _guardianInvitationNow,
      previewInvitationCancelled: _guardianInvitationCancelled,
      onCancelPreviewInvitation: cancelInvitation,
      familyState: _guardianFamily.freePlaces > 0
          ? ZyraGuardianFamilyState.freePlace
          : ZyraGuardianFamilyState.noFamily,
      familyInvited: (id) =>
          _guardianFamily.inviteFor(id)?.pendingAt(_previewNow) == true,
      onFamilyInvite: (id) {
        if (!current() ||
            _guardianPage >= people.length ||
            people[_guardianPage].id != id ||
            _model.canUseSampleGuardianChat(id)) {
          return;
        }
        final guardian = people[_guardianPage];
        final seeker = _accountSession.ownProfile(false);
        final relationship = guardian.relationshipLabel;
        if (relationship == null) return;
        _guardianFamily.send(
          guardianId: id,
          guardianName: guardian.firstName,
          seekerId: seeker.id,
          seekerName: seeker.firstName,
          seekerGender: seeker.gender,
          relationship: relationship,
          main: guardian.isMain,
          now: _previewNow,
        );
        _armGuardianFamilyExpiry();
        _publishCheckpoint();
      },
      onFamilyCancel: (id) {
        if (!current()) return;
        final invite = _guardianFamily.inviteFor(id);
        if (invite != null) _guardianFamily.cancel(invite, _previewNow);
        _armGuardianFamilyExpiry();
        _publishCheckpoint();
      },
      canAct: current,
      canActInOwnedMenu: () => current(ownedMenu: true),
      onMenuRouteChanged: (route, {required open}) {
        if (open) {
          _guardianOptionsRoute = route;
        } else if (identical(_guardianOptionsRoute, route)) {
          _guardianOptionsRoute = null;
        }
      },
      interactionEpoch: () => (_uiRevision, _routeStamp),
      contextIdentity: (
        account,
        identityHashCode(session),
        _guardianRole,
        _seekerMembership,
        stamp,
      ),
      renderIdentity: _uiRevision,
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
        if (_signupUnverified) {
          _verifyDeveloperIdentity();
        } else {
          _open('guardian_invite');
        }
      },
      onUpgrade: () {
        if (currentAction()) {
          _accountDispatch(ZyraConceptAccountAction.membership);
        }
      },
      onHistory: (id, enabled) {
        if (target(id) == null) return;
        _act(() => _conceptGuardianHistory[id] = enabled);
      },
      onPermission: (id, journeyId, {view, chat}) {
        final guardian = target(id);
        if (guardian == null ||
            (guardian.isMain &&
                (view != null ||
                    _guardianFamily.inviteFor(id)?.status !=
                        ZyraGuardianFamilyInviteStatus.accepted)) ||
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
        _makeMainCheckStopped = false;
        final guardian = target(id);
        if (guardian == null || guardian.isMain) return false;
        final current = _accountFreshGuard();
        if (!await _confirmSensitiveAction()) {
          _makeMainCheckStopped = true;
          return false;
        }
        if (!current() || target(id) == null) {
          return false;
        }
        _act(() {
          _conceptMainGuardianId = id;
          _model.setOwnMainGuardianPresent(true);
          _guardianPage = 0;
          _notice = '${guardian.firstName} is now your Main Guardian.';
        });
        return true;
      },
      makeMainCheckStopped: () => _makeMainCheckStopped,
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

  void _selectGuardianJourney(String? id) {
    _guardianJourneyId = id;
    _guardianJourneyAttemptRevision = id == null
        ? null
        : _model.attemptRevisionFor(id);
  }

  bool get _hasGuardianCompatibilityPlan =>
      _guardianMembership == 'Guardian Basic' ||
      _guardianMembership == 'Guardian One';

  bool get _guardianCompatibilityOwner =>
      _allowed &&
      _fixtureAccount ==
          (ZyraAccountState.userId, ZyraAccountState.generation) &&
      ModalRoute.of(context)?.isCurrent == true &&
      _guardianRole &&
      _guardianTabs.main &&
      _conceptHassanLinked &&
      _hasGuardianCompatibilityPlan;

  bool _guardianCompatibilityOrigin({required bool archived}) {
    if (!_guardianRole) return false;
    // These leaves are session-local. Validate their exact parent chain on
    // every render, including while the informational upgrade is visible.
    final depth = switch (_page) {
      'guardian_compatibility' => 1,
      'guardian_compatibility_upgrade' => 2,
      _ => 0,
    };
    final origin = _pages.take(_pages.length - depth).toList();
    if (archived) {
      return _tab == 1 &&
          _heldTitle == 'Ended Journeys' &&
          origin.length == 1 &&
          origin.single == 'held_action';
    }
    return switch ((_tab, origin)) {
      (1 || 2, ['guardian']) ||
      (3, ['guardian_seeker', 'guardian']) ||
      (3, ['guardian_seeker', 'guardian_circle', 'guardian']) ||
      (_, ['guardian_circle', 'guardian']) => true,
      _ => false,
    };
  }

  bool _canReadGuardianCompatibility(_GuardianCompatibilityTarget target) {
    final id = target.subjectId;
    final archiveId = target.archiveId;
    if (!_guardianCompatibilityOwner ||
        !_profileIds.contains(id) ||
        _model.isBlocked(id) ||
        !_guardianCompatibilityOrigin(archived: archiveId != null)) {
      return false;
    }
    if (archiveId != null) {
      final attempt = _endedAttempt(id, archiveId);
      return attempt != null &&
          _guardianCanSeePastSummary(attempt) &&
          attempt.hasRecordedEnd(_previewNow) &&
          attempt.progress.compatibilityConsent &&
          attempt.progress.peerCompatibilityConsent;
    }
    return id == _guardianJourneyId &&
        target.activeRevision == _guardianJourneyAttemptRevision &&
        _model.hasGuardianViewForAttempt(
          'draft-guardian-hassan',
          id,
          target.activeRevision,
          isMain: _conceptLinkedSeeker.isMain,
        ) &&
        _model.compatibilityRevealed(id);
  }

  bool _guardianCanSeePastSummary(DraftEndedJourneyAttempt attempt) =>
      _guardianCompatibilityOwner &&
      !_model.isBlocked(attempt.profileId) &&
      !_model.hasDeparted(attempt.profileId) &&
      !_model.isEndedAttemptRemoved(attempt.id) &&
      _conceptGuardianHistory['draft-guardian-hassan'] == true &&
      attempt.guardiansWithView.contains('draft-guardian-hassan');

  _GuardianCompatibilityTarget _guardianPastTarget(
    DraftEndedJourneyAttempt attempt,
  ) => (
    subjectId: attempt.profileId,
    activeRevision: null,
    archiveId: attempt.id,
  );

  Widget _guardianCompatibilityRow(_GuardianCompatibilityTarget target) {
    final fresh = _accountFreshGuard();
    final tier = _guardianMembership;
    final archiveId = target.archiveId;
    return ZyraGuardianCompatibilityRow(
      rowKey: ValueKey(
        archiveId == null
            ? 'draft_guardian_compatibility_${target.subjectId}'
            : 'draft_guardian_past_compatibility_${target.subjectId}_$archiveId',
      ),
      canAct: () =>
          fresh() &&
          _guardianMembership == tier &&
          _canReadGuardianCompatibility(target),
      onTap: () => _move(() {
        _guardianCompatibilityTarget = target;
        _pages.add('guardian_compatibility');
      }),
    );
  }

  Widget _guardianCompatibilityReader() {
    final target = _guardianCompatibilityTarget;
    if (target == null || !_canReadGuardianCompatibility(target)) {
      return _unavailable();
    }
    final person = draftProfiles.firstWhere((p) => p.id == target.subjectId);
    final fresh = _accountFreshGuard();
    final basic = _guardianMembership == 'Guardian Basic';
    bool canSeeUpgrade() =>
        fresh() &&
        _guardianMembership == 'Guardian Basic' &&
        _guardianCompatibilityTarget == target &&
        _canReadGuardianCompatibility(target);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: ZyraDraftCompatibilityPresentation(
          key: ValueKey((target, _guardianMembership)),
          personName: person.firstName,
          overallScore: ZyraDraftCompatibilityPreview(
            person.id,
            balance: 0,
          ).overallScore,
          balance: 0,
          revealed: true,
          areaBands: basic ? null : ZyraCompatibilityDemo.bandsFor(person.id),
          areaGate: basic
              ? ZyraCompatibilityAreaGate(
                  guardian: true,
                  canAct: canSeeUpgrade,
                  onUpgrade: () => _open('guardian_compatibility_upgrade'),
                )
              : null,
        ),
      ),
    );
  }

  Widget _guardianCompatibilityUpgrade() {
    final target = _guardianCompatibilityTarget;
    if (target == null ||
        _guardianMembership != 'Guardian Basic' ||
        !_canReadGuardianCompatibility(target)) {
      return _unavailable();
    }
    final fresh = _accountFreshGuard();
    final childFresh = _accountFreshGuard(allowOwnedChildRoute: true);
    return ZyraOneUpgradePage(
      guardian: true,
      founderPreview: true,
      seekerFirstName: _conceptGuardianJourney?.linkedSeekerName ?? 'Adam',
      includesPreviewComparisons: true,
      canContinue: () =>
          fresh() &&
          _guardianMembership == 'Guardian Basic' &&
          _canReadGuardianCompatibility(target),
      childCanAct: () =>
          childFresh() &&
          _guardianMembership == 'Guardian Basic' &&
          _canReadGuardianCompatibility(target),
      onBack: _bound(_back),
    );
  }

  Widget _guardianDetail() => _guardianPermittedJourney();

  Widget _guardianPermittedJourney() {
    final journey = _conceptGuardianJourney;
    final _GuardianCompatibilityTarget compatibility = (
      subjectId: _guardianJourneyId ?? '',
      activeRevision: _guardianJourneyAttemptRevision,
      archiveId: null,
    );
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
            avatarAlignment: _ownSeekerAvatarAlignment,
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
        if (journey?.partner.id == compatibility.subjectId &&
            _canReadGuardianCompatibility(compatibility)) ...[
          const SizedBox(height: ZyraPreviewSpacing.cardToCard),
          _guardianCompatibilityRow(compatibility),
        ],
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
      _clearActivityFixture();
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

  DateTime? get _pendingGuardianFreePlace {
    final expiresAt = _guardianTabs.freePlaceInviteExpiresAt;
    return _guardianRole &&
            _guardianMembership == 'Guardian Basic' &&
            _seekerMembership == 'Seeker Basic' &&
            expiresAt != null &&
            expiresAt.isAfter(_previewNow) &&
            !_guardianTabs.consumedFocus.contains(
              ZyraGuardianTabsState.freePlaceInviteFocus,
            )
        ? expiresAt
        : null;
  }

  Widget _guardianFreePlaceInvite() {
    final invitation = _pendingGuardianFreePlace;
    if (invitation == null) return _unavailable();
    final fresh = _accountFreshGuard();
    final owner = _guardianTabs;
    bool current() =>
        fresh() &&
        _tab == 2 &&
        _page == 'guardian_free_place_invite' &&
        identical(owner, _guardianTabs) &&
        _pendingGuardianFreePlace == invitation;

    return ZyraGuardianFreePlacePage(
      canAct: current,
      onJoin: () {
        if (current()) _open('one_upgrade');
      },
      onDismiss: () {
        if (!current()) return;
        _move(() {
          owner.consumedFocus.add(ZyraGuardianTabsState.freePlaceInviteFocus);
          owner.focusIndex = 0;
          _pages.clear();
        });
      },
    );
  }

  ZyraGuardianFamilyInvite? get _pendingGuardianFamilyOffer {
    final offer = _guardianFamily.inviteFor('draft-guardian-hassan');
    if (!_guardianRole ||
        !_conceptHassanLinked ||
        _guardianMembership != 'Guardian Basic' ||
        _model.sampleGuardianMembershipFor('draft-guardian-hassan') !=
            DraftGuardianMembership.basic ||
        offer?.pendingAt(_previewNow) != true) {
      return null;
    }
    final guardian = _conceptGuardianPeople
        .where((p) => p.id == offer!.guardianId)
        .firstOrNull;
    final seeker = _accountSession.ownProfile(false);
    return guardian != null &&
            guardian.isMain == offer!.main &&
            guardian.relationshipLabel == offer.relationship &&
            seeker.id == offer.seekerId &&
            seeker.firstName == offer.seekerName &&
            seeker.gender == offer.seekerGender
        ? offer
        : null;
  }

  bool Function() _guardianFamilyGuard(
    String page,
    ZyraGuardianFamilyInvite offer,
  ) {
    final fresh = _accountFreshGuard();
    final family = _guardianFamily;
    var revoked = false;
    return () {
      final current =
          !revoked &&
          fresh() &&
          _accountSession.current &&
          _guardianRole &&
          _tab == 2 &&
          _page == page &&
          identical(family, _guardianFamily) &&
          _pendingGuardianFamilyOffer?.revision == offer.revision;
      if (!current) revoked = true;
      return current;
    };
  }

  void _armGuardianFamilyExpiry() {
    _guardianFamilyDeadline?.cancel();
    final pending =
        _guardianFamily.invites.where((i) => i.pendingAt(_previewNow)).toList()
          ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    if (pending.isEmpty) return;
    _guardianFamilyDeadline = Timer(
      pending.first.expiresAt.difference(_previewNow),
      () {
        if (!_allowed) return;
        _act(() {
          _guardianFamily.expire(_previewNow);
          if (_pendingGuardianFamilyOffer == null) {
            _pages.removeWhere(
              (p) =>
                  p == 'guardian_family_offer' ||
                  p == 'guardian_family_identity',
            );
          }
        });
        _armGuardianFamilyExpiry();
      },
    );
  }

  Widget _guardianFamilyIdentity() {
    final offer = _pendingGuardianFamilyOffer;
    if (offer == null) return const SizedBox.shrink();
    final current = _guardianFamilyGuard('guardian_family_identity', offer);
    return InitialIdentityCheckScreen(
      key: ValueKey(('family-identity', offer.revision)),
      devPreview: true,
      // Reuse the real verification page in its isolated local mode. Unknown
      // identity is not a passed check; its verified Continue owns this result.
      onContinue: (_) async {
        if (!current() ||
            !_guardianFamily.accept(
              offer,
              _previewNow,
              identityVerified: true,
            )) {
          return;
        }
        if (!_model.acceptSampleGuardianFamilyPlace(offer.guardianId)) return;
        _move(() {
          _guardianMembership = 'Guardian One';
          _subscriptionWallet = _subscriptionWallet.withRole(
            ZyraWalletRole.guardian,
            coverage: ZyraWalletCoverage.assignedFamily,
          );
          _pages.clear();
          _guardianTabs.focusIndex = 0;
        });
        _armGuardianFamilyExpiry();
      },
    );
  }

  Widget _guardianJourneySelector() {
    final people = _permittedGuardianJourneys;
    final selected = people.indexWhere((p) => p.id == _guardianFocus?.id);
    final callbacks = [
      for (final p in people)
        _bound(() => _move(() => _selectGuardianJourney(p.id))),
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

  List<DraftProfile> _guardianJourneyRequests(DraftJourneyState state) {
    if (!_conceptHassanLinked || !_conceptLinkedSeeker.isMain) return const [];
    if (_hasDeveloperPreview) {
      final rows = state == DraftJourneyState.received
          ? _developerSamples.receivedRows
          : state == DraftJourneyState.sent
          ? _developerSamples.sentRows
          : null;
      if (rows != null) return [for (final row in rows) row.person];
    }
    return _visibleRequests(state);
  }

  String _guardianRequestReadToken(String id) {
    if (_hasDeveloperPreview) {
      final request = _developerSamples.receivedRows
          ?.where((row) => row.person.id == id)
          .firstOrNull;
      if (request != null) {
        return 'guardian-sample:$id:${request.date.toIso8601String()}';
      }
    }
    return 'guardian-${_receivedFocusToken(id)}';
  }

  String _guardianRequestTabToken(String id) =>
      'tab-${_guardianRequestReadToken(id)}';

  bool get _hasGuardianMyZyraTabActivity =>
      _conceptHassanLinked &&
      (_hasCircleTabActivity ||
          (_tab != 2 &&
              _guardianJourneyRequests(DraftJourneyState.received).any(
                (person) =>
                    !_guardianTabs.consumedFocus.contains(
                      _guardianRequestReadToken(person.id),
                    ) &&
                    !_guardianTabs.consumedFocus.contains(
                      _guardianRequestTabToken(person.id),
                    ),
              )) ||
          (!_guardianTabs.attentionSeen &&
              (_guardianTabs.hasUnseenReview ||
                  (_guardianMembership == 'Guardian One' &&
                      _conceptLinkedSeeker.isMain &&
                      _guardianTabs.hasUnseenConnection))));

  void _seeGuardianTabActivity() {
    _guardianTabs.attentionSeen = true;
    for (final person in _guardianJourneyRequests(DraftJourneyState.received)) {
      _guardianTabs.consumedFocus.add(_guardianRequestTabToken(person.id));
    }
  }

  int get _guardianNewJourneyRequests =>
      _guardianJourneyRequests(DraftJourneyState.received)
          .where(
            (person) => !_guardianTabs.consumedFocus.contains(
              _guardianRequestReadToken(person.id),
            ),
          )
          .length;

  void _acknowledgeGuardianReceivedRequests() {
    if (_guardianTabs.requestsSent || _guardianTabs.requestSeeker == 2) return;
    for (final person in _guardianJourneyRequests(DraftJourneyState.received)) {
      _guardianTabs.consumedFocus.add(_guardianRequestReadToken(person.id));
    }
  }

  Widget _guardianTabsView(String page) {
    _guardianFamily.expire(_previewNow);
    final offer = _pendingGuardianFamilyOffer;
    final permitted = _permittedGuardianJourneys.map((p) => p.id).toSet();
    final people = page == 'seekers'
        ? _tabJourneys.where((p) => permitted.contains(p.id)).toList()
        : _guardianTabJourneyPeople;
    final selected = people.indexWhere((p) => p.id == _guardianJourneyId);
    final current = people.isEmpty ? null : people[selected < 0 ? 0 : selected];
    final fresh = _accountFreshGuard();
    final circle = page == 'my_zyra' ? _currentCircleData() : null;
    final arrivals = circle == null
        ? const <ZyraFamilyMessage>[]
        : (_circleAttention(circle).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    final circleFocus = arrivals.map((message) {
      final key = _circleMessageKey(circle!, message);
      final seeker = circle.participants.firstWhere(
        (person) => person.userId == circle.seekerId,
      );
      return ZyraFocusItem(
        id: 'circle:$key',
        title: "New message in ${seeker.firstName}'s Guardian Circle",
        detail:
            "${message.senderFirstName} has added to the families' conversation.",
        actionLabel: 'Open Circle',
        icon: Icons.forum_outlined,
        onAction: () {
          if (!fresh() || !_guardianRole || _tab != 2 || _page != null) return;
          final data = _currentCircleData();
          if (data != null &&
              _circleAttention(
                data,
              ).any((arrival) => _circleMessageKey(data, arrival) == key)) {
            _open('guardian_circle');
          }
        },
      );
    }).toList();
    return ZyraGuardianTabsPresentation(
      state: _guardianTabs,
      page: page,
      unverified: _signupUnverified,
      introductionDeclined: _developerSamples.hasDeclinedIntroduction,
      madeIntroductions: _developerSamples.guardianIntroductions(
        'draft-guardian-hassan',
      ),
      circleFocus: [
        if (page == 'my_zyra') ..._seasonalOfferFocus(fresh),
        if (_signupIncomplete)
          _signupFocus(
            _bound(() {
              unawaited(_resumeSignup());
            }),
          ),
        ...circleFocus,
      ],
      linked: _conceptHassanLinked,
      linkedSeekerNames: _conceptHassanLinked
          ? const ['Adam', 'Yusuf']
          : const [],
      paid: _guardianMembership == 'Guardian One',
      tabClearance: _quickAccessTabBar,
      canInteract: () =>
          fresh() &&
          _guardianRole &&
          _tab == (page == 'seekers' ? 3 : 2) &&
          _page == null,
      adamMain: _conceptLinkedSeeker.isMain,
      adamMembership: _seekerMembership,
      seekerGender: _conceptLinkedSeekerProfile.gender,
      adamPhoto: _ownSeekerPhoto,
      adamAvatarAlignment: _ownSeekerAvatarAlignment,
      familyOffer: offer,
      freePlaceInvite: _pendingGuardianFreePlace != null,
      familyCanAct: offer == null
          ? () => false
          : _guardianFamilyGuard('guardian_family_offer', offer),
      currentSeekerJourneyId: current?.id,
      currentSeekerJourney: current == null
          ? null
          : 'With ${current.firstName} · ${current.id == 'draft-sara' ? _guardianTabs.stage : _model.stageFor(current.id)?.label ?? _stateLabel(_model.stateFor(current.id)!)}',
      journeys: [for (final person in people) _guardianTabJourneyCard(person)],
      journeyIndex: selected < 0 ? 0 : selected,
      journeyIdentity: (_uiRevision, _routeStamp, _guardianTabs.seeker),
      photoFor: (id) {
        final index = draftProfiles.indexWhere((p) => p.id == 'draft-$id');
        return index < 0 ? null : _photos?.forIndex(index).firstOrNull;
      },
      newJourneyRequestCount: _guardianNewJourneyRequests,
      receivedJourneyRequests: _guardianJourneyRequests(
        DraftJourneyState.received,
      ),
      sentJourneyRequests: _guardianJourneyRequests(DraftJourneyState.sent),
      notificationCount: _conceptHassanLinked
          ? (_guardianTabs.hasUnseenReview ? 1 : 0) +
                (_guardianMembership == 'Guardian One' &&
                        _conceptLinkedSeeker.isMain &&
                        _guardianTabs.hasUnseenConnection
                    ? 1
                    : 0)
          : 0,
      onAction: _boundGuardianAction(page),
    );
  }

  ZyraGuardianJourneyCard _guardianTabJourneyCard(DraftProfile person) {
    final stage = _model.stageFor(person.id);
    final chat =
        _guardianMembership == 'Guardian One' &&
        _conceptAccessFor('draft-guardian-hassan', person.id).chat;
    final role = _conceptLinkedSeeker.isMain
        ? 'Main Guardian'
        : 'Additional Guardian';
    return ZyraGuardianJourneyCard(
      id: person.id,
      title: 'Adam & ${person.firstName}',
      details:
          '${person.firstName} ${person.surname} · ${person.age} · ${person.city} · You: $role · ${chat ? 'View and Chat' : 'View only'}',
      stageLine: person.id == 'draft-sara'
          ? _guardianTabs.stageLine
          : 'Stage ${stage?.order ?? 1} of 8 · ${stage?.label ?? _stateLabel(_model.stateFor(person.id)!)}',
      photo: _preparedGuardianJourneyPhoto(person),
    );
  }

  ImageProvider? _preparedGuardianJourneyPhoto(DraftProfile person) {
    final index = draftProfiles.indexOf(person);
    if (index < 0) return null;
    return zyraGuardianJourneyPhoto(
      allowed: _allowed,
      blocked: _model.isBlocked(person.id),
      preparedPhoto: _photos?.forIndex(index).firstOrNull,
    );
  }

  ValueChanged<String> _boundGuardianAction(String source) {
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final ownerPage = _page;
    final ownerTab = _tab;
    final revision = _uiRevision;
    final routes = _routeStamp;
    return (action) {
      if (!_allowed ||
          account != (ZyraAccountState.userId, ZyraAccountState.generation) ||
          !_guardianRole ||
          revision != _uiRevision ||
          routes != _routeStamp ||
          ownerPage != _page ||
          ownerTab != _tab) {
        return;
      }
      _guardianTabsAction(action);
    };
  }

  void _guardianTabsAction(String actionName) {
    final quickAccess = actionName.startsWith('quick_');
    if (quickAccess && (_tab != 2 || _page != null)) return;
    final action = quickAccess ? actionName.substring(6) : actionName;
    if (_signupUnverified &&
        (action == 'introduce_confirm' || action == 'connect_confirm')) {
      _verifyDeveloperIdentity();
      return;
    }
    if (action == 'free_place_view') {
      if (_tab == 2 && _page == null && _pendingGuardianFreePlace != null) {
        _open('guardian_free_place_invite');
      }
      return;
    }
    if (action == 'family_view' ||
        action == 'family_accept' ||
        action == 'family_decline') {
      final offer = _pendingGuardianFamilyOffer;
      if (offer == null) return;
      if (action == 'family_view') {
        if (_page == null && _tab == 2) _open('guardian_family_offer');
      } else if (_guardianFamilyGuard('guardian_family_offer', offer)()) {
        if (action == 'family_accept') {
          _open('guardian_family_identity');
        } else if (_guardianFamily.decline(offer, _previewNow)) {
          _move(() {
            _pages.clear();
            _notice = 'Declined. The place stays free for ${offer.seekerName}.';
          });
        }
      }
      return;
    }
    final state = _guardianTabs;
    final paid = _guardianMembership == 'Guardian One';
    if (action.startsWith('seekers_')) {
      if (_page != null || _tab != 3 || !_conceptHassanLinked) return;
      final index = int.tryParse(action.split('_').last);
      if (index == null || index < 0 || index > 2) return;
      if (action.startsWith('seekers_select_')) {
        if (index == 2) {
          _act(
            () {},
          ); // Revoke the previous card without changing Circle owner.
        } else {
          _act(() => state.seeker = index);
        }
      } else if (state.seeker == index) {
        if (action.startsWith('seekers_circle_')) {
          _open('guardian_circle');
        } else if (action == 'seekers_journey_0' &&
            _guardianTabJourneyPeople.isNotEmpty) {
          final people = _guardianTabJourneyPeople;
          _selectGuardianJourney(
            people.any((p) => p.id == _guardianJourneyId)
                ? _guardianJourneyId!
                : people.first.id,
          );
          _tabTo(1);
        }
      }
      return;
    }
    if (action.startsWith('seeker_journey_')) {
      if (_page != 'guardian_seeker' || !state.main || !_conceptHassanLinked) {
        return;
      }
      final id = action.substring('seeker_journey_'.length);
      if (!_guardianTabJourneyPeople.any((p) => p.id == id)) return;
      _selectGuardianJourney(id);
      if (id == 'draft-sara') state.consumedFocus.add(state.reviewFocusId);
      _open('guardian');
      return;
    }
    if (action.startsWith('journey_select_') ||
        action.startsWith('journey_open_')) {
      if (_page != null || _tab != 1 || !state.main || !_conceptHassanLinked) {
        return;
      }
      final opening = action.startsWith('journey_open_');
      final id = action.substring(
        opening ? 'journey_open_'.length : 'journey_select_'.length,
      );
      if (!_guardianTabJourneyPeople.any((p) => p.id == id)) return;
      if (!opening) {
        _act(() => _selectGuardianJourney(id));
      } else {
        _selectGuardianJourney(id);
        if (id == 'draft-sara') state.consumedFocus.add(state.reviewFocusId);
        _open('guardian');
      }
      return;
    }
    if (action.startsWith('focus_index_')) {
      final index = int.tryParse(action.substring('focus_index_'.length));
      final circle = _currentCircleData();
      final circleItems = circle == null ? 0 : _circleAttention(circle).length;
      if (index != null && index >= 0 && index < 3 + circleItems) {
        state.focusIndex = index;
        _publishCheckpoint();
      }
      return;
    }
    if (action == 'notifications') {
      if (quickAccess) {
        _openMyZyraQuickPage('notifications');
      } else {
        _open('notifications');
      }
      return;
    }
    if (action == 'focus_adam') {
      if (!_conceptHassanLinked) return;
      _move(() {
        state.seeker = 0;
        _selectGuardianJourney('draft-sara');
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
        if (action == 'request_seeker' || action.startsWith('requests_tab_')) {
          _acknowledgeGuardianReceivedRequests();
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
      if (_signupUnverified) {
        _tabTo(0);
        return;
      }
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
        _acknowledgeGuardianReceivedRequests();
        _pages.add('guardian_requests');
        if (quickAccess) _myZyraQuickAccessPage = 'guardian_requests';
      });
      return;
    }
    if (action == 'received' || action == 'connect') {
      if (!paid) return;
      _move(() {
        state.connectReceived = action == 'received';
        if (state.connectReceived) state.consumedFocus.add('connect-pending');
        _pages.add('guardian_connect');
        if (quickAccess) _myZyraQuickAccessPage = 'guardian_connect';
      });
      return;
    }
    if (action == 'introductions') {
      if (quickAccess) {
        _openMyZyraQuickPage('guardian_introductions');
      } else {
        _open('guardian_introductions');
      }
      return;
    }
    if (action == 'introduce_confirm' || action == 'connect_confirm') {
      if (!paid || !_conceptHassanLinked) return;
      if (action == 'introduce_confirm' &&
          (state.introducedForCurrent() ||
              _model.hasDeparted(
                'draft-${ZyraGuardianTabsState.network[state.networkIndex].id}',
              ))) {
        return;
      }
      if (action == 'connect_confirm' &&
          state.sent.contains(
            ZyraGuardianTabsState.network[state.networkIndex].id,
          )) {
        return;
      }
      if (action == 'introduce_confirm') {
        final peer = ZyraGuardianTabsState.network[state.networkIndex].id;
        _open('guardian_introduce', person: 'draft-$peer');
      } else {
        _open('network_request');
      }
      return;
    }
    if (action == 'introduce_send' || action == 'connect_send') {
      if (!paid || !_conceptHassanLinked) return;
      _act(() {
        if (action == 'introduce_send') {
          final peer = ZyraGuardianTabsState.network[state.networkIndex].id;
          if (!_model.hasDeparted('draft-$peer')) {
            state.introduced.add(state.introducedKey);
          }
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
        "You see ${state.seekerName}'s past Journeys only if he shares their summaries with you.",
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
    final revision = _uiRevision, routes = _routeStamp, tab = _tab;
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
          _conceptHassanLinked &&
          _conceptLinkedSeeker.isMain &&
          _guardianMembership == 'Guardian One' &&
          _guardianTabs.connection == ZyraGuardianConnection.accepted &&
          revision == _uiRevision &&
          (expectedNavigatorStamp?.call() ?? routes) == _routeStamp &&
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
    var expectedStamp = _routeStamp;
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
            sheetStamp == _routeStamp &&
            owned();
        void choose(String action) {
          if (!admitted()) return;
          consumed = true;
          Navigator.of(sheetContext).pop(action);
          expectedStamp = _routeStamp;
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
    sheetStamp = _routeStamp;
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
        (_allowed ||
            (_ownedConfirmRoute?.isCurrent == true &&
                (widget.canActInOwnedDialog?.call() ?? false))) &&
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
        canInteract: () => _allowed && current(),
        confirmRotation: _confirmConceptAction,
        interactionEpoch: () => _routeStamp,
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

  List<DraftEndedJourneyAttempt> get _guardianPastSummaries => [
    for (final person in draftProfiles)
      ..._model.endedAttemptsFor(person.id).where(_guardianCanSeePastSummary),
  ];

  Widget _heldPreviewAction() {
    if (_guardianRole && _heldTitle == 'Ended Journeys') {
      final summaries = _guardianCompatibilityOrigin(archived: true)
          ? _guardianPastSummaries
          : const <DraftEndedJourneyAttempt>[];
      if (summaries.isNotEmpty) {
        final dates = MaterialLocalizations.of(context);
        return _pageScroll([
          _heading(_heldTitle, ''),
          for (final attempt in summaries) ...[
            const SizedBox(height: ZyraPreviewSpacing.cardToCard),
            _card([
              _title('Ended Journey', size: 25),
              _body(switch (attempt.startedAt) {
                final start? => 'Started ${dates.formatFullDate(start)}',
                null => 'Start date not recorded',
              }),
              _body(switch (attempt.endedAt) {
                final end? => 'Ended ${dates.formatFullDate(end)}',
                null => 'End date not recorded',
              }),
            ]),
            if (_canReadGuardianCompatibility(
              _guardianPastTarget(attempt),
            )) ...[
              const SizedBox(height: ZyraPreviewSpacing.cardToCard),
              _guardianCompatibilityRow(_guardianPastTarget(attempt)),
            ],
          ],
        ], key: const ValueKey('concept_held_action'));
      }
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            key: const ValueKey('concept_held_action'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _heading(_heldTitle, ''),
              Expanded(
                child: Builder(
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          MediaQuery.textScalerOf(context).scale(12.5) <= 12.5
                          ? 240
                          : 0,
                    ),
                    child: ZyraEmptyState(
                      icon: Icons.history_outlined,
                      title: 'No ended Journeys to show.',
                      message: _heldDetail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      key: const ValueKey('concept_held_action'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(_heldTitle, ''),
        _card([_body(_heldDetail)]),
      ],
    );
  }

  Widget _ownProfilePreview() {
    if (_photos == null && !_photoLoadFailed) {
      return const ZyraLoading();
    }
    if (_ownProfilePreviewView != null &&
        _ownProfilePreviewRevision == _uiRevision) {
      return _ownProfilePreviewView!;
    }
    final fresh = _accountFreshGuard();
    final seekerPlan = switch (_membership) {
      'Seeker Basic' => ZyraPlan.basic,
      'Seeker One' => ZyraPlan.one,
      _ => null,
    };
    _ownProfilePreviewRevision = _uiRevision;
    return _ownProfilePreviewView = MyProfilePreviewScreen.preview(
      key: ValueKey(('retained-own-profile', _uiRevision, _guardianRole)),
      profile: _accountSession.ownProfile(
        _guardianRole,
        seekerPlan: seekerPlan,
      ),
      previewAvatar: (size) => ListenableBuilder(
        listenable: _accountSession,
        builder: (_, _) => ZyraSeekerAvatar(
          photo: fresh() ? _ownSeekerPhoto : null,
          size: size,
          alignmentX: ZyraProfileDetailsPage.photoAlignment.x,
          alignmentY: ZyraProfileDetailsPage.photoAlignment.y,
          applyAvatarCrop: false,
        ),
      ),
      hapticLevel: _accountSession.hapticLevel,
      canAct: fresh,
      onBack: () {
        if (fresh()) _back();
      },
      onSelectTab: (index) {
        if (fresh()) _tabTo(index);
      },
      showMyZyraActivity: _hasNewMyZyraTabActivity,
      loadProfileVideo: seekerPlan == ZyraPlan.one
          ? _fixtureProfileVideoLoader
          : null,
    );
  }

  String? get _ownSeekerPhoto => _accountSession.photos(false).firstOrNull;
  Offset get _ownSeekerAvatarAlignment => _accountSession.avatar(false);

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
    familyPlacePayer:
        _guardianRole &&
            _guardianMembership == 'Guardian One' &&
            _guardianFamily.inviteFor('draft-guardian-hassan')?.status ==
                ZyraGuardianFamilyInviteStatus.accepted
        ? _guardianFamily.inviteFor('draft-guardian-hassan')!.seekerName
        : null,
    guardianCount: '${_conceptGuardianPeople.length}',
    signedInWith: 'Apple',
    appLock: ZyraAppLock.instance.enabled,
    profilePaused: _profilePrivacy.paused,
    privateMode: _profilePrivacy.privateMode,
    backgroundLabel: _accountSession.palette.label.replaceAll(' · Current', ''),
    hapticLabel: _accountSession.hapticLevel.label,
    gold: false,
    plusUnlocks: _compatibilityAccess.balance,
    photoAsset: _guardianRole ? null : _ownSeekerPhoto,
    avatarAlignment: _guardianRole ? Offset.zero : _ownSeekerAvatarAlignment,
    smoothSettings: false,
    membershipPaymentHistory: _membershipPaymentHistory,
  );

  Future<bool> _confirmSensitiveAction() {
    // Fixture ownership exists only in test/capture routes. Old interaction
    // fixtures remain deterministic; LOCK 40 tests supply true/false fakes.
    if (widget.fixture case final fixture?) {
      return fixture.confirmSensitiveAction?.call() ?? Future.value(true);
    }
    return ZyraAppLock.instance.confirmSensitiveAction();
  }

  String _privacyDate(String id) => _privacyDates[id] ?? _todayPrivacyDate();

  String _todayPrivacyDate() {
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
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]}';
  }

  void _markPrivacyDate(String id) => _privacyDates[id] = _todayPrivacyDate();

  Widget _privacySecurityView(ZyraConceptAccountAction action) {
    final fresh = _accountFreshGuard();
    final page = switch (action) {
      ZyraConceptAccountAction.hiddenProfiles =>
        ZyraPrivacySecurityPage.hiddenBlocked,
      ZyraConceptAccountAction.appLock => ZyraPrivacySecurityPage.appLock,
      _ => ZyraPrivacySecurityPage.signIn,
    };
    final people = _guardianRole
        ? [
            for (final person in draftGuardians)
              (id: person.id, firstName: person.firstName),
          ]
        : [
            for (final person in draftProfiles)
              (id: person.id, firstName: person.firstName),
          ];
    List<ZyraPrivacyPerson> visible(bool blocked) => [
      for (final person in people)
        if (blocked
            ? _model.blockedPeers.contains(person.id) ||
                  _developerSamples.sampleBlockedPeers.contains(person.id)
            : (_model.hiddenPeers.contains(person.id) ||
                      _developerSamples.sampleHiddenPeers.contains(
                        person.id,
                      )) &&
                  !_model.blockedPeers.contains(person.id) &&
                  !_developerSamples.sampleBlockedPeers.contains(person.id))
          ZyraPrivacyPerson(
            id: person.id,
            firstName: person.firstName,
            date: _privacyDate(person.id),
          ),
    ];
    return ZyraPrivacySecurityPreview(
      page: page,
      blocked: visible(true),
      hidden: visible(false),
      onUnblock: (id) {
        if (!fresh() || !people.any((person) => person.id == id)) return;
        final name = people.firstWhere((person) => person.id == id).firstName;
        if (!_model.blockedPeers.contains(id) &&
            !_developerSamples.sampleBlockedPeers.contains(id)) {
          return;
        }
        _act(() {
          final ordinary = _model.unblock(id);
          final sample = _developerSamples.unblockSampleProfile(id);
          if (ordinary || sample) {
            _privacyDates.remove(id);
            _notice = 'Unblocked $name. They were not told.';
          }
        });
      },
      onShowAgain: (id) {
        if (!fresh() || !people.any((person) => person.id == id)) return;
        final name = people.firstWhere((person) => person.id == id).firstName;
        if (!_model.isHidden(id) &&
            !_developerSamples.sampleHiddenPeers.contains(id)) {
          return;
        }
        _act(() {
          final ordinary = _model.unhide(id);
          final sample = _developerSamples.unhideSampleProfile(id);
          if (ordinary || sample) {
            _privacyDates.remove(id);
            _notice = '$name can appear in your Profiles again.';
          }
        });
      },
      lockEnabled: ZyraAppLock.instance.enabled,
      lockDelay: ZyraAppLock.instance.delay,
      switcherCover: ZyraLocalPrefs.switcherCoverEnabled,
      hideMessageText: ZyraLocalPrefs.messageTextHidden,
      onLockChanged: (enabled) async {
        if (!fresh()) return false;
        final changed = await ZyraAppLock.instance.setEnabled(enabled);
        if (changed && fresh()) _act(() {});
        return changed;
      },
      onDelayChanged: (delay) {
        if (!fresh()) return;
        unawaited(ZyraAppLock.instance.setDelay(delay));
        _act(() {});
      },
      onSwitcherCoverChanged: (enabled) {
        if (!fresh()) return;
        unawaited(ZyraAppLock.instance.setSwitcherCoverEnabled(enabled));
        _act(() {});
      },
      onMessageTextChanged: (enabled) {
        if (!fresh()) return;
        unawaited(ZyraLocalPrefs.setMessageTextHidden(enabled));
        _act(() {});
      },
      otherDevicesPresent: _otherSampleDevicesPresent,
      onSignOutOtherDevices: () async {
        if (!fresh() || !_otherSampleDevicesPresent) return;
        if (!await _confirmSensitiveAction() || !fresh()) return;
        _act(() {
          _otherSampleDevicesPresent = false;
          _notice = 'All other devices are signed out.';
        });
      },
    );
  }

  Future<bool> _confirmConceptAction({
    required String title,
    required String body,
    required String primaryLabel,
    required String secondaryLabel,
    required bool Function() canCommit,
    String? personName,
    List<String> peerIds = const [],
    IconData icon = Icons.info_outline,
    Key? sheetKey,
    Key? primaryKey,
    Key? secondaryKey,
  }) async {
    if (!_allowed || _ownedConfirmRoute != null || !canCommit()) return false;
    var expectedStamp = _routeStamp;
    final fresh = _accountFreshGuard(
      expectedNavigatorStamp: () => expectedStamp,
    );
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final revision = _uiRevision;
    final page = _page;
    final tab = _tab;
    final guardian = _guardianRole;
    late ModalRoute<bool> route;
    _confirmPeerIds = peerIds;
    try {
      final pending = showZyraConfirm(
        context: _tapContext,
        title: title,
        body: body,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        personName: personName,
        icon: icon,
        sheetKey: sheetKey,
        primaryKey: primaryKey,
        secondaryKey: secondaryKey,
        hapticLevel: () => _accountSession.hapticLevel,
        onOpening: (opened) => _ownedConfirmRoute = route = opened,
        canConfirm: () =>
            mounted &&
            identical(_ownedConfirmRoute, route) &&
            (widget.canActInOwnedDialog?.call() ?? _allowed) &&
            account == (ZyraAccountState.userId, ZyraAccountState.generation) &&
            revision == _uiRevision &&
            page == _page &&
            tab == _tab &&
            guardian == _guardianRole &&
            expectedStamp == _routeStamp &&
            canCommit(),
        onConfirmedPop: () => expectedStamp = _routeStamp,
      );
      expectedStamp = _routeStamp;
      return await pending == true && fresh() && canCommit();
    } finally {
      _ownedConfirmRoute = null;
      _confirmPeerIds = const [];
    }
  }

  bool Function() _accountFreshGuard({
    int Function()? expectedNavigatorStamp,
    bool allowOwnedChildRoute = false,
  }) {
    final account = (ZyraAccountState.userId, ZyraAccountState.generation);
    final revision = _uiRevision;
    final guardian = _guardianRole;
    final page = _page;
    final tab = _tab;
    final navigatorStamp = _routeStamp;
    final hostRoute = ModalRoute.of(context);
    return () =>
        _allowed &&
        account == (ZyraAccountState.userId, ZyraAccountState.generation) &&
        (allowOwnedChildRoute
            ? hostRoute?.isActive == true
            : (expectedNavigatorStamp?.call() ?? navigatorStamp) ==
                      _routeStamp &&
                  hostRoute?.isCurrent == true) &&
        revision == _uiRevision &&
        guardian == _guardianRole &&
        page == _page &&
        tab == _tab;
  }

  void _accountDispatch(ZyraConceptAccountAction action) {
    switch (action) {
      case ZyraConceptAccountAction.yourSeekers:
        if (_guardianRole) _tabTo(3);
      case ZyraConceptAccountAction.previewProfile:
        _open('own_profile_preview');
      case ZyraConceptAccountAction.pastJourneys:
        // Ended Journeys live only in My ZYRA in the new methodology.
        return;
      case ZyraConceptAccountAction.phoneAccess:
        _phoneAccessSeen = true;
        unawaited(_savePhoneAccessSeen());
        _open('phone_access');
      case ZyraConceptAccountAction.settings:
        _open('settings');
      case ZyraConceptAccountAction.membership:
        if (_membership.contains('Basic')) {
          _open('one_upgrade');
        } else {
          _membershipDraft = _membershipDraft.copyWith(
            section: ZyraMembershipSection.current,
          );
          _open('membership');
        }
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
      case ZyraConceptAccountAction.contactSupport:
        _open('help_contact');
      case ZyraConceptAccountAction.advanced:
        _open('help_advanced');
      case ZyraConceptAccountAction.privacyData:
        _open('help_privacy');
      case ZyraConceptAccountAction.replayWalkthrough:
        _startFirstTour();
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
    return () => fresh() && identical(wallet, _subscriptionWallet);
  }

  void _cacheWallet(ZyraSubscriptionWalletDraft draft) {
    if (!_allowed ||
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
        if (fresh()) _open('switch_account_signup');
      },
    );
  }

  bool get _hasPreviewFamily =>
      _guardianFamily.freePlaces > 0 ||
      _guardianFamily.invites.any(
        (invite) => invite.status == ZyraGuardianFamilyInviteStatus.accepted,
      );

  Widget _subscriptionsView() {
    if (_guardianRole) {
      final linked = _conceptLinkedSeeker;
      final journey = _conceptGuardianJourney;
      final adamAccess = !linked.isMain
          ? 'Additional Guardian · as Adam allows'
          : journey == null ||
                _conceptAccessFor(
                  'draft-guardian-hassan',
                  journey.partner.id,
                ).chat
          ? 'Main Guardian · View and Chat'
          : 'Main Guardian · View';
      return ZyraGuardianPlacesPreview(
        familyPayer: _accountData.familyPlacePayer,
        isBasic: _guardianMembership == 'Guardian Basic',
        seekers: [
          if (_conceptHassanLinked) ...[
            ZyraProfileSmallPageRow(
              icon: Icons.person_outline,
              title: linked.firstName,
              subtitle: adamAccess,
            ),
            const ZyraProfileSmallPageRow(
              icon: Icons.person_outline,
              title: 'Yusuf',
              subtitle: 'Additional Guardian · as Yusuf allows',
            ),
          ],
        ],
      );
    }
    final one = _seekerMembership == 'Seeker One';
    final journeys = _currentJourneys;
    return ZyraSeekerPlacesPreview(
      isOne: one,
      journeys: [
        for (final person in journeys)
          ZyraProfileSmallPageRow(
            icon: Icons.people_outline,
            title:
                '${person.firstName} · Stage ${_model.stageFor(person.id)?.order ?? 1} of 8',
            subtitle: 'In use',
          ),
        for (var i = journeys.length; i < (one ? 3 : 1); i++)
          const ZyraProfileSmallPageRow(icon: Icons.add, title: 'Free place'),
      ],
      familyPlaces: !_hasPreviewFamily
          ? null
          : [
              ZyraProfileSmallPageRow(
                icon: Icons.person_outline,
                title: 'You · $_seekerMembership',
                subtitle: 'Your own place',
              ),
              for (final invite in _guardianFamily.invites)
                if (invite.status == ZyraGuardianFamilyInviteStatus.accepted)
                  ZyraProfileSmallPageRow(
                    icon: Icons.security,
                    title: '${invite.guardianName} · Guardian One',
                    subtitle: 'Family place',
                  ),
              if (_guardianFamily.freePlaces > 0)
                ZyraProfileSmallPageRow(
                  icon: Icons.add,
                  title:
                      '${_guardianFamily.freePlaces} ${_guardianFamily.freePlaces == 1 ? 'place' : 'places'} free',
                  subtitle:
                      'Give it to a Guardian from their card in the Guardian tab',
                ),
            ],
    );
  }

  Widget _inviteView() {
    final fresh = _accountFreshGuard();
    final link = _guardianRole ? 'zyra.app/i/HASSAN3K' : 'zyra.app/i/ADAM7Q';
    return ZyraInvitePreview(
      guardian: _guardianRole,
      link: link,
      onCopy: () async {
        if (!fresh()) return;
        await Clipboard.setData(ClipboardData(text: link));
        if (fresh()) _act(() => _notice = 'Link copied.');
      },
      onShare: () {
        if (!fresh()) return;
        final box = context.findRenderObject() as RenderBox?;
        unawaited(
          SharePlus.instance.share(
            ShareParams(
              text: link,
              sharePositionOrigin: box == null
                  ? null
                  : box.localToGlobal(Offset.zero) & box.size,
            ),
          ),
        );
      },
    );
  }

  void _startAddedRoleSignup(ZyraWalletRole role) {
    if (!_allowed) return;
    final guardian = role == ZyraWalletRole.guardian;
    final profile = _accountSession.ownProfile(guardian);
    _signup?.dispose();
    _signup = ZyraSignupPreviewController(now: widget.previewClock)
      ..seedSetup(
        guardian: guardian,
        verified: !_signupUnverified,
        firstName: profile.firstName,
        surname: profile.surnameLine ?? '',
      )
      ..resumeSetup();
    _addedRoleSignup = _signup;
    // Both roles share this preview account; the added role must not reset
    // the current role’s Journeys or start a second account.
    _signupHasEntered = true;
    _signupPreferences = null;
    _signupSurface = _signupPreferenceSurface = null;
    _signupLease = Object();
    _open('signup');
    unawaited(_loadSignupPhoto());
  }

  Widget _switchSignupView({required bool setupOverview}) {
    final fresh = _walletGuard();
    final targetRole = _walletRole.other;
    final sample = _profileSmallPageSample;
    final missing =
        sample ==
            (_guardianRole
                ? ZyraProfileSmallPageSample.guardianOnly
                : ZyraProfileSmallPageSample.seekerOnly) ||
        _subscriptionWallet.forRole(targetRole).readiness ==
            ZyraWalletReadiness.missing;
    if (!setupOverview &&
        (missing ||
            _subscriptionWallet.nextStep(targetRole) ==
                    ZyraWalletNextStep.switchProfile &&
                ZyraWalletRole.values.every(
                  (role) =>
                      _subscriptionWallet.forRole(role).readiness ==
                      ZyraWalletReadiness.ready,
                ))) {
      final seekerPlan = _guardianRole
          ? (_subscriptionWallet.seeker.isOne ? 'Seeker One' : 'Seeker Basic')
          : _seekerMembership;
      final guardianPlan = _guardianRole
          ? _guardianMembership
          : (_subscriptionWallet.guardian.isOne
                ? 'Guardian One'
                : 'Guardian Basic');
      return ZyraSwitchProfilePreview(
        guardian: _guardianRole,
        seekerPlan: '$seekerPlan${_hasPreviewFamily ? ' · ZYRA Family' : ''}',
        guardianPlan: '$guardianPlan${_guardianRole ? '' : ' · ready'}',
        otherRoleMissing: missing,
        onSwitch: () {
          if (!fresh()) return;
          if (missing) {
            _startAddedRoleSignup(targetRole);
            return;
          }
          _walletSwitch(targetRole);
          if (_walletRole == targetRole) _act(() => _notice = 'Switched.');
        },
      );
    }
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

  final _membershipRecords = {
    for (final role in ZyraWalletRole.values)
      role: ZyraMembershipPreviewRecord.sample(),
  };

  final _acceptedRetentionOffers =
      <ZyraWalletRole, ({DateTime accepted, ZyraRetentionMode mode})>{};
  // The shell's account generation owns one local entry across both roles.
  bool _enteredRamadanDraw = false;

  ZyraPreviewOfferChoices get _offerChoices =>
      widget.fixture?.offerChoices ?? _developerSamples.offers;

  bool get _ramadanDrawAvailable =>
      _fixtureAccount ==
          (ZyraAccountState.userId, ZyraAccountState.generation) &&
      _offerChoices.ramadan;

  ZyraMembershipPreviewRecord? get _currentOfferMembership =>
      (widget.fixture?.membershipRecords ?? _membershipRecords)[_walletRole];

  ZyraEidGiftPreview? get _eidGift {
    final record = _currentOfferMembership;
    final accepted = _acceptedRetentionOffers[_walletRole];
    final gift = zyraEidGiftPreview(
      eid: _offerChoices.eid,
      guardian: _guardianRole,
      one: _accountData.isOne,
      paid:
          _accountData.familyPlacePayer == null &&
          record != null &&
          !record.trial &&
          record.paidMonths > 0,
    );
    if (gift?.appliesDiscount == true &&
        accepted != null &&
        ZyraRetentionOfferPreview(
          mode: accepted.mode,
          guardian: _guardianRole,
        ).isActive(now: _previewNow, accepted: accepted.accepted)) {
      return null;
    }
    return gift;
  }

  List<ZyraFocusItem> _seasonalOfferFocus(bool Function() fresh) => [
    if (_eidGift != null)
      ZyraFocusItem(
        id: 'preview-eid-gift',
        icon: Icons.check,
        title: 'Eid Mubarak —\na gift from ZYRA',
        detail: 'Open to see your Eid gift.',
        actionLabel: 'See my gift',
        actionKey: 'preview_open_eid_gift',
        onAction: () {
          if (fresh() && _eidGift != null) _open('eid_gift_preview');
        },
      ),
    if (_ramadanDrawAvailable)
      ZyraFocusItem(
        id: 'preview-ramadan-draw',
        icon: Icons.card_giftcard_outlined,
        title: 'Ramadan gift draw',
        detail:
            'Enter once for a chance to win 6 months of ZYRA One. Free to enter.',
        actionLabel: 'Enter',
        actionKey: 'preview_open_ramadan_draw',
        onAction: () {
          if (fresh() && _ramadanDrawAvailable) _open('ramadan_draw_preview');
        },
      ),
  ];

  Widget _offersView() {
    final current = _accountFreshGuard();
    if (_page == 'eid_gift_preview') {
      final gift = _eidGift;
      if (gift == null) return _unavailable();
      return ZyraEidGiftPreviewPage(
        firstName: _accountData.name.trim().split(' ').first,
        gift: gift,
        onThanks: () {
          if (current()) _back();
        },
      );
    }
    if (!_ramadanDrawAvailable) return _unavailable();
    return ZyraRamadanDrawPreviewPage(
      entered: _enteredRamadanDraw,
      onEnter: () {
        if (!current() || !_ramadanDrawAvailable || _enteredRamadanDraw) return;
        _act(() => _enteredRamadanDraw = true);
      },
    );
  }

  Future<void> _cancelMembershipWithOffer(bool Function() current) async {
    if (!current() || _ownedConfirmRoute != null) return;
    final role = _walletRole;
    final offer = ZyraRetentionOfferPreview(
      mode: _offerChoices.retentionMode,
      guardian: _guardianRole,
    );
    bool eligible() {
      final record = _currentOfferMembership;
      return _accountData.isOne &&
          _accountData.familyPlacePayer == null &&
          _offerChoices.retentionMode == offer.mode &&
          record != null &&
          offer.isEligible(
            trial: record.trial,
            paidMonths: record.paidMonths,
            now: _previewNow,
            lastAccepted: _acceptedRetentionOffers[role]?.accepted,
          );
    }

    if (!eligible()) {
      await _openAppleSubscriptions(current);
      return;
    }
    final host = _tapContext;
    final navigator = Navigator.of(host, rootNavigator: true);
    var expectedStamp = _routeStamp;
    final owner = (ZyraAccountState.userId, ZyraAccountState.generation);
    final originalPage = _page;
    final originalTab = _tab;
    final revision = _uiRevision;
    final fresh = _accountFreshGuard(
      expectedNavigatorStamp: () => expectedStamp,
    );
    var selected = false;
    late final ModalBottomSheetRoute<bool> route;
    route = ModalBottomSheetRoute<bool>(
      capturedThemes: InheritedTheme.capture(from: host, to: navigator.context),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierLabel: MaterialLocalizations.of(host).modalBarrierDismissLabel,
      modalBarrierColor: const Color(0x611E1610),
      sheetAnimationStyle:
          MediaQuery.disableAnimationsOf(host) ||
              MediaQuery.accessibleNavigationOf(host)
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) {
        bool admitted() =>
            mounted &&
            !selected &&
            route.isCurrent &&
            identical(_ownedConfirmRoute, route) &&
            expectedStamp == _routeStamp &&
            (widget.canActInOwnedDialog?.call() ?? _allowed) &&
            owner == (ZyraAccountState.userId, ZyraAccountState.generation) &&
            revision == _uiRevision &&
            originalPage == _page &&
            originalTab == _tab &&
            role == _walletRole;
        void choose(bool stay) {
          if (!admitted()) return;
          selected = true;
          navigator.pop(stay);
          expectedStamp = _routeStamp;
        }

        return ZyraTapFeedback(
          level: () => _accountSession.hapticLevel,
          canAct: admitted,
          child: ZyraRetentionPreviewSheet(
            offer: offer,
            onStay: () => choose(true),
            onContinue: () => choose(false),
          ),
        );
      },
    );
    _ownedConfirmRoute = route;
    try {
      final pending = navigator.push(route);
      expectedStamp = _routeStamp;
      final stayed = await pending;
      await route.completed;
      if (!fresh() || stayed == null) return;
      if (!stayed) {
        await _openAppleSubscriptions(fresh);
      } else if (eligible()) {
        _act(() {
          _acceptedRetentionOffers[role] = (
            accepted: _previewNow,
            mode: offer.mode,
          );
          _notice =
              'Thank you for staying. Your offer starts at your next renewal.';
        });
      }
    } finally {
      if (identical(_ownedConfirmRoute, route)) _ownedConfirmRoute = null;
    }
  }

  Widget _membershipView() {
    final fresh = _accountFreshGuard();
    bool allowed() => fresh();
    if (_membershipDraft.section == ZyraMembershipSection.current &&
        !_membership.contains('Basic')) {
      final data = _accountData;
      final payer = data.familyPlacePayer;
      final offer = _guardianFamily.inviteFor('draft-guardian-hassan');
      void toast(String message) {
        if (allowed()) _act(() => _notice = message);
      }

      return ZyraMembershipPreview(
        guardian: _guardianRole,
        record: _currentOfferMembership,
        unlocks: _compatibilityAccess.balance,
        familyPayer: payer,
        onUnlocks: () {
          if (allowed()) _open('compatibility_store');
        },
        onFamily: () => toast('Opens ZYRA Family.'),
        onCovered: () => toast(
          payer == null
              ? 'A Seeker can cover you with a place in their ZYRA Family. You pay nothing.'
              : '$payer covers you with a place in ${offer?.seekerGender.toLowerCase() == 'female' ? 'her' : 'his'} ZYRA Family. You pay nothing.',
        ),
        onCompare: () {
          if (allowed()) _open('one_upgrade');
        },
        onRestore: () =>
            toast('ZYRA checks your Apple ID for earlier purchases.'),
        onCancel: () {
          if (allowed() && payer == null) {
            unawaited(_cancelMembershipWithOffer(allowed));
          }
        },
      );
    }
    return ZyraConceptMembershipPresentation(
      data: _accountData,
      initialDraft: _membershipDraft,
      currentProducts: _coveredWalletProducts,
      currentDetail: _subscriptionWallet
          .forRole(_walletRole)
          .coverageLabel(_walletRole),
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
        canAct: () => fresh(),
      ),
    );
  }

  Widget _phoneAccess() {
    final fresh = _accountFreshGuard();
    return ZyraPhoneAccessPage(
      key: ValueKey(('phone_access', _uiRevision, _routeStamp)),
      canAct: () => fresh(),
      onBack: () {
        if (fresh()) _back();
      },
    );
  }

  Widget _settings() {
    final fresh = _accountFreshGuard();
    return ZyraConceptSettingsPresentation(
      data: _accountData,
      hapticLevel: _accountSession.hapticLevel,
      hapticOwner: (_uiRevision, _routeStamp, _guardianRole),
      readHapticLevel: () => _accountSession.hapticLevel,
      canChangeHaptics: () => fresh() && _accountSession.current,
      onHapticChanged: (level) =>
          fresh() && _accountSession.setHapticLevel(level),
      showBackButton: false,
      onAction: (action) {
        if (fresh()) {
          _accountDispatch(action);
        } else {
          ZyraInteractionStyle.cancelSelectionTap();
        }
      },
      onBack: () {
        if (fresh()) _back();
      },
    );
  }

  bool get _isRetainedAccountPage => const [
    'edit_profile',
    'filter_preferences',
    'preference_quick_check',
    'manage_photos',
  ].contains(_page);

  void _accountChanged() {
    if (!_allowed) _cancelTimeRuleTimer();
    if (!_allowed) return;
    // Local presentation updates are not navigation epochs. Keeping this
    // lifetime stable lets the retained choice sheet return to its own page.
    setState(() {});
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
    final videoFixture = !guardian && identical(widget.fixture, _fixtureOwner)
        ? _fixtureOwner
        : null;
    final videoStore = videoFixture?.profileVideoStore;
    final navigator = GlobalKey<NavigatorState>();
    _accountNavigator = navigator;
    _accountLeafRevision = revision;
    bool retainedOwner() =>
        mounted &&
        (_allowed || _developerBridge?.canPresent == true) &&
        revision == _uiRevision &&
        guardian == _guardianRole &&
        page == _page &&
        tab == _tab &&
        _accountSession.current;
    bool current() => _allowed && retainedOwner();
    bool hubCurrent() => current() && navigator.currentState?.canPop() == false;
    final compatibility = _accountSession.compatibility;
    Future<(ZyraCompatibilityDraft, ZyraPreferenceQuickCheck)>
    loadPreferences() async {
      final snapshot = await compatibility.load('draft-self');
      final checks = await compatibility.visiblePreferenceChecks('draft-self');
      return (
        ZyraCompatibilityDraft.fromSnapshot(
          gender: _accountSession.ownProfile(false).gender,
          snapshot: snapshot,
        ),
        ZyraPreferenceQuickCheck(
          items: checks.legacyAmber,
          missing: checks.missing,
          setup: await compatibility.loadSetupPreferenceLights('draft-self'),
          confirm: (option, light) async {
            if (!current()) throw StateError('The preview account changed.');
            await compatibility.confirmPreferenceLight(
              'draft-self',
              option,
              light,
            );
          },
        ),
      );
    }

    final preferences =
        !guardian &&
            (page == 'filter_preferences' || page == 'preference_quick_check')
        ? loadPreferences()
        : null;
    void back() {
      if (current()) _back();
    }

    void support() {
      if (current()) _open('help_contact');
    }

    Future<void> editDetails(ZyraSignupStep step, VoidCallback refresh) async {
      if (!hubCurrent() || navigator.currentState == null) return;
      final own = _accountSession.ownProfile(guardian);
      final editor = ZyraSignupPreviewController()
        ..setAboutYou(_accountSession.signupAbout(guardian) ?? '')
        ..setLocation(own.city)
        ..setNationality(own.publicNationality);
      for (final value in (own.publicEthnicity ?? '').split(', ')) {
        if (value.isNotEmpty) editor.toggleEthnicity(value);
      }
      editor.setStep(step);
      await navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (editorContext) {
            bool active() =>
                current() && (ModalRoute.of(editorContext)?.isCurrent ?? false);
            void done() {
              if (!active()) return;
              if (_accountSession.editProfileDetails(
                guardian: guardian,
                about: editor.aboutYou,
                city: editor.location ?? '',
                nationality: editor.nationality,
                ethnicity: editor.ethnicities.isEmpty
                    ? null
                    : editor.ethnicities.join(', '),
              )) {
                Navigator.of(editorContext).pop();
              }
            }

            return ZyraPullDownBackScope(
              routeIdentity: editor,
              onBack: () {
                if (active()) Navigator.of(editorContext).pop();
              },
              child: ZyraSignupPreview(
                controller: editor,
                canAct: active,
                preferencesBuilder: (_) => const SizedBox.shrink(),
                onPause: () {},
                onEnter: () {},
                onShareCode: () {},
                samplePhotos: const [],
                ownCode: '',
                onEditDone: done,
              ),
            );
          },
        ),
      );
      editor.dispose();
      if (current()) refresh();
    }

    Future<void> editBio(
      int index,
      ZyraCompatibilityDraft draft,
      VoidCallback refresh,
    ) async {
      if (!hubCurrent() || navigator.currentState == null) return;
      await navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (editorContext) {
            bool active() =>
                current() && (ModalRoute.of(editorContext)?.isCurrent ?? false);
            return BioOnboardingFlow.previewEdit(
              gender: _accountSession.seekerGender,
              initialBio: JourneyBio.fromOnboardingAnswers(draft.answers),
              section: const [
                'Work & education',
                'Family & marriage',
                'Practical life',
              ][index],
              canAct: active,
              canRetain: retainedOwner,
              onSave: (bio) async {
                if (!active()) return false;
                final updated = draft.copy();
                updated.answers.addAll(bio.toOnboardingAnswers());
                return await compatibility.save('draft-self', updated) &&
                    active();
              },
              onDone: () {
                if (active()) Navigator.of(editorContext).pop();
              },
            );
          },
        ),
      );
      if (current()) refresh();
    }

    // Publication rebuilds the leaf. Keep its admitted callbacks stable for
    // this route epoch rather than accidentally revoking its own editor.
    void photosChanged(List<String> photos) {
      if (current()) _accountSession.setPhotos(guardian, photos);
    }

    void avatarChanged(Offset alignment) {
      if (current()) _accountSession.setAvatar(guardian, alignment);
    }

    // The retained hub owns its ordinary child routes in this Navigator.
    // Covering the hub with its own editor or picker does not cover the
    // admitted Founder route or grant a stale page permission to save.
    return _accountLeafView = ZyraDeveloperOwnedNavigatorScope(
      bridge: _developerBridge,
      navigatorKey: navigator,
      canPresent: current,
      child: Navigator(
        observers: [ZyraPreviewRouteObserver()],
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
                'filter_preferences' ||
                'preference_quick_check' => FutureBuilder(
                  future: preferences,
                  builder: (_, snapshot) {
                    if (guardian || !current()) return const SizedBox.shrink();
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const ZyraLoading();
                    }
                    final data = snapshot.data;
                    if (data == null) return const SizedBox.shrink();
                    return CompatibilityEditorScreen.preview(
                      kind: CompatibilityEditorKind.trafficLights,
                      initialDraft: data.$1,
                      quickCheck: data.$2,
                      openQuickCheck: page == 'preference_quick_check',
                      onPreviewReturn: (_) => back(),
                      canAct: current,
                      canRetain: retainedOwner,
                      canActChanges: _accountSession,
                      onPersist: (draft) async =>
                          current() &&
                          await _accountSession.compatibility.save(
                            'draft-self',
                            draft,
                          ) &&
                          current(),
                    );
                  },
                ),
                'edit_profile' => EditProfileScreen.preview(
                  repository: _accountSession.compatibility,
                  canAct: current,
                  canRetain: retainedOwner,
                  gender: _accountSession.ownProfile(guardian).gender,
                  age: _accountSession.ownProfile(guardian).age,
                  onSupport: support,
                  profileBuilder: (draft, preferences, refresh) {
                    final own = _accountSession.ownProfile(guardian);
                    final bio = JourneyBio.fromOnboardingAnswers(draft.answers);
                    final progress = [
                      for (final section in const [
                        'Work & education',
                        'Family & marriage',
                        'Practical life',
                      ])
                        () {
                          final fields = journeyBioFieldDefinitions
                              .where((f) => f.section == section)
                              .toList();
                          final answered = fields
                              .where(
                                (f) => (bio.fieldValues[f.id] ?? '')
                                    .trim()
                                    .isNotEmpty,
                              )
                              .length;
                          return '$answered of ${fields.length}';
                        }(),
                    ];
                    return ZyraEditProfilePresentation(
                      name: '${own.firstName} ${own.surnameLine ?? ''}'.trim(),
                      age: own.age,
                      gender: own.gender == 'female' ? 'Female' : 'Male',
                      photoCount: _accountSession.photos(guardian).length,
                      about: _accountSession.signupAbout(guardian) ?? '',
                      location: own.city.split(',').first,
                      nationality: own.publicNationality ?? '—',
                      ethnicity: own.publicEthnicity ?? '—',
                      bioProgress: progress,
                      preferencesProgress:
                          '${draft.preferenceAnswerCount} of ${draft.preferenceOptionCount}',
                      onPhotos: () {
                        if (hubCurrent()) _open('manage_photos');
                      },
                      onAbout: () =>
                          editDetails(ZyraSignupStep.aboutYou, refresh),
                      onLocation: () =>
                          editDetails(ZyraSignupStep.location, refresh),
                      onNationality: () =>
                          editDetails(ZyraSignupStep.nationality, refresh),
                      onEthnicity: () =>
                          editDetails(ZyraSignupStep.ethnicity, refresh),
                      onBio: (index) => editBio(index, draft, refresh),
                      onPreferences: preferences,
                      onSupport: () {
                        if (hubCurrent()) support();
                      },
                    );
                  },
                ),
                'manage_photos' => EditPhotosScreen.preview(
                  canAct: current,
                  canRetain: retainedOwner,
                  localPhotoImport: widget.localPhotoImport,
                  initialPhotos: _accountSession.photos(guardian),
                  gender: 'male',
                  hapticLevel: _accountSession.hapticLevel,
                  initialAlignmentX: _accountSession.avatar(guardian).dx,
                  initialAlignmentY: _accountSession.avatar(guardian).dy,
                  onPhotosChanged: photosChanged,
                  onAvatarChanged: avatarChanged,
                  profileVideo: videoStore == null
                      ? null
                      : (
                          store: videoStore,
                          media: videoFixture!.profileVideoMedia,
                          basic: _seekerMembership == 'Seeker Basic',
                          canAct: () =>
                              identical(widget.fixture, videoFixture) &&
                              _fixtureAccount ==
                                  (
                                    ZyraAccountState.userId,
                                    ZyraAccountState.generation,
                                  ),
                          onUpgrade: () {
                            if (current() && _fixtureIsCurrent()) {
                              _open('one_upgrade');
                            }
                          },
                        ),
                ),
                _ => _unavailable(),
              },
            ),
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
        ZyraConceptAccountAction.settings => 'Settings',
        ZyraConceptAccountAction.signOut => 'Sign out',
        ZyraConceptAccountAction.signInSecurity => 'Sign-in & security',
        ZyraConceptAccountAction.appLock => 'App lock',
        ZyraConceptAccountAction.phoneAccess => 'Phone access',
        ZyraConceptAccountAction.advanced => 'Advanced',
        ZyraConceptAccountAction.guardianPrivacy => 'Guardian privacy',
        ZyraConceptAccountAction.visibility => 'Pause My Profile',
        ZyraConceptAccountAction.privateMode => 'Private mode',
        ZyraConceptAccountAction.hiddenProfiles => 'Hidden and blocked',
        ZyraConceptAccountAction.notificationSettings =>
          'Notifications & emails',
        ZyraConceptAccountAction.membership => 'Membership',
        ZyraConceptAccountAction.helpSupport => 'Help & support',
        ZyraConceptAccountAction.contactSupport => 'Contact support',
        ZyraConceptAccountAction.replayWalkthrough => 'Replay the walkthrough',
        ZyraConceptAccountAction.feedback => 'Send feedback',
        ZyraConceptAccountAction.privacyData => 'Privacy & data',
        ZyraConceptAccountAction.background => 'Background',
        ZyraConceptAccountAction.haptics => 'Haptic feel',
        ZyraConceptAccountAction.cancelMembership => 'Cancel membership',
        ZyraConceptAccountAction.subscriptions => 'Your subscriptions',
      };

  Widget _accountActionView() {
    final action = _accountDestination;
    if (action == ZyraConceptAccountAction.visibility ||
        action == ZyraConceptAccountAction.privateMode) {
      if (_guardianRole) return _unavailable();
      final fresh = _accountFreshGuard();
      return ZyraPausePrivatePreview(
        privatePage: action == ZyraConceptAccountAction.privateMode,
        paused: _profilePrivacy.paused,
        privateMode: _profilePrivacy.privateMode,
        seekerOne: _seekerMembership == 'Seeker One',
        onPause: () {
          if (!fresh()) return;
          if (_profilePrivacy.pause()) {
            _act(() => _notice = 'Paused. You are hidden from Profiles.');
          }
        },
        onShowProfile: () {
          if (fresh() && _profilePrivacy.showProfile()) {
            _act(() => _notice = 'Your profile is visible again.');
          }
        },
        onPrivateChanged: (enabled) {
          if (!fresh()) return;
          if (!_profilePrivacy.setPrivateMode(enabled)) {
            _act(() => _notice = 'Private mode comes with Seeker One.');
          }
        },
        onUpgrade: () {
          if (fresh()) _accountDispatch(ZyraConceptAccountAction.membership);
        },
      );
    }
    if (action == ZyraConceptAccountAction.signInSecurity ||
        action == ZyraConceptAccountAction.appLock ||
        action == ZyraConceptAccountAction.hiddenProfiles) {
      return _privacySecurityView(action!);
    }
    if (action == ZyraConceptAccountAction.invite) return _inviteView();
    if (action == ZyraConceptAccountAction.notificationSettings) {
      final fresh = _accountFreshGuard();
      return ZyraEmailSettingsPreview(
        settings: _accountSession.emailSettings,
        onChanged: (setting, enabled) {
          if (fresh()) _accountSession.setEmailSetting(setting, enabled);
        },
      );
    }
    if (_settingsOverviewActions.contains(action)) {
      final fresh = _accountFreshGuard();
      final pending = _hiddenProfileRestore;
      bool currentHidden(String id) =>
          fresh() &&
          !_guardianRole &&
          _accountDestination == ZyraConceptAccountAction.hiddenProfiles &&
          _profileIds.contains(id) &&
          _model.isHidden(id);
      bool currentRestore() =>
          pending != null &&
          currentHidden(pending.id) &&
          _hiddenProfileRestore == pending &&
          pending.revision == _uiRevision &&
          pending.navigatorStamp == _routeStamp;
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
              navigatorStamp: _routeStamp,
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
          if (!fresh()) return;
          _move(() {
            _settingsDetail = detail;
            _pages.add('settings_detail');
          });
        },
        onHelp: () {
          if (fresh()) _open('help_support');
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
                physics: const ScrollPhysics(),
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
        if (fresh()) _open('help_support');
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

  bool get _bioGalleryEnabled =>
      identical(widget.fixture, _fixtureOwner) &&
      (_fixtureOwner?.profileVideoLoader != null ||
          _fixtureOwner?.profileVideoStore != null);

  bool _canOpenBioGallery(String ownerId, String page, int revision) =>
      _bioGalleryEnabled &&
      _fixtureIsCurrent() &&
      _uiRevision == revision &&
      _page == page &&
      _personId == ownerId &&
      switch (page) {
        'bio' =>
          _canViewJourneyBio(ownerId) && _model.canViewJourneyBio(ownerId),
        'ended_bio' => _canViewEndedBio(ownerId),
        'journey' =>
          _canAddressJourneyDisclosure(ownerId) &&
              _model.canParticipateInJourney(ownerId) &&
              _model.isBioStepOpen(ownerId) &&
              _model.bioRevealed(ownerId),
        _ => false,
      };

  DraftProfile? get _currentBioGallery {
    final gallery = _bioGallery;
    return gallery != null &&
            _canOpenBioGallery(gallery.ownerId, gallery.page, gallery.revision)
        ? _person
        : null;
  }

  List<String> _journeyBioPhotos(DraftProfile person) => _displayProfile(
    person,
  ).photos.where(_browsePhotoRenderer.isReady).toList(growable: false);

  Widget? _journeyBioGalleryButton(DraftProfile person) {
    final page = _page;
    final revision = _uiRevision;
    final id = person.id;
    if (page == null ||
        !_canOpenBioGallery(id, page, revision) ||
        _journeyBioPhotos(person).isEmpty) {
      return null;
    }

    return ZyraProfileVideoAccess(
      ownerId: id,
      load: _fixtureProfileVideoLoader,
      builder: (context, video) => ZyraFloatingSurface(
        radius: 999,
        child: TextButton(
          key: const ValueKey('journey-bio-gallery-button'),
          style: TextButton.styleFrom(
            foregroundColor: ZyraColors.espresso,
            backgroundColor: const Color(0xFFFBF7F0),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: ZyraText.body(size: 12.5),
          ),
          onPressed: ZyraTapFeedback.onTap(
            context,
            () => setState(
              () => _bioGallery = (ownerId: id, page: page, revision: revision),
            ),
            canAct: () => _canOpenBioGallery(id, page, revision),
          ),
          child: Text(video == null ? 'Photos ›' : 'Photos & video ›'),
        ),
      ),
    );
  }

  Widget _journeyBioGallery(DraftProfile person) {
    final gallery = _bioGallery!;
    bool canAct() =>
        _bioGallery == gallery &&
        _canOpenBioGallery(gallery.ownerId, gallery.page, gallery.revision);
    return ZyraProfileVideoAccess(
      key: ValueKey(('bio-gallery', gallery)),
      ownerId: person.id,
      load: _fixtureProfileVideoLoader,
      builder: (context, video) => ZyraFullScreenProfileGallery(
        photos: _journeyBioPhotos(person),
        video: video,
        photoBuilder: _browsePhotoRenderer.build,
        canAct: canAct,
        onClose: () {
          if (canAct()) setState(() => _bioGallery = null);
        },
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
      galleryButton: _journeyBioGalleryButton(person),
    );
  }

  VoidCallback _bioStepAction(DraftProfile person, bool Function() change) {
    final fresh = _accountFreshGuard();
    final revision = _uiRevision;
    final page = _page;
    return _bound(() {
      final correctPage = page == 'journey';
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
                galleryButton: _journeyBioGalleryButton(person),
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
            'You can view the result you revealed together or used a profile Unlock to open.',
          ),
        ]),
      ], key: ValueKey('draft_ended_compatibility_locked_${person.id}'));
    }
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
          areaGate: _seekerMembership == 'Seeker Basic' && used == null
              ? const ZyraCompatibilityAreaGate(guardian: false)
              : null,
          areaBands:
              used?.areaBands ??
              (_seekerMembership == 'Seeker Basic'
                  ? null
                  : ZyraCompatibilityDemo.bandsFor(person.id)),
        ),
      ),
    );
  }

  Widget _compatibilityInfo() {
    final route = _compatibilityRoute;
    final person = _person;
    final navigatorStamp = _routeStamp;
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
        navigatorStamp == _routeStamp &&
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

    final result = _compatibilityAccess.resultFor(person.id);
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
              result?.overallScore ??
              ZyraDraftCompatibilityPreview(person.id, balance: 0).overallScore,
          revealed: result != null,
          areaBands: result?.areaBands,
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
    final navigatorStamp = _routeStamp;
    final hostRoute = ModalRoute.of(context);
    bool current() =>
        fresh() &&
        navigatorStamp == _routeStamp &&
        hostRoute?.isCurrent == true &&
        _page == 'compatibility_store';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: ZyraDraftCompatibilityStorePresentation(
          isSeekerOne: _seekerMembership == 'Seeker One',
          canAct: current,
          balance: _guardianRole ? null : _compatibilityAccess.balance,
          founderPreview: true,
          onPurchaseNotice: (message) {
            if (current()) _act(() => _notice = message);
          },
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

  Widget _notificationsView() => KeyedSubtree(
    key: const ValueKey('concept_notifications_end_card'),
    child: _card([
      ZyraDeveloperTitle(child: _title('Only what matters to you.', size: 26)),
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
        () {
          if (_focus == null) {
            if (_guardianRole) {
              _guardianTabsAction('requests');
            } else {
              _activity('requests');
            }
          } else if (_currentJourneys.length > 1) {
            _tabTo(1);
          } else {
            _journey(_focus!.id);
          }
        },
      ),
      _body(
        'No real notifications are fetched, marked read or sent.',
        small: true,
      ),
    ]),
  );
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
      if (_seekerMembership != 'Seeker Basic') _browseHistory.reset();
      _pages.removeLast();
    });
  }

  Widget _filters() {
    final revision = _uiRevision;
    final guardian = _guardianRole;
    final routes = _routeStamp;
    final locationFlow = _locationFlow;
    final hostRoute = ModalRoute.of(context);
    final allFilters = _hasAllBrowseFilters;
    bool current() =>
        _allowed &&
        revision == _uiRevision &&
        guardian == _guardianRole &&
        allFilters == _hasAllBrowseFilters &&
        _page == 'filters' &&
        _locationSheet == 0;
    bool canPage() =>
        current() &&
        routes == _routeStamp &&
        locationFlow == _locationFlow &&
        hostRoute?.isCurrent == true;
    return ZyraOneJourneyFiltersPresentation(
      filter: allFilters
          ? _editingBrowseFilter
          : _editingBrowseFilter.withoutHeritage(),
      allFilters: allFilters,
      initialIndex: _filtersCardIndex,
      onIndexChanged: (index) {
        if (canPage()) _filtersCardIndex = index;
      },
      onUpgrade: () {
        if (canPage() && !allFilters && !_guardianRole) _open('one_upgrade');
      },
      homeTown: _homeTown,
      paintWhileCovered: _locationSheet != 0,
      currentArea: _location.point != null,
      canAct: () => current() && _locationSheet == 0,
      canPage: canPage,
      onChanged: (filter) {
        if (current()) {
          _act(() {
            _editingBrowseFilter = _keepingSavedOneFilters(
              filter,
              _editingBrowseFilter,
            );
          });
        }
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
      _locationRevision == _uiRevision &&
      _locationRoute == _routeStamp &&
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
    _locationRoute = _routeStamp;
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
    final attempt = _model.attemptRevisionFor(person.id);
    final safetyRevision = _model.personSafetyRevision;
    final sourcePersonId = _personId;
    bool samePerson() =>
        _personId == sourcePersonId &&
        !_guardianRole &&
        _model.canApplyPersonSafety(
          person.id,
          hide: hide,
          expectedAttemptRevision: attempt,
          expectedSafetyRevision: safetyRevision,
          endCurrentJourney: true,
        );
    if (!canAct() || !samePerson() || _personSafetyConfirmationOpen) return;
    _personSafetyConfirmationOpen = true;
    final name = person.firstName;
    try {
      if (!await _confirmConceptAction(
        title: '${hide ? 'Hide' : 'Block'} $name and end your Journey?',
        body: hide
            ? 'Hiding ends this Journey permanently first. Your Timeline stays. $name won’t appear again. You can undo this in Settings → Hidden and blocked.'
            : 'Blocking ends this Journey permanently first. Your Timeline stays. $name can’t see or contact you and won’t be told you blocked them.',
        primaryLabel: hide ? 'End Journey and hide' : 'End Journey and block',
        secondaryLabel: 'Keep this Journey',
        personName: name,
        peerIds: [person.id],
        primaryKey: const ValueKey('journey_person_safety_confirm'),
        secondaryKey: const ValueKey('journey_person_safety_keep'),
        canCommit: samePerson,
      )) {
        return;
      }
      // The model validates the complete transaction again before either
      // mutation. No asynchronous work separates ending from hide/block.
      _move(() {
        if (!_model.applyPersonSafety(
          person.id,
          hide: hide,
          expectedAttemptRevision: attempt,
          expectedSafetyRevision: safetyRevision,
          endCurrentJourney: true,
          mainGuardianId: hide ? _conceptMainGuardianId : null,
        )) {
          return;
        }
        if (_developerSamples.hasSamples) {
          final sampleJourney =
              (_developerSamples.activeRows ?? const <ZyraSampleJourney>[])
                  .where((row) => row.person.id == person.id)
                  .firstOrNull;
          if (sampleJourney != null) {
            _developerSamples.endActive(sampleJourney);
          }
          if (hide) {
            _developerSamples.hideSampleProfile(person);
          } else {
            _developerSamples.blockSampleProfile(person);
          }
        }
        _markPrivacyDate(person.id);
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
              _markPrivacyDate(person.id);
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
          onSubmit: person == null
              ? null
              : _bound(() {
                  if (canSelect() && _personId == person.id) {
                    _open('help_report_sent');
                  }
                }),
          onHide: localAction(true),
          onBlock: localAction(false),
        ),
      ),
    );
  }

  Widget _helpSafetyView() {
    final page = _page;
    final screen = switch (page) {
      'help_contact' => ZyraHelpSafetyScreen.contact,
      'help_contact_sent' => ZyraHelpSafetyScreen.contactSent,
      'help_report_sent' => ZyraHelpSafetyScreen.reportSent,
      'help_advanced' => ZyraHelpSafetyScreen.advanced,
      'help_data' => ZyraHelpSafetyScreen.data,
      'help_delete' => ZyraHelpSafetyScreen.delete,
      'help_closed' => ZyraHelpSafetyScreen.closed,
      _ => ZyraHelpSafetyScreen.privacy,
    };
    final person = _person;
    final firstName = _accountData.name.trim().split(' ').first;
    final current = _accountFreshGuard();
    return ZyraHelpSafetyPreview(
      key: ValueKey(('help_safety', page, _guardianRole)),
      screen: screen,
      guardian: _guardianRole,
      firstName: firstName,
      reportedName: person?.firstName,
      dataRequestedAt: _helpDataRequestedAt,
      closedAt: _helpClosedAt,
      onContactSent: () {
        if (current()) _open('help_contact_sent');
      },
      onReportDone: () {
        if (!current()) return;
        _move(() {
          if (_pages.lastOrNull == 'help_report_sent') _pages.removeLast();
          if (_pages.lastOrNull == 'safety' ||
              _pages.lastOrNull == 'guardian_chat_report') {
            _pages.removeLast();
          }
        });
      },
      onBlockReported: () {
        if (!current() || person == null || _personId != person.id) return;
        if (_warnBeforePersonSafety(
          person,
          hide: false,
          canAct: () => current() && _personId == person.id,
        )) {
          return;
        }
        _move(() {
          if (!_model.block(person.id)) return;
          _markPrivacyDate(person.id);
          _pages.clear();
          _tab = 0;
          _personId = null;
          _browseIndex = 0;
        });
      },
      onOpenData: () {
        if (current()) _open('help_data');
      },
      onOpenDelete: () {
        if (current()) _open('help_delete');
      },
      onRequestData: () async {
        if (!current() || _helpDataRequestedAt != null) return;
        if (!await _confirmSensitiveAction() ||
            !current() ||
            _helpDataRequestedAt != null) {
          return;
        }
        _act(() => _helpDataRequestedAt = DateTime.now());
      },
      onDelete: () async {
        if (!current()) return;
        if (!await _confirmSensitiveAction() || !current()) return;
        _move(() {
          _helpClosedAt = DateTime.now();
          _pages.add('help_closed');
        });
      },
      onClose: () {
        if (current()) widget.onExit();
      },
      onDone: () {
        if (!current()) return;
        _move(() {
          if (_pages.lastOrNull == 'help_contact_sent') _pages.removeLast();
          if (_pages.lastOrNull == 'help_contact') _pages.removeLast();
        });
      },
      onLegal: (name) {
        if (!current()) return;
        final message = switch (name) {
          'privacy' => 'The privacy policy opens here.',
          'terms' => 'The terms of use open here.',
          _ => 'Opens the photo privacy page.',
        };
        _act(() => _notice = message);
      },
      onSubscriptions: () {
        if (current()) unawaited(_openAppleSubscriptions(current));
      },
      onPauseProfile: _guardianRole
          ? null
          : () {
              if (current()) {
                _accountDispatch(ZyraConceptAccountAction.visibility);
              }
            },
    );
  }

  Future<void> _openAppleSubscriptions(bool Function() current) async {
    if (!current()) return;
    bool opened;
    try {
      opened = await launchUrl(
        Uri.parse('https://apps.apple.com/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (current() && !opened) {
      _act(() => _notice = 'App Store subscriptions could not be opened.');
    }
  }

  Widget _unavailable() => _card([
    _title('Nothing to open here.', size: 23),
    _button('concept_return_connections', 'Go to Journey', () => _tabTo(1)),
  ]);
  Widget _mainHeading(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Align(
      alignment: Alignment.topLeft,
      child: ZyraTabTitle(
        title,
        textKey: ValueKey('concept_main_title_$title'),
      ),
    ),
  );
  Widget _heading(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZyraDeveloperTitle(child: _title(title, size: 26)),
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
        disabledForegroundColor: ZyraColors.secondaryText,
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
          height: ZyraNavBarMetrics.legacyRestingHeight,
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

/// The Guardian Journey card only receives an already prepared, allowed photo.
ImageProvider? zyraGuardianJourneyPhoto({
  required bool allowed,
  required bool blocked,
  required String? preparedPhoto,
}) {
  if (!allowed || blocked || preparedPhoto == null) return null;
  if (preparedPhoto.startsWith('assets/')) return AssetImage(preparedPhoto);
  if (!preparedPhoto.startsWith('data:image/')) return null;
  final comma = preparedPhoto.indexOf(',');
  if (comma < 0) return null;
  try {
    return MemoryImage(base64Decode(preparedPhoto.substring(comma + 1)));
  } on FormatException {
    return null;
  }
}

// The existing Guardian page's horizontal presentation, with an owned local
// controller. Revisiting a page restores the local selection; reset starts at
// the first Guardian without reusing a stale PageStorage offset.
