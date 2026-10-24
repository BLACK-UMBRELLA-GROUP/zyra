import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_local_preview.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

Widget _homeTools({bool busy = false}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: ZyraDeveloperAccess.authorizationChanges,
            builder: (context, _) => ZyraDevHomeTools(
              busy: busy,
              onHome: () {},
              onRestart: () {},
              onReset: () {},
              onAccounts: () {},
              onSeekerSignUp: () {},
              onGuardianSignUp: () {},
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraDevLocalPreview.genderSelection.value = 'male';
  });

  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevLocalPreview.genderSelection.value = 'male';
  });

  testWidgets('removed Home gender controls stay absent across authorization', (
    tester,
  ) async {
    await tester.pumpWidget(_homeTools());

    expect(find.text('Preview gender'), findsNothing);
    expect(find.byKey(const ValueKey('dev_preview_gender_male')), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_preview_gender_female')),
      findsNothing,
    );

    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pump();

    expect(find.text('Preview gender'), findsNothing);
    expect(find.byKey(const ValueKey('dev_preview_gender_male')), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_preview_gender_female')),
      findsNothing,
    );

    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();

    expect(find.text('Preview gender'), findsNothing);
    expect(find.byKey(const ValueKey('dev_preview_gender_male')), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_preview_gender_female')),
      findsNothing,
    );
  });

  testWidgets('preview state cannot restore gender controls in narrow Home', (
    tester,
  ) async {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    await tester.pumpWidget(_homeTools());

    ZyraDevLocalPreview.genderSelection.value = 'female';
    await tester.pump();

    expect(find.text('Preview gender'), findsNothing);
    for (final gender in const ['male', 'female']) {
      expect(find.byKey(ValueKey('dev_preview_gender_$gender')), findsNothing);
    }
    expect(ZyraDevLocalPreview.genderSelection.value, 'female');
    expect(tester.takeException(), isNull);
    for (final key in const [
      'dev_home_login',
      'dev_reset_state',
      'dev_switch_accounts',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('dev_signup_seeker')), findsNothing);
    expect(find.byKey(const ValueKey('dev_signup_guardian')), findsNothing);
  });

  testWidgets(
    'busy Home has no gender choices and leaves preview state intact',
    (tester) async {
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      await tester.pumpWidget(_homeTools(busy: true));

      for (final gender in const ['male', 'female']) {
        expect(
          find.byKey(ValueKey('dev_preview_gender_$gender')),
          findsNothing,
        );
      }
      expect(find.text('Resetting…'), findsOneWidget);
      expect(ZyraDevLocalPreview.genderSelection.value, 'male');
      expect(tester.takeException(), isNull);
    },
  );
}
