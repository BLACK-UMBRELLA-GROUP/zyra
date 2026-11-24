// OA-ZYRA-371: automatic LOCK14 V9 raster gate, using the real route fixtures.
// Ordinary capture paths are untouched; this registration writes build/ only.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_first_tour_overlay.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/screens/welcome_screen.dart';

import 'zyra_rendered_text_contrast.dart';
import '../visual/baseline_capture_support.dart';
import '../visual/oa316_seeker_baseline_capture_test.dart' as seeker;
import '../visual/basic_plans_capture_test.dart' as basic;
import '../visual/lock8_guardian_tabs_capture_test.dart' as guardian;
import '../visual/line121_signup_capture_test.dart' as signup;
import '../visual/line124_first_tour_capture_test.dart' as tour;
import '../visual/line119_membership_capture_test.dart' as membership;
import '../visual/line118_menu_sheet_capture_test.dart' as menus;
import '../visual/line98_ended_journeys_visual_test.dart' as ended;
import '../visual/line88_guardian_compatibility_test.dart' as compatibility;
import '../visual/guardian_chat_v4_capture_test.dart' as chat;
import '../visual/lock22_v4_settings_edit_profile_test.dart' as settings;
import '../visual/lock22_safety_advice_v6_capture_test.dart' as safety;
import '../visual/lock10_filters_capture_test.dart' as filters;
import '../visual/lock20_circle_topics_capture_test.dart' as circle;
import '../visual/lock19_v3_family_acceptance_test.dart' as family;
import '../visual/lock35_guardian_seekers_test.dart' as seekers;
import '../visual/lock12_phone_access_capture_test.dart' as phone;
import '../visual/lock15_focus_capture_test.dart' as focus;
import '../visual/line120_recovery_removal_capture_test.dart' as recovery;
import '../visual/line126_remaining_routes_test.dart' as remaining;
import '../visual/line126_coverage_entry_routes_test.dart' as entries;

const _reportOnly = bool.fromEnvironment('ZYRA_LINE126_REPORT_ONLY');
const _alphaCheck = bool.fromEnvironment('ZYRA_LINE126_ALPHA_CHECK');

class ZyraContrastDriver {
  const ZyraContrastDriver(this.id, this.viewports);
  final String id;
  final List<BaselineAuditViewport> viewports;
}

const zyraContrastNormal430 = ZyraContrastDriver('normal-430', [
  BaselineAuditViewport(Size(430, 932), 1),
]);
const zyraContrastNormal = ZyraContrastDriver('normal', [
  BaselineAuditViewport(Size(375, 667), 1),
]);
const zyraContrastLarge430 = ZyraContrastDriver('large-430', [
  BaselineAuditViewport(Size(430, 932), 1.3),
]);
const zyraContrastLarge375 = ZyraContrastDriver('large-375', [
  BaselineAuditViewport(Size(375, 667), 1.3),
]);
ZyraContrastDriver _driver = zyraContrastNormal;
List<BaselineAuditViewport> get _viewports => _driver.viewports;
String get _reportPath => 'build/line126-rebuild-contrast-${_driver.id}.json';
String get _progressPath =>
    'build/line126-rebuild-contrast-${_driver.id}-progress.json';
final _clock = Stopwatch();
final _frames = <Map<String, Object?>>[];
final _excludedLegacyWelcomeFrames = <Map<String, Object?>>[];
final _failures = <Map<String, Object?>>[];
final _groups = <String>{}, _plans = <String>{}, _routes = <String>{};
final _tabs = <String>{}, _steps = <String>{}, _tourFrames = <String>{};
final _measuredTuples = <String>{};
final _nonTextObservations = <Map<String, Object?>>[];
final _signupCoverage = <String>{}, _signupSelections = <String>{};
const _guardianSignupExclusions = {
  'gender',
  'location',
  'nationality',
  'ethnicity',
  'photos',
  'membership',
  'preferences',
  'addGuardian',
};
const _seekerSignupExclusions = {'relationship', 'addSeeker'};
var _runs = 0, _pixels = 0, _exemptPixels = 0, _modalExemptPixels = 0;
var _lastProgressMs = 0;
var _cacheHits = 0, _rasterImages = 0, _occlusionFringePixels = 0;

