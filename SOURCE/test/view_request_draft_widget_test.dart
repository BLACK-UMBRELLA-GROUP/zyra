import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_journey_peer_guardians_presentation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/screens/wali/link_guardian_panel.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_guardian_dashboard_profile_card.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_one_profile_avatar.dart';
import 'package:zyra/widgets/zyra_profile_membership_row.dart';
import 'package:zyra/widgets/zyra_profile_name_block.dart';
import 'package:zyra/widgets/zyra_segmented_toggle.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_browse_next_photo_motion.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

// Retired control identities remain absence-only regression evidence.
const _historicalBrowseControlNames = [
  'portraitCard',
  'photoStrip',
  'compactList',
  'twoColumnGallery',
  'profileFolio',
  'galleryStack',
  'galleryDuo',
  'galleryMosaic',
  'galleryRail',
  'galleryFrame',
  'gallerySplit',
  'galleryContactSheet',
  'galleryRibbon',
  'galleryAlbum',
  'galleryFocus',
  'peoplePortraitGrid',
  'peopleMosaic',
  'peopleStaggered',
  'peopleEditorialRows',
  'peopleContactSheet',
  'peopleSideBySide',
  'peopleFramedPortraits',
  'peopleFilmstrip',
  'peoplePairedAlbums',
  'peopleSpotlight',
];

const _capture = bool.fromEnvironment('ZYRA_VIEW_REQUEST_CAPTURE');
const _cardLockinCapture = bool.fromEnvironment('ZYRA_CARD_LOCKIN_CAPTURE');
const _simplifiedCapture = bool.fromEnvironment(
  'ZYRA_MY_ZYRA_SIMPLIFIED_CAPTURE',
);
const _requestsCapture = bool.fromEnvironment('ZYRA_REQUESTS_CAPTURE');
const _requestsCaptureDirectory = String.fromEnvironment(
  'ZYRA_REQUESTS_CAPTURE_DIRECTORY',
);
const _useRealFonts =
    _capture || _cardLockinCapture || _simplifiedCapture || _requestsCapture;
const _boundary = ValueKey('view-request-draft-candidate');
const _candidateDirectory =
    'visual/candidates/non_swipe_theme_review_2026_10_09';
const _cardLockinCandidateDirectory =
    'visual/candidates/journey_card_locked_2026_10_09';
const _simplifiedCandidateDirectory =
    'visual/candidates/my_zyra_simplified_2026_10_09';
const _fixture = 'draft-sara';
const _guardianView = 'guardian-journey-access-toggle-draft-attempt-$_fixture';
const _guardianChat = 'guardian-journey-chat-toggle-draft-attempt-$_fixture';
const _guardianHistory = 'guardian-history-consent-toggle';
const _requestLabels = ['Received', 'Sent', 'Past'];

Finder _key(String value) => find.byKey(ValueKey(value));

SeekerProfile _currentBrowseDetailsProfile(WidgetTester tester) {
  final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
    find.byType(ZyraOneJourneyBrowseDesigns),
  );
  final profile = browse.profiles[browse.selectedIndex];
  final details = _key('concept_browse_details_${profile.id}');
  expect(details, findsOneWidget);
  final expectedValues = [
    profile.firstName,
    if (profile.surnameLine?.trim().isNotEmpty ?? false)
      profile.surnameLine!.trim(),
    if (profile.age > 0) ...['Age', '${profile.age}'],
    if (profile.city.trim().isNotEmpty && profile.city.trim() != '—') ...[
      'Location',
      profile.city.trim(),
    ],
    if (profile.publicNationality?.trim().isNotEmpty ?? false) ...[
      'Nationality',
      profile.publicNationality!.trim(),
    ],
    if (profile.publicEthnicity?.trim().isNotEmpty ?? false) ...[
      'Ethnicity',
      profile.publicEthnicity!.trim(),
    ],
  ];
  for (final value in expectedValues.toSet()) {
    expect(
      find.descendant(of: details, matching: find.text(value)),
      findsNWidgets(expectedValues.where((item) => item == value).length),
    );
  }
  // LOCK 4 retains the compact details card and shows this person's first
  // photo inside its existing ring; it must never become a full-photo page.
  final avatar = _key('concept_browse_details_avatar_${profile.id}');
  expect(avatar, findsOneWidget);
  expect(tester.getSize(avatar), const Size(56, 56));
  final detailsImages = find.descendant(
    of: details,
    matching: find.byType(Image),
  );
  if (profile.photos.isEmpty) {
    expect(detailsImages, findsNothing);
    expect(
      find.descendant(of: avatar, matching: find.byIcon(Icons.person_outline)),
      findsOneWidget,
    );
  } else {
    final photo = _key('concept_browse_details_avatar_photo_${profile.id}');
    expect(detailsImages, findsOneWidget);
    expect(photo, findsOneWidget);
    expect(tester.getSize(photo), const Size(50, 50));
    final image = tester.widget<Image>(detailsImages);
    expect(image.image, isA<MemoryImage>());
    expect(
      (image.image as MemoryImage).bytes,
      base64Decode(profile.photos.first.split(',').last),
    );
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.center);
  }
  expect(
    tester
        .widget<PageView>(_key('concept_browse_photo_swipe_${profile.id}'))
        .controller!
        .page,
    closeTo(0, .01),
  );
  return profile;
}

void _expectBrowsePhoto(WidgetTester tester, SeekerProfile profile, int index) {
  final photo = _key('concept_browse_photo_${profile.id}_$index');
  expect(photo, findsOneWidget);
  final image = tester.widget<Image>(
    find.descendant(of: photo, matching: find.byType(Image)),
  );
  expect(image.image, isA<MemoryImage>());
  expect(
    (image.image as MemoryImage).bytes,
    base64Decode(profile.photos[index].split(',').last),
  );
}

Finder _compatibilityResult(String id) =>
    find.byKey(ValueKey(('draft_journey_compatibility', id)));
Semantics _permissionCircle(WidgetTester tester, String key) =>
    tester.widget<Semantics>(_key(key));

Iterable<ZyraOneJourneyBrowseDesign> get _visibleBrowseDesigns => const [
  ZyraOneJourneyBrowseDesign.portraitCard,
];

Widget _app({
  bool launcher = false,
  bool enabled = true,
  double scale = 1,
  bool reduce = true,
  VoidCallback? onBeforeOpen,
  int? generation,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
      disableAnimations: reduce,
    ),
    child: RepaintBoundary(key: _boundary, child: child!),
  ),
  home: launcher
      ? Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: DevDiscoveryDirectionPicker(
                enabled: enabled,
                onBeforeOpen: onBeforeOpen,
              ),
            ),
          ),
        )
      : ViewRequestDraftScreen(
          ownerGeneration: generation ?? ZyraAccountState.generation,
          ownerId: ZyraAccountState.userId,
        ),
);

Future<void> _mount(
  WidgetTester tester, {
  bool launcher = false,
  bool enabled = true,
  double scale = 1,
  bool reduce = true,
  VoidCallback? onBeforeOpen,
  int? generation,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      launcher: launcher,
      enabled: enabled,
      scale: scale,
      reduce: reduce,
      onBeforeOpen: onBeforeOpen,
      generation: generation,
    ),
  );
  await tester.pumpAndSettle();
  // Real image codecs finish outside the fake test clock. Wait for the shell's
  // guarded first-frame publication, not an arbitrary number of fake pumps.
  if (!launcher && enabled && generation == null) {
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final browse = find.byType(ZyraOneJourneyBrowseDesigns);
        if (browse.evaluate().isEmpty) return;
        final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(browse);
        if (deck.profiles.isNotEmpty && deck.profiles.first.photos.isNotEmpty) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
      }
      fail('The offline Browse deck did not publish prepared photo frames.');
    });
    await tester.pumpAndSettle();
  }
  final failure = tester.takeException();
  if (failure is FlutterError) {
    debugPrint(
      failure.diagnostics.map((node) => node.toStringDeep()).join('\n'),
    );
  }
  expect(failure, isNull);
}

Future<void> _press(WidgetTester tester, String id) async {
  if (id == 'draft_rules') {
    if (_key('dev_controls_page').evaluate().isEmpty) {
      await openZyraDevControls(tester);
    }
    expect(find.text('Page options'), findsOneWidget);
    expect(_key('dev_controls_close'), findsOneWidget);
    expect(_key('draft_back'), findsNothing);
    expect(_key('draft_rules'), findsNothing);
    return;
  }
  if (id == 'draft_back' &&
      find.text('Page options').evaluate().isEmpty &&
      [
        'draft_compatibility_card',
        'concept_activity_requests',
        'concept_activity_ended',
      ].any((key) => _key(key).evaluate().isNotEmpty)) {
    // These leaves now own real Actions controls. Existing return tests must
    // use the shared Back instead of mistaking Actions for Back.
    await _returnPage(tester);
    return;
  }
  if (await pressZyraDevControlKey(tester, id)) return;
  final contextualTab = id.startsWith('concept_journey_preview_')
      ? 1
      : id == 'draft_history'
      ? 2
      : id.startsWith('concept_guardian_plan_')
      ? 3
      : id.startsWith('draft_membership_seeker_')
      ? 4
      : null;
  if (contextualTab != null && _key(id).evaluate().isEmpty) {
    await _nav(tester, contextualTab);
    await _press(tester, 'draft_rules');
  }
  final target = _key(id);
  // Browse keeps the original action-navigation affordance. Filters are the
  // fourth action, not a separate top-right shortcut in the new shell.
  if (id == 'concept_filters' &&
      target.evaluate().isEmpty &&
      _key('concept_browse_menu').evaluate().isNotEmpty) {
    await _press(tester, 'concept_browse_menu');
    await _nav(tester, 3);
    return;
  }
  // Existing safety/Block tests use the actual Report destination exposed by
  // Browse's restored action bar, rather than the replaced full-view icon.
  if (id == 'draft_safety' &&
      target.evaluate().isEmpty &&
      _key('concept_browse_menu').evaluate().isNotEmpty) {
    await _press(tester, 'concept_browse_menu');
    await _nav(tester, 4);
    return;
  }
  if (id == _guardianHistory && target.evaluate().isEmpty) {
    await _press(tester, 'guardian-history-consent-details-toggle');
  }
  // Current production Connections cards deliberately reveal actions inline.
  // Use their genuine headers rather than injecting an expanded state.
  if (target.evaluate().isEmpty) {
    for (final prefix in [
      'draft_accept_',
      'draft_decline_',
      'draft_recipient_',
      'draft_cancel_',
    ]) {
      if (id.startsWith(prefix)) {
        final header = 'concept_request_${id.substring(prefix.length)}_header';
        if (_key(header).evaluate().isNotEmpty) await _press(tester, header);
      }
    }
    if (id.startsWith('concept_saved_') || id.startsWith('draft_journey_')) {
      final header = '${id}_header';
      if (_key(header).evaluate().isNotEmpty) await _press(tester, header);
    }
  }
  if (target.evaluate().isEmpty && id.startsWith('draft_journey_')) {
    final owner = find.byKey(
      const PageStorageKey('concept_connections_page_0'),
    );
    if (owner.evaluate().isNotEmpty) {
      final scrollable = find
          .descendant(of: owner, matching: find.byType(Scrollable))
          .first;
      // Search lazy cards from their real reading origin through gestures.
      // This changes no Journey, permission or card state.
      for (var attempt = 0; attempt < 20; attempt++) {
        final state = tester.state<ScrollableState>(scrollable);
        if (state.position.pixels <= state.position.minScrollExtent) break;
        await tester.drag(owner, const Offset(0, 250));
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(target, 200, scrollable: scrollable);
      await tester.pumpAndSettle();
    }
  }
  // The current Journey frame starts with its real arrival page. Advancing to
  // actions is an actual down-cue tap, never a PageController state injection.
  if (_key('concept_current_journey_pages').evaluate().isNotEmpty &&
      id != 'concept_journey_arrival_continue' &&
      (id.startsWith('draft_stage_') ||
          id.startsWith('draft_salam_') ||
          id.startsWith('draft_peer_salam_') ||
          id.startsWith('draft_reveal_') ||
          id.startsWith('draft_peer_reveal_') ||
          id.startsWith('draft_pause_') ||
          id.startsWith('draft_agree_pause_') ||
          id.startsWith('draft_end_') ||
          id == 'concept_stage_guardians' ||
          id == 'concept_send_message') &&
      tester
              .widget<PageView>(_key('concept_current_journey_pages'))
              .controller!
              .page! <=
          tester
                  .widget<ZyraConceptJourneyPresentation>(
                    find.byType(ZyraConceptJourneyPresentation),
                  )
                  .stage
                  .order -
              1) {
    // A compact arrival can now read naturally in its own scrollable. Use
    // the actual existing Continue cue, as above, rather than assuming one
    // physical drag skips all of that text and advances the parent pager.
    final continueCue = _key('concept_journey_arrival_continue');
    expect(continueCue, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(continueCue), alignment: 1);
    await tester.pumpAndSettle();
    expect(continueCue.hitTestable(), findsOneWidget);
    await tester.tap(continueCue);
    await tester.pumpAndSettle();
  }
  if (target.evaluate().isEmpty) {
    final scrollKey = id.startsWith('my-zyra-route-')
        ? 'my-zyra-quiet-scroll-0'
        : id.startsWith('concept_settings_')
        ? 'concept-current-settings-scroll'
        : 'concept-current-profile-scroll';
    final owner = _key(scrollKey);
    if (owner.evaluate().isNotEmpty) {
      final scrollable = find
          .descendant(of: owner, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(target, 250, scrollable: scrollable);
      await tester.pumpAndSettle();
    }
  }
  expect(
    target,
    findsOneWidget,
    reason:
        'Target $id; stage=${find.byType(ZyraConceptJourneyPresentation).evaluate().isEmpty ? "none" : tester.widget<ZyraConceptJourneyPresentation>(find.byType(ZyraConceptJourneyPresentation)).stage.value}; page=${_key("concept_current_journey_pages").evaluate().isEmpty ? "none" : tester.widget<PageView>(_key("concept_current_journey_pages")).controller?.page}',
  );
  if (id == 'concept_journey_arrival_continue') {
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return;
  }
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
  // Bounded Browse cards scroll beneath the current floating navigation.
  // Reveal an oversized action in the reading area before selecting a hit point.
  if (find
          .ancestor(of: target, matching: _key('concept_browse_design_scroll'))
          .evaluate()
          .isNotEmpty &&
      tester.getRect(target).bottom >
          tester.view.physicalSize.height / tester.view.devicePixelRatio -
              34 -
              ZyraNavBarMetrics.restingHeight -
              ZyraNavBarMetrics.bottomInset) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  // At large text a legitimate button can be taller than the scroll viewport.
  // Tap its visible intersection, and prove that exact target receives events.
  // Never silence missed-tap warnings or count a no-op as destination coverage.
  var visible = tester
      .getRect(target)
      .intersect(
        Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio),
      );
  if (find
      .ancestor(of: target, matching: _key('draft_scroll'))
      .evaluate()
      .isNotEmpty) {
    visible = visible.intersect(tester.getRect(_key('draft_scroll')));
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  final alignment = Alignment(
    2 * local.dx / box.size.width - 1,
    2 * local.dy / box.size.height - 1,
  );
  expect(
    target.hitTestable(at: alignment),
    findsOneWidget,
    reason:
        '$id box=${tester.getRect(target)} visible=$visible local=$local alignment=$alignment callback=${id.startsWith("draft_begin_") ? _action(tester, id) : "unchecked"} scroll=${_key("draft_scroll").evaluate().isNotEmpty ? tester.getRect(_key("draft_scroll")) : "none"} hits=${tester.hitTestOnBinding(visible.center).path.map((hit) => hit.target.runtimeType).toList()}',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  final failure = tester.takeException();
  if (failure is FlutterError) {
    debugPrint(
      failure.diagnostics.map((node) => node.toStringDeep()).join('\n'),
    );
  }
  expect(failure, isNull);
}

VoidCallback _callback(WidgetTester tester, String id) {
  final callback = _action(tester, id);
  expect(callback, isNotNull, reason: '$id must expose its real action.');
  return callback!;
}

Future<void> _nav(WidgetTester tester, int index) async {
  // Full-page production destinations correctly hide the bottom navigation.
  // Close page controls, then use actual Back for their owned leaves.
  for (
    var depth = 0;
    find.byType(ZyraShellNavigation).evaluate().isEmpty && depth < 6;
    depth++
  ) {
    if (find.text('Page options').evaluate().isNotEmpty ||
        _key('concept_pull_down_back_scope').evaluate().isEmpty) {
      await returnZyraPreviewPage(tester);
    } else {
      await _returnPage(tester);
    }
  }
  final nav = tester.widget<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  if (nav.items.first.label == 'Network') index = const [2, 0, 3, 4][index];
  nav.onTap(index);
  await tester.pumpAndSettle();
  final failure = tester.takeException();
  if (failure is FlutterError) {
    debugPrint(
      failure.diagnostics.map((node) => node.toStringDeep()).join('\n'),
    );
  }
  if (failure is FlutterError) {
    for (final element
        in find
            .byWidgetPredicate((widget) => widget is Row || widget is Column)
            .evaluate()) {
      final row = element.renderObject;
      if (row is! RenderFlex || !row.hasSize) continue;
      var width = 0.0;
      row.visitChildren((child) {
        if (child is RenderBox && child.hasSize) {
          width += row.direction == Axis.horizontal
              ? child.size.width
              : child.size.height;
        }
      });
      if (width >
          (row.direction == Axis.horizontal
                  ? row.size.width
                  : row.size.height) +
              .1) {
        final ancestors = <String>[];
        element.visitAncestorElements((ancestor) {
          ancestors.add(ancestor.widget.runtimeType.toString());
          return ancestors.length < 14;
        });
        final copy = find
            .descendant(
              of: find.byWidget(element.widget),
              matching: find.byType(Text),
            )
            .evaluate()
            .map(
              (child) =>
                  (child.widget as Text).data ??
                  (child.widget as Text).textSpan?.toPlainText(),
            )
            .toList();
        debugPrint(
          'Measured overflowing ${row.direction}: ${row.debugCreator}; size=${row.size}; child extent=$width; ancestors=$ancestors; copy=$copy',
        );
      }
    }
  }
  expect(failure, isNull, reason: 'Root navigation destination $index');
}

Future<void> _tapRootNav(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final navigation = tester.widget<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  final index = navigation.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  final item = navigation.items[index];
  final target = find.descendant(
    of: find.byType(ZyraShellNavigation),
    matching: item.useJourneyGlyph
        ? find.byType(ZyraJourneyIcon)
        : find.byIcon(item.icon),
  );
  expect(target, findsOneWidget);
  // Canonical current navigation deliberately puts IgnorePointer around each
  // icon cell: its one bar-wide detector owns the real touch gesture.
  final touchBar = find
      .ancestor(
        of: target,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(touchBar.hitTestable(), findsOneWidget);
  final point = tester.getCenter(target);
  expect(tester.getRect(touchBar).contains(point), isTrue);
  await tester.tapAt(point);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(
    tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .currentIndex,
    index,
  );
}

Future<void> _openGallerySara(WidgetTester tester) async {
  // Current Browse is the real public-card action surface; it no longer opens
  // a gallery-only full-photo route. Exercise that current surface for guards.
  await _nav(tester, 0);
  expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
  expect(_key('draft_profile_$_fixture'), findsOneWidget);
}

Future<void> _openBrowseSafety(WidgetTester tester, String id) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    if (browse.profiles[browse.selectedIndex].id == id) break;
    await _press(tester, 'concept_next_profile');
  }
  final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
    find.byType(ZyraOneJourneyBrowseDesigns),
  );
  expect(browse.profiles[browse.selectedIndex].id, id);
  await _press(tester, 'draft_safety');
}

Future<void> _openAdditionalGuardian(WidgetTester tester) async {
  await tester.drag(
    _key('guardian-page-view'),
    Offset(-tester.view.physicalSize.width * .8, 0),
  );
  await tester.pumpAndSettle();
  expect(_key('guardian-page-static-draft-guardian-yusuf'), findsOneWidget);
}

Future<void> _chooseBrowseFilter(
  WidgetTester tester,
  String field,
  String label,
) async {
  await _press(tester, 'concept_$field');
  final search = find.byType(TextField);
  expect(search, findsOneWidget);
  await tester.enterText(search, label);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

VoidCallback? _action(WidgetTester tester, String id) {
  final target = tester.widget<Widget>(_key(id));
  if (target is ButtonStyleButton) return target.onPressed;
  if (target is InkWell) return target.onTap;
  if (target is GestureDetector) return target.onTap;
  final ink = find.descendant(of: _key(id), matching: find.byType(InkWell));
  if (ink.evaluate().isNotEmpty) return tester.widget<InkWell>(ink.first).onTap;
  throw TestFailure(
    '$id has an unsupported action type: ${target.runtimeType}.',
  );
}

Future<void> _sendRequest(WidgetTester tester) async {
  await _press(tester, 'draft_profile_$_fixture');
  expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
  expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
  expect(_key('draft_confirm_request'), findsNothing);
  await _openRequests(tester, sent: true);
}

Future<void> _openRequests(WidgetTester tester, {bool sent = false}) async {
  await _nav(tester, 2);
  await _press(tester, 'my-zyra-route-concept-my-requests');
  await _press(tester, 'draft_requests_${sent ? 1 : 0}');
}

Finder _returnSemantics() => find
    .descendant(
      of: _key('concept_pull_down_back_scope'),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.onDismiss != null,
      ),
    )
    .first;

Future<void> _returnPage(WidgetTester tester, {Finder? from}) async {
  final scope = _key('concept_pull_down_back_scope');
  expect(scope, findsOneWidget);
  if (from != null) {
    expect(find.descendant(of: scope, matching: from), findsOneWidget);
  }
  await returnZyraPreviewPage(tester);
}

Future<void> _openEnded(WidgetTester tester) async {
  await _nav(tester, 2);
  await _press(tester, 'my-zyra-route-concept-my-ended');
}

Future<void> _selectBrowseDesign(
  WidgetTester tester,
  ZyraOneJourneyBrowseDesign design,
) async {
  expect(design, ZyraOneJourneyBrowseDesign.portraitCard);
  expect(
    tester
        .widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        )
        .design,
    design,
  );
}

