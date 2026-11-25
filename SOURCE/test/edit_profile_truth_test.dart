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
    testWidgets('LOCK45 profile sections fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const MaterialApp(home: EditProfileScreen()));
      await tester.pump();
      for (final label in const [
        'Photos and video',
        'A few words about you',
        'Where you live',
        'Nationality',
        'Ethnicity',
        'Work and education',
        'Family and marriage',
        'Practical life',
        'Partner preferences',
        'Name',
        'Date of birth',
        'Gender',
      ]) {
        final row = find.text(label);
        await tester.scrollUntilVisible(
          row,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(row.hitTestable(), findsOneWidget);
      }
      expect(find.text('Male'), findsOneWidget);
      for (final retired in const [
        'Green / Yellow / Red',
        'Hard requirements',
        'Lifestyle',
        'Brother',
        'Sister',
      ]) {
        expect(find.textContaining(retired), findsNothing);
      }
      expect(find.text('Not available yet'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
