import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/data/zyra_seeker_plan_limits.dart';
import 'package:zyra/dev/zyra_limits_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/connections/zyra_sample_activity.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LOCK48 only waiting outbound requests consume space', () {
    var now = DateTime.utc(2026, 11, 24, 12);
    final model = ViewRequestDraftModel(capacity: 3, clock: () => now);
    expect(ZyraSeekerPlanLimits.basic.hasWaitingRequestSpace(4), isTrue);
    expect(ZyraSeekerPlanLimits.basic.hasWaitingRequestSpace(5), isFalse);
    expect(ZyraSeekerPlanLimits.one.hasWaitingRequestSpace(19), isTrue);
    expect(ZyraSeekerPlanLimits.one.hasWaitingRequestSpace(20), isFalse);
    expect(model.seedReceived('draft-amira'), isTrue);
    expect(model.seedReceived('draft-zainab'), isTrue);
    expect(model.request('draft-sara'), isTrue);
    expect(model.request('draft-aisha'), isTrue);
    expect(model.request('draft-noor'), isTrue);
    expect(model.waitingSentProfileIds, {
      'draft-sara',
      'draft-aisha',
      'draft-noor',
    });
    expect(model.cancel('draft-sara'), isTrue);
    expect(model.simulateRecipientAccept('draft-aisha'), isTrue);
    expect(model.waitingSentProfileIds, {'draft-noor'});
    now = now.add(ViewRequestDraftModel.requestLifetime);
    expect(model.advanceTimeRules(), isTrue);
    expect(model.waitingSentProfileIds, isEmpty);
    expect(model.requestCooldownUntil('draft-noor'), isNotNull);
    expect(model.stateFor('draft-amira'), DraftJourneyState.received);
    expect(model.stateFor('draft-zainab'), DraftJourneyState.received);
  });

  test(
    'LOCK48 Basic viewing tracks unique exposures in a four-hour window',
    () {
      final start = DateTime.utc(2026, 11, 24, 14, 20);
      final window = ZyraPreviewBrowseWindow(startedAt: start, seededViews: 24);
      expect(window.record('draft-sara', start), isTrue);
      expect(window.record('draft-sara', start), isFalse);
      expect(window.record('draft-aisha', start), isFalse);
      expect(window.countAt(start), 25);
      expect(window.refillAt, DateTime.utc(2026, 11, 24, 18, 20));
      final restored = ZyraPreviewBrowseWindow.fromSnapshot(window.snapshot());
      expect(restored.countAt(start), 25);
      expect(restored.countAt(window.refillAt!), 0);
      expect(restored.record('draft-aisha', window.refillAt!), isFalse);
    },
  );

  testWidgets('LOCK48 introduction tile and full profile ask before sending', (
    t,
  ) async {
    final samples = ZyraDeveloperSamples.instance;
    SharedPreferences.setMockInitialValues({});
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    addTearDown(() {
      samples.clear();
      samples.unbind();
      ZyraText.useTestFontStubs = false;
      ZyraAccountState.resetForTesting();
      ZyraAccountState.clearImagesForTesting = null;
    });
    const owner = 'line146-introduction-owner';
    await t.runAsync(() => ZyraAccountState.synchronize(owner));
    samples.bind(
      authorized: () => true,
      capacity: () => 3,
      isSeekerOne: () => true,
    );
    samples.recordRealCounts(owner, ZyraAccountState.generation, active: 0);
    samples.setIntroductions(1);
    var admitted = false;
    final admittedContexts = <bool>[];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraSampleIntroductionsList(
            wrapTitle: (title) => title,
            admitRequest: (context) {
              admittedContexts.add(ModalRoute.isCurrentOf(context) == true);
              return admitted;
            },
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final header = find.byKey(
      const ValueKey('sample-introduction-draft-noor-header'),
    );
    expect(samples.waitingSentProfileIds, isEmpty);
    await t.tap(header);
    await t.pumpAndSettle();
    await t.tap(find.text('Request a Journey'));
    await t.pumpAndSettle();
    expect(samples.waitingSentProfileIds, isEmpty);
    await t.tap(find.text('View profile'));
    await t.pumpAndSettle();
    await t.tap(find.text('Request a Journey'));
    await t.pumpAndSettle();
    expect(samples.waitingSentProfileIds, isEmpty);
    expect(admittedContexts, [true, true]);
    admitted = true;
    await t.tap(find.text('Request a Journey'));
    await t.pumpAndSettle();
    expect(samples.waitingSentProfileIds, ['draft-noor']);
    expect(admittedContexts, [true, true, true]);
  });
}
