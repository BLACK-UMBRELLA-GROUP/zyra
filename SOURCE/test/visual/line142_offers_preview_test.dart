import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_membership_preview.dart';
import 'package:zyra/dev/zyra_pause_private_preview.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/models/zyra_offers_preview.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';

import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _capture = bool.fromEnvironment('ZYRA_LINE142_CAPTURE');
Finder _key(String name) => find.byKey(ValueKey(name));

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(WidgetTester t, String id, {bool larger = false}) {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    return BaselineHarness(
      t,
      group: 'line142_$id',
      logicalSize: larger ? const Size(375, 667) : const Size(430, 932),
      textScale: larger ? 1.3 : 1,
      outputRoot: 'build/line142/screens',
      evidenceRoot: 'build/line142/screens',
      flatOutput: true,
      safePadding: larger
          ? const EdgeInsets.only(top: 20)
          : const EdgeInsets.only(top: 59, bottom: 34),
    );
  }

  Future<void> audit(BaselineHarness h, String id) async {
    if (!_capture && !baselineTextAuditOnly) return;
    final shadows = debugDisableShadows;
    try {
      debugDisableShadows = false;
      await h.tester.pump(const Duration(milliseconds: 2600));
      await h.capture('offers', id, 'normal', id, fileName: '$id.png');
      if (baselineTextAuditOnly) return;
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(
        _key('zyra-founder-baseline-boundary'),
      );
      final result = await auditZyraRenderedText(h.tester, boundary);
      expect(result.failures, isEmpty, reason: '$id ${result.toJson()}');
    } finally {
      debugDisableShadows = shadows;
    }
  }

  test('sample retention excludes trial, unpaid months and active wait', () {
    final accepted = DateTime.utc(2026, 8, 31);
    for (final mode in ZyraRetentionMode.values) {
      final offer = ZyraRetentionOfferPreview(mode: mode, guardian: false);
      expect(
        offer.isEligible(trial: true, paidMonths: 2, now: accepted),
        isFalse,
      );
      expect(
        offer.isEligible(trial: false, paidMonths: 1, now: accepted),
        isFalse,
      );
      expect(
        offer.isEligible(trial: false, paidMonths: 2, now: accepted),
        isTrue,
      );
      final boundary = mode == ZyraRetentionMode.growth
          ? DateTime.utc(2027, 2, 28)
          : DateTime.utc(2027, 8, 31);
      expect(
        offer.isEligible(
          trial: false,
          paidMonths: 2,
          now: boundary.subtract(const Duration(seconds: 1)),
          lastAccepted: accepted,
        ),
        isFalse,
      );
      expect(
        offer.isEligible(
          trial: false,
          paidMonths: 2,
          now: boundary,
          lastAccepted: accepted,
        ),
        isTrue,
      );
    }
  });

  testWidgets('o01 Seeker Delete shows Pause while Guardian Delete does not', (
    t,
  ) async {
    final h = harness(t, 'o01');
    await h.mount(tab: 4);
    await h.tap('concept_settings');
    await h.tap('concept_settings_advanced');
    await h.tap('help_row_Delete my account');
    expect(find.text('Need a break instead?'), findsOneWidget);
    expect(_key('offer_pause_before_delete'), findsOneWidget);
    await audit(h, 'o01');
    await h.tap('offer_pause_before_delete');
    final pause = find.byType(ZyraPausePrivatePreview);
    expect(_key('pause_profile_page'), findsOneWidget);
    expect(t.widget<ZyraPausePrivatePreview>(pause).privatePage, isFalse);
    expect(find.text('Your profile is visible'), findsOneWidget);
    expect(find.text('1 week'), findsNothing);
    expect(find.text('1 month'), findsNothing);
    await h.tap('pause_private_action');
    expect(find.text('Your profile is paused'), findsOneWidget);
    expect(find.text('Show my profile again'), findsOneWidget);
    await h.tap('pause_private_action');
    expect(find.text('Your profile is visible'), findsOneWidget);
    await h.mount(guardian: true, tab: 4);
    await h.tap('concept_settings');
    await h.tap('concept_settings_advanced');
    await h.tap('help_row_Delete my account');
    expect(find.text('Need a break instead?'), findsNothing);
    expect(_key('offer_pause_before_delete'), findsNothing);
  });

  for (final (id, mode, guardian, stayText) in [
    ('o02', ZyraRetentionMode.growth, false, 'Stay for £14.99 a month'),
    ('o03', ZyraRetentionMode.normal, false, 'Stay for £14.99'),
    ('o04', ZyraRetentionMode.growth, true, 'Stay for £9.99 a month'),
  ]) {
    testWidgets(
      '$id paid role opens locked offer and Continue reaches subscriptions',
      (t) async {
        final launches = <String>[];
        _recordSubscriptions(launches);
        final h = harness(t, id);
        await h.mount(
          guardian: guardian,
          tab: 4,
          offerChoices: ZyraPreviewOfferChoices(retentionMode: mode),
        );
        await h.tap('concept_membership');
        await h.tap('concept_cancel_membership');
        expect(_key('membership_paid_page'), findsOneWidget);
        expect(_key('retention_offer_sheet'), findsOneWidget);
        expect(find.text(stayText), findsOneWidget);
        expect(launches, isEmpty);
        await audit(h, id);
        await h.tap('retention_offer_continue');
        expect(launches, ['https://apps.apple.com/account/subscriptions']);
        expect(_key('retention_offer_sheet'), findsNothing);
      },
    );
  }

  testWidgets(
    'a trial skips the sheet; Stay consumes only the local sample offer',
    (t) async {
      final launches = <String>[];
      _recordSubscriptions(launches);
      final h = harness(t, 'trial');
      await h.mount(
        tab: 4,
        membershipRecords: {
          ZyraWalletRole.seeker: ZyraMembershipPreviewRecord(
            date: DateTime(2026, 12, 6),
            trial: true,
            paidMonths: 2,
          ),
        },
      );
      await h.tap('concept_membership');
      await h.tap('concept_cancel_membership');
      expect(_key('retention_offer_sheet'), findsNothing);
      expect(launches, hasLength(1));
      await h.mount(tab: 4);
      await h.tap('concept_membership');
      await h.tap('concept_cancel_membership');
      await h.tapText('Stay for £14.99 a month');
      expect(launches, hasLength(1));
      expect(
        find.text(
          'Thank you for staying. Your offer starts at your next renewal.',
        ),
        findsOneWidget,
      );
      await h.tap('concept_cancel_membership');
      expect(_key('retention_offer_sheet'), findsNothing);
      expect(launches, hasLength(2));
    },
  );

  for (final (id, eid, guardian, basic, label) in [
    ('o05', ZyraPreviewEid.fitr, false, false, '3 Compatibility Unlocks'),
    ('o06', ZyraPreviewEid.adha, false, false, '25% off your next month'),
    ('o07', ZyraPreviewEid.fitr, false, true, '1 Compatibility Unlock'),
    ('o08', ZyraPreviewEid.fitr, true, false, '25% off your next month'),
    ('o09', ZyraPreviewEid.fitr, true, true, '3 days of Guardian One'),
  ]) {
    testWidgets('$id Eid card and the gift for the current plan', (t) async {
      final h = harness(t, id);
      await h.mount(
        guardian: guardian,
        tab: 2,
        receivedRequest: false,
        initialSeekerBasic: !guardian && basic,
        initialGuardianBasic: guardian && basic,
        seekerMembership: !guardian && basic ? 'Seeker Basic' : 'Seeker One',
        guardianMembership: guardian && basic
            ? 'Guardian Basic'
            : 'Guardian One',
        offerChoices: ZyraPreviewOfferChoices(eid: eid),
      );
      if (id == 'o05') await audit(h, 'o12');
      await h.tap('preview_open_eid_gift');
      h.assertPage('eid_gift_preview');
      expect(find.text(label), findsOneWidget);
      expect(
        find.text('Eid Mubarak, ${guardian ? 'Hassan' : 'Adam'}'),
        findsOneWidget,
      );
      expect(find.text('Eid al-Fitr'), findsNothing);
      expect(find.text('Eid al-Adha'), findsNothing);
      await audit(h, id);
      await h.tapText('Thank you');
      expect(_key('preview_open_eid_gift'), findsOneWidget);
    });
  }

  testWidgets('o10–o11 Ramadan entry is once per preview and rules are in app', (
    t,
  ) async {
    final h = harness(t, 'o10');
    await h.mount(
      tab: 2,
      receivedRequest: false,
      offerChoices: const ZyraPreviewOfferChoices(ramadan: true),
    );
    await h.tap('preview_open_ramadan_draw');
    await h.tap('preview_draw_rules');
    expect(
      find.textContaining(
        'Apple is not a sponsor of this draw and is not involved in it in any way.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Full terms'), findsNothing);
    await audit(h, 'o10');
    final submit = t
        .widget<FilledButton>(
          find.ancestor(
            of: find.text('Enter the draw'),
            matching: find.byType(FilledButton),
          ),
        )
        .onPressed!;
    await h.tapText('Enter the draw');
    expect(_key('preview_draw_entered'), findsOneWidget);
    submit();
    await h.flush();
    expect(_key('preview_draw_entered'), findsOneWidget);
    expect(find.text('Enter the draw'), findsNothing);
    await audit(h, 'o11');
    await t.binding.handlePopRoute();
    await h.flush();
    await h.tap('preview_open_ramadan_draw');
    expect(_key('preview_draw_entered'), findsOneWidget);
    await h.mount(tab: 2, receivedRequest: false);
    expect(_key('preview_open_ramadan_draw'), findsNothing);
  });

  testWidgets('Ramadan entry follows the login across profile switches', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ZyraAccountState.resetForTesting();
    addTearDown(ZyraAccountState.resetForTesting);
    await t.runAsync(() => ZyraAccountState.synchronize('ramadan-sample-a'));
    final accountGeneration = ZyraAccountState.generation;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final h = harness(t, 'ramadan_owner');
    const offers = ZyraPreviewOfferChoices(ramadan: true);
    await h.mount(tab: 2, receivedRequest: false, offerChoices: offers);

    Future<void> switchProfile({required bool guardian}) async {
      await h.tap('floating-nav-item-4');
      await h.tap('switch-account-button');
      h.assertPage('switch_account_signup');
      await h.tap('small_pages_switch_role');
      expect(h.latest.guardian, guardian);
      expect(h.latest.pages, isEmpty);
      if (!guardian) await h.tap('floating-nav-item-2');
    }

    await h.tap('preview_open_ramadan_draw');
    final enter = find.text('Enter the draw');
    final retiredSubmit = t
        .widget<FilledButton>(
          find.ancestor(of: enter, matching: find.byType(FilledButton)),
        )
        .onPressed!;
    await h.tapText('Enter the draw');
    expect(_key('preview_draw_entered'), findsOneWidget);
    await t.binding.handlePopRoute();
    await h.flush();

    for (final guardian in [true, false]) {
      await switchProfile(guardian: guardian);
      expect(ZyraAccountState.userId, 'ramadan-sample-a');
      expect(ZyraAccountState.generation, accountGeneration);
      await h.tap('preview_open_ramadan_draw');
      expect(_key('preview_draw_entered'), findsOneWidget);
      expect(enter, findsNothing);
      await t.binding.handlePopRoute();
      await h.flush();
    }

    await t.runAsync(() => ZyraAccountState.synchronize('ramadan-sample-b'));
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await h.mount(tab: 2, receivedRequest: false, offerChoices: offers);
    await h.tap('preview_open_ramadan_draw');
    retiredSubmit();
    await h.flush();
    expect(_key('preview_draw_entered'), findsNothing);
    expect(enter.hitTestable(), findsOneWidget);
    await h.tapText('Enter the draw');
    expect(_key('preview_draw_entered'), findsOneWidget);
  });

  for (final guardian in [false, true]) {
    testWidgets('o13–o14 profile label contains plan only', (t) async {
      final h = harness(t, guardian ? 'o14' : 'o13');
      for (final basic in [false, true]) {
        final role = guardian ? 'Guardian' : 'Seeker';
        final label = '$role ${basic ? 'Basic' : 'One'}';
        await h.mount(
          guardian: guardian,
          tab: 4,
          initialSeekerBasic: !guardian && basic,
          initialGuardianBasic: guardian && basic,
          seekerMembership: !guardian && basic ? label : 'Seeker One',
          guardianMembership: guardian && basic ? label : 'Guardian One',
        );
        expect(find.text(label.toUpperCase()), findsOneWidget);
        expect(
          find.text('${label.toUpperCase()} · ${role.toUpperCase()}'),
          findsNothing,
        );
        if (!basic) await audit(h, guardian ? 'o14' : 'o13');
      }
    });
  }

  testWidgets('larger text: Ramadan rules scroll above pinned Enter', (
    t,
  ) async {
    final h = harness(t, 'ramadan_large', larger: true);
    await h.mount(
      tab: 2,
      receivedRequest: false,
      offerChoices: const ZyraPreviewOfferChoices(ramadan: true),
    );
    await h.tap('preview_open_ramadan_draw');
    await h.tap('preview_draw_rules');
    expect(t.takeException(), isNull);
    expect(find.text('Enter the draw').hitTestable(), findsOneWidget);
  });
}

void _recordSubscriptions(List<String> launches) {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'launch') {
      launches.add((call.arguments as Map)['url'] as String);
    }
    return true;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}
