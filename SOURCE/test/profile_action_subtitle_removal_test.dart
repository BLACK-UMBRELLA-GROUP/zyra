import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/screens/profile/profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _captures = String.fromEnvironment('ZYRA_PROFILE_ACTION_CAPTURE_DIR');
const _captureKey = ValueKey('profile-actions-capture');
const _font = 'PoppinsProfileActions';
const _removed = [
  'See exactly what another Seeker sees',
  'About you, preferences and compatibility answers',
  'Add, arrange and choose your main photo',
];
const _actions = [
  (
    label: 'Preview my profile',
    protectedKey: 'concept_preview_profile',
    ordinaryKey: 'preview-profile-action',
    icon: Icons.person_outline,
    action: ZyraConceptAccountAction.previewProfile,
  ),
  (
    label: 'Edit profile',
    protectedKey: 'concept_edit_profile',
    ordinaryKey: 'edit-profile-action',
    icon: Icons.edit_outlined,
    action: ZyraConceptAccountAction.editProfile,
  ),
  (
    label: 'Manage photos',
    protectedKey: 'concept_manage_photos',
    ordinaryKey: 'edit-photos-action',
    icon: Icons.photo_library_outlined,
    action: ZyraConceptAccountAction.managePhotos,
  ),
];
const _account = ZyraConceptAccountData(
  guardian: false,
  name: 'Adam Khan',
  age: '30',
  gender: 'Male',
  location: 'London',
  membership: 'Seeker One',
  isOne: true,
  relationship: 'Father',
  linkedSeekers: '1',
  guardianCount: '2',
  signedInWith: 'Google',
  backgroundLabel: 'Midnight Plum',
  hapticLabel: 'Subtle',
  gold: false,
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Profile action fixtures must remain offline.');
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

Finder _scrollable(bool protected) => find.descendant(
  of: protected
      ? _key('concept-current-profile-scroll')
      : find.byType(ProfileScreen),
  matching: find.byType(Scrollable),
);

Future<void> _mount(
  WidgetTester tester, {
  required bool protected,
  required bool compact,
  required ValueChanged<ZyraConceptAccountAction> onAction,
}) async {
  tester.view.physicalSize = compact
      ? const Size(320, 568)
      : const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark().copyWith(
        textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(compact ? 2 : 1),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _captureKey,
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: protected
                ? ZyraConceptProfilePresentation(
                    data: _account,
                    onAction: onAction,
                    onSwitchRole: () {},
                  )
                : const ProfileScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _reveal(WidgetTester tester, bool protected, Finder row) async {
  await tester.scrollUntilVisible(
    row,
    140,
    scrollable: _scrollable(protected),
    maxScrolls: 30,
  );
  await tester.pumpAndSettle();
  expect(row.hitTestable(), findsOneWidget);
}

void _expectRemovedCopy() {
  for (final hint in _removed) {
    expect(find.text(hint), findsNothing);
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(hint))), findsNothing);
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldStubs = ZyraText.useTestFontStubs;
  final oldFamily = ZyraText.testReadingFontFamily;
  final oldHttp = HttpOverrides.current;
  late _NoNetwork network;

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError(
          'Capture output must be an existing absolute directory.',
        );
      }
      var path = '';
      for (final component
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (component == '.' || component == '..') {
          throw StateError('Capture output cannot contain aliases.');
        }
        path += '/$component';
        if (FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError(
            'Capture output must contain only existing nonlinked directories.',
          );
        }
      }
    }
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(
      name: 'Adam',
      gender: 'male',
      dob: DateTime(1997, 3, 14),
      location: 'London',
      plan: ZyraPlan.one,
    );
    AppState.instance.photos = [];
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldHttp;
    ZyraInternalPreviewClient.finishSignOut();
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.resetForTesting();
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFamily;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final protected in [true, false]) {
    for (final compact in [false, true]) {
      testWidgets(
        '${protected ? 'protected' : 'ordinary'} Profile keeps clean action rows ${compact ? '320px200%' : '393px'}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final actions = <ZyraConceptAccountAction>[];
            await _mount(
              tester,
              protected: protected,
              compact: compact,
              onAction: actions.add,
            );
            for (final entry in _actions) {
              final row = _key(
                protected ? entry.protectedKey : entry.ordinaryKey,
              );
              await _reveal(tester, protected, row);
              _expectRemovedCopy();
              final ink = find.descendant(
                of: row,
                matching: find.byType(InkWell),
              );
              final label = find.descendant(
                of: row,
                matching: find.text(entry.label),
              );
              final icon = find.descendant(
                of: row,
                matching: find.byIcon(entry.icon),
              );
              final chevron = find.descendant(
                of: row,
                matching: find.byIcon(Icons.chevron_right_rounded),
              );
              expect(ink, findsOneWidget);
              expect(label, findsOneWidget);
              expect(icon, findsOneWidget);
              expect(chevron, findsOneWidget);
              final target = tester.getRect(ink);
              final text = tester.widget<Text>(label);
              final paragraph = tester.renderObject<RenderParagraph>(label);
              expect(target.height, greaterThanOrEqualTo(44));
              expect(target.width, greaterThanOrEqualTo(44));
              expect(text.maxLines, isNull);
              expect(text.overflow, isNull);
              expect(paragraph.didExceedMaxLines, isFalse);
              expect(tester.widget<Icon>(icon).size, 20);
              expect(tester.widget<Icon>(chevron).size, 18);
              for (final content in [label, icon, chevron]) {
                final rect = tester.getRect(content);
                expect(rect.center.dy, closeTo(target.center.dy, .01));
                expect(rect.left, greaterThanOrEqualTo(target.left - .01));
                expect(rect.right, lessThanOrEqualTo(target.right + .01));
                expect(rect.top, greaterThanOrEqualTo(target.top - .01));
                expect(rect.bottom, lessThanOrEqualTo(target.bottom + .01));
              }
              expect(
                tester.getRect(label).left - tester.getRect(icon).right,
                closeTo(14, .01),
              );
              final data = tester.getSemantics(ink).getSemanticsData();
              expect(data.label, contains(entry.label));
              expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
              for (final hint in _removed) {
                expect(data.label, isNot(contains(hint)));
              }
              if (compact &&
                  entry.action == ZyraConceptAccountAction.previewProfile) {
                expect(paragraph.size.height, greaterThan(40));
              }
              if (protected) {
                await tester.tap(ink);
                await tester.pumpAndSettle();
                expect(actions.last, entry.action);
              }
              expect(tester.takeException(), isNull);
            }
            if (protected) {
              expect(actions, _actions.map((entry) => entry.action).toList());
            }

            // Align the real list to the first action, not a replacement crop.
            final first = _key(
              protected
                  ? _actions.first.protectedKey
                  : _actions.first.ordinaryKey,
            );
            final scrollable = _scrollable(protected);
            tester.state<ScrollableState>(scrollable).position.jumpTo(0);
            await tester.pumpAndSettle();
            await _reveal(tester, protected, first);
            final viewport = tester.getRect(scrollable);
            final last = _key(
              protected
                  ? _actions.last.protectedKey
                  : _actions.last.ordinaryKey,
            );
            final overflow = tester.getRect(last).bottom - viewport.bottom;
            if (overflow > 0) {
              final position = tester
                  .state<ScrollableState>(scrollable)
                  .position;
              position.jumpTo(
                (position.pixels + overflow)
                    .clamp(0, position.maxScrollExtent)
                    .toDouble(),
              );
              await tester.pumpAndSettle();
            }
            for (final entry in _actions) {
              final label = find.text(entry.label);
              final rect = tester.getRect(label);
              expect(label.hitTestable(), findsOneWidget);
              expect(rect.top, greaterThanOrEqualTo(viewport.top - .01));
              expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + .01));
            }
            await _capture(
              tester,
              protected
                  ? compact
                        ? '02-protected-compact-200'
                        : '01-protected'
                  : compact
                  ? '04-ordinary-compact-200'
                  : '03-ordinary',
            );
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
