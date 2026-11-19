import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_card_content.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_settings_details.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_text.dart';

const _names = [
  ('Sara', 'Ahmed'),
  ('Fatima-Zahra', 'Abdul-Rahman Al-Hashimi'),
  ('Zainab', 'Malik-Abdulkareem Bin Yusuf'),
];
const _data = ZyraConceptAccountData(
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
  signedInWith: 'Apple',
  backgroundLabel: 'Midnight Plum',
  hapticLabel: 'Subtle',
  gold: false,
);

void main() {
  setUpAll(() async {
    final font = FontLoader('PoppinsLock33Other');
    for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsLock33Other';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final size in [const Size(375, 667), const Size(430, 932)]) {
    for (final scale in [1.0, 2.0]) {
      for (final surface in ['journey', 'guardian_request', 'hidden_profile']) {
        testWidgets(
          '$surface names keep one line and equal height at $size / $scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            var semanticsDisposed = false;
            void disposeSemantics() {
              if (!semanticsDisposed) semantics.dispose();
              semanticsDisposed = true;
            }

            addTearDown(disposeSemantics);
            double? height;
            for (final (first, surname) in _names) {
              final fullName = '$first $surname';
              final content = switch (surface) {
                'journey' => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    key: const ValueKey('lock33_measured_card'),
                    padding: const EdgeInsets.all(12),
                    child: ZyraOneJourneyCardContent(
                      design: ZyraOneJourneyCardDesign.portraitSplit,
                      profile: SeekerProfile(
                        id: 'long-name',
                        firstName: first,
                        surnameLine: surname,
                        age: 27,
                        city: 'London',
                        gender: 'female',
                        photos: const [],
                      ),
                      photo: const ColoredBox(color: Colors.grey),
                      action: const SizedBox(height: 44),
                      primaryButton: const SizedBox(height: 44),
                      fillHeight: false,
                    ),
                  ),
                ),
                'guardian_request' => ZyraGuardianTabsPresentation(
                  state: ZyraGuardianTabsState(),
                  page: 'requests',
                  onAction: (_) {},
                  photoFor: (_) => null,
                  seekerGender: 'male',
                  receivedJourneyRequests: [
                    DraftProfile(
                      id: 'long-name',
                      firstName: first,
                      surname: surname,
                      age: 27,
                      city: 'London',
                    ),
                  ],
                ),
                _ => ZyraConceptSettingsOverview(
                  action: ZyraConceptAccountAction.hiddenProfiles,
                  data: _data,
                  onOpenDetail: (_) {},
                  onHelp: () {},
                  onUnhide: (_) {},
                  hiddenProfiles: [
                    ZyraConceptHiddenProfile(
                      id: 'long-name',
                      name: fullName,
                      detail: '27 · London',
                    ),
                  ],
                ),
              };
              await tester.pumpWidget(
                MaterialApp(
                  theme: ThemeData.dark(),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: surface == 'journey'
                        ? SingleChildScrollView(child: content)
                        : content,
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final name = find.text(fullName);
              expect(name, findsOneWidget);
              final text = tester.widget<Text>(name);
              expect(text.maxLines, 1);
              expect(text.overflow, TextOverflow.ellipsis);
              expect(text.semanticsLabel, fullName);
              expect(
                find.bySemanticsLabel(RegExp(RegExp.escape(fullName))),
                findsWidgets,
              );
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(of: name, matching: find.byType(RichText)),
              );
              expect(paragraph.maxLines, 1);
              expect(
                text.style!.fontSize,
                surface == 'journey'
                    ? 19
                    : surface == 'guardian_request'
                    ? 18
                    : 16,
              );
              final measured = surface == 'journey'
                  ? find.byKey(const ValueKey('lock33_measured_card'))
                  : find.ancestor(of: name, matching: find.byType(Row)).first;
              final currentHeight = tester.getSize(measured).height;
              height ??= currentHeight;
              expect(currentHeight, height, reason: fullName);
              expect(tester.takeException(), isNull);
            }
            disposeSemantics();
          },
        );
      }
    }
  }
}