Future<void> _confirmGuardianMain(
  WidgetTester tester, {
  required bool remove,
}) async {
  final base = remove ? 'guardian-clear-main' : 'guardian-make-main';
  await _press(tester, base);
  final confirm = find.descendant(
    of: _key('$base-confirmation'),
    matching: find.text('Confirm'),
  );
  expect(confirm, findsOneWidget);
  if (confirm.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(confirm);
  }
  expect(confirm.hitTestable(), findsOneWidget);
  await tester.tap(confirm);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  if (!remove) {
    expect(_key('concept_main_guardian_notice'), findsOneWidget);
    await _press(tester, 'concept_main_guardian_continue');
  }
  final people = tester
      .widget<SeekerGuardianPage>(find.byType(SeekerGuardianPage))
      .people;
  expect(
    people.where((person) => person.isMain).length,
    remove ? 0 : 1,
    reason:
        'The actual current confirmation must update the local Main Guardian before threshold checks. Pager=${tester.widget<PageView>(_key("guardian-page-view")).controller?.page}; text=${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).whereType<String>().toList()}',
  );
}

Future<void> _fillJourney(WidgetTester tester) async {
  await _nav(tester, 1);
  await _press(tester, 'draft_rules');
  expect(_key('draft_fill'), findsNothing);
  await _press(tester, 'concept_journey_preview_1');
  await _press(tester, 'draft_journey_$_fixture');
}

Future<void> _seedJourneyCards(WidgetTester tester, int count) async {
  await _nav(tester, 1);
  await _press(tester, 'draft_rules');
  await _press(tester, 'concept_journey_preview_$count');
  expect(
    find.byType(ZyraOneJourneyConnectionsActiveCard),
    findsNWidgets(count),
  );
}

Future<void> _cancelJourneyOptions(WidgetTester tester) async {
  final options = tester.widget<ZyraConceptJourneyOptions>(
    find.byType(ZyraConceptJourneyOptions),
  );
  if (options.inline) {
    expect(find.byType(BottomSheet), findsNothing);
    await _press(tester, 'draft_journey_options_${options.id}');
    expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
    expect(tester.takeException(), isNull);
    return;
  }
  final cancel = find.widgetWithText(TextButton, 'Cancel');
  expect(cancel, findsOneWidget);
  await tester.ensureVisible(cancel);
  await tester.pumpAndSettle();
  expect(cancel.hitTestable(), findsOneWidget);
  await tester.tap(cancel);
  await tester.pumpAndSettle();
  expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
  expect(tester.takeException(), isNull);
}

Future<void> _advanceStage(WidgetTester tester) async {
  await _press(tester, 'draft_stage_ready_$_fixture');
  await _press(tester, 'draft_stage_peer_ready_$_fixture');
  await _press(tester, 'draft_stage_next_$_fixture');
}

Future<void> _completeBioStep(WidgetTester tester) async {
  expect(_key('draft_journey_bio_step_$_fixture'), findsOneWidget);
  expect(_key('draft_journey_bio_about'), findsNothing);
  expect(_key('draft_bio_continue_$_fixture'), findsNothing);
  expect(find.textContaining('Guardian Gate'), findsNothing);
  await _press(tester, 'draft_bio_reveal_$_fixture');
  expect(_key('draft_journey_bio_about'), findsNothing);
  expect(_key('draft_bio_continue_$_fixture'), findsNothing);
  await _press(tester, 'draft_rules');
  expect(_action(tester, 'draft_peer_bio_ready_$_fixture'), isNull);
  await _press(tester, 'draft_peer_bio_reveal_$_fixture');
  await _press(tester, 'draft_back');
  expect(_key('draft_journey_bio_step_$_fixture'), findsOneWidget);
  expect(_key('draft_journey_bio_about'), findsOneWidget);
  expect(_key('draft_bio_reveal_$_fixture'), findsNothing);
  expect(find.textContaining('Guardian Gate'), findsNothing);
  await _press(tester, 'draft_bio_continue_$_fixture');
  expect(find.text('Waiting for Sara to continue.'), findsOneWidget);
  expect(_action(tester, 'draft_bio_continue_$_fixture'), isNull);
  await _press(tester, 'draft_rules');
  await _press(tester, 'draft_peer_bio_ready_$_fixture');
  await _press(tester, 'draft_back');
  expect(_key('draft_journey_bio_step_$_fixture'), findsOneWidget);
  await _press(tester, 'draft_bio_continue_$_fixture');
  expect(_key('draft_journey_bio_step_$_fixture'), findsNothing);
  expect(find.textContaining('Guardian Gate'), findsWidgets);
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('The synthetic concept must not create an HTTP client.');
  }
}

ZyraRequestActivityPresentation _selector(
  WidgetTester tester,
  List<String> labels,
) => tester
    .widgetList<ZyraRequestActivityPresentation>(
      find.byType(ZyraRequestActivityPresentation),
    )
    .singleWhere((widget) => listEquals(widget.labels, labels));

ValueChanged<int> _retainedRequestTabs(WidgetTester tester) {
  final callbacks = [
    for (var index = 0; index < _requestLabels.length; index++)
      tester.widget<InkWell>(_key('draft_requests_$index')).onTap!,
  ];
  return (index) => callbacks[index]();
}

void _expectRequestTabs(
  WidgetTester tester,
  ZyraRequestActivityPresentation selector,
) {
  expect(selector.labels, _requestLabels);
  for (var index = 0; index < _requestLabels.length; index++) {
    final tab = _key('draft_requests_$index');
    expect(tab, findsOneWidget);
    expect(tester.getSize(tab).height, greaterThanOrEqualTo(44));
    final semantics = tester
        .widgetList<Semantics>(
          find.ancestor(of: tab, matching: find.byType(Semantics)),
        )
        .firstWhere(
          (widget) => widget.properties.label == _requestLabels[index],
        );
    expect(semantics.properties.selected, selector.selectedIndex == index);
    expect(semantics.properties.inMutuallyExclusiveGroup, isTrue);
    expect(tester.widget<InkWell>(tab).onTap, isNotNull);
  }
}

void _expectSingleMyZyra(WidgetTester tester) {
  final dashboard = tester.widget<ZyraQuietDashboard>(
    find.byType(ZyraQuietDashboard),
  );
  expect(dashboard.singlePage, isTrue);
  expect(dashboard.permanentNavigation, isTrue);
  // The lazy list may keep Quick access below the reading viewport. Confirm
  // the permanent destination contract without moving its preserved scroll.
  for (final id in [
    'concept-my-requests',
    'concept-my-introductions',
    'concept-my-ended',
  ]) {
    expect(dashboard.fixtureCards.where((card) => card.id == id), hasLength(1));
  }
  expect(dashboard.onTabChanged, isNull);
  expect(find.text('My ZYRA'), findsOneWidget);
  expect(find.byType(ZyraSegmentedToggle), findsNothing);
  expect(find.byType(PageView), findsNothing);
  expect(_key('my-zyra-now-tab'), findsNothing);
  expect(_key('my-zyra-insights-tab'), findsNothing);
  expect(_key('my-zyra-insights-empty'), findsNothing);
  expect(_key('my-zyra-route-concept-saved'), findsNothing);
  expect(_key('my-zyra-route-concept-my-paused'), findsNothing);
  expect(find.text('Saved'), findsNothing);
  expect(find.text('Paused Journeys'), findsNothing);
}

Future<void> _captureCandidate(
  WidgetTester tester,
  String filename, {
  bool cardLockin = false,
  bool requests = false,
}) async {
  if (requests) {
    if (!_requestsCapture) return;
    expect(_requestsCaptureDirectory, startsWith('/'));
  } else {
    if (!_simplifiedCapture && !(cardLockin ? _cardLockinCapture : _capture)) {
      return;
    }
  }
  expect(autoUpdateGoldenFiles, isTrue);
  // Capture the stable destination after the informational local notice.
  await tester.pump(const Duration(seconds: 3));
  // Browse owns the full viewport; other pages can have their own nested
  // vertical scrollers. Reset only visible vertical positions under this
  // capture root, retaining the selected horizontal page and request segment.
  for (final state in tester.stateList<ScrollableState>(
    find.descendant(
      of: find.byKey(_boundary),
      matching: find.byType(Scrollable),
    ),
  )) {
    if (axisDirectionToAxis(state.widget.axisDirection) == Axis.vertical &&
        state.position.hasContentDimensions) {
      state.position.jumpTo(state.position.minScrollExtent);
    }
  }
  await tester.pumpAndSettle();
  await _settlePaintedImages(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        bytes!.buffer.asUint8List(),
        matchesGoldenFile(
          '${requests
              ? _requestsCaptureDirectory
              : _simplifiedCapture
              ? _simplifiedCandidateDirectory
              : cardLockin
              ? _cardLockinCandidateDirectory
              : _candidateDirectory}/$filename.png',
        ),
      );
    } finally {
      image.dispose();
    }
  });
}

