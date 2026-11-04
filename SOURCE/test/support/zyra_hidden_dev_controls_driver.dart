// Code-only sample configuration for captures and widget tests. No developer
// panel or replacement test UI is built. Member navigation remains physical.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_draft_timeline_preview.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/dev/zyra_my_zyra_activity_preview.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_next_photo_motion.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

/// Each mounted shell receives its own fixture through its constructor.
/// Commands are accepted only while that exact shell owns the current route.
class ZyraShellTestFixture extends ChangeNotifier {
  ZyraShellTestFixture({
    ViewRequestDraftModel? model,
    DateTime Function()? clock,
    ZyraSubscriptionWalletDraft? wallet,
    ZyraDraftCompatibilityAccessStore? compatibilityAccess,
    ZyraMyZyraActivityExample? activityExample,
    ZyraMembershipPaymentHistory membershipPaymentHistory =
        ZyraMembershipPaymentHistory.paidBefore,
  }) : _model =
           model ??
           (clock == null
               ? null
               : ViewRequestDraftModel(capacity: 3, clock: clock)),
       _compatibilityAccess = compatibilityAccess,
       wallet = wallet ?? ZyraSubscriptionWalletDraft.sample(),
       membershipPaymentHistory = membershipPaymentHistory,
       activityExample = activityExample {
    fixture = ZyraOneJourneyShellFixture(
      model: _model,
      changes: this,
      wallet: this.wallet,
      membershipPaymentHistory: membershipPaymentHistory,
      activityExample: activityExample,
      timeline: timelineFor,
      readState: _consumeState,
      onAttached: (isCurrent) => _isCurrent = isCurrent,
      onCaptureGuardAttached: (capture) => _captureGuard = capture,
      onModelAttached: (model) => _model = model,
      onCheckpoint: _recordCheckpoint,
      compatibilityAccess: compatibilityAccess,
      onCompatibilityAccessAttached: (access) => _compatibilityAccess = access,
      onStateAttached: (state) {
        guardianRole = state.guardianRole ?? guardianRole;
        this.wallet = state.wallet ?? this.wallet;
        this.membershipPaymentHistory =
            state.membershipPaymentHistory ?? this.membershipPaymentHistory;
        seekerMembership = state.seekerMembership ?? seekerMembership;
        guardianMembership = state.guardianMembership ?? guardianMembership;
      },
    );
  }

  ViewRequestDraftModel? _model;
  ViewRequestDraftModel get model => _model!;
  ZyraDraftCompatibilityAccessStore? _compatibilityAccess;
  ZyraDraftCompatibilityAccessStore? get compatibilityAccess =>
      _compatibilityAccess;
  late final ZyraOneJourneyShellFixture fixture;
  ZyraSubscriptionWalletDraft wallet;
  ZyraMembershipPaymentHistory membershipPaymentHistory;
  ZyraMyZyraActivityExample? activityExample;
  final _timelines = <String, ZyraDraftTimelinePreview>{};
  bool Function()? _isCurrent;
  bool Function() Function()? _captureGuard;
  bool Function() captureGuard() => _captureGuard?.call() ?? () => false;
  ZyraOneJourneyShellFixtureState? _pending;
  ZyraPreviewNavigationCheckpoint? latest;
  bool setupScopeOpen = false;
  bool guardianRole = false;
  String seekerMembership = 'Seeker One', guardianMembership = 'Guardian One';

  int revision = 0;
  bool get current => _isCurrent?.call() == true;
  ZyraWalletRole get role =>
      guardianRole ? ZyraWalletRole.guardian : ZyraWalletRole.seeker;

  ZyraOneJourneyShellFixtureState? _consumeState() {
    final value = _pending;
    _pending = null;
    return value;
  }

  bool update(VoidCallback change, {ZyraOneJourneyShellFixtureState? state}) {
    if (!current) return false;
    change();
    _pending = state;
    revision++;
    notifyListeners();
    return true;
  }

