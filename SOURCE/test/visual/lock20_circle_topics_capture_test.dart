// LOCK20: actual retained Circle controller and Topics widgets in the app frame.
// Master-named sample people/dates below are explicit offline display fixtures.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_circle_discussion_archive.dart';
import 'package:zyra/dev/zyra_circle_topics_presentation.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'baseline_capture_support.dart';

const base = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const output = '$base/PRODUCT/APPROVED/GUARDIAN_CIRCLE/BUILT/V2';
const evidence = '$base/REPORTS/EVIDENCE/LOCK20_TOPICS_2026-11-01';
const capture = bool.fromEnvironment('ZYRA_LOCK20_CAPTURE');
const names = [
  'gc01_seeker__everyone',
  'gc02_seeker__menu_members',
  'gc03_seeker__topic_sara',
  'gc04_seeker__past_list',
  'gc05_seeker__past_open_zainab',
  'gc06_seeker__past_closed_hana',
  'gc07_seeker__topic_empty_maryam',
  'gc08_seeker_basic__menu',
  'gc09_guardian__everyone_sharing_off',
  'gc10_guardian__past_list_sharing_on',
  'gc11_guardian__past_closed_hana',
  'gc12_guardian__menu',
  'gc13_guardian_basic__reads_only',
  'gc14_seeker__all_new_family',
];
Finder key(String id) => find.byKey(ValueKey('circle_topics_$id'));
final now = DateTime.utc(2026, 10, 31);
const sara = ZyraFamilyMessageContext(
  referenceId: 'draft-sara',
  firstName: 'Sara',
  kind: ZyraFamilyMessageContextKind.active,
);
const aisha = ZyraFamilyMessageContext(
  referenceId: 'draft-aisha',
  firstName: 'Aisha',
  kind: ZyraFamilyMessageContextKind.active,
);
const maryam = ZyraFamilyMessageContext(
  referenceId: 'draft-maryam',
  firstName: 'Maryam',
  kind: ZyraFamilyMessageContextKind.active,
);

