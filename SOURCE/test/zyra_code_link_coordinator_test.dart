import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_code_link_coordinator.dart';
import 'package:zyra/services/zyra_code_link_service.dart';

const _member = 'member-a';
const _otherMember = 'member-b';
const _code = 'ZYRA-7A2F-09D4-B81C-3E6A-5F0D';
const _otherCode = 'ZYRA-0000-1111-2222-3333-4444';
const _link = 'https://zyraconnect.app/c/#$_code';
const _otherLink = 'https://zyraconnect.app/c/#$_otherCode';
const _received = ZyraCodeLinkResult(ZyraCodeLinkOutcome.addGuardian);
const _channel = MethodChannel('app.zyraconnect.zyra/code_links');

class _CoordinatorHarness {
  _CoordinatorHarness() {
    links = ZyraCodeLinkCoordinator(
      resolve: (code, {required isCurrent}) {
        checks.add(code);
        return resolve(isCurrent);
      },
    );
    links.configure(
      currentUser: () => user,
      canPresent: () => unlocked,
      showBadLink: () => invalidLinks++,
      open: (role, code, result) =>
          opened.add((role: role, code: code, outcome: result.outcome)),
    );
  }

  late final ZyraCodeLinkCoordinator links;
  final checks = <String>[];
  final opened =
      <
        ({
          ZyraCodeLinkMemberRole role,
          String code,
          ZyraCodeLinkOutcome outcome,
        })
      >[];
  bool unlocked = true;
  String? user;
  int invalidLinks = 0;
  Future<ZyraCodeLinkResult> Function(bool Function()) resolve = (_) async =>
      _received;

  void changeAccount(String? next) {
    user = next;
    links.accountChanged(next);
  }

  Object mount(ZyraCodeLinkMemberRole role) {
    final surface = Object();
    final owner = user!;
    links.memberMounted(
      surface,
      role: role,
      userId: owner,
      isCurrent: () => user == owner,
    );
    return surface;
  }
}

