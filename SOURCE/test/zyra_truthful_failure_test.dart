import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/journey/journey_flow_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_truthful_write.dart';
import 'package:zyra/widgets/zyra_write_feedback.dart';

class _PausedLimit implements Exception {}

class _LegacyPlanRefusal implements Exception {}

void main() {
  setUp(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));
  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

  group('truthful persistence boundary', () {
    test('an exception is a failure, never success', () async {
      final saved = await runZyraTruthfulWrite(
        context: 'forced test write',
        write: () async => throw StateError('forced offline'),
      );
      expect(saved, isFalse);
    });

    test('a duplicate is success only where the caller declares it', () async {
      final saved = await runZyraTruthfulWrite(
        context: 'forced duplicate retry',
        duplicateIsSuccess: true,
        write: () async => throw StateError('duplicate key value'),
      );
      expect(saved, isTrue);
    });

    test('Pause maps named refusals and rethrows unknown failures', () async {
      Future<void> run(Future<void> Function() write) => runZyraPauseWrite(
        write: write,
        pausedLimit: _PausedLimit.new,
        legacyPlanRefusal: _LegacyPlanRefusal.new,
      );

      await expectLater(
        run(() async => throw StateError('paused_limit_reached')),
        throwsA(isA<_PausedLimit>()),
      );
      await expectLater(
        run(() async => throw StateError('suspension_requires_one')),
        throwsA(isA<_LegacyPlanRefusal>()),
      );
      await expectLater(
        run(() async => throw StateError('forced network failure')),
        throwsA(isA<StateError>()),
      );
    });
  });

  testWidgets('decision failure is visible and a failed retry stays honest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showZyraDecisionWriteFailure(
                context,
                decision: 'Consider',
                retry: () async => false,
              ),
              child: const Text('Force decision failure'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Force decision failure'));
    await tester.pump();
    expect(
      find.text("Your Consider didn't save — check your connection."),
      findsOneWidget,
    );

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump();
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text("Still couldn't save — please try again later."),
      findsOneWidget,
    );
  });

  testWidgets('family-answer failure tells the user to submit again', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showZyraFamilyAnswersWriteFailure(context),
              child: const Text('Force family failure'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Force family failure'));
    await tester.pump();
    expect(
      find.text(
        "Some answers didn't save — check your connection and press Submit again.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('a successful decision retry leaves no confirmation snackbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    final reply = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showZyraDecisionWriteFailure(
                context,
                decision: 'Save',
                retry: () {
                  retries++;
                  return reply.future;
                },
              ),
              child: const Text('Force decision failure'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Force decision failure'));
    await tester.pumpAndSettle();
    expect(
      find.text("Your Save didn't save — check your connection."),
      findsOneWidget,
    );
    // Use the real action so Material dismisses the original failure notice.
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retries, 1);
    expect(find.byType(SnackBar), findsNothing);
    reply.complete(true);
    await tester.pumpAndSettle();
    expect(retries, 1);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Save saved.'), findsNothing);
    expect(
      find.text("Still couldn't save — please try again later."),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('developer decision previews never paint a bottom snackbar', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showZyraDecisionWriteFailure(
                context,
                decision: 'Save',
                retry: () async => false,
              ),
              child: const Text('Force developer failure'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Force developer failure'));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining("didn't save"), findsNothing);
  });

  testWidgets('unknown Pause failure keeps confirmation open with an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: buildZyraPauseFailureTestSurface(
          write: () async => throw StateError('forced network failure'),
        ),
      ),
    );

    await tester.tap(find.text('Request Pause').last);
    await tester.pump();
    expect(find.text('Request a pause?'), findsOneWidget);
    expect(
      find.text(
        "Pause request didn't go through. Check your connection and try again.",
      ),
      findsOneWidget,
    );
  });
}