Set<String> _expectedRoutes() {
  final source = File(
    'lib/dev/zyra_one_journey_concept_shell.dart',
  ).readAsStringSync();
  final content = source.substring(
    source.indexOf('Widget _content()'),
    source.indexOf('VoidCallback _bound('),
  );
  return RegExp(
      r"^\s*'([a-z_]+)'(?=\s*(?:=>|\|\|))",
      multiLine: true,
    ).allMatches(content).map((match) => match.group(1)!).toSet()
    ..addAll(['guardian_circle', 'journey_options'])
    ..removeAll([
      'saved',
      'paused',
      'past_journeys',
      'guardian_network_profile',
    ]);
}

List<Map<String, Object?>> _routeMatrix() {
  const seekerOnly = {
    'profile',
    'journey',
    'request_capacity',
    'journey_compatibility',
    'journey_compatibility_locked',
    'journey_guardians',
    'journey_options',
    'ended_archive',
    'ended_bio',
    'ended_guardians',
    'ended_restart',
    'ended_compatibility',
    'guardian_access_agreement',
    'guardian_invite',
    'guardian_main_notice',
    'guardian_info',
    'requests',
    'introductions',
    'ended',
    'edit_profile',
    'preference_quick_check',
    'filter_preferences',
    'bio',
    'bio_locked',
    'compatibility',
    'filters',
    'scan',
    'timeline',
    'developer_inactivity_email',
  };
  const guardianOnly = {
    // Only _boundGuardianAction reaches _holdPreviewAction; it explicitly
    // rejects !_guardianRole (concept_shell:8876-8888).
    'held_action',
    // Guardian-tab and Circle Guardian actions only; Seeker restore whitelist
    // omits it (concept_shell:1977-2001, 7920, 8876-8888).
    'guardian',
    'guardian_compatibility',
    'guardian_compatibility_upgrade',
    'network_request',
    'guardian_introduce',
    'guardian_family_offer',
    'guardian_free_place_invite',
    'guardian_family_identity',
    'guardian_requests',
    'guardian_connect',
    'guardian_introductions',
    'guardian_seeker',
    'guardian_private_chat',
    'guardian_chat_report',
    'guardian_linked_profile',
  };
  final rows = <Map<String, Object?>>[];
  for (final route in _expectedRoutes().toList()..sort()) {
    if (route == 'signup') continue; // typed detached-flow matrix below
    final roles = seekerOnly.contains(route)
        ? ['Seeker']
        : guardianOnly.contains(route)
        ? ['Guardian']
        : ['Seeker', 'Guardian'];
    for (final role in roles) {
      for (final tier in ['One', 'Basic']) {
        if ({
              'guardian_family_offer',
              'guardian_family_identity',
              'guardian_free_place_invite',
            }.contains(route) &&
            tier != 'Basic') {
          continue;
        }
        if (route == 'guardian_compatibility_upgrade' && tier != 'Basic') {
          continue;
        }
        if ({
              'membership',
              'membership_review',
              'network_request',
              'guardian_introduce',
              'guardian_requests',
              'guardian_connect',
              'guardian_introductions',
              'guardian_private_chat',
              'guardian_chat_report',
            }.contains(route) &&
            tier != 'One') {
          continue;
        }
        if (route == 'one_upgrade' && tier != 'Basic') continue;
        final plan = '$role $tier';
        final measured = _frames
            .where(
              (frame) =>
                  frame['plan'] == plan &&
                  frame['rendered_route'] == route &&
                  (frame['runs'] as int) > 0,
            )
            .map((frame) => frame['viewport'] as String)
            .toSet();
        rows.add({
          'route': route,
          'plan': plan,
          'viewports': measured.toList()..sort(),
          'missing_viewports': [
            for (final viewport in _viewports)
              if (!measured.contains(viewport.id)) viewport.id,
          ],
        });
      }
    }
  }
  return rows;
}

