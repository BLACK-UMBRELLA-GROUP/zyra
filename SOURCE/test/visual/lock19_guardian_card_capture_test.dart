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
import 'baseline_capture_support.dart';

const _base = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _out = '$_base/PRODUCT/APPROVED/GUARDIAN_CARD/BUILT/V2';
const _evidence = '$_base/REPORTS/EVIDENCE/LOCK19_GUARDIAN_CARD_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_LOCK19_CAPTURE');
const _hassan = 'draft-guardian-hassan', _ibrahim = 'draft-guardian-yusuf';
Finder _key(String key) => find.byKey(ValueKey(key));
BaselineHarness _h(WidgetTester t, {double scale = 1}) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(
    t,
    group: 'lock19_$scale',
    flatOutput: true,
    outputRoot: _out,
    evidenceRoot: _evidence,
    textScale: scale,
  );
}

Future<void> _cap(BaselineHarness h, String name) async {
  if (!_capture) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(h.tester.renderObject(_key('zyra-founder-baseline-boundary')));
    await h.tester.pump();
    await h.capture(
      'guardian_cards',
      name,
      name,
      'Actual LOCK19 card/sheet widgets; explicit read-only master data in production frame, no transport.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

Future<void> _narrowCap(BaselineHarness h, String name) async {
  if (!_capture) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      _key('zyra-founder-baseline-boundary'),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await h.tester.pump();
    await h.tester.runAsync(() async {
      final im = await boundary.toImage(pixelRatio: 3);
      try {
        expect(im.width, 960);
        final data = await im.toByteData(format: ui.ImageByteFormat.png);
        await File('$_out/$name.png').writeAsBytes(data!.buffer.asUint8List());
      } finally {
        im.dispose();
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
                      membership: 'Guardian One',
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
                compactWhenIdle: true,
                compactV2: true,
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
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  testWidgets(
    'LOCK19 k01-k04 Main front, two/three/no Journey access',
    (t) async {
      final h = _h(t);
      await _fixture(h);
      await _cap(h, 'k01_card_front__hassan_main');
      await h.tap('guardian-card-center');
      await _cap(h, 'k02_access__hassan_2_journeys');
      await _fixture(h, count: 3);
      await h.tap('guardian-card-center');
      await _cap(h, 'k03_access__hassan_3_journeys');
      await _fixture(h, count: 0);
      await h.tap('guardian-card-center');
      await _cap(h, 'k04_access__hassan_no_journeys');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 k05-k08 Additional Basic, invited sample and add last',
    (t) async {
      final h = _h(t);
      await _fixture(h, additional: true, guardianBasic: true);
      await _cap(h, 'k05_card_front__ibrahim_basic');
      await h.tap('guardian-card-center');
      await _cap(h, 'k06_access__ibrahim_chat_locked');
      await h.tap('guardian-card-next');
      await _cap(h, 'k07_card__omar_invited');
      await h.tap('guardian-card-next');
      await _cap(h, 'k08_card__add_a_guardian');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 k09-k16 three Family states, formula, invite and accepted projection',
    (t) async {
      final h = _h(t);
      await _fixture(h, additional: true, guardianBasic: true);
      await h.tap('guardian-card-center');
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'k09_sheet__basic_no_family');
      await h.tap('guardian-family-introduction-primary');
      expect(find.text('£49.98 a month'), findsOneWidget);
      await _cap(h, 'k10_sheet__price_no_family');
      await h.tap('guardian-family-price-primary');
      await _cap(h, 'k14_sheet__invite_sent');
      await h.tap('guardian-family-invited-primary');
      await _cap(h, 'k15_access__ibrahim_invited');
      await _fixture(
        h,
        additional: true,
        guardianBasic: true,
        family: ZyraGuardianFamilyState.freePlace,
      );
      await h.tap('guardian-card-center');
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'k11_sheet__basic_free_place');
      await h.tap('guardian-family-introduction-secondary');
      await _fixture(
        h,
        additional: true,
        guardianBasic: true,
        family: ZyraGuardianFamilyState.full,
      );
      await h.tap('guardian-card-center');
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'k12_sheet__basic_family_full');
      await h.tap('guardian-family-introduction-primary');
      expect(find.text('£66.47 a month'), findsOneWidget);
      await _cap(h, 'k13_sheet__price_family_full');
      await h.tap('guardian-family-price-secondary');
      await h.tap('guardian-family-introduction-secondary');
      await _fixture(h, additional: true, accepted: true);
      await h.tap('guardian-card-center');
      await _cap(h, 'k16_access__ibrahim_accepted_chat_off');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 k17-k19 Seeker Basic one Guardian and locked add',
    (t) async {
      final h = _h(t);
      await _fixture(h, count: 1, basic: true);
      await _cap(h, 'k17_basic__card_front_hassan');
      await h.tap('guardian-card-center');
      await _cap(h, 'k18_basic__access_1_journey');
      await h.tap('guardian-card-next');
      await _cap(h, 'k19_basic__add_more_locked');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'LOCK19 Larger Text tiles and all sheet controls remain reachable',
    (t) async {
      final h = _h(t, scale: 2);
      await _fixture(h, additional: true, guardianBasic: true, count: 3);
      await h.tap('guardian-card-center');
      await _cap(h, 'large_200_access_top');
      await t.ensureVisible(_key('guardian-remove'));
      await h.flush();
      await _cap(h, 'large_200_access_actions');
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
      _oneLine(t, find.text('Ibrahim'));
      await h.tap('guardian-card-center');
      _oneLine(
        t,
        find.descendant(
          of: _key('guardian-card-view-$_ibrahim-draft-sara'),
          matching: find.text('View'),
        ),
      );
      await _narrowCap(h, 'narrow_320_200_access_top');
      await t.ensureVisible(_key('guardian-remove'));
      await h.flush();
      _oneLine(
        t,
        find.descendant(
          of: _key('guardian-remove'),
          matching: find.text('Remove'),
        ),
      );
      await _narrowCap(h, 'narrow_320_200_access_actions');
      await t.ensureVisible(_key('guardian-card-chat-$_ibrahim-draft-sara'));
      await h.flush();
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _narrowCap(h, 'narrow_320_200_sheet_top');
      await t.ensureVisible(_key('guardian-family-introduction-primary'));
      await h.flush();
      await _narrowCap(h, 'narrow_320_200_sheet_actions');
      await h.tap('guardian-family-introduction-primary');
      await t.ensureVisible(_key('guardian-family-price-primary'));
      await h.flush();
      await _narrowCap(h, 'narrow_320_200_price_actions');
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
      await _cap(h, 'shell_actual_samples_front');
      await h.tap('guardian-card-next');
      await h.tap('guardian-card-center');
      await h.tap('guardian-card-chat-$_ibrahim-draft-sara');
      await _cap(h, 'shell_actual_samples_basic_sheet');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
