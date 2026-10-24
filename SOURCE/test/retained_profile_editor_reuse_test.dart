import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/onboarding/generic_select_question_screen.dart';
import 'package:zyra/screens/onboarding/traffic_light_question_screen.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

class _LocalEditorRepository implements ZyraCompatibilityEditorRepository {
  @override
  String? currentUserId = 'local-editor-owner';
  @override
  int accountGeneration = 7;
  bool failOwnerCheck = false;
  int loads = 0;
  final savedOwners = <String>[];
  final candidates = <ZyraCompatibilityDraft>[];
  ZyraOnboardingAnswersSnapshot? stored;
  Future<ZyraOnboardingAnswersSnapshot?> Function()? onLoad;
  Future<bool> Function()? onSave;

  @override
  bool isCurrentOwner(String userId, int generation) {
    if (failOwnerCheck) throw StateError('Owner check failed');
    return userId == currentUserId && generation == accountGeneration;
  }

  @override
  Future<ZyraOnboardingAnswersSnapshot?> load(String userId) async {
    expect(userId, 'local-editor-owner');
    ++loads;
    if (onLoad != null) return onLoad!();
    return stored;
  }

  @override
  Future<bool> save(String userId, ZyraCompatibilityDraft draft) async {
    savedOwners.add(userId);
    candidates.add(draft);
    final generation = accountGeneration;
    final checkpoint = draft.toSnapshot();
    final success = onSave == null ? true : await onSave!();
    if (success && isCurrentOwner(userId, generation)) stored = checkpoint;
    return success;
  }
}

class _Owner {
  bool allowed = true;
  bool exceptional = false;
  bool canAct() {
    if (exceptional) throw StateError('The caller owner failed');
    return allowed;
  }
}

void _viewport(WidgetTester tester, [Size size = const Size(393, 852)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget home, {GlobalKey<NavigatorState>? navigatorKey}) =>
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData.dark(),
      home: Scaffold(body: home),
    );

Widget _hub(_LocalEditorRepository repository, _Owner owner) =>
    EditProfileScreen.preview(
      key: const ValueKey('retained-profile'),
      repository: repository,
      canAct: owner.canAct,
      gender: 'female',
      age: 29,
    );

