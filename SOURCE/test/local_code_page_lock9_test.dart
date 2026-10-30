import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_local_code_aliases.dart';
import 'package:zyra/dev/zyra_draft_local_code_page.dart';
import 'package:zyra/dev/zyra_draft_code_entry.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';

const fieldKey = ValueKey('local-code-field');
const checkKey = ValueKey('local-code-check');
const sendKey = ValueKey('local-code-send');
Finder key(String name) => find.byKey(ValueKey(name));

class NoCodeNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('LOCK9 local page cannot use a network client');
  }
}

Future<void> pressCode(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> enterCode(WidgetTester t, String value) async {
  await t.enterText(find.byKey(fieldKey), value);
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
}

void main() {
  late NoCodeNetwork network;
  final prior = HttpOverrides.current;
  setUp(() {
    network = NoCodeNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = prior;
    ZyraText.useTestFontStubs = false;
  });

  Future<void> mount(
    WidgetTester t, {
    ZyraLocalCodeContext mode = ZyraLocalCodeContext.scan,
    bool Function()? canAct,
    bool Function()? canInteract,
    Object Function()? epoch,
    Object owner = 'owner',
    Future<ZyraLocalCodeIdentity?> Function(String)? lookup,
    ZyraLocalCaptureBuilder? capture,
    GlobalKey<NavigatorState>? navigator,
    double scale = 1,
    Size size = const Size(430, 932),
  }) async {
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: ZyraLocalCodePage(
            mode: mode,
            ownerKey: owner,
            canAct: canAct ?? () => true,
            canInteract: canInteract,
            interactionEpoch: epoch,
            personalCode: 'ZYRA-DEMO-GUARDIAN-IBRAHIM',
            captureBuilder: capture,
            lookupCode:
                lookup ??
                (code) async => ZyraLocalCodeIdentity(
                  'Sample',
                  mode == ZyraLocalCodeContext.addGuardian
                      ? 'Guardian'
                      : 'Seeker',
                ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  test(
    'all explicit aliases are20 nonhex and adapt exact canonical samples only',
    () {
      expect(
        ZyraPersonalCode.fromRow({
          'code': 'ZYRA-AAAA-BBBB-CCCC-DDDD-EEEE',
          'role_context': 'seeker',
        }),
        isNotNull,
      );
      for (final mode in ZyraLocalCodeContext.values) {
        final aliases = ZyraLocalCodeAliases.forContext(mode);
        expect(aliases.values.toSet().length, aliases.length);
        for (final entry in aliases.entries) {
          expect(entry.key, matches(RegExp(r'^[A-Z0-9]{20}$')));
          expect(entry.key, contains(RegExp('[G-Z]')));
          expect(
            ZyraLocalCodeAliases.entry(mode, entry.value.toLowerCase()),
            entry.key,
          );
          final grouped = List.generate(
            5,
            (i) => entry.key.substring(i * 4, i * 4 + 4),
          ).join('-');
          for (final code in [entry.key, 'ZYRA-$grouped']) {
            expect(
              ZyraPersonalCode.fromRow({
                'code': code,
                'role_context': 'seeker',
              }),
              isNull,
            );
          }
          for (final raw in [
            'https://example/$grouped',
            '${entry.value}-EXTRA',
            'WRONG-${entry.value}',
          ]) {
            expect(ZyraLocalCodeAliases.entry(mode, raw), isNull);
          }
        }
      }
      for (final code in ZyraLocalCodeAliases.scan.values) {
        expect(ZyraDraftKnownPersonCodes.resolve(code), isNotNull);
      }
    },
  );

  testWidgets(
    'five boxes fill uppercase on type and canonical paste with one field label',
    (t) async {
      await mount(t);
      await enterCode(t, '7k2m q9td!4h');
      expect(
        t.widget<TextField>(find.byKey(fieldKey)).controller!.text,
        '7K2MQ9TD4H',
      );
      expect(find.text('7K2M'), findsOneWidget);
      expect(find.text('Q9TD'), findsOneWidget);
      expect(find.text('4H'), findsOneWidget);
      final semantics = t.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp('ZYRA Code, 20 characters')),
        findsOneWidget,
      );
      semantics.dispose();
      await enterCode(t, 'ZYRA-DRAFT-SARA');
      expect(
        t.widget<TextField>(find.byKey(fieldKey)).controller!.text,
        ZyraLocalCodeAliases.master,
      );
      for (final part in ['7K2M', 'Q9TD', '4HXA', '2B8C', '5E1F']) {
        expect(find.text(part), findsOneWidget);
      }
    },
  );

  testWidgets(
    'every length0 through19 errors before lookup; Check is enabled gold',
    (t) async {
      int calls = 0;
      await mount(
        t,
        lookup: (_) async {
          calls++;
          return null;
        },
      );
      for (int length = 0; length < 20; length++) {
        await enterCode(t, 'A' * length);
        await pressCode(t, find.byKey(checkKey));
        expect(find.text('Enter all 20 characters.'), findsOneWidget);
        ScaffoldMessenger.of(t.element(find.byKey(checkKey))).clearSnackBars();
        await t.pumpAndSettle();
      }
      expect(calls, 0);
    },
  );

  testWidgets(
    'unknown20, real hex and malformed paste never call canonical reader',
    (t) async {
      int calls = 0;
      await mount(
        t,
        lookup: (_) async {
          calls++;
          return null;
        },
      );
      for (final value in ['Z' * 20, 'A' * 20]) {
        await enterCode(t, value);
        await pressCode(t, find.byKey(checkKey));
        expect(find.text('That code is not available.'), findsOneWidget);
      }
      await enterCode(t, '');
      for (final value in [
        'https://example/ZYRA-DRAFT-SARA',
        '${ZyraLocalCodeAliases.master}EXTRA',
      ]) {
        await enterCode(t, value);
        expect(
          t.widget<TextField>(find.byKey(fieldKey)).controller!.text,
          isEmpty,
        );
      }
      expect(calls, 0);
    },
  );

  for (final mode in ZyraLocalCodeContext.values) {
    testWidgets(
      '$mode found reveals first name and role; only Add can locally send',
      (t) async {
        final seen = <String>[];
        await mount(
          t,
          mode: mode,
          lookup: (raw) async {
            seen.add(raw);
            return ZyraLocalCodeIdentity(
              'Sample',
              mode == ZyraLocalCodeContext.addGuardian ? 'Guardian' : 'Seeker',
            );
          },
        );
        await enterCode(t, ZyraLocalCodeAliases.master);
        await pressCode(t, find.byKey(checkKey));
        expect(find.text('Sample'), findsOneWidget);
        expect(find.textContaining('first name and role only'), findsOneWidget);
        expect(seen, [
          ZyraLocalCodeAliases.canonical(mode, ZyraLocalCodeAliases.master),
        ]);
        expect(find.text('View profile'), findsNothing);
        expect(find.text('How are you related?'), findsNothing);
        if (mode != ZyraLocalCodeContext.scan) {
          await pressCode(t, find.byKey(sendKey));
          expect(find.text('Request sent'), findsOneWidget);
          expect(find.byType(BottomSheet), findsNothing);
          expect(find.textContaining('once they accept.'), findsOneWidget);
          expect(find.byKey(sendKey), findsNothing);
        } else {
          expect(find.byKey(sendKey), findsNothing);
        }
      },
    );
  }

  for (final identity in [
    const ZyraLocalCodeIdentity('', 'Seeker'),
    const ZyraLocalCodeIdentity('Wrong', 'Guardian'),
  ]) {
    testWidgets(
      'empty or wrong-role local result cannot disclose identity $identity',
      (t) async {
        await mount(t, lookup: (_) async => identity);
        await enterCode(t, ZyraLocalCodeAliases.master);
        await pressCode(t, find.byKey(checkKey));
        expect(find.text('That code is not available.'), findsOneWidget);
        expect(find.text('Wrong'), findsNothing);
      },
    );
  }

  testWidgets('lookup exception retains existing error without live fallback', (
    t,
  ) async {
    await mount(t, lookup: (_) async => throw StateError('local failure'));
    await enterCode(t, ZyraLocalCodeAliases.master);
    await pressCode(t, find.byKey(checkKey));
    expect(
      find.text("The code couldn't be checked. Please try again."),
      findsOneWidget,
    );
  });

  for (final interruption in [
    'edit',
    'epoch',
    'cover',
    'background',
    'revoke',
    'dispose',
    'rebind',
  ]) {
    testWidgets('pending lookup cannot publish after $interruption', (t) async {
      final held = Completer<ZyraLocalCodeIdentity?>();
      bool allowed = true;
      int epoch = 0;
      final nav = GlobalKey<NavigatorState>();
      Future<ZyraLocalCodeIdentity?> lookup(String _) => held.future;
      bool guard() => allowed;
      Object readEpoch() => epoch;
      await mount(
        t,
        lookup: lookup,
        canAct: guard,
        epoch: readEpoch,
        navigator: nav,
      );
      await enterCode(t, ZyraLocalCodeAliases.master);
      await t.tap(find.byKey(checkKey));
      await t.pump();
      switch (interruption) {
        case 'edit':
          await enterCode(t, 'Z' * 20);
        case 'epoch':
          epoch += 2;
        case 'cover':
          nav.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('cover')),
            ),
          );
          await t.pumpAndSettle();
          nav.currentState!.pop();
          await t.pumpAndSettle();
        case 'background':
          for (final state in [
            AppLifecycleState.inactive,
            AppLifecycleState.hidden,
            AppLifecycleState.paused,
          ]) {
            t.binding.handleAppLifecycleStateChanged(state);
          }
          await t.pump();
          for (final state in [
            AppLifecycleState.hidden,
            AppLifecycleState.inactive,
            AppLifecycleState.resumed,
          ]) {
            t.binding.handleAppLifecycleStateChanged(state);
          }
        case 'revoke':
          allowed = false;
        case 'dispose':
          await t.pumpWidget(const SizedBox());
        case 'rebind':
          await mount(
            t,
            owner: 'replacement',
            lookup: lookup,
            canAct: guard,
            epoch: readEpoch,
            navigator: nav,
          );
      }
      held.complete(const ZyraLocalCodeIdentity('Stale', 'Seeker'));
      await t.pumpAndSettle();
      expect(find.text('Stale'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets(
    'stale send callback after input edit and epoch change cannot claim sent',
    (t) async {
      int epoch = 0;
      await mount(
        t,
        mode: ZyraLocalCodeContext.addGuardian,
        epoch: () => epoch,
      );
      await enterCode(t, ZyraLocalCodeAliases.master);
      await pressCode(t, find.byKey(checkKey));
      final tap = t
          .widget<InkWell>(
            find.descendant(
              of: find.byKey(sendKey),
              matching: find.byType(InkWell),
            ),
          )
          .onTap!;
      epoch += 2;
      tap();
      await t.pumpAndSettle();
      expect(find.text('Request sent'), findsNothing);
      await enterCode(t, 'Z' * 20);
      tap();
      await t.pumpAndSettle();
      expect(find.text('Request sent'), findsNothing);
    },
  );

  testWidgets(
    'guarded camera canonical capture is one-shot and typing keeps it mounted',
    (t) async {
      late bool Function() canCapture;
      late ValueChanged<String> detected;
      int calls = 0;
      await mount(
        t,
        capture: (context, guard, code, manual) {
          canCapture = guard;
          detected = code;
          return const Center(child: Text('fake guarded camera'));
        },
        lookup: (raw) async {
          calls++;
          return const ZyraLocalCodeIdentity('Sara', 'Seeker');
        },
      );
      await t.tap(key('local-code-camera'));
      await t.pumpAndSettle();
      final oldCapture = detected;
      await enterCode(t, '7k2m');
      expect(find.text('fake guarded camera'), findsOneWidget);
      expect(canCapture(), isTrue);
      oldCapture('ZYRA-DRAFT-SARA');
      oldCapture('ZYRA-DRAFT-AMIRA');
      await t.pumpAndSettle();
      expect(find.text('Sara'), findsOneWidget);
      expect(calls, 1);
      expect(canCapture(), isFalse);
    },
  );

  for (final mode in ZyraLocalCodeContext.values) {
    testWidgets(
      '$mode compact200 percent has no overflow and actions remain reachable',
      (t) async {
        await mount(t, mode: mode, scale: 2, size: const Size(320, 568));
        await enterCode(t, ZyraLocalCodeAliases.master);
        await pressCode(t, find.byKey(checkKey));
        if (mode != ZyraLocalCodeContext.scan) {
          await pressCode(t, find.byKey(sendKey));
        }
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('inactive permission prompt keeps the guarded scan session', (
    t,
  ) async {
    late bool Function() guard;
    late ValueChanged<String> detected;
    await mount(
      t,
      capture: (context, canCapture, onCode, manual) {
        guard = canCapture;
        detected = onCode;
        return const Text('permission camera');
      },
    );
    await t.tap(key('local-code-camera'));
    await t.pumpAndSettle();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    expect(guard(), isFalse);
    expect(find.text('permission camera'), findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(guard(), isTrue);
    detected('ZYRA-DRAFT-SARA');
    await t.pumpAndSettle();
    expect(find.text('Sample'), findsOneWidget);
  });

  testWidgets('throwing epoch fails closed without a build or tap exception', (
    t,
  ) async {
    await mount(t, epoch: () => throw StateError('revoked epoch'));
    expect(find.byKey(fieldKey), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('scan line moves slowly and reduced motion holds its position', (
    t,
  ) async {
    await mount(t);
    double top() => t.widget<Positioned>(key('local-code-scan-line')).top!;
    final first = top();
    await t.pump(const Duration(seconds: 1));
    expect(top(), greaterThan(first));
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ZyraLocalCodePage(
              mode: ZyraLocalCodeContext.scan,
              ownerKey: 'quiet',
              canAct: () => true,
              lookupCode: (_) async => null,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final quiet = top();
    await t.pump(const Duration(seconds: 1));
    expect(top(), quiet);
  });
  testWidgets(
    'enabled code tap emits one shared haptic and a revoked callback emits none',
    (t) async {
      int haptics = 0;
      bool allowed = true;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics++;
        if (call.method == 'Clipboard.hasStrings') {
          return <String, dynamic>{'value': false};
        }
        if (call.method == 'LiveText.isLiveTextInputAvailable') {
          return false;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await t.pumpWidget(
        MaterialApp(
          home: ZyraTapFeedback(
            level: () => ZyraHapticLevel.light,
            canAct: () => true,
            child: Scaffold(
              body: ZyraLocalCodePage(
                mode: ZyraLocalCodeContext.scan,
                ownerKey: 'haptic',
                canAct: () => allowed,
                lookupCode: (_) async => null,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final tap = t
          .widget<InkWell>(
            find.descendant(
              of: find.byKey(checkKey),
              matching: find.byType(InkWell),
            ),
          )
          .onTap!;
      await pressCode(t, find.byKey(checkKey));
      expect(haptics, 1);
      allowed = false;
      tap();
      await t.pumpAndSettle();
      expect(haptics, 1);
    },
  );
}
