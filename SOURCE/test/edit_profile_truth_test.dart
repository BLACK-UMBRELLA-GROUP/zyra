import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.beginPreview();
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

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets('all compatibility editors are available and fit $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const MaterialApp(home: EditProfileScreen()));
      await tester.pump();
      expect(find.textContaining('Your answers stay private'), findsOneWidget);
      for (final name in const [
        'aboutYou',
        'lifestyle',
        'marriagePreferences',
        'trafficLights',
        'hardRequirements',
      ]) {
        final editor = find.byKey(ValueKey('compatibility-editor-$name'));
        await tester.scrollUntilVisible(
          editor,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(editor, findsOneWidget);
      }
      expect(find.text('Not available yet'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