  bool refresh({ZyraOneJourneyShellFixtureState? state}) =>
      update(() {}, state: state);

  bool changeModel(VoidCallback change) => update(change);

  bool selectRole(bool guardian) {
    if (!current) return false;
    guardianRole = guardian;
    return refresh(
      state: ZyraOneJourneyShellFixtureState(guardianRole: guardian),
    );
  }

  bool showJourneys(int count, {int tab = 1}) {
    if (!current || !model.seedJourneys(count)) return false;
    guardianRole = false;
    return refresh(
      state: ZyraOneJourneyShellFixtureState(guardianRole: false, tab: tab),
    );
  }

  bool setSeekerBasic(bool basic) {
    if (!current || !model.setCapacity(basic ? 1 : 3)) return false;
    seekerMembership = basic ? 'Seeker Basic' : 'Seeker One';
    wallet = wallet.withRole(
      ZyraWalletRole.seeker,
      coverage: basic
          ? ZyraWalletCoverage.basic
          : ZyraWalletCoverage.individualOne,
    );
    return refresh(
      state: ZyraOneJourneyShellFixtureState(
        wallet: wallet,
        seekerMembership: seekerMembership,
      ),
    );
  }

  bool setGuardianBasic(String id, bool basic) {
    if (!current ||
        !model.setSampleGuardianMembership(
          id,
          basic ? DraftGuardianMembership.basic : DraftGuardianMembership.one,
        )) {
      return false;
    }
    if (id != 'draft-guardian-hassan') return refresh();
    guardianMembership = basic ? 'Guardian Basic' : 'Guardian One';
    wallet = wallet.withRole(
      ZyraWalletRole.guardian,
      coverage: basic
          ? ZyraWalletCoverage.basic
          : ZyraWalletCoverage.individualOne,
    );
    return refresh(
      state: ZyraOneJourneyShellFixtureState(
        wallet: wallet,
        guardianMembership: guardianMembership,
      ),
    );
  }

  bool setOtherReadiness(ZyraWalletReadiness readiness) {
    if (!current) return false;
    wallet = wallet.withRole(role.other, readiness: readiness);
    return refresh(state: ZyraOneJourneyShellFixtureState(wallet: wallet));
  }

  bool setOtherCoverage(ZyraWalletCoverage coverage) {
    if (!current) return false;
    wallet = wallet
        .withRole(role.other, coverage: coverage)
        .copyWith(
          places: wallet.places.where(
            (place) =>
                place.role != role.other ||
                place.state != ZyraWalletPlaceState.available,
          ),
        );
    return refresh(state: ZyraOneJourneyShellFixtureState(wallet: wallet));
  }

  bool setOtherSparePlace() {
    if (!current) return false;
    wallet = wallet
        .withRole(role.other, coverage: ZyraWalletCoverage.none)
        .copyWith(
          places: ZyraSubscriptionWalletDraft.sample().places,
          inventoryAvailable: true,
        );
    return refresh(state: ZyraOneJourneyShellFixtureState(wallet: wallet));
  }

  bool setPaymentHistory(ZyraMembershipPaymentHistory history) {
    if (!current) return false;
    membershipPaymentHistory = history;
    return refresh(
      state: ZyraOneJourneyShellFixtureState(membershipPaymentHistory: history),
    );
  }

  bool selectActivity(ZyraMyZyraActivityExample? example) {
    if (!current) return false;
    activityExample = example;
    return refresh(
      state: ZyraOneJourneyShellFixtureState(
        activityExample: example,
        replaceActivity: true,
      ),
    );
  }

