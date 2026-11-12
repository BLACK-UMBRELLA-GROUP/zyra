import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE92_CAPTURE_DIR');
const _myZyraAction = 'focus-open-preference-quick-check';
const _cardAction = 'partner-preferences-check-now';
const _legacyLine = 'Saved before as “No preference”. Tap a light to confirm.';

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final (size, safePadding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('LOCK 30 quick check at $dimensions', (tester) async {
      final harness = BaselineHarness(
        tester,
        group: 'line92_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: safePadding,
        reduceMotion: true,
      );
      final checkpoint = ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: (ViewRequestDraftModel(
          capacity: 3,
        )..seedReceived('draft-amira')).snapshot(),
        tab: 2,
        pages: const [],
      );
      final ready = Completer<void>();
      await harness.mountPresentation(
        child: ZyraOneJourneyConceptShell(
          canAct: () => true,
          onExit: () => fail('The check stays in the Founder preview'),
          initialCheckpoint: checkpoint,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
          fixture: const ZyraOneJourneyShellFixture(
            legacyAmberQuickCheck: true,
          ),
        ),
        checkpoint: checkpoint,
      );
      for (var attempt = 0; attempt < 80 && !ready.isCompleted; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await harness.flush();
      }
      expect(ready.isCompleted, isTrue);
      Future<void> capture(String name) async {
        if (_captures.isNotEmpty) {
          await harness.capture(
            'preferences',
            'quick_check',
            name,
            name,
            fileName: '${name}_$dimensions.png',
          );
        }
      }

      expect(find.byKey(const ValueKey(_myZyraAction)), findsOneWidget);
      await capture('my_zyra_pending');
      await harness.tap(_myZyraAction);
      await tester.pumpAndSettle();
      expect(find.text("Your partner's sect"), findsOneWidget);
      expect(find.text(_legacyLine), findsOneWidget);
      expect(find.text('Open to this'), findsNWidgets(3));
      await capture('sect_before');
      await swipeZyraBack(tester);

      expect(find.text('5 answers to check'), findsOneWidget);
      expect(find.text('5 to check', findRichText: true), findsNothing);
      expect(
        find.textContaining('5 to check', findRichText: true),
        findsOneWidget,
      );
      await capture('overview_pending');
      await harness.tap('edit-preferences-deen_practice');
      await capture('deen');
      await swipeZyraBack(tester);
      await harness.tap(_cardAction);
      await tester.pumpAndSettle();
      expect(find.text("Your partner's sect"), findsOneWidget);
      await harness.tap('preference_Shia_yellow');
      expect(find.text(_legacyLine), findsNothing);
      expect(find.text('Saved. 4 left to check.'), findsOneWidget);
      await capture('sect_after');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await swipeZyraBack(tester);

      expect(find.text('4 answers to check'), findsOneWidget);
      await harness.tap('edit-preferences-deen_practice');
      expect(find.text('FROM YOUR PROFILE SET-UP'), findsOneWidget);
      expect(find.text('PARTNER PREFERENCES'), findsOneWidget);
      expect(find.text('1 to check'), findsNWidgets(2));
      expect(find.text('2 to check'), findsOneWidget);

      await harness.tap('edit-lights-ch2.sect.outside_flexibility');
      expect(find.text(_legacyLine), findsOneWidget);
      await capture('outside_before');
      await harness.tap('preference_Outside my preferred sect_green');
      expect(find.text('Saved. 3 left to check.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await swipeZyraBack(tester);

      await harness.tap('edit-lights-ch2.revert.flexibility');
      expect(find.text(_legacyLine), findsOneWidget);
      await capture('revert_before');
      await harness.tap('preference_A partner who reverted to Islam_red');
      expect(find.text('Saved. 2 left to check.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await swipeZyraBack(tester);

      await harness.tap('edit-lights-ch3_q33');
      expect(find.text(_legacyLine), findsNWidgets(2));
      await capture('partner_before');
      await harness.tap('preference_Usually all five prayers_yellow');
      expect(find.text(_legacyLine), findsOneWidget);
      expect(find.text('All checked. Thank you.'), findsNothing);
      await capture('partner_one_left');
      await harness.tap('preference_Most days_green');
      expect(find.text(_legacyLine), findsNothing);
      expect(find.text('All checked. Thank you.'), findsOneWidget);
      await capture('partner_complete');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await swipeZyraBack(tester);
      await swipeZyraBack(tester);

      expect(find.byKey(const ValueKey(_cardAction)), findsNothing);
      await capture('overview_complete');
      await swipeZyraBack(tester);
      expect(find.byKey(const ValueKey(_myZyraAction)), findsNothing);
      await capture('my_zyra_complete');
    });
  }

  test(
    'counterpart variants count only matching options and preserve legacy keys',
    () {
      final snapshot = ZyraOnboardingAnswersSnapshot(
        ch3Answers: const {},
        ch4Preferences: const {
          'ch3_q26': {'I only wish to have one wife': TrafficLight.yellow},
          'ch3_q39': {'Most daily prayers': TrafficLight.yellow},
        },
        ch4HardRequirements: const {},
        journeyBio: JourneyBio.fromOnboardingAnswers(const {}),
      );
      final man = ZyraCompatibilityDraft.fromSnapshot(
        gender: 'male',
        snapshot: snapshot,
      );
      final woman = ZyraCompatibilityDraft.fromSnapshot(
        gender: 'female',
        snapshot: snapshot,
      );
      final forMan = man.preferenceQuestionBank.singleWhere(
        (q) => q.id == 'ch3_q26',
      );
      final forWoman = woman.preferenceQuestionBank.singleWhere(
        (q) => q.id == 'ch3_q26',
      );
      expect(forMan.genderVisibility, GenderVisibility.womenOnly);
      expect(forWoman.genderVisibility, GenderVisibility.menOnly);
      expect(man.preferenceQuestionBank.any((q) => q.id == 'ch3_q39'), isFalse);
      expect(
        woman.preferenceQuestionBank.any((q) => q.id == 'ch3_q39'),
        isTrue,
      );
      expect(man.valuesFor(forMan), isEmpty);
      expect(woman.valuesFor(forWoman).values, [TrafficLight.yellow]);
      expect(man.preferenceAnswerCount, 0);
      expect(man.toSnapshot().ch4Preferences, snapshot.ch4Preferences);
    },
  );
}
