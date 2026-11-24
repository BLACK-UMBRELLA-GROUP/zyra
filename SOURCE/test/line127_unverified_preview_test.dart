import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_guardian_add_card.dart';

void main() {
  test('unverified members are excluded from both browse candidate lists', () {
    final profiles = verifiedPublicCandidates(const [
      DraftProfile(
        id: 'verified',
        firstName: 'Sara',
        age: 27,
        city: 'Birmingham',
      ),
      DraftProfile(
        id: 'unverified',
        firstName: 'Hidden',
        age: 28,
        city: 'Leeds',
        verified: false,
      ),
    ]).toList();
    expect(profiles.map((profile) => profile.id), ['verified']);
    expect(
      ZyraGuardianTabsState.candidates.any(
        (person) => person.id == 'unverified-sample',
      ),
      isTrue,
    );
    expect(
      ZyraGuardianTabsState.network.any(
        (person) => person.id == 'unverified-sample',
      ),
      isFalse,
    );
  });

  testWidgets('unverified Add a Guardian card asks for verification', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraGuardianAddCard(verifyFirst: true, onAdd: () => opened++),
        ),
      ),
    );
    expect(
      find.text(
        'Verify your identity first. Guardians only link to verified members.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Share your ZYRA Code'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('guardian-card-add-button')));
    expect(opened, 1);
  });

  testWidgets('unverified setup has no code or share action', (tester) async {
    final controller = ZyraSignupPreviewController()
      ..seedSetup(
        guardian: false,
        verified: false,
        firstName: 'Adam',
        surname: 'Khan',
      )
      ..setStep(ZyraSignupStep.addGuardian);
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraSignupPreview(
          controller: controller,
          canAct: () => true,
          preferencesBuilder: (_) => const SizedBox.shrink(),
          onPause: () {},
          onEnter: () {},
          samplePhotos: const [],
          ownCode: 'ZYRA-7Q4M-K2XD-9P3L-W8RT-F6NB',
          onShareCode: () {},
          onVerifyIdentity: () => opened++,
        ),
      ),
    );
    expect(find.text('VERIFIED MEMBERS ONLY'), findsOneWidget);
    expect(find.text('Verify now'), findsOneWidget);
    expect(find.text('YOUR ZYRA CODE'), findsNothing);
    expect(find.byKey(const ValueKey('signup_share_code')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('signup_guardian_verify_now')));
    expect(opened, 1);
    controller.dispose();
  });

  testWidgets('unverified Guardian Network hides town and gates actions', (
    tester,
  ) async {
    final actions = <String>[];
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraGuardianTabsPresentation(
          state: ZyraGuardianTabsState(),
          page: 'network',
          unverified: true,
          paid: false,
          seekerGender: 'male',
          onAction: actions.add,
          photoFor: (_) => null,
        ),
      ),
    );
    expect(find.text('Verify to see the town'), findsOneWidget);
    expect(find.text('London'), findsNothing);
    expect(find.text('Verify to introduce'), findsOneWidget);
    expect(find.text('Verify to connect'), findsOneWidget);
    await tester.tap(find.text('Verify to introduce'));
    expect(actions, ['introduce_confirm']);
    await tester.tap(find.text('Verify to connect'));
    expect(actions, ['introduce_confirm', 'connect_confirm']);
  });
}
