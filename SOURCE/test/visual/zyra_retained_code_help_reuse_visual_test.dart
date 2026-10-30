// Retained Help checks. Code presentation coverage moved to LOCK9's nine real
// caller captures and local_code_page_lock9_test; old code UI was replaced.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('PoppinsLock9Help');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
    ]) {
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await font.load();
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsLock9Help';
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });
  final signIn = zyraHelpCategories
      .expand((c) => c.entries)
      .singleWhere((e) => e.question == 'How do I sign in?');
  final categories = [
    ZyraHelpCategory('Getting started', [signIn]),
  ];
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'retained original Help search and answer fit text scale$scale',
      (t) async {
        t.view.physicalSize = const Size(320, 568);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: HelpSupportScreen.preview(
                canAct: () => true,
                categories: categories,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final field = find.descendant(
          of: find.byKey(const ValueKey('help-support-preview-search')),
          matching: find.byType(TextField),
        );
        await t.enterText(field, 'sign in');
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        await Scrollable.ensureVisible(
          t.element(find.text(signIn.question)),
          alignment: .5,
        );
        await t.pumpAndSettle();
        await t.tap(find.text(signIn.question));
        await t.pumpAndSettle();
        expect(find.text(signIn.answer), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
