import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  test('profile answer groups cover each compatibility category once', () {
    final grouped = <String>[
      ...CompatibilityEditorKind.aboutYou.categoryIds,
      ...CompatibilityEditorKind.lifestyle.categoryIds,
      ...CompatibilityEditorKind.marriagePreferences.categoryIds,
    ];

    expect(grouped.toSet(), hasLength(chapter3Categories.length));
    expect(grouped, hasLength(chapter3Categories.length));
    expect(grouped.toSet(), {
      for (final category in chapter3Categories) category.id,
    });
  });

  testWidgets('about-you answer edits are retained in the complete draft', (
    tester,
  ) async {
    final initial = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
    ZyraCompatibilityDraft? persisted;
    await tester.pumpWidget(
      MaterialApp(
        home: CompatibilityEditorScreen(
          kind: CompatibilityEditorKind.aboutYou,
          initialDraft: initial,
          onPersist: (draft) async {
            persisted = draft.copy();
            return true;
          },
        ),
      ),
    );

    final category = chapter3Categories.firstWhere(
      (item) => item.id == 'deen_practice',
    );
    final question = category.questions.firstWhere(
      (item) => item.visibleFor('male'),
    );
    await tester.tap(find.byKey(ValueKey('edit-category-${category.id}')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('edit-answer-${question.responseKey}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(question.options.first));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('question-save')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compatibility-save')));
    await tester.pumpAndSettle();

    expect(persisted, isNotNull);
    expect(persisted!.answers[question.responseKey], question.options.first);
  });

  testWidgets('traffic-light editor saves every option and hard exclusions', (
    tester,
  ) async {
    final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
    final category = chapter3Categories.firstWhere(
      (item) => draft.preferenceQuestions(item).isNotEmpty,
    );
    final question = draft.preferenceQuestions(category).first;
    draft.preferences[question.responseKey] = {
      for (final option in question.options) option: TrafficLight.red,
    };
    ZyraCompatibilityDraft? persisted;

    await tester.pumpWidget(
      MaterialApp(
        home: CompatibilityEditorScreen(
          kind: CompatibilityEditorKind.hardRequirements,
          initialDraft: draft,
          onPersist: (value) async {
            persisted = value.copy();
            return true;
          },
        ),
      ),
    );

    final option = question.options.first;
    final hardOption = find.byKey(
      ValueKey('hard-option-${question.responseKey}-$option'),
    );
    await tester.ensureVisible(hardOption);
    await tester.tap(hardOption);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('compatibility-save')));
    await tester.pumpAndSettle();

    expect(persisted!.hardRequirements[question.responseKey], contains(option));
    expect(
      persisted!.preferences[question.responseKey]![option],
      TrafficLight.red,
    );
  });
}
