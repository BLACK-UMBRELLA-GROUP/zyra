import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

class EditorRepository implements ZyraCompatibilityEditorRepository {
  @override
  String? currentUserId = 'owner-a';
  @override
  int accountGeneration = 1;
  int loads = 0;
  final List<String> savedOwners = [];
  Future<ZyraOnboardingAnswersSnapshot?> Function()? onLoad;
  Future<bool> Function()? onSave;

  @override
  bool isCurrentOwner(String userId, int generation) =>
      userId == currentUserId && generation == accountGeneration;
  @override
  Future<ZyraOnboardingAnswersSnapshot?> load(String userId) async {
    expect(userId, 'owner-a');
    loads++;
    return onLoad == null ? null : await onLoad!();
  }

  @override
  Future<bool> save(String userId, ZyraCompatibilityDraft draft) async {
    savedOwners.add(userId);
    return onSave == null ? true : await onSave!();
  }
}

Future<void> mount(WidgetTester tester, EditorRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(home: EditProfileScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

Future<CompatibilityEditorScreen> openEditor(WidgetTester tester) async {
  final row = find.byKey(const ValueKey('compatibility-editor-aboutYou'));
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  return tester.widget<CompatibilityEditorScreen>(
    find.byType(CompatibilityEditorScreen),
  );
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    AppState.instance.applyDevPreset(
      name: 'Adam',
      gender: 'male',
      location: 'London',
    );
  });
  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('failed restore cannot create an empty writable draft', (
    tester,
  ) async {
    final repository = EditorRepository()
      ..onLoad = () => Future.error(StateError('connection failed'));
    await mount(tester, repository);
    expect(
      find.byKey(const ValueKey('edit_profile_load_error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compatibility-editor-aboutYou')),
      findsNothing,
    );
    expect(repository.savedOwners, isEmpty);
    repository.onLoad = null;
    await tester.tap(find.byKey(const ValueKey('edit_profile_restore_retry')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('compatibility-editor-aboutYou')),
      findsOneWidget,
    );
    expect(repository.loads, 2);
  });

  testWidgets('stale restore cannot hydrate another account Bio', (
    tester,
  ) async {
    final pending = Completer<ZyraOnboardingAnswersSnapshot?>();
    final repository = EditorRepository()..onLoad = () => pending.future;
    await tester.pumpWidget(
      MaterialApp(home: EditProfileScreen(repository: repository)),
    );
    await tester.pump();
    repository.currentUserId = 'owner-b';
    repository.accountGeneration++;
    pending.complete(
      const ZyraOnboardingAnswersSnapshot(
        ch3Answers: {},
        ch4Preferences: {},
        ch4HardRequirements: {},
        journeyBio: JourneyBio(aboutMe: 'Old account private biography'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      AppState.instance.journeyBio.aboutMe,
      isNot('Old account private biography'),
    );
    expect(
      find.byKey(const ValueKey('edit_profile_load_error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compatibility-editor-aboutYou')),
      findsNothing,
    );
  });

  testWidgets('save is pinned to the captured owner', (tester) async {
    final repository = EditorRepository();
    await mount(tester, repository);
    final editor = await openEditor(tester);
    expect(await editor.onPersist(editor.initialDraft), isTrue);
    expect(repository.savedOwners, ['owner-a']);
  });

  testWidgets('owner change before editor save issues no write', (
    tester,
  ) async {
    final repository = EditorRepository();
    await mount(tester, repository);
    final editor = await openEditor(tester);
    repository.currentUserId = 'owner-b';
    repository.accountGeneration++;
    expect(await editor.onPersist(editor.initialDraft), isFalse);
    expect(repository.savedOwners, isEmpty);
  });

  testWidgets('A to B to A during save cannot report success', (tester) async {
    final repository = EditorRepository();
    final pending = Completer<bool>();
    repository.onSave = () => pending.future;
    await mount(tester, repository);
    final editor = await openEditor(tester);
    final saved = editor.onPersist(editor.initialDraft);
    repository.currentUserId = 'owner-b';
    repository.accountGeneration++;
    repository.currentUserId = 'owner-a';
    repository.accountGeneration++;
    pending.complete(true);
    expect(await saved, isFalse);
    expect(repository.savedOwners, ['owner-a']);
  });

  testWidgets('local editor preview never reads or saves member choices', (
    tester,
  ) async {
    ZyraInternalPreviewClient.beginPreview();
    final repository = EditorRepository();
    await mount(tester, repository);
    final editor = await openEditor(tester);
    expect(await editor.onPersist(editor.initialDraft), isFalse);
    expect(repository.loads, 0);
    expect(repository.savedOwners, isEmpty);
    ZyraInternalPreviewClient.finishSignOut();
    expect(await editor.onPersist(editor.initialDraft), isFalse);
    expect(repository.loads, 0);
    expect(repository.savedOwners, isEmpty);
  });
}
