import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/data/zyra_release_gates.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/connections/connections_screen.dart';
import 'package:zyra/screens/journey/journey_flow_screen.dart';
import 'package:zyra/services/zyra_guardian_suggestion_service.dart';
import 'package:zyra/services/zyra_journey_service.dart';
import 'package:zyra/services/zyra_unlock_service.dart';

void main() {
  setUp(() {
    ZyraDevScenario.instance.reset();
    ZyraUnlockService.clearForSignOut();
  });

  Future<void> pumpJourneyCard(
    WidgetTester tester,
    ZyraConnectionsJourneyCardTestState state, {
    double width = 330,
    double textScale = 1,
    bool expand = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              textScaler: TextScaler.linear(textScale),
            ),
            child: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: width,
                  child: buildZyraConnectionsJourneyCardTestSurface(state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (expand) {
      await tester.tap(find.text('Maryam, 27'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> pumpActivityCard(
    WidgetTester tester,
    ZyraConnectionsActivityCardTestState state, {
    double width = 330,
    double textScale = 1,
    bool expand = false,
    bool localTestProfile = false,
    bool movedIntroduction = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              textScaler: TextScaler.linear(textScale),
            ),
            child: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: width,
                  child: buildZyraConnectionsActivityCardTestSurface(
                    state,
                    localTestProfile: localTestProfile,
                    movedIntroduction: movedIntroduction,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (expand) {
      await tester.tap(find.text('Maryam, 27'));
      await tester.pumpAndSettle();
    }
  }

  void expectJourneyReferenceMatchesProfilePill(
    WidgetTester tester,
    Finder references,
    String label,
    IconData icon,
  ) {
    final action = find.descendant(
      of: references,
      matching: find.byKey(ValueKey<String>('connections-action-$label')),
    );
    expect(action, findsOneWidget);

    final profile = find.byKey(
      const ValueKey('connections-action-View Profile'),
    );
    expect(profile, findsOneWidget);
    expect(
      tester.widget<Material>(action).color,
      tester.widget<Material>(profile).color,
    );

    final ink = find.descendant(of: action, matching: find.byType(Ink));
    final profileInk = find.descendant(of: profile, matching: find.byType(Ink));
    expect(ink, findsOneWidget);
    expect(profileInk, findsOneWidget);
    final decoration = tester.widget<Ink>(ink).decoration! as BoxDecoration;
    final profileDecoration =
        tester.widget<Ink>(profileInk).decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.borderRadius, profileDecoration.borderRadius);
    expect(
      find.descendant(of: action, matching: find.byIcon(icon)),
      findsOneWidget,
    );

    final tapTarget = find.descendant(
      of: action,
      matching: find.byType(InkWell),
    );
    expect(tapTarget, findsOneWidget);
    expect(tester.widget<InkWell>(tapTarget).onTap, isNotNull);
  }

  testWidgets(
    'Potential Paused and Ended hide Report until their card is expanded',
    (tester) async {
      const reportKey = ValueKey(
        'connections-report-connections-card-test-profile',
      );

      for (final state in ZyraConnectionsJourneyCardTestState.values) {
        await pumpJourneyCard(tester, state, expand: false);

        expect(
          find.byKey(reportKey),
          findsNothing,
          reason: '${state.name} must stay visually quiet while collapsed',
        );

        await tester.tap(find.text('Maryam, 27'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(reportKey),
          findsOneWidget,
          reason: '${state.name} exposes the safety action after expansion',
        );

        await tester.tap(find.text('Maryam, 27'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(reportKey),
          findsNothing,
          reason: '${state.name} hides the safety action after collapsing',
        );
        expect(tester.takeException(), isNull, reason: state.name);
      }
    },
  );

  testWidgets(
    'Journey cards use one centred header arrow only while collapsed',
    (tester) async {
      for (final state in ZyraConnectionsJourneyCardTestState.values) {
        await pumpJourneyCard(tester, state, expand: false);

        final expand = find.byKey(
          ValueKey<String>(
            'connections-card-expand-connections-card-test-${state.name}',
          ),
        );
        final collapse = find
            .byKey(
              ValueKey<String>(
                'connections-card-collapse-connections-card-test-${state.name}',
              ),
            )
            .hitTestable();
        final identity = find.text('Maryam, 27');
        final header = find.byKey(
          ValueKey<String>(
            'connections-card-header-connections-card-test-${state.name}',
          ),
        );

        expect(expand, findsOneWidget, reason: state.name);
        expect(collapse, findsNothing, reason: state.name);
        expect(
          tester.getRect(expand).center.dy,
          closeTo(tester.getRect(header).center.dy, 1),
          reason:
              '${state.name} collapsed arrow must centre on the identity row',
        );

        await tester.tap(identity);
        await tester.pumpAndSettle();

        expect(expand, findsNothing, reason: state.name);
        expect(collapse, findsOneWidget, reason: state.name);
        expect(tester.takeException(), isNull, reason: state.name);

        await tester.tap(collapse);
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('Considered Saved and Passed copy Potential arrow position', (
    tester,
  ) async {
    await pumpJourneyCard(
      tester,
      ZyraConnectionsJourneyCardTestState.potential,
      expand: false,
    );
    final potentialArrow = tester.getRect(
      find.byKey(
        const ValueKey(
          'connections-card-expand-connections-card-test-potential',
        ),
      ),
    );
    final potentialHeader = tester.getRect(
      find.byKey(
        const ValueKey(
          'connections-card-header-connections-card-test-potential',
        ),
      ),
    );
    final expectedRightInset = potentialHeader.right - potentialArrow.center.dx;

    for (final state in ZyraConnectionsActivityCardTestState.values) {
      await pumpActivityCard(tester, state);
      final arrow = tester.getRect(
        find.byKey(
          ValueKey<String>(
            'connections-activity-expand-connections-activity-test-${state.name}',
          ),
        ),
      );
      final header = tester.getRect(
        find.byKey(
          ValueKey<String>(
            'connections-activity-card-header-connections-activity-test-${state.name}',
          ),
        ),
      );

      expect(
        arrow.center.dy,
        closeTo(header.center.dy, 1),
        reason: '${state.name} arrow must be vertically centred',
      );
      expect(
        header.right - arrow.center.dx,
        closeTo(expectedRightInset, 0.01),
        reason: '${state.name} must use Potential\'s right inset',
      );
      expect(tester.takeException(), isNull, reason: state.name);
    }
  });

  testWidgets(
    'Activity cards show identity, exact actions, and expanded report flag',
    (tester) async {
      const expected = {
        ZyraConnectionsActivityCardTestState.considered: [
          'Save',
          'Pass',
          'Compatibility Unlock',
        ],
        ZyraConnectionsActivityCardTestState.saved: [
          'Consider',
          'Pass',
          'Compatibility Unlock',
        ],
        ZyraConnectionsActivityCardTestState.passed: [
          'Consider',
          'Save',
          'Compatibility Unlock',
        ],
      };

      for (final localTestProfile in [false, true]) {
        for (final state in ZyraConnectionsActivityCardTestState.values) {
          final localState = ZyraActivityTestState.values.byName(state.name);
          final id = localTestProfile
              ? zyraActivityTestProfileId(localState, 0)
              : 'connections-activity-test-${state.name}';
          final reason = '${state.name} / local=$localTestProfile';
          final report = find.byKey(ValueKey<String>('connections-report-$id'));
          final header = find.byKey(
            ValueKey<String>('connections-activity-card-header-$id'),
          );
          final location = find.byKey(
            ValueKey<String>('connections-activity-location-$id'),
          );
          final expand = find.byKey(
            ValueKey<String>('connections-activity-expand-$id'),
          );
          final collapse = find.byKey(
            ValueKey<String>('connections-activity-collapse-$id'),
          );

          await pumpActivityCard(
            tester,
            state,
            localTestProfile: localTestProfile,
          );
          expect(header, findsOneWidget, reason: reason);
          expect(find.text('Maryam, 27'), findsOneWidget, reason: reason);
          expect(location, findsOneWidget, reason: reason);
          expect(find.text('London'), findsOneWidget, reason: reason);
          expect(find.textContaining('Preview'), findsNothing, reason: reason);
          expect(expand, findsOneWidget, reason: reason);
          expect(report, findsNothing, reason: reason);

          await tester.tap(find.text('Maryam, 27'));
          await tester.pumpAndSettle();

          expect(header, findsOneWidget, reason: reason);
          expect(location, findsOneWidget, reason: reason);
          expect(expand, findsNothing, reason: reason);
          expect(collapse, findsOneWidget, reason: reason);
          expect(report, findsOneWidget, reason: reason);
          expect(
            find.byKey(const ValueKey('connections-action-Report')),
            findsNothing,
            reason: '$reason uses the quiet top-right flag',
          );
          expect(
            find.byType(AspectRatio),
            findsNothing,
            reason: '$reason must not restore the retired large photo',
          );
          expect(
            find.byKey(const ValueKey('connections-action-View Profile')),
            findsOneWidget,
            reason: reason,
          );

          final actionStrip = find.byKey(
            const ValueKey('connections-card-action-strip'),
          );
          expect(actionStrip, findsOneWidget, reason: reason);
          expect(
            find.descendant(of: actionStrip, matching: find.byType(Material)),
            findsNWidgets(3),
            reason: '$reason has exactly three secondary pills',
          );

          final expectedLabels = expected[state]!;
          final actionRects = <Rect>[];
          for (final label in expectedLabels) {
            final action = find.byKey(
              ValueKey<String>('connections-action-$label'),
            );
            expect(action, findsOneWidget, reason: '$reason / $label');
            actionRects.add(tester.getRect(action));
          }
          expect(
            actionRects[0].center.dy,
            closeTo(actionRects[1].center.dy, 0.01),
            reason: '$reason keeps the two state decisions together',
          );
          expect(
            actionRects[0].center.dx,
            lessThan(actionRects[1].center.dx),
            reason: '$reason preserves the approved state-decision order',
          );
          expect(
            actionRects[2].top,
            greaterThan(actionRects[0].bottom),
            reason: '$reason places Compatibility after the decisions',
          );
          expect(
            actionRects[2].width,
            greaterThan(actionRects[0].width * 1.8),
            reason: '$reason keeps Compatibility Unlock readable',
          );

          for (final action in ['Pass', 'Save', 'Consider']) {
            expect(
              find.byKey(ValueKey<String>('connections-action-$action')),
              expectedLabels.contains(action) ? findsOneWidget : findsNothing,
              reason: '$reason / $action',
            );
          }
          expect(
            find.byKey(const ValueKey('connections-action-View Compatibility')),
            findsNothing,
            reason: '$reason starts locked in this isolated surface',
          );

          await tester.tap(collapse.hitTestable());
          await tester.pumpAndSettle();
          expect(header, findsOneWidget, reason: reason);
          expect(location, findsOneWidget, reason: reason);
          expect(expand, findsOneWidget, reason: reason);
          expect(report, findsNothing, reason: reason);
          expect(tester.takeException(), isNull, reason: reason);
        }
      }
    },
  );

  testWidgets('Activity compact expansion survives narrow large text', (
    tester,
  ) async {
    for (final state in ZyraConnectionsActivityCardTestState.values) {
      await pumpActivityCard(
        tester,
        state,
        width: 286,
        textScale: 1.45,
        expand: true,
      );
      expect(tester.takeException(), isNull, reason: state.name);
    }
  });

  testWidgets('Activity main and Pass actions use one neutral glass colour', (
    tester,
  ) async {
    await pumpActivityCard(
      tester,
      ZyraConnectionsActivityCardTestState.considered,
      expand: true,
    );

    Material materialFor(String label) => tester.widget<Material>(
      find.byKey(ValueKey<String>('connections-action-$label')),
    );

    final viewProfile = materialFor('View Profile');
    final save = materialFor('Save');
    final pass = materialFor('Pass');
    expect(viewProfile.color, save.color);
    expect(pass.color, save.color);

    Color? iconColour(String label, IconData icon) => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(ValueKey<String>('connections-action-$label')),
            matching: find.byIcon(icon),
          ),
        )
        .color;

    expect(
      iconColour('Pass', Icons.close),
      iconColour('Save', Icons.bookmark_border),
    );
  });

  testWidgets('Journey and Activity allow only one expanded card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 330,
              child: buildZyraConnectionsExclusiveExpansionTestSurface(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Maryam, 27'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('connections-card-collapse-exclusive-journey')),
      findsOneWidget,
    );

    final activityHeader = find.byKey(
      const ValueKey(
        'connections-activity-card-header-exclusive-activity-profile',
      ),
    );
    await tester.ensureVisible(activityHeader);
    await tester.tap(activityHeader);
    await tester.pumpAndSettle();

    expect(
      find
          .byKey(const ValueKey('connections-card-collapse-exclusive-journey'))
          .hitTestable(),
      findsNothing,
    );
    expect(
      find
          .byKey(
            const ValueKey(
              'connections-activity-collapse-exclusive-activity-profile',
            ),
          )
          .hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('moved Introduction keeps its Guardian attribution', (
    tester,
  ) async {
    await pumpActivityCard(
      tester,
      ZyraConnectionsActivityCardTestState.saved,
      localTestProfile: true,
      movedIntroduction: true,
      expand: true,
    );

    expect(find.text('Suggested by Ibrahim'), findsOneWidget);
    expect(find.textContaining('Preview'), findsNothing);
    expect(
      find.byKey(const ValueKey('connections-action-View Profile')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact Chips fill the card with three equal actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: buildZyraConnectionsDesignTestSurface()),
        ),
      ),
    );

    final profile = tester.getSize(
      find.byKey(const ValueKey('connections-action-View Profile')),
    );
    final timeline = tester.getSize(
      find.byKey(const ValueKey('connections-action-Timeline')),
    );
    final options = tester.getSize(
      find.byKey(const ValueKey('connections-action-Options')),
    );

    expect(profile.width, closeTo(timeline.width, 0.01));
    expect(timeline.width, closeTo(options.width, 0.01));
    expect(profile.width * 3 + 14, closeTo(330, 0.01));
  });

  testWidgets('approved Accent Marker heading omits numeric counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: buildZyraConnectionsDesignTestSurface()),
        ),
      ),
    );

    expect(find.text('1'), findsNothing);
  });

  testWidgets('Potential keeps Report top-right and gives two actions width', (
    tester,
  ) async {
    await pumpJourneyCard(
      tester,
      ZyraConnectionsJourneyCardTestState.potential,
    );

    final report = find.byKey(
      const ValueKey('connections-report-connections-card-test-profile'),
    );
    final card = find.byKey(
      const ValueKey(
        'connections-journey-card-connections-card-test-potential',
      ),
    );
    expect(report, findsOneWidget);
    expect(
      find.byKey(const ValueKey('connections-action-Report')),
      findsNothing,
    );
    expect(
      tester.getRect(report).center.dx,
      greaterThan(tester.getRect(card).center.dx),
    );

    final strip = find.byKey(const ValueKey('connections-card-action-strip'));
    final profile = find.descendant(
      of: strip,
      matching: find.byKey(const ValueKey('connections-action-View Profile')),
    );
    final compatibility = find.descendant(
      of: strip,
      matching: find.byKey(
        const ValueKey('connections-action-Compatibility Unlock'),
      ),
    );
    expect(profile, findsOneWidget);
    expect(compatibility, findsOneWidget);
    expect(
      tester.getSize(profile).width,
      closeTo(tester.getSize(compatibility).width, 0.01),
    );
  });

  testWidgets('Paused groups Journey references and leaves two card actions', (
    tester,
  ) async {
    await pumpJourneyCard(tester, ZyraConnectionsJourneyCardTestState.paused);

    final references = find.byKey(
      const ValueKey(
        'connections-journey-reference-connections-card-test-paused',
      ),
    );
    final strip = find.byKey(const ValueKey('connections-card-action-strip'));
    expect(
      find.descendant(of: references, matching: find.text('Timeline')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: references,
        matching: find.text('View Compatibility'),
      ),
      findsOneWidget,
    );
    final referenceActions = find.descendant(
      of: find.descendant(
        of: references,
        matching: find.byKey(
          const ValueKey('connections-journey-reference-actions'),
        ),
      ),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'connections-action-',
            ),
      ),
    );
    expect(referenceActions, findsNWidgets(2));
    expectJourneyReferenceMatchesProfilePill(
      tester,
      references,
      'Timeline',
      Icons.timeline_outlined,
    );
    expectJourneyReferenceMatchesProfilePill(
      tester,
      references,
      'View Compatibility',
      Icons.insights_outlined,
    );
    expect(tester.widget<Container>(references).decoration, isNull);
    expect(
      find.descendant(of: strip, matching: find.text('Timeline')),
      findsNothing,
    );
    expect(
      find.descendant(of: strip, matching: find.text('View Compatibility')),
      findsNothing,
    );

    final profile = find.descendant(
      of: strip,
      matching: find.byKey(const ValueKey('connections-action-View Profile')),
    );
    final end = find.descendant(
      of: strip,
      matching: find.byKey(const ValueKey('connections-action-End Journey')),
    );
    expect(profile, findsOneWidget);
    expect(end, findsOneWidget);
    expect(
      tester.getSize(profile).width,
      closeTo(tester.getSize(end).width, 0.01),
    );
    expect(
      tester.widget<Material>(profile).color,
      tester.widget<Material>(end).color,
      reason: 'Paused End Journey uses the same neutral glass as View Profile',
    );
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: profile,
              matching: find.byIcon(Icons.person_outline),
            ),
          )
          .color,
      tester
          .widget<Icon>(
            find.descendant(
              of: end,
              matching: find.byIcon(Icons.stop_circle_outlined),
            ),
          )
          .color,
    );
    expect(find.textContaining('together'), findsNothing);
  });

  testWidgets('Ended keeps Timeline and Compatibility in Journey section', (
    tester,
  ) async {
    await pumpJourneyCard(tester, ZyraConnectionsJourneyCardTestState.ended);

    final references = find.byKey(
      const ValueKey(
        'connections-journey-reference-connections-card-test-ended',
      ),
    );
    final strip = find.byKey(const ValueKey('connections-card-action-strip'));
    expect(
      find.descendant(of: references, matching: find.text('Timeline')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: references,
        matching: find.text('View Compatibility'),
      ),
      findsOneWidget,
    );
    expectJourneyReferenceMatchesProfilePill(
      tester,
      references,
      'Timeline',
      Icons.timeline_outlined,
    );
    expectJourneyReferenceMatchesProfilePill(
      tester,
      references,
      'View Compatibility',
      Icons.insights_outlined,
    );
    expect(tester.widget<Container>(references).decoration, isNull);
    expect(
      find.descendant(of: strip, matching: find.text('View Profile')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: strip, matching: find.text('Timeline')),
      findsNothing,
    );
  });

  testWidgets(
    'Founder TestFlight hold removes every Request New Journey control',
    (tester) async {
      expect(ZyraReleaseGates.requestNewJourneyEnabled, isFalse);

      await pumpJourneyCard(tester, ZyraConnectionsJourneyCardTestState.ended);

      expect(find.text('Request New Journey'), findsNothing);
      expect(find.text('Send request'), findsNothing);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('View Compatibility'), findsOneWidget);
    },
  );

  test(
    'Founder TestFlight hold short-circuits Journey request RPC wrappers',
    () async {
      expect(await ZyraJourneyService.fetchMayRequestNewJourneyIds(), isEmpty);
      expect(
        await ZyraJourneyService.requestNewJourney('not-a-live-match'),
        ZyraReleaseGates.requestNewJourneyUnavailable,
      );
      expect(
        await ZyraJourneyService.respondToJourneyRequest(
          'not-a-live-request',
          'accept',
        ),
        ZyraReleaseGates.requestNewJourneyUnavailable,
      );
    },
  );

  testWidgets(
    'end and ended surfaces do not promise the held 60-day request path',
    (tester) async {
      Future<void> expectHeldCopy(Widget surface) async {
        await tester.pumpWidget(MaterialApp(home: surface));
        await tester.pump();
        expect(
          find.textContaining(ZyraReleaseGates.requestNewJourneyUnavailable),
          findsOneWidget,
        );
        expect(find.textContaining('60 days'), findsNothing);
      }

      await expectHeldCopy(buildZyraEndConfirmationTestSurface());
      await expectHeldCopy(buildZyraJourneyEndedCompleteTestSurface());
      await expectHeldCopy(Scaffold(body: buildZyraEndedJourneyTestSurface()));
    },
  );

  testWidgets('all Journey cards avoid overflow at compact large-text width', (
    tester,
  ) async {
    for (final state in ZyraConnectionsJourneyCardTestState.values) {
      await pumpJourneyCard(tester, state, width: 286, textScale: 1.45);
      expect(tester.takeException(), isNull, reason: state.name);
    }
  });

  test('Introduction fixtures preserve real rows and add unique extras', () {
    const real = GuardianSuggestion(
      profile: SeekerProfile(
        id: 'real-introduction',
        firstName: 'Amina',
        age: 28,
        city: 'London',
        photos: [],
        gender: 'female',
      ),
      suggestedBy: 'Ibrahim',
    );

    final composed = composeZyraIntroductionPreviewSuggestions(const [
      real,
    ], previewCount: 2);

    expect(composed, hasLength(3));
    expect(composed.first, same(real));
    expect(composed.map((row) => row.profile.id).toSet(), hasLength(3));
    expect(
      composed.skip(1).every((row) => row.suggestedBy == 'Ibrahim'),
      isTrue,
    );
  });

  test(
    'local Introduction Preview bypasses only the development load gate',
    () {
      expect(
        shouldZyraIntroductionShowLoading(
          suggestionsLoaded: false,
          localPreviewCount: 1,
          releaseBuild: false,
        ),
        isFalse,
      );
      expect(
        shouldZyraIntroductionShowLoading(
          suggestionsLoaded: false,
          localPreviewCount: 0,
          releaseBuild: false,
        ),
        isTrue,
      );
      expect(
        shouldZyraIntroductionShowLoading(
          suggestionsLoaded: false,
          localPreviewCount: 1,
          releaseBuild: true,
        ),
        isTrue,
      );
    },
  );

  test('Activity previews preserve truth and remain unique by group', () {
    const real = SeekerProfile(
      id: 'real-saved',
      firstName: 'Amina',
      age: 28,
      city: 'London',
      photos: [],
      gender: 'female',
    );

    final considered = composeZyraActivityPreviewProfiles(
      const [real],
      kind: ZyraActivityTestState.considered,
      previewCount: 7,
      viewerGender: 'male',
    );
    final saved = composeZyraActivityPreviewProfiles(
      const [real],
      kind: ZyraActivityTestState.saved,
      previewCount: 2,
      viewerGender: 'male',
    );

    expect(considered, hasLength(6));
    expect(considered.first, same(real));
    expect(considered.map((profile) => profile.id).toSet(), hasLength(6));
    expect(saved, hasLength(3));
    expect(
      considered
          .skip(1)
          .map((profile) => profile.id)
          .toSet()
          .intersection(saved.skip(1).map((profile) => profile.id).toSet()),
      isEmpty,
    );
    expect(
      considered.skip(1).every((profile) => profile.gender == 'female'),
      isTrue,
    );
  });

  test('moved local fixtures appear in exactly one Activity section', () {
    final scenario = ZyraDevScenario.instance
      ..setConsideredPreviewCount(1)
      ..setIntroductionPreviewCount(1);
    final consideredId = zyraActivityTestProfileId(
      ZyraActivityTestState.considered,
      0,
    );
    final introductionId = zyraIntroductionTestProfileId(0);

    ZyraActivityTestBuckets buckets() => composeZyraActivityTestBuckets(
      scenario: scenario,
      realConsidered: const [],
      realSaved: const [],
      realPassed: const [],
      viewerGender: 'male',
    );

    int occurrences(ZyraActivityTestBuckets value, String id) => [
      ...value.considered,
      ...value.saved,
      ...value.passed,
    ].where((profile) => profile.id == id).length;

    final initial = buckets();
    expect(initial.considered.single.id, consideredId);
    expect(occurrences(initial, consideredId), 1);
    expect(occurrences(initial, introductionId), 0);

    scenario
      ..moveLocalProfile(consideredId, ZyraActivityTestState.passed)
      ..moveLocalProfile(introductionId, ZyraActivityTestState.saved);
    final moved = buckets();
    expect(moved.passed.single.id, consideredId);
    expect(moved.saved.single.id, introductionId);
    expect(occurrences(moved, consideredId), 1);
    expect(occurrences(moved, introductionId), 1);

    scenario
      ..setConsideredPreviewCount(0)
      ..setIntroductionPreviewCount(0);
    final removed = buckets();
    expect(occurrences(removed, consideredId), 0);
    expect(occurrences(removed, introductionId), 0);
  });

  testWidgets('Introduction fixture surface renders exact 0, 1 and 5 rows', (
    tester,
  ) async {
    for (final count in [0, 1, 5]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 330,
                child: buildZyraIntroductionPreviewTestSurface(
                  previewCount: count,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Preview'), findsNothing);
      expect(
        find.text('Suggested by Ibrahim').hitTestable(),
        findsNWidgets(count),
      );
      expect(tester.takeException(), isNull, reason: 'test count $count');
    }
  });

  testWidgets('local Introduction fixture exposes safe local test actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 330,
              child: buildZyraIntroductionPreviewTestSurface(previewCount: 1),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Maryam, 27'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Preview'), findsNothing);
    expect(
      find.byKey(
        const ValueKey(
          'connections-activity-card-header-zyra-local-introduction-preview-0',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('London'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'connections-activity-location-zyra-local-introduction-preview-0',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(AspectRatio), findsNothing);
    expect(
      find.byKey(const ValueKey('connections-action-View Profile')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('connections-report-zyra-local-introduction-preview-0'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('connections-action-Report')),
      findsNothing,
    );
    for (final localAction in [
      'Pass',
      'Save',
      'Consider',
      'Compatibility Unlock',
    ]) {
      expect(
        find.byKey(ValueKey<String>('connections-action-$localAction')),
        findsOneWidget,
        reason: localAction,
      );
    }
    expect(
      find.byKey(const ValueKey('connections-action-View Compatibility')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
