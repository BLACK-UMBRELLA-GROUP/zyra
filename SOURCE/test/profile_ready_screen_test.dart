import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_identity_verification.dart';
import 'package:zyra/screens/onboarding/profile_ready_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_profile_service.dart';
import 'package:zyra/theme/zyra_text.dart';

ZyraProfileReviewSnapshot snapshot({
  bool complete = false,
  bool hasProfile = true,
  int due = 72,
  int missing = 0,
  bool verified = true,
  bool profileSectionComplete = true,
}) => ZyraProfileReviewSnapshot(
  progress: ZyraOnboardingProgress(
    complete: complete,
    due: due,
    missing: missing,
    hasChapter2: hasProfile,
    basicProfile: complete,
  ),
  verification: verified
      ? ZyraIdentityVerificationState(
          result: ZyraIdentityVerificationResult.verified,
          duplicateReview: ZyraDuplicateReviewState.clear,
          consentGranted: true,
          consentVersion: 'test',
          consentRecordedAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          decidedAt: DateTime.utc(2026),
        )
      : null,
  profileSectionComplete: profileSectionComplete,
);

class ReviewRepository implements ZyraProfileReviewRepository {
  @override
  String? currentUserId = 'owner-a';
  @override
  int accountGeneration = 1;
  int loads = 0;
  int publications = 0;
  ZyraProfileReviewSnapshot value = snapshot();
  Future<ZyraProfileReviewSnapshot> Function()? onLoad;
  Future<bool> Function()? onPublish;

  @override
  bool isCurrentOwner(String userId, int generation) =>
      userId == currentUserId && generation == accountGeneration;

  @override
  Future<ZyraProfileReviewSnapshot> load(String userId) async {
    expect(userId, 'owner-a');
    loads++;
    return onLoad == null ? value : await onLoad!();
  }

  @override
  Future<bool> publish(String userId) async {
    expect(userId, 'owner-a');
    publications++;
    return onPublish == null ? false : await onPublish!();
  }
}

