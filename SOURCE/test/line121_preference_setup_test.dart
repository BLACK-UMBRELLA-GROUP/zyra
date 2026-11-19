// LOCK 34: partial setup choices save locally through a caller-owned draft.
// This harness uses no authenticated repository, provider or network service.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/dev/zyra_signup_preferences_preview.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/onboarding/traffic_light_question_screen.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/theme/zyra_text.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

class _SetupFixture extends ChangeNotifier {
  final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
  final root = GlobalKey<NavigatorState>();
  final inner = GlobalKey<NavigatorState>();
  final snapshots = <ZyraCompatibilityDraft>[];
  late ModalRoute<dynamic> rootRoute;
  var retained = true;
  var explicitSaves = 0;

  bool canAct() => retained && rootRoute.isCurrent;
  bool canRetain() => retained;
  void revoke() {
    retained = false;
    notifyListeners();
  }

  void changed(ZyraCompatibilityDraft value) => snapshots.add(value);
  Future<bool> persist(ZyraCompatibilityDraft value) async {
    explicitSaves++;
    return true;
  }

  Widget app({bool setup = true}) => MaterialApp(
    navigatorKey: root,
    home: Builder(
      builder: (context) {
        rootRoute = ModalRoute.of(context)!;
        return Scaffold(
          body: Navigator(
            key: inner,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => CompatibilityEditorScreen.preview(
                kind: CompatibilityEditorKind.trafficLights,
                initialDraft: draft,
                onPersist: persist,
                canAct: canAct,
                canRetain: canRetain,
                canActChanges: this,
                preferenceSetup: setup,
                onPreferenceChanged: changed,
              ),
            ),
          ),
        );
      },
    ),
  );

  (OnboardingCategory, OnboardingQuestion) get first {
    for (final category in chapter3Categories) {
      for (final question in draft.preferenceQuestions(category)) {
        if (question.hardRequirementSupported) return (category, question);
      }
    }
    throw StateError('The current bank has no preference question.');
  }

  Future<TrafficLightQuestionScreen> openQuestion(WidgetTester tester) async {
    final (category, question) = first;
    await tester.tap(_key('edit-preferences-${category.id}'));
    await tester.pumpAndSettle();
    await tester.tap(_key('edit-lights-${question.responseKey}'));
    await tester.pumpAndSettle();
    return tester.widget<TrafficLightQuestionScreen>(
      find.byType(TrafficLightQuestionScreen),
    );
  }
}

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  Future<_SetupFixture> mount(WidgetTester tester, {bool setup = true}) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = _SetupFixture();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.dispose();
    });
    await tester.pumpWidget(fixture.app(setup: setup));
    await tester.pumpAndSettle();
    return fixture;
  }

  testWidgets('partial setup light and hard choices emit detached drafts', (
    tester,
  ) async {
    final fixture = await mount(tester);
    expect(_key('compatibility-save'), findsNothing);
    await fixture.openQuestion(tester);
    final question = fixture.first.$2;
    final option = question.options.first;
    await tester.tap(_key('preference_${option}_red'));
    await tester.pumpAndSettle();
    expect(fixture.snapshots, hasLength(1));
    expect(fixture.snapshots.last.valuesFor(question), {
      option: TrafficLight.red,
    });
    expect(fixture.snapshots.last.preferenceAnswerCount, 1);
    expect(fixture.draft.valuesFor(question), isEmpty);
    expect(
      tester.widget<FilledButton>(_key('question-save')).onPressed,
      isNull,
    );

    final hard = find.text('Never introduce anyone who answered "$option".');
    await tester.ensureVisible(hard);
    await tester.tap(hard);
    await tester.pumpAndSettle();
    expect(fixture.snapshots.last.hardRequirementsFor(question), {option});
    final beforeGreen = fixture.snapshots.length;
    await tester.tap(_key('preference_${option}_green'));
    await tester.pumpAndSettle();
    expect(fixture.snapshots, hasLength(beforeGreen + 1));
    expect(fixture.snapshots.last.hardRequirementsFor(question), isEmpty);
    expect(fixture.snapshots.last.valuesFor(question), {
      option: TrafficLight.green,
    });
    expect(fixture.explicitSaves, 0);

    // Mutating a delivered snapshot cannot change the editor's retained copy.
    fixture.snapshots.last.preferences.clear();
    fixture.inner.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.tap(_key('edit-lights-${question.responseKey}'));
    await tester.pumpAndSettle();
    final reopened = tester.widget<TrafficLightQuestionScreen>(
      find.byType(TrafficLightQuestionScreen),
    );
    expect(reopened.initialValues[option], TrafficLight.green);
  });

  testWidgets(
    'temporary outer coverage preserves partial draft and denies edits',
    (tester) async {
      final fixture = await mount(tester);
      final questionWidget = await fixture.openQuestion(tester);
      final question = fixture.first.$2;
      final option = question.options.first;
      questionWidget.onChanged({option: TrafficLight.green});
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(TrafficLightQuestionScreen));
      final beforeCover = fixture.snapshots.length;
      unawaited(
        fixture.root.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Developer cover')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(fixture.rootRoute.isCurrent, isFalse);
      questionWidget.onChanged({option: TrafficLight.red});
      questionWidget.onHardRequirementChanged({option});
      await tester.pumpAndSettle();
      expect(fixture.snapshots, hasLength(beforeCover));
      fixture.root.currentState!.pop();
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(TrafficLightQuestionScreen)),
        same(state),
      );
      expect(_key('compatibility_editor_preview_denied'), findsNothing);
      questionWidget.onChanged({option: TrafficLight.yellow});
      await tester.pumpAndSettle();
      expect(fixture.snapshots.last.valuesFor(question), {
        option: TrafficLight.yellow,
      });
    },
  );

  testWidgets('revoked setup callbacks cannot emit after the caller returns', (
    tester,
  ) async {
    final fixture = await mount(tester);
    final old = await fixture.openQuestion(tester);
    final option = fixture.first.$2.options.first;
    old.onChanged({option: TrafficLight.green});
    await tester.pumpAndSettle();
    final beforeRevoke = fixture.snapshots.length;
    fixture.revoke();
    await tester.pumpAndSettle();
    fixture.retained = true;
    old.onChanged({option: TrafficLight.red});
    old.onHardRequirementChanged({option});
    await tester.pumpAndSettle();
    expect(fixture.snapshots, hasLength(beforeRevoke));
    expect(fixture.explicitSaves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary preview keeps explicit save without setup emissions', (
    tester,
  ) async {
    final fixture = await mount(tester, setup: false);
    expect(_key('compatibility-save'), findsOneWidget);
    final page = await fixture.openQuestion(tester);
    page.onChanged({fixture.first.$2.options.first: TrafficLight.green});
    await tester.pumpAndSettle();
    expect(fixture.snapshots, isEmpty);
    expect(fixture.explicitSaves, 0);
  });

  for (final binding in ['setup mode', 'change callback']) {
    testWidgets('changed setup $binding permanently retires its editor', (
      tester,
    ) async {
      final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
      final snapshots = <ZyraCompatibilityDraft>[];
      bool guard() => true;
      Future<bool> persist(ZyraCompatibilityDraft value) async => true;
      void original(ZyraCompatibilityDraft value) => snapshots.add(value);
      void replacement(ZyraCompatibilityDraft value) => snapshots.add(value);
      Widget app({bool changed = false}) => MaterialApp(
        home: CompatibilityEditorScreen.preview(
          key: const ValueKey('setup-binding-owner'),
          kind: CompatibilityEditorKind.trafficLights,
          initialDraft: draft,
          onPersist: persist,
          canAct: guard,
          preferenceSetup: !(changed && binding == 'setup mode'),
          onPreferenceChanged: changed && binding == 'change callback'
              ? replacement
              : original,
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(_key('compatibility_editor_preview_denied'), findsNothing);
      final state = tester.state(find.byType(CompatibilityEditorScreen));
      await tester.pumpWidget(app(changed: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(CompatibilityEditorScreen)), same(state));
      expect(_key('compatibility_editor_preview_denied'), findsOneWidget);
      expect(snapshots, isEmpty);
    });
  }

  testWidgets('narrow two-times text keeps setup actions and bank reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
    final category = chapter3Categories.firstWhere(
      (value) => draft.preferenceQuestions(value).isNotEmpty,
    );
    final question = draft.preferenceQuestions(category).first;
    var next = 0, later = 0;
    final changes = <ZyraCompatibilityDraft>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: ZyraSignupPreferencesPreview(
            initialDraft: draft,
            canAct: () => true,
            canRetain: () => true,
            onChanged: changes.add,
            onNext: () => next++,
            onLater: () => later++,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_key('signup_preferences_next').hitTestable(), findsOneWidget);
    expect(_key('signup_preferences_later').hitTestable(), findsOneWidget);
    final lastCategory = chapter3Categories.lastWhere(
      (value) => draft.preferenceQuestions(value).isNotEmpty,
    );
    final lastDoor = _key('edit-preferences-${lastCategory.id}');
    await tester.scrollUntilVisible(
      lastDoor,
      150,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 100,
    );
    await tester.ensureVisible(lastDoor);
    await tester.pumpAndSettle();
    expect(lastDoor.hitTestable(), findsOneWidget);
    final categoryDoor = _key('edit-preferences-${category.id}');
    await tester.scrollUntilVisible(
      categoryDoor,
      -150,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 100,
    );
    await Scrollable.ensureVisible(tester.element(categoryDoor), alignment: .5);
    await tester.pumpAndSettle();
    expect(categoryDoor.hitTestable(), findsOneWidget);
    await tester.tap(categoryDoor);
    await tester.pumpAndSettle();
    final questionDoor = _key('edit-lights-${question.responseKey}');
    await tester.scrollUntilVisible(
      questionDoor,
      100,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 100,
    );
    await tester.ensureVisible(questionDoor);
    await tester.pumpAndSettle();
    expect(questionDoor.hitTestable(), findsOneWidget);
    await tester.tap(questionDoor);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final choice = _key('preference_${question.options.first}_green');
    await tester.scrollUntilVisible(
      choice,
      100,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 100,
    );
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    expect(find.byType(TrafficLightQuestionScreen), findsOneWidget);
    expect(choice.hitTestable(), findsOneWidget);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(changes.last.preferenceAnswerCount, 1);
    expect(_key('signup_preferences_next').hitTestable(), findsOneWidget);
    expect(_key('signup_preferences_later').hitTestable(), findsOneWidget);
    await tester.tap(_key('signup_preferences_next'));
    await tester.tap(_key('signup_preferences_later'));
    await tester.pumpAndSettle();
    expect(next, 1);
    expect(later, 1);
    expect(tester.takeException(), isNull);
  });
}