List<String> _coverageGaps() {
  final gaps = <String>[];
  for (final prefix in [
    'seeker',
    'basic_seeker',
    'basic_guardian',
    'lock8_',
    'line121_',
    'line124_',
    'line119_',
    'line118_',
    'line98_',
    'line88_',
    'queue70_',
    'settings_',
    'safety_',
    'lock10_',
    'lock20_',
    'lock19_',
    'lock35',
    'lock12_',
    'lock15_',
    'line120',
    'line126_remaining_',
    'line126_entry_',
  ]) {
    if (!_groups.any((group) => group.startsWith(prefix))) {
      gaps.add('suite:$prefix');
    }
  }
  for (final plan in [
    'Seeker One',
    'Seeker Basic',
    'Guardian One',
    'Guardian Basic',
  ]) {
    if (!_plans.contains(plan)) gaps.add('plan:$plan');
    for (var tab = 0; tab < 5; tab++) {
      if (!_tabs.contains('$plan:$tab')) gaps.add('tab:$plan:$tab');
    }
  }
  for (final step in ZyraSignupStep.values) {
    if (!_steps.contains(step.name)) gaps.add('signup:${step.name}');
  }
  for (final viewport in _viewports) {
    for (final step in ZyraSignupStep.values) {
      if ({'splash', 'welcome'}.contains(step.name)) {
        if (!_signupCoverage.contains('shared:${step.name}:${viewport.id}')) {
          gaps.add('signup_flow:shared:${step.name}:${viewport.id}');
        }
        continue;
      }
      for (final role in ['Seeker', 'Guardian']) {
        final exclusions = role == 'Guardian'
            ? _guardianSignupExclusions
            : _seekerSignupExclusions;
        if (!exclusions.contains(step.name) &&
            !_signupCoverage.contains('$role:${step.name}:${viewport.id}')) {
          gaps.add('signup_flow:$role:${step.name}:${viewport.id}');
        }
      }
    }
    for (final selection in ['One', 'Basic']) {
      if (!_signupSelections.contains('$selection:${viewport.id}')) {
        gaps.add('signup_membership_selection:$selection:${viewport.id}');
      }
    }
  }
  for (final (role, count) in [('seeker', 20), ('guardian', 16)]) {
    for (var index = 0; index < count; index++) {
      if (!_tourFrames.contains('$role:$index')) {
        gaps.add('walkthrough:$role:$index');
      }
    }
  }
  for (final viewport in _viewports) {
    if (!_measuredTuples.contains(viewport.id)) {
      gaps.add('viewport:${viewport.id}');
    }
  }
  final source = File(
    'lib/dev/zyra_one_journey_concept_shell.dart',
  ).readAsStringSync();
  final content = source.substring(
    source.indexOf('Widget _content()'),
    source.indexOf('VoidCallback _bound('),
  );
  final expected =
      RegExp(
          r"^\s*'([a-z_]+)'(?=\s*(?:=>|\|\|))",
          multiLine: true,
        ).allMatches(content).map((match) => match.group(1)!).toSet()
        ..addAll(['guardian_circle', 'journey_options']);
  expected.removeAll([
    'saved',
    'paused',
    'past_journeys',
    'guardian_network_profile',
  ]);
  for (final route in expected) {
    if (!_routes.contains(route)) gaps.add('current_route:$route');
  }
  for (final row in _routeMatrix()) {
    for (final viewport in row['missing_viewports']! as List) {
      gaps.add('route_plan_viewport:${row['route']}:${row['plan']}:$viewport');
    }
  }
  return gaps..sort();
}

