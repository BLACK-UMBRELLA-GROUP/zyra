// Fresh member-Personalisation candidates only, never approved baselines.
// Actual shared screen; local presentation hydration does not write a member
// preference, initialize an SDK, grant developer authority or use a network.
// Capture with ZYRA_MEMBER_GOLD_CAPTURE=true and --update-goldens.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

const _capture = bool.fromEnvironment('ZYRA_MEMBER_GOLD_CAPTURE');
const _boundary = ValueKey('member-gold-personalisation-candidate');
const _directory = 'candidates/member_gold_personalisation_2026_10_04';
const _goldRow = ValueKey('personalisation_gold');
const _goldToggle = ValueKey('personalisation_gold_toggle');

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    return Uint8List.fromList(data!.buffer.asUint8List());
  } finally {
    image?.dispose();
  }
}

Future<void> _candidate(
  String name,
  Uint8List pixels,
  WidgetTester tester,
) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  await tester.runAsync(
    () => expectLater(pixels, matchesGoldenFile('$_directory/$name.png')),
  );
}

void _expectControlReachable(WidgetTester tester, Size size) {
  final toggle = find.byKey(_goldToggle);
  expect(toggle.hitTestable(), findsOneWidget);
  final bounds = tester.getRect(toggle);
  expect(bounds.left, greaterThanOrEqualTo(0));
  expect(bounds.right, lessThanOrEqualTo(size.width));
  expect(bounds.top, greaterThanOrEqualTo(24 + kToolbarHeight));
  expect(bounds.bottom, lessThanOrEqualTo(size.height - 24));
  expect(bounds.width, greaterThanOrEqualTo(44));
  expect(bounds.height, greaterThanOrEqualTo(44));
  expect(tester.widget<Switch>(toggle).onChanged, isNotNull);
  expect(find.text('Gold accents'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final reading = FontLoader('PoppinsMemberGoldAudit');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneMemberGoldAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsMemberGoldAudit';
    ZyraText.testWordmarkFontFamily = 'SyneMemberGoldAudit';
  });

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraLocalPrefs.setCachedRole(null);
    AppState.instance.gender = 'male';
  });

  tearDown(() {
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraLocalPrefs.setCachedRole(null);
    AppState.instance.gender = null;
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final layout in const [
    (name: 'standard', size: Size(390, 844), scale: 1.0),
    (name: 'compact140', size: Size(320, 568), scale: 1.4),
  ]) {
    for (final role in ['seeker', 'wali']) {
      testWidgets('member $role gold Off/On real fonts ${layout.name}', (
        tester,
      ) async {
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ZyraLocalPrefs.setCachedRole(role);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark().copyWith(
              textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                foregroundColor: ZyraColors.foreground,
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(layout.scale),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                disableAnimations: true,
              ),
              child: ZyraAppGoldPreviewHost(
                child: RepaintBoundary(key: _boundary, child: child!),
              ),
            ),
            home: const PersonalisationScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(_goldRow),
          160,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('personalisation-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(
          tester.element(find.byKey(_goldRow)),
          alignment: .5,
          duration: Duration.zero,
        );
        await tester.pumpAndSettle();
        _expectControlReachable(tester, layout.size);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(ZyraDevAppGold.instance.enabled, isFalse);
        expect(ZyraDevAppGold.instance.renderingEnabled, isFalse);
        expect(tester.widget<Switch>(find.byKey(_goldToggle)).value, isFalse);
        final mountedScreen = find
            .byType(PersonalisationScreen)
            .evaluate()
            .single;
        final off = await _pixels(tester);
        await _candidate('${role}_${layout.name}_off', off, tester);

        // Seed the real member presentation reader without invoking its
        // persistence writer. Functional suites exercise actual toggle taps.
        ZyraAppGoldStyle.instance.restore(true);
        await tester.pumpAndSettle();
        _expectControlReachable(tester, layout.size);
        expect(tester.widget<Switch>(find.byKey(_goldToggle)).value, isTrue);
        expect(ZyraAppGoldStyle.instance.enabled, isTrue);
        expect(ZyraDevAppGold.instance.enabled, isFalse);
        expect(ZyraDevAppGold.instance.renderingEnabled, isTrue);
        expect(ZyraDevAppGold.instance.reducedMotion, isTrue);
        expect(
          find.byType(PersonalisationScreen).evaluate().single,
          same(mountedScreen),
        );
        final on = await _pixels(tester);
        expect(on, isNot(orderedEquals(off)));
        await _candidate('${role}_${layout.name}_on', on, tester);

        ZyraAppGoldStyle.instance.restore(false);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(find.byKey(_goldToggle)).value, isFalse);
        expect(ZyraDevAppGold.instance.renderingEnabled, isFalse);
        expect(await _pixels(tester), orderedEquals(off));
        expect(ZyraLocalPrefs.cachedRole, role);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(ZyraDevAppGold.instance.debugPainterCount, 0);
      });
    }
  }
}
