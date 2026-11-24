import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_email_settings_preview.dart';
import 'package:zyra/dev/zyra_email_template_preview.dart';
import 'package:zyra/dev/zyra_email_templates.dart';
import 'package:zyra/dev/zyra_request_account_session.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final reading = FontLoader('ZYRAEmailPoppins');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await reading.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'ZYRAEmailPoppins';
  });
  tearDownAll(() => ZyraText.useTestFontStubs = false);

  test('em00 inbox order and Q215 copy match all sixteen templates', () {
    expect(zyraPreviewEmailTemplates.map((template) => template.id).toList(), [
      'welcome',
      'verified',
      'verifyagain',
      'request',
      'request_restart',
      'guardreq',
      'begun',
      'invite',
      'subscribed',
      'trialend',
      'renew',
      'support',
      'report',
      'data',
      'closed',
      'deleted',
    ]);
    expect(
      zyraPreviewEmailTemplate('invite')!.footers.single,
      'The invitation is open for 14 days. You choose whether to accept.',
    );
    expect(zyraPreviewEmailTemplate('deleted')!.paragraphs, [
      'As you asked, your ZYRA account, profile and photos have now been deleted for good.',
      "For everyone's safety, a sealed copy of your Journey and Circle conversations is kept for one year and then deleted. Anything linked to an open safety report is kept until the report is closed.",
      'Thank you for being part of ZYRA. You are always welcome back.',
    ]);
  });

  test('recipient switch suppresses only Journey email templates', () {
    const off = ZyraPreviewEmailSettings(journeyEmails: false);
    for (final template in zyraPreviewEmailTemplates) {
      expect(
        zyraPreviewShouldSendEmail(template, off),
        !template.journeyEmail,
        reason: template.id,
      );
      expect(
        zyraPreviewShouldSendEmail(template, const ZyraPreviewEmailSettings()),
        isTrue,
        reason: template.id,
      );
    }
    expect(
      zyraPreviewEmailTemplates
          .where((template) => template.journeyEmail)
          .map((template) => template.id),
      containsAll(['request', 'request_restart', 'guardreq', 'begun']),
    );
  });

  test('preview switches remain with their owning sample session', () {
    var firstCurrent = true;
    final first = ZyraRequestAccountSession(
      canAct: () => firstCurrent,
      palette: ZyraColors.currentDefaultPalette,
      hapticLevel: ZyraHapticLevel.subtle,
      goldEnabled: true,
    );
    final second = ZyraRequestAccountSession(
      canAct: () => true,
      palette: ZyraColors.currentDefaultPalette,
      hapticLevel: ZyraHapticLevel.subtle,
      goldEnabled: true,
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    for (final setting in ZyraEmailSetting.values) {
      expect(first.emailSettings.value(setting), isTrue);
    }
    expect(
      first.setEmailSetting(ZyraEmailSetting.journeyEmails, false),
      isTrue,
    );
    expect(first.emailSettings.journeyEmails, isFalse);
    expect(first.emailSettings.messages, isTrue);
    expect(second.emailSettings.journeyEmails, isTrue);
    firstCurrent = false;
    expect(
      first.setEmailSetting(ZyraEmailSetting.journeyEmails, true),
      isFalse,
    );
    expect(first.emailSettings.journeyEmails, isTrue);
    expect(second.emailSettings.journeyEmails, isTrue);
  });

  test('HTML and plain text share the approved sample words in order', () {
    for (final template in zyraPreviewEmailTemplates) {
      final fields = template.toPreviewSourceRecord().keys;
      expect(fields, isNot(contains('surname')), reason: template.id);
      expect(fields, isNot(contains('town')), reason: template.id);
      expect(fields, isNot(contains('photo')), reason: template.id);
      final html = template.renderHtml();
      final plain = template.renderPlainText();
      expect(
        html,
        contains('<title>${template.subject}</title>'),
        reason: template.id,
      );
      expect(html, isNot(contains('<h1')), reason: template.id);
      expect(
        plain,
        startsWith('ZYRA · ${template.chipLabel}'),
        reason: template.id,
      );
      expect(html, contains(template.chipLabel), reason: template.id);
      expect(plain, contains(template.chipLabel), reason: template.id);
      expect(
        html,
        contains('<span style="display:inline-block;border-radius:999px;'),
        reason: template.id,
      );
      var lastHtml = -1;
      var lastPlain = -1;
      for (final paragraph in template.paragraphs) {
        final htmlParagraph = const HtmlEscape().convert(paragraph);
        final nextHtml = html.indexOf(htmlParagraph, lastHtml + 1);
        final nextPlain = plain.indexOf(paragraph, lastPlain + 1);
        expect(nextHtml, greaterThan(lastHtml), reason: template.id);
        expect(nextPlain, greaterThan(lastPlain), reason: template.id);
        lastHtml = nextHtml;
        lastPlain = nextPlain;
      }
      expect(html, isNot(contains('href=')), reason: template.id);
      if (template.journeyEmail) {
        expect(plain, contains('Turn off Journey emails'), reason: template.id);
      }
    }
  });

  test('action URLs are validated for HTML and plain text', () {
    final template = zyraPreviewEmailTemplate('request')!;
    for (final unsafe in [
      'http://example.com/request',
      'javascript:alert(1)',
      'https://',
      'https://user:pass@example.com/request',
    ]) {
      expect(() => template.renderHtml(actionUrl: unsafe), throwsArgumentError);
      expect(
        () => template.renderPlainText(actionUrl: unsafe),
        throwsArgumentError,
      );
    }
    final html = template.renderHtml(
      actionUrl: 'https://example.com/request?name="A&B"',
    );
    expect(html, contains('href="https://example.com/request?name='));
    expect(html, isNot(contains('name="A&B"')));
    expect(
      template.renderPlainText(actionUrl: 'https://example.com/request'),
      contains('https://example.com/request'),
    );
    expect(
      html.indexOf('>ZYRA</div>'),
      lessThan(html.indexOf('New Journey request')),
    );
  });

  for (final template in zyraPreviewEmailTemplates) {
    testWidgets('renders ${template.id} preview from the shared template', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ZyraEmailTemplatePreview(template: template)),
      );
      expect(find.text(template.subject), findsOneWidget);
      expect(find.text(template.chipLabel), findsOneWidget);
      expect(
        find.text('Assalaamu alaikum ${template.recipientFirstName},'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('em90 shows the fixed rows and toggles only the chosen switch', (
    tester,
  ) async {
    var settings = const ZyraPreviewEmailSettings();
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) => ZyraEmailSettingsPreview(
            settings: settings,
            onChanged: (setting, enabled) {
              update(() => settings = settings.withValue(setting, enabled));
            },
          ),
        ),
      ),
    );
    expect(find.text('Notifications & emails'), findsOneWidget);
    expect(find.text('Membership reminders'), findsOneWidget);
    expect(find.text('Account and safety'), findsOneWidget);
    expect(find.text('Always on'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('email_setting_journeyEmails')));
    await tester.pump();
    expect(settings.journeyEmails, isFalse);
    expect(settings.messages, isTrue);
    expect(settings.guardianActivity, isTrue);
  });

  testWidgets('em90 lays out at the locked 430 by 932 viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(430, 932),
            padding: EdgeInsets.only(top: 59, bottom: 34),
            devicePixelRatio: 3,
          ),
          child: RepaintBoundary(
            key: boundaryKey,
            child: ZyraEmailSettingsPreview(
              settings: const ZyraPreviewEmailSettings(),
              onChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notifications & emails'), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('ZYRA_LINE133_CAPTURE')) {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/line133_preview/em90.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      });
    }
  });

  testWidgets('em90 keeps every row readable at 375 with Larger Text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.only(top: 20),
            devicePixelRatio: 3,
            textScaler: TextScaler.linear(1.5),
          ),
          child: ZyraEmailSettingsPreview(
            settings: const ZyraPreviewEmailSettings(),
            onChanged: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('zyra_email_settings_scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Account and safety'),
      180,
      scrollable: scroll,
    );
    expect(find.text('Always on'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