Future<void> _settlePaintedImages(WidgetTester tester) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  // A valid byte decode is not evidence the actual UI painted its photos.
  // Let each genuine mounted provider deliver a frame outside FakeAsync.
  await tester.runAsync(() async {
    for (final widget in images) {
      expect(
        widget.image,
        isA<MemoryImage>(),
        reason: 'Concept photos must use the actual local image provider.',
      );
      final context = tester.element(find.byWidget(widget));
      final stream = widget.image.resolve(
        createLocalImageConfiguration(context),
      );
      final painted = Completer<void>();
      final listener = ImageStreamListener(
        (info, _) {
          info.dispose();
          if (!painted.isCompleted) painted.complete();
        },
        onError: (error, stack) {
          if (!painted.isCompleted) painted.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await painted.future.timeout(const Duration(seconds: 10));
      } finally {
        stream.removeListener(listener);
      }
    }
  });
  await tester.pumpAndSettle();
  for (final widget in images) {
    final raw = find.descendant(
      of: find.byWidget(widget),
      matching: find.byType(RawImage),
    );
    expect(
      raw,
      findsOneWidget,
      reason: 'An actual mounted photo must paint, not fall back.',
    );
    expect(tester.widget<RawImage>(raw).image, isNotNull);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFatalHitTests = WidgetController.hitTestWarningShouldBeFatal;

  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    if (!_useRealFonts) return;
    final reading = FontLoader('PoppinsViewRequestDraftAudit');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneViewRequestDraftAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
  });

  tearDownAll(() {
    WidgetController.hitTestWarningShouldBeFatal = previousFatalHitTests;
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _useRealFonts
        ? 'PoppinsViewRequestDraftAudit'
        : null;
    ZyraText.testWordmarkFontFamily = _useRealFonts
        ? 'SyneViewRequestDraftAudit'
        : null;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) {
        debugPrint(details.toString());
        debugPrint(
          details.informationCollector
                  ?.call()
                  .map((node) => node.toStringDeep())
                  .join('\n') ??
              'No render diagnostic collector supplied.',
        );
      }
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'Browse filters Apply, Back and Clear preserve public sample boundaries',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        ZyraOneJourneyBrowseDesigns browse() =>
            tester.widget<ZyraOneJourneyBrowseDesigns>(
              find.byType(ZyraOneJourneyBrowseDesigns),
            );
        final original = browse().profiles.map((p) => p.id).toList();
        final sara = browse().profiles.firstWhere((p) => p.id == _fixture);
        expect(sara.publicNationality, 'Pakistani');
        expect(sara.publicEthnicity, 'Pakistani');
        await _press(tester, 'concept_filters');
        expect(find.text(zyraBrowseSampleOriginLabel), findsOneWidget);
        expect(find.text('Sample people only'), findsNothing);
        expect(find.text('Sample location · Manchester'), findsNothing);
        expect(
          find.text('Your current location is not available here.'),
          findsOneWidget,
        );
        await _chooseBrowseFilter(tester, 'nationality', 'Pakistani (PK)');
        await returnZyraPreviewPage(tester);
        expect(browse().profiles.map((p) => p.id), original);
        await _press(tester, 'concept_filters');
        expect(find.text('Nationality · Any'), findsOneWidget);
        await _chooseBrowseFilter(tester, 'country', 'United Kingdom');
        await _chooseBrowseFilter(tester, 'nationality', 'Pakistani (PK)');
        await _chooseBrowseFilter(tester, 'ethnicity', 'Pakistani');
        await _press(tester, 'concept_radius_2');
        await _press(tester, 'concept_age_1');
        final slider = tester.widget<RangeSlider>(_key('concept_age_range'));
        slider.onChanged!(const RangeValues(27, 27));
        await tester.pumpAndSettle();
        await _press(tester, 'concept_apply_filter');
        expect(browse().profiles.map((p) => p.id), [_fixture]);
        await _press(tester, 'concept_filters');
        await _press(tester, 'concept_city_3');
        await _press(tester, 'concept_apply_filter');
        expect(find.byType(ZyraOneJourneyBrowseDesigns), findsNothing);
        expect(find.text('No profiles in this view.'), findsOneWidget);
        await _press(tester, 'concept_clear_filters');
        expect(browse().profiles.map((p) => p.id), original);
        await _press(tester, 'concept_filters');
        expect(find.text('Country of residence · Any'), findsOneWidget);
        expect(find.text('Nationality · Any'), findsOneWidget);
        expect(find.text('Ethnicity · Any'), findsOneWidget);
        expect(_key('concept_age_range'), findsNothing);
        await returnZyraPreviewPage(tester);
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'retained filter slider cannot write after an editing-session ABA',
    (tester) async {
      await _mount(tester);
      await _press(tester, 'concept_filters');
      await _press(tester, 'concept_age_1');
      final oldSlider = tester
          .widget<RangeSlider>(_key('concept_age_range'))
          .onChanged!;
      await returnZyraPreviewPage(tester);
      await _press(tester, 'concept_filters');
      await _press(tester, 'concept_age_1');
      oldSlider(const RangeValues(60, 70));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RangeSlider>(_key('concept_age_range')).values,
        const RangeValues(18, 70),
      );
      await _press(tester, 'concept_apply_filter');
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
    },
  );

  testWidgets(
    'hidden controls keep one animation dropdown and no Browse designs',
    (tester) async {
      await _mount(tester);
      expect(_key('draft_close'), findsNothing);
      expect(_key('draft_back'), findsNothing);
      expect(_key('dev_controls_hold_surface'), findsOneWidget);
      expect(_key('draft_rules'), findsNothing);
      await _press(tester, 'draft_rules');
      expect(_key('draft_rules'), findsNothing);
      expect(find.text('Page options'), findsOneWidget);
      expect(_key('draft_back'), findsNothing);
      expect(_key('dev_controls_close'), findsOneWidget);
      expect(
        find.byType(DropdownButtonFormField<ZyraBrowseNextMotion>),
        findsOneWidget,
      );
      for (final name in _historicalBrowseControlNames) {
        expect(_key('concept_browse_design_$name'), findsNothing);
      }
      await _press(tester, 'draft_back');
      expect(
        tester
            .widget<ZyraOneJourneyBrowseDesigns>(
              find.byType(ZyraOneJourneyBrowseDesigns),
            )
            .design,
        ZyraOneJourneyBrowseDesign.portraitCard,
      );
    },
  );

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0),
    (size: Size(320, 568), scale: 1.4),
    (size: Size(320, 568), scale: 2.0),
  ]) {
    testWidgets(
      'Journey title and three empty slots remain nav-safe ${viewport.scale}',
      (tester) async {
        await _mount(tester, size: viewport.size, scale: viewport.scale);
        await _nav(tester, 1);
        final title = tester.widget<Text>(_key('concept_connections_title'));
        expect(title.style?.fontSize, 26);
        expect(title.textAlign, TextAlign.left);
        final titleRect = tester.getRect(_key('concept_connections_title'));
        expect(titleRect.left, closeTo(20, .1));
        expect(titleRect.top, lessThan(85));
        final list = find.byKey(
          const PageStorageKey('concept_connections_page_0'),
        );
        final viewportRect = tester.getRect(list);
        expect(viewportRect.top, greaterThan(titleRect.bottom));
        final position = tester
            .state<ScrollableState>(
              find.descendant(of: list, matching: find.byType(Scrollable)),
            )
            .position;
        expect(position.pixels, position.minScrollExtent);
        expect(
          position.maxScrollExtent,
          viewport.scale == 1 ? closeTo(0, .01) : greaterThan(0),
        );
        final navigationTop = tester.getRect(find.byType(FloatingNavBar)).top;
        expect(find.text('Awaiting a Journey'), findsNWidgets(3));
        for (var index = 0; index < 3; index++) {
          final slot = _key('concept_journey_capacity_slot_$index');
          expect(slot, findsOneWidget);
          await tester.ensureVisible(slot);
          await tester.pumpAndSettle();
          final copy = find.descendant(of: slot, matching: find.byType(Text));
          final copyWidget = tester.widget<Text>(copy);
          expect(copyWidget.style?.fontSize, 14);
          expect(copyWidget.overflow, isNot(TextOverflow.ellipsis));
          expect(
            tester.renderObject<RenderParagraph>(copy).didExceedMaxLines,
            isFalse,
          );
          expect(
            find.descendant(of: slot, matching: find.byType(FittedBox)),
            findsNothing,
          );
          final bounds = tester.getRect(copy);
          expect(bounds.left, greaterThanOrEqualTo(viewportRect.left - .01));
          expect(bounds.right, lessThanOrEqualTo(viewportRect.right + .01));
          expect(bounds.top, greaterThanOrEqualTo(viewportRect.top - .01));
          expect(bounds.bottom, lessThanOrEqualTo(navigationTop + .01));
          expect(copy.hitTestable(), findsOneWidget);
        }
        expect(find.text('No Journey yet.'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final guardian in ['draft-guardian-hassan', 'draft-guardian-yusuf']) {
    testWidgets(
      'Basic $guardian has view but no chat including forged local writes',
      (tester) async {
        await _mount(tester);
        await _fillJourney(tester);
        await _nav(tester, 3);
        if (guardian.endsWith('yusuf')) await _openAdditionalGuardian(tester);
        final stale = tester
            .widget<SeekerGuardianPage>(find.byType(SeekerGuardianPage))
            .journeyAccessLoader!;
        await _press(tester, 'draft_rules');
        await _press(tester, 'concept_guardian_plan_${guardian}_0');
        await _press(tester, 'draft_back');
        if (guardian.endsWith('yusuf') &&
            _key(
              'guardian-page-static-draft-guardian-yusuf',
            ).evaluate().isEmpty) {
          await _openAdditionalGuardian(tester);
        }
        final page = tester.widget<SeekerGuardianPage>(
          find.byType(SeekerGuardianPage),
        );
        final read = await page.journeyAccessLoader!(guardianId: guardian);
        expect(read.isAvailable, isTrue);
        final state = read.valueOrNull!.first;
        expect(state.included, isTrue);
        expect(state.chatAvailable, isFalse);
        expect(state.chatEnabled, isFalse);
        final denied = await page.journeyAccessLoader!(
          guardianId: guardian,
          attemptId: 'draft-attempt-$_fixture',
          chatEnabled: true,
        );
        expect(denied.isUnavailable, isTrue);
        final oldDenied = await stale(
          guardianId: guardian,
          attemptId: 'draft-attempt-$_fixture',
          chatEnabled: true,
        );
        expect(oldDenied.isUnavailable, isTrue);
        expect(_key(_guardianChat), findsNothing);
        expect(
          find.descendant(
            of: find.byType(SeekerGuardianPage),
            matching: find.text('Chat'),
          ),
          findsNothing,
        );
        await _press(tester, 'draft_rules');
        await _press(tester, 'concept_guardian_plan_${guardian}_1');
        await _press(tester, 'draft_back');
        final updated = tester.widget<SeekerGuardianPage>(
          find.byType(SeekerGuardianPage),
        );
        final one = await updated.journeyAccessLoader!(guardianId: guardian);
        expect(one.valueOrNull!.first.chatAvailable, isTrue);
        expect(one.valueOrNull!.first.chatEnabled, guardian.endsWith('hassan'));
        if (guardian.endsWith('yusuf')) {
          final allowed = await updated.journeyAccessLoader!(
            guardianId: guardian,
            attemptId: 'draft-attempt-$_fixture',
            chatEnabled: true,
          );
          expect(allowed.isAvailable, isTrue);
          expect(allowed.valueOrNull!.first.chatEnabled, isTrue);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final action in ['hide', 'block']) {
    testWidgets(
      'fictional $action excludes Browse but retains ended archive without stale writes',
      (tester) async {
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester);
          await _fillJourney(tester);
          await _press(tester, 'draft_end_$_fixture');
          await _press(tester, 'draft_confirm_end_$_fixture');
          await _nav(tester, 0);
          final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
          expect(browse.profiles.map((p) => p.id), contains(_fixture));
          expect(
            browse.canRequest!(
              browse.profiles.firstWhere((p) => p.id == _fixture),
            ),
            isFalse,
          );
          await _press(tester, 'concept_browse_open_$_fixture');
          await _press(tester, 'draft_safety');
          final staleOther = _callback(
            tester,
            'draft_safety_${action == 'hide' ? 'block' : 'hide'}',
          );
          await _press(tester, 'draft_safety_$action');
          staleOther();
          await tester.pumpAndSettle();
          final after = tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
          expect(after.profiles.map((p) => p.id), isNot(contains(_fixture)));
          await _openEnded(tester);
          if (action == 'hide') {
            expect(_key('draft_journey_${_fixture}_header'), findsOneWidget);
          } else {
            expect(_key('concept_blocked_archive_$_fixture'), findsOneWidget);
            expect(find.text('Sara'), findsNothing);
          }
          if (action == 'hide') {
            await _press(tester, 'draft_journey_options_$_fixture');
            expect(_key('draft_options_archive_$_fixture'), findsNothing);
            expect(find.text('View archive'), findsNothing);
            await _press(tester, 'draft_options_timeline_$_fixture');
          } else {
            await _press(tester, 'draft_journey_$_fixture');
          }
          expect(_key('concept_journey_menu'), findsNothing);
          expect(_key('concept_message'), findsNothing);
          expect(_key('concept_send_message'), findsNothing);
          expect(_key('draft_request'), findsNothing);
          if (action == 'hide') {
            final history = tester.widget<ZyraDraftTimelinePresentation>(
              find.byType(ZyraDraftTimelinePresentation),
            );
            expect(history.subjectId, _fixture);
            expect(history.view.frozen, isTrue);
            expect(history.onPropose, isNull);
            expect(history.onConfirm, isNull);
            expect(history.onNotYet, isNull);
            expect(
              history.view.entries.map((entry) => entry.type),
              containsAll([
                'match_created',
                'journey_started',
                'journey_ended',
              ]),
            );
            expect(find.text('User not found'), findsNothing);
          } else {
            expect(_key('concept_user_not_found'), findsOneWidget);
            expect(find.text('User not found'), findsOneWidget);
            expect(find.text('Journey with Sara'), findsNothing);
            expect(find.byType(ZyraProfileImage), findsNothing);
            expect(_key('concept_user_not_found_back'), findsNothing);
            await _returnPage(tester, from: _key('concept_user_not_found'));
            expect(_key('concept_activity_ended'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );
  }

  for (final sent in [false, true]) {
    testWidgets(
      'blocked ${sent ? 'sent' : 'received'} request keeps its record but hides identity',
      (tester) async {
        await _mount(tester);
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .items[2]
              .dot,
          isTrue,
        );
        if (sent) await _sendRequest(tester);
        await _nav(tester, 2);
        final before = tester.widget<ZyraQuietDashboard>(
          find.byType(ZyraQuietDashboard),
        );
        expect(
          before.fixtureCards
              .firstWhere((card) => card.id == 'concept-my-requests')
              .detail,
          sent ? '1 received · 1 sent' : '1 received · 0 sent',
        );
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .items[2]
              .dot,
          // LOCK 5 clears tab attention on this My ZYRA visit, while Amira's
          // unopened request retains its own New activity treatment.
          isFalse,
        );
        expect(
          before.fixtureCards
              .singleWhere((card) => card.id == 'concept-my-requests')
              .hasNewActivity,
          isTrue,
        );
        await _nav(tester, 0);
        final body = tester.widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
        final id = sent ? _fixture : 'draft-amira';
        final person = body.profiles.firstWhere((p) => p.id == id);
        await _openBrowseSafety(tester, id);
        await _press(tester, 'draft_safety_block');
        await _nav(tester, 2);
        expect(find.textContaining(person.firstName), findsNothing);
        final after = tester.widget<ZyraQuietDashboard>(
          find.byType(ZyraQuietDashboard),
        );
        expect(
          after.fixtureCards
              .firstWhere((card) => card.id == 'concept-my-requests')
              .detail,
          sent ? '1 received · 0 sent' : '0 received · 0 sent',
        );
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .items[2]
              .dot,
          isFalse,
        );
        expect(
          after.fixtureCards
              .singleWhere((card) => card.id == 'concept-my-requests')
              .hasNewActivity,
          sent,
        );
        // A current dispatcher cannot address the hidden blocked invitation,
        // even though its underlying fictional record has not been deleted.
        after.onNavigate!(
          SupportiveCard(
            id: 'concept-request-$id',
            section: SupportiveSection.stand,
            title: 'Blocked request probe',
            target: ZyraDashboardTarget.connectionsActivity,
          ),
        );
        await tester.pumpAndSettle();
        expect(_key('concept_activity_requests'), findsNothing);
        expect(find.byType(ZyraQuietDashboard), findsOneWidget);
        after.onNavigate!(
          const SupportiveCard(
            id: 'blocked-request-notifications-probe',
            section: SupportiveSection.stand,
            title: 'Updates',
            target: ZyraDashboardTarget.notifications,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            sent
                ? 'A Journey invitation is waiting in My ZYRA.'
                : 'No Journey requests need your attention right now.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining(person.firstName), findsNothing);
        await _openRequests(tester, sent: sent);
        expect(_key('concept_request_${id}_header'), findsNothing);
        expect(find.textContaining(person.firstName), findsNothing);
        expect(find.byType(ZyraProfileImage), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Hide preserves request counts and item attention while My ZYRA clears its tab badge',
    (tester) async {
      await _mount(tester);
      final body = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      expect(body.onProfile, isNull);
      await _openBrowseSafety(tester, 'draft-amira');
      await _press(tester, 'draft_safety_hide');
      expect(
        tester
            .widget<ZyraOneJourneyBrowseDesigns>(
              find.byType(ZyraOneJourneyBrowseDesigns),
            )
            .profiles
            .map((person) => person.id),
        isNot(contains('draft-amira')),
      );
      expect(
        tester
            .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
            .items[2]
            .dot,
        isTrue,
      );
      await _nav(tester, 2);
      final dashboard = tester.widget<ZyraQuietDashboard>(
        find.byType(ZyraQuietDashboard),
      );
      expect(
        dashboard.fixtureCards
            .firstWhere((card) => card.id == 'concept-my-requests')
            .detail,
        '1 received · 0 sent',
      );
      expect(
        tester
            .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
            .items[2]
            .dot,
        isFalse,
      );
      expect(
        dashboard.fixtureCards
            .singleWhere((card) => card.id == 'concept-my-requests')
            .hasNewActivity,
        isTrue,
      );
      dashboard.onNavigate!(
        const SupportiveCard(
          id: 'hidden-request-notifications-probe',
          section: SupportiveSection.stand,
          title: 'Updates',
          target: ZyraDashboardTarget.notifications,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('A Journey invitation is waiting in My ZYRA.'),
        findsOneWidget,
      );
      await _openRequests(tester);
      expect(_key('concept_request_draft-amira_header'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'blocked active Journey retains capacity but has redacted safe End action',
    (tester) async {
      await _mount(tester);
      await _press(tester, 'draft_rules');
      await _press(tester, 'draft_membership_seeker_basic');
      await _press(tester, 'draft_back');
      await _fillJourney(tester);
      await _press(tester, 'concept_journey_menu');
      tester
          .widget<ZyraConceptJourneyOptions>(
            find.byType(ZyraConceptJourneyOptions),
          )
          .onSelected(ZyraConceptJourneyOption.profile);
      await tester.pumpAndSettle();
      await _press(tester, 'draft_safety');
      await _press(tester, 'draft_safety_block');
      expect(find.text('Your Journey has your focus.'), findsOneWidget);
      await _nav(tester, 1);
      expect(_key('concept_blocked_journey_$_fixture'), findsOneWidget);
      expect(find.textContaining('Sara'), findsNothing);
      expect(find.byType(ZyraProfileImage), findsNothing);
      await _nav(tester, 2);
      expect(find.textContaining('Sara'), findsNothing);
      await _nav(tester, 1);
      await _press(tester, 'draft_end_$_fixture');
      expect(find.text('End this Journey?'), findsOneWidget);
      expect(find.textContaining('Sara'), findsNothing);
      await _press(tester, 'draft_confirm_end_$_fixture');
      await _nav(tester, 0);
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      await _openEnded(tester);
      expect(_key('concept_blocked_archive_$_fixture'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, suffix: 'standard'),
    (size: Size(320, 568), scale: 1.4, suffix: 'compact140'),
    (size: Size(320, 568), scale: 2.0, suffix: 'compact200'),
  ]) {
    for (final design in _visibleBrowseDesigns) {
      testWidgets(
        'whole-app ${design.name} ${viewport.suffix} neutral Browse keeps decisions deliberate',
        (tester) async {
          final network = _NoNetwork();
          await HttpOverrides.runWithHttpOverrides(() async {
            await _mount(tester, size: viewport.size, scale: viewport.scale);
            await _selectBrowseDesign(tester, design);
            ZyraOneJourneyBrowseDesigns body() =>
                tester.widget<ZyraOneJourneyBrowseDesigns>(
                  find.byType(ZyraOneJourneyBrowseDesigns),
                );
            final before = body();
            expect(before.design, design);
            expect(before.profiles[before.selectedIndex].id, _fixture);
            final requestKey = 'draft_profile_$_fixture';
            final staleRequest = _callback(tester, requestKey);
            expect(_key('concept_save_$_fixture'), findsNothing);
            expect(find.text('Save'), findsNothing);
            final staleProfile = _action(
              tester,
              'concept_browse_open_$_fixture',
            );
            await _captureCandidate(
              tester,
              'browse_design_${design.name}_${viewport.suffix}',
            );
            await _press(tester, 'concept_next_profile');
            expect(body().profiles[body().selectedIndex].id, isNot(_fixture));
            staleRequest();
            staleProfile?.call();
            await tester.pumpAndSettle();
            expect(_key('draft_confirm_request'), findsNothing);
            for (var i = 1; i < before.profiles.length; i++) {
              await _press(tester, 'concept_next_profile');
            }
            expect(body().profiles[body().selectedIndex].id, _fixture);
            expect(
              body().profiles.map((profile) => profile.id),
              contains(_fixture),
            );
            await _openRequests(tester, sent: true);
            expect(_key('concept_request_${_fixture}_header'), findsNothing);
            await _nav(tester, 2);
            _expectSingleMyZyra(tester);
            expect(_key('concept_saved_${_fixture}_header'), findsNothing);
            await _nav(tester, 0);
            expect(body().design, design);
            expect(_key('concept_save_$_fixture'), findsNothing);
            await _openRequests(tester, sent: true);
            expect(_key('concept_request_${_fixture}_header'), findsNothing);
            await _nav(tester, 0);
            await _press(tester, requestKey);
            expect(_key('draft_confirm_request'), findsNothing);
            expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
            expect(body().design, design);
            expect(body().selectedIndex, before.selectedIndex);
            final person = body().profiles.firstWhere((p) => p.id == _fixture);
            expect(body().requestLabel!(person), 'Request sent');
            expect(body().canRequest!(person), isTrue);
            await _press(tester, requestKey);
            expect(body().design, design);
            expect(body().selectedIndex, before.selectedIndex);
            expect(body().requestLabel!(person), 'Request a Journey');
            await _openRequests(tester, sent: true);
            expect(_key('concept_request_${_fixture}_header'), findsNothing);
            await _nav(tester, 0);
            expect(body().design, design);
            expect(tester.takeException(), isNull);
          }, network);
          expect(network.attempts, 0);
        },
      );
    }
  }

  testWidgets(
    'current Portrait survives tabs and local reset without global preference writes',
    (tester) async {
      final network = _NoNetwork();
      SharedPreferences.setMockInitialValues({'ordinary-preference': 'keep'});
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      Map<String, Object?> snapshot() => {
        for (final key in prefs!.getKeys()) key: prefs.get(key),
      };
      final beforePreferences = snapshot();
      final palette = ZyraColors.devPalette;
      final gold = ZyraAppGoldStyle.instance.enabled;
      final font = ZyraText.appFont;
      final haptic = ZyraInteractionStyle.hapticLevel;
      final app = AppState.instance;
      final ordinarySaved = List.of(app.saved);
      final ordinaryActive = List.of(app.activeJourneys);
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        for (final design in _visibleBrowseDesigns) {
          await _selectBrowseDesign(tester, design);
          await _nav(tester, 4);
          await _nav(tester, 0);
          expect(
            tester
                .widget<ZyraOneJourneyBrowseDesigns>(
                  find.byType(ZyraOneJourneyBrowseDesigns),
                )
                .design,
            design,
          );
          await _press(tester, 'draft_rules');
          await _press(tester, 'draft_reset');
          expect(
            tester
                .widget<ZyraOneJourneyBrowseDesigns>(
                  find.byType(ZyraOneJourneyBrowseDesigns),
                )
                .design,
            design,
          );
        }
        expect(snapshot(), beforePreferences);
        expect(ZyraColors.devPalette, palette);
        expect(ZyraAppGoldStyle.instance.enabled, gold);
        expect(ZyraText.appFont, font);
        expect(ZyraInteractionStyle.hapticLevel, haptic);
        expect(app.saved, ordinarySaved);
        expect(app.activeJourneys, ordinaryActive);
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'stale request segments and single-page Dashboard routes refuse navigation ABA',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 2);
      _expectSingleMyZyra(tester);
      final staleDashboardRoute = tester
          .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
          .onNavigate!;
      await _openRequests(tester);
      final staleSegment = _retainedRequestTabs(tester);
      await _nav(tester, 0);
      await _openRequests(tester);
      staleSegment(1);
      await tester.pumpAndSettle();
      expect(_selector(tester, _requestLabels).selectedIndex, 0);
      await _nav(tester, 2);
      staleDashboardRoute(
        const SupportiveCard(
          id: 'concept-my-requests',
          section: SupportiveSection.stand,
          title: 'Journey requests',
          target: ZyraDashboardTarget.connectionsActivity,
        ),
      );
      await tester.pumpAndSettle();
      _expectSingleMyZyra(tester);
      expect(_key('concept_activity_requests'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, suffix: 'standard'),
    (size: Size(320, 568), scale: 2.0, suffix: 'compact200'),
  ]) {
    for (final reduce in [false, true]) {
      testWidgets(
        'Requests has two swipe pages and Introductions is a separate leaf ${viewport.suffix} reduce=$reduce',
        (tester) async {
          final network = _NoNetwork();
          final app = AppState.instance;
          final ordinarySaved = List.of(app.saved);
          final ordinaryJourneys = List.of(app.activeJourneys);
          final captureSuffix =
              '${viewport.suffix}_${reduce ? 'reduced' : 'motion'}';
          await HttpOverrides.runWithHttpOverrides(() async {
            await _mount(
              tester,
              size: viewport.size,
              scale: viewport.scale,
              reduce: reduce,
            );
            await _openRequests(tester);
            final pager = find.descendant(
              of: _key('concept_activity_requests'),
              matching: find.byType(PageView),
            );
            ZyraRequestActivityPresentation requests() =>
                tester.widget<ZyraRequestActivityPresentation>(
                  _key('concept_activity_requests'),
                );

            void expectRequestPage(int index) {
              expect(pager, findsOneWidget);
              final page = tester.widget<PageView>(pager);
              final source = requests();
              expect(source.labels, _requestLabels);
              expect(source.pages, hasLength(3));
              expect(source.selectedIndex, index);
              expect(page.scrollDirection, Axis.horizontal);
              expect(page.controller!.page, closeTo(index, .01));
              final selector = _selector(tester, _requestLabels);
              _expectRequestTabs(tester, selector);
              expect(selector.selectedIndex, index);
              expect(selector.segmentKeys, const [
                ValueKey('draft_requests_0'),
                ValueKey('draft_requests_1'),
                ValueKey('draft_requests_2'),
              ]);
              expect(_key('draft_requests_2'), findsOneWidget);
              expect(_key('concept_activity_introductions'), findsNothing);
              expect(_key('concept_activity_back'), findsNothing);
              expect(_key('concept_pull_down_back_scope'), findsOneWidget);
              expect(find.byType(ZyraShellNavigation), findsNothing);
              expect(find.byType(ZyraQuietDashboard), findsNothing);
            }

            void expectIntroductions() {
              expect(_key('concept_activity_requests'), findsNothing);
              final source = tester.widget<ZyraRequestActivityPresentation>(
                _key('concept_activity_introductions'),
              );
              expect(source.title, 'Introductions');
              expect(source.pages, hasLength(1));
              expect(source.selectedIndex, 0);
              expect(
                source.pages.single.whereType<ZyraRequestActivityCard>(),
                isEmpty,
              );
              expect(find.byType(PageView), findsNothing);
              for (final index in [0, 1, 2]) {
                expect(_key('draft_requests_$index'), findsNothing);
              }
              expect(find.text('No introductions yet'), findsOneWidget);
              expect(
                find.text(
                  'People your Guardians put forward will appear here.',
                ),
                findsOneWidget,
              );
              expect(_key('concept_pull_down_back_scope'), findsOneWidget);
            }

            Future<void> backToMyZyra() async {
              await _returnPage(
                tester,
                from: _key('concept_connections_title'),
              );
              _expectSingleMyZyra(tester);
              expect(_key('concept_activity_requests'), findsNothing);
              expect(_key('concept_activity_introductions'), findsNothing);
              expect(find.byType(ZyraShellNavigation), findsOneWidget);
            }

            expectRequestPage(0);
            expect(_key('concept_request_draft-amira_header'), findsOneWidget);
            await _captureCandidate(
              tester,
              'requests_received_$captureSuffix',
              requests: true,
            );
            for (final index in [1, 0]) {
              await _press(tester, 'draft_requests_$index');
              expectRequestPage(index);
              if (index == 1) {
                expect(find.text('No sent requests yet.'), findsOneWidget);
                await _captureCandidate(
                  tester,
                  'requests_sent_$captureSuffix',
                  requests: true,
                );
              }
            }
            // Actual body swipes page Received/Sent in both directions.
            for (final index in [1, 0]) {
              final current = tester.widget<PageView>(pager).controller!.page!;
              await tester.drag(
                pager,
                Offset(
                  (index > current ? -1.0 : 1.0) *
                      tester.getSize(pager).width *
                      .8,
                  0,
                ),
              );
              await tester.pumpAndSettle();
              expectRequestPage(index);
            }
            // Past follows Sent; Introductions remains its own separate destination.
            await _press(tester, 'draft_requests_1');
            await tester.drag(
              pager,
              Offset(-tester.getSize(pager).width * .8, 0),
            );
            await tester.pumpAndSettle();
            expectRequestPage(2);
            await _press(tester, 'draft_requests_0');
            await tester.dragFrom(
              tester.getCenter(_key('concept_connections_title')),
              const Offset(0, 24),
            );
            await tester.pumpAndSettle();
            expectRequestPage(0);
            await tester.dragFrom(
              tester.getCenter(_key('concept_connections_title')),
              const Offset(120, 8),
            );
            await tester.pumpAndSettle();
            expectRequestPage(0);

            final staleSource = requests().onChanged;
            final staleSegments = _retainedRequestTabs(tester);
            await backToMyZyra();
            for (final index in [0, 1]) {
              await _press(tester, 'my-zyra-route-concept-my-requests');
              if (index != 0) await _press(tester, 'draft_requests_$index');
              expectRequestPage(index);
              await backToMyZyra();
            }
            await _captureCandidate(
              tester,
              'my_zyra_requests_introductions_$captureSuffix',
              requests: true,
            );
            await _press(tester, 'my-zyra-route-concept-my-introductions');
            expectIntroductions();
            staleSource(1);
            staleSegments(0);
            staleSegments(1);
            await tester.pumpAndSettle();
            expectIntroductions();
            await _captureCandidate(
              tester,
              'requests_introductions_$captureSuffix',
              requests: true,
            );
            await tester.drag(
              find.byKey(const PageStorageKey('concept_connections_page_0')),
              const Offset(-200, 0),
            );
            await tester.pumpAndSettle();
            expectIntroductions();
            await backToMyZyra();

            // Same-name route ABA cannot revive the former delegates.
            await _press(tester, 'my-zyra-route-concept-my-requests');
            expectRequestPage(0);
            staleSource(1);
            staleSegments(1);
            await tester.pumpAndSettle();
            expectRequestPage(0);
            await backToMyZyra();
            expect(app.saved, ordinarySaved);
            expect(app.activeJourneys, ordinaryJourneys);
            expect(tester.takeException(), isNull);
          }, network);
          expect(network.attempts, 0);
        },
      );
    }
  }

  for (final reduce in [false, true]) {
    testWidgets(
      'Requests downward scroll below the reading origin does not close reduce=$reduce',
      (tester) async {
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(
            tester,
            size: const Size(320, 568),
            scale: 2,
            reduce: reduce,
          );
          await _openRequests(tester);
          await _press(tester, 'concept_request_draft-amira_header');
          final list = find.byKey(
            const PageStorageKey('concept_connections_page_0'),
          );
          final scrollable = find
              .descendant(of: list, matching: find.byType(Scrollable))
              .first;
          ScrollPosition position() =>
              tester.state<ScrollableState>(scrollable).position;
          expect(position().maxScrollExtent, greaterThan(0));
          await tester.drag(list, const Offset(0, -260));
          await tester.pumpAndSettle();
          expect(position().pixels, greaterThan(0));
          // This gesture begins below the top. Even a deliberate downward pull
          // must read/scroll the card, not turn an in-flight return to the top
          // into dismissal of the entire Requests page.
          final belowTop = position().pixels;
          await tester.drag(list, const Offset(0, 180));
          await tester.pumpAndSettle();
          expect(_key('concept_activity_requests'), findsOneWidget);
          expect(_selector(tester, _requestLabels).selectedIndex, 0);
          expect(find.byType(ZyraQuietDashboard), findsNothing);
          expect(position().pixels, lessThan(belowTop));
          for (
            var attempt = 0;
            position().pixels > .5 && attempt < 8;
            attempt++
          ) {
            await tester.drag(list, const Offset(0, 220));
            await tester.pumpAndSettle();
            expect(_key('concept_activity_requests'), findsOneWidget);
          }
          expect(position().pixels, closeTo(0, .5));
          // Returning through Back is separate from ordinary reading gestures.
          await _returnPage(tester, from: list);
          _expectSingleMyZyra(tester);
          expect(find.byType(ZyraShellNavigation), findsOneWidget);
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );

    testWidgets(
      'Requests Sent profile Back returns one level with its selected tab reduce=$reduce',
      (tester) async {
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester, reduce: reduce);
          await _press(tester, 'draft_profile_$_fixture');
          await _openRequests(tester, sent: true);
          final staleSource = tester
              .widget<ZyraRequestActivityPresentation>(
                _key('concept_activity_requests'),
              )
              .onChanged;
          await _press(tester, 'concept_request_${_fixture}_header');
          await _press(tester, 'concept_request_profile_$_fixture');
          expect(find.byType(ZyraOneJourneyBrowsePresentation), findsOneWidget);
          expect(_key('concept_activity_requests'), findsNothing);
          final staleLeafBack = tester
              .widget<Semantics>(_returnSemantics())
              .properties
              .onDismiss!;
          await _returnPage(tester);
          expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
          expect(_key('concept_activity_requests'), findsOneWidget);
          expect(_selector(tester, _requestLabels).selectedIndex, 1);
          expect(
            tester
                .widget<ZyraRequestActivityPresentation>(
                  _key('concept_activity_requests'),
                )
                .selectedIndex,
            1,
          );
          expect(_key('concept_request_${_fixture}_header'), findsOneWidget);
          expect(find.byType(ZyraQuietDashboard), findsNothing);
          expect(find.byType(ZyraShellNavigation), findsNothing);
          staleSource(0);
          staleLeafBack();
          await tester.pumpAndSettle();
          expect(_key('concept_activity_requests'), findsOneWidget);
          expect(_selector(tester, _requestLabels).selectedIndex, 1);
          await _returnPage(tester, from: _key('concept_connections_title'));
          _expectSingleMyZyra(tester);
          await _press(tester, 'my-zyra-route-concept-my-requests');
          await _press(tester, 'draft_requests_1');
          expect(_key('concept_request_${_fixture}_header'), findsOneWidget);
          expect(_key('draft_confirm_request'), findsNothing);
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );
  }

  for (final action in ['dismiss', 'custom Back', 'system Back']) {
    testWidgets(
      'Introductions accessible $action returns to My ZYRA with its captured Back return',
      (tester) async {
        final handle = tester.ensureSemantics();
        final network = _NoNetwork();
        try {
          await HttpOverrides.runWithHttpOverrides(() async {
            await _mount(tester);
            await _openRequests(tester);
            await _returnPage(tester);
            await _press(tester, 'my-zyra-route-concept-my-introductions');
            expect(_key('concept_activity_introductions'), findsOneWidget);
            expect(find.text('No introductions yet'), findsOneWidget);
            expect(_key('concept_activity_back'), findsNothing);
            final semantics = _returnSemantics();
            expect(semantics, findsOneWidget);
            final annotation = tester.widget<Semantics>(semantics);
            final retainedDismiss = annotation.properties.onDismiss!;
            final node = tester.getSemantics(semantics);
            final owner = tester.renderObject<RenderObject>(semantics).owner;
            expect(owner, isNotNull);
            final semanticsOwner = owner!.semanticsOwner;
            expect(semanticsOwner, isNotNull);
            expect(
              node.getSemanticsData().hasAction(ui.SemanticsAction.dismiss),
              isTrue,
            );
            if (action == 'system Back') {
              await tester
                  .state<NavigatorState>(find.byType(Navigator))
                  .maybePop();
            } else if (action == 'custom Back') {
              final custom = annotation.properties.customSemanticsActions!.keys
                  .singleWhere((entry) => entry.label == 'Back');
              final id = CustomSemanticsAction.getIdentifier(custom);
              expect(
                node.getSemanticsData().customSemanticsActionIds,
                contains(id),
              );
              semanticsOwner!.performAction(
                node.id,
                ui.SemanticsAction.customAction,
                id,
              );
            } else {
              semanticsOwner!.performAction(
                node.id,
                ui.SemanticsAction.dismiss,
              );
            }
            await tester.pumpAndSettle();
            _expectSingleMyZyra(tester);
            expect(find.byType(ZyraShellNavigation), findsOneWidget);
            expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
            await _press(tester, 'my-zyra-route-concept-my-requests');
            retainedDismiss();
            await tester.pumpAndSettle();
            expect(_key('concept_activity_requests'), findsOneWidget);
            expect(_selector(tester, _requestLabels).selectedIndex, 0);
            expect(tester.takeException(), isNull);
          }, network);
          expect(network.attempts, 0);
        } finally {
          handle.dispose();
        }
      },
    );
  }

  testWidgets(
    'fresh inactive Requests card actions cannot act behind another tab',
    (tester) async {
      final network = _NoNetwork();
      final app = AppState.instance;
      final ordinarySaved = List.of(app.saved);
      final ordinaryJourneys = List.of(app.activeJourneys);
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _press(tester, 'draft_profile_$_fixture');
        await _openRequests(tester);
        ZyraRequestActivityPresentation source() =>
            tester.widget<ZyraRequestActivityPresentation>(
              _key('concept_activity_requests'),
            );
        List<String> requestIds(int tab) => source().pages[tab]
            .whereType<ZyraRequestActivityCard>()
            .map((card) => card.profile.id)
            .toList();
        final received = requestIds(0);
        final sent = requestIds(1);
        expect(received, contains('draft-amira'));
        expect(sent, [_fixture]);

        for (final visibleTab in [0, 1]) {
          await _press(tester, 'draft_requests_$visibleTab');
          for (final inactiveTab in [0, 1]) {
            if (inactiveTab == visibleTab) continue;
            final id = inactiveTab == 0 ? 'draft-amira' : _fixture;
            for (var action = 0; action < 4; action++) {
              // Read a fresh card/delegate from the current presentation,
              // rather than letting stale-revision guards mask tab authority.
              final card = source().pages[inactiveTab]
                  .whereType<ZyraRequestActivityCard>()
                  .singleWhere((card) => card.profile.id == id);
              final callbacks = [
                card.primary.onTap,
                ...card.actions.map((button) => button.onTap),
                card.onReport,
              ];
              expect(callbacks, hasLength(4));
              expect(callbacks[action], isNotNull);
              callbacks[action]!();
              await tester.pumpAndSettle();
              expect(_key('concept_activity_requests'), findsOneWidget);
              expect(source().selectedIndex, visibleTab);
              expect(
                _selector(tester, _requestLabels).selectedIndex,
                closeTo(visibleTab, .01),
              );
              expect(requestIds(0), received);
              expect(requestIds(1), sent);
              expect(
                find.byType(ZyraOneJourneyBrowsePresentation),
                findsNothing,
              );
              expect(find.byType(ZyraConceptJourneyPresentation), findsNothing);
              expect(_key('draft_safety_block'), findsNothing);
              expect(find.text('Request declined.'), findsNothing);
              expect(find.text('Request cancelled.'), findsNothing);
              expect(tester.takeException(), isNull);
            }
          }
        }
        // The guards are not global disablement: genuine visible actions still
        // alter only the disposable fixture once their own tab is selected.
        await _press(tester, 'draft_requests_0');
        await _press(tester, 'draft_decline_draft-amira');
        expect(requestIds(0), isNot(contains('draft-amira')));
        expect(find.text('Request declined.'), findsNothing);
        expect(requestIds(1), sent);
        await _press(tester, 'draft_requests_1');
        await _press(tester, 'draft_cancel_$_fixture');
        expect(requestIds(1), isEmpty);
        expect(find.text('Request cancelled.'), findsNothing);
        expect(app.saved, ordinarySaved);
        expect(app.activeJourneys, ordinaryJourneys);
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'local notification dispatcher routes requests to My ZYRA and focus to Journey',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        Future<void> openDispatcher() async {
          await _nav(tester, 2);
          final dashboard = tester.widget<ZyraQuietDashboard>(
            find.byType(ZyraQuietDashboard),
          );
          // Exercise the real local dispatch seam. The current fixture list does
          // not expose a notifications entry; this is not a button-visibility claim.
          dashboard.onNavigate!(
            const SupportiveCard(
              id: 'local-notifications-probe',
              section: SupportiveSection.stand,
              title: 'Updates',
              target: ZyraDashboardTarget.notifications,
            ),
          );
          await tester.pumpAndSettle();
        }

        await openDispatcher();
        expect(
          find.text('A Journey invitation is waiting in My ZYRA.'),
          findsOneWidget,
        );
        await _press(tester, 'concept_updates_connections');
        expect(find.text('Journey requests'), findsOneWidget);
        expect(_selector(tester, _requestLabels).selectedIndex, 0);
        await _fillJourney(tester);
        await openDispatcher();
        await _press(tester, 'concept_updates_connections');
        expect(find.byType(ZyraConceptJourneyPresentation), findsOneWidget);
        expect(find.text('Journey with Sara'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, suffix: 'standard'),
    (size: Size(320, 568), scale: 1.4, suffix: 'compact140'),
    (size: Size(320, 568), scale: 2.0, suffix: 'compact200'),
  ]) {
    testWidgets(
      'simplified My ZYRA is one guarded information page ${viewport.suffix}',
      (tester) async {
        final network = _NoNetwork();
        final app = AppState.instance;
        final ordinarySaved = List.of(app.saved);
        final ordinaryJourneys = List.of(app.activeJourneys);
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester, size: viewport.size, scale: viewport.scale);
          await _nav(tester, 2);
          _expectSingleMyZyra(tester);
          final dashboard = tester.widget<ZyraQuietDashboard>(
            find.byType(ZyraQuietDashboard),
          );
          expect(dashboard.fixtureCards.map((card) => card.id), [
            'concept-request-draft-amira',
            'concept-my-requests',
            'concept-my-introductions',
            'concept-my-ended',
          ]);
          expect(dashboard.onInsightsUpgrade, isNull);
          final navigate = dashboard.onNavigate!;
          // Removed destinations are not merely hidden. A stale/forged old
          // dashboard ID cannot fall through to requests or reveal history.
          for (final id in ['concept-saved', 'concept-my-paused']) {
            navigate(
              SupportiveCard(
                id: id,
                section: SupportiveSection.stand,
                title: 'Retired preview option',
                target: ZyraDashboardTarget.connectionsActivity,
              ),
            );
            await tester.pumpAndSettle();
            _expectSingleMyZyra(tester);
            for (final retired in ['saved', 'paused', 'requests']) {
              expect(_key('concept_activity_$retired'), findsNothing);
            }
          }
          await tester.drag(
            _key('my-zyra-quiet-scroll-0'),
            const Offset(-200, 0),
          );
          await tester.pumpAndSettle();
          _expectSingleMyZyra(tester);
          await _captureCandidate(
            tester,
            'simplified_my_zyra_empty_${viewport.suffix}',
          );
          await _seedJourneyCards(tester, 2);
          await _nav(tester, 2);
          _expectSingleMyZyra(tester);
          await _captureCandidate(
            tester,
            'simplified_my_zyra_two_journeys_${viewport.suffix}',
          );
          expect(
            _key('my-zyra-route-concept-current-journey-draft-aisha'),
            findsNothing,
          );
          expect(find.text('Your Journey with Aisha'), findsNothing);
          await _nav(tester, 1);
          await _press(tester, 'draft_journey_draft-aisha');
          expect(find.text('Journey with Aisha'), findsOneWidget);
          expect(_key('draft_pause_draft-aisha'), findsNothing);
          await _nav(tester, 2);
          await _press(tester, 'draft_rules');
          await _press(tester, 'draft_history');
          await _nav(tester, 2);
          _expectSingleMyZyra(tester);
          await _openEnded(tester);
          expect(_key('concept_activity_ended'), findsOneWidget);
          expect(_key('draft_journey_draft-noor_header'), findsOneWidget);
          expect(_key('draft_journey_draft-hana_header'), findsNothing);
          expect(find.textContaining('Paused'), findsNothing);
          await _captureCandidate(
            tester,
            'simplified_my_zyra_ended_${viewport.suffix}',
          );
          await _nav(tester, 1);
          expect(
            find.byType(ZyraOneJourneyConnectionsActiveCard),
            findsNWidgets(2),
          );
          expect(app.saved, ordinarySaved);
          expect(app.activeJourneys, ordinaryJourneys);
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );
  }

  for (final change in ['page ABA', 'role ABA', 'account generation']) {
    testWidgets('simplified My ZYRA retained navigation refuses $change', (
      tester,
    ) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _nav(tester, 2);
        final stale = tester
            .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
            .onNavigate!;
        if (change == 'account generation') {
          ZyraAccountState.resetForTesting();
          AppState.instance.resetForAccountChange();
        } else if (change == 'role ABA') {
          await _press(tester, 'draft_rules');
          await _press(tester, 'draft_role_guardian');
          await _press(tester, 'draft_rules');
          await _press(tester, 'draft_role_seeker');
          await _nav(tester, 2);
        } else {
          await _nav(tester, 0);
          await _nav(tester, 2);
        }
        stale(
          const SupportiveCard(
            id: 'concept-my-requests',
            section: SupportiveSection.stand,
            title: 'Journey requests',
            target: ZyraDashboardTarget.connectionsActivity,
          ),
        );
        await tester.pumpAndSettle();
        expect(_key('concept_activity_requests'), findsNothing);
        if (change == 'account generation') {
          expect(find.text('Preview closed'), findsOneWidget);
          expect(find.byType(ZyraQuietDashboard), findsNothing);
        } else {
          _expectSingleMyZyra(tester);
          await _openRequests(tester);
          expect(_key('concept_activity_requests'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    });
  }

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, suffix: 'standard'),
    (size: Size(320, 568), scale: 1.4, suffix: 'compact140'),
    (size: Size(320, 568), scale: 2.0, suffix: 'compact200'),
  ]) {
    testWidgets(
      'locked card addressed options keep both Journeys read-only ${viewport.suffix}',
      (tester) async {
        final network = _NoNetwork();
        final app = AppState.instance;
        final ordinarySaved = List.of(app.saved);
        final ordinaryPotential = List.of(app.potentialJourneys);
        final ordinaryActive = List.of(app.activeJourneys);
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester, size: viewport.size, scale: viewport.scale);
          await _seedJourneyCards(tester, 2);
          for (final person in const [
            (id: 'draft-sara', name: 'Sara'),
            (id: 'draft-aisha', name: 'Aisha'),
          ]) {
            await _press(tester, 'draft_journey_options_${person.id}');
            final options = tester.widget<ZyraConceptJourneyOptions>(
              find.byType(ZyraConceptJourneyOptions),
            );
            expect(options.id, person.id);
            expect(options.firstName, person.name);
            expect(options.inline, isTrue);
            expect(find.byType(BottomSheet), findsNothing);
            expect(
              _key('concept_expanded_journey_${person.id}'),
              findsOneWidget,
            );
            expect(find.text('Compatibility score'), findsOneWidget);
            expect(find.text('Check compatibility score'), findsNothing);
            expect(find.text('Guardians'), findsOneWidget);
            expect(options.canViewBio, isFalse);
            expect(options.canViewCompatibility, isFalse);
            expect(
              _key('draft_options_compatibility_locked_${person.id}'),
              findsOneWidget,
            );
            expect(_key('draft_options_pause_${person.id}'), findsNothing);
            expect(find.text('Request Pause'), findsNothing);
            await _captureCandidate(
              tester,
              'addressed_options_${person.id}_${viewport.suffix}',
              cardLockin: true,
            );
            await _press(tester, 'draft_options_compatibility_${person.id}');
            expect(
              _key('draft_journey_compatibility_locked_${person.id}'),
              findsOneWidget,
            );
            expect(_compatibilityResult(person.id), findsNothing);
            expect(find.text('Compatibility score'), findsOneWidget);
            expect(find.text('You and ${person.name}'), findsNothing);
            expect(find.text('Your result stays private'), findsOneWidget);
            expect(find.text('Your shared result'), findsNothing);
            expect(find.textContaining('%'), findsNothing);
            expect(_key('draft_reveal_${person.id}'), findsNothing);
            expect(_key('draft_peer_reveal_${person.id}'), findsNothing);
            expect(_key('concept_message'), findsNothing);
            expect(
              find.text(
                'Complete Compatibility Reveal together to view your result.',
              ),
              findsOneWidget,
            );
            await _captureCandidate(
              tester,
              'addressed_compatibility_${person.id}_${viewport.suffix}',
              cardLockin: true,
            );
            await _press(tester, 'draft_disclosure_continue_${person.id}');
            expect(find.byType(ZyraConceptJourneyPresentation), findsOneWidget);
            expect(find.text('Journey with ${person.name}'), findsOneWidget);
            expect(
              tester
                  .widget<ZyraConceptJourneyPresentation>(
                    find.byType(ZyraConceptJourneyPresentation),
                  )
                  .stage
                  .value,
              'salam_exchange',
            );
            // Opening the locked explanation did not seal Salam or advance.
            await _returnPage(tester);
            expect(
              _key('draft_journey_compatibility_locked_${person.id}'),
              findsOneWidget,
            );
            expect(_compatibilityResult(person.id), findsNothing);
            await returnZyraPreviewPage(tester);
            await _press(tester, 'draft_journey_options_${person.id}');
            await _press(tester, 'draft_options_guardians_${person.id}');
            expect(
              _key('draft_journey_guardians_${person.id}'),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: _key('draft_journey_guardians_${person.id}'),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Text &&
                      widget.data == 'Journey with ${person.name}' &&
                      widget.style?.fontSize == 13,
                ),
              ),
              findsOneWidget,
              reason:
                  'The addressed context rail is distinct from retained permission-row titles.',
            );
            final peerRoute = _key('draft_journey_guardians_${person.id}');
            final guardians = tester
                .widget<ZyraJourneyPeerGuardiansPresentation>(peerRoute);
            expect(guardians.subjectId, person.id);
            expect(guardians.firstName, person.name);
            expect(
              guardians.guardians!.map(
                (g) => (g.firstName, g.relationship, g.isMain),
              ),
              [
                ('Ibrahim', 'uncle', true),
                ('Maryam', 'sister', false),
                ('Yusuf', 'grandfather', false),
              ],
            );
            expect(find.byType(SeekerGuardianPage), findsNothing);
            expect(_key('guardian-page-view'), findsNothing);
            expect(
              find.descendant(
                of: peerRoute,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Switch || w is ButtonStyleButton || w is IconButton,
                ),
              ),
              findsNothing,
            );
            for (final label in [
              'Remove Guardian',
              'Remove as Main Guardian',
              'Active Journey access',
              'Share past Journey summaries',
            ]) {
              expect(
                find.descendant(of: peerRoute, matching: find.text(label)),
                findsNothing,
              );
            }
            await _captureCandidate(
              tester,
              'addressed_guardians_${person.id}_${viewport.suffix}',
              cardLockin: true,
            );
            await returnZyraPreviewPage(tester);
            expect(
              find.byType(ZyraOneJourneyConnectionsActiveCard),
              findsNWidgets(2),
            );
            expect(_key('draft_journey_options_${person.id}'), findsOneWidget);
          }
          expect(app.saved, ordinarySaved);
          expect(app.potentialJourneys, ordinaryPotential);
          expect(app.activeJourneys, ordinaryActive);
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );
  }

  testWidgets(
    'locked card compatibility follows both reveal choices without computing a score',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _fillJourney(tester);
        await _press(tester, 'draft_salam_$_fixture');
        await _press(tester, 'draft_peer_salam_$_fixture');
        await _advanceStage(tester);
        await _press(tester, 'draft_reveal_$_fixture');
        await _press(tester, 'concept_journey_menu');
        await _press(tester, 'draft_options_compatibility_$_fixture');
        expect(
          _key('draft_journey_compatibility_locked_$_fixture'),
          findsOneWidget,
        );
        expect(_compatibilityResult(_fixture), findsNothing);
        expect(find.text('Your result stays private'), findsOneWidget);
        expect(find.text('Your shared result'), findsNothing);
        expect(
          find.text(
            'Complete Compatibility Reveal together to view your result.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('%'), findsNothing);
        await _captureCandidate(
          tester,
          'addressed_reveal_one_choice_standard',
          cardLockin: true,
        );
        await _press(tester, 'draft_disclosure_continue_$_fixture');
        await _press(tester, 'draft_peer_reveal_$_fixture');
        expect(find.text('You both chose to reveal.'), findsOneWidget);
        await _press(tester, 'concept_journey_menu');
        await _press(tester, 'draft_options_compatibility_$_fixture');
        expect(
          _key('draft_journey_compatibility_locked_$_fixture'),
          findsOneWidget,
        );
        expect(_compatibilityResult(_fixture), findsNothing);
        expect(find.text('Your shared result'), findsNothing);
        expect(find.text('Your result stays private'), findsOneWidget);
        expect(
          find.text(
            'Complete Compatibility Reveal together to view your result.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('%'), findsNothing);
        expect(find.text('—'), findsNothing);
        expect(_key('draft_reveal_$_fixture'), findsNothing);
        expect(_key('draft_peer_reveal_$_fixture'), findsNothing);
        await _captureCandidate(
          tester,
          'addressed_reveal_mutual_standard',
          cardLockin: true,
        );
        await _press(tester, 'draft_disclosure_continue_$_fixture');
        await _press(tester, 'concept_journey_arrival_continue');
        expect(find.text('You both chose to reveal.'), findsOneWidget);
        await _advanceStage(tester);
        await _completeBioStep(tester);
        expect(find.textContaining('Guardian Gate'), findsWidgets);
        await _press(tester, 'concept_journey_menu');
        final completedMenu = tester.widget<ZyraConceptJourneyOptions>(
          find.byType(ZyraConceptJourneyOptions),
        );
        expect(completedMenu.canViewCompatibility, isTrue);
        expect(completedMenu.canViewBio, isTrue);
        expect(
          _key('draft_options_compatibility_locked_$_fixture'),
          findsNothing,
        );
        await _press(tester, 'draft_options_compatibility_$_fixture');
        expect(find.text('Compatibility score'), findsOneWidget);
        expect(find.text('You and Sara'), findsNothing);
        expect(_compatibilityResult(_fixture), findsNothing);
        expect(
          _key('draft_journey_compatibility_locked_$_fixture'),
          findsNothing,
        );
        expect(find.text('Your result'), findsOneWidget);
        expect(
          find.text(
            'You both chose to reveal. Your result is not available yet.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('%'), findsNothing);
        expect(_key('draft_reveal_$_fixture'), findsNothing);
        expect(_key('draft_peer_reveal_$_fixture'), findsNothing);
        expect(_key('draft_disclosure_continue_$_fixture'), findsNothing);
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  for (final choice in [
    ZyraConceptJourneyOption.compatibility,
    ZyraConceptJourneyOption.guardians,
  ]) {
    testWidgets(
      'locked card dismissed ${choice.name} handlers refuse after role ABA and preserve a fresh addressed page',
      (tester) async {
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester);
          await _seedJourneyCards(tester, 2);
          await _press(tester, 'draft_journey_options_$_fixture');
          final sheet = tester.widget<ZyraConceptJourneyOptions>(
            find.byType(ZyraConceptJourneyOptions),
          );
          final staleChoice = sheet.onSelected;
          final staleCancel = sheet.onCancel;
          await _cancelJourneyOptions(tester);
          staleChoice(choice);
          await tester.pumpAndSettle();
          expect(_compatibilityResult(_fixture), findsNothing);
          expect(
            _key('draft_journey_compatibility_locked_$_fixture'),
            findsNothing,
          );
          expect(_key('draft_journey_guardians_$_fixture'), findsNothing);
          await _tapRootNav(tester, 'Profile');
          await _press(tester, 'draft_role_guardian');
          await _tapRootNav(tester, 'Profile');
          await _press(tester, 'draft_role_seeker');
          await _tapRootNav(tester, 'Journey');
          staleChoice(choice);
          await tester.pumpAndSettle();
          expect(_compatibilityResult(_fixture), findsNothing);
          expect(
            _key('draft_journey_compatibility_locked_$_fixture'),
            findsNothing,
          );
          expect(_key('draft_journey_guardians_$_fixture'), findsNothing);
          await _press(tester, 'draft_journey_options_draft-aisha');
          await _press(tester, 'draft_options_${choice.name}_draft-aisha');
          final destination = choice == ZyraConceptJourneyOption.compatibility
              ? 'draft_journey_compatibility_locked_draft-aisha'
              : 'draft_journey_guardians_draft-aisha';
          expect(_key(destination), findsOneWidget);
          expect(_compatibilityResult('draft-aisha'), findsNothing);
          staleChoice(choice);
          staleCancel();
          await tester.pumpAndSettle();
          expect(_key(destination), findsOneWidget);
          expect(
            _key('draft_journey_compatibility_locked_$_fixture'),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );

    testWidgets(
      'locked card open ${choice.name} inline options refuse revoked authorization intent',
      (tester) async {
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester);
          await _seedJourneyCards(tester, 2);
          await _press(tester, 'draft_journey_options_$_fixture');
          final staleChoice = tester
              .widget<ZyraConceptJourneyOptions>(
                find.byType(ZyraConceptJourneyOptions),
              )
              .onSelected;
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          await tester.pumpAndSettle();
          staleChoice(choice);
          await tester.pumpAndSettle();
          expect(_compatibilityResult(_fixture), findsNothing);
          expect(
            _key('draft_journey_compatibility_locked_$_fixture'),
            findsNothing,
          );
          expect(_key('draft_journey_guardians_$_fixture'), findsNothing);
          expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
          expect(find.text('Preview closed'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );
  }

  testWidgets('ordinary launcher is absent and direct ordinary route refuses', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await _mount(tester, launcher: true);
    expect(_key('dev_discovery_view_request'), findsNothing);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Preview closed'), findsOneWidget);
    expect(_key('draft_scroll'), findsNothing);
    expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
    expect(find.text('Sara'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy launcher cannot open its draft', (tester) async {
    var beforeCalls = 0;
    await _mount(
      tester,
      launcher: true,
      enabled: false,
      onBeforeOpen: () => beforeCalls++,
    );
    expect(
      tester
          .widget<OutlinedButton>(_key('dev_discovery_view_request'))
          .onPressed,
      isNull,
    );
    await tester.tap(_key('dev_discovery_view_request'));
    await tester.pumpAndSettle();
    expect(beforeCalls, 0);
    expect(find.byType(ViewRequestDraftScreen), findsNothing);
  });

  testWidgets('protected launcher opens and Close returns to current app', (
    tester,
  ) async {
    var beforeCalls = 0;
    await _mount(tester, launcher: true, onBeforeOpen: () => beforeCalls++);
    await _press(tester, 'dev_discovery_view_request');
    expect(beforeCalls, 1);
    expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(ZyraConceptPreviewIsolation.active, isTrue);
    expect(_key('draft_profile_$_fixture'), findsOneWidget);
    await leaveZyraDeveloperPreview(tester);
    await tester.pumpAndSettle();
    expect(_key('dev_discovery_view_request'), findsOneWidget);
    expect(_key('draft_scroll'), findsNothing);
    expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
    expect(ZyraConceptPreviewIsolation.active, isFalse);
  });

  for (final exit in ['draft_close', 'concept_sign_out']) {
    testWidgets('$exit turns off the entire concept from a nested page', (
      tester,
    ) async {
      await _mount(tester, launcher: true);
      await _press(tester, 'dev_discovery_view_request');
      if (exit == 'draft_close') {
        await _openGallerySara(tester);
        await _press(tester, 'concept_filters');
        expect(_key('draft_save'), findsNothing);
      } else {
        await _nav(tester, 4);
      }
      await _press(tester, exit);
      expect(_key('dev_discovery_view_request'), findsOneWidget);
      expect(_key('draft_scroll'), findsNothing);
      expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
      expect(ZyraConceptPreviewIsolation.active, isFalse);
      await _press(tester, 'dev_discovery_view_request');
      await _openGallerySara(tester);
      expect(find.text('Save'), findsNothing);
      expect(_key('draft_save'), findsNothing);
      expect(_action(tester, 'draft_profile_$_fixture'), isNotNull);
    });
  }

  for (final change in ['revocation', 'ABA', 'account generation']) {
    testWidgets('$change refuses a captured stale launcher callback', (
      tester,
    ) async {
      var beforeCalls = 0;
      await _mount(tester, launcher: true, onBeforeOpen: () => beforeCalls++);
      final stale = _callback(tester, 'dev_discovery_view_request');
      if (change == 'account generation') {
        ZyraAccountState.resetForTesting();
        AppState.instance.resetForAccountChange();
      } else {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        if (change == 'ABA') {
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        }
      }
      stale();
      await tester.pumpAndSettle();
      expect(beforeCalls, 0);
      expect(_key('draft_scroll'), findsNothing);
      expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
      expect(_key('dev_discovery_view_request'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$change closes an open route and refuses stale actions', (
      tester,
    ) async {
      await _mount(tester);
      await _openGallerySara(tester);
      final stale = _callback(tester, 'draft_profile_$_fixture');
      if (change == 'account generation') {
        ZyraAccountState.resetForTesting();
        AppState.instance.resetForAccountChange();
      } else {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        if (change == 'ABA') {
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        }
      }
      stale();
      await tester.pumpAndSettle();
      expect(find.text('Preview closed'), findsOneWidget);
      expect(_key('draft_scroll'), findsNothing);
      expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
      expect(_key('draft_confirm_request'), findsNothing);
      expect(find.text('Sara'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('system Back first leaves a local page, not the concept route', (
    tester,
  ) async {
    await _mount(tester, launcher: true);
    await _press(tester, 'dev_discovery_view_request');
    await _openGallerySara(tester);
    await _press(tester, 'concept_filters');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(_key('draft_profile_$_fixture'), findsOneWidget);
    expect(_key('draft_request'), findsNothing);
    expect(_key('dev_discovery_view_request'), findsNothing);
    expect(ZyraConceptPreviewIsolation.active, isTrue);
    await leaveZyraDeveloperPreview(tester);
    await tester.pumpAndSettle();
    expect(_key('dev_discovery_view_request'), findsOneWidget);
    expect(ZyraConceptPreviewIsolation.active, isFalse);
  });

  testWidgets('onBeforeOpen account drift refuses route construction', (
    tester,
  ) async {
    await _mount(
      tester,
      launcher: true,
      onBeforeOpen: () {
        ZyraAccountState.resetForTesting();
        AppState.instance.resetForAccountChange();
      },
    );
    await _press(tester, 'dev_discovery_view_request');
    expect(find.byType(ViewRequestDraftScreen), findsNothing);
    expect(_key('dev_discovery_view_request'), findsNothing);
  });

  testWidgets('pending-open authorization ABA does not readmit lazy route', (
    tester,
  ) async {
    await _mount(tester, launcher: true);
    // Route construction is lazy: revoke and restore before its first frame.
    await tester.tap(_key('dev_discovery_view_request'));
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpAndSettle();
    expect(find.text('Preview closed'), findsOneWidget);
    expect(_key('draft_scroll'), findsNothing);
    expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
    expect(find.text('Sara'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained Close cannot pop a newer route or act after disposal', (
    tester,
  ) async {
    await _mount(tester, launcher: true);
    await _press(tester, 'dev_discovery_view_request');
    await openZyraDevControls(tester);
    final staleClose = _callback(tester, 'draft_close');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Unrelated route')),
      ),
    );
    await tester.pumpAndSettle();
    staleClose();
    await tester.pumpAndSettle();
    expect(find.text('Unrelated route'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    await leaveZyraDeveloperPreview(tester);
    await tester.pumpAndSettle();
    expect(_key('dev_discovery_view_request'), findsOneWidget);
    staleClose();
    await tester.pumpAndSettle();
    expect(_key('dev_discovery_view_request'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct stale-generation route refuses even authorized account', (
    tester,
  ) async {
    final previous = ZyraAccountState.generation;
    ZyraAccountState.resetForTesting();
    await _mount(tester, generation: previous);
    expect(find.text('Preview closed'), findsOneWidget);
    expect(_key('draft_scroll'), findsNothing);
    expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
  });

  testWidgets('covered concept cannot act behind a newer real route', (
    tester,
  ) async {
    await _mount(tester, launcher: true);
    await _press(tester, 'dev_discovery_view_request');
    await _openGallerySara(tester);
    final request = _callback(tester, 'draft_profile_$_fixture');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Unrelated route')),
      ),
    );
    await tester.pumpAndSettle();
    request();
    await tester.pumpAndSettle();
    expect(find.text('Unrelated route'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(_key('draft_confirm_request'), findsNothing);
    expect(_key('draft_profile_$_fixture'), findsOneWidget);
    final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    final person = browse.profiles.firstWhere(
      (person) => person.id == _fixture,
    );
    expect(browse.requestLabel!(person), 'Request a Journey');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending sign-out closes the concept and captured actions refuse',
    (tester) async {
      await _mount(tester);
      await _openGallerySara(tester);
      final stale = _callback(tester, 'draft_profile_$_fixture');
      await tester.runAsync(ZyraAccountState.beginSignOut);
      expect(ZyraAccountState.isSigningOut, isTrue);
      stale();
      await tester.pumpAndSettle();
      expect(find.text('Preview closed'), findsOneWidget);
      expect(_key('draft_confirm_request'), findsNothing);
      expect(ZyraConceptPreviewIsolation.active, isFalse);
      expect(tester.takeException(), isNull);
      ZyraAccountState.endSignOutAttempt();
    },
  );

  testWidgets(
    'Browse shares current navigation, full fake names and offline photos',
    (tester) async {
      await _mount(tester);
      final navigation = tester.widget<ZyraShellNavigation>(
        find.byType(ZyraShellNavigation),
      );
      expect(navigation.items.map((item) => item.label), [
        'Profiles',
        'Journey',
        'My ZYRA',
        'Guardian',
        'Profile',
      ]);
      expect(navigation.items.map((item) => item.icon), [
        Icons.search,
        Icons.route_outlined,
        Icons.dashboard_outlined,
        Icons.gpp_good_outlined,
        Icons.person_outline,
      ]);
      expect(navigation.items.map((item) => item.useJourneyGlyph), [
        false,
        true,
        false,
        false,
        false,
      ]);
      final position = tester
          .widgetList<Positioned>(
            find.descendant(
              of: find.byType(ZyraShellNavigation),
              matching: find.byType(Positioned),
            ),
          )
          .first;
      expect(position.left, 20);
      expect(position.right, 20);
      expect(position.bottom, 0);
      final initialProfile = _currentBrowseDetailsProfile(tester);
      expect(initialProfile.id, _fixture);
      expect(initialProfile.firstName, 'Sara');
      expect(initialProfile.surnameLine, 'Ahmed');
      expect(initialProfile.photos, hasLength(2));
      await _press(tester, 'concept_browse_photo_tap_$_fixture');
      _expectBrowsePhoto(tester, initialProfile, 0);
      expect(find.byType(ZyraProfileNameBlock), findsNothing);
      expect(_key('concept_browse_identity_$_fixture'), findsNothing);
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      final selectedProfile = browse.profiles[browse.selectedIndex];
      expect(selectedProfile.id, initialProfile.id);
      expect(selectedProfile.firstName, initialProfile.firstName);
      expect(selectedProfile.surnameLine, initialProfile.surnameLine);
      expect(selectedProfile.photos, initialProfile.photos);

      expect(
        initialProfile.photos.every(
          (photo) => photo.startsWith('data:image/jpeg;base64,'),
        ),
        isTrue,
      );
      expect(
        find.descendant(
          of: _key('concept_browse_photo_${_fixture}_0'),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Illustrated'), findsNothing);
      expect(find.text('27 · Birmingham'), findsNothing);
      expect(_key('concept_next_profile'), findsOneWidget);
      expect(_key('concept_previous_profile'), findsOneWidget);
      final portrait = tester.getRect(
        _key('concept_browse_photo_${_fixture}_0'),
      );
      final card = tester.getRect(_key('concept_browse_portrait_card'));
      expect(portrait.height, greaterThanOrEqualTo(160));
      expect(portrait.height, card.height);
      expect(card.contains(portrait.topLeft), isTrue);
      expect(
        card.contains(portrait.bottomRight - const Offset(.01, .01)),
        isTrue,
      );
      await _press(tester, 'concept_next_profile');
      expect(_currentBrowseDetailsProfile(tester).id, isNot(_fixture));
      await _press(tester, 'concept_previous_profile');
      expect(_currentBrowseDetailsProfile(tester).id, _fixture);
      await _openRequests(tester, sent: true);
      expect(_key('draft_recipient_$_fixture'), findsNothing);
    },
  );

  for (final reduce in [false, true]) {
    testWidgets(
      'Current photo taps cycle the filtered Browse without expanding at reduce=$reduce',
      (tester) async {
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester, reduce: reduce);
          await _press(tester, 'concept_filters');
          await _chooseBrowseFilter(tester, 'nationality', 'British (GB)');
          await _press(tester, 'concept_apply_filter');
          await _press(tester, 'concept_next_profile');
          ZyraOneJourneyBrowseDesigns browse() =>
              tester.widget<ZyraOneJourneyBrowseDesigns>(
                find.byType(ZyraOneJourneyBrowseDesigns),
              );
          final before = browse();
          final ids = before.profiles.map((person) => person.id).toList();
          final person = before.profiles[before.selectedIndex];
          expect(ids.length, 2);
          expect(before.selectedIndex, 1);
          expect(before.onProfile, isNull);
          final pager = _key('concept_browse_photo_swipe_${person.id}');
          final tap = 'concept_browse_photo_tap_${person.id}';
          expect(person.photos.length, greaterThan(1));
          final pageCount = person.photos.length + 1;
          for (var step = 1; step <= pageCount; step++) {
            await _press(tester, tap);
            final page = step % pageCount;
            expect(
              tester.widget<PageView>(pager).controller!.page,
              closeTo(page, .01),
            );
            if (page == 0) {
              expect(_currentBrowseDetailsProfile(tester).id, person.id);
            } else {
              _expectBrowsePhoto(tester, person, page - 1);
            }
            expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
            expect(_key('draft_confirm_request'), findsNothing);
          }
          await tester.drag(pager, const Offset(-300, 0));
          await tester.pumpAndSettle();
          expect(
            tester.widget<PageView>(pager).controller!.page,
            closeTo(1, .01),
          );
          expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
          expect(browse().design, ZyraOneJourneyBrowseDesign.portraitCard);
          expect(browse().selectedIndex, before.selectedIndex);
          expect(browse().profiles.map((person) => person.id), ids);
          expect(browse().profiles[before.selectedIndex].id, person.id);
          expect(find.byType(ZyraShellNavigation), findsOneWidget);
          await _openRequests(tester, sent: true);
          for (final id in ids) {
            expect(_key('concept_request_${id}_header'), findsNothing);
          }
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );
  }

  testWidgets(
    'Current vertical pulls remain in bounded Browse without expanding',
    (tester) async {
      await _mount(tester, reduce: false);
      await _press(tester, 'concept_browse_photo_tap_$_fixture');
      final pager = _key('concept_browse_photo_swipe_$_fixture');
      for (final delta in [const Offset(0, 45), const Offset(0, -220)]) {
        await tester.timedDragFrom(
          const Offset(150, 330),
          delta,
          const Duration(milliseconds: 600),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
        expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
        expect(
          tester.widget<PageView>(pager).controller!.page,
          closeTo(1, .01),
        );
        expect(_key('draft_confirm_request'), findsNothing);
      }
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Current photo cycling leaves inline invitation state untouched',
    (tester) async {
      await _mount(tester);
      ZyraOneJourneyBrowseDesigns browse() =>
          tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
      final before = browse();
      final ids = before.profiles.map((p) => p.id).toList();
      await _press(tester, 'draft_profile_$_fixture');
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(_key('draft_confirm_request'), findsNothing);
      expect(browse().selectedIndex, before.selectedIndex);
      expect(browse().profiles.map((p) => p.id), ids);
      final person = browse().profiles.firstWhere((p) => p.id == _fixture);
      expect(browse().requestLabel!(person), 'Request sent');
      final pager = _key('concept_browse_photo_swipe_$_fixture');
      await _press(tester, 'concept_browse_photo_tap_$_fixture');
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
      await tester.drag(pager, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(0, .01));
      await _press(tester, 'concept_browse_photo_tap_$_fixture');
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(browse().selectedIndex, before.selectedIndex);
      expect(browse().profiles.map((p) => p.id), ids);
      expect(browse().requestLabel!(person), 'Request sent');
      // Photo taps/swipes inspect only; the same invitation action cancels.
      await _press(tester, 'draft_profile_$_fixture');
      expect(browse().selectedIndex, before.selectedIndex);
      expect(browse().requestLabel!(person), 'Request a Journey');
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
      await _openRequests(tester, sent: true);
      expect(_key('concept_request_${_fixture}_header'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Retained Current photo tap cannot affect a changed invitation or route',
    (tester) async {
      await _mount(tester);
      final pager = _key('concept_browse_photo_swipe_$_fixture');
      final tapRect = tester.getRect(
        _key('concept_browse_photo_tap_$_fixture'),
      );
      final local = Offset(tapRect.width * .75, tapRect.height * .5);
      final tapDetails = TapUpDetails(
        kind: ui.PointerDeviceKind.touch,
        globalPosition: tapRect.topLeft + local,
        localPosition: local,
      );
      final stale = tester
          .widget<GestureDetector>(_key('concept_browse_photo_tap_$_fixture'))
          .onTapUp!;
      await _press(tester, 'draft_profile_$_fixture');
      stale(tapDetails);
      await tester.pumpAndSettle();
      expect(_key('draft_confirm_request'), findsNothing);
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(0, .01));
      expect(find.text('Request sent'), findsOneWidget);
      await _press(tester, 'concept_browse_photo_tap_$_fixture');
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
      await _nav(tester, 2);
      stale(tapDetails);
      await tester.pumpAndSettle();
      expect(find.byType(ZyraQuietDashboard), findsOneWidget);
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Current bounded invitation double taps use only current delegates',
    (tester) async {
      await _mount(tester, reduce: false);
      ZyraOneJourneyBrowseDesigns browse() =>
          tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
      final person = browse().profiles.firstWhere(
        (person) => person.id == _fixture,
      );
      final send = _callback(tester, 'draft_profile_$_fixture');
      expect(browse().requestLabel!(person), 'Request a Journey');
      await _press(tester, 'draft_profile_$_fixture');
      send();
      await tester.pumpAndSettle();
      expect(browse().profiles[browse().selectedIndex].id, _fixture);
      expect(browse().requestLabel!(person), 'Request sent');
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(find.byType(ZyraShellNavigation), findsOneWidget);
      expect(_key('draft_confirm_request'), findsNothing);
      final cancel = _callback(tester, 'draft_profile_$_fixture');
      await _press(tester, 'draft_profile_$_fixture');
      cancel();
      send();
      await tester.pumpAndSettle();
      expect(browse().profiles[browse().selectedIndex].id, _fixture);
      expect(browse().requestLabel!(person), 'Request a Journey');
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      await _openRequests(tester, sent: true);
      expect(_key('concept_request_${_fixture}_header'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Browse arrows move exactly one eligible profile per actual tap',
    (tester) async {
      await _mount(tester);
      String currentId() => _currentBrowseDetailsProfile(tester).id;
      expect(currentId(), _fixture);
      for (final id in const [
        'draft-aisha',
        'draft-maryam',
        'draft-hana',
        'draft-noor',
        'draft-zainab',
        'draft-amira',
        _fixture,
      ]) {
        await _press(tester, 'concept_next_profile');
        expect(currentId(), id);
      }
      for (final id in const [
        'draft-amira',
        'draft-zainab',
        'draft-noor',
        'draft-hana',
        'draft-maryam',
        'draft-aisha',
        _fixture,
      ]) {
        await _press(tester, 'concept_previous_profile');
        expect(currentId(), id);
      }
      await _openRequests(tester, sent: true);
      expect(_key('draft_recipient_$_fixture'), findsNothing);
      expect(_key('draft_recipient_draft-aisha'), findsNothing);
    },
  );

  testWidgets(
    'sent invitation stays in Browse after each other eligible profile is seen',
    (tester) async {
      await _mount(tester);
      ZyraOneJourneyBrowseDesigns browse() =>
          tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
      String currentId() => browse().profiles[browse().selectedIndex].id;
      final eligible = browse().profiles.map((profile) => profile.id).toList();
      expect(currentId(), _fixture);
      await _press(tester, 'draft_profile_$_fixture');
      expect(currentId(), _fixture);
      expect(browse().profiles.map((profile) => profile.id), eligible);
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(find.text('Request sent'), findsOneWidget);
      final visited = <String>[];
      for (final id in const [
        'draft-aisha',
        'draft-maryam',
        'draft-hana',
        'draft-noor',
        'draft-zainab',
        'draft-amira',
      ]) {
        await _press(tester, 'concept_next_profile');
        expect(currentId(), id);
        visited.add(currentId());
        expect(currentId(), isNot(_fixture));
        expect(browse().profiles.map((profile) => profile.id), eligible);
      }
      expect(visited.toSet(), eligible.where((id) => id != _fixture).toSet());
      expect(visited.toSet().length, visited.length);
      await _press(tester, 'concept_next_profile');
      expect(currentId(), _fixture);
      expect(find.text('Request sent'), findsOneWidget);
      final returnedIndex = browse().selectedIndex;
      await _press(tester, 'draft_profile_$_fixture');
      expect(currentId(), _fixture);
      expect(browse().selectedIndex, returnedIndex);
      expect(browse().profiles.map((profile) => profile.id), eligible);
      expect(find.text('Request a Journey'), findsOneWidget);
      expect(find.text('Request sent'), findsNothing);
      await _openRequests(tester, sent: true);
      expect(_key('concept_request_${_fixture}_header'), findsNothing);
    },
  );

  testWidgets(
    'Next after Back replays the viewed profile before new profiles',
    (tester) async {
      await _mount(tester);
      String currentId() => _currentBrowseDetailsProfile(tester).id;
      expect(currentId(), _fixture);
      await _press(tester, 'concept_next_profile');
      expect(currentId(), 'draft-aisha');
      await _press(tester, 'concept_previous_profile');
      expect(currentId(), _fixture);
      await _press(tester, 'concept_next_profile');
      expect(currentId(), 'draft-aisha');
      await _press(tester, 'concept_next_profile');
      expect(currentId(), 'draft-maryam');
      expect(find.text('Request a Journey'), findsOneWidget);
      await _openRequests(tester, sent: true);
      expect(_key('concept_request_${_fixture}_header'), findsNothing);
      expect(_key('concept_request_draft-aisha_header'), findsNothing);
      expect(_key('concept_request_draft-maryam_header'), findsNothing);
    },
  );

  testWidgets('fresh Back is disabled and never exposes an unviewed profile', (
    tester,
  ) async {
    await _mount(tester);
    String currentId() => _currentBrowseDetailsProfile(tester).id;
    expect(currentId(), _fixture);
    expect(
      tester.widget<InkWell>(_key('concept_previous_profile')).onTap,
      isNull,
    );
    await _press(tester, 'concept_previous_profile');
    expect(currentId(), _fixture);
    await _press(tester, 'concept_next_profile');
    expect(currentId(), 'draft-aisha');
    expect(find.text('Request a Journey'), findsOneWidget);
    expect(find.text('Request sent'), findsNothing);
    await _openRequests(tester, sent: true);
    expect(_key('concept_request_${_fixture}_header'), findsNothing);
    expect(_key('concept_request_draft-amira_header'), findsNothing);
    expect(_key('concept_request_draft-aisha_header'), findsNothing);
  });

  testWidgets('Back stops at ten visits and Next replays the exact ten', (
    tester,
  ) async {
    await _mount(tester);
    String currentId() => _currentBrowseDetailsProfile(tester).id;
    final visits = <String>[currentId()];
    for (var index = 0; index < 13; index++) {
      await _press(tester, 'concept_next_profile');
      visits.add(currentId());
    }
    final retained = visits.sublist(visits.length - 11);
    for (var index = 9; index >= 0; index--) {
      expect(
        tester.widget<InkWell>(_key('concept_previous_profile')).onTap,
        isNotNull,
      );
      await _press(tester, 'concept_previous_profile');
      expect(currentId(), retained[index]);
    }
    expect(
      tester.widget<InkWell>(_key('concept_previous_profile')).onTap,
      isNull,
    );
    final disabledIcon = tester.widget<Icon>(
      find.descendant(
        of: _key('concept_previous_profile'),
        matching: find.byIcon(Icons.chevron_left),
      ),
    );
    expect(disabledIcon.color, ZyraColors.ink(.34));
    await _press(tester, 'concept_previous_profile');
    expect(currentId(), retained.first);
    for (final id in retained.skip(1)) {
      await _press(tester, 'concept_next_profile');
      expect(currentId(), id);
    }
    await _press(tester, 'concept_next_profile');
    expect(currentId(), isNot(retained.last));
    expect(find.text('Request sent'), findsNothing);
    await _openRequests(tester, sent: true);
    for (final person in visits.toSet()) {
      expect(_key('concept_request_${person}_header'), findsNothing);
    }
  });

  testWidgets('applying and clearing filters retains seen Browse profiles', (
    tester,
  ) async {
    await _mount(tester);
    String currentId() => _currentBrowseDetailsProfile(tester).id;
    await _press(tester, 'concept_next_profile');
    expect(currentId(), 'draft-aisha');
    await _press(tester, 'concept_filters');
    await _chooseBrowseFilter(tester, 'nationality', 'Pakistani (PK)');
    await _press(tester, 'concept_apply_filter');
    expect(currentId(), _fixture);
    await _press(tester, 'concept_filters');
    await _chooseBrowseFilter(tester, 'nationality', 'Any');
    await _press(tester, 'concept_apply_filter');
    expect(currentId(), 'draft-amira');
    await _press(tester, 'concept_next_profile');
    expect(currentId(), 'draft-maryam');
    expect(find.text('Request a Journey'), findsOneWidget);
  });

  testWidgets('local reset clears seen Browse profiles without sending', (
    tester,
  ) async {
    await _mount(tester);
    String currentId() => _currentBrowseDetailsProfile(tester).id;
    await _press(tester, 'concept_next_profile');
    expect(currentId(), 'draft-aisha');
    await _press(tester, 'concept_previous_profile');
    expect(currentId(), _fixture);
    await _press(tester, 'draft_rules');
    await _press(tester, 'draft_reset');
    expect(currentId(), _fixture);
    await _press(tester, 'concept_next_profile');
    expect(currentId(), 'draft-aisha');
    await _openRequests(tester, sent: true);
    expect(_key('concept_request_${_fixture}_header'), findsNothing);
    expect(_key('concept_request_draft-aisha_header'), findsNothing);
  });

  testWidgets(
    'Browse Back retained callback cannot move two profiles in one frame',
    (tester) async {
      await _mount(tester);
      await _press(tester, 'concept_next_profile');
      await _press(tester, 'concept_next_profile');
      final previous = tester.widget<InkWell>(_key('concept_previous_profile'));
      previous.onTap!();
      previous.onTap!();
      await tester.pumpAndSettle();
      expect(_currentBrowseDetailsProfile(tester).id, 'draft-aisha');
      previous.onTap!();
      await tester.pumpAndSettle();
      expect(_currentBrowseDetailsProfile(tester).id, 'draft-aisha');
      await _press(tester, 'concept_previous_profile');
      expect(_currentBrowseDetailsProfile(tester).id, _fixture);
    },
  );

  testWidgets('Browse Back respects one and two profile filtered decks', (
    tester,
  ) async {
    await _mount(tester);
    String currentId() => _currentBrowseDetailsProfile(tester).id;
    await _press(tester, 'concept_filters');
    await _chooseBrowseFilter(tester, 'nationality', 'British (GB)');
    await _press(tester, 'concept_apply_filter');
    expect(currentId(), 'draft-amira');
    await _press(tester, 'concept_previous_profile');
    expect(currentId(), 'draft-amira');
    await _press(tester, 'concept_next_profile');
    expect(currentId(), 'draft-aisha');
    await _press(tester, 'concept_previous_profile');
    expect(currentId(), 'draft-amira');
    await _press(tester, 'concept_previous_profile');
    expect(currentId(), 'draft-amira');
    await _press(tester, 'concept_next_profile');
    expect(currentId(), 'draft-aisha');
    await _press(tester, 'concept_filters');
    await _chooseBrowseFilter(tester, 'nationality', 'Pakistani (PK)');
    await _press(tester, 'concept_apply_filter');
    expect(currentId(), _fixture);
    await _press(tester, 'concept_previous_profile');
    expect(currentId(), _fixture);
    await _press(tester, 'concept_next_profile');
    expect(currentId(), _fixture);
  });

  testWidgets(
    'Connections shows only the current Journey; activity belongs to My ZYRA',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 1);
      final header = tester
          .widgetList<Text>(find.text('Journey'))
          .where((text) => text.style?.fontSize == 26);
      expect(header, hasLength(1));
      expect(find.byType(ZyraSegmentedToggle), findsNothing);
      expect(find.text('Requests'), findsNothing);
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Paused'), findsNothing);
      expect(find.text('Ended'), findsNothing);
      expect(find.text('No Journey yet.'), findsNothing);
      expect(find.text('Awaiting a Journey'), findsNWidgets(3));
      for (var index = 0; index < 3; index++) {
        expect(_key('concept_journey_capacity_slot_$index'), findsOneWidget);
      }
      expect(_key('draft_accept_draft-amira'), findsNothing);
      expect(
        find.byType(ZyraOneJourneyConnectionsPresentation),
        findsOneWidget,
      );
      expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsNothing);
      expect(find.byType(ZyraRequestActivityPresentation), findsNothing);
      expect(find.byType(PageView), findsNothing);
      await _openRequests(tester);
      final received = _selector(tester, _requestLabels);
      _expectRequestTabs(tester, received);
      expect(received.selectedIndex, 0);
      expect(received.segmentKeys, [
        const ValueKey('draft_requests_0'),
        const ValueKey('draft_requests_1'),
        const ValueKey('draft_requests_2'),
      ]);
      expect(_key('draft_requests_2'), findsOneWidget);
      expect(_key('draft_accept_draft-amira'), findsNothing);
      await _press(tester, 'concept_request_draft-amira_header');
      expect(_key('draft_accept_draft-amira'), findsOneWidget);
      await _press(tester, 'draft_requests_1');
      expect(_selector(tester, _requestLabels).selectedIndex, 1);
      await _fillJourney(tester);
      expect(find.byType(ZyraConceptJourneyPresentation), findsOneWidget);
      expect(
        tester
            .widget<PageView>(_key('concept_current_journey_pages'))
            .scrollDirection,
        Axis.vertical,
      );
      expect(find.text('Journey with Sara'), findsOneWidget);
      await _press(tester, 'concept_journey_arrival_continue');
      expect(_key('draft_salam_$_fixture'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared account widgets and My ZYRA keep sample destinations local',
    (tester) async {
      await _mount(tester);
      await _nav(tester, 4);
      expect(find.byType(ZyraOneProfileAvatar), findsOneWidget);
      expect(
        tester.getSize(_key('profile-membership-avatar')),
        const Size(68, 68),
      );
      expect(find.byType(ZyraProfileMembershipRow), findsOneWidget);
      expect(
        tester
            .widget<ZyraProfileMembershipRow>(
              find.byType(ZyraProfileMembershipRow),
            )
            .isOne,
        isTrue,
      );
      await _nav(tester, 2);
      _expectSingleMyZyra(tester);
      await _press(tester, 'my-zyra-route-concept-my-requests');
      expect(find.text('Journey requests'), findsOneWidget);
      expect(_selector(tester, _requestLabels).selectedIndex, 0);
      expect(_key('concept_request_draft-amira_header'), findsOneWidget);
      await _press(tester, 'draft_rules');
      await _press(tester, 'draft_role_guardian');
      await _nav(tester, 0);
      expect(find.byType(ZyraGuardianTabsPresentation), findsOneWidget);
      expect(find.text('Family Review for\nAdam and Sara'), findsOneWidget);
      await _nav(tester, 3);
      expect(find.text('Hassan Rahman'), findsOneWidget);
      expect(find.text('Linked Seekers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Browse is view-only; requests are deliberate, not automatic likes',
    (tester) async {
      await _mount(tester);
      expect(find.byType(FloatingNavBar), findsOneWidget);
      expect(_key('draft_capacity_0'), findsNothing);
      expect(_key('draft_capacity_1'), findsNothing);
      expect(_key('draft_profile_draft-safiya'), findsNothing);
      await _press(tester, 'concept_browse_photo_tap_$_fixture');
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(_key('draft_save'), findsNothing);
      expect(find.text('Save'), findsNothing);
      await _nav(tester, 2);
      _expectSingleMyZyra(tester);
      expect(_key('concept_saved_${_fixture}_header'), findsNothing);
      expect(_key('draft_accept_draft-amira'), findsNothing);
      await _openRequests(tester, sent: true);
      expect(_key('draft_recipient_$_fixture'), findsNothing);
      await _nav(tester, 0);
      await _press(tester, 'draft_profile_$_fixture');
      expect(_key('draft_confirm_request'), findsNothing);
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(find.text('Request sent'), findsOneWidget);
      expect(_action(tester, 'draft_profile_$_fixture'), isNotNull);
      await _press(tester, 'draft_profile_$_fixture');
      expect(find.text('Request a Journey'), findsOneWidget);
      await _openRequests(tester, sent: true);
      expect(_key('draft_recipient_$_fixture'), findsNothing);
    },
  );

  testWidgets(
    'Basic accepted request reserves its place; readiness is mutual and deliberate',
    (tester) async {
      await _mount(tester);
      await _press(tester, 'draft_rules');
      await _press(tester, 'draft_membership_seeker_basic');
      await _nav(tester, 0);
      await _sendRequest(tester);
      await _press(tester, 'draft_recipient_$_fixture');
      expect(_action(tester, 'draft_begin_$_fixture'), isNull);
      await _press(tester, 'draft_ready_$_fixture');
      expect(_action(tester, 'draft_begin_$_fixture'), isNull);
      await _press(tester, 'draft_peer_ready_$_fixture');
      expect(_action(tester, 'draft_begin_$_fixture'), isNotNull);
      await _press(tester, 'draft_begin_$_fixture');
      await _press(tester, 'draft_agree_guardian_access_$_fixture');
      expect(find.textContaining('Salam Exchange'), findsWidgets);
      expect(_key('draft_reveal_$_fixture'), findsNothing);
      await _nav(tester, 0);
      expect(_key('draft_profile_draft-amira'), findsNothing);
      expect(_key('draft_profile_$_fixture'), findsNothing);
      expect(find.text('Your Journey has your focus.'), findsOneWidget);
      expect(
        find.text(
          'You are out of search while your Journey place is reserved or active.',
        ),
        findsOneWidget,
      );
      await _nav(tester, 2);
      expect(find.text('Your Journey with Sara'), findsNothing);
      expect(
        _key('my-zyra-route-concept-current-journey-$_fixture'),
        findsNothing,
      );
      await _nav(tester, 1);
      await _press(tester, 'draft_journey_$_fixture');
      expect(find.text('Journey with Sara'), findsOneWidget);
    },
  );

  testWidgets('received requests follow the same mutual preparation', (
    tester,
  ) async {
    await _mount(tester);
    await _openRequests(tester);
    await _press(tester, 'draft_accept_draft-amira');
    await _press(tester, 'draft_ready_draft-amira');
    expect(_action(tester, 'draft_begin_draft-amira'), isNull);
    await _press(tester, 'draft_peer_ready_draft-amira');
    await _press(tester, 'draft_begin_draft-amira');
    await _press(tester, 'draft_agree_guardian_access_draft-amira');
    expect(find.textContaining('Salam Exchange'), findsWidgets);
  });

  testWidgets('cancellation and decline do not create a Journey', (
    tester,
  ) async {
    await _mount(tester);
    await _sendRequest(tester);
    await _press(tester, 'draft_cancel_$_fixture');
    expect(_key('draft_recipient_$_fixture'), findsNothing);
    expect(find.text('Request cancelled.'), findsNothing);
    await _press(tester, 'draft_requests_0');
    await _press(tester, 'draft_decline_draft-amira');
    expect(_key('draft_accept_draft-amira'), findsNothing);
    expect(find.text('Request declined.'), findsNothing);
    expect(find.byType(ZyraRequestActivityEmpty), findsWidgets);
    await _nav(tester, 0);
    expect(_key('draft_profile_$_fixture'), findsOneWidget);
  });

  testWidgets('Salam comes first and both compatibility choices are required', (
    tester,
  ) async {
    await _mount(tester);
    await _fillJourney(tester);
    expect(find.textContaining('Salam Exchange'), findsWidgets);
    await _press(tester, 'draft_salam_$_fixture');
    expect(_action(tester, 'draft_stage_next_$_fixture'), isNull);
    await _press(tester, 'draft_peer_salam_$_fixture');
    await _press(tester, 'draft_stage_ready_$_fixture');
    expect(_action(tester, 'draft_stage_next_$_fixture'), isNull);
    await _press(tester, 'draft_stage_peer_ready_$_fixture');
    await _press(tester, 'draft_stage_next_$_fixture');
    expect(find.textContaining('Compatibility Reveal'), findsWidgets);
    await _press(tester, 'draft_reveal_$_fixture');
    expect(find.text('You both chose to reveal.'), findsNothing);
    await _press(tester, 'draft_peer_reveal_$_fixture');
    expect(find.text('You both chose to reveal.'), findsOneWidget);
    expect(
      find.textContaining(
        'There is not enough between you yet to work out a figure.',
      ),
      findsOneWidget,
    );
    expect(find.text('—'), findsOneWidget);
    await _press(tester, 'draft_stage_ready_$_fixture');
    await _press(tester, 'draft_stage_peer_ready_$_fixture');
    await _press(tester, 'draft_stage_next_$_fixture');
    await _completeBioStep(tester);
    expect(find.textContaining('Guardian Gate'), findsWidgets);
  });

  testWidgets('Guardian gate and all eight stages remain meaningful', (
    tester,
  ) async {
    await _mount(tester);
    await _fillJourney(tester);
    await _press(tester, 'draft_salam_$_fixture');
    await _press(tester, 'draft_peer_salam_$_fixture');
    await _advanceStage(tester);
    await _press(tester, 'draft_reveal_$_fixture');
    await _press(tester, 'draft_peer_reveal_$_fixture');
    await _advanceStage(tester);
    await _completeBioStep(tester);
    await _press(tester, 'concept_stage_guardians');
    await _confirmGuardianMain(tester, remove: true);
    await _nav(tester, 1);
    await _press(tester, 'draft_journey_$_fixture');
    await _press(tester, 'draft_stage_ready_$_fixture');
    await _press(tester, 'draft_stage_peer_ready_$_fixture');
    expect(_action(tester, 'draft_stage_next_$_fixture'), isNull);
    await _press(tester, 'concept_missing_main');
    await _confirmGuardianMain(tester, remove: false);
    await _nav(tester, 1);
    await _press(tester, 'draft_journey_$_fixture');
    await _advanceStage(tester);
    for (final stage in ZyraJourneyStages.all.skip(3)) {
      expect(find.textContaining(stage.label), findsWidgets);
      if (stage.value != 'conversation') {
        expect(_key('concept_message'), findsNothing);
        await _advanceStage(tester);
      }
    }
    expect(_key('draft_stage_next_$_fixture'), findsNothing);
    await _press(tester, 'concept_journey_arrival_continue');
    await tester.ensureVisible(_key('concept_message'));
    await tester.enterText(_key('concept_message'), 'A local sample greeting');
    await _press(tester, 'concept_send_message');
    expect(find.textContaining('A local sample greeting'), findsOneWidget);
    await tester.enterText(
      _key('concept_message'),
      'Must not send after ending',
    );
    final staleSend = _callback(tester, 'concept_send_message');
    expect(_key('draft_pause_$_fixture'), findsNothing);
    await _press(tester, 'draft_end_$_fixture');
    await _press(tester, 'draft_confirm_end_$_fixture');
    staleSend();
    await tester.pumpAndSettle();
    expect(find.text('You · Must not send after ending'), findsNothing);
    expect(_key('concept_send_message'), findsNothing);
    staleSend();
    await tester.pumpAndSettle();
    expect(_key('concept_message'), findsNothing);
    expect(_key('concept_archive_$_fixture'), findsOneWidget);
    expect(find.text('You · A local sample greeting'), findsOneWidget);
    expect(_key('concept_journey_menu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preview exposes no Pause; End stays deliberate, retains history and reset is draft-only',
    (tester) async {
      await _mount(tester);
      await _fillJourney(tester);
      await _press(tester, 'concept_journey_arrival_continue');
      expect(_key('draft_pause_$_fixture'), findsNothing);
      expect(_key('draft_agree_pause_$_fixture'), findsNothing);
      expect(_key('draft_resume_$_fixture'), findsNothing);
      await _press(tester, 'concept_journey_menu');
      expect(_key('draft_options_pause_$_fixture'), findsNothing);
      expect(find.text('Request Pause'), findsNothing);
      await _captureCandidate(
        tester,
        'simplified_journey_options_no_pause_standard',
      );
      if (find.byType(ZyraConceptJourneyOptions).evaluate().isNotEmpty) {
        await _cancelJourneyOptions(tester);
      }
      await _press(tester, 'draft_end_$_fixture');
      await _press(tester, 'draft_cancel_end_$_fixture');
      await _press(tester, 'concept_journey_arrival_continue');
      expect(_key('draft_pause_$_fixture'), findsNothing);
      expect(_key('draft_end_$_fixture'), findsOneWidget);
      await _press(tester, 'draft_end_$_fixture');
      await _press(tester, 'draft_confirm_end_$_fixture');
      expect(_key('draft_resume_$_fixture'), findsNothing);
      await _nav(tester, 0);
      expect(_key('draft_profile_$_fixture'), findsOneWidget);
      expect(_action(tester, 'draft_profile_$_fixture'), isNull);
      expect(find.text('Journey archived'), findsOneWidget);
      await _nav(tester, 1);
      expect(_key('draft_journey_${_fixture}_header'), findsNothing);
      await _openEnded(tester);
      expect(_key('draft_journey_${_fixture}_header'), findsOneWidget);
      await _press(tester, 'draft_rules');
      await _press(tester, 'draft_reset');
      await _nav(tester, 0);
      expect(_key('draft_profile_$_fixture'), findsOneWidget);
    },
  );

  testWidgets(
    'whole-app preview performs no HTTP or real member/preference changes',
    (tester) async {
      final noNetwork = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        expect(() => Supabase.instance, throwsA(isA<AssertionError>()));
        SharedPreferences.setMockInitialValues({
          'zyra.cached_account_owner': 'synthetic-member-owner',
          'zyra.cached_first_name': 'Ordinary member',
          'zyra.cached_role': 'seeker',
          'zyra.app_gold_enabled': true,
          'zyra.haptic_level': 'medium',
          'sentinel.untouched': 'ordinary-setting',
        });
        await tester.runAsync(() async {
          await ZyraLocalPrefs.init();
          await ZyraLocalPrefs.bindAccount('synthetic-member-owner');
        });
        final prefs = await SharedPreferences.getInstance();
        Map<String, Object?> snapshot() => {
          for (final key in prefs.getKeys()) key: prefs.get(key),
        };
        final beforePreferences = snapshot();
        final app = AppState.instance;
        app
          ..name = 'Ordinary member'
          ..surnameLine = 'Private account'
          ..photos = ['unchanged-photo-reference']
          ..plan = ZyraPlan.one;
        app.saved.add(
          const SeekerProfile(
            id: 'ordinary-saved-fixture',
            firstName: 'Unchanged',
            age: 31,
            city: 'London',
            photos: [],
            gender: 'female',
          ),
        );
        final generation = ZyraAccountState.generation;
        final userId = ZyraAccountState.userId;
        final realSaved = List.of(app.saved);
        final realPotential = List.of(app.potentialJourneys);
        final realActive = List.of(app.activeJourneys);
        final palette = ZyraColors.devPalette;
        final gold = ZyraAppGoldStyle.instance.enabled;
        final haptic = ZyraInteractionStyle.hapticLevel;
        final font = ZyraText.appFont;
        var memberNotifications = 0;
        void changed() => memberNotifications++;
        app.addListener(changed);
        addTearDown(() => app.removeListener(changed));
        await _mount(tester);
        await _press(tester, 'concept_browse_photo_tap_$_fixture');
        expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
        expect(_key('draft_save'), findsNothing);
        await _press(tester, 'draft_profile_$_fixture');
        expect(_key('draft_confirm_request'), findsNothing);
        expect(find.text('Request sent'), findsOneWidget);
        for (final index in [1, 2, 3, 4]) {
          await _nav(tester, index);
          expect(find.byType(FloatingNavBar), findsOneWidget);
        }
        await _press(tester, 'concept_settings');
        expect(find.text('Settings'), findsWidgets);
        await _press(tester, 'concept_settings_notificationSettings');
        expect(find.text('Notifications & emails'), findsWidgets);
        await _nav(tester, 4);
        await _press(tester, 'concept_personalisation');
        expect(find.textContaining('Personalisation'), findsWidgets);
        await _press(tester, 'personalisation_gold_toggle');
        await _nav(tester, 4);
        await _press(tester, 'concept_membership');
        expect(find.text('Membership'), findsWidgets);
        expect(_key('membership-section-seeker'), findsOneWidget);
        await _press(tester, 'membership-section-seeker');
        expect(find.text('Up to 3 active Journeys'), findsOneWidget);
        await _press(tester, 'membership-next');
        expect(find.text('1 active Journey'), findsOneWidget);
        expect(_key('membership-select-seekerBasic'), findsOneWidget);
        expect(find.textContaining('Saved profiles'), findsNothing);
        expect(find.textContaining('Paused Journey'), findsNothing);
        expect(find.textContaining('Insights and initiating'), findsNothing);
        expect(find.textContaining('profile swipes'), findsNothing);
        await _captureCandidate(
          tester,
          'simplified_membership_features_standard',
        );
        await _press(tester, 'draft_rules');
        await _press(tester, 'draft_role_guardian');
        for (final index in [0, 1, 2, 3]) {
          await _nav(tester, index);
          expect(find.byType(ZyraShellNavigation), findsOneWidget);
        }
        await _press(tester, 'concept_personalisation');
        await _press(tester, 'personalisation_gold_toggle');
        await tester.runAsync(
          () => ZyraLocalPrefs.bindAccount('synthetic-member-owner'),
        );
        expect(snapshot(), beforePreferences);
        expect(app.name, 'Ordinary member');
        expect(app.surnameLine, 'Private account');
        expect(app.photos, ['unchanged-photo-reference']);
        expect(app.plan, ZyraPlan.one);
        expect(app.saved, realSaved);
        expect(app.potentialJourneys, realPotential);
        expect(app.activeJourneys, realActive);
        expect(ZyraAccountState.generation, generation);
        expect(ZyraAccountState.userId, userId);
        expect(ZyraColors.devPalette, palette);
        expect(ZyraAppGoldStyle.instance.enabled, gold);
        expect(ZyraInteractionStyle.hapticLevel, haptic);
        expect(ZyraText.appFont, font);
        expect(memberNotifications, 0);
        expect(() => Supabase.instance, throwsA(isA<AssertionError>()));
      }, noNetwork);
      expect(noNetwork.attempts, 0);
    },
  );

  testWidgets(
    'Guardian plus reuses the Code page while Guardian-role invitations stay held and Circle stays working',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        // Match the protected host's offline latch only for this integration.
        // Its absence must keep the explicit local Code route denied.
        addTearDown(ZyraInternalPreviewClient.finishSignOut);
        ZyraInternalPreviewClient.beginPreview();
        await _mount(tester);
        await _tapRootNav(tester, 'Guardian');
        await _press(tester, 'guardian-add-top');
        expect(find.byType(LinkGuardianScreen), findsOneWidget);
        expect(find.byType(ZyraCodeScreen), findsOneWidget);
        final code = tester.widget<ZyraCodeScreen>(find.byType(ZyraCodeScreen));
        expect(code.asGuardian, isFalse);
        expect(code.signupPreview, isFalse);
        expect(code.localPreview, isNotNull);
        expect(find.text('Add a Guardian'), findsOneWidget);
        expect(find.text('Scan code'), findsOneWidget);
        expect(find.text('Enter code'), findsOneWidget);
        expect(_key('concept_held_action'), findsNothing);
        expect(_key('signup_code_preview'), findsNothing);
        expect(find.text('PREVIEW ONLY'), findsNothing);
        await returnZyraPreviewPage(tester);
        expect(find.byType(LinkGuardianScreen), findsNothing);
        expect(find.byType(SeekerGuardianPage), findsOneWidget);
        for (final route in const [
          (key: 'guardian-family-messages-top', title: 'Guardian Circle'),
        ]) {
          await _press(tester, route.key);
          final circle = route.key == 'guardian-family-messages-top';
          final title = route.title;
          expect(
            _key('concept_held_action'),
            circle ? findsNothing : findsOneWidget,
          );
          expect(find.text(title), findsOneWidget);
          expect(
            find.byType(ZyraGuardianCircleScreen),
            circle ? findsOneWidget : findsNothing,
          );
          expect(find.text('PREVIEW ONLY'), findsNothing);
          expect(_key('draft_fill'), findsNothing);
          expect(_key('concept_held_back'), findsNothing);
          await _returnPage(tester, from: find.text(title));
          expect(_key('concept_held_action'), findsNothing);
          expect(find.byType(SeekerGuardianPage), findsOneWidget);
        }
        await _press(tester, 'draft_rules');
        await _press(tester, 'draft_role_guardian');
        await _tapRootNav(tester, 'Seekers');
        for (final route in const [
          (key: 'guardian_invite', title: 'Invite your Seeker'),
          (key: 'guardian_circle', title: 'Guardian Circle'),
        ]) {
          if (route.key == 'guardian_circle') {
            await _press(tester, 'guardian_seeker_0');
          }
          await _press(tester, route.key);
          final circle = route.key == 'guardian_circle';
          final title = route.title;
          expect(
            _key('concept_held_action'),
            circle ? findsNothing : findsOneWidget,
          );
          expect(find.text(title), findsOneWidget);
          expect(
            find.byType(ZyraGuardianCircleScreen),
            circle ? findsOneWidget : findsNothing,
          );
          expect(find.text('PREVIEW ONLY'), findsNothing);
          expect(_key('draft_fill'), findsNothing);
          expect(_key('concept_held_back'), findsNothing);
          await _returnPage(tester, from: find.text(title));
          expect(_key('concept_held_action'), findsNothing);
          expect(find.byType(ZyraGuardianTabsPresentation), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets(
    'own Profile Preview has visible and accessible Back; Ended archive lives only in My ZYRA',
    (tester) async {
      final network = _NoNetwork();
      final semantics = tester.ensureSemantics();
      try {
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester);
          await _tapRootNav(tester, 'Profile');
          await _press(tester, 'concept_preview_profile');
          expect(_key('concept_own_profile_preview_back'), findsNothing);
          expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
          expect(_key('concept_pull_down_back_scope'), findsOneWidget);
          final backSemantics = _returnSemantics();
          expect(
            tester
                .getSemantics(backSemantics)
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.dismiss),
            isTrue,
          );
          expect(
            tester
                .widget<Semantics>(backSemantics)
                .properties
                .customSemanticsActions!
                .keys
                .map((action) => action.label),
            contains('Back'),
          );
          final preview = tester.widget<ZyraBrowseDesigns>(
            find.byType(ZyraBrowseDesigns),
          );
          final own = preview.profiles.single;
          expect(own.id, 'draft-self');
          final details = _key('concept_browse_details_${own.id}');
          expect(details, findsOneWidget);
          expect(
            find.descendant(of: details, matching: find.text(own.firstName)),
            findsOneWidget,
          );
          if (own.surnameLine?.trim().isNotEmpty ?? false) {
            expect(
              find.descendant(
                of: details,
                matching: find.text(own.surnameLine!.trim()),
              ),
              findsOneWidget,
            );
          }
          // LOCK 4 also uses the first admitted photo on the own-profile
          // details card, inside the existing compact gold ring.
          final avatar = _key('concept_browse_details_avatar_${own.id}');
          final photo = _key('concept_browse_details_avatar_photo_${own.id}');
          expect(own.photos, isNotEmpty);
          expect(avatar, findsOneWidget);
          expect(photo, findsOneWidget);
          expect(tester.getSize(avatar), const Size(56, 56));
          expect(tester.getSize(photo), const Size(50, 50));
          final detailsImages = find.descendant(
            of: details,
            matching: find.byType(Image),
          );
          expect(detailsImages, findsOneWidget);
          final image = tester.widget<Image>(detailsImages);
          expect(image.image, isA<MemoryImage>());
          expect(
            (image.image as MemoryImage).bytes,
            base64Decode(own.photos.first.split(',').last),
          );
          expect(image.fit, BoxFit.cover);
          expect(image.alignment, Alignment.center);
          expect(
            tester
                .widget<PageView>(_key('concept_browse_photo_swipe_${own.id}'))
                .controller!
                .page,
            closeTo(0, .01),
          );
          expect(_key('draft_request'), findsNothing);
          expect(_key('draft_fill'), findsNothing);
          await _returnPage(tester);
          expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
          await _fillJourney(tester);
          expect(_key('draft_pause_$_fixture'), findsNothing);
          await _press(tester, 'draft_end_$_fixture');
          await _press(tester, 'draft_confirm_end_$_fixture');
          await returnZyraPreviewPage(tester);
          await _tapRootNav(tester, 'Profile');
          expect(_key('concept_past_journeys'), findsNothing);
          expect(find.text('Past Journeys'), findsNothing);
          await _openEnded(tester);
          expect(_key('concept_activity_ended'), findsOneWidget);
          expect(find.text('Ended Journeys'), findsOneWidget);
          expect(find.text('Paused'), findsNothing);
          expect(_key('draft_journey_${_fixture}_header'), findsOneWidget);
          expect(_key('draft_fill'), findsNothing);
          await _press(tester, 'draft_journey_options_$_fixture');
          expect(_key('draft_options_archive_$_fixture'), findsNothing);
          expect(find.text('View archive'), findsNothing);
          await _press(tester, 'draft_options_timeline_$_fixture');
          expect(find.text('Journey with Sara'), findsOneWidget);
          expect(_key('draft_end_$_fixture'), findsNothing);
          expect(_key('draft_pause_$_fixture'), findsNothing);
          expect(_key('draft_resume_$_fixture'), findsNothing);
          expect(_key('concept_message'), findsNothing);
          final history = tester.widget<ZyraDraftTimelinePresentation>(
            find.byType(ZyraDraftTimelinePresentation),
          );
          expect(history.subjectId, _fixture);
          expect(history.view.frozen, isTrue);
          expect(history.onPropose, isNull);
          expect(history.onConfirm, isNull);
          expect(history.onNotYet, isNull);
          expect(
            history.view.entries.map((entry) => entry.type),
            containsAll(['match_created', 'journey_started', 'journey_ended']),
          );
          await returnZyraPreviewPage(tester);
          expect(_key('concept_activity_ended'), findsOneWidget);
          expect(_key('draft_journey_${_fixture}_header'), findsOneWidget);
          expect(find.text('No paused Journeys.'), findsNothing);
          expect(find.text('No ended Journeys.'), findsNothing);
          expect(tester.takeException(), isNull);
        }, network);
      } finally {
        semantics.dispose();
      }
      expect(network.attempts, 0);
    },
  );

  testWidgets('Guardian role has no Seeker request or acceptance actions', (
    tester,
  ) async {
    await _mount(tester);
    await _press(tester, 'draft_rules');
    await _press(tester, 'draft_role_guardian');
    await _nav(tester, 0);
    expect(_key('draft_request'), findsNothing);
    expect(_key('draft_profile_$_fixture'), findsNothing);
    await _nav(tester, 1);
    expect(_key('draft_accept_draft-amira'), findsNothing);
    await _nav(tester, 3);
    expect(find.textContaining('Guardian'), findsWidgets);
    await _press(tester, 'draft_rules');
    await _press(tester, 'draft_role_seeker');
    await _nav(tester, 0);
    expect(_key('draft_profile_$_fixture'), findsOneWidget);
  });

  testWidgets(
    'removing the actual Main Guardian revokes all local linked context and stale loaders',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _fillJourney(tester);
        await _nav(tester, 3);
        final before = tester.widget<SeekerGuardianPage>(
          find.byType(SeekerGuardianPage),
        );
        final oldJourneyAccess = before.journeyAccessLoader!;
        final oldHistoryConsent = before.historyConsentLoader!;
        await _press(tester, 'guardian-remove');
        final confirmation = find.descendant(
          of: _key('guardian-remove-confirmation'),
          matching: find.text('Confirm'),
        );
        expect(confirmation.hitTestable(), findsOneWidget);
        await tester.tap(confirmation);
        await tester.pumpAndSettle();
        final people = tester
            .widget<SeekerGuardianPage>(find.byType(SeekerGuardianPage))
            .people;
        expect(
          people.any((person) => person.id == 'draft-guardian-hassan'),
          isFalse,
        );
        final staleJourney = await oldJourneyAccess(
          guardianId: 'draft-guardian-hassan',
          attemptId: 'draft-attempt-$_fixture',
          enabled: false,
        );
        final staleHistory = await oldHistoryConsent(
          guardianId: 'draft-guardian-hassan',
          guardianIsMain: true,
          enabled: true,
        );
        expect(staleJourney.isUnavailable, isTrue);
        expect(staleHistory.isUnavailable, isTrue);
        await _nav(tester, 4);
        await _press(tester, 'draft_role_guardian');
        await _nav(tester, 3);
        final account = tester.widget<ZyraGuardianTabsPresentation>(
          find.byType(ZyraGuardianTabsPresentation),
        );
        expect(account.linked, isFalse);
        for (final index in [0, 1, 2]) {
          await _nav(tester, index);
          expect(find.byType(GuardianDashboardProfileCard), findsNothing);
          expect(find.byType(ZyraProfileImage), findsNothing);
          expect(find.text('Adam'), findsNothing);
        }
        final roster = tester.widget<ZyraGuardianTabsPresentation>(
          find.byType(ZyraGuardianTabsPresentation),
        );
        expect(roster.linked, isFalse);
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets('Guardian Seekers gold uses only the local shell canvas', (
    tester,
  ) async {
    final memberGold = ZyraAppGoldStyle.instance.enabled;
    await _mount(tester);
    await _nav(tester, 4);
    await _press(tester, 'concept_personalisation');
    final before = tester
        .widget<Switch>(_key('personalisation_gold_toggle'))
        .value;
    await _press(tester, 'personalisation_gold_toggle');
    await _nav(tester, 4);
    await _press(tester, 'draft_role_guardian');
    await _nav(tester, 2);
    final roster = tester.widget<ZyraGuardianTabsPresentation>(
      find.byType(ZyraGuardianTabsPresentation),
    );
    expect(roster.page, 'seekers');
    final localPaint = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where(
          (paint) =>
              paint.painter.runtimeType.toString() ==
              'ZyraOnboardingGoldPainter',
        );
    expect(localPaint.length, before ? 0 : 1);
    expect(ZyraAppGoldStyle.instance.enabled, memberGold);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guardian permission choices stay linked and chat needs view', (
    tester,
  ) async {
    await _mount(tester);
    await _fillJourney(tester);
    await _nav(tester, 3);
    await _openAdditionalGuardian(tester);
    expect(_permissionCircle(tester, _guardianChat).properties.toggled, isTrue);
    await _press(tester, _guardianView);
    final chat = _permissionCircle(tester, _guardianChat).properties;
    expect(chat.toggled, isFalse);
    expect(chat.enabled, isFalse);
    expect(chat.onTap, isNull);
    await _press(tester, _guardianHistory);
    expect(tester.widget<Switch>(_key(_guardianHistory)).value, isTrue);
    await _press(tester, _guardianView);
    expect(
      _permissionCircle(tester, _guardianChat).properties.toggled,
      isFalse,
    );
    await _press(tester, _guardianChat);
    expect(_permissionCircle(tester, _guardianChat).properties.toggled, isTrue);
  });

  for (final change in ['navigation', 'stage progress', 'end']) {
    testWidgets('stale Guardian grants refuse after $change', (tester) async {
      await _mount(tester);
      await _fillJourney(tester);
      await _nav(tester, 3);
      await _openAdditionalGuardian(tester);
      await _press(tester, 'guardian-history-consent-details-toggle');
      // This now-working information sheet is a real covering route, not
      // an inline expansion. Dismiss it before retaining current page grants.
      expect(_key('guardian-history-consent-explanation'), findsOneWidget);
      await tester.tapAt(const Offset(10, 70));
      await tester.pumpAndSettle();
      expect(_key('guardian-history-consent-explanation'), findsNothing);
      expect(
        _permissionCircle(tester, _guardianView).properties.toggled,
        isTrue,
      );
      expect(
        _permissionCircle(tester, _guardianChat).properties.toggled,
        isTrue,
      );
      final view = _permissionCircle(tester, _guardianView).properties.onTap!;
      final chat = _permissionCircle(tester, _guardianChat).properties.onTap!;
      final history = tester.widget<Switch>(_key(_guardianHistory)).onChanged!;
      await _nav(tester, 1);
      await _press(tester, 'draft_journey_$_fixture');
      if (change == 'stage progress') {
        await _press(tester, 'draft_salam_$_fixture');
        await _press(tester, 'draft_peer_salam_$_fixture');
        await _advanceStage(tester);
      } else if (change == 'end') {
        await _press(tester, 'draft_end_$_fixture');
        await _press(tester, 'draft_confirm_end_$_fixture');
      }
      view();
      chat();
      history(true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (change == 'end') {
        await _press(tester, 'draft_rules');
        await _press(tester, 'draft_reset');
        await _fillJourney(tester);
      }
      await _nav(tester, 3);
      // The actual production Guardian pager is restored on section entry.
      await _openAdditionalGuardian(tester);
      await _press(tester, 'guardian-history-consent-details-toggle');
      expect(_key('guardian-history-consent-explanation'), findsOneWidget);
      await tester.tapAt(const Offset(10, 70));
      await tester.pumpAndSettle();
      expect(_key('guardian-history-consent-explanation'), findsNothing);
      expect(
        _permissionCircle(tester, _guardianView).properties.toggled,
        isTrue,
      );
      expect(
        _permissionCircle(tester, _guardianChat).properties.toggled,
        isTrue,
      );
      expect(tester.widget<Switch>(_key(_guardianHistory)).value, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 1.4, 2.0]) {
    testWidgets('compact 320×568 at scale $scale stays scroll reachable', (
      tester,
    ) async {
      await _mount(
        tester,
        scale: scale,
        reduce: true,
        size: const Size(320, 568),
      );
      await _sendRequest(tester);
      await _press(tester, 'draft_recipient_$_fixture');
      await _press(tester, 'draft_ready_$_fixture');
      await _press(tester, 'draft_peer_ready_$_fixture');
      await _press(tester, 'draft_begin_$_fixture');
      await _press(tester, 'draft_agree_guardian_access_$_fixture');
      await _press(tester, 'draft_end_$_fixture');
      await _press(tester, 'draft_confirm_end_$_fixture');
      for (final index in [0, 2, 3, 4]) {
        await _nav(tester, index);
      }
      await _press(tester, 'concept_personalisation');
      final gold = _key('personalisation_gold_toggle');
      await tester.scrollUntilVisible(
        gold,
        180,
        scrollable: find
            .descendant(
              of: _key('personalisation-scroll'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(_key('personalisation_gold_toggle'), findsOneWidget);
      final failure = tester.takeException();
      if (failure != null) {
        for (final element in find.byType(Row).evaluate()) {
          final row = element.renderObject;
          if (row is! RenderFlex || !row.hasSize) continue;
          var width = 0.0;
          row.visitChildren((child) {
            if (child is RenderBox && child.hasSize) width += child.size.width;
          });
          if (width > row.size.width + .1) {
            final copy = find
                .descendant(
                  of: find.byWidget(element.widget),
                  matching: find.byType(Text),
                )
                .evaluate()
                .map(
                  (child) =>
                      (child.widget as Text).data ??
                      (child.widget as Text).textSpan?.toPlainText(),
                )
                .toList();
            debugPrint(
              'Measured Personalisation overflowing Row: ${row.debugCreator}; size=${row.size}; child widths=$width; copy=$copy',
            );
          }
        }
      }
      expect(failure, isNull);
    });
  }

  testWidgets('actions expose labelled current-app targets and tokens', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(tester);
      await tester.ensureVisible(_key('draft_profile_$_fixture'));
      await tester.pumpAndSettle();
      final request = tester.widget<InkWell>(_key('draft_profile_$_fixture'));
      expect(request.onTap, isNotNull);
      expect(
        tester.getSize(_key('draft_profile_$_fixture')).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(_key('draft_profile_$_fixture')).label,
        contains('Request a Journey'),
      );
      await _openRequests(tester);
      await _press(tester, 'concept_request_draft-amira_header');
      await tester.ensureVisible(_key('draft_accept_draft-amira'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(_key('draft_accept_draft-amira')).height,
        greaterThanOrEqualTo(30),
      );
      expect(
        tester.getSemantics(_key('draft_accept_draft-amira')).label,
        contains('Accept'),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('compact 200% Browse identity clears neutral controls', (
    tester,
  ) async {
    final noNetwork = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      await _mount(tester, scale: 2, size: const Size(320, 568));
      final identity = _key('concept_browse_details_$_fixture');
      expect(identity, findsOneWidget);
      final identityViewport = tester.getRect(identity);
      final arrows = [
        tester.getRect(_key('concept_previous_profile')),
        tester.getRect(_key('concept_next_profile')),
      ];
      for (final textFinder
          in find
              .descendant(of: identity, matching: find.byType(Text))
              .evaluate()
              .map((element) => find.byWidget(element.widget))) {
        final paragraph = tester.renderObject<RenderParagraph>(textFinder);
        final text = tester.widget<Text>(textFinder).data!;
        final origin = paragraph.localToGlobal(Offset.zero);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
        for (final box in boxes) {
          final bounds = box.toRect().shift(origin).intersect(identityViewport);
          for (final arrow in arrows) {
            expect(
              bounds.overlaps(arrow),
              isFalse,
              reason:
                  'Browse text "$text" $bounds intersects a neutral control $arrow.',
            );
          }
        }
      }
      _currentBrowseDetailsProfile(tester);
      final initial = find.descendant(
        of: identity,
        matching: find.text('Sara'),
      );
      expect(initial, findsOneWidget);
      // Current remains a bounded portrait. At 200% text, vertical reading
      // reveals the full details identity without an enlarged viewer.
      await tester.ensureVisible(initial);
      await tester.pumpAndSettle();
      final footer = Offset.zero & tester.view.physicalSize;
      final initialParagraph = tester.renderObject<RenderParagraph>(initial);
      final origin = initialParagraph.localToGlobal(Offset.zero);
      for (final box in initialParagraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 4),
      )) {
        final bounds = box.toRect().shift(origin);
        expect(
          bounds.top,
          greaterThanOrEqualTo(footer.top),
          reason: 'The 200% detail name $bounds must fit the footer $footer.',
        );
        expect(bounds.bottom, lessThanOrEqualTo(footer.bottom));
      }
      await _captureCandidate(tester, 'browse_compact200');
      await _press(tester, 'concept_browse_photo_tap_$_fixture');
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      await _captureCandidate(tester, 'browse_photo_2_compact200');
      expect(find.byType(ZyraProfileNameBlock), findsNothing);
      expect(_key('concept_browse_identity_$_fixture'), findsNothing);
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      final person = browse.profiles[browse.selectedIndex];
      _expectBrowsePhoto(tester, person, 0);
      final photoPager = _key('concept_browse_photo_swipe_$_fixture');
      final cleanPhoto = tester.getRect(
        _key('concept_browse_photo_${_fixture}_0'),
      );
      expect(cleanPhoto, tester.getRect(photoPager));
      expect(cleanPhoto, tester.getRect(_key('concept_browse_portrait_card')));
      for (final arrow in [
        tester.getRect(_key('concept_previous_profile')),
        tester.getRect(_key('concept_next_profile')),
      ]) {
        expect(cleanPhoto.overlaps(arrow), isFalse);
      }
      expect(tester.takeException(), isNull);
    }, noNetwork);
    expect(noNetwork.attempts, 0);
  });

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, suffix: '_standard_final'),
    (size: Size(320, 568), scale: 1.4, suffix: '_compact140_final'),
    (size: Size(320, 568), scale: 2.0, suffix: '_compact200_final'),
  ]) {
    testWidgets(
      'fresh whole-app real-font candidates are not approval${viewport.suffix}',
      (tester) async {
        final noNetwork = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          Future<void> capture(String name) =>
              _captureCandidate(tester, '$name${viewport.suffix}');
          await _mount(tester, size: viewport.size, scale: viewport.scale);
          await capture('browse');
          await _press(tester, 'concept_browse_photo_tap_$_fixture');
          expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
          await capture('browse_photo_2');
          await _press(tester, 'draft_profile_$_fixture');
          expect(_key('draft_confirm_request'), findsNothing);
          expect(find.text('Request sent'), findsOneWidget);
          await _nav(tester, 1);
          await capture('connections');
          await _openRequests(tester, sent: true);
          await capture('my_zyra_sent_requests');
          await _press(tester, 'draft_recipient_$_fixture');
          await capture('mutual_preparation');
          await _press(tester, 'draft_ready_$_fixture');
          await _press(tester, 'draft_peer_ready_$_fixture');
          await _press(tester, 'draft_begin_$_fixture');
          await _press(tester, 'draft_agree_guardian_access_$_fixture');
          await _nav(tester, 1);
          await capture('connections_current_journey');
          await _press(tester, 'draft_journey_$_fixture');
          await capture('journey_salam');
          await _nav(tester, 0);
          await capture('focused_browse');
          await _nav(tester, 2);
          _expectSingleMyZyra(tester);
          await capture('my_zyra');
          await _openEnded(tester);
          await capture('my_zyra_ended');
          await _nav(tester, 3);
          await capture('guardians');
          await _openAdditionalGuardian(tester);
          await capture('guardian_detail');
          await _nav(tester, 4);
          await capture('profile');
          await _press(tester, 'concept_settings');
          await capture('settings');
          await _nav(tester, 4);
          await _press(tester, 'concept_personalisation');
          await capture('personalisation');
          await _nav(tester, 4);
          await _press(tester, 'concept_membership');
          await capture('membership');
          await _press(tester, 'draft_rules');
          await _press(tester, 'draft_role_guardian');
          await capture('guardian_account');
          await _nav(tester, 1);
          await capture('guardian_network');
          await _nav(tester, 2);
          await capture('guardian_linked_seekers');
        }, noNetwork);
        expect(noNetwork.attempts, 0);
      },
    );
  }
}