Map<String, Object?> _report() => {
  'rule': 'LOCK14 V9 current locked clearer-text rules',
  'driver': _driver.id,
  'report_only': _reportOnly,
  'status': _failures.isEmpty && _coverageGaps().isEmpty ? 'pass' : 'fail',
  'wall_seconds': _clock.elapsedMilliseconds / 1000,
  'real_shadows': true,
  'font': 'bundled Poppins/Syne',
  'frames': _frames.length,
  'frames_seen': _frames.length,
  'unique_audits': _frames.length - _cacheHits,
  'cache_hits': _cacheHits,
  'raster_images': _rasterImages,
  'raster_pixel_ratio': 1,
  'production_external_backdrop':
      'ZyraAppGoldDecoration with actual genderGradient, matching main.dart MaterialApp.builder',
  'geometric_occlusion_aa_pixels': _occlusionFringePixels,
  'runs': _runs,
  'painted_pixels': _pixels,
  'exempt_pixels': _exemptPixels,
  'modal_backdrop_exempt_pixels': _modalExemptPixels,
  'viewports': _measuredTuples.toList()..sort(),
  'groups': _groups.toList()..sort(),
  'plans': _plans.toList()..sort(),
  'observed_routes': _routes.toList()..sort(),
  'route_plan_viewport_coverage': _routeMatrix(),
  'typed_signup_flow_coverage': _signupCoverage.toList()..sort(),
  'typed_signup_membership_selections': _signupSelections.toList()..sort(),
  'signup_flow_exclusions': {
    'authority': 'ZyraSignupPreviewController._initialSteps and _setupSteps',
    'shared_pre_role': ['splash', 'welcome'],
    'Seeker': _seekerSignupExclusions.toList()..sort(),
    'Guardian': _guardianSignupExclusions.toList()..sort(),
    'member_plan_scope':
        'Detached signup controllers have no admitted checkpoint plan; Guardian skips membership. Seeker One and Basic selections are measured explicitly.',
  },
  'route_plan_basis':
      'Current shell role gates, Basic Network gate and membership dispatch. Common routes conservatively require both roles/plans until a concrete current-source exclusion is established.',
  'inapplicable_route_plans': [
    {
      'routes': ['held_action'],
      'plans': ['Seeker One', 'Seeker Basic'],
      'authority':
          '_holdPreviewAction has only Guardian-tab callers; _boundGuardianAction explicitly rejects !_guardianRole (concept_shell:8876-8888)',
    },
    {
      'routes': ['guardian'],
      'plans': ['Seeker One', 'Seeker Basic'],
      'authority':
          'Guardian-tab actions and Guardian Circle context only; Seeker checkpoint whitelist omits this route (concept_shell:1977-2001,7920,8876-8888)',
    },
    {
      'routes': ['journey_options'],
      'plans': ['Guardian One', 'Guardian Basic'],
      'authority': '_canAddressJourneyDisclosure requires !guardianRole',
    },
    {
      'routes': ['guardian_family_offer', 'guardian_family_identity'],
      'plans': ['Guardian One'],
      'authority':
          '_pendingGuardianFamilyOffer requires Guardian Basic and linked Basic Main Guardian',
    },
    {
      'routes': ['guardian_free_place_invite'],
      'plans': ['Guardian One'],
      'authority':
          '_pendingGuardianFreePlace requires Guardian Basic and Seeker Basic with an unexpired invitation',
    },
    {
      'routes': ['guardian_private_chat', 'guardian_chat_report'],
      'plans': ['Guardian Basic'],
      'authority':
          '_guardianPrivateGuard requires Guardian One and an accepted Main-Guardian connection',
    },
  ],
  'coverage_gaps': _coverageGaps(),
  'excluded_presenters': [
    {
      'presenter': 'WelcomeScreen(devPreview:false)',
      'scope':
          'Ordinary pre-auth startup/AuthGate and legacy member recovery entry, outside the Founder-preview planned app named by AGENTS.md. The line120 ordinary provider-order assertions remain unchanged; no pixel or member-plan credit is granted.',
      'source_authority': [
        'main.dart:821-832 and auth_gate.dart:209 ordinary signed-out entry',
        'zyra_session_router.dart:80 Founder admission',
        'zyra_dev_local_preview.dart:234 and dev_discovery_directions.dart:151 Founder shell destination',
        'zyra_one_journey_concept_shell.dart:466-474,656 planned signup presenter',
      ],
      'planned_entry':
          'ZyraSignupPreview._welcome remains strictly audited through typed role-flow requirements at every assigned viewport. No generic wordmark exemption.',
      'unmeasured_fixture_callbacks': _excludedLegacyWelcomeFrames,
    },
  ],
  'excluded_routes': [
    {
      'routes': ['saved', 'paused'],
      'reason':
          'Retired member pages; current shell restoration excludes these states.',
    },
    {
      'routes': ['past_journeys'],
      'reason':
          'Retired alias; current ended_journeys and ended_archive are required.',
    },
    {
      'routes': ['guardian_network_profile'],
      'authority': 'OA-ZYRA-371',
      'reason':
          'Dormant presenter: no current opener and absent from guardianPages restoration whitelist. Remaining-route fixtures assert actual Network and rejected checkpoint; no rendered pass claimed.',
    },
  ],
  'exemptions': [
    'Q192 only painted content behind an actual modal dim while its sheet/dialog/menu is open; foreground remains strict',
    'walkthrough dimmed backdrop only; lit target and coach audited',
    'actual scroll-edge fade band only',
  ],
  'navigation_and_pixel_proof':
      'Existing route tests retain navigation/presenter assertions at their fixture geometry. The callback measures four tuples and their reflowed scroll extents, then restores geometry/offsets. Email pixels use the real presenter; existing developer-entry tests separately cover its protected opener.',
  'failures': _failures,
  'nontext_guard_observations': _nonTextObservations,
  'audited_states': _frames,
};