Future<void> mount(WidgetTester tester, ReviewRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(home: ProfileReadyScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

FilledButton goLive(WidgetTester tester) => tester.widget<FilledButton>(
  find.byKey(const ValueKey('profile_review_go_live')),
);

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  test(
    'publication readiness requires saved profile, answers and verified IDV',
    () {
      expect(snapshot().readyToPublish, isTrue);
      expect(snapshot(hasProfile: false).readyToPublish, isFalse);
      expect(snapshot(missing: 1).readyToPublish, isFalse);
      expect(snapshot(due: 0).readyToPublish, isFalse);
      expect(snapshot(verified: false).readyToPublish, isFalse);
      expect(snapshot(profileSectionComplete: false).readyToPublish, isFalse);
    },
  );

  testWidgets('review reads saved truth but never publishes on arrival', (
    tester,
  ) async {
    final repository = ReviewRepository();
    await mount(tester, repository);
    expect(find.text('Review your profile.'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Your profile is live.'), findsNothing);
    expect(find.text('Your profile journey is complete.'), findsNothing);
    expect(find.textContaining('Awaiting the live verification'), findsNothing);
    expect(goLive(tester).onPressed, isNotNull);
    expect(repository.loads, 1);
    expect(repository.publications, 0);
  });

  for (final (label, state) in [
    ('unfinished profile', snapshot(hasProfile: false)),
    ('missing compatibility', snapshot(missing: 3)),
    ('unverified identity', snapshot(verified: false)),
    ('empty bank progress', snapshot(due: 0)),
    ('partial saved profile', snapshot(profileSectionComplete: false)),
  ]) {
    testWidgets('$label cannot publish', (tester) async {
      final repository = ReviewRepository()..value = state;
      await mount(tester, repository);
      expect(goLive(tester).onPressed, isNull);
      expect(
        find.text(
          label == 'unverified identity'
              ? 'Complete verification'
              : 'Continue setup',
        ),
        findsOneWidget,
      );
      expect(repository.publications, 0);
      expect(find.text('Your profile is live.'), findsNothing);
    });
  }

  testWidgets('load failure offers retry without invented completion', (
    tester,
  ) async {
    final repository = ReviewRepository()
      ..onLoad = () => Future.error(StateError('read failed'));
    await mount(tester, repository);
    expect(find.byKey(const ValueKey('profile_review_error')), findsOneWidget);
    expect(goLive(tester).onPressed, isNull);
    expect(find.text('Verified'), findsNothing);
    repository.onLoad = null;
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile_review_retry')),
    );
    await tester.tap(find.byKey(const ValueKey('profile_review_retry')));
    await tester.pumpAndSettle();
    expect(goLive(tester).onPressed, isNotNull);
    expect(repository.publications, 0);
  });

  testWidgets('explicit Go live rechecks and confirms server completion', (
    tester,
  ) async {
    final repository = ReviewRepository();
    repository.onPublish = () async {
      repository.value = snapshot(complete: true);
      return true;
    };
    await mount(tester, repository);
    await tester.tap(find.byKey(const ValueKey('profile_review_go_live')));
    await tester.pumpAndSettle();
    expect(repository.loads, 3);
    expect(repository.publications, 1);
    expect(find.text('Your profile setup is complete.'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile_review_go_live')), findsNothing);
    expect(find.text('Return to My ZYRA'), findsOneWidget);
  });

  testWidgets('RPC response alone cannot claim publication', (tester) async {
    final repository = ReviewRepository()..onPublish = () async => true;
    await mount(tester, repository);
    await tester.tap(find.byKey(const ValueKey('profile_review_go_live')));
    await tester.pumpAndSettle();
    expect(repository.publications, 1);
    expect(find.text('Your profile is live.'), findsNothing);
    expect(find.textContaining('isn’t live yet'), findsOneWidget);
  });

  testWidgets('unknown publish outcome requires refresh before another write', (
    tester,
  ) async {
    final repository = ReviewRepository()
      ..onPublish = () => Future.error(TimeoutException('unknown result'));
    await mount(tester, repository);
    await tester.tap(find.byKey(const ValueKey('profile_review_go_live')));
    await tester.pumpAndSettle();
    expect(repository.publications, 1);
    expect(find.textContaining('whether your profile is live'), findsOneWidget);
    expect(goLive(tester).onPressed, isNull);
    repository.value = snapshot(complete: true);
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile_review_retry')),
    );
    await tester.tap(find.byKey(const ValueKey('profile_review_retry')));
    await tester.pumpAndSettle();
    expect(find.text('Your profile setup is complete.'), findsOneWidget);
    expect(repository.publications, 1);
  });

  testWidgets('changed saved status at action time prevents publication', (
    tester,
  ) async {
    final repository = ReviewRepository();
    await mount(tester, repository);
    repository.value = snapshot(missing: 1);
    await tester.tap(find.byKey(const ValueKey('profile_review_go_live')));
    await tester.pumpAndSettle();
    expect(repository.publications, 0);
    expect(goLive(tester).onPressed, isNull);
    expect(find.text('1 question still to finish'), findsOneWidget);
  });

  testWidgets(
    'owner changes during action cannot publish or display old truth',
    (tester) async {
      final repository = ReviewRepository();
      await mount(tester, repository);
      final pending = Completer<ZyraProfileReviewSnapshot>();
      repository.onLoad = () => pending.future;
      await tester.tap(find.byKey(const ValueKey('profile_review_go_live')));
      await tester.pump();
      repository.currentUserId = 'owner-b';
      repository.accountGeneration++;
      pending.complete(snapshot());
      await tester.pumpAndSettle();
      expect(repository.publications, 0);
      expect(find.text('Your sign-in has changed.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile_review_go_live')),
        findsNothing,
      );
      expect(find.text('Verified'), findsNothing);
    },
  );

  testWidgets('double tap while pending has one publication request', (
    tester,
  ) async {
    final repository = ReviewRepository();
    final pending = Completer<bool>();
    repository.onPublish = () => pending.future;
    await mount(tester, repository);
    final button = find.byKey(const ValueKey('profile_review_go_live'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(repository.publications, 1);
    pending.complete(false);
    await tester.pumpAndSettle();
  });

  testWidgets('account A to B to A still invalidates pending review', (
    tester,
  ) async {
    final repository = ReviewRepository();
    await mount(tester, repository);
    final pending = Completer<ZyraProfileReviewSnapshot>();
    repository.onLoad = () => pending.future;
    await tester.tap(find.byKey(const ValueKey('profile_review_go_live')));
    await tester.pump();
    repository.currentUserId = 'owner-b';
    repository.accountGeneration++;
    repository.currentUserId = 'owner-a';
    repository.accountGeneration++;
    pending.complete(snapshot());
    await tester.pumpAndSettle();
    expect(repository.publications, 0);
    expect(find.text('Your sign-in has changed.'), findsOneWidget);
  });

  testWidgets('developer review never reads or publishes member state', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final repository = ReviewRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileReadyScreen(devPreview: true, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('local preview'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);
    expect(find.byKey(const ValueKey('profile_review_go_live')), findsNothing);
    expect(repository.loads, 0);
    expect(repository.publications, 0);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile_ready_preview_denied')),
      findsOneWidget,
    );
    expect(repository.loads, 0);
    expect(repository.publications, 0);
  });

  testWidgets('compact large text keeps review controls and DEV skip usable', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: const ProfileReadyScreen(devPreview: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile_ready_dev_skip')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile_review_my_zyra')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
