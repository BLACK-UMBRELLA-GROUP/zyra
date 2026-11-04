import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'support/queue44_removed_controls_fixture.dart';

void main() {
  setUp(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
  });
  testWidgets('removed Home gender controls stay absent across authorization', (
    t,
  ) async {
    await t.pumpWidget(const Queue44MemberFrame(child: WelcomeScreen()));
    await t.pumpAndSettle();
    expectQueue44ControlsAbsent();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await t.pump();
    expectQueue44ControlsAbsent();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await t.pump();
    expectQueue44ControlsAbsent();
  });
  testWidgets(
    'busy Home has no gender choices and leaves preview state intact',
    (t) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      AppState.instance.applyDevPreset(gender: 'female');
      final before = AppState.instance.gender;
      await t.pumpWidget(const Queue44MemberFrame(child: WelcomeScreen()));
      await t.pumpAndSettle();
      await holdQueue44MemberPage(t);
      expect(AppState.instance.gender, before);
    },
  );
  testWidgets('preview state cannot restore gender controls in narrow Home', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.applyDevPreset(gender: 'female');
    await t.pumpWidget(const Queue44MemberFrame(child: WelcomeScreen()));
    await t.pumpAndSettle();
    expectQueue44ControlsAbsent();
    expect(AppState.instance.gender, 'female');
    expect(t.takeException(), isNull);
  });
}
