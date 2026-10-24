import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_unlock_service.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = SeekerProfile(
    id: 'dev-browse-preview-f-3',
    firstName: 'Noor',
    surnameLine: 'Mahmood',
    age: 30,
    city: 'Glasgow',
    photos: <String>[],
    gender: 'female',
  );

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraUnlockService.clearForSignOut();
  });

  tearDown(() {
    ZyraUnlockService.clearForSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('Founder preview completes Compatibility Unlock locally', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileUnlockScreen(profile: profile)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 left'), findsOneWidget);
    expect(find.text('Unlock Compatibility'), findsOneWidget);
    expect(find.textContaining('demo profile'), findsNothing);

    await tester.ensureVisible(find.text('Unlock Compatibility'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock Compatibility'));
    await tester.pumpAndSettle();

    final score = ZyraUnlockService.developerPreviewScore(profile.id)!.round();
    expect(find.text('$score%'), findsOneWidget);
    expect(find.text('aligned'), findsOneWidget);
    expect(find.text('Unlock Compatibility'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      ZyraUnlockService.isUnlocked(profile.id, UnlockTier.standard),
      isFalse,
    );
    expect(
      ZyraUnlockService.isUnlocked(profile.id, ZyraUnlockService.currentTier),
      isFalse,
    );
    expect(find.text('Sample category percentages'), findsOneWidget);
    expect(find.text('Main Guardian · Fictional example'), findsOneWidget);
  });

  test('ordinary accounts cannot obtain a fixture score', () {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(ZyraUnlockService.developerPreviewScore(profile.id), isNull);
  });

  test('earlier overall access never confirms a unified full unlock', () async {
    expect(
      await ZyraUnlockService.unlock(profile.id, UnlockTier.standard),
      UnlockOutcome.sampleProfile,
    );
    expect(
      ZyraUnlockService.isUnlocked(profile.id, UnlockTier.standard),
      isTrue,
    );
    expect(
      ZyraUnlockService.isUnlocked(profile.id, ZyraUnlockService.currentTier),
      isFalse,
    );
    expect(
      await ZyraUnlockService.unlock(profile.id, ZyraUnlockService.currentTier),
      UnlockOutcome.unavailable,
    );
  });
}
