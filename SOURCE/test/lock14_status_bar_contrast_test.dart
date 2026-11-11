// Line 77: look up the actual composited status-area annotation.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';

import 'visual/baseline_capture_support.dart';

SystemUiOverlayStyle? _status(WidgetTester tester) => tester
    .binding
    .renderViews
    .single
    .debugLayer
    ?.find<SystemUiOverlayStyle>(const Offset(120, 10));

void _expectDark(WidgetTester tester) {
  expect(_status(tester)?.statusBarIconBrightness, Brightness.dark);
  expect(_status(tester)?.statusBarBrightness, Brightness.light);
}

void _expectLight(WidgetTester tester) {
  expect(_status(tester)?.statusBarIconBrightness, Brightness.light);
  expect(_status(tester)?.statusBarBrightness, Brightness.dark);
}

void main() {
  testWidgets('the app supplies dark icons to Ivory routes and AppBars', (
    tester,
  ) async {
    await tester.pumpWidget(const ZyraApp());
    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme;
    expect(theme?.appBarTheme.systemOverlayStyle, SystemUiOverlayStyle.dark);
    _expectDark(tester);
  });

  testWidgets(
    'Founder Settings stays dark and full-screen profile photos use light icons',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = BaselineHarness(tester, group: 'status-bar');
      await h.mount(tab: 0);
      _expectDark(tester);
      await h.mount(tab: 4, pages: ['settings']);
      _expectDark(tester);
      await h.mount(tab: 0, pages: ['profile']);
      _expectLight(tester);
    },
  );

  testWidgets('the Connections photo fallback follows the painted top', (
    tester,
  ) async {
    const profile = SeekerProfile(
      id: 'status-fallback',
      firstName: 'Sam',
      age: 28,
      city: '',
      photos: [],
      gender: '',
    );
    await tester.pumpWidget(
      const MaterialApp(home: SeekerProfileScreen(profile: profile)),
    );
    _expectLight(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: SeekerProfileScreen(
          profile: profile,
          emptyPhoto: ColoredBox(color: Color(0xFFFBF7F0)),
        ),
      ),
    );
    _expectDark(tester);
  });
}