Future<void> fixture(BaselineHarness h, int scene) async {
  final guardian = scene >= 9 && scene <= 13,
      basicGuardian = scene == 13,
      basicSeeker = scene == 8,
      empty = scene == 14;
  final sender = basicGuardian
      ? 'ibrahim'
      : guardian
      ? 'hassan'
      : 'adam';
  final photos = await h.tester.runAsync(
    () => ZyraOneJourneySamplePhotos.load(),
  );
  final contexts = empty
      ? <ZyraFamilyMessageContext>[]
      : [sara, if (!basicSeeker) aisha, if (scene == 7) maryam];
  final past = empty || scene == 9 || scene == 12 || scene == 13
      ? <ZyraCircleDiscussionTopic>[]
      : [
          ZyraCircleDiscussionTopic(
            id: 'draft-circle-past-zainab',
            firstName: 'Zainab',
            kind: ZyraCircleTopicKind.past,
            endedOn: DateTime.utc(2026, 10, 24),
            sharedSummaryLabel: guardian ? 'Adam & Zainab' : null,
          ),
          ZyraCircleDiscussionTopic(
            id: 'draft-circle-past-hana',
            firstName: 'Hana',
            kind: ZyraCircleTopicKind.past,
            endedOn: DateTime.utc(2026, 9, 10),
            sharedSummaryLabel: guardian ? 'Adam & Hana' : null,
          ),
        ];
  final readers = [
    for (final id in ['adam', 'hassan', if (!basicSeeker) 'ibrahim'])
      ZyraFamilyMessageReader(
        userId: id,
        firstName: id == 'adam'
            ? 'Adam'
            : id == 'hassan'
            ? 'Hassan'
            : 'Ibrahim',
        roleLabel: id == 'adam' ? 'Seeker' : 'Guardian',
        readAt: DateTime.utc(2026, 10, 31, 1, 11),
      ),
  ];
  ZyraFamilyMessage message(
    String id,
    String owner,
    String body,
    DateTime at, {
    bool unread = false,
  }) => ZyraFamilyMessage(
    id: id,
    senderId: owner,
    senderFirstName: owner == 'adam' ? 'Adam' : 'Hassan',
    senderRelationship: owner == 'hassan' ? 'father' : null,
    senderRoleLabel: owner == 'adam' ? 'Seeker' : 'Main Guardian',
    body: body,
    createdAt: at,
    unreadForMe: unread,
    readBy: id == 'today-own'
        ? readers.where((r) => r.userId != 'adam').toList()
        : const [],
  );
  final messages = empty
      ? <ZyraFamilyMessage>[]
      : [
          message(
            'hana',
            'hassan',
            'Alhamdulillah for the clarity. It wasn’t meant to be.',
            // 7:15 PM in the locked Europe/London September fixture.
            DateTime.utc(2026, 9, 11, 18, 15),
          ),
          message(
            'zainab',
            'hassan',
            'Ending it kindly was the right thing. May Allah make it easy.',
            DateTime.utc(2026, 10, 25, 9, 2),
          ),
          message(
            'zainab-own',
            'adam',
            'JazakAllah khair, Abba.',
            DateTime.utc(2026, 10, 25, 9, 20),
          ),
          message(
            'sara',
            'hassan',
            'Sara’s answers on Faith & Values sit close to ours, ma sha Allah.',
            DateTime.utc(2026, 10, 30, 20, 40),
          ),
          message(
            'sara-own',
            'adam',
            'Yes — I liked how she talked about family.',
            DateTime.utc(2026, 10, 30, 20, 52),
          ),
          if (!basicSeeker)
            message(
              'aisha',
              'hassan',
              'Let’s take our time with Aisha. No rush.',
              DateTime.utc(2026, 10, 30, 21, 5),
            ),
          message(
            'today-own',
            'adam',
            'Assalaamu alaikum. Let’s discuss the journey together.',
            DateTime.utc(2026, 10, 31, 1, 10),
          ),
          message(
            'today',
            'hassan',
            'Wa alaikum assalaam. We’re here to support you.',
            DateTime.utc(2026, 10, 31, 1, 12),
            unread: !guardian,
          ),
        ];
  final tags = <String, ZyraCircleDiscussionTopic>{
    for (final pair in [
      ('sara', sara),
      ('sara-own', sara),
      if (!basicSeeker) ('aisha', aisha),
    ])
      pair.$1: ZyraCircleDiscussionTopic(
        id: pair.$2.referenceId,
        firstName: pair.$2.firstName,
        kind: ZyraCircleTopicKind.current,
      ),
    if (!empty)
      'hana': ZyraCircleDiscussionTopic(
        id: 'draft-circle-past-hana',
        firstName: 'Hana',
        kind: ZyraCircleTopicKind.past,
        endedOn: DateTime.utc(2026, 9, 10),
      ),
    if (!empty)
      'zainab': ZyraCircleDiscussionTopic(
        id: 'draft-circle-past-zainab',
        firstName: 'Zainab',
        kind: ZyraCircleTopicKind.past,
        endedOn: DateTime.utc(2026, 10, 24),
      ),
    if (!empty)
      'zainab-own': ZyraCircleDiscussionTopic(
        id: 'draft-circle-past-zainab',
        firstName: 'Zainab',
        kind: ZyraCircleTopicKind.past,
        endedOn: DateTime.utc(2026, 10, 24),
      ),
  };
  final data = ZyraGuardianCirclePreviewData(
    seekerId: 'adam',
    senderId: sender,
    canSend: !basicGuardian,
    participants: [
      ZyraFamilyCircleParticipant(
        userId: 'adam',
        firstName: 'Adam',
        memberRole: 'seeker',
        isMainGuardian: false,
        isCurrentUser: sender == 'adam',
      ),
      ZyraFamilyCircleParticipant(
        userId: 'hassan',
        firstName: 'Hassan',
        memberRole: 'guardian',
        isMainGuardian: true,
        isCurrentUser: sender == 'hassan',
      ),
      if (!basicSeeker)
        ZyraFamilyCircleParticipant(
          userId: 'ibrahim',
          firstName: 'Ibrahim',
          memberRole: 'guardian',
          isMainGuardian: false,
          isCurrentUser: sender == 'ibrahim',
        ),
    ],
    messages: messages,
    contexts: contexts,
  );
  final design = ValueNotifier(ZyraCircleBubbleDesign.current);
  addTearDown(design.dispose);
  final topics = ZyraCircleTopicsPreview(
    guardianBasic: basicGuardian,
    readOnlyParticipantIds: [if (!basicSeeker) 'ibrahim'],
    clock: () => now,
    messageTopics: tags,
    onManageGuardians: () {},
    onMembership: () {},
    tiles: [
      for (final c in contexts)
        ZyraCircleTopicTile(
          id: c.referenceId,
          name: c.firstName,
          stage: c == sara
              ? 'Stage 4 of 8 · Faith & Values'
              : c == maryam
              ? 'Stage 2 of 8 · Compatibility Reveal'
              : 'Stage 1 of 8 · Salam Exchange',
          photo: photos!
              .forIndex(
                c == sara
                    ? 1
                    : c == maryam
                    ? 3
                    : 2,
              )
              .first,
        ),
      for (final t in past)
        ZyraCircleTopicTile(
          id: t.id,
          name: t.firstName,
          photo: guardian
              ? null
              : photos!.forIndex(t.firstName == 'Zainab' ? 6 : 4).first,
        ),
    ],
  );
  ZyraCircleDiscussionArchive? archive(ZyraCircleDiscussionTopic t) =>
      past.any((p) => identical(p, t))
      ? ZyraCircleDiscussionArchive(
          topicId: t.id,
          firstName: t.firstName,
          startedOn: DateTime.utc(
            2026,
            t.firstName == 'Zainab' ? 10 : 8,
            t.firstName == 'Zainab' ? 2 : 18,
          ),
          endedOn: t.endedOn!,
          sharedSummaryLabel: t.sharedSummaryLabel,
        )
      : null;
  await h.mountPresentation(
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: guardian,
      model: ViewRequestDraftModel().snapshot(),
      tab: 3,
      pages: ['guardian_circle'],
    ),
    child: ZyraPullDownBackScope(
      routeIdentity: Object(),
      onBack: () {},
      child: ZyraGuardianCircleScreen(
        key: UniqueKey(),
        seekerId: 'adam',
        seekerFirstName: 'Adam',
        viewerIsSeeker: !guardian,
        preview: true,
        previewData: data,
        previewTopics: topics,
        previewBubbleDesign: design,
        previewPastTopics: past,
        previewDiscussionArchiveFor: archive,
        canAct: () => true,
        onOpenContext: (_) {},
      ),
    ),
  );
  expect(find.byType(ZyraCircleTopicsPresentation), findsOneWidget);
  Future<void> press(String id) async {
    await h.tester.ensureVisible(key(id));
    await h.tester.tap(key(id));
    await h.tester.pumpAndSettle();
  }

  if (scene == 3) await press('topic_draft-sara');
  if (scene == 7) await press('topic_draft-maryam');
  if ([4, 5, 6, 10, 11].contains(scene)) await press('past');
  if (scene == 5) await press('past_draft-circle-past-zainab');
  if (scene == 6 || scene == 11) await press('past_draft-circle-past-hana');
  if ([2, 8, 12].contains(scene)) await press('menu');
  expect(h.tester.takeException(), isNull);
}

