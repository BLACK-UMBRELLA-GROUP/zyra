// New candidate captures; approved baselines and profile editors stay intact.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/screens/onboarding/generic_select_question_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/flexibility_choice.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';

import '../initial_signup_draft_test.dart' show FakeSignupStore;

const _capture = bool.fromEnvironment('ZYRA_GUIDED_CHOICES_CAPTURE');
const _boundary = ValueKey('guided-choices-candidate');

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsGuidedChoiceReview');
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
    final logo = FontLoader('SyneGuidedChoiceReview')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), logo.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsGuidedChoiceReview';
    ZyraText.testWordmarkFontFamily = 'SyneGuidedChoiceReview';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });
  setUp(
    () => ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: FakeSignupStore(),
        backend: 'https://example.invalid',
        currentUserId: () => 'choice-account',
        isPreview: () => false,
      ),
    ),
  );
  tearDown(() => ZyraInitialSignupDraftService.setRepositoryForTesting(null));

  for (final compact in [false, true]) {
    for (final page in [
      'seeker_gender',
      'guardian_gender',
      'guardian_relationship',
      'compatibility',
      'flexibility',
    ]) {
      testWidgets('guided choices $page ${compact ? 'compact140' : 'phone'}', (
        tester,
      ) async {
        tester.view.physicalSize = compact
            ? const Size(320, 568)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                textScaler: TextScaler.linear(compact ? 1.4 : 1),
                disableAnimations: true,
              ),
              child: RepaintBoundary(key: _boundary, child: child!),
            ),
            home: _page(page),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final suffix = compact ? 'compact140' : 'phone';
        if (page == 'seeker_gender') {
          await _candidate(tester, '${page}_unselected_$suffix');
          await tester.ensureVisible(find.text('Male'));
          await tester.tap(find.text('Male'));
          await tester.pumpAndSettle();
          await _candidate(tester, '${page}_male_$suffix');
          await tester.ensureVisible(find.text('Female'));
          await tester.tap(find.text('Female'));
          await tester.pumpAndSettle();
          await _candidate(tester, '${page}_female_$suffix');
        } else {
          await _candidate(tester, '${page}_$suffix');
        }
        if (compact) {
          // The continue footer is fixed: revealing it cannot scroll the
          // answer list. Read to its actual end before capturing that state.
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -900),
          );
          await tester.pumpAndSettle();
          await _candidate(tester, '${page}_end_$suffix');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Widget _page(String page) {
  if (page == 'seeker_gender') {
    return const OnboardingFlow(
      signupUserId: 'choice-account',
      initialDraft: ZyraInitialSignupDraft(
        role: ZyraSignupRole.seeker,
        step: 1,
        firstName: 'Amina',
        lastName: 'Ahmad',
      ),
    );
  }
  if (page.startsWith('guardian')) {
    return WaliOnboardingFlow(
      signupUserId: 'choice-account',
      initialDraft: ZyraInitialSignupDraft(
        role: ZyraSignupRole.guardian,
        step: page == 'guardian_relationship' ? 3 : 2,
        firstName: 'Amina',
        lastName: 'Ahmad',
        dob: DateTime(1990, 1, 1),
        gender: 'female',
        relationship: page == 'guardian_relationship' ? 'Mother' : null,
      ),
    );
  }
  return OnboardingScaffold(
    background: ZyraBackgroundVariant.neutral,
    chapterName: page == 'flexibility'
        ? 'Your Profile'
        : 'Compatibility · Part 1',
    chapterProgress: .3,
    question: page == 'flexibility'
        ? 'Would you be happy for ZYRA to introduce people outside your preferred area if they appear to be a strong match?'
        : 'How would you describe your approach to practising Islam?',
    frameContent: false,
    fabActive: true,
    onContinue: () {},
    content: page == 'flexibility'
        ? FlexibilityChoice(
            greenText: "Yes, I'd be happy to consider them.",
            yellowText: 'Maybe, depending on the person.',
            redText: "No, I'd prefer to stay within my preferred area.",
            value: TrafficLight.green,
            onChanged: (_) {},
          )
        : GenericSelectQuestionScreen(
            prompt: 'Practice',
            options: const [
              'I strive to practise consistently',
              'I am learning and growing',
            ],
            selectionType: QuestionSelectionType.multi,
            guidedChoices: true,
            initialValue: const ['I strive to practise consistently'],
            onChanged: (_) {},
          ),
  );
}

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.runAsync(
      () => expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile(
          'candidates/onboarding_guided_choices_2026_10_04/$name.png',
        ),
      ),
    );
  } finally {
    image?.dispose();
  }
}
