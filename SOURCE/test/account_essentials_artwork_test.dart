import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

const _artwork = ValueKey('onboarding_account_essentials_artwork');
const _icon = ValueKey('onboarding_account_essentials_icon');

void main() {
  for (final direction in <String?>[
    null,
    'current',
    'structured',
    'luma',
    'revolut',
    'headspace',
    'mozi',
    'wise',
    'uber',
    'ahead',
    'howWeFeel',
    'atoms',
  ]) {
    testWidgets('account artwork is local in ${direction ?? 'ordinary'}', (
      tester,
    ) async {
      final account = AccountEssentialsIntroScreen(onContinue: () {});
      await tester.pumpWidget(
        MaterialApp(
          home: direction == null
              ? account
              : OnboardingPreviewStyle(
                  directionName: direction,
                  child: account,
                ),
        ),
      );
      expect(find.text('First, your account.'), findsOneWidget);
      expect(find.text('ACCOUNT ESSENTIALS'), findsOneWidget);
      expect(tester.getSize(find.byKey(_artwork)), const Size(70, 70));
      final icon = tester.widget<Icon>(find.byKey(_icon));
      expect(icon.icon, Icons.person_outline_rounded);
      expect(icon.color, ZyraColors.journeyGold);
      expect(icon.size, 32);
      expect(
        find.ancestor(
          of: find.byKey(_icon),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      expect(find.byType(OnboardingPreviewAccent), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('later stages retain their existing artwork', (tester) async {
    for (final stage in SeekerOnboardingStage.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingStageIntroScreen(
            key: ValueKey(stage),
            stage: stage,
            includeOverview: false,
            onContinue: () {},
          ),
        ),
      );
      expect(find.byKey(_artwork), findsNothing);
      expect(find.byKey(_icon), findsNothing);
      expect(find.byType(OnboardingPreviewAccent), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact large-text account remains readable and advances once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.4),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: AccountEssentialsIntroScreen(onContinue: () => advances++),
      ),
    );
    expect(tester.getSize(find.byKey(_artwork)), const Size(70, 70));
    expect(
      find.textContaining(
        'Add your first and last name, gender, date of birth and one photo',
      ),
      findsOneWidget,
    );
    final next = find.byKey(const ValueKey('onboarding_stage_continue'));
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pump();
    expect(advances, 1);
    expect(tester.takeException(), isNull);
  });
}
