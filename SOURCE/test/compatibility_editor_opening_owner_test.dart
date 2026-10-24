// OA-ZYRA-193/303/304/305: private editor copies and every child route stay
// within their opening member/caller lifetime. Synthetic SDK and injected
// repository only; no live account, score, consent, provider or backend I/O.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/onboarding/generic_select_question_screen.dart';
import 'package:zyra/screens/onboarding/traffic_light_question_screen.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000003421';
const _b = '00000000-0000-4000-8000-000000003422';
const _hub = ValueKey('ordinary-compatibility-owner-hub');
const _editor = ValueKey('ordinary-compatibility-owner-editor');
const _cover = ValueKey('unrelated-compatibility-cover');

Map<String, Object?> _sessionJson(String id, {String marker = 'opening'}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800, 'jti': marker})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-in-memory-only',
    'user': {
      'id': id,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-18T00:00:00Z',
    },
  };
}

Future<void> _session(String id, {bool synchronize = true}) async {
  await supabase.auth.setInitialSession(jsonEncode(_sessionJson(id)));
  if (synchronize) await ZyraAccountState.synchronize(id);
}

OnboardingCategory get _deen =>
    chapter3Categories.firstWhere((category) => category.id == 'deen_practice');
OnboardingQuestion get _answer =>
    _deen.questions.firstWhere((question) => question.visibleFor('male'));

(OnboardingCategory, OnboardingQuestion) _preference(
  ZyraCompatibilityDraft draft,
) {
  for (final category in chapter3Categories) {
    for (final question in draft.preferenceQuestions(category)) {
      if (question.hardRequirementSupported && question.showIf == null) {
        return (category, question);
      }
    }
  }
  throw StateError(
    'The existing catalog must contain a hard-requirement question.',
  );
}

ZyraCompatibilityDraft _seed() {
  final draft = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
  draft.answers[_answer.responseKey] = _answer.options.first;
  draft.answers['bio_about_me'] =
      'Synthetic private biography retained unchanged';
  final question = _preference(draft).$2;
  draft.preferences[question.responseKey] = {
    for (final option in question.options) option: TrafficLight.red,
  };
  draft.hardRequirements[question.responseKey] = {question.options.first};
  return draft;
}

class _Repository implements ZyraCompatibilityEditorRepository {
  final initial = _seed();
  final saves = <(String, ZyraCompatibilityDraft)>[];
  Future<bool> Function()? acknowledge;
  int loads = 0;

  @override
  String? get currentUserId => supabase.auth.currentUser?.id;
  @override
  int get accountGeneration => ZyraAccountState.generation;
  @override
  bool isCurrentOwner(String userId, int generation) =>
      currentUserId == userId && ZyraAccountState.isCurrent(userId, generation);
  @override
  Future<ZyraOnboardingAnswersSnapshot?> load(String userId) async {
    loads++;
    return initial.toSnapshot();
  }

  @override
  Future<bool> save(String userId, ZyraCompatibilityDraft draft) async {
    saves.add((userId, draft.copy()));
    return acknowledge == null ? true : await acknowledge!();
  }
}

class _Caller extends ChangeNotifier {
  bool allowed = true;
  late final bool Function() guard = _canAct;
  bool _canAct() => allowed;
  void revoke() {
    allowed = false;
    notifyListeners();
  }
}

class _Navigation extends NavigatorObserver {
  int pops = 0;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));
VoidCallback _save(WidgetTester tester, [String key = 'compatibility-save']) =>
    tester.widget<FilledButton>(_key(key)).onPressed!;
VoidCallback _back(WidgetTester tester) =>
    tester.widget<BackButton>(find.byType(BackButton)).onPressed!;

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _settle(WidgetTester tester) async {
  await _flush(tester);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}

Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (var frame = 0; frame < 100 && !done(); frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(done(), isTrue, reason: 'Synthetic editor workflow did not settle.');
}

Future<void> _operation(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  var done = false;
  Object? failure;
  StackTrace? failureStack;
  action().then<void>(
    (_) => done = true,
    onError: (Object error, StackTrace stack) {
      failure = error;
      failureStack = stack;
      done = true;
    },
  );
  await _until(tester, () => done);
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      150,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 40,
    );
  }
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _settle(tester);
}