Future<void> snap(BaselineHarness h, String name, {bool narrow = false}) async {
  if (!capture) return;
  final old = debugDisableShadows;
  debugDisableShadows = false;
  try {
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
    );
    void repaint(RenderObject o) {
      o.markNeedsPaint();
      o.visitChildren(repaint);
    }

    repaint(boundary);
    await h.tester.pump();
    if (!narrow) {
      await h.capture(
        'circle_topics',
        name,
        'LOCK20',
        'Actual Circle controller and Topics widgets; explicit master-named offline fixtures; no transport.',
        fileName: '$name.png',
      );
    } else {
      final images = h.tester.widgetList<Image>(find.byType(Image)).toList();
      await h.tester.runAsync(() async {
        for (final widget in images) {
          final context = h.tester.element(find.byWidget(widget).first);
          final stream = widget.image.resolve(
            createLocalImageConfiguration(context),
          );
          final painted = Completer<void>();
          final listener = ImageStreamListener(
            (info, _) {
              info.dispose();
              if (!painted.isCompleted) painted.complete();
            },
            onError: (Object error, StackTrace? stack) {
              if (!painted.isCompleted) painted.completeError(error, stack);
            },
          );
          stream.addListener(listener);
          try {
            await painted.future.timeout(const Duration(seconds: 10));
          } finally {
            stream.removeListener(listener);
          }
        }
      });
      await h.tester.pump();
      await h.tester.pump(const Duration(milliseconds: 100));
      for (final widget in images) {
        final raw = find.descendant(
          of: find.byWidget(widget).first,
          matching: find.byType(RawImage),
        );
        if (raw.evaluate().isNotEmpty) {
          expect(h.tester.widget<RawImage>(raw.first).image, isNotNull);
        }
      }
      await h.tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        try {
          expect(image.width, 960);
          final b = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$output/$name.png').writeAsBytes(b!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    }
  } finally {
    debugDisableShadows = old;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  for (final mode in ['normal', 'large', 'narrow']) {
    for (var scene = 1; scene <= 14; scene++) {
      testWidgets(
        'LOCK20 ${names[scene - 1]} $mode',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = BaselineHarness(
            tester,
            group: 'lock20_$mode',
            flatOutput: true,
            outputRoot: output,
            evidenceRoot: evidence,
            textScale: mode == 'normal' ? 1 : 1.3,
          );
          await fixture(h, scene);
          if (mode == 'narrow') {
            tester.view.physicalSize = const Size(960, 2796);
            await tester.pumpAndSettle();
          }
          await snap(
            h,
            '${names[scene - 1]}${mode == 'normal' ? '' : '_$mode'}',
            narrow: mode == 'narrow',
          );
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  }
}
