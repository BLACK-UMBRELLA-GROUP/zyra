import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
// LOCK19: real presenters in the production frame. Explicit master data fixtures.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_family_sheet.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import '../support/guardian_card_driver.dart';
import 'baseline_capture_support.dart';

const _reviewDirectory = String.fromEnvironment('ZYRA_LOCK19_REVIEW_DIR');
const _hassan = 'draft-guardian-hassan', _ibrahim = 'draft-guardian-yusuf';
Finder _key(String key) => find.byKey(ValueKey(key));

BaselineHarness _h(WidgetTester t, {double scale = 1}) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(t, group: 'lock19_v6_$scale', textScale: scale);
}

Future<void> _cap(BaselineHarness h, String name) async {
  if (_reviewDirectory.isEmpty) return;
  final tester = h.tester;
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    await tester.runAsync(() => precacheImage(image.image, element));
  }
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      _key('zyra-founder-baseline-boundary'),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$_reviewDirectory/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
    });
  } finally {
    debugDisableShadows = previous;
  }
}

Future<void> _fixture(
  BaselineHarness h, {
  int count = 2,
  bool basic = false,
  bool additional = false,
  bool guardianBasic = false,
  bool mainBasic = false,
  ZyraGuardianFamilyState family = ZyraGuardianFamilyState.noFamily,
  bool accepted = false,
}) async {
  final photos = await h.tester.runAsync(
    () => ZyraOneJourneySamplePhotos.load(),
  );
  var revision = 0;
  var history = false;
  final model = ViewRequestDraftModel(capacity: basic ? 1 : 3);
  if (count > 0) model.seedJourneys(count);
  await h.mountPresentation(
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: model.snapshot(),
      tab: 3,
      pages: [],
    ),
    child: StatefulBuilder(
      key: UniqueKey(),
      builder: (context, setState) => Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: Stack(
            children: [
              Positioned.fill(
                child: ZyraOneJourneyGuardianCards(
                  contextIdentity: 'master-fixture',
                  onCancelPreviewInvitation: () {},
                  renderIdentity: revision,
                  canAct: () => true,
                  interactionEpoch: () => revision,
                  people: [
                    ZyraGuardianCardPerson(
                      person: WaliLinkedPerson(
                        id: _hassan,
                        firstName: 'Hassan',
                        relationship: 'father',
                        linkedAt: DateTime(2026, 9, 20),
                        isMain: true,
                      ),
                      membership: mainBasic ? 'Guardian Basic' : 'Guardian One',
                      history: history,
                    ),
                    if (!basic)
                      ZyraGuardianCardPerson(
                        person: WaliLinkedPerson(
                          id: _ibrahim,
                          firstName: 'Ibrahim',
                          relationship: 'uncle',
                          linkedAt: DateTime(2026, 10, 2),
                          isMain: false,
                        ),
                        membership: guardianBasic && !accepted
                            ? 'Guardian Basic'
                            : 'Guardian One',
                        history: false,
                        familyPlace: accepted,
                      ),
                  ],
                  journeysFor: (id) => [
                    for (var i = 0; i < count; i++)
                      ZyraGuardianCardJourney(
                        id: ['draft-sara', 'draft-aisha', 'draft-maryam'][i],
                        attempt: i + 1,
                        name: ['Sara', 'Aisha', 'Maryam'][i],
                        stageNumber: [4, 1, 2][i],
                        stage: [
                          'Stage 4 of 8 · Faith & Values',
                          'Stage 1 of 8 · Salam Exchange',
                          'Stage 2 of 8 · Compatibility Reveal',
                        ][i],
                        photo: photos!.forIndex(i + 1).first,
                        view: true,
                        chat: id == _hassan,
                        canChange: id != _hassan,
                      ),
                  ],
                  basic: basic,
                  capacity: basic ? 1 : 3,
                  initialPage: additional ? 1 : 0,
                  unread: 2,
                  familyState: family,
                  onPage: (_) {},
                  onHistory: (id, value) => setState(() {
                    history = value;
                    revision++;
                  }),
                  onPermission: (id, journey, {view, chat}) {},
                  makeMain: (_) async => false,
                  clearMain: (_) async => false,
                  remove: (_) async => null,
                  onAdd: () {},
                  onUpgrade: () {},
                  onCircle: () {},
                ),
              ),
              const ZyraShellNavigation(
                items: [
                  FloatingNavItem(icon: Icons.search, label: 'Profiles'),
                  FloatingNavItem(
                    icon: Icons.people_outline,
                    label: 'Journeys',
                    useJourneyGlyph: true,
                  ),
                  FloatingNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'My ZYRA',
                  ),
                  FloatingNavItem(
                    icon: Icons.gpp_good_outlined,
                    label: 'Guardian',
                  ),
                  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
                ],
                currentIndex: 3,
                onTap: _noop,
                lockedTabBar: true,
                contentEdgeInset: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _oneLine(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(
    paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.data!.length),
    ),
    hasLength(1),
    reason: 'Whole control word stays on one rendered line at200%',
  );
}

void _noop(int _) {}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);
  testWidgets(
    'LOCK19 V6 Main card with two, three and zero active Journeys',
    (t) async {
      final h = _h(t);
      await _fixture(h);
      for (final count in [2, 3, 0]) {
        if (count != 2) await _fixture(h, count: count);
        expect(find.text('Hassan'), findsOneWidget);
        expect(find.text('JOURNEY ACCESS'), findsOneWidget);
        expect(find.text('Past Journey summaries'), findsOneWidget);
        expect(find.text('View'), findsNWidgets(count));
        expect(find.text('Free Journey place'), findsNWidgets(3 - count));
        await _cap(h, 'main_card_${count}_active_journeys');
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 V6 Additional Basic, invited sample and Add last',
    (t) async {
      final h = _h(t);
      await _fixture(h, additional: true, guardianBasic: true);
      expect(find.text('Guardian Basic'), findsOneWidget);
      expect(_key('guardian-card-chat-$_ibrahim-draft-sara'), findsOneWidget);
      await _cap(h, 'additional_basic_card');
      await h.tap('guardian-card-menu');
      expect(find.text('Make Main Guardian'), findsOneWidget);
      expect(find.text('Remove Ibrahim'), findsOneWidget);
      await _cap(h, 'additional_guardian_menu');
      await h.tap('guardian-card-menu-cancel');
      final chip = _key('guardian-card-view-$_ibrahim-draft-sara');
      final origin = t.getCenter(chip);
      final swipe = await t.startGesture(origin);
      await swipe.moveBy(const Offset(-90, 0));
      await t.pump();
      expect(t.getCenter(chip).dx, closeTo(origin.dx - 90, 1));
      await _cap(h, 'additional_guardian_card_mid_drag');
      await swipe.up();
      await t.pumpAndSettle();
      expect(find.text('Waiting for Omar to accept'), findsOneWidget);
      expect(find.text('Cancel invitation'), findsOneWidget);
      expect(_key('guardian-card-menu'), findsNothing);
      await _cap(h, 'invited_guardian_card');
      await swipeGuardianCard(t);
      await h.flush();
      expect(_key('guardian-card-add'), findsOneWidget);
      await _cap(h, 'add_guardian_card');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 k09-k16 three Family states, formula, invite and accepted projection',
    (t) async {
      final h = _h(t);
      await _fixture(h, additional: true, guardianBasic: true);
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'k09_sheet__basic_no_family');
      await h.tap('guardian-family-introduction-primary');
      expect(find.text('£49.98 a month'), findsOneWidget);
      await _cap(h, 'k10_sheet__price_no_family');
      await h.tap('guardian-family-price-primary');
      await _cap(h, 'k14_sheet__invite_sent');
      await h.tap('guardian-family-invited-primary');
      expect(find.text('Invited'), findsNWidgets(2));
      await _cap(h, 'additional_guardian_family_invited');
      await _fixture(
        h,
        additional: true,
        guardianBasic: true,
        family: ZyraGuardianFamilyState.freePlace,
      );
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'k11_sheet__basic_free_place');
      await h.tap('guardian-family-introduction-secondary');
      await _fixture(
        h,
        additional: true,
        guardianBasic: true,
        family: ZyraGuardianFamilyState.full,
      );
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'k12_sheet__basic_family_full');
      await h.tap('guardian-family-introduction-primary');
      expect(find.text('£66.47 a month'), findsOneWidget);
      await _cap(h, 'k13_sheet__price_family_full');
      await h.tap('guardian-family-price-secondary');
      await h.tap('guardian-family-introduction-secondary');
      await _fixture(h, additional: true, accepted: true);
      expect(find.text('Guardian One · Family place'), findsOneWidget);
      await _cap(h, 'additional_guardian_family_accepted');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 V7 Seeker Basic Guardian and Add card',
    (t) async {
      final h = _h(t);
      await _fixture(h, count: 1, basic: true);
      expect(find.text('MAIN GUARDIAN'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      await _cap(h, 'seeker_basic_guardian_card');
      await swipeGuardianCard(t);
      await h.flush();
      expect(find.text('Guardian Basic place'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      await _cap(h, 'seeker_basic_add_free');
      await _fixture(h, count: 1, basic: true, mainBasic: true);
      await swipeGuardianCard(t);
      await h.flush();
      expect(find.text('Used'), findsOneWidget);
      await _cap(h, 'seeker_basic_add_used');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 Larger Text tiles and all sheet controls remain reachable',
    (t) async {
      final h = _h(t, scale: 2);
      await _fixture(h, additional: true, guardianBasic: true, count: 3);
      await _cap(h, 'large_200_card_top');
      await h.tap('guardian-card-menu');
      expect(_key('guardian-remove').hitTestable(), findsOneWidget);
      await _cap(h, 'large_200_management_menu');
      await h.tap('guardian-card-menu-cancel');
      await t.ensureVisible(_key('guardian-card-chat-$_ibrahim-draft-sara'));
      await h.flush();
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'large_200_family_top');
      await t.ensureVisible(_key('guardian-family-introduction-primary'));
      await h.flush();
      await _cap(h, 'large_200_family_actions');
      await h.tap('guardian-family-introduction-primary');
      await t.ensureVisible(_key('guardian-family-price-primary'));
      await h.flush();
      await _cap(h, 'large_200_price_actions');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 narrow320 and200percent tiles/sheet/actions reachable',
    (t) async {
      final h = _h(t, scale: 2);
      await _fixture(h, additional: true, guardianBasic: true, count: 3);
      t.view.physicalSize = const Size(960, 1920);
      await h.flush();
      _oneLine(t, _key('guardian-manager-title'));
      final name = find.text('Ibrahim');
      final paragraph = t.renderObject<RenderParagraph>(name);
      expect(
        paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 6, extentOffset: 7),
        ),
        isNotEmpty,
        reason: 'The final letter remains visible if the compact name wraps.',
      );
      _oneLine(
        t,
        find.descendant(
          of: _key('guardian-card-view-$_ibrahim-draft-sara'),
          matching: find.text('View'),
        ),
      );
      await _cap(h, 'narrow_320_200_card_top');
      await h.tap('guardian-card-menu');
      expect(_key('guardian-remove').hitTestable(), findsOneWidget);
      await _cap(h, 'narrow_320_200_management_menu');
      await h.tap('guardian-card-menu-cancel');
      await t.ensureVisible(_key('guardian-card-chat-$_ibrahim-draft-sara'));
      await h.flush();
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'narrow_320_200_sheet_top');
      await t.ensureVisible(_key('guardian-family-introduction-primary'));
      await h.flush();
      await _cap(h, 'narrow_320_200_sheet_actions');
      await h.tap('guardian-family-introduction-primary');
      await t.ensureVisible(_key('guardian-family-price-primary'));
      await h.flush();
      await _cap(h, 'narrow_320_200_price_actions');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 actual shell samples are captured separately from named master data',
    (t) async {
      final h = _h(t);
      final model = ViewRequestDraftModel(capacity: 3)
        ..seedJourneys(2)
        ..setSampleGuardianMembership(_ibrahim, DraftGuardianMembership.basic);
      await h.mount(tab: 3, model: model);
      await _cap(h, 'shell_actual_samples_card');
      await swipeGuardianCard(t);
      await h.flush();
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'shell_actual_samples_basic_sheet');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