Future<void> _mountHub(
  WidgetTester tester,
  _LocalEditorRepository repository,
  _Owner owner, {
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  await tester.pumpWidget(
    _app(_hub(repository, owner), navigatorKey: navigatorKey),
  );
  await tester.pumpAndSettle();
}

Future<void> _openHubEditor(
  WidgetTester tester, [
  CompatibilityEditorKind kind = CompatibilityEditorKind.aboutYou,
]) async {
  final door = find.byKey(ValueKey('compatibility-editor-${kind.name}'));
  await tester.ensureVisible(door);
  await tester.tap(door);
  await tester.pumpAndSettle();
}

Future<void> _returnWithEdgeSwipe(WidgetTester tester) async {
  final back = find.byKey(const ValueKey('zyra_visible_back_button'));
  expect(back, findsNothing);
  await swipeZyraBack(tester);
}

Future<void> _mountEditor(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigator,
  _Owner owner,
  Future<bool> Function(ZyraCompatibilityDraft) persist, {
  ZyraCompatibilityDraft? draft,
  CompatibilityEditorKind kind = CompatibilityEditorKind.aboutYou,
}) async {
  final initial =
      draft ?? ZyraCompatibilityDraft.fromSnapshot(gender: 'female');
  await tester.pumpWidget(_app(const Text('Parent'), navigatorKey: navigator));
  unawaited(
    navigator.currentState!.push<ZyraCompatibilityDraft>(
      MaterialPageRoute(
        builder: (_) => CompatibilityEditorScreen.preview(
          kind: kind,
          initialDraft: initial,
          onPersist: persist,
          canAct: owner.canAct,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

OnboardingCategory get _deen =>
    chapter3Categories.firstWhere((category) => category.id == 'deen_practice');
OnboardingQuestion get _firstQuestion =>
    _deen.questions.firstWhere((question) => question.visibleFor('female'));

Future<GenericSelectQuestionScreen> _openQuestion(WidgetTester tester) async {
  await tester.tap(find.byKey(ValueKey('edit-category-${_deen.id}')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(ValueKey('edit-answer-${_firstQuestion.responseKey}')),
  );
  await tester.pumpAndSettle();
  return tester.widget<GenericSelectQuestionScreen>(
    find.byType(GenericSelectQuestionScreen),
  );
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.finishSignOut();
  });
  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraText.useTestFontStubs = false;
  });

  test(
    'draft checkpoints detach all mutable answers, preferences and hard sets',
    () {
      final multi = chapter3Categories
          .expand((category) => category.questions)
          .firstWhere(
            (question) =>
                question.selectionType == QuestionSelectionType.multi &&
                question.visibleFor('female'),
          );
      final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'female');
      draft.answers[multi.responseKey] = <String>[multi.options.first];
      draft.answers['bio_fields'] = <String, String>{'occupation': 'Teacher'};
      draft.answers['bio_visible_field_ids'] = <String>['occupation'];
      draft.preferences[multi.responseKey] = {
        multi.options.first: TrafficLight.red,
      };
      draft.hardRequirements[multi.responseKey] = {multi.options.first};
      final copy = draft.copy();
      final checkpoint = draft.toSnapshot();
      (draft.answers[multi.responseKey] as List<String>).clear();
      (draft.answers['bio_fields'] as Map<String, String>)['occupation'] =
          'Changed';
      draft.preferences[multi.responseKey]!.clear();
      draft.hardRequirements[multi.responseKey]!.clear();
      expect(copy.answers[multi.responseKey], <String>[multi.options.first]);
      expect(copy.answers[multi.responseKey], isA<List<String>>());
      expect(copy.answers['bio_fields'], {'occupation': 'Teacher'});
      final restored = ZyraCompatibilityDraft.fromSnapshot(
        gender: 'female',
        snapshot: checkpoint,
      );
      expect(restored.answers[multi.responseKey], <String>[
        multi.options.first,
      ]);
      expect(restored.answers[multi.responseKey], isA<List<String>>());
      expect(
        restored.preferences[multi.responseKey]![multi.options.first],
        TrafficLight.red,
      );
      expect(restored.hardRequirements[multi.responseKey], {
        multi.options.first,
      });
      expect(checkpoint.journeyBio.fieldValues, {'occupation': 'Teacher'});
      (restored.answers[multi.responseKey] as List<String>).clear();
      (restored.answers['bio_fields'] as Map)['occupation'] = 'Also changed';
      expect(checkpoint.ch3Answers[multi.id], <String>[multi.options.first]);
      expect(checkpoint.journeyBio.fieldValues, {'occupation': 'Teacher'});
    },
  );

  for (final gender in ['female', 'male']) {
    test(
      'checkpoint uses canonical q26 for $gender without the hidden variant',
      () {
        final variants = chapter3Categories
            .expand((category) => category.questions)
            .where((question) => question.id == 'ch3_q26')
            .toList();
        final visible = variants.singleWhere(
          (question) => question.visibleFor(gender),
        );
        final hidden = variants.singleWhere(
          (question) => !question.visibleFor(gender),
        );
        final draft = ZyraCompatibilityDraft.fromSnapshot(gender: gender);
        draft.answers[visible.responseKey] = visible.options.first;
        draft.preferences[visible.responseKey] = {
          visible.options.first: TrafficLight.red,
        };
        draft.hardRequirements[visible.responseKey] = {visible.options.first};
        final checkpoint = draft.toSnapshot();
        expect(checkpoint.ch3Answers['ch3_q26'], visible.options.first);
        expect(checkpoint.ch3Answers.containsKey(visible.responseKey), isFalse);
        final restored = ZyraCompatibilityDraft.fromSnapshot(
          gender: gender,
          snapshot: checkpoint,
        );
        expect(restored.answers[visible.responseKey], visible.options.first);
        expect(restored.answers.containsKey(hidden.responseKey), isFalse);
        expect(
          restored.preferences[visible.responseKey]![visible.options.first],
          TrafficLight.red,
        );
        expect(restored.hardRequirements[visible.responseKey], {
          visible.options.first,
        });
      },
    );
  }

  for (final globalPreview in [false, true]) {
    testWidgets(
      'explicit hub uses only its repository with global preview $globalPreview',
      (tester) async {
        _viewport(tester);
        if (globalPreview) ZyraInternalPreviewClient.beginPreview();
        final globalBio = AppState.instance.journeyBio;
        final globalGender = AppState.instance.gender;
        final globalAge = AppState.instance.age;
        final repository = _LocalEditorRepository()
          ..stored = const ZyraOnboardingAnswersSnapshot(
            ch3Answers: {},
            ch4Preferences: {},
            ch4HardRequirements: {},
            journeyBio: JourneyBio(aboutMe: 'Own local biography'),
          );
        final owner = _Owner();
        await _mountHub(tester, repository, owner);
        expect(repository.loads, 1);
        for (final kind in CompatibilityEditorKind.values) {
          expect(
            find.byKey(ValueKey('compatibility-editor-${kind.name}')),
            findsOneWidget,
          );
        }
        final title = tester.widget<Text>(
          find.byKey(const ValueKey('edit_profile_preview_title')),
        );
        expect(title.style!.fontSize, 28);
        expect(
          tester.getTopLeft(
            find.byKey(const ValueKey('edit_profile_preview_title')),
          ),
          const Offset(20, 16),
        );
        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(BackButton), findsNothing);
        expect(
          tester
              .widget<Material>(
                find
                    .ancestor(
                      of: find.byKey(
                        const ValueKey('edit_profile_preview_title'),
                      ),
                      matching: find.byType(Material),
                    )
                    .first,
              )
              .color,
          Colors.transparent,
        );
        expect(
          tester
              .widgetList<DecoratedBox>(find.byType(DecoratedBox))
              .where((box) => box.decoration is ZyraAppGoldDecoration),
          isEmpty,
        );
        await tester.ensureVisible(find.text('Age 29'));
        expect(find.text('Sister'), findsOneWidget);
        await _openHubEditor(tester);
        final editor = tester.widget<CompatibilityEditorScreen>(
          find.byType(CompatibilityEditorScreen),
        );
        expect(await editor.onPersist(editor.initialDraft), isTrue);
        expect(repository.savedOwners, ['local-editor-owner']);
        expect(identical(AppState.instance.journeyBio, globalBio), isTrue);
        expect(AppState.instance.gender, globalGender);
        expect(AppState.instance.age, globalAge);
      },
    );
  }

  testWidgets(
    'actual retained answer renderer saves and restores through the same hub',
    (tester) async {
      _viewport(tester);
      final repository = _LocalEditorRepository();
      await _mountHub(tester, repository, _Owner());
      await _openHubEditor(tester);
      expect(find.byType(ZyraPullDownBackScope), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      final renderer = await _openQuestion(tester);
      expect(renderer.guidedChoices, isFalse);
      await tester.tap(find.text(_firstQuestion.options.first));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('question-save')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('edit-answer-${_firstQuestion.responseKey}')),
        findsOneWidget,
      );
      await _returnWithEdgeSwipe(tester);
      expect(find.byKey(ValueKey('edit-category-${_deen.id}')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('edit_profile_preview_title')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('compatibility-save')));
      await tester.pumpAndSettle();
      expect(repository.savedOwners, ['local-editor-owner']);
      expect(
        repository.stored!.ch3Answers[_firstQuestion.id],
        _firstQuestion.options.first,
      );
      await _openHubEditor(tester);
      final reopened = tester.widget<CompatibilityEditorScreen>(
        find.byType(CompatibilityEditorScreen),
      );
      expect(
        reopened.initialDraft.answers[_firstQuestion.responseKey],
        _firstQuestion.options.first,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'same route dependency rebuild does not replace the editor owner',
    (tester) async {
      _viewport(tester);
      final navigator = GlobalKey<NavigatorState>();
      final repository = _LocalEditorRepository();
      final owner = _Owner();
      await _mountHub(tester, repository, owner, navigatorKey: navigator);
      await _openHubEditor(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 1.1;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('compatibility_editor_preview_denied')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('compatibility-save')));
      await tester.pumpAndSettle();
      expect(repository.savedOwners, ['local-editor-owner']);
      expect(
        find.byKey(const ValueKey('edit_profile_preview_title')),
        findsOneWidget,
      );
    },
  );

  testWidgets('failed local restore stays non-writable and can retry', (
    tester,
  ) async {
    _viewport(tester);
    final repository = _LocalEditorRepository()
      ..onLoad = () async => throw StateError('Failed restore');
    await _mountHub(tester, repository, _Owner());
    expect(
      find.byKey(const ValueKey('edit_profile_load_error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compatibility-editor-aboutYou')),
      findsNothing,
    );
    repository.onLoad = null;
    await tester.tap(find.byKey(const ValueKey('edit_profile_restore_retry')));
    await tester.pumpAndSettle();
    expect(repository.loads, 2);
    expect(
      find.byKey(const ValueKey('compatibility-editor-aboutYou')),
      findsOneWidget,
    );
    expect(repository.savedOwners, isEmpty);
  });

  testWidgets(
    'covered restore completion is discarded and retry remains possible',
    (tester) async {
      _viewport(tester);
      final navigator = GlobalKey<NavigatorState>();
      final pending = Completer<ZyraOnboardingAnswersSnapshot?>();
      final repository = _LocalEditorRepository()
        ..onLoad = () => pending.future;
      final owner = _Owner();
      await tester.pumpWidget(
        _app(_hub(repository, owner), navigatorKey: navigator),
      );
      await tester.pump();
      unawaited(
        navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Cover')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      pending.complete(
        const ZyraOnboardingAnswersSnapshot(
          ch3Answers: {},
          ch4Preferences: {},
          ch4HardRequirements: {},
          journeyBio: JourneyBio(aboutMe: 'Stale private biography'),
        ),
      );
      await tester.pump();
      expect(find.text('Cover'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('compatibility-editor-aboutYou')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('edit_profile_restore_retry')),
        findsOneWidget,
      );
      repository.onLoad = null;
      await tester.tap(
        find.byKey(const ValueKey('edit_profile_restore_retry')),
      );
      await tester.pumpAndSettle();
      expect(repository.loads, 2);
    },
  );

  testWidgets('account generation change rejects a pending local restore', (
    tester,
  ) async {
    _viewport(tester);
    final pending = Completer<ZyraOnboardingAnswersSnapshot?>();
    final repository = _LocalEditorRepository()..onLoad = () => pending.future;
    final owner = _Owner();
    await tester.pumpWidget(_app(_hub(repository, owner)));
    await tester.pump();
    repository.accountGeneration += 2;
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('edit_profile_preview_denied')),
      findsOneWidget,
    );
    repository.accountGeneration = 7;
    await tester.pumpWidget(_app(_hub(repository, owner)));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('edit_profile_preview_denied')),
      findsOneWidget,
    );
    expect(repository.savedOwners, isEmpty);
  });

  testWidgets('disposed restore completion cannot hydrate account state', (
    tester,
  ) async {
    _viewport(tester);
    final bio = AppState.instance.journeyBio;
    final pending = Completer<ZyraOnboardingAnswersSnapshot?>();
    final repository = _LocalEditorRepository()..onLoad = () => pending.future;
    await tester.pumpWidget(_app(_hub(repository, _Owner())));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete(
      const ZyraOnboardingAnswersSnapshot(
        ch3Answers: {},
        ch4Preferences: {},
        ch4HardRequirements: {},
        journeyBio: JourneyBio(aboutMe: 'Disposed biography'),
      ),
    );
    await tester.pump();
    expect(identical(AppState.instance.journeyBio, bio), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final exceptional in [false, true]) {
    testWidgets(
      'caller ${exceptional ? 'exception' : 'revocation'} is sticky for hub and captured save',
      (tester) async {
        _viewport(tester);
        final repository = _LocalEditorRepository();
        final owner = _Owner();
        await _mountHub(tester, repository, owner);
        await _openHubEditor(tester);
        final editor = tester.widget<CompatibilityEditorScreen>(
          find.byType(CompatibilityEditorScreen),
        );
        if (exceptional) {
          owner.exceptional = true;
        } else {
          owner.allowed = false;
        }
        expect(await editor.onPersist(editor.initialDraft), isFalse);
        owner.exceptional = false;
        owner.allowed = true;
        expect(await editor.onPersist(editor.initialDraft), isFalse);
        expect(repository.savedOwners, isEmpty);
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('edit_profile_preview_denied')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('exceptional repository guard is permanent denial', (
    tester,
  ) async {
    _viewport(tester);
    final repository = _LocalEditorRepository();
    final owner = _Owner();
    await _mountHub(tester, repository, owner);
    repository.failOwnerCheck = true;
    await tester.pumpWidget(_app(_hub(repository, owner)));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('edit_profile_preview_denied')),
      findsOneWidget,
    );
    repository.failOwnerCheck = false;
    await tester.pumpWidget(_app(_hub(repository, owner)));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('edit_profile_preview_denied')),
      findsOneWidget,
    );
    expect(repository.loads, 1);
  });

  testWidgets(
    'rebinding explicit hub to default cannot enable legacy transport',
    (tester) async {
      _viewport(tester);
      final repository = _LocalEditorRepository();
      final owner = _Owner();
      await _mountHub(tester, repository, owner);
      await tester.pumpWidget(
        _app(
          EditProfileScreen(
            key: const ValueKey('retained-profile'),
            repository: repository,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('edit_profile_preview_denied')),
        findsOneWidget,
      );
      await tester.pumpWidget(_app(_hub(repository, owner)));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('edit_profile_preview_denied')),
        findsOneWidget,
      );
      expect(repository.loads, 1);
      expect(repository.savedOwners, isEmpty);
    },
  );

  testWidgets('duplicate Save changes presses issue one detached local write', (
    tester,
  ) async {
    _viewport(tester);
    final pending = Completer<bool>();
    final repository = _LocalEditorRepository()..onSave = () => pending.future;
    await _mountHub(tester, repository, _Owner());
    await _openHubEditor(tester);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('compatibility-save')),
    );
    button.onPressed!();
    button.onPressed!();
    await tester.pump();
    expect(repository.savedOwners, ['local-editor-owner']);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('compatibility-save')),
          )
          .onPressed,
      isNull,
    );
    final editor = tester.widget<CompatibilityEditorScreen>(
      find.byType(CompatibilityEditorScreen),
    );
    expect(
      identical(
        repository.candidates.single.answers,
        editor.initialDraft.answers,
      ),
      isFalse,
    );
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('edit_profile_preview_title')),
      findsOneWidget,
    );
  });

  testWidgets('failed asynchronous save remains open and safely retries', (
    tester,
  ) async {
    _viewport(tester);
    final repository = _LocalEditorRepository()
      ..onSave = () async => throw StateError('Local store failure');
    await _mountHub(tester, repository, _Owner());
    await _openHubEditor(tester);
    await tester.tap(find.byKey(const ValueKey('compatibility-save')));
    await tester.pumpAndSettle();
    expect(
      find.text('Your changes could not be saved. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('compatibility-save')),
          )
          .onPressed,
      isNotNull,
    );
    repository.onSave = null;
    // The transient failure message overlays the bottom Save control until
    // its normal duration expires. Retry through a genuinely visible tap.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('compatibility-save'));
    await tester.ensureVisible(save);
    expect(save.hitTestable(), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.savedOwners, [
      'local-editor-owner',
      'local-editor-owner',
    ]);
    expect(
      find.byKey(const ValueKey('edit_profile_preview_title')),
      findsOneWidget,
    );
  });

  testWidgets(
    'generation change during save cannot return a successful draft',
    (tester) async {
      _viewport(tester);
      final pending = Completer<bool>();
      final repository = _LocalEditorRepository()
        ..onSave = () => pending.future;
      await _mountHub(tester, repository, _Owner());
      await _openHubEditor(tester);
      await tester.tap(find.byKey(const ValueKey('compatibility-save')));
      await tester.pump();
      repository.accountGeneration += 2;
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('edit_profile_preview_title')),
        findsNothing,
      );
      expect(find.byType(CompatibilityEditorScreen), findsOneWidget);
      expect(repository.stored, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'foreign cover during save prevents delayed pop of either route',
    (tester) async {
      _viewport(tester);
      final navigator = GlobalKey<NavigatorState>();
      final pending = Completer<bool>();
      int writes = 0;
      Future<bool> persist(ZyraCompatibilityDraft draft) {
        ++writes;
        return pending.future;
      }

      await _mountEditor(tester, navigator, _Owner(), persist);
      await tester.tap(find.byKey(const ValueKey('compatibility-save')));
      await tester.pump();
      unawaited(
        navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Cover')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.byType(CompatibilityEditorScreen), findsOneWidget);
      expect(find.text('Parent'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('compatibility-save')),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposed save completion has no navigation or setState effect', (
    tester,
  ) async {
    _viewport(tester);
    final navigator = GlobalKey<NavigatorState>();
    final pending = Completer<bool>();
    Future<bool> persist(ZyraCompatibilityDraft draft) => pending.future;
    await _mountEditor(tester, navigator, _Owner(), persist);
    await tester.tap(find.byKey(const ValueKey('compatibility-save')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('revoked nested answer callbacks cannot update or save a draft', (
    tester,
  ) async {
    _viewport(tester);
    final repository = _LocalEditorRepository();
    final owner = _Owner();
    await _mountHub(tester, repository, owner);
    await _openHubEditor(tester);
    final renderer = await _openQuestion(tester);
    renderer.onChanged(_firstQuestion.options.first);
    await tester.pump();
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('question-save')),
    );
    expect(save.onPressed, isNotNull);
    owner.allowed = false;
    renderer.onChanged(_firstQuestion.options.first);
    save.onPressed?.call();
    owner.allowed = true;
    renderer.onChanged(_firstQuestion.options.first);
    save.onPressed?.call();
    await tester.pump();
    expect(find.byType(GenericSelectQuestionScreen), findsNothing);
    expect(find.byKey(const ValueKey('question-save')), findsNothing);
    expect(
      find.byKey(const ValueKey('compatibility_editor_preview_denied')),
      findsWidgets,
    );
    expect(repository.savedOwners, isEmpty);
    expect(repository.candidates, isEmpty);
    expect(repository.stored, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed nested answer callback is inert', (tester) async {
    _viewport(tester);
    await _mountHub(tester, _LocalEditorRepository(), _Owner());
    await _openHubEditor(tester);
    final renderer = await _openQuestion(tester);
    await tester.pumpWidget(const SizedBox());
    renderer.onChanged(_firstQuestion.options.first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final exceptional in [false, true]) {
    testWidgets(
      'retained child Save denies ${exceptional ? 'exceptional' : 'revoked'} owner before transport',
      (tester) async {
        _viewport(tester);
        final owner = _Owner();
        var writes = 0;
        Future<bool> persist(ZyraCompatibilityDraft value) async {
          ++writes;
          return true;
        }

        await _mountEditor(tester, GlobalKey<NavigatorState>(), owner, persist);
        final save = tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('compatibility-save')),
            )
            .onPressed!;
        if (exceptional) {
          owner.exceptional = true;
        } else {
          owner.allowed = false;
        }
        save();
        await tester.pump();
        owner.allowed = true;
        owner.exceptional = false;
        save();
        await tester.pump();
        expect(writes, 0);
        expect(find.byType(CompatibilityEditorScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('retained child cannot be rebound into a legacy editor', (
    tester,
  ) async {
    _viewport(tester);
    final owner = _Owner();
    final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'female');
    var writes = 0;
    Future<bool> persist(ZyraCompatibilityDraft value) async {
      ++writes;
      return true;
    }

    Widget preview() => _app(
      CompatibilityEditorScreen.preview(
        key: const ValueKey('sticky-child'),
        kind: CompatibilityEditorKind.aboutYou,
        initialDraft: draft,
        onPersist: persist,
        canAct: owner.canAct,
      ),
    );
    await tester.pumpWidget(preview());
    await tester.pump();
    final save = tester
        .widget<FilledButton>(find.byKey(const ValueKey('compatibility-save')))
        .onPressed!;
    await tester.pumpWidget(
      _app(
        CompatibilityEditorScreen(
          key: const ValueKey('sticky-child'),
          kind: CompatibilityEditorKind.aboutYou,
          initialDraft: draft,
          onPersist: persist,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('compatibility_editor_preview_denied')),
      findsOneWidget,
    );
    await tester.pumpWidget(preview());
    await tester.pump();
    save();
    await tester.pump();
    expect(writes, 0);
    expect(
      find.byKey(const ValueKey('compatibility_editor_preview_denied')),
      findsOneWidget,
    );
  });

  testWidgets(
    'traffic lights and exclusions reuse their original renderer and private checkpoint',
    (tester) async {
      _viewport(tester);
      final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'female');
      final category = chapter3Categories.firstWhere(
        (category) => draft.preferenceQuestions(category).isNotEmpty,
      );
      final question = draft.preferenceQuestions(category).first;
      draft.preferences[question.responseKey] = {
        for (final option in question.options) option: TrafficLight.red,
      };
      draft.hardRequirements[question.responseKey] = {question.options.first};
      ZyraCompatibilityDraft? checkpoint;
      Future<bool> persist(ZyraCompatibilityDraft value) async {
        checkpoint = value;
        return true;
      }

      await _mountEditor(
        tester,
        GlobalKey<NavigatorState>(),
        _Owner(),
        persist,
        draft: draft,
        kind: CompatibilityEditorKind.trafficLights,
      );
      final categoryDoor = find.byKey(
        ValueKey('edit-preferences-${category.id}'),
      );
      await tester.ensureVisible(categoryDoor);
      await tester.tap(categoryDoor);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('edit-lights-${question.responseKey}')),
      );
      await tester.pumpAndSettle();
      final renderer = tester.widget<TrafficLightQuestionScreen>(
        find.byType(TrafficLightQuestionScreen),
      );
      expect(
        renderer.hardRequirementSupported,
        question.hardRequirementSupported,
      );
      expect(renderer.initialHardRequirement, {question.options.first});
      renderer.onChanged({
        for (final option in question.options) option: TrafficLight.green,
      });
      renderer.onHardRequirementChanged({});
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('question-save')));
      await tester.pumpAndSettle();
      await _returnWithEdgeSwipe(tester);
      await tester.tap(find.byKey(const ValueKey('compatibility-save')));
      await tester.pumpAndSettle();
      expect(
        checkpoint!.preferences[question.responseKey]!.values,
        everyElement(TrafficLight.green),
      );
      expect(
        checkpoint!.hardRequirements.containsKey(question.responseKey),
        isFalse,
      );
      expect(
        draft.preferences[question.responseKey]!.values,
        everyElement(TrafficLight.red),
      );
      expect(draft.hardRequirements[question.responseKey], {
        question.options.first,
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hard exclusions use the retained red-option control and checkpoint',
    (tester) async {
      _viewport(tester);
      final navigator = GlobalKey<NavigatorState>();
      final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'female');
      final question = chapter3Categories
          .expand(draft.preferenceQuestions)
          .firstWhere((question) => question.hardRequirementSupported);
      final option = question.options.first;
      draft.preferences[question.responseKey] = {option: TrafficLight.red};
      ZyraCompatibilityDraft? checkpoint;
      Future<bool> persist(ZyraCompatibilityDraft value) async {
        checkpoint = value;
        return true;
      }

      await _mountEditor(
        tester,
        navigator,
        _Owner(),
        persist,
        draft: draft,
        kind: CompatibilityEditorKind.hardRequirements,
      );
      final optionFinder = find.byKey(
        ValueKey('hard-option-${question.responseKey}-$option'),
      );
      await tester.ensureVisible(optionFinder);
      await tester.tap(optionFinder);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('compatibility-save')));
      await tester.pumpAndSettle();
      expect(checkpoint!.hardRequirements[question.responseKey], {option});
      expect(
        checkpoint!.preferences[question.responseKey]![option],
        TrafficLight.red,
      );
      expect(draft.hardRequirements, isEmpty);
      expect(find.text('Parent'), findsOneWidget);
    },
  );

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets('retained hub remains readable with large text at $size', (
      tester,
    ) async {
      _viewport(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _mountHub(tester, _LocalEditorRepository(), _Owner());
      final scrollable = find
          .descendant(
            of: find.byKey(const ValueKey('edit_profile_content_scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final kind in CompatibilityEditorKind.values) {
        final door = find.byKey(ValueKey('compatibility-editor-${kind.name}'));
        // ListView builds these rows lazily; scroll to discover each actual
        // control rather than requiring offscreen rows to remain mounted.
        await tester.scrollUntilVisible(door, 200, scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(door.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.text('Age 29'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Age 29').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
