// LOCK18 V2: actual Founder routes, real item counts, input and retained handlers.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_profiles_components.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _out = '$_root/PRODUCT/APPROVED/PAGE_DOTS/BUILT/V2';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK18_PAGE_DOTS_V2_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_LOCK18_CAPTURE');
Finder _k(String value) => find.byKey(ValueKey(value));
Finder get _dots => find.byType(ZyraProfilesDots);
ZyraProfilesDots _pager(WidgetTester t) => t.widget<ZyraProfilesDots>(_dots);
Finder _target(int index) => find
    .descendant(of: _dots, matching: find.byType(GestureDetector))
    .at(index);

Future<void> _cap(BaselineHarness h, String name) async {
  if (!_capture) return;
  final shadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      _k('zyra-founder-baseline-boundary'),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await h.tester.pump();
    await h.tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$_out/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  } finally {
    debugDisableShadows = shadows;
  }
}

Future<void> _decodeVisiblePhotos(BaselineHarness h) async {
  final images = find.byType(Image).evaluate().toList();
  for (final element in images) {
    final provider = (element.widget as Image).image;
    await h.tester.runAsync(() => precacheImage(provider, element));
  }
  await h.flush();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          zyraPhoneAccessChannel,
          (call) async => call.method == 'status'
              ? {
                  'notifications': 'allowed',
                  'location': 'allowed',
                  'photos': 'limited',
                  'camera': 'notDetermined',
                  'faceID': 'notDetermined',
                }
              : null,
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraPhoneAccessChannel, null),
  );

  final cases = [
    (
      name: 'd01_profiles',
      title: 'Profiles',
      tab: 0,
      guardian: false,
      page: <String>[],
    ),
    (
      name: 'd02_journey_tab',
      title: 'Journey',
      tab: 1,
      guardian: false,
      page: <String>[],
    ),
    (
      name: 'd03_guardian_tab',
      title: 'Guardian',
      tab: 3,
      guardian: false,
      page: <String>[],
    ),
    (
      name: 'd04_my_zyra',
      title: 'My ZYRA',
      tab: 2,
      guardian: false,
      page: <String>[],
    ),
    (
      name: 'e05_guardian_my_zyra',
      title: 'My ZYRA',
      tab: 2,
      guardian: true,
      page: <String>[],
    ),
    (
      name: 'e06_photos',
      title: 'Photos',
      tab: 4,
      guardian: false,
      page: ['manage_photos'],
    ),
    (
      name: 'e07_subscriptions',
      title: 'Your subscriptions',
      tab: 4,
      guardian: false,
      page: ['subscriptions'],
    ),
    (
      name: 'e08_peer_guardians',
      title: 'Guardians',
      tab: 1,
      guardian: false,
      page: ['journey_guardians'],
    ),
    (
      name: 'e09_guardian_info',
      title: 'What Guardians can do',
      tab: 4,
      guardian: false,
      page: ['guardian_info'],
    ),
    (
      name: 'e10_filters',
      title: 'Filters',
      tab: 0,
      guardian: false,
      page: ['filters'],
    ),
  ];

  for (final scale in [1.0, 2.0]) {
    for (final narrow in [false, true]) {
      if (scale == 1 && narrow) continue;
      testWidgets(
        'LOCK18 real routes: scale $scale, narrow $narrow',
        (t) async {
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final h = BaselineHarness(
            t,
            group: 'lock18_${scale}_$narrow',
            outputRoot: _out,
            evidenceRoot: _evidence,
            textScale: scale,
          );
          for (final entry in cases) {
            final model = ViewRequestDraftModel(
              capacity: 3,
              clock: () => DateTime.utc(2026, 10, 31, 12),
            );
            if (entry.name != 'd01_profiles') model.seedJourneys(1);
            await h.mount(
              guardian: entry.guardian,
              tab: entry.tab,
              pages:
                  entry.name == 'e06_photos' ||
                      entry.name == 'e08_peer_guardians'
                  ? entry.page
                  : const [],
              model: model,
            );
            final open = switch (entry.name) {
              'e07_subscriptions' => 'concept_subscriptions',
              'e09_guardian_info' => 'concept_guardian_info',
              'e10_filters' => 'concept_browse_menu',
              _ => null,
            };
            if (open != null) {
              await h.tap(open);
              if (entry.name == 'e10_filters') {
                await t.tapAt(
                  t.getCenter(
                    find.descendant(
                      of: _k('concept_browse_options_navigation'),
                      matching: _k('floating-nav-item-3'),
                    ),
                  ),
                );
                await h.flush();
                h.assertPage('filters');
              }
            }
            if (narrow) {
              t.view.physicalSize = const Size(960, 1704);
              await h.flush();
            }
            await _decodeVisiblePhotos(h);
            expect(_dots, findsOneWidget, reason: entry.name);
            final dots = _pager(t);
            expect(dots.count, greaterThan(1), reason: entry.name);
            final dotRect = t.getRect(_dots);
            final title = find.text(entry.title).first;
            expect(
              dotRect.top,
              greaterThanOrEqualTo(t.getRect(title).bottom),
              reason: entry.name,
            );
            expect(
              dotRect.center.dx,
              closeTo(narrow ? 160 : 215, 1),
              reason: entry.name,
            );
            expect(t.getSize(_target(1)).height, greaterThanOrEqualTo(24));
            expect(_k('focus-next'), findsNothing);
            expect(_k('focus-previous'), findsNothing);
            if (scale == 1 ||
                entry.name.startsWith('d0') ||
                entry.name == 'e06_photos' ||
                entry.name == 'e07_subscriptions') {
              await _cap(
                h,
                '${entry.name}${scale == 1
                    ? ''
                    : narrow
                    ? '_narrow_large_text'
                    : '_large_text'}',
              );
            }
            final first = dots.index;
            final next = first == 0 ? 1 : 0;
            final retained = t.widget<GestureDetector>(_target(next)).onTap!;
            await t.tap(_target(next));
            await h.flush();
            expect(_pager(t).index, next, reason: '${entry.name}: tap');
            if (narrow && entry.name == 'd03_guardian_tab') {
              await _cap(h, 'd03_guardian_tab_narrow_large_text_access');
              final reader = find
                  .descendant(
                    of: _k('guardian-card-scroll'),
                    matching: find.byType(Scrollable),
                  )
                  .first;
              final position = t.state<ScrollableState>(reader).position;
              position.jumpTo(position.maxScrollExtent);
              await h.flush();
              await _cap(h, 'd03_guardian_tab_narrow_large_text_access_bottom');
            }
            retained();
            await h.flush();
            expect(
              _pager(t).index,
              next,
              reason: '${entry.name}: retained prior render',
            );
            // The card manager's horizontal swipe selects a different Guardian;
            // its top dots retain the locked Details/Journey access meaning.
            if (entry.name == 'd03_guardian_tab') {
              await t.tap(_target(0));
              await h.flush();
              final before = h.latest.guardianPage;
              await t.flingFrom(
                Offset(narrow ? 160 : 215, narrow ? 350 : 450),
                const Offset(-240, 0),
                1000,
              );
              await h.flush();
              expect(h.latest.guardianPage, isNot(before));
            } else {
              final swipe = switch (entry.name) {
                'd01_profiles' => find.byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key as ValueKey<String>).value.startsWith(
                        'concept_browse_photo_swipe_',
                      ),
                ),
                'd02_journey_tab' => _k('journey_tab_card'),
                'd04_my_zyra' || 'e05_guardian_my_zyra' => _k('focus-area'),
                'e06_photos' => _k('photos-page-view'),
                'e07_subscriptions' => _k('wallet_profiles_pages'),
                'e08_peer_guardians' => _k('peer_guardians_pager_draft-sara'),
                'e09_guardian_info' => _k('guardian_info_cards'),
                _ => _k('filters_card'),
              };
              await t.ensureVisible(swipe);
              final visible = t
                  .getRect(swipe)
                  .intersect(
                    Rect.fromLTWH(0, 0, narrow ? 320 : 430, narrow ? 468 : 832),
                  );
              await t.flingFrom(
                visible.center,
                Offset(next == 1 ? 240 : -240, 0),
                1000,
              );
              await h.flush();
              expect(_pager(t).index, first, reason: '${entry.name}: swipe');
            }
            if (entry.name == 'e07_subscriptions') {
              final oldProfileDot = t
                  .widget<GestureDetector>(_target(1))
                  .onTap!;
              await h.tap('wallet_group_family');
              final count = _pager(t).count;
              expect(count, greaterThan(1));
              await t.tap(_target(count - 1));
              await h.flush();
              expect(_pager(t).index, count - 1);
              oldProfileDot();
              await h.flush();
              expect(_pager(t).index, count - 1);
              if (scale == 1) await _cap(h, 'e12_subscriptions_family');
              final pages = _k('wallet_family_pages');
              await t.ensureVisible(pages);
              final visible = t
                  .getRect(pages)
                  .intersect(
                    Rect.fromLTWH(0, 0, narrow ? 320 : 430, narrow ? 468 : 832),
                  );
              await t.flingFrom(visible.center, const Offset(240, 0), 1000);
              await h.flush();
              expect(_pager(t).index, count - 2);
            }
            if (scale == 2 &&
                (entry.name == 'd04_my_zyra' ||
                    entry.name == 'e05_guardian_my_zyra')) {
              final action = find
                  .descendant(
                    of: _k('focus-area'),
                    matching: find.byType(TextButton),
                  )
                  .first;
              await t.ensureVisible(action);
              await h.flush();
              expect(action.hitTestable(), findsOneWidget);
              if (narrow) {
                await _cap(h, '${entry.name}_narrow_large_text_action');
              }
              final lastTile = _k(
                entry.guardian
                    ? 'guardian_notifications'
                    : 'focus-notifications',
              );
              await t.ensureVisible(lastTile);
              await h.flush();
              expect(lastTile.hitTestable(), findsOneWidget);
              if (narrow) {
                await _cap(h, '${entry.name}_narrow_large_text_bottom');
              }
            }
            if (narrow && entry.name == 'e06_photos') {
              await t.pumpAndSettle();
              await t.fling(_k('photo-large-0'), const Offset(0, -150), 1000);
              await h.flush();
              expect(_k('adjust-photo-0').hitTestable(), findsOneWidget);
              expect(_k('adjust-main-avatar').hitTestable(), findsOneWidget);
              await _cap(h, 'e06_photos_narrow_large_text_actions');
            }
          }
          if (scale == 1) {
            await h.mount(tab: 0, pages: const ['profile']);
            expect(_dots, findsNothing);
            expect(_k('concept_browse_photo_dot_0'), findsOneWidget);
            await _cap(h, 'x11_full_screen_profile_unchanged');
          }
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  }

  testWidgets('replaced admission cannot revive an earlier dot handler', (
    t,
  ) async {
    var first = 0, replacement = 0;
    final haptics = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
    Future<void> mount(bool allowed, bool second) => t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraTapFeedback(
            level: () => ZyraHapticLevel.strong,
            canAct: () => true,
            child: ZyraProfilesDots(
              key: const ValueKey('stable-dots'),
              count: 2,
              index: 0,
              dotKey: (i) => ValueKey('replacement-$i'),
              canAct: () => allowed,
              onSelected: (_) {
                if (second) {
                  replacement++;
                } else {
                  first++;
                }
              },
            ),
          ),
        ),
      ),
    );
    await mount(true, false);
    final retained = t.widget<GestureDetector>(_target(1)).onTap!;
    await mount(false, true);
    retained();
    await t.pump();
    await mount(true, true);
    retained();
    await t.pump();
    expect(first, 0);
    expect(replacement, 0);
    expect(haptics, isEmpty);
    await t.tap(_target(1));
    await t.pump();
    expect(first, 0);
    expect(replacement, 1);
    expect(haptics, hasLength(1));
  });

  testWidgets('shared dots deny stale owner/target before selection haptic', (
    t,
  ) async {
    var owner = 'a', target = 'first';
    var changes = 0;
    final haptics = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraTapFeedback(
            level: () => ZyraHapticLevel.strong,
            canAct: () => true,
            child: ZyraProfilesDots(
              count: 3,
              index: 0,
              dotKey: (i) => ValueKey('shared-$i'),
              canAct: () => owner == 'a' && target == 'first',
              onSelected: (_) => changes++,
            ),
          ),
        ),
      ),
    );
    final retained = t.widget<GestureDetector>(_target(1)).onTap!;
    retained();
    await t.pump();
    expect(changes, 1);
    expect(haptics, hasLength(1));
    owner = 'b';
    retained();
    await t.pump();
    owner = 'a';
    target = 'replacement';
    retained();
    await t.pump();
    expect(changes, 1);
    expect(haptics, hasLength(1));
    target = 'first';
    retained();
    await t.pump();
    expect(changes, 1);
    expect(haptics, hasLength(1));
    expect(t.getSize(_k('shared-0')), const Size(30, 6));
    expect(t.getSize(_k('shared-1')), const Size(6, 6));
  });
}