  void _recordCheckpoint(ZyraPreviewNavigationCheckpoint checkpoint) {
    final previous = latest;
    if (previous != null &&
        previous.pages.contains('timeline') &&
        (previous.personId != checkpoint.personId ||
            !checkpoint.pages.contains('timeline'))) {
      // DEV_TOGGLES brief step 5: these are caller-owned test examples.
      // Closing their addressed page ends the transient example, while the
      // model and the cached Timeline's actual history stay untouched.
      _timelines[previous.personId]?.selectScenario(
        ZyraDraftTimelineScenario.current,
      );
    }
    latest = checkpoint;
  }

  ZyraDraftTimelinePreview timelineFor(String id) =>
      _timelines[id] ??
      ZyraDraftTimelinePreview(
        id,
        firstName: draftProfiles.firstWhere((p) => p.id == id).firstName,
        journeyState: model.stateFor(id),
        stageValue: model.stageFor(id)?.value,
        compatibilityRevealed: model.compatibilityRevealed(id),
        endedAttempts: model.endedAttemptsFor(id),
      );

  bool selectTimelineScenario(String id, ZyraDraftTimelineScenario scenario) {
    if (!current) return false;
    final timeline = timelineFor(id)..selectScenario(scenario);
    _timelines[id] = timeline;
    return refresh(
      state: ZyraOneJourneyShellFixtureState(
        timeline: timeline,
        replaceTimeline: true,
      ),
    );
  }

  bool selectTimelineEvent(String id, String event) {
    if (!current) return false;
    final timeline = timelineFor(id)..selectEvent(event);
    _timelines[id] = timeline;
    return refresh(
      state: ZyraOneJourneyShellFixtureState(
        timeline: timeline,
        replaceTimeline: true,
      ),
    );
  }

  bool selectTimelineStage(String id, String stage) {
    if (!current) return false;
    final timeline = timelineFor(id)..selectStage(stage);
    _timelines[id] = timeline;
    return refresh(
      state: ZyraOneJourneyShellFixtureState(
        timeline: timeline,
        replaceTimeline: true,
      ),
    );
  }

  bool selectBrowseMotion(ZyraBrowseNextMotion motion) =>
      refresh(state: ZyraOneJourneyShellFixtureState(browseNextMotion: motion));

  bool selectCircleBubble(ZyraCircleBubbleDesign design) => refresh(
    state: ZyraOneJourneyShellFixtureState(circleBubbleDesign: design),
  );

  bool reset() {
    if (!current) return false;
    model.setCapacity(3);
    model.reset();
    _timelines.clear();
    wallet = ZyraSubscriptionWalletDraft.sample(ownerId: wallet.ownerId);
    guardianRole = false;
    seekerMembership = 'Seeker One';
    guardianMembership = 'Guardian One';
    membershipPaymentHistory = ZyraMembershipPaymentHistory.paidBefore;
    activityExample = null;
    compatibilityAccess?.reset();
    return refresh(
      state: ZyraOneJourneyShellFixtureState(
        guardianRole: false,
        tab: 0,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: model.snapshot(),
          tab: 0,
          pages: const [],
          guardianTabs:
              latest?.guardianTabs ?? const ZyraGuardianTabsSnapshot(),
        ),
        wallet: wallet,
        membershipPaymentHistory: membershipPaymentHistory,
        seekerMembership: seekerMembership,
        guardianMembership: guardianMembership,
        replaceActivity: true,
        replaceTimeline: true,
        circleBubbleDesign: ZyraCircleBubbleDesign.current,
      ),
    );
  }
}

ZyraShellTestFixture zyraShellFixtureFor(WidgetTester tester) {
  final shell = find.byType(ZyraOneJourneyConceptShell);
  expect(shell, findsOneWidget);
  final fixture = tester.widget<ZyraOneJourneyConceptShell>(shell).fixture;
  expect(
    fixture,
    isNotNull,
    reason:
        'Inject a ZyraShellTestFixture.fixture '
        'through the shell or ViewRequestDraftScreen constructor.',
  );
  expect(fixture!.changes, isA<ZyraShellTestFixture>());
  return fixture.changes! as ZyraShellTestFixture;
}

