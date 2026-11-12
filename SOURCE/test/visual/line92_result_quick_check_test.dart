import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/compatibility_result_quick_check.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE92_CAPTURE_DIR');
const _missing = (questionId: 'ch2.sect.matrix', optionValue: 'current-sect');
const _visible = <ZyraPreferenceOption>{
  (questionId: 'ch2.sect.matrix', optionValue: 'shia'),
  (questionId: 'ch2.sect.outside_flexibility', optionValue: '*'),
  (questionId: 'ch3_q33', optionValue: 'Usually all five prayers'),
  (questionId: 'ch3_q33', optionValue: 'Most days'),
};
// The V201 storyboard places the female q26 item in its synthetic hidden list.
// The male viewer's actual server projection classifies that variant as visible.
const _hidden = <ZyraPreferenceOption>{
  (questionId: 'ch3_q24', optionValue: 'Within 2–3 years'),
  (
    questionId: 'ch3_q26',
    optionValue: 'I would consider being an additional wife',
  ),
};

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  test('V201 male viewer has 320 Chapter 3 choices', () {
    final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
    expect(draft.preferenceOptionCount, 320);
    expect(
      draft.preferenceQuestionBank
          .singleWhere((q) => q.id == 'ch3_q26')
          .genderVisibility,
      GenderVisibility.womenOnly,
    );
    expect(draft.preferenceQuestionBank.any((q) => q.id == 'ch3_q39'), isFalse);
  });

  for (final (size, safePadding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('V201 compatibility result and combined check at $dimensions', (
      tester,
    ) async {
      final harness = BaselineHarness(
        tester,
        group: 'q115_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: safePadding,
        reduceMotion: true,
      );
      final submitted = <Map<ZyraPreferenceOption, TrafficLight>>[];
      await harness.mountPresentation(
        child: _ResultFixture(
          confirm: (selections) async => submitted.add(selections),
        ),
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel(capacity: 3).snapshot(),
          tab: 0,
          pages: const [],
        ),
      );
      Future<void> capture(String name) async {
        if (_captures.isNotEmpty) {
          await harness.capture(
            'compatibility',
            'quick_check',
            name,
            name,
            fileName: 'flutter_${name}_$dimensions.png',
          );
        }
      }

      expect(find.text('One quick check first'), findsOneWidget);
      expect(find.byType(ZyraCompatibilityScoreReader), findsNothing);
      expect(
        find.textContaining('never shows anything about Sara'),
        findsOneWidget,
      );
      await capture('needs_check');
      await tester.tap(find.text('Check my answers'));
      await tester.pumpAndSettle();
      expect(find.text('Quick check'), findsOneWidget);
      expect(find.textContaining('Sara'), findsNothing);
      expect(find.text('Done · 6 left'), findsOneWidget);
      await capture('list_initial');
      await tester.tap(find.text('Done · 6 left'));
      await tester.pumpAndSettle();
      expect(find.text('6 left to check.'), findsOneWidget);
      expect(submitted, isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      final scroll = find.descendant(
        of: find.byType(ZyraCompatibilityResultQuickCheck),
        matching: find.byType(Scrollable),
      );
      final expected = <ZyraPreferenceOption, TrafficLight>{};
      for (final (index, option) in [..._visible, ..._hidden].indexed) {
        final light =
            TrafficLight.values[(index + 1) % TrafficLight.values.length];
        final button = find.byKey(ValueKey((option, light)));
        await tester.scrollUntilVisible(button, 180, scrollable: scroll);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        if (index == _visible.length) await capture('list_hidden');
        await tester.tap(button);
        await tester.pumpAndSettle();
        expected[option] = light;
      }
      expect(submitted, isEmpty);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('✓ Done'), findsWidgets);
      await capture('all_done');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(submitted, [expected]);
      expect(find.text('Thank you. Your result is ready.'), findsOneWidget);
      expect(find.byType(ZyraCompatibilityScoreReader), findsOneWidget);
      expect(find.text('76%'), findsOneWidget);
      await capture('result_ready');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('Q116 combined check shows missing and Amber at $dimensions', (
      tester,
    ) async {
      final harness = BaselineHarness(
        tester,
        group: 'q116_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: safePadding,
        reduceMotion: true,
      );
      await harness.mountPresentation(
        child: _ResultFixture(
          missing: const {_missing},
          confirm: (_) async => fail('No lights were tapped.'),
        ),
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel(capacity: 3).snapshot(),
          tab: 0,
          pages: const [],
        ),
      );
      await tester.tap(find.text('Check my answers'));
      await tester.pumpAndSettle();
      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('Done · 7 left'), findsOneWidget);
      expect(find.textContaining('Sara'), findsNothing);
      if (_captures.isNotEmpty) {
        await harness.capture(
          'compatibility',
          'quick_check',
          'result_check_missing_sect',
          'result_check_missing_sect',
          fileName: 'result_check_missing_sect_$dimensions.png',
        );
      }
    });
  }
}

class _ResultFixture extends StatefulWidget {
  const _ResultFixture({required this.confirm, this.missing = const {}});
  final Future<void> Function(Map<ZyraPreferenceOption, TrafficLight>) confirm;
  final Set<ZyraPreferenceOption> missing;

  @override
  State<_ResultFixture> createState() => _ResultFixtureState();
}

class _ResultFixtureState extends State<_ResultFixture> {
  bool _ready = false;

  Future<void> _open() async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ZyraCompatibilityResultQuickCheck(
          isOwnerCurrent: () => mounted,
          load: () async =>
              (visible: _visible, hidden: _hidden, missing: widget.missing),
          confirm: widget.confirm,
        ),
      ),
    );
    if (!mounted || completed != true) return;
    setState(() => _ready = true);
    showZyraPreferenceToast(context, 'Thank you. Your result is ready.');
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ZyraAppGoldDecoration(
      gradient: ZyraColors.genderGradient('male'),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _ready
              ? const ZyraDraftCompatibilityPresentation(
                  personName: 'Sara',
                  balance: 0,
                  overallScore: 76,
                  revealed: true,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Compatibility score',
                      style: ZyraText.heading(size: 26),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ZyraCompatibilityCheckCard(
                        personName: 'Sara',
                        onCheck: _open,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
