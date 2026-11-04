import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';

const _background = ValueKey('personalisation_background');
const _haptics = ValueKey('personalisation_haptic');
const _gold = ValueKey('personalisation_gold_toggle');
const _unavailable = ValueKey('personalisation-unavailable');

class _PreviewHarness extends StatefulWidget {
  const _PreviewHarness({super.key, this.guardUsesRoute = false});

  final bool guardUsesRoute;

  @override
  State<_PreviewHarness> createState() => _PreviewHarnessState();
}

class _PreviewHarnessState extends State<_PreviewHarness> {
  bool allowed = true;
  bool exceptional = false;
  bool preview = true;
  bool alternateCallbacks = false;
  ZyraDevPalette palette = ZyraDevPalette.midnightPlum;
  ZyraHapticLevel haptic = ZyraHapticLevel.subtle;
  bool gold = false;
  int hapticCalls = 0;
  int goldCalls = 0;
  int alternateCalls = 0;

  bool canAct() {
    if (exceptional) throw StateError('Denied owner');
    return allowed &&
        (!widget.guardUsesRoute || ModalRoute.of(context)?.isCurrent == true);
  }

  void selectHaptic(ZyraHapticLevel value) {
    setState(() {
      haptic = value;
      hapticCalls++;
    });
  }

  void selectGold(bool value) {
    setState(() {
      gold = value;
      goldCalls++;
    });
  }

  void alternateHaptic(ZyraHapticLevel value) {
    setState(() => alternateCalls++);
  }

  void update(VoidCallback mutation) => setState(mutation);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: preview
        ? PersonalisationScreen.preview(
            key: const ValueKey('same-personalisation-state'),
            canAct: canAct,
            palette: palette,
            hapticLevel: haptic,
            goldEnabled: gold,
            onHapticChanged: alternateCallbacks
                ? alternateHaptic
                : selectHaptic,
            onGoldChanged: selectGold,
          )
        : const PersonalisationScreen(
            key: ValueKey('same-personalisation-state'),
          ),
  );
}

Future<_PreviewHarnessState> _mount(
  WidgetTester tester, {
  GlobalKey<NavigatorState>? navigatorKey,
  bool guardUsesRoute = false,
}) async {
  final key = GlobalKey<_PreviewHarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: _PreviewHarness(key: key, guardUsesRoute: guardUsesRoute),
    ),
  );
  await tester.pump();
  return key.currentState!;
}

Future<void> _openChoice(WidgetTester tester, Key row) async {
  await _tapVisible(tester, find.byKey(row));
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('personalisation-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  var visible = tester.getRect(target).intersect(Offset.zero & logicalSize);
  final scrollable = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  if (scrollable.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(scrollable.first));
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final rect = tester.getRect(target);
  final alignment = Alignment(
    2 * (visible.center.dx - rect.left) / rect.width - 1,
    2 * (visible.center.dy - rect.top) / rect.height - 1,
  );
  expect(target.hitTestable(at: alignment), findsOneWidget);
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
}

Future<SharedPreferences> _persistedMemberPrefs(WidgetTester tester) async {
  await _completeMemberOperation(
    tester,
    () => ZyraLocalPrefs.bindAccount(ZyraAccountState.userId),
    'member preference writes',
  );
  final prefs = await tester.runAsync(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  });
  expect(prefs, isNotNull);
  return prefs!;
}

Future<void> _synchronizeMember(WidgetTester tester, String? account) async {
  await _completeMemberOperation(
    tester,
    () => ZyraAccountState.synchronize(account),
    'member synchronization to ${account ?? 'signed out'}',
  );
}

