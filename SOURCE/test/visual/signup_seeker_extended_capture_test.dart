// Queue 10: the existing optional Seeker setup, with local data and no account.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/onboarding/article9_consent_screen.dart';
import 'package:zyra/screens/onboarding/bio_onboarding_flow.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/onboarding/profile_ready_screen.dart';
import 'package:zyra/screens/onboarding/values_preferences_flow.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_onboarding_choice_card.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

import 'signup_capture_support.dart';

Widget _selectedPresentation(Widget child) => ZyraOnboardingArrowScope(
  enabled: true,
  child: OnboardingPreviewStyle(directionName: 'luma', child: child),
);

String _slug(String value) => value.replaceAll(RegExp('[^a-zA-Z0-9]+'), '_');

const _existingBioDiagnostic =
    'ListTile background color or ink splashes may be invisible. '
    'The ListTile is wrapped in a DecoratedBox that has a background color. '
    'Because ListTile paints its background and ink splashes on the nearest '
    'Material ancestor, this DecoratedBox will hide those effects. '
    'To fix this, wrap the ListTile in its own Material widget, or remove the '
    'background color from the intermediate DecoratedBox.';

String _normalizedDiagnostic(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();

Future<void> _captureExistingBio(
  WidgetTester tester,
  Future<void> Function() capture,
) async {
  final original = FlutterError.onError;
  final diagnostics = <Map<String, Object?>>[];
  FlutterError.onError = (details) {
    final raw = details.exceptionAsString();
    if (details.exception is FlutterError &&
        _normalizedDiagnostic(raw) == _existingBioDiagnostic) {
      diagnostics.add({
        'raw_diagnostic': raw,
        'normalized_diagnostic': _normalizedDiagnostic(raw),
        'context': details.context?.toDescription(),
        'library': details.library,
        'stack': details.stack?.toString(),
      });
      return;
    }
    if (original != null) {
      original(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  try {
    await capture();
  } finally {
    // Compatibility and all other pages retain the original strict handler.
    FlutterError.onError = original;
    final file = File('$signupEvidence/existing_bio_list_tile_diagnostic.json');
    await tester.runAsync(
      () => file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'known_existing_visual_diagnostic': true,
          'scope': 'Bio capture only; handler restored before Compatibility',
          'exact_normalized_message': _existingBioDiagnostic,
          'matching_rule':
              'FlutterError type and entire normalized text equality',
          'all_other_errors': 'forwarded to original FlutterError.onError',
          'source':
              'SOURCE/lib/screens/onboarding/bio_onboarding_flow.dart:585',
          'written_refusal':
              'No product repair under the capture-only brief. Screenshots retain '
              'the existing SwitchListTile presentation and its known background '
              'or ink diagnostic. This task records the limitation.',
          'diagnostics': diagnostics,
        }),
        flush: true,
      ),
    );
  }
  expect(diagnostics, isNotEmpty);
  for (final diagnostic in diagnostics) {
    expect(diagnostic['normalized_diagnostic'], _existingBioDiagnostic);
    expect(
      _normalizedDiagnostic(diagnostic['raw_diagnostic']! as String),
      _existingBioDiagnostic,
    );
  }
  expect(FlutterError.onError, same(original));
}

ScrollPosition? _pageScroll(WidgetTester tester) {
  final positions = tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .map((state) => state.position)
      .where(
        (position) =>
            position.axis == Axis.vertical && position.hasContentDimensions,
      )
      .toList();
  if (positions.isEmpty) return null;
  positions.sort((a, b) => b.viewportDimension.compareTo(a.viewportDimension));
  return positions.first;
}

Future<void> _top(SignupCaptureHarness h) async {
  final position = _pageScroll(h.tester);
  if (position != null) position.jumpTo(position.minScrollExtent);
  await h.flush(const Duration(milliseconds: 500));
}

/// Each file remains a real phone viewport. Overlapping scroll positions also
/// expose every option and every grouped preference row below the first fold.
Future<void> _page(
  SignupCaptureHarness h,
  int order,
  String screen,
  String state,
  String reached,
) async {
  await _top(h);
  await h.capture(order + 2, screen, state, reached: reached);
  final position = _pageScroll(h.tester);
  if (position == null || position.maxScrollExtent <= 1) return;
  final maximum = position.maxScrollExtent;
  final stride = math.max(1.0, position.viewportDimension * .72);
  var frame = 1;
  for (var offset = math.min(stride, maximum); ; offset += stride) {
    final target = math.min(offset, maximum);
    position.jumpTo(target);
    await h.flush();
    await h.capture(
      order + 2,
      screen,
      '${state}_scroll_${frame.toString().padLeft(2, '0')}',
      reached:
          '$reached; actual page scroll to '
          '${target.toStringAsFixed(1)} of ${maximum.toStringAsFixed(1)} logical px',
    );
    frame++;
    if (target >= maximum) break;
    expect(frame, lessThan(100), reason: 'Bounded scroll coverage per page');
  }
  await _top(h);
}

Future<void> _skipQuestion(SignupCaptureHarness h) async {
  await _top(h);
  await h.tap('onboarding_dev_skip');
}

Future<void> _stage(SignupCaptureHarness h, int order, String name) async {
  expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
  await _page(
    h,
    order,
    '${name}_stage',
    'normal',
    'Complete setup branch; actual prior chapter continuation opens the '
        'existing $name stage; local preview, no persistence',
  );
  await h.tap('onboarding_stage_dev_skip');
}

List<OnboardingQuestion> _questions(
  OnboardingCategory category,
  String gender,
) => category.questions
    .where((question) => question.visibleGiven(gender, const {}))
    .toList();

Map<String, int> _maleCompatibilityOrders() {
  var order = 46;
  final result = <String, int>{};
  for (final category in chapter3Categories) {
    result['intro:${category.id}'] = order++;
    for (final question in _questions(category, 'male')) {
      result['answer:${question.id}'] = order++;
    }
    result['summary:${category.id}'] = order++;
  }
  result['about-complete'] = order++;
  result['preferences-intro'] = order++;
  result['preferences-guide'] = order++;
  for (final category in chapter3Categories) {
    result['preferences:${category.id}'] = order++;
  }
  expect(order, 186);
  return result;
}

Future<void> _compatibility(
  SignupCaptureHarness h, {
  required String gender,
  required bool femaleDifferencesOnly,
}) async {
  final orders = _maleCompatibilityOrders();
  final statePrefix = femaleDifferencesOnly ? 'female_' : '';
  final reached =
      'Complete setup branch; actual ValuesPreferencesFlow(devPreview:true), '
      '$gender; each answer selected through its visible current choice; '
      'fixed local sample, no saved account';
  var answerCount = 0;
  for (final category in chapter3Categories) {
    final categoryReached =
        '$reached; '
        '${gender == 'male' && category.id == 'lifestyle_wellbeing' ? 'each Lifestyle answer uses the shortest current option (first on equal lengths), selected by its actual choice callback; long-answer summary overflow remains a recorded source limitation' : 'first current option selected for each answer'}';
    expect(find.text(category.name), findsWidgets);
    if (!femaleDifferencesOnly || category.id == 'deen_practice') {
      await _page(
        h,
        orders['intro:${category.id}']!,
        'compatibility_${category.id}_intro',
        '${statePrefix}normal',
        categoryReached,
      );
    }
    await h.tap('compatibility_section_continue');
    for (final question in _questions(category, gender)) {
      final questionKey = 'ch3_${question.responseKey}_$gender';
      expect(find.byKey(ValueKey(questionKey)), findsOneWidget);
      expect(find.text(question.prompt), findsWidgets);
      final capture = !femaleDifferencesOnly || question.id == 'ch3_q26';
      final screen = 'values_${_slug(question.responseKey)}';
      final order = orders['answer:${question.id}']!;
      if (capture) {
        await _page(h, order, screen, '${statePrefix}empty', categoryReached);
      }
      // The first current q3 answer is Yes, so the conditional q24 is visited.
      final choice = gender == 'male' && category.id == 'lifestyle_wellbeing'
          ? question.options.reduce(
              (shortest, candidate) =>
                  candidate.length < shortest.length ? candidate : shortest,
            )
          : question.options.first;
      if (question.id == 'ch3_q3') expect(choice, 'Yes');
      await h.tap('compatibility_choice_$choice');
      if (capture) {
        await _page(
          h,
          order,
          screen,
          '${statePrefix}selected',
          categoryReached,
        );
      }
      await h.tap('onboarding_continue');
      answerCount++;
    }
    if (!femaleDifferencesOnly ||
        const {'deen_practice', 'marriage_intentions'}.contains(category.id)) {
      await _page(
        h,
        orders['summary:${category.id}']!,
        'compatibility_${category.id}_summary',
        '${statePrefix}normal',
        categoryReached,
      );
    }
    await h.tap('deferred_onboarding_dev_skip');
  }
  expect(answerCount, gender == 'male' ? 104 : 103);
  await _page(
    h,
    orders['about-complete']!,
    'compatibility_about_you_complete',
    '${statePrefix}normal',
    reached,
  );
  await h.tap('compatibility_boundary_continue');
  if (!femaleDifferencesOnly) {
    await _page(
      h,
      orders['preferences-intro']!,
      'partner_preferences_intro',
      'normal',
      reached,
    );
  }
  await h.tap('compatibility_boundary_continue');
  if (!femaleDifferencesOnly) {
    await _page(
      h,
      orders['preferences-guide']!,
      'partner_preferences_guide',
      'normal',
      reached,
    );
  }
  await h.tap('preference_guide_continue');
  for (final category in chapter3Categories) {
    final questions = _questions(
      category,
      gender,
    ).where((question) => question.ch4Status != Ch4Status.none).toList();
    expect(find.text(category.name), findsWidgets);
    for (final question in questions) {
      expect(
        find.byKey(ValueKey('ch4_grouped_${question.id}')),
        findsOneWidget,
      );
    }
    if (!femaleDifferencesOnly ||
        const {'deen_practice', 'marriage_intentions'}.contains(category.id)) {
      await _page(
        h,
        orders['preferences:${category.id}']!,
        'partner_preferences_${category.id}',
        '${statePrefix}empty',
        '$reached; every grouped preference row shown through overlapping '
            'actual page scroll positions; existing DEV Skip section advances '
            'without claiming preferences saved',
      );
    }
    await _skipQuestion(h);
  }
  expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
}

void main() {
  setUpAll(signupCaptureSetUp);
  tearDownAll(signupCaptureTearDown);

  testWidgets(
    'capture complete optional Seeker Profile Bio and Compatibility route',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'seeker',
        group: 'seeker_extended',
      );
      AppState.instance.applyDevPreset(
        name: 'Shakeel',
        gender: 'male',
        dob: DateTime(1990, 1, 1),
      );
      await h.mount(
        _selectedPresentation(
          const Chapter2Flow(gender: 'male', devPreview: true),
        ),
      );
      var order = 17;
      for (var step = 0; step < 21; step++) {
        expect(find.byType(Chapter2Flow), findsOneWidget);
        final scaffold = tester.widget<OnboardingScaffold>(
          find.byType(OnboardingScaffold),
        );
        expect(scaffold.progressLabel, 'STEP ${step + 1} OF 21');
        final screen =
            'profile_question_${(step + 1).toString().padLeft(2, '0')}';
        final reached =
            'Complete setup branch; public Chapter2Flow(gender:male, '
            'devPreview:true) entry, then actual existing page controls; '
            'question ${step + 1}: ${scaffold.question}; local data only';
        await _page(h, order, screen, 'empty', reached);
        if (step == 1) {
          await tester.enterText(find.byType(TextField), 'London');
          FocusManager.instance.primaryFocus?.unfocus();
          tester.testTextInput.hide();
          await h.flush();
          await _page(h, order, screen, 'selected', reached);
        } else if (find
            .byType(ZyraOnboardingChoiceCard)
            .evaluate()
            .isNotEmpty) {
          await h.tapFinder(find.byType(ZyraOnboardingChoiceCard).first);
          await _page(h, order, screen, 'selected', reached);
        }
        order++;
        if (step == 3) {
          // Use the real enabled question CTA so consent is not bypassed.
          await h.tap('onboarding_continue');
          expect(find.byType(Article9ConsentScreen), findsOneWidget);
          await _page(
            h,
            order++,
            'article9_consent',
            'undecided',
            'Complete setup branch; actual Profile question4 Continue opens '
                'Article9ConsentScreen(devPreview:true); no real consent record',
          );
          await h.tapFinder(
            find.text('I agree — use these answers to match me'),
          );
        } else {
          await _skipQuestion(h);
        }
      }
      expect(order, 39);
      await _stage(h, order++, 'bio');
      expect(find.byType(BioOnboardingFlow), findsOneWidget);
      final bioScreens = [
        'bio_about_me',
        'bio_work_education',
        'bio_family_marriage',
        'bio_practical_life',
        'bio_visibility_review',
      ];
      await _captureExistingBio(tester, () async {
        for (var step = 0; step < bioScreens.length; step++) {
          final reached =
              'Complete setup branch; actual Bio page ${step + 1} of5; '
              'optional local biography data, no profile save';
          await _page(
            h,
            order,
            bioScreens[step],
            step == 4 ? 'sample' : 'empty',
            reached,
          );
          if (step == 0) {
            await tester.enterText(
              find.byType(TextField),
              'Family, faith and a thoughtful approach to marriage matter to me.',
            );
            FocusManager.instance.primaryFocus?.unfocus();
            tester.testTextInput.hide();
            await h.flush();
            await _page(h, order, bioScreens[step], 'sample', reached);
          } else if (step < 4) {
            final section = const [
              'Work & education',
              'Family & marriage',
              'Practical life',
            ][step - 1];
            final fields = journeyBioFieldDefinitions
                .where((field) => field.section == section)
                .toList();
            final dropdownFields = fields
                .where((field) => !field.usesFreeText)
                .toList();
            for (var index = 0; index < dropdownFields.length; index++) {
              final field = dropdownFields[index];
              await h.tapFinder(
                find.byType(DropdownButtonFormField<String>).at(index),
              );
              await h.tapFinder(find.text(field.options.first).last);
            }
            if (find.byType(TextField).evaluate().isNotEmpty) {
              await tester.enterText(find.byType(TextField).first, 'Teacher');
              FocusManager.instance.primaryFocus?.unfocus();
              tester.testTextInput.hide();
              await h.flush();
            }
            await _page(h, order, bioScreens[step], 'sample', reached);
          }
          order++;
          await _skipQuestion(h);
        }
      });
      expect(order, 45);
      await _stage(h, order++, 'compatibility');
      expect(find.byType(ValuesPreferencesFlow), findsOneWidget);
      await _compatibility(h, gender: 'male', femaleDifferencesOnly: false);
      await _stage(h, 186, 'review');
      expect(find.byType(ProfileReadyScreen), findsOneWidget);
      await _page(
        h,
        187,
        'profile_ready',
        'preview',
        'Complete setup branch; actual local ProfileReadyScreen; preview '
            'status only, no identity check or publication was performed',
      );
      await h.tap('profile_review_my_zyra');
      expect(find.byType(HomeShell), findsOneWidget);
      expect(tester.widget<HomeShell>(find.byType(HomeShell)).initialTab, 2);
      expect(
        tester
            .widget<HomeShell>(find.byType(HomeShell))
            .deferredOnboardingDevPreview,
        isTrue,
      );
      await _page(
        h,
        188,
        'complete_setup_first_tab',
        'preview',
        'Complete setup branch; actual Profile review My ZYRA action to '
            'HomeShell initialTab2 with protected deferred onboarding preview; '
            'no live account, no Founder-preview destination',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'capture existing female-only Compatibility wording and row differences',
    (tester) async {
      final h = SignupCaptureHarness(
        tester,
        role: 'seeker',
        group: 'seeker_extended_female',
      );
      AppState.instance.applyDevPreset(
        name: 'Amina',
        gender: 'female',
        dob: DateTime(1990, 1, 1),
      );
      await h.mount(
        _selectedPresentation(
          const ValuesPreferencesFlow(gender: 'female', devPreview: true),
        ),
      );
      await _compatibility(h, gender: 'female', femaleDifferencesOnly: true);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    skip: !signupCaptureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