/// Physical root-tab navigation is two deliberate taps when LOCK 6 is idle.
/// Expand through the real bar before callers measure their destination; the
/// moving small icons are not destination-sized touch targets. Legacy/action
/// bars have no compact surface and are deliberately left alone.
Future<void> expandZyraPreviewTabBarIfIdle(WidgetTester tester) async {
  final surface = find.byKey(const ValueKey('compact-nav-surface'));
  if (surface.evaluate().isEmpty) return;
  expect(surface, findsOneWidget);
  final root = find.byType(ZyraShellNavigation);
  expect(root, findsOneWidget);
  final navigation = tester.widget<ZyraShellNavigation>(root);
  final context = tester.element(surface);
  if (!navigation.interactionEnabled ||
      ModalRoute.of(context)?.isCurrent == false ||
      surface.hitTestable().evaluate().isEmpty) {
    return;
  }
  final viewport = MediaQuery.sizeOf(context).width;
  final fullWidth =
      viewport -
      2 * (navigation.contentEdgeInset ?? ZyraNavBarMetrics.sideInset);
  if (tester.getSize(surface).width >
          fullWidth * (navigation.compactV2 ? .6 : .4) + .01 &&
      tester.getSize(surface).width < fullWidth - .01) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (tester.getSize(surface).width >= fullWidth - .01) return;
  final selected = navigation.currentIndex;
  await tester.tapAt(tester.getCenter(surface));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(tester.takeException(), isNull);
  expect(tester.getSize(surface).width, closeTo(fullWidth, .01));
  expect(tester.widget<ZyraShellNavigation>(root).currentIndex, selected);
}

/// Finder-based legacy helpers can configure removed choices without creating
/// a matching widget. Unrecognized targets continue through real UI actions.
Future<bool> pressZyraFixtureFinder(WidgetTester tester, Finder target) async {
  final match = RegExp(
    r"\[<'([^']+)'>\]",
  ).firstMatch(target.describeMatch(Plurality.one));
  if (match == null) return false;
  return pressZyraDevControlKey(tester, match.group(1)!);
}

/// Legacy setup names only mark a test-side configuration scope. No widget,
/// route, hold gesture, button or developer control exists in the app.
Future<void> openZyraDevControls(WidgetTester tester) async {
  final fixture = zyraShellFixtureFor(tester);
  if (fixture.current) {
    fixture.setupScopeOpen = true;
    fixture.refresh();
  }
  await tester.pump();
}

Future<void> closeZyraDevControls(WidgetTester tester) async {
  final fixture = zyraShellFixtureFor(tester);
  fixture.setupScopeOpen = false;
  fixture.refresh();
  await tester.pump();
}

Future<void> toggleZyraDevControls(WidgetTester tester) async {
  final fixture = zyraShellFixtureFor(tester);
  if (fixture.current) {
    fixture.setupScopeOpen = !fixture.setupScopeOpen;
    fixture.refresh();
  }
  await tester.pump();
}