Future<void> _completeMemberOperation(
  WidgetTester tester,
  Future<void> Function() operation,
  String description,
) async {
  var completed = false;
  Object? failure;
  StackTrace? failureStack;
  // Never await a potentially old-zone queue tail while runAsync holds the
  // framework's fake-clock pump. Register observation, then leave that zone.
  await tester.runAsync(() async {
    try {
      unawaited(
        operation().then<void>(
          (_) => completed = true,
          onError: (Object error, StackTrace stack) {
            failure = error;
            failureStack = stack;
            completed = true;
          },
        ),
      );
    } catch (error, stack) {
      failure = error;
      failureStack = stack;
      completed = true;
    }
  });
  for (var attempt = 0; attempt < 100 && !completed; attempt++) {
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    });
  }
  expect(
    completed,
    isTrue,
    reason:
        '$description did not complete within 100 interleaved fake pumps '
        'and real async yields.',
  );
  expect(failure, isNull, reason: '$description failed. ${failureStack ?? ''}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize('member-a');
    ZyraAppGoldStyle.instance.restore(false);
    ZyraAppGoldRenderer.instance.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraText.restoreAppFont(null);
    ZyraText.useTestFontStubs = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() async {
    await ZyraAccountState.synchronize(null);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAppGoldRenderer.instance.resetForTesting();
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'pure retained content uses supplied snapshot and explicit actions',
    (tester) async {
      var haptic = 0;
      bool? gold;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraPersonalisationContent(
              snapshot: const ZyraPersonalisationSnapshot(
                palette: ZyraDevPalette.deepEmerald,
                hapticLevel: ZyraHapticLevel.strong,
                goldEnabled: true,
              ),
              onChooseHaptic: () => haptic++,
              onGoldChanged: (value) => gold = value,
            ),
          ),
        ),
      );
      expect(find.byKey(_background), findsNothing);
      expect(find.text('Strong'), findsOneWidget);
      await _tapVisible(tester, find.byKey(_haptics));
      await _tapVisible(tester, find.byKey(_gold));
      expect(haptic, 1);
      expect(gold, isFalse);
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
      expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.subtle);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
    },
  );

  testWidgets(
    'preview choices update only caller state and never member prefs',
    (tester) async {
      final state = await _mount(tester);
      final paletteCache = ZyraLocalPrefs.cachedAppPaletteName;
      final hapticCache = ZyraLocalPrefs.cachedHapticLevelName;
      expect(find.byKey(_background), findsNothing);
      await _openChoice(tester, _haptics);
      await tester.tap(find.text('Strong'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(_gold));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_gold));
      await tester.pumpAndSettle();
      expect(state.haptic, ZyraHapticLevel.strong);
      expect(state.hapticCalls, 1);
      expect(state.gold, isTrue);
      expect(state.goldCalls, 1);
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
      expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.subtle);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraLocalPrefs.cachedAppPaletteName, paletteCache);
      expect(ZyraLocalPrefs.cachedHapticLevelName, hapticCache);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preview header stays top-left and its sample uses Ivory for legacy input',
    (tester) async {
      final state = await _mount(tester);
      state.update(() => state.palette = ZyraDevPalette.deepEmerald);
      await tester.pump();
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('personalisation-preview-title')),
      );
      expect(title.style?.fontSize, ZyraText.pageTitleSize);
      expect(find.byType(BackButton), findsNothing);
      final sample = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(const ValueKey('personalisation_preview')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (sample.decoration as BoxDecoration).gradient,
        ZyraDevPalette.ivory.gradient,
      );
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
    },
  );

  testWidgets(
    'legacy preview background input is ignored without member writes',
    (tester) async {
      final state = await _mount(tester);
      final beforePalette = ZyraLocalPrefs.cachedAppPaletteName;
      final beforeRevision = ZyraLocalPrefs.cachedAppPaletteRevision;
      final beforeOwner = ZyraLocalPrefs.accountOwner;
      final beforeGeneration = ZyraLocalPrefs.bindingGeneration;
      final beforePrefs = await _persistedMemberPrefs(tester);
      final beforeDisk = {
        for (final key in beforePrefs.getKeys()) key: beforePrefs.get(key),
      };
      state.update(() => state.palette = ZyraDevPalette.midnightBlue);
      await tester.pump();
      expect(find.byKey(_background), findsNothing);
      final content = tester.widget<ZyraPersonalisationContent>(
        find.byType(ZyraPersonalisationContent),
      );
      expect(content.snapshot.palette, ZyraDevPalette.ivory);
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
      expect(ZyraLocalPrefs.cachedAppPaletteName, beforePalette);
      expect(ZyraLocalPrefs.cachedAppPaletteRevision, beforeRevision);
      expect(ZyraLocalPrefs.accountOwner, beforeOwner);
      expect(ZyraLocalPrefs.bindingGeneration, beforeGeneration);
      final afterPrefs = await _persistedMemberPrefs(tester);
      expect({
        for (final key in afterPrefs.getKeys()) key: afterPrefs.get(key),
      }, beforeDisk);
      expect(tester.takeException(), isNull);
      await _synchronizeMember(tester, null);
    },
  );

  testWidgets('in-place preview rebuild uses current supplied values', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.update(() {
      state.palette = ZyraDevPalette.deepEmerald;
      state.haptic = ZyraHapticLevel.medium;
      state.gold = true;
    });
    await tester.pump();
    expect(find.byKey(_background), findsNothing);
    expect(find.text('Medium'), findsOneWidget);
    expect(tester.widget<Switch>(find.byKey(_gold)).value, isTrue);
    expect(state.hapticCalls + state.goldCalls, 0);
  });

  testWidgets(
    'retained gold callback cannot overwrite a newer supplied snapshot',
    (tester) async {
      final state = await _mount(tester);
      final retained = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
      state.update(() => state.gold = true);
      await tester.pump();
      retained(false);
      await tester.pump();
      expect(state.gold, isTrue);
      expect(state.goldCalls, 0);
    },
  );

  testWidgets('observed preview denial stays revoked after owner returns', (
    tester,
  ) async {
    final state = await _mount(tester);
    final retained = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
    state.update(() => state.allowed = false);
    await tester.pump();
    expect(find.byKey(_unavailable), findsOneWidget);
    state.update(() => state.allowed = true);
    await tester.pump();
    retained(true);
    expect(state.goldCalls, 0);
    expect(find.byKey(_unavailable), findsOneWidget);
    expect(ZyraAppGoldStyle.instance.enabled, isFalse);
  });

  testWidgets('exceptional preview admission is fail-closed without escaping', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.update(() => state.exceptional = true);
    await tester.pump();
    expect(find.byKey(_unavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
    state.update(() => state.exceptional = false);
    await tester.pump();
    expect(find.byKey(_unavailable), findsOneWidget);
  });

  testWidgets(
    'preview constructor cannot become member setters in same State',
    (tester) async {
      final state = await _mount(tester);
      final retained = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
      state.update(() => state.preview = false);
      await tester.pump();
      expect(find.byKey(_unavailable), findsOneWidget);
      retained(true);
      expect(state.goldCalls, 0);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
    },
  );

  testWidgets(
    'member constructor cannot become preview authority in same State',
    (tester) async {
      var preview = false;
      var calls = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return preview
                  ? PersonalisationScreen.preview(
                      key: const ValueKey('mode-owner'),
                      canAct: () => true,
                      palette: ZyraDevPalette.deepEmerald,
                      hapticLevel: ZyraHapticLevel.strong,
                      goldEnabled: true,
                      onHapticChanged: (_) => calls++,
                      onGoldChanged: (_) => calls++,
                    )
                  : const PersonalisationScreen(key: ValueKey('mode-owner'));
            },
          ),
        ),
      );
      final retained = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
      rebuild(() => preview = true);
      await tester.pump();
      retained(true);
      expect(find.byKey(_unavailable), findsOneWidget);
      expect(calls, 0);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
    },
  );

  testWidgets('preview without an owning route never mounts actions', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      PersonalisationScreen.preview(
        canAct: () => true,
        palette: ZyraDevPalette.midnightPlum,
        hapticLevel: ZyraHapticLevel.subtle,
        goldEnabled: false,
        onHapticChanged: (_) => calls++,
        onGoldChanged: (_) => calls++,
      ),
    );
    expect(find.byKey(_unavailable), findsOneWidget);
    expect(find.byKey(_gold), findsNothing);
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'denial while sheet is pending cannot apply its returned choice',
    (tester) async {
      final state = await _mount(tester);
      await _openChoice(tester, _haptics);
      state.update(() => state.allowed = false);
      await tester.pump();
      await tester.tap(find.text('Strong'));
      await tester.pumpAndSettle();
      expect(state.hapticCalls, 0);
      expect(state.haptic, ZyraHapticLevel.subtle);
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
    },
  );

  testWidgets(
    'owner containing parent-route guard survives its own choice sheet',
    (tester) async {
      final state = await _mount(tester, guardUsesRoute: true);
      await _openChoice(tester, _haptics);
      await tester.tap(find.text('Strong'));
      await tester.pumpAndSettle();
      expect(state.hapticCalls, 1);
      expect(state.haptic, ZyraHapticLevel.strong);
      expect(find.byKey(_unavailable), findsNothing);
    },
  );

  testWidgets(
    'covered sheet callback cannot pop covering route or change state',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final state = await _mount(tester, navigatorKey: navigator);
      await _openChoice(tester, _haptics);
      final sheet = tester
          .widget<ZyraPersonalisationChoiceSheet<ZyraHapticLevel>>(
            find.byType(ZyraPersonalisationChoiceSheet<ZyraHapticLevel>),
          );
      navigator.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
      );
      await tester.pumpAndSettle();
      sheet.onSelected(ZyraHapticLevel.strong);
      await tester.pump();
      expect(find.text('Cover'), findsOneWidget);
      expect(state.hapticCalls, 0);
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('backgrounded picker completion is cancelled after resuming', (
    tester,
  ) async {
    final state = await _mount(tester);
    await _openChoice(tester, _haptics);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Strong'));
    await tester.pumpAndSettle();
    expect(state.hapticCalls, 0);
    expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.subtle);
  });

  testWidgets('callback replacement invalidates an outstanding choice intent', (
    tester,
  ) async {
    final state = await _mount(tester);
    await _openChoice(tester, _haptics);
    state.update(() => state.alternateCallbacks = true);
    await tester.pump();
    await tester.tap(find.text('Strong'));
    await tester.pumpAndSettle();
    expect(state.hapticCalls, 0);
    expect(state.alternateCalls, 0);
    expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
  });

  testWidgets('disposed preview leaves retained choices inert', (tester) async {
    final state = await _mount(tester);
    await _openChoice(tester, _haptics);
    final sheet = tester
        .widget<ZyraPersonalisationChoiceSheet<ZyraHapticLevel>>(
          find.byType(ZyraPersonalisationChoiceSheet<ZyraHapticLevel>),
        );
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    sheet.onSelected(ZyraHapticLevel.strong);
    await tester.pumpAndSettle();
    expect(state.hapticCalls, 0);
    expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'member Ivory leaves stored legacy background and revision untouched',
    (tester) async {
      await _completeMemberOperation(tester, () async {
        await ZyraLocalPrefs.setCachedAppPaletteName('midnightBlue');
        await ZyraLocalPrefs.setCachedAppPaletteRevision('legacy-revision');
      }, 'seed legacy member background preferences');
      final beforePrefs = await _persistedMemberPrefs(tester);
      final beforeDisk = {
        for (final key in beforePrefs.getKeys()) key: beforePrefs.get(key),
      };
      ZyraColors.restoreCurrentAppPalette();
      ZyraColors.selectAppPalette(ZyraDevPalette.deepEmerald);
      await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));
      expect(find.byKey(_background), findsNothing);
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
      expect(ZyraLocalPrefs.cachedAppPaletteName, 'midnightBlue');
      expect(ZyraLocalPrefs.cachedAppPaletteRevision, 'legacy-revision');
      final afterPrefs = await _persistedMemberPrefs(tester);
      expect({
        for (final key in afterPrefs.getKeys()) key: afterPrefs.get(key),
      }, beforeDisk);
      expect(find.byType(BackButton), findsNothing);
      await _synchronizeMember(tester, null);
    },
  );

  testWidgets('member haptic remains connected and Poppins remains fixed', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));
    await _openChoice(tester, _haptics);
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.medium);
    expect(ZyraLocalPrefs.cachedHapticLevelName, ZyraHapticLevel.medium.name);
    expect(ZyraText.appFont, ZyraAppFont.poppins);
    final prefs = await _persistedMemberPrefs(tester);
    expect(prefs.getString('zyra.cached_account_owner'), 'member-a');
    expect(prefs.getString('zyra.haptic_level'), ZyraHapticLevel.medium.name);
    await _synchronizeMember(tester, null);
  });

  testWidgets(
    'member choice cannot stamp an account that changed while sheet was open',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));
      await _openChoice(tester, _haptics);
      await _synchronizeMember(tester, 'member-b');
      await tester.pump();
      await tester.tap(find.text('Strong'));
      await tester.pumpAndSettle();
      expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.subtle);
      expect(ZyraLocalPrefs.cachedHapticLevelName, isNull);
      expect(find.byKey(_unavailable), findsOneWidget);
    },
  );

  testWidgets(
    'member A-to-B-to-A lifetime still rejects retained gold callback',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));
      final retained = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
      await _synchronizeMember(tester, 'member-b');
      await _synchronizeMember(tester, 'member-a');
      retained(true);
      await tester.pump();
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
    },
  );

  testWidgets('member haptic choice cannot overwrite a newer selection', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));
    await _openChoice(tester, _haptics);
    final sheet = tester
        .widget<ZyraPersonalisationChoiceSheet<ZyraHapticLevel>>(
          find.byType(ZyraPersonalisationChoiceSheet<ZyraHapticLevel>),
        );
    ZyraInteractionStyle.restoreHapticLevel(ZyraHapticLevel.strong.name);
    final choice = sheet.options.firstWhere(
      (option) => option != ZyraHapticLevel.strong,
    );
    sheet.onSelected(choice);
    await tester.pumpAndSettle();
    expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.strong);
    expect(ZyraLocalPrefs.cachedHapticLevelName, isNull);
  });

  testWidgets('member gold rejects an older selection revision', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));
    final retained = tester.widget<Switch>(find.byKey(_gold)).onChanged!;
    ZyraAppGoldStyle.instance.select(
      true,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: ZyraAppGoldStyle.instance.revision,
    );
    await tester.pump();
    retained(false);
    await tester.pump();
    expect(ZyraAppGoldStyle.instance.enabled, isTrue);
    expect(ZyraLocalPrefs.cachedAppGoldEnabled, isTrue);
    final prefs = await _persistedMemberPrefs(tester);
    expect(prefs.getString('zyra.cached_account_owner'), 'member-a');
    expect(prefs.getBool('zyra.app_gold_enabled'), isTrue);
    await _synchronizeMember(tester, null);
  });

  testWidgets(
    'compact large text retains reachable controls without layout exceptions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey<_PreviewHarnessState>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: _PreviewHarness(key: key),
        ),
      );
      await _tapVisible(tester, find.byKey(_gold));
      expect(key.currentState!.goldCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