void _write(String path) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(_report()), flush: true);
}

Future<void> _measure(BaselineHarness h, String state) async {
  if (_clock.elapsed > const Duration(minutes: 25)) {
    throw TestFailure(
      'The bounded raster audit exceeded 25 minutes; report is incomplete.',
    );
  }
  final legacyWelcome = h.tester
      .widgetList<WelcomeScreen>(find.byType(WelcomeScreen))
      .any((widget) => !widget.devPreview);
  if (legacyWelcome) {
    _excludedLegacyWelcomeFrames.add({
      'group': h.group,
      'state': state,
      'presenter': 'WelcomeScreen(devPreview:false)',
      'reason': 'Concrete ordinary auth entry outside Founder-preview scope',
    });
    return;
  }
  final boundaryFinder = find.byKey(
    const ValueKey('zyra-founder-baseline-boundary'),
  );
  if (boundaryFinder.evaluate().isEmpty) {
    _failures.add({
      'group': h.group,
      'state': state,
      'coverage_error': 'Expected production-frame repaint boundary is missing',
    });
    return;
  }
  await h.prepareRasterFrame();
  for (final viewport in _viewports) {
    await h.withAuditViewport(viewport, () async {
      var scrollFrame = 0;
      Future<void> frame() async {
        // Q187 permits short entry/feedback fades. Existing implicit
        // controllers do not necessarily finish merely because MediaQuery
        // switches to Reduce Motion; advance one bounded settlement window.
        if (h.tester.binding.transientCallbackCount > 0) {
          await h.tester.pump(const Duration(milliseconds: 650));
          await h.tester.pump();
        }
        if (_clock.elapsed > const Duration(minutes: 25)) {
          throw TestFailure(
            'The bounded raster audit exceeded 25 minutes; report is incomplete.',
          );
        }
        final viewportError = h.auditViewportMismatch(viewport);
        if (viewportError != null) {
          _failures.add({
            'group': h.group,
            'state': state,
            'viewport': viewport.id,
            'coverage_error': viewportError,
          });
          return;
        }
        final boundary = h.tester.renderObject<RenderRepaintBoundary>(
          boundaryFinder,
        );
        final renderError = h.tester.takeException();
        final result = await auditZyraRenderedText(
          h.tester,
          boundary,
          collectRunDiagnostics: _alphaCheck,
          prepareBeforeCapture: () async {
            await h.prepareRasterFrame();
            // Readiness belongs inside the same unchanged driver deadline.
            if (_clock.elapsed > const Duration(minutes: 25)) {
              throw TestFailure(
                'The bounded raster audit exceeded 25 minutes; report is incomplete.',
              );
            }
          },
          verifyBeforeCapture: () {
            if (_clock.elapsed > const Duration(minutes: 25)) {
              throw TestFailure(
                'The bounded raster audit exceeded 25 minutes; report is incomplete.',
              );
            }
          },
          diagnosticPoints: _alphaCheck
              ? const [
                  Offset(88.5, 576.5),
                  Offset(80.5, 842.5),
                  Offset(132.5, 206.5),
                ]
              : const [],
        );
        final signupPresenters = h.tester
            .widgetList<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
            .toList();
        final signupController = signupPresenters.firstOrNull?.controller;
        final plan = signupController != null
            ? 'Signup ${signupController.guardian ? 'Guardian' : 'Seeker'}'
            : h.latest.guardian
            ? h.latest.guardianMembership
            : h.latest.seekerMembership;
        final currentRoute = signupController != null
            ? 'signup'
            : h.latest.pages.lastOrNull;
        final row = <String, Object?>{
          'group': h.group,
          'state': state,
          'viewport': viewport.id,
          'plan': plan,
          'tab': h.latest.tab,
          'pages': h.latest.pages,
          'rendered_route': currentRoute,
          'proof_kind':
              find.byType(ZyraOneJourneyConceptShell).evaluate().isNotEmpty
              ? 'shell_navigation'
              : 'direct_production_presenter',
          if (signupController != null)
            'signup_controller': {
              'role': signupController.guardian ? 'Guardian' : 'Seeker',
              'step': signupController.step.name,
              'membership_selection': signupController.membershipBasic
                  ? 'Basic'
                  : 'One',
            },
          'scroll_frame': scrollFrame++,
          'runs': result.runs,
          'pixels': result.paintedPixels,
          'exempt_pixels': result.exemptPixels,
          'modal_backdrop_exempt_pixels': result.modalExemptPixels,
          'failures': result.failures.length,
          if (result.diagnosticSamples.isNotEmpty)
            'diagnostic_samples': result.diagnosticSamples,
          if (result.diagnosticRuns.isNotEmpty)
            'run_diagnostics': result.diagnosticRuns,
          'cache_hit': result.cacheHit,
          'raster_images': result.rasterImages,
          'geometric_occlusion_aa_pixels': result.occlusionFringePixels,
        };
        _frames.add(row);
        if (renderError != null) {
          _failures.add({...row, 'render_error': renderError.toString()});
        }
        _runs += result.runs;
        if (result.cacheHit) _cacheHits++;
        _rasterImages += result.rasterImages;
        _occlusionFringePixels += result.occlusionFringePixels;
        _pixels += result.paintedPixels;
        _exemptPixels += result.exemptPixels;
        _modalExemptPixels += result.modalExemptPixels;
        if (result.runs > 0) {
          _groups.add(h.group);
          if (signupController == null) _plans.add(plan);
          if (currentRoute case final current?) {
            _routes.add(current);
          }
          if (signupController == null) _tabs.add('$plan:${h.latest.tab}');
          _measuredTuples.add(viewport.id);
          for (final widget in h.tester.widgetList<ZyraSignupPreview>(
            find.byType(ZyraSignupPreview),
          )) {
            _steps.add(widget.controller.step.name);
            final c = widget.controller;
            final role = {'splash', 'welcome'}.contains(c.step.name)
                ? 'shared'
                : c.guardian
                ? 'Guardian'
                : 'Seeker';
            _signupCoverage.add('$role:${c.step.name}:${viewport.id}');
            if (!c.guardian && c.step == ZyraSignupStep.membership) {
              _signupSelections.add(
                '${c.membershipBasic ? 'Basic' : 'One'}:${viewport.id}',
              );
            }
          }
          for (final widget in h.tester.widgetList<ZyraFirstTourOverlay>(
            find.byType(ZyraFirstTourOverlay),
          )) {
            _tourFrames.add(
              '${widget.guardian ? 'guardian' : 'seeker'}:${widget.index}',
            );
          }
        }
        if (result.runs == 0 && result.exemptPixels == 0) {
          _failures.add({
            ...row,
            'coverage_error':
                'Expected text-bearing fixture produced no visible text runs',
          });
        }
        for (final failure in result.failures) {
          _failures.add({...row, ...failure});
        }
        if (_frames.length == 1 ||
            _clock.elapsedMilliseconds - _lastProgressMs >= 5000) {
          _lastProgressMs = _clock.elapsedMilliseconds;
          _write(_progressPath);
          debugPrint(
            'LINE126 raster ${_frames.length} frames, ${_failures.length} failures; ${h.group} ${viewport.id}',
          );
        }
      }

      await frame();
      List<ScrollPosition> positions() => h.tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .where((state) => ModalRoute.of(state.context)?.isCurrent ?? true)
          .map((state) => state.position)
          .where(
            (position) =>
                position.hasContentDimensions &&
                (position.axisDirection == AxisDirection.down ||
                    position.axisDirection == AxisDirection.up),
          )
          .toList();
      final visited = <ScrollPosition>{};
      var reflows = 0;
      while (reflows++ < 100) {
        final pending = positions()
            .where((position) => !visited.contains(position))
            .toList();
        if (pending.isEmpty) break;
        for (final position in pending) {
          if (!positions().contains(position)) continue;
          visited.add(position);
          var steps = 0;
          if (position.maxScrollExtent <= 0) continue;
          position.jumpTo(0);
          await h.tester.pump();
          await h.tester.pump();
          await frame();
          while (positions().contains(position) &&
              position.pixels < position.maxScrollExtent &&
              steps++ < 100) {
            position.jumpTo(
              math.min(
                position.maxScrollExtent,
                position.pixels +
                    math.max(40, position.viewportDimension * .75),
              ),
            );
            await h.tester.pump();
            await h.tester.pump();
            await frame();
          }
          if (positions().contains(position) &&
              position.pixels < position.maxScrollExtent) {
            _failures.add({
              'group': h.group,
              'viewport': viewport.id,
              'coverage_error':
                  'Reflowed scroll extent exceeded the 100-step bound',
            });
          }
        }
      }
      if (positions().any((position) => !visited.contains(position))) {
        _failures.add({
          'group': h.group,
          'viewport': viewport.id,
          'coverage_error':
              'Reflowed scrolling did not stabilize within100 active-position passes',
        });
      }
    });
  }
}

