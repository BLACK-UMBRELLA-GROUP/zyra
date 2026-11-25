import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/widgets/zyra_help_support_page.dart';

import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _capture = bool.fromEnvironment('ZYRA_LINE137_CAPTURE');
const _root = 'build/line137';
Finder _key(String id) => find.byKey(ValueKey(id));
Finder get _search => find.descendant(
  of: _key('help-support-preview-search'),
  matching: find.byType(TextField),
);

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(
    WidgetTester t,
    String name, {
    double width = 430,
    double scale = 1,
  }) {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    return BaselineHarness(
      t,
      group: 'line137_$name',
      logicalSize: Size(width, width == 430 ? 932 : 667),
      textScale: scale,
      outputRoot: '$_root/screens',
      evidenceRoot: '$_root/screens',
      flatOutput: true,
      safePadding: width == 430
          ? const EdgeInsets.only(top: 59, bottom: 34)
          : const EdgeInsets.only(top: 20),
    );
  }

  Future<void> search(BaselineHarness h, String query) async {
    final scroll = h.tester.state<ScrollableState>(
      find
          .descendant(
            of: _key('help-support-preview-scroll'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scroll.position.jumpTo(0);
    await h.flush();
    await h.tester.enterText(_search, query);
    await h.tester.testTextInput.receiveAction(TextInputAction.done);
    await h.flush();
  }

  Future<void> check(BaselineHarness h, String name) async {
    final before = debugDisableShadows;
    try {
      debugDisableShadows = false;
      await h.tester.pump(const Duration(milliseconds: 2600));
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(
        _key('zyra-founder-baseline-boundary'),
      );
      final audit = await auditZyraRenderedText(h.tester, boundary);
      await h.tester.runAsync(() async {
        final file = File('$_root/audit/$name.json');
        await file.parent.create(recursive: true);
        final report = audit.toJson();
        final title = h.tester.getRect(_key('help-support-preview-title'));
        report['title_rect'] = [
          title.left,
          title.top,
          title.right,
          title.bottom,
        ];
        final footer = _key('help-contact-card');
        if (footer.evaluate().isNotEmpty) {
          final rect = h.tester.getRect(footer);
          report['contact_rect'] = [
            rect.left,
            rect.top,
            rect.right,
            rect.bottom,
          ];
        }
        await file.writeAsString(jsonEncode(report));
      });
      expect(audit.failures, isEmpty, reason: '$name ${audit.toJson()}');
      void repaint(RenderObject node) {
        node.visitChildren(repaint);
        node.markNeedsPaint();
      }

      repaint(boundary);
      await h.tester.pump();
      await h.capture('help', name, 'normal', name, fileName: '$name.png');
    } finally {
      debugDisableShadows = before;
    }
  }

  test('LOCK43 six topics, no retired questions, unique canonical questions', () {
    expect(zyraHelpCategories.map((c) => c.title), [
      'Getting started',
      'Profiles and Journeys',
      'Guardians',
      'Membership',
      'Safety',
      'Your account',
    ]);
    final entries = zyraHelpCategories.expand((c) => c.entries).toList();
    expect(entries.map((e) => e.question).toSet().length, entries.length);
    final all = entries.map((e) => '${e.question} ${e.answer}').join('\n');
    for (final old in [
      'Consider, Save and Pass',
      'Potential Journey',
      'Paused Journey',
      'Saved profiles',
      'Will someone know if I passed on them?',
    ]) {
      expect(all, isNot(contains(old)));
    }
    expect(
      entries
          .singleWhere((e) => e.question == zyraPastJourneySummariesQuestion)
          .answer,
      endsWith(
        'Turn it on or off any time on that Guardian’s card in the Guardian tab.',
      ),
    );
  });

  for (final guardian in [false, true]) {
    testWidgets(
      'LOCK43 actual entry points, search, accordion, contact and stale action $guardian',
      (t) async {
        final h = harness(t, 'actions_$guardian');
        await h.mount(guardian: guardian, tab: 4);
        await h.tap('concept_settings');
        await h.tap('concept_settings_helpSupport');
        h.assertPage('help_support');
        expect(find.text('Help & support'), findsOneWidget);
        expect(find.byType(BackButton), findsNothing);
        expect(_key('floating-nav-item-0'), findsNothing);
        await h.tap('help-support-faq:Getting started:How does ZYRA work?');
        expect(find.textContaining('You build a profile,'), findsOneWidget);
        await h.tap('help-support-faq:Getting started:How do I sign in?');
        expect(find.textContaining('You build a profile,'), findsNothing);
        expect(
          find.textContaining('With Sign in with Apple or Google,'),
          findsOneWidget,
        );
        await search(h, 'password of its own');
        expect(find.text('How do I sign in?'), findsOneWidget);
        expect(find.text('How does ZYRA work?'), findsNothing);
        await h.tap('help-topic:Getting started');
        await search(h, '30 days');
        expect(find.textContaining('No answers for “30 days”'), findsOneWidget);
        await h.tap('help-topic:All');
        expect(find.text('How do I delete my account?'), findsOneWidget);
        await search(h, 'xyz');
        expect(
          find.text(
            'No answers for “xyz”. Try other words, or contact us below.',
          ),
          findsOneWidget,
        );
        final stale = t
            .widget<ZyraHelpSupportPage>(find.byType(ZyraHelpSupportPage))
            .onContact;
        await h.tap('help-contact-us');
        h.assertPage('help_contact');
        stale();
        await h.flush();
        expect(h.latest.pages, ['settings', 'help_support', 'help_contact']);
        await t.binding.handlePopRoute();
        await h.flush();
        h.assertPage('help_support');
        await t.binding.handlePopRoute();
        await h.flush();
        h.assertPage('settings');
        await t.binding.handlePopRoute();
        await h.flush();
        await h.tap('concept_safety_advice');
        await h.tap('draft_safety_advice_help');
        h.assertPage('help_support');
      },
    );
  }

  for (final width in [430.0, 375.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LOCK43 focused replay $width $scale', (t) async {
        final id = '${width.toInt()}_${scale.toInt()}';
        final h = harness(t, id, width: width, scale: scale);
        await h.mount(tab: 4, pages: const ['help_support']);
        await check(h, '${id}_hp01_all');
        final endQuestion = _key(
          'help-support-faq:Profiles and Journeys:What happens when a Journey ends?',
        );
        await t.scrollUntilVisible(
          endQuestion,
          250,
          scrollable: find
              .descendant(
                of: _key('help-support-preview-scroll'),
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 50,
        );
        await h.tapFinder(endQuestion);
        await check(h, '${id}_hp02_answer');
        await search(h, 'guardian');
        await check(h, '${id}_hp03_search');
        await search(h, 'xyz');
        await check(h, '${id}_hp04_no_results');
        if (scale > 1) {
          await Scrollable.ensureVisible(
            t.element(_key('help-contact-card')),
            alignment: 1,
          );
          await h.flush();
          await check(h, '${id}_no_results_contact');
          final card = t.getRect(_key('help-contact-card'));
          expect(card.bottom, lessThanOrEqualTo(width == 430 ? 898 : 667));
          expect(
            card.top,
            greaterThanOrEqualTo(
              t.getRect(_key('help-support-preview-title')).bottom,
            ),
          );
        }
        await search(h, '');
        await t.drag(
          _key('help-support-preview-scroll'),
          const Offset(0, -12000),
        );
        await h.flush();
        await Scrollable.ensureVisible(
          t.element(_key('help-contact-card')),
          alignment: 1,
        );
        await h.flush();
        await check(h, '${id}_hp05_contact');
        final card = t.getRect(_key('help-contact-card'));
        expect(card.bottom, lessThanOrEqualTo(width == 430 ? 898 : 667));
        expect(
          card.top,
          greaterThanOrEqualTo(
            t.getRect(_key('help-support-preview-title')).bottom,
          ),
        );
        expect(_key('help-contact-us').hitTestable(), findsOneWidget);
      }, skip: !_capture);
    }
  }
}