void main() {
  testWidgets('cold and warm native links each resolve exactly once', (
    tester,
  ) async {
    final harness = _CoordinatorHarness()..changeAccount(_member);
    harness.mount(ZyraCodeLinkMemberRole.seeker);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = StandardMethodCodec();
    messenger.setMockMethodCallHandler(_channel, (call) async {
      expect(call.method, 'takePendingCodeLink');
      return _link;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(_channel, null);
      _channel.setMethodCallHandler(null);
    });

    await harness.links.listenToNative();
    await tester.pumpAndSettle();
    expect(harness.checks, [_code]);

    await messenger.handlePlatformMessage(
      _channel.name,
      codec.encodeMethodCall(const MethodCall('openCodeLink', _otherLink)),
      null,
    );
    await tester.pumpAndSettle();
    expect(harness.checks, [_code, _otherCode]);
    expect(harness.opened.map((item) => item.code), [_code, _otherCode]);
  });

  testWidgets('signed-out link waits for the current member surface', (
    tester,
  ) async {
    final harness = _CoordinatorHarness();
    harness.links.receive(_link);
    await tester.pumpAndSettle();
    expect(harness.checks, isEmpty);
    expect(harness.opened, isEmpty);

    harness.changeAccount(_member);
    await tester.pumpAndSettle();
    expect(harness.checks, isEmpty);
    harness.mount(ZyraCodeLinkMemberRole.seeker);
    await tester.pumpAndSettle();
    expect(harness.checks, [_code]);
    expect(harness.opened, [
      (
        role: ZyraCodeLinkMemberRole.seeker,
        code: _code,
        outcome: ZyraCodeLinkOutcome.addGuardian,
      ),
    ]);

    harness.links.presentationChanged();
    await tester.pumpAndSettle();
    expect(harness.checks, [_code]);
    expect(harness.opened, hasLength(1));
  });

  testWidgets('bad link shows only the rejection after presentation is safe', (
    tester,
  ) async {
    final harness = _CoordinatorHarness()..unlocked = false;
    harness.links.receive('https://outside.example.invalid/c/#$_code');
    await tester.pumpAndSettle();
    expect(harness.invalidLinks, 0);

    harness.unlocked = true;
    harness.links.presentationChanged();
    await tester.pumpAndSettle();
    expect(harness.invalidLinks, 1);
    expect(harness.checks, isEmpty);
    expect(harness.opened, isEmpty);
  });

  testWidgets('App Lock preserves one in-flight result over surface teardown', (
    tester,
  ) async {
    final harness = _CoordinatorHarness()
      ..changeAccount(_member)
      ..unlocked = false;
    final reply = Completer<ZyraCodeLinkResult>();
    late bool Function() isCurrent;
    harness.resolve = (current) {
      isCurrent = current;
      return reply.future;
    };
    final original = harness.mount(ZyraCodeLinkMemberRole.seeker);
    harness.links.receive(_link);
    await tester.pumpAndSettle();
    expect(harness.checks, isEmpty);

    harness.unlocked = true;
    harness.links.presentationChanged();
    await tester.pumpAndSettle();
    expect(harness.checks, [_code]);

    harness.unlocked = false;
    harness.links.memberUnmounted(original);
    expect(isCurrent(), isTrue);
    reply.complete(_received);
    await tester.pumpAndSettle();
    expect(harness.opened, isEmpty);

    harness.unlocked = true;
    harness.mount(ZyraCodeLinkMemberRole.seeker);
    await tester.pumpAndSettle();
    expect(harness.checks, [_code]);
    expect(harness.opened, hasLength(1));
  });

  testWidgets('changing the account discards an in-flight result', (
    tester,
  ) async {
    final harness = _CoordinatorHarness()..changeAccount(_member);
    final reply = Completer<ZyraCodeLinkResult>();
    late bool Function() isCurrent;
    harness.resolve = (current) {
      isCurrent = current;
      return reply.future;
    };
    harness.mount(ZyraCodeLinkMemberRole.seeker);
    harness.links.receive(_link);
    await tester.pumpAndSettle();
    expect(harness.checks, [_code]);

    harness.changeAccount(null);
    harness.changeAccount(_otherMember);
    harness.mount(ZyraCodeLinkMemberRole.guardian);
    expect(isCurrent(), isFalse);
    reply.complete(_received);
    await tester.pumpAndSettle();
    expect(harness.opened, isEmpty);
    expect(harness.checks, [_code]);
  });

  testWidgets('Guardian sign-up resolves the carried code once after unlock', (
    tester,
  ) async {
    final harness = _CoordinatorHarness();
    final opened = <(String, ZyraCodeLinkOutcome)>[];
    final reply = Completer<ZyraCodeLinkResult>();
    harness.resolve = (_) => reply.future;
    void mountSignup(Object surface) {
      harness.links.guardianSignupMounted(
        surface,
        userId: _member,
        isCurrent: () => harness.unlocked,
        open: (code, result) => opened.add((code, result.outcome)),
      );
    }

    harness.links.receive(_link);
    await tester.pumpAndSettle();
    expect(harness.checks, isEmpty);

    harness.changeAccount(_member);
    final old = Object();
    mountSignup(old);
    await tester.pumpAndSettle();
    expect(harness.checks, [_code]);

    harness.unlocked = false;
    harness.links.guardianSignupUnmounted(old);
    reply.complete(const ZyraCodeLinkResult(ZyraCodeLinkOutcome.addSeeker));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);

    harness.unlocked = true;
    mountSignup(Object());
    await tester.pumpAndSettle();
    expect(opened, [(_code, ZyraCodeLinkOutcome.addSeeker)]);
    expect(harness.opened, isEmpty);
    expect(harness.checks, [_code]);
  });

  testWidgets('Founder preview receives canonical unknown code locally', (
    tester,
  ) async {
    final harness = _CoordinatorHarness()..changeAccount(_member);
    final delivered = <String>[];
    final preview = Object();
    harness.links.founderPreviewMounted(
      preview,
      userId: _member,
      isCurrent: () => true,
      openUnknownCode: delivered.add,
    );

    harness.links.receive(_link);
    await tester.pumpAndSettle();
    expect(delivered, [_code]);
    expect(harness.checks, isEmpty);

    harness.links.receive('https://zyraconnect.app/c/#ZYRA-DEMO-SEEKER-ADAM');
    await tester.pumpAndSettle();
    expect(harness.invalidLinks, 1);
    expect(delivered, [_code]);
    expect(harness.opened, isEmpty);
    harness.links.founderPreviewUnmounted(preview);
  });

  testWidgets('passes every resolver outcome with the active member role', (
    tester,
  ) async {
    final harness = _CoordinatorHarness()..changeAccount(_member);
    final seeker = harness.mount(ZyraCodeLinkMemberRole.seeker);
    const seekerOutcomes = [
      ZyraCodeLinkOutcome.addGuardian,
      ZyraCodeLinkOutcome.scan,
      ZyraCodeLinkOutcome.ownCode,
      ZyraCodeLinkOutcome.unavailable,
      ZyraCodeLinkOutcome.rateLimited,
      ZyraCodeLinkOutcome.failed,
    ];
    for (final outcome in seekerOutcomes) {
      harness.resolve = (_) async => ZyraCodeLinkResult(outcome);
      harness.links.receive(_link);
      await tester.pumpAndSettle();
      expect(harness.opened.last, (
        role: ZyraCodeLinkMemberRole.seeker,
        code: _code,
        outcome: outcome,
      ));
    }

    harness.links.memberUnmounted(seeker);
    harness.mount(ZyraCodeLinkMemberRole.guardian);
    harness.resolve = (_) async =>
        const ZyraCodeLinkResult(ZyraCodeLinkOutcome.addSeeker);
    harness.links.receive(_otherLink);
    await tester.pumpAndSettle();
    expect(harness.opened.last, (
      role: ZyraCodeLinkMemberRole.guardian,
      code: _otherCode,
      outcome: ZyraCodeLinkOutcome.addSeeker,
    ));
    expect(harness.checks, hasLength(seekerOutcomes.length + 1));
  });
}
