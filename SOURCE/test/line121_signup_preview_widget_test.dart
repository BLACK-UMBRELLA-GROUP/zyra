import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_swipe_track.dart';

class _NoNetwork extends HttpOverrides {
  int calls = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    calls++;
    throw StateError('Sign-up preview must stay local.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));
const _samplePhoto =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1sAAAAASUVORK5CYII=';

Future<void> _mount(
  WidgetTester tester,
  ZyraSignupPreviewController c, {
  TargetPlatform platform = TargetPlatform.iOS,
  bool Function()? canAct,
  VoidCallback? onPause,
  VoidCallback? onEnter,
  VoidCallback? onShare,
  Size size = const Size(430, 932),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: ZyraSignupPreview(
          controller: c,
          canAct: canAct ?? () => true,
          preferencesBuilder: (_) =>
              const Center(child: Text('Existing preference editor')),
          onPause: onPause ?? () {},
          onEnter: onEnter ?? () {},
          samplePhotos: const [_samplePhoto],
          ownCode: 'ZYRA-7Q4M-K2XD-9P3L-W8RT-F6NB',
          onShareCode: onShare ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _NoNetwork network;
  late HttpOverrides? prior;
  setUp(() {
    ZyraText.useTestFontStubs = true;
    prior = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    HttpOverrides.global = prior;
    ZyraText.useTestFontStubs = false;
    expect(network.calls, 0);
  });

  testWidgets(
    'Welcome orders providers by platform and contains no email entry',
    (tester) async {
      final c = ZyraSignupPreviewController();
      addTearDown(c.dispose);
      c.setStep(ZyraSignupStep.welcome);
      await _mount(tester, c);
      expect(
        tester.getTopLeft(_key('signup_apple')).dy,
        lessThan(tester.getTopLeft(_key('signup_google')).dy),
      );
      expect(find.byType(TextField), findsNothing);
      await _mount(tester, c, platform: TargetPlatform.android);
      expect(
        tester.getTopLeft(_key('signup_google')).dy,
        lessThan(tester.getTopLeft(_key('signup_apple')).dy),
      );
      await tester.tap(_key('signup_google'));
      await tester.pumpAndSettle();
      expect(c.step, ZyraSignupStep.role);
      expect(c.provider, 'Google');
    },
  );

  testWidgets('A retired role swipe cannot change a later step', (
    tester,
  ) async {
    final c = ZyraSignupPreviewController();
    addTearDown(c.dispose);
    c.setStep(ZyraSignupStep.role);
    await _mount(tester, c);
    final select = tester
        .widget<ZyraSwipeTrack>(find.byType(ZyraSwipeTrack))
        .onSettled;
    c.setStep(ZyraSignupStep.name);
    await tester.pumpAndSettle();
    select(1);
    expect(c.guardian, isFalse);
  });

  testWidgets('Name counters and numeric DOB red state follow the controller', (
    tester,
  ) async {
    final c = ZyraSignupPreviewController(now: () => DateTime(2026, 11, 19));
    addTearDown(c.dispose);
    c.setStep(ZyraSignupStep.name);
    await _mount(tester, c);
    expect(find.text('0/30'), findsNothing);
    expect(find.text('0/40'), findsNothing);
    expect(
      tester.widget<FilledButton>(_key('signup_continue')).onPressed,
      isNull,
    );
    await tester.enterText(_key('signup_first_name'), 'Adam');
    await tester.enterText(_key('signup_surname'), 'Hussain');
    await tester.pump();
    expect(find.text('4/30'), findsNothing);
    await tester.enterText(_key('signup_first_name'), 'A' * 24);
    await tester.enterText(_key('signup_surname'), 'B' * 34);
    await tester.pump();
    expect(find.text('24/30'), findsNothing);
    expect(find.text('34/40'), findsNothing);
    await tester.enterText(_key('signup_first_name'), 'A' * 25);
    await tester.enterText(_key('signup_surname'), 'B' * 35);
    await tester.pump();
    expect(find.text('25/30'), findsOneWidget);
    expect(find.text('35/40'), findsOneWidget);
    await tester.enterText(_key('signup_first_name'), 'A' * 31);
    await tester.enterText(_key('signup_surname'), 'B' * 41);
    await tester.pump();
    expect(c.firstName, 'A' * 30);
    expect(c.surname, 'B' * 40);
    expect(find.text('30/30'), findsOneWidget);
    expect(find.text('40/40'), findsOneWidget);
    await tester.tap(_key('signup_continue'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('signup_day'), '14');
    await tester.enterText(_key('signup_month'), '03');
    await tester.enterText(_key('signup_year'), '343');
    await tester.pump();
    expect(
      find.text('Enter your year of birth in full, for example 1997.'),
      findsOneWidget,
    );
    final input = tester.widget<TextField>(_key('signup_year'));
    expect(
      (input.decoration!.enabledBorder! as OutlineInputBorder).borderSide.width,
      1.5,
    );
    expect(
      tester.widget<FilledButton>(_key('signup_continue')).onPressed,
      isNull,
    );
    final dayWidth = tester.getSize(_key('signup_day')).width;
    final monthWidth = tester.getSize(_key('signup_month')).width;
    final yearWidth = tester.getSize(_key('signup_year')).width;
    expect(dayWidth, closeTo(monthWidth, .01));
    expect(yearWidth / dayWidth, closeTo(1.4, .01));
    expect(
      tester
          .widget<FilledButton>(_key('signup_continue'))
          .style!
          .side!
          .resolve({}),
      BorderSide.none,
    );
    await tester.enterText(_key('signup_day'), '31');
    await tester.enterText(_key('signup_month'), '02');
    await tester.enterText(_key('signup_year'), '1997');
    await tester.pump();
    expect(find.text('Enter a valid date of birth.'), findsOneWidget);
    for (final part in ['day', 'month', 'year']) {
      final field = tester.widget<TextField>(_key('signup_$part'));
      final border = field.decoration!.enabledBorder! as OutlineInputBorder;
      expect(border.borderSide.width, 1.5);
      expect(border.borderSide.color, ZyraColors.dangerText);
    }
    expect(
      tester.widget<FilledButton>(_key('signup_continue')).onPressed,
      isNull,
    );
  });

  testWidgets(
    'Guardian code display keeps locked groups and gold share action',
    (tester) async {
      final c = ZyraSignupPreviewController();
      addTearDown(c.dispose);
      c.seedSetup(guardian: false, verified: true);
      c.setStep(ZyraSignupStep.addGuardian);
      var shares = 0;
      await _mount(tester, c, onShare: () => shares++);
      expect(
        find.text('ZYRA · 7Q4M · K2XD · 9P3L\nW8RT · F6NB'),
        findsOneWidget,
      );
      final label = tester.widget<Text>(find.text('Share my code'));
      expect(label.style!.color, ZyraColors.goldText);
      await tester.tap(_key('signup_share_code'));
      await tester.pumpAndSettle();
      expect(shares, 1);
    },
  );

  testWidgets('Gender chosen state and search chips match the locked choices', (
    tester,
  ) async {
    final c = ZyraSignupPreviewController();
    addTearDown(c.dispose);
    c.setStep(ZyraSignupStep.gender);
    await _mount(tester, c);
    await tester.tap(_key('signup_gender_male'));
    await tester.pumpAndSettle();
    expect(find.text('✓ CHOSEN'), findsOneWidget);
    await tester.tap(_key('signup_continue'));
    await tester.pumpAndSettle();
    await tester.tap(_key('signup_choice_London'));
    await tester.pumpAndSettle();
    expect(c.location, 'London, United Kingdom');
    await tester.tap(_key('signup_continue'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('signup_search'), 'Canadian');
    await tester.pumpAndSettle();
    await tester.tap(_key('signup_choice_Canadian'));
    await tester.pumpAndSettle();
    expect(c.nationality, 'Canadian');
    c.setStep(ZyraSignupStep.ethnicity);
    await tester.pumpAndSettle();
    await tester.tap(_key('signup_choice_Pakistani'));
    await tester.pumpAndSettle();
    await tester.tap(_key('signup_choice_Indian'));
    await tester.pumpAndSettle();
    expect(c.ethnicities, {'Pakistani', 'Indian'});
    await tester.enterText(_key('signup_search'), 'no-such-answer');
    await tester.pump();
    expect(find.text('No match. Try another spelling.'), findsOneWidget);
  });

  testWidgets('Membership preview shows Apple notice and only Skip advances', (
    tester,
  ) async {
    final c = ZyraSignupPreviewController();
    addTearDown(c.dispose);
    c.seedSetup(guardian: false, verified: true);
    c.setStep(ZyraSignupStep.membership);
    await _mount(tester, c);
    expect(find.text('ONE'), findsWidgets);
    final button = _key('signup_membership_checkout');
    final onePrint = _key('purchase-fine-print-seekerOne');
    expect(onePrint, findsOneWidget);
    expect(
      tester.getTopLeft(onePrint).dy,
      lessThan(tester.getTopLeft(button).dy),
    );
    c.setMembershipBasic(true);
    await tester.pumpAndSettle();
    final basicPrint = _key('purchase-fine-print-seekerBasic');
    expect(onePrint, findsNothing);
    expect(basicPrint, findsOneWidget);
    expect(
      tester.getTopLeft(basicPrint).dy,
      lessThan(tester.getTopLeft(button).dy),
    );
    c.setMembershipBasic(false);
    await tester.pumpAndSettle();
    await tester.tap(_key('signup_membership_checkout'));
    await tester.pumpAndSettle();
    expect(find.text("Apple's subscription sheet opens here."), findsOneWidget);
    expect(c.step, ZyraSignupStep.membership);
    await tester.tap(_key('signup_skip'));
    await tester.pumpAndSettle();
    expect(c.step, ZyraSignupStep.accountReady);
  });

  testWidgets('Verify later reveals the explanation before Continue', (
    tester,
  ) async {
    for (final guardian in [false, true]) {
      final c = ZyraSignupPreviewController();
      c.setGuardian(guardian);
      c.setStep(ZyraSignupStep.verify);
      await _mount(tester, c);
      expect(_key('signup_verify_deferred_message'), findsNothing);
      expect(find.text('Verify now'), findsOneWidget);
      await tester.tap(_key('signup_verify_later'));
      await tester.pumpAndSettle();
      expect(c.step, ZyraSignupStep.verify);
      expect(c.verified, isFalse);
      expect(c.hasAccount, isFalse);
      expect(_key('signup_verify_deferred_message'), findsOneWidget);
      expect(_key('signup_verify_later'), findsNothing);
      expect(find.text('Verify now'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
      expect(
        tester.getTopLeft(_key('signup_verify_deferred_message')).dy,
        greaterThan(
          tester
              .getBottomLeft(
                find.text('We confirm your name and that you’re 18 or over'),
              )
              .dy,
        ),
      );
      await tester.tap(_key('signup_verify_now'));
      await tester.pumpAndSettle();
      expect(c.step, ZyraSignupStep.accountReady);
      expect(c.verified, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    }
  });

  testWidgets(
    'Account ready has an outlined secondary action and aligned status',
    (tester) async {
      final c = ZyraSignupPreviewController();
      addTearDown(c.dispose);
      c.seedSetup(guardian: false, verified: true);
      c.addPhoto(_samplePhoto);
      await _mount(tester, c);
      final lookAround = tester.widget<OutlinedButton>(
        _key('signup_look_around'),
      );
      expect(
        lookAround.style!.backgroundColor!.resolve({}),
        Colors.transparent,
      );
      expect(lookAround.style!.side!.resolve({})!.color.a, greaterThan(.2));
      final statusRight = tester.getBottomRight(find.text('Done').first).dx;
      for (final status in [
        find.text('Done').last,
        find.text('Set any time in Profile'),
        find.text('Optional · add any time'),
      ]) {
        expect(tester.getBottomRight(status).dx, closeTo(statusRight, .01));
      }
      final circles = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (widget) =>
                widget.constraints?.maxWidth == 22 &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
          );
      final emptyCircles = circles.where(
        (widget) =>
            (widget.decoration! as BoxDecoration).color == null &&
            (widget.decoration! as BoxDecoration).border != null,
      );
      expect(emptyCircles.length, 2);
      for (final circle in emptyCircles) {
        expect(
          ((circle.decoration! as BoxDecoration).border! as Border).top.color.a,
          greaterThan(.25),
        );
      }
    },
  );

  testWidgets(
    'About you begins with an empty setup progress bar for both roles',
    (tester) async {
      for (final guardian in [false, true]) {
        final c = ZyraSignupPreviewController();
        c.seedSetup(guardian: guardian, verified: true);
        c.resumeSetup();
        if (!guardian) c.advance();
        await _mount(tester, c);
        expect(c.step, ZyraSignupStep.aboutYou);
        expect(
          tester.widget<LinearProgressIndicator>(_key('signup_progress')).value,
          0,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }
    },
  );

  testWidgets('Every supplied step renders without overflow at phone size', (
    tester,
  ) async {
    final c = ZyraSignupPreviewController();
    addTearDown(c.dispose);
    c.seedSetup(guardian: false, verified: true);
    await _mount(tester, c);
    for (final step in ZyraSignupStep.values) {
      if (step == ZyraSignupStep.splash) {
        continue;
      }
      c.setStep(step);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: step.name);
    }
  });

  testWidgets('Compact enlarged text keeps long steps and actions scrollable', (
    tester,
  ) async {
    for (final (step, guardian, action, next) in [
      (ZyraSignupStep.role, false, 'signup_continue', ZyraSignupStep.name),
      (
        ZyraSignupStep.membership,
        false,
        'signup_membership_checkout',
        ZyraSignupStep.membership,
      ),
      (
        ZyraSignupStep.verify,
        false,
        'signup_verify_now',
        ZyraSignupStep.membership,
      ),
      (
        ZyraSignupStep.name,
        false,
        'signup_continue',
        ZyraSignupStep.dateOfBirth,
      ),
      (ZyraSignupStep.aboutYou, true, 'signup_continue', ZyraSignupStep.allSet),
    ]) {
      final c = ZyraSignupPreviewController();
      c.seedSetup(guardian: guardian, verified: true);
      c.setStep(step);
      if (step == ZyraSignupStep.name) {
        c.setFirstName(List.filled(30, 'a').join());
        c.setSurname(List.filled(40, 'b').join());
      }
      try {
        await _mount(tester, c, size: const Size(320, 568), textScale: 2);
        expect(tester.takeException(), isNull, reason: step.name);
        final target = _key(action);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget, reason: step.name);
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: _key('signup_accessible_scroll'),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scroll.position.pixels, greaterThan(0), reason: step.name);
        expect(tester.widget<FilledButton>(target).onPressed, isNotNull);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(c.step, next);
        expect(tester.takeException(), isNull, reason: step.name);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }
    }
  });

  testWidgets('Pause preserves setup; stale controls cannot edit or enter', (
    tester,
  ) async {
    final c = ZyraSignupPreviewController();
    addTearDown(c.dispose);
    c.seedSetup(guardian: true, verified: false);
    c.resumeSetup();
    var admitted = true;
    var pauses = 0;
    var enters = 0;
    await _mount(
      tester,
      c,
      canAct: () => admitted,
      onPause: () => pauses++,
      onEnter: () => enters++,
    );
    await tester.tap(_key('signup_finish_later'));
    await tester.pumpAndSettle();
    expect(pauses, 1);
    c.setStep(ZyraSignupStep.accountReady);
    c.resumeSetup();
    expect(c.step, ZyraSignupStep.aboutYou);
    await tester.pumpAndSettle();
    final continueAction = tester
        .widget<FilledButton>(_key('signup_continue'))
        .onPressed!;
    admitted = false;
    continueAction();
    await tester.pump();
    expect(c.step, ZyraSignupStep.aboutYou);
    expect(enters, 0);
    admitted = true;
    c.advance();
    await tester.pumpAndSettle();
    await tester.tap(_key('signup_enter'));
    await tester.pumpAndSettle();
    expect(enters, 1);
  });
}