Future<GenericSelectQuestionScreen> _answerPage(WidgetTester tester) async {
  await _tap(tester, 'edit-category-${_deen.id}');
  await _tap(tester, 'edit-answer-${_answer.responseKey}');
  return tester.widget<GenericSelectQuestionScreen>(
    find.byType(GenericSelectQuestionScreen),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final unexpected = <String>[];
  final pending = <Completer<bool>>[];
  late GlobalKey<NavigatorState> navigation;
  late _Navigation observer;
  late _Repository repository;

  Widget app(Widget home) => MaterialApp(
    navigatorKey: navigation,
    navigatorObservers: [observer],
    home: home,
  );

  Future<void> mountHub(
    WidgetTester tester,
    CompatibilityEditorKind kind,
  ) async {
    await tester.pumpWidget(
      app(EditProfileScreen(key: _hub, repository: repository)),
    );
    await _settle(tester);
    await _tap(tester, 'compatibility-editor-${kind.name}');
    expect(repository.loads, 1);
  }

  void withdrawn(WidgetTester tester) {
    expect(_key('compatibility_editor_owner_unavailable'), findsOneWidget);
    expect(find.byType(GenericSelectQuestionScreen), findsNothing);
    expect(find.byType(TrafficLightQuestionScreen), findsNothing);
    expect(_key('compatibility-save'), findsNothing);
    expect(repository.saves, isEmpty);
    expect(tester.takeException(), isNull);
  }

  void ownerTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await _operation(tester, () => _session(_a));
        AppState.instance.applyDevPreset(
          name: 'Synthetic member',
          gender: 'male',
          location: 'Synthetic city',
        );
        await body(tester);
        expect(unexpected, isEmpty);
      } finally {
        for (final ack in pending) {
          if (!ack.isCompleted) ack.complete(false);
        }
        pending.clear();
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester);
        await _operation(tester, () => ZyraAccountState.synchronize(null));
        var drained = false;
        Zone.root.run(() {
          ZyraLocalPrefs.bindAccount(_a);
          ZyraLocalPrefs.bindAccount(null).then<void>((_) => drained = true);
        });
        await _until(tester, () => drained);
      }
    }, timeout: const Timeout(Duration(seconds: 25)));
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://compatibility-owner-evidence.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        unexpected.add('${request.method} ${request.url}');
        throw StateError('Injected editor evidence must not use HTTP.');
      }),
    );
  });
  setUp(() {
    unexpected.clear();
    navigation = GlobalKey<NavigatorState>();
    observer = _Navigation();
    repository = _Repository();
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
  });
  tearDown(() {
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  for (final returnToA in [false, true]) {
    for (final surface in ['answer', 'preference', 'hard requirement']) {
      ownerTest(
        '$surface copy withdraws on account ${returnToA ? 'ABA' : 'replacement'}',
        (tester) async {
          final kind = switch (surface) {
            'answer' => CompatibilityEditorKind.aboutYou,
            'preference' => CompatibilityEditorKind.trafficLights,
            _ => CompatibilityEditorKind.hardRequirements,
          };
          await mountHub(tester, kind);
          final mainSave = _save(tester);
          VoidCallback edit;
          VoidCallback? use;
          if (surface == 'answer') {
            final question = await _answerPage(tester);
            edit = () => question.onChanged(_answer.options.last);
            use = _save(tester, 'question-save');
          } else if (surface == 'preference') {
            final (category, question) = _preference(repository.initial);
            await _tap(tester, 'edit-preferences-${category.id}');
            await _tap(tester, 'edit-lights-${question.responseKey}');
            final editor = tester.widget<TrafficLightQuestionScreen>(
              find.byType(TrafficLightQuestionScreen),
            );
            edit = () {
              editor.onChanged({
                for (final option in question.options)
                  option: TrafficLight.green,
              });
              editor.onHardRequirementChanged(<String>{});
            };
            use = _save(tester, 'question-save');
          } else {
            final question = _preference(repository.initial).$2;
            edit = tester
                .widget<InkWell>(
                  _key(
                    'hard-option-${question.responseKey}-${question.options.first}',
                  ),
                )
                .onTap!;
          }
          final back = _back(tester);
          final pops = observer.pops;
          await _operation(tester, () => _session(_b));
          if (returnToA) await _operation(tester, () => _session(_a));
          await _settle(tester);
          edit();
          use?.call();
          mainSave();
          back();
          await _settle(tester);
          withdrawn(tester);
          expect(observer.pops, pops);
          expect(
            repository.initial.answers[_answer.responseKey],
            _answer.options.first,
          );
        },
      );
    }
  }

  ownerTest(
    'SDK-only ABA withdraws an open answer without account-generation change',
    (tester) async {
      await mountHub(tester, CompatibilityEditorKind.aboutYou);
      final question = await _answerPage(tester);
      final use = _save(tester, 'question-save');
      final generation = ZyraAccountState.generation;
      await _operation(tester, () => _session(_b, synchronize: false));
      await _operation(tester, () => _session(_a, synchronize: false));
      await _settle(tester);
      expect(ZyraAccountState.generation, generation);
      question.onChanged(_answer.options.last);
      use();
      await _settle(tester);
      withdrawn(tester);
    },
  );

  ownerTest(
    'covered answer callbacks cannot edit or pop and work after return',
    (tester) async {
      await mountHub(tester, CompatibilityEditorKind.aboutYou);
      final question = await _answerPage(tester);
      final use = _save(tester, 'question-save');
      final back = _back(tester);
      final pops = observer.pops;
      unawaited(
        navigation.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) =>
                const Scaffold(key: _cover, body: Text('Unrelated')),
          ),
        ),
      );
      await _settle(tester);
      question.onChanged(_answer.options.last);
      use();
      back();
      await _settle(tester);
      expect(find.byKey(_cover), findsOneWidget);
      expect(observer.pops, pops);
      navigation.currentState!.pop();
      await _settle(tester);
      question.onChanged(_answer.options.last);
      use();
      await _settle(tester);
      expect(find.byType(GenericSelectQuestionScreen), findsNothing);
      expect(repository.saves, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  ownerTest(
    'disposing the Profile hub withdraws an independently retained child',
    (tester) async {
      await mountHub(tester, CompatibilityEditorKind.aboutYou);
      final question = await _answerPage(tester);
      final use = _save(tester, 'question-save');
      final back = _back(tester);
      final pops = observer.pops;
      await tester.pumpWidget(
        app(const Scaffold(body: Text('Replacement home'))),
      );
      await _settle(tester);
      expect(find.byType(EditProfileScreen, skipOffstage: false), findsNothing);
      question.onChanged(_answer.options.last);
      use();
      back();
      await _settle(tester);
      withdrawn(tester);
      expect(observer.pops, pops);
    },
  );

  for (final binding in [
    'mode',
    'kind',
    'draft',
    'persist',
    'guard',
    'changes',
  ]) {
    ownerTest(
      'same-key $binding rebinding cannot adopt a copied ordinary draft',
      (tester) async {
        final caller = _Caller();
        final replacement = _Caller();
        final draft = _seed();
        final candidates = <ZyraCompatibilityDraft>[];
        Future<bool> persist(ZyraCompatibilityDraft value) async {
          candidates.add(value.copy());
          return true;
        }

        Future<bool> otherPersist(ZyraCompatibilityDraft value) async {
          candidates.add(value.copy());
          return true;
        }

        // Pin the public callback instance, not a freshly-created closure.
        final Future<bool> Function(ZyraCompatibilityDraft) originalPersist =
            persist;
        Widget editor({bool changed = false}) {
          final guard = changed && binding == 'guard'
              ? replacement.guard
              : caller.guard;
          final changes = changed && binding == 'changes'
              ? replacement
              : caller;
          if (changed && binding == 'mode') {
            return CompatibilityEditorScreen.preview(
              key: _editor,
              kind: CompatibilityEditorKind.aboutYou,
              initialDraft: draft,
              onPersist: originalPersist,
              canAct: guard,
              canActChanges: changes,
            );
          }
          return CompatibilityEditorScreen(
            key: _editor,
            kind: changed && binding == 'kind'
                ? CompatibilityEditorKind.lifestyle
                : CompatibilityEditorKind.aboutYou,
            initialDraft: changed && binding == 'draft' ? draft.copy() : draft,
            onPersist: changed && binding == 'persist'
                ? otherPersist
                : originalPersist,
            canAct: guard,
            canActChanges: changes,
          );
        }

        await tester.pumpWidget(app(editor()));
        await _settle(tester);
        final state = tester.state(find.byType(CompatibilityEditorScreen));
        final save = _save(tester);
        final question = await _answerPage(tester);
        final use = _save(tester, 'question-save');
        await tester.pumpWidget(app(editor(changed: true)));
        await _settle(tester);
        await tester.pumpWidget(app(editor()));
        await _settle(tester);
        expect(
          tester.state(
            find.byType(CompatibilityEditorScreen, skipOffstage: false),
          ),
          same(state),
        );
        question.onChanged(_answer.options.last);
        use();
        save();
        await _settle(tester);
        withdrawn(tester);
        expect(candidates, isEmpty);
        expect(draft.answers[_answer.responseKey], _answer.options.first);
      },
    );
  }

  ownerTest(
    'caller notification withdraws its private ordinary child terminally',
    (tester) async {
      final caller = _Caller();
      var saves = 0;
      await tester.pumpWidget(
        app(
          CompatibilityEditorScreen(
            kind: CompatibilityEditorKind.aboutYou,
            initialDraft: _seed(),
            canAct: caller.guard,
            canActChanges: caller,
            onPersist: (_) async {
              saves++;
              return true;
            },
          ),
        ),
      );
      await _settle(tester);
      final question = await _answerPage(tester);
      final use = _save(tester, 'question-save');
      caller.revoke();
      caller.allowed = true;
      await _settle(tester);
      question.onChanged(_answer.options.last);
      use();
      await _settle(tester);
      withdrawn(tester);
      expect(saves, 0);
    },
  );

  ownerTest(
    'healthy token refresh preserves edit/save and detached original draft',
    (tester) async {
      await mountHub(tester, CompatibilityEditorKind.aboutYou);
      final initialPreferences = repository.initial.toSnapshot().ch4Preferences;
      final initialHard = repository.initial.toSnapshot().ch4HardRequirements;
      final question = await _answerPage(tester);
      // ignore: invalid_use_of_internal_member
      supabase.auth.notifyAllSubscribers(
        AuthChangeEvent.tokenRefreshed,
        session: Session.fromJson(_sessionJson(_a, marker: 'refreshed')),
        broadcast: false,
      );
      await _flush(tester);
      question.onChanged(_answer.options.last);
      _save(tester, 'question-save')();
      await _settle(tester);
      _back(tester)();
      await _settle(tester);
      _save(tester)();
      await _settle(tester);
      expect(repository.saves, hasLength(1));
      final (owner, saved) = repository.saves.single;
      expect(owner, _a);
      expect(saved.answers[_answer.responseKey], _answer.options.last);
      expect(saved.toSnapshot().ch4Preferences, initialPreferences);
      expect(saved.toSnapshot().ch4HardRequirements, initialHard);
      expect(
        repository.initial.answers[_answer.responseKey],
        _answer.options.first,
      );
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final acknowledged in [false, true]) {
    ownerTest(
      'covered ordinary save settles $acknowledged without duplicate write or pop',
      (tester) async {
        final ack = Completer<bool>();
        pending.add(ack);
        repository.acknowledge = () => ack.future;
        await mountHub(tester, CompatibilityEditorKind.aboutYou);
        final save = _save(tester);
        save();
        await _flush(tester);
        expect(repository.saves, hasLength(1));
        unawaited(
          navigation.currentState!.push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(key: _cover, body: Text('Unrelated')),
            ),
          ),
        );
        await _settle(tester);
        navigation.currentState!.pop();
        await _flush(tester);
        save();
        await _flush(tester);
        expect(repository.saves, hasLength(1));
        final pops = observer.pops;
        ack.complete(acknowledged);
        await _settle(tester);
        expect(observer.pops, pops);
        expect(find.byType(CompatibilityEditorScreen), findsOneWidget);
        expect(_save(tester), isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  ownerTest('late successful save cannot restore an account-replaced editor', (
    tester,
  ) async {
    final ack = Completer<bool>();
    pending.add(ack);
    repository.acknowledge = () => ack.future;
    await mountHub(tester, CompatibilityEditorKind.aboutYou);
    final save = _save(tester);
    save();
    await _flush(tester);
    expect(repository.saves, hasLength(1));
    final pops = observer.pops;
    await _operation(tester, () => _session(_b));
    ack.complete(true);
    await _settle(tester);
    save();
    await _settle(tester);
    expect(_key('compatibility_editor_owner_unavailable'), findsOneWidget);
    expect(repository.saves, hasLength(1));
    expect(observer.pops, pops);
    expect(tester.takeException(), isNull);
  });
}