void runZyraTextContrastCorpus(ZyraContrastDriver driver) {
  _driver = driver;
  baselineTextAuditOnly = true;
  baselineTextAudit = _measure;
  baselineNonTextObservation = (h, state, evidence, verifyNonText) async {
    for (final viewport in _viewports) {
      await h.withAuditViewport(viewport, () async {
        verifyNonText();
        expect(h.auditViewportMismatch(viewport), isNull);
        final boundary = h.tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
        );
        final result = await auditZyraRenderedText(h.tester, boundary);
        expect(result.failures, isEmpty);
        expect(result.runs, 0);
        expect(result.paintedPixels, 0);
        expect(result.exemptPixels, 0);
        _nonTextObservations.add({
          'group': h.group,
          'state': state,
          'viewport': viewport.id,
          'plan': h.latest.guardian
              ? h.latest.guardianMembership
              : h.latest.seekerMembership,
          'pages': h.latest.pages,
          'proof_kind': 'typed_nontext_guard_rejection',
          'raster_or_route_credit': false,
          'runs': result.runs,
          'pixels': result.paintedPixels,
          ...evidence,
        });
      });
    }
  };
  remaining.line126RemainingAuditAllDimensions = false;
  setUpAll(_clock.start);
  test(
    'the four CI drivers cover four locked tuples in adjacent shard order',
    () {
      const drivers = [
        zyraContrastNormal430,
        zyraContrastLarge375,
        zyraContrastLarge430,
        zyraContrastNormal,
      ];
      expect(drivers.map((driver) => driver.id).toSet(), hasLength(4));
      for (final driver in drivers) {
        expect(driver.viewports, hasLength(1));
      }
      final tuples = [
        for (final driver in drivers)
          for (final viewport in driver.viewports) viewport.id,
      ];
      expect(tuples, hasLength(4));
      expect(tuples.toSet(), {
        '430x932@1.0',
        '375x667@1.0',
        '430x932@1.3',
        '375x667@1.3',
      });
      // Full-suite modulo-three sharding sees A,D,C,B consecutively. The two
      // normal-text drivers (A+B) therefore share one shard; each large driver
      // occupies a different shard, without changing workflow/sharder budgets.
      const files = [
        (
          'test/zyra_clearer_text_contrast_430_test.dart',
          'zyraContrastNormal430',
        ),
        (
          'test/zyra_clearer_text_contrast_large_375_test.dart',
          'zyraContrastLarge375',
        ),
        (
          'test/zyra_clearer_text_contrast_large_430_test.dart',
          'zyraContrastLarge430',
        ),
        ('test/zyra_clearer_text_contrast_test.dart', 'zyraContrastNormal'),
      ];
      final allTests =
          Directory('test')
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .map((file) => file.path)
              .where((path) => path.endsWith('_test.dart'))
              .toList()
            ..sort();
      final indices = [for (final (file, _) in files) allTests.indexOf(file)];
      expect(indices.every((index) => index >= 0), isTrue);
      expect(
        allTests.sublist(indices.first, indices.last + 1),
        files.map((entry) => entry.$1).toList(),
      );
      expect(indices.first % 3, indices.last % 3);
      expect(indices.take(3).map((index) => index % 3).toSet(), hasLength(3));
      for (final (file, driver) in files) {
        expect(
          File(file).readAsStringSync(),
          contains('runZyraTextContrastCorpus($driver)'),
        );
      }
    },
  );
  tearDownAll(() {
    _write(_reportPath);
    baselineTextAudit = null;
    baselineNonTextObservation = null;
    baselineTextAuditOnly = false;
    if (!_reportOnly) {
      expect(
        _coverageGaps(),
        isEmpty,
        reason:
            'Every current route and fixture group must contribute real raster proof; see $_reportPath',
      );
      expect(
        _failures,
        isEmpty,
        reason: 'Actual rendered text failed LOCK14 V9; see $_reportPath',
      );
    }
  });
  for (final (name, register) in <(String, void Function())>[
    ('Seeker', seeker.main),
    ('Basic plans', basic.main),
    ('Guardian One', guardian.main),
    ('Signup', signup.main),
    ('Walkthrough', tour.main),
    ('Membership', membership.main),
    ('Menus', menus.main),
    ('Ended', ended.main),
    ('Compatibility', compatibility.main),
    ('Chat', chat.main),
    ('Settings', settings.main),
    ('Safety', safety.main),
    ('Filters', filters.main),
    ('Circle', circle.main),
    ('Family', family.main),
    ('Seekers', seekers.main),
    ('Phone', phone.main),
    ('Focus', focus.main),
    ('Recovery', recovery.main),
    ('Remaining routes', remaining.main),
    ('Coverage entries', entries.main),
  ]) {
    group(name, register);
  }
}