/// Exercise the same left-edge gesture as a sighted user, including the
/// committed closing animation. Never invoke a shell-state callback instead.
Future<void> swipeZyraBack(WidgetTester tester) async {
  final edge = find
      .byKey(const ValueKey('zyra_back_swipe_edge'))
      .hitTestable()
      .last;
  expect(edge, findsOneWidget);
  final rect = tester.getRect(edge);
  final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.timedDragFrom(
    Offset(rect.left + 8, rect.top + rect.height * .4),
    Offset(viewport.width * .72, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Capture the real accessibility action for stale-owner rejection tests.
/// This is not the physical navigation driver and creates no hidden button.
VoidCallback captureZyraAccessibleBack(WidgetTester tester) {
  final semantics = find
      .byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.key == const ValueKey('zyra_pull_down_back_semantics') &&
            widget.properties.onDismiss != null,
      )
      .last;
  expect(semantics, findsOneWidget);
  final action = tester.widget<Semantics>(semantics).properties.onDismiss;
  expect(action, isNotNull);
  return action!;
}

Future<void> returnZyraPreviewPage(WidgetTester tester) async {
  final fixture = zyraShellFixtureFor(tester);
  if (fixture.setupScopeOpen) {
    await closeZyraDevControls(tester);
  } else {
    await swipeZyraBack(tester);
  }
}

Future<void> leaveZyraDeveloperPreview(WidgetTester tester) async {
  final shell = find.byType(ZyraOneJourneyConceptShell);
  expect(shell, findsOneWidget);
  final widget = tester.widget<ZyraOneJourneyConceptShell>(shell);
  if (zyraShellFixtureFor(tester).current) widget.onExit();
  await tester.pumpAndSettle();
}

bool isZyraFixtureCommandKey(String key) =>
    key == 'draft_role_guardian' ||
    key == 'draft_role_seeker' ||
    key.startsWith('concept_journey_preview_') ||
    key.startsWith('draft_membership_seeker_') ||
    key.startsWith('concept_guardian_plan_') ||
    key.startsWith('concept_wallet_coverage_') ||
    key == 'concept_wallet_spare_place' ||
    key == 'concept_switch_ready' ||
    key == 'concept_switch_needs_signup' ||
    key.startsWith('concept_membership_history_') ||
    key.startsWith('draft_compatibility_unlock_') ||
    key.startsWith('draft_peer_bio_') ||
    key.startsWith('draft_peer_salam_') ||
    key.startsWith('draft_peer_reveal_') ||
    key.startsWith('draft_stage_peer_ready_') ||
    key.startsWith('concept_requests_controls_') ||
    key.startsWith('activity-checklist-') ||
    [
      'activity-preview-previous',
      'activity-preview-next',
      'activity-preview-current',
      'activity-preview-checklist',
    ].contains(key) ||
    key.startsWith('concept_timeline_') ||
    key.startsWith('concept_browse_next_motion_') ||
    key.startsWith('concept_circle_bubble_design_') ||
    key == 'concept_activity_checklist' ||
    key == 'draft_history' ||
    key == 'draft_reset';

/// A retained fixture delegate is bound to its exact code-configuration epoch.
/// It cannot borrow a newer configuration or a replaced/covered shell owner.
ValueChanged<T> captureZyraFixtureChange<T>(
  WidgetTester tester,
  void Function(ZyraShellTestFixture, T) change,
) {
  final fixture = zyraShellFixtureFor(tester);
  final revision = fixture.revision;
  final guard = fixture.captureGuard();
  return (value) {
    if (guard() && fixture.current && fixture.revision == revision) {
      change(fixture, value);
    }
  };
}

ValueChanged<ZyraDraftTimelineScenario> captureZyraTimelineScenarioAction(
  WidgetTester tester,
) {
  final view = tester.widget<ZyraDraftTimelinePresentation>(
    find.byType(ZyraDraftTimelinePresentation),
  );
  return captureZyraFixtureChange(
    tester,
    (fixture, scenario) =>
        fixture.selectTimelineScenario(view.subjectId, scenario),
  );
}

ValueChanged<ZyraBrowseNextMotion> captureZyraBrowseMotionAction(
  WidgetTester tester,
) => captureZyraFixtureChange(
  tester,
  (fixture, motion) => fixture.selectBrowseMotion(motion),
);

VoidCallback? captureZyraFixtureCommand(WidgetTester tester, String key) {
  if (!isZyraFixtureCommandKey(key) &&
      !['dev_controls_close', 'draft_close'].contains(key)) {
    return null;
  }
  final fixture = zyraShellFixtureFor(tester);
  if (!fixture.current) return null;
  if (key.startsWith('concept_journey_preview_') &&
      int.parse(key.split('_').last) > fixture.model.capacity) {
    return null;
  }
  final shell = tester.widget<ZyraOneJourneyConceptShell>(
    find.byType(ZyraOneJourneyConceptShell),
  );
  final revision = fixture.revision;
  final guard = fixture.captureGuard();
  return () {
    if (!guard() || !fixture.current || fixture.revision != revision) return;
    if (key == 'draft_role_guardian' || key == 'draft_role_seeker') {
      fixture.selectRole(key == 'draft_role_guardian');
    } else if (key.startsWith('concept_journey_preview_')) {
      fixture.showJourneys(int.parse(key.split('_').last));
    } else if (key == 'draft_reset') {
      fixture.reset();
    } else if (key == 'draft_history') {
      fixture.changeModel(fixture.model.seedHistory);
    } else if (key.startsWith('draft_compatibility_unlock_')) {
      fixture.update(
        () => fixture.compatibilityAccess?.setBalance(
          count: int.parse(key.split('_').last),
        ),
      );
    } else if (key.startsWith('concept_membership_history_')) {
      fixture.setPaymentHistory(
        ZyraMembershipPaymentHistory.values.byName(
          key.substring('concept_membership_history_'.length),
        ),
      );
    } else if (key == 'dev_controls_close') {
      fixture.setupScopeOpen = false;
      fixture.refresh();
    } else if (key == 'draft_close') {
      shell.onExit();
    } else if (key.startsWith('draft_membership_seeker_')) {
      fixture.setSeekerBasic(key.endsWith('_basic'));
    } else {
      throw StateError('No retained fixture command mapping for $key');
    }
  };
}

/// Legacy setup command names configure only the injected code fixture.
/// Real member Profile Switch still follows its two physical UI actions.
Future<bool> pressZyraDevControlKey(WidgetTester tester, String key) async {
  if (key == 'draft_rules') {
    await openZyraDevControls(tester);
    return true;
  }
  if (key == 'draft_back') {
    await toggleZyraDevControls(tester);
    return true;
  }
  if (key == 'draft_close') {
    await leaveZyraDeveloperPreview(tester);
    return true;
  }
  final recognized = isZyraFixtureCommandKey(key);
  if (!recognized) return false;
  final fixture = zyraShellFixtureFor(tester);
  final isRole = key == 'draft_role_guardian' || key == 'draft_role_seeker';
  if (isRole &&
      !fixture.setupScopeOpen &&
      find
          .byKey(const ValueKey('switch-account-button'))
          .evaluate()
          .isNotEmpty) {
    if (!fixture.current) return true;
    final button = find.byKey(const ValueKey('switch-account-button'));
    await Scrollable.ensureVisible(tester.element(button), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    final role = key == 'draft_role_guardian' ? 'guardian' : 'seeker';
    final confirm = find.byKey(ValueKey('wallet_primary_$role'));
    await Scrollable.ensureVisible(tester.element(confirm), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    fixture.guardianRole = role == 'guardian';
    expect(tester.takeException(), isNull);
    return true;
  }
  if (!fixture.current) return true;
  if (isRole) {
    fixture.selectRole(key == 'draft_role_guardian');
  } else if (key.startsWith('concept_journey_preview_')) {
    fixture.showJourneys(int.parse(key.split('_').last));
  } else if (key.startsWith('draft_membership_seeker_')) {
    fixture.setSeekerBasic(key.endsWith('_basic'));
  } else if (key.startsWith('concept_guardian_plan_')) {
    final value = key.substring('concept_guardian_plan_'.length);
    final split = value.lastIndexOf('_');
    fixture.setGuardianBasic(value.substring(0, split), value.endsWith('_0'));
  } else if (key == 'concept_switch_ready' ||
      key == 'concept_switch_needs_signup') {
    fixture.setOtherReadiness(
      key == 'concept_switch_ready'
          ? ZyraWalletReadiness.ready
          : ZyraWalletReadiness.missing,
    );
  } else if (key.startsWith('concept_wallet_coverage_')) {
    final name = key.substring('concept_wallet_coverage_'.length);
    fixture.setOtherCoverage(ZyraWalletCoverage.values.byName(name));
  } else if (key == 'concept_wallet_spare_place') {
    fixture.setOtherSparePlace();
  } else if (key.startsWith('concept_membership_history_')) {
    fixture.setPaymentHistory(
      ZyraMembershipPaymentHistory.values.byName(
        key.substring('concept_membership_history_'.length),
      ),
    );
  } else if (key.startsWith('draft_compatibility_unlock_')) {
    fixture.update(
      () => fixture.compatibilityAccess?.setBalance(
        count: int.parse(key.split('_').last),
      ),
    );
  } else if (key.startsWith('concept_requests_controls_')) {
    fixture.refresh(
      state: ZyraOneJourneyShellFixtureState(
        requestsTab: int.parse(key.split('_').last),
      ),
    );
  } else if (key == 'concept_activity_checklist' ||
      key == 'activity-preview-checklist') {
    fixture.setupScopeOpen = true;
  } else if (key == 'activity-checklist-current' ||
      key == 'activity-preview-current') {
    fixture.selectActivity(null);
  } else if (key.startsWith('activity-checklist-')) {
    fixture.selectActivity(
      ZyraMyZyraActivityExample.values.byName(
        key.substring('activity-checklist-'.length),
      ),
    );
  } else if (key == 'activity-preview-previous' ||
      key == 'activity-preview-next') {
    final values = ZyraMyZyraActivityExample.values;
    final delta = key.endsWith('previous') ? -1 : 1;
    fixture.selectActivity(
      values[((fixture.activityExample?.index ?? 0) + delta) % values.length],
    );
  } else if (key.startsWith('concept_browse_next_motion_')) {
    fixture.selectBrowseMotion(
      ZyraBrowseNextMotion.values.byName(
        key.substring('concept_browse_next_motion_'.length),
      ),
    );
  } else if (key.startsWith('concept_circle_bubble_design_')) {
    fixture.selectCircleBubble(
      ZyraCircleBubbleDesign.values.byName(
        key.substring('concept_circle_bubble_design_'.length),
      ),
    );
  } else if (key.startsWith('concept_timeline_')) {
    final view = find.byType(ZyraDraftTimelinePresentation);
    expect(view, findsOneWidget);
    final id = tester.widget<ZyraDraftTimelinePresentation>(view).subjectId;
    if (key.startsWith('concept_timeline_scenario_')) {
      final name = key
          .substring('concept_timeline_scenario_'.length)
          .split('.')
          .last;
      fixture.selectTimelineScenario(
        id,
        ZyraDraftTimelineScenario.values.byName(name),
      );
    } else if (key.startsWith('concept_timeline_event_')) {
      fixture.selectTimelineEvent(
        id,
        key.substring('concept_timeline_event_'.length),
      );
    } else if (key.startsWith('concept_timeline_stage_')) {
      fixture.selectTimelineStage(
        id,
        key.substring('concept_timeline_stage_'.length),
      );
    }
  } else if (key == 'draft_history') {
    fixture.changeModel(fixture.model.seedHistory);
  } else if (key == 'draft_reset') {
    fixture.reset();
  } else {
    final prefixes = <String, bool Function(String)>{
      'draft_peer_bio_reveal_': fixture.model.simulatePeerBioReveal,
      'draft_peer_bio_ready_': fixture.model.simulatePeerBioContinue,
      'draft_peer_salam_': fixture.model.simulatePeerSalam,
      'draft_peer_reveal_': fixture.model.simulatePeerCompatibilityReveal,
      'draft_stage_peer_ready_': fixture.model.simulatePeerStageContinue,
    };
    for (final entry in prefixes.entries) {
      if (key.startsWith(entry.key)) {
        fixture.changeModel(() => entry.value(key.substring(entry.key.length)));
        break;
      }
    }
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return true;
}
