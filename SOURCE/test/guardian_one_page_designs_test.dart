import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _headerFont = 'PoppinsGuardianPermissionHeader';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String? previousReadingFont;

  setUpAll(() async {
    final font = FontLoader(_headerFont);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
  });

  final mainGuardian = WaliLinkedPerson(
    id: 'main',
    firstName: 'Abdul',
    relationship: 'father',
    isMain: true,
    linkedAt: DateTime.utc(2026, 7, 12),
  );
  final additionalGuardian = WaliLinkedPerson(
    id: 'additional',
    firstName: 'Hassan',
    relationship: 'brother',
    linkedAt: DateTime.utc(2026, 8, 2),
  );

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.reset();
    previousReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _headerFont;
    ZyraColors.restoreAppSurfaceStyle(null);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = previousReadingFont;
  });

  Widget subject({
    bool preview = true,
    int previewActiveJourneyCount = 1,
    GuardianMakeMainAction? makeMainGuardian,
    GuardianClearMainAction? clearMainGuardian,
    GuardianRemoveAction? removeGuardian,
    VoidCallback? onChanged,
    List<WaliLinkedPerson>? people,
    GuardianPageJourneyAccessLoader? journeyAccessLoader,
    GuardianPageHistoryConsentLoader? historyConsentLoader,
    bool activityAvailable = true,
    double textScale = 1,
    bool boldText = false,
  }) {
    // A visual fixture request is not authorization. Ordinary loader tests
    // remain explicitly unauthorized; intentional previews opt in here.
    ZyraDeveloperAccess.setAuthorizedForTesting(preview);
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          boldText: boldText,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SafeArea(
            child: SeekerGuardianPage(
              people: people ?? [mainGuardian, additionalGuardian],
              activity: {
                mainGuardian.id: [
                  GuardianActivity(
                    waliId: mainGuardian.id,
                    type: 'review_waiting',
                    occurredAt: DateTime.utc(2026, 9, 15),
                  ),
                ],
              },
              linksAvailable: true,
              activityAvailable: activityAvailable,
              onRetry: () {},
              onAdd: () {},
              historyConsentPreview: preview,
              previewActiveJourneyCount: previewActiveJourneyCount,
              journeyAccessLoader: journeyAccessLoader,
              historyConsentLoader: historyConsentLoader,
              makeMainGuardian: makeMainGuardian,
              clearMainGuardian: clearMainGuardian,
              removeGuardian: removeGuardian,
              onChanged: onChanged,
              comparisonNow: DateTime.utc(2026, 9, 17),
            ),
          ),
        ),
      ),
    );
  }

  Future<ZyraSourceResult<GuardianHistoryConsentState>> confirmedHistory({
    required String guardianId,
    required bool guardianIsMain,
    bool? enabled,
  }) async => ZyraSourceResult.available(
    GuardianHistoryConsentState(
      enabled: enabled ?? false,
      activeGuardianLinkId: 'test-link-$guardianId',
      guardianId: guardianId,
      guardianIsMain: guardianIsMain,
    ),
  );

  Finder accessSummary() =>
      find.byKey(const ValueKey('guardian-journey-access-summary'));

  Finder attemptControl(String prefix) => find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });

  void expectPermissionHeader(
    WidgetTester tester,
    int count, {
    required bool isMain,
  }) {
    Rect globalRect(Finder finder) {
      final box = tester.renderObject<RenderBox>(finder);
      return Rect.fromPoints(
        box.localToGlobal(Offset.zero),
        box.localToGlobal(Offset(box.size.width, box.size.height)),
      );
    }

    final summary = accessSummary();
    final header = find.byKey(
      const ValueKey('guardian-journey-permission-header'),
    );
    final gap = find.byKey(
      const ValueKey('guardian-journey-permission-header-gap'),
    );
    final divider = find.byKey(
      const ValueKey('guardian-journey-permission-header-divider'),
    );
    expect(header, findsOneWidget);
    expect(
      tester.widget<Padding>(header).padding,
      const EdgeInsets.symmetric(vertical: 4),
    );
    final headerRect = globalRect(header);
    final headerSize = tester.getSize(header);
    final scaleX = headerRect.width / headerSize.width;
    final scaleY = headerRect.height / headerSize.height;
    expect(scaleX, greaterThan(0));
    expect(scaleX, lessThanOrEqualTo(1 + .01));
    expect(scaleX, closeTo(scaleY, .01));
    final context = tester.element(header);
    final rects = <String, Rect>{};
    var expectedColumnWidth = 56.0;
    for (final label in ['Journey', 'View', 'Chat']) {
      final text = find.descendant(of: header, matching: find.text(label));
      expect(text, findsOneWidget);
      final widget = tester.widget<Text>(text);
      expect(widget.style!.fontSize, 12.25);
      final rect = globalRect(text);
      rects[label] = rect;
      expect(rect.center.dy, closeTo(headerRect.center.dy, .01));
      expect(rect.top - headerRect.top, greaterThanOrEqualTo(4 * scaleY - .01));
      expect(
        headerRect.bottom - rect.bottom,
        greaterThanOrEqualTo(4 * scaleY - .01),
      );
      expect(rect.left, greaterThanOrEqualTo(globalRect(summary).left));
      expect(rect.right, lessThanOrEqualTo(globalRect(summary).right));
      final paragraph = tester.renderObject<RenderParagraph>(text);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(widget.overflow, isNot(TextOverflow.ellipsis));
      expect(widget.overflow, isNot(TextOverflow.fade));
      final glyphBoxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: label.length),
      );
      expect(glyphBoxes, isNotEmpty);
      for (final box in glyphBoxes) {
        expect(box.left, greaterThanOrEqualTo(-.01));
        expect(box.top, greaterThanOrEqualTo(-.01));
        expect(box.right, lessThanOrEqualTo(paragraph.size.width + .01));
        expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + .01));
      }
      if (label != 'Journey') {
        var style = DefaultTextStyle.of(context).style.merge(widget.style);
        if (MediaQuery.boldTextOf(context)) {
          style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
        }
        final measure = TextPainter(
          text: TextSpan(text: label, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
          maxLines: 1,
        )..layout();
        expectedColumnWidth = math.max(
          expectedColumnWidth,
          measure.width.ceilToDouble() + 12,
        );
        measure.dispose();
      }
    }
    expect(
      rects['Journey']!.right,
      lessThanOrEqualTo(rects['View']!.left + .01),
    );
    expect(rects['View']!.right, lessThanOrEqualTo(rects['Chat']!.left + .01));
    for (final permission in ['View', 'Chat']) {
      expect(
        rects[permission]!.width,
        closeTo(expectedColumnWidth * scaleX, .01),
      );
      expect(
        rects[permission]!.center.dy,
        closeTo(rects['Journey']!.center.dy, .01),
      );
    }
    expect(tester.getSize(gap).height, 8);
    expect(globalRect(gap).top, closeTo(headerRect.bottom, .01));
    expect(
      globalRect(divider).top - headerRect.bottom,
      closeTo(8 * scaleY, .01),
    );
    for (var index = 0; index < 3; index++) {
      final pending = index >= count;
      final attempt = index == 0
          ? 'dev-active-journey'
          : 'dev-active-journey-${index + 1}';
      final rowLabel = pending
          ? find.descendant(
              of: find.byKey(ValueKey('guardian-journey-pending-row-$index')),
              matching: find.byType(Text),
            )
          : find.text('Journey with ${['Maryam', 'Aaliyah', 'Sara'][index]}');
      expect(rowLabel, findsOneWidget);
      expect(globalRect(rowLabel).left, closeTo(rects['Journey']!.left, .01));
      for (final permission in ['view', 'chat']) {
        final key = pending
            ? 'guardian-journey-pending-$permission-$index'
            : isMain
            ? 'guardian-journey-$permission-required-$attempt'
            : 'guardian-journey-${permission == 'view' ? 'access' : 'chat'}-toggle-$attempt';
        final control = find.byKey(ValueKey(key));
        expect(control, findsOneWidget);
        expect(
          tester.getCenter(control).dx,
          closeTo(
            rects[permission == 'view' ? 'View' : 'Chat']!.center.dx,
            .01,
          ),
        );
        expect(
          tester.getCenter(control).dy,
          closeTo(tester.getCenter(rowLabel).dy, .01),
        );
        if (!pending && isMain) {
          expect(tester.getSize(control), const Size(26, 26));
        } else {
          expect(tester.getSize(control), const Size(44, 44));
          final face = find.descendant(
            of: control,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.constraints ==
                      const BoxConstraints.tightFor(width: 26, height: 26),
            ),
          );
          expect(face, findsOneWidget);
          expect(tester.getSize(face), const Size(26, 26));
        }
      }
    }
  }

  void expectPendingAccess(
    WidgetTester tester,
    int count, {
    required bool isMain,
  }) {
    expect(find.text('Awaiting a Journey'), findsNWidgets(3 - count));
    final switches = tester
        .widgetList<Semantics>(
          find.descendant(
            of: accessSummary(),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.toggled != null,
            ),
          ),
        )
        .toList();
    final pending = switches.where(
      (toggle) =>
          toggle.properties.toggled == false && toggle.properties.onTap == null,
    );
    expect(pending, hasLength((3 - count) * 2));
    expect(switches, hasLength(isMain ? (3 - count) * 2 : 6));
    for (var slot = count; slot < 3; slot++) {
      expect(
        find.byKey(ValueKey('guardian-journey-pending-row-$slot')),
        findsOneWidget,
      );
      for (final permission in ['view', 'chat']) {
        final toggle = tester.widget<Semantics>(
          find.byKey(ValueKey('guardian-journey-pending-$permission-$slot')),
        );
        expect(toggle.properties.toggled, isFalse);
        expect(toggle.properties.enabled, isFalse);
        expect(toggle.properties.onTap, isNull);
      }
    }
    expect(
      attemptControl('guardian-journey-view-required-'),
      findsNWidgets(isMain ? count : 0),
    );
    expect(
      attemptControl('guardian-journey-chat-required-'),
      findsNWidgets(isMain ? count : 0),
    );
    expect(
      attemptControl('guardian-journey-access-toggle-'),
      findsNWidgets(isMain ? 0 : count),
    );
    expect(
      attemptControl('guardian-journey-chat-toggle-'),
      findsNWidgets(isMain ? 0 : count),
    );
    for (var index = 0; index < 3; index++) {
      expect(
        find.text('Journey with ${['Maryam', 'Aaliyah', 'Sara'][index]}'),
        index < count ? findsOneWidget : findsNothing,
      );
    }
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    for (final person in [mainGuardian, additionalGuardian]) {
      for (var count = 0; count <= 3; count++) {
        testWidgets(
          '${person.isMain ? 'Main' : 'Additional'} with $count active Journeys uses three rows on ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              subject(people: [person], previewActiveJourneyCount: count),
            );
            await tester.pumpAndSettle();
            expect(accessSummary(), findsOneWidget);
            expectPendingAccess(tester, count, isMain: person.isMain);
            expectPermissionHeader(tester, count, isMain: person.isMain);
            final rowCentres = <double>[
              for (var index = 0; index < count; index++)
                tester
                    .getCenter(
                      find.text(
                        'Journey with ${['Maryam', 'Aaliyah', 'Sara'][index]}',
                      ),
                    )
                    .dy,
              for (var index = count; index < 3; index++)
                tester
                    .getCenter(
                      find.text('Awaiting a Journey').at(index - count),
                    )
                    .dy,
            ];
            expect(
              rowCentres[1] - rowCentres[0],
              closeTo(rowCentres[2] - rowCentres[1], 1),
            );
            expect(
              find.text(
                count == 0
                    ? 'NO ACTIVE JOURNEYS'
                    : count == 1
                    ? '1 ACTIVE JOURNEY'
                    : '$count ACTIVE JOURNEYS',
              ),
              findsNothing,
            );
            expect(find.byType(SingleChildScrollView), findsNothing);
            final page = tester.getRect(
              find.byKey(const ValueKey('guardian-page-view')),
            );
            final summary = tester.getRect(accessSummary());
            final remove = tester.getRect(
              find.byKey(const ValueKey('guardian-remove')),
            );
            expect(summary.top, greaterThanOrEqualTo(page.top));
            expect(summary.bottom, lessThan(remove.top));
            expect(remove.bottom, lessThanOrEqualTo(page.bottom + .01));
            expect(page.bottom - remove.bottom, lessThanOrEqualTo(8));
            expect(
              find.byKey(ValueKey('guardian-page-static-${person.id}')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final person in [mainGuardian, additionalGuardian]) {
    for (final boldText in [false, true]) {
      testWidgets(
        '${person.isMain ? 'Main' : 'Additional'} available permission headers and controls fit 320x568 at 2x text with bold $boldText',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            subject(
              people: [person],
              previewActiveJourneyCount: 3,
              textScale: 2,
              boldText: boldText,
            ),
          );
          await tester.pumpAndSettle();
          expectPendingAccess(tester, 3, isMain: person.isMain);
          expectPermissionHeader(tester, 3, isMain: person.isMain);
          expect(find.byType(SingleChildScrollView), findsNothing);
          final page = tester.getRect(
            find.byKey(const ValueKey('guardian-page-view')),
          );
          final remove = tester.getRect(
            find.byKey(const ValueKey('guardian-remove')),
          );
          expect(remove.bottom, lessThanOrEqualTo(page.bottom + .01));
          expect(accessSummary().hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final textScale in [1.4, 2.0]) {
      testWidgets(
        '${person.isMain ? 'Main' : 'Additional'} production failures fit 320x568 at ${textScale}x text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          Future<ZyraSourceResult<List<GuardianJourneyAccessState>>>
          unavailableJourneys({
            required String guardianId,
            String? attemptId,
            bool? enabled,
            bool? chatEnabled,
          }) async {
            expect(guardianId, person.id);
            expect(attemptId, isNull);
            expect(enabled, isNull);
            expect(chatEnabled, isNull);
            return const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            );
          }

          Future<ZyraSourceResult<GuardianHistoryConsentState>>
          unavailableHistory({
            required String guardianId,
            required bool guardianIsMain,
            bool? enabled,
          }) async {
            expect(guardianId, person.id);
            expect(guardianIsMain, person.isMain);
            expect(enabled, isNull);
            return const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            );
          }

          await tester.pumpWidget(
            subject(
              people: [person],
              preview: false,
              activityAvailable: false,
              textScale: textScale,
              journeyAccessLoader: unavailableJourneys,
              historyConsentLoader: unavailableHistory,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
          expect(find.text('Journey unavailable'), findsNWidgets(3));
          expect(find.text('Awaiting a Journey'), findsNothing);
          expectPermissionHeader(tester, 0, isMain: person.isMain);
          expect(
            find.text('Past-summary permission could not be refreshed.'),
            findsOneWidget,
          );
          expect(
            find.text('Current Guardian activity could not be refreshed.'),
            person.isMain ? findsNothing : findsOneWidget,
          );
          final switches = tester
              .widgetList<Semantics>(
                find.descendant(
                  of: accessSummary(),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Semantics &&
                        widget.properties.toggled != null,
                  ),
                ),
              )
              .toList();
          expect(switches, hasLength(6));
          expect(
            switches.every(
              (toggle) =>
                  toggle.properties.toggled == false &&
                  toggle.properties.onTap == null,
            ),
            isTrue,
          );
          expect(find.text('MANAGE'), findsNothing);
          expect(find.text('JOURNEY ACCESS'), findsNothing);
          expect(find.byType(SingleChildScrollView), findsNothing);
          final page = tester.getRect(
            find.byKey(const ValueKey('guardian-page-view')),
          );
          final remove = tester.getRect(
            find.byKey(const ValueKey('guardian-remove')),
          );
          expect(remove.top, greaterThanOrEqualTo(page.top));
          expect(remove.bottom, lessThanOrEqualTo(page.bottom + .01));
          expect(page.bottom - remove.bottom, lessThanOrEqualTo(8));
          expect(
            find.byKey(
              ValueKey(
                person.isMain ? 'guardian-clear-main' : 'guardian-make-main',
              ),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '${person.isMain ? 'Main' : 'Additional'} loading and failure never claim pending empty Journeys',
      (tester) async {
        final response =
            Completer<ZyraSourceResult<List<GuardianJourneyAccessState>>>();
        var reads = 0;
        Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> loader({
          required String guardianId,
          String? attemptId,
          bool? enabled,
          bool? chatEnabled,
        }) {
          expect(guardianId, person.id);
          expect(attemptId, isNull);
          expect(enabled, isNull);
          expect(chatEnabled, isNull);
          reads++;
          return reads == 1
              ? response.future
              : Future.value(
                  const ZyraSourceResult.available(
                    <GuardianJourneyAccessState>[],
                  ),
                );
        }

        await tester.pumpWidget(
          subject(
            people: [person],
            preview: false,
            journeyAccessLoader: loader,
            historyConsentLoader: confirmedHistory,
          ),
        );
        await tester.pump();
        expect(find.text('Loading Journey…'), findsNWidgets(3));
        expect(find.text('LOADING JOURNEY ACCESS'), findsOneWidget);
        expect(find.text('Awaiting a Journey'), findsNothing);
        expect(find.text('Journey unavailable'), findsNothing);
        final loadingSwitches = tester
            .widgetList<Semantics>(
              find.descendant(
                of: accessSummary(),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Semantics && widget.properties.toggled != null,
                ),
              ),
            )
            .toList();
        expect(loadingSwitches, hasLength(6));
        for (final toggle in loadingSwitches) {
          expect(toggle.properties.toggled, isFalse);
          expect(toggle.properties.onTap, isNull);
        }
        expect(attemptControl('guardian-journey-view-required-'), findsNothing);
        expect(attemptControl('guardian-journey-access-toggle-'), findsNothing);
        response.complete(
          const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed),
        );
        await tester.pumpAndSettle();
        expect(find.text('Journey unavailable'), findsNWidgets(3));
        expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
        expect(find.text('Awaiting a Journey'), findsNothing);
        expect(find.text('Loading Journey…'), findsNothing);
        final switches = tester
            .widgetList<Semantics>(
              find.descendant(
                of: accessSummary(),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Semantics && widget.properties.toggled != null,
                ),
              ),
            )
            .toList();
        expect(switches, hasLength(6));
        expect(
          switches.every(
            (toggle) =>
                toggle.properties.toggled == false &&
                toggle.properties.onTap == null,
          ),
          isTrue,
        );
        expect(find.text('Try again'), findsOneWidget);
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(reads, 2);
        expect(find.text('Awaiting a Journey'), findsNWidgets(3));
        expect(find.text('Journey unavailable'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'pending slots never write while a real Additional Journey remains independently writable',
    (tester) async {
      final writes = <String>[];
      var view = true;
      var chat = true;
      Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> loader({
        required String guardianId,
        String? attemptId,
        bool? enabled,
        bool? chatEnabled,
      }) async {
        expect(guardianId, additionalGuardian.id);
        if (attemptId != null) {
          expect(attemptId, 'real-active-attempt');
          writes.add(attemptId);
          view = enabled ?? view;
          chat = view ? (chatEnabled ?? chat) : false;
        }
        return ZyraSourceResult.available([
          GuardianJourneyAccessState(
            attemptId: 'real-active-attempt',
            matchId: 'real-match',
            counterpartFirstName: 'Maryam',
            included: view,
            canChange: true,
            guardianIsMain: false,
            chatAvailable: true,
            chatEnabled: chat,
          ),
        ]);
      }

      await tester.pumpWidget(
        subject(
          people: [additionalGuardian],
          preview: false,
          journeyAccessLoader: loader,
          historyConsentLoader: confirmedHistory,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Awaiting a Journey'), findsNWidgets(2));
      final pending = find.descendant(
        of: accessSummary(),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.toggled == false &&
              widget.properties.onTap == null,
        ),
      );
      expect(pending, findsNWidgets(4));
      for (var index = 0; index < 4; index++) {
        await tester.tap(pending.at(index));
        await tester.pumpAndSettle();
      }
      expect(writes, isEmpty);
      await tester.tap(
        find.byKey(
          const ValueKey('guardian-journey-access-toggle-real-active-attempt'),
        ),
      );
      await tester.pumpAndSettle();
      expect(writes, ['real-active-attempt']);
      expect(view, isFalse);
      expect(chat, isFalse);
      expect(find.text('Awaiting a Journey'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('official Quiet sections page renders without retired content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-page-quiet-sections')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('guardian-page-view')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardian-page-scroll-main')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('guardian-page-static-main')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guardian-page-bottom-fade')),
      findsNothing,
    );
    expect(find.text('Share past Journey summaries'), findsOneWidget);
    expect(find.text('CURRENT OBLIGATION'), findsNothing);
    expect(find.text('Remove as Main Guardian'), findsOneWidget);
    expect(find.text('Remove Guardian'), findsOneWidget);
    expect(find.textContaining('Swipe to view'), findsNothing);
    expect(find.text('RELATIONSHIP HISTORY'), findsNothing);
    expect(
      find.byKey(const ValueKey('main-guardian-protected-access')),
      findsOneWidget,
    );
    expect(
      tester.widget(
        find.byKey(const ValueKey('main-guardian-protected-access')),
      ),
      isA<Column>(),
      reason: 'Main access should not restore the translucent card container',
    );
    expect(
      find.byKey(const ValueKey('main-guardian-journey-access-toggle')),
      findsNothing,
    );
    expect(find.text('Journey with Maryam'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('guardian-journey-view-required-dev-active-journey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('guardian-journey-chat-required-dev-active-journey'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Main Guardian access cannot be switched off'),
      findsNothing,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Main access stays visible and Manage stays quiet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-journey-access-summary')),
      findsOneWidget,
    );
    expect(find.text('Journey with Maryam'), findsOneWidget);

    final clearMain = find.byKey(const ValueKey('guardian-clear-main'));
    await tester.ensureVisible(clearMain);
    await tester.pumpAndSettle();
    final clearDecoration =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: clearMain,
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    // LOCK14 V2 floating surfaces, APP_COLOURS/MASTERS/c04_guardian_tab.png.
    expect(clearDecoration.color, ZyraColors.surfaceFill);
    expect((clearDecoration.border! as Border).top.color, ZyraColors.ink(0.16));

    final remove = find.byKey(const ValueKey('guardian-remove'));
    final removeDecoration =
        tester
                .widget<Container>(
                  find
                      .descendant(of: remove, matching: find.byType(Container))
                      .first,
                )
                .decoration!
            as BoxDecoration;
    expect(
      (removeDecoration.border! as Border).top.color,
      ZyraColors.destructive.withValues(alpha: 0.30),
    );
  });

  testWidgets('horizontal swipe changes Guardian and dots without a button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Guardian 1 of 2'), findsOneWidget);
    expect(find.textContaining('Swipe to view'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('guardian-page-view')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Guardian 2 of 2'), findsOneWidget);
    expect(find.text('Hassan'), findsOneWidget);
    expect(find.text('Limited Journey summary'), findsNothing);
    expect(find.text('Journey with Maryam'), findsOneWidget);
    expect(find.text('CAN VIEW'), findsNothing);
    expect(find.text('MAIN GUARDIAN LEADS'), findsNothing);
    expect(find.text('LEADS'), findsNothing);
    expect(find.text('Make Main Guardian'), findsOneWidget);
    expect(find.text('Remove Guardian'), findsOneWidget);
    expect(find.text('Journey with Maryam'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Included'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('guardian-journey-chat-toggle-dev-active-journey'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Guardian One makes Chat available'),
      findsNothing,
    );
    expect(find.text('Turn on View before allowing Chat.'), findsNothing);
  });

  testWidgets('Additional Guardian preview can show three active Journeys', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject(previewActiveJourneyCount: 3));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('guardian-page-view')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 ACTIVE JOURNEYS'), findsNothing);
    expect(find.text('Journey with Maryam'), findsOneWidget);
    expect(find.text('Journey with Aaliyah'), findsOneWidget);
    expect(find.text('Journey with Sara'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardian-journey-access-summary')),
      findsOneWidget,
    );
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('guardian-journey-access-toggle-dev-active-journey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('guardian-journey-chat-toggle-dev-active-journey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('guardian-journey-access-toggle-dev-active-journey-2'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('guardian-journey-chat-toggle-dev-active-journey-2'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('guardian-journey-access-toggle-dev-active-journey-3'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('guardian-journey-chat-toggle-dev-active-journey-3'),
      ),
      findsOneWidget,
    );

    Semantics circleFor(String key) =>
        tester.widget<Semantics>(find.byKey(ValueKey(key)));

    final maryamView = find.byKey(
      const ValueKey('guardian-journey-access-toggle-dev-active-journey'),
    );
    await tester.tap(maryamView);
    await tester.pumpAndSettle();

    expect(
      circleFor(
        'guardian-journey-access-toggle-dev-active-journey',
      ).properties.toggled,
      isFalse,
    );
    expect(
      circleFor(
        'guardian-journey-chat-toggle-dev-active-journey',
      ).properties.toggled,
      isFalse,
    );
    expect(
      circleFor(
        'guardian-journey-access-toggle-dev-active-journey-2',
      ).properties.toggled,
      isTrue,
    );
    expect(
      circleFor(
        'guardian-journey-chat-toggle-dev-active-journey-2',
      ).properties.toggled,
      isTrue,
    );
    expect(
      circleFor(
        'guardian-journey-access-toggle-dev-active-journey-3',
      ).properties.toggled,
      isTrue,
    );
    expect(
      circleFor(
        'guardian-journey-chat-toggle-dev-active-journey-3',
      ).properties.toggled,
      isTrue,
    );

    final page = tester.getRect(
      find.byKey(const ValueKey('guardian-page-view')),
    );
    final remove = tester.getRect(
      find.byKey(const ValueKey('guardian-remove')),
    );
    expect(
      page.bottom - remove.bottom,
      inInclusiveRange(0, 8),
      reason: 'Manage must anchor near the bottom of the one-screen page.',
    );
    final maryam = tester.getCenter(find.text('Journey with Maryam')).dy;
    final aaliyah = tester.getCenter(find.text('Journey with Aaliyah')).dy;
    final sara = tester.getCenter(find.text('Journey with Sara')).dy;
    expect(
      aaliyah - maryam,
      closeTo(sara - aaliyah, 1),
      reason: 'The available Journey area should use balanced row spacing.',
    );
  });

  testWidgets(
    'Main Guardian shows all three named Journeys without scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(subject(previewActiveJourneyCount: 3));
      await tester.pumpAndSettle();

      expect(find.text('3 ACTIVE JOURNEYS'), findsNothing);
      expect(find.text('Journey with Maryam'), findsOneWidget);
      expect(find.text('Journey with Aaliyah'), findsOneWidget);
      expect(find.text('Journey with Sara'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('guardian-journey-view-required-dev-active-journey-3'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('guardian-journey-chat-required-dev-active-journey-3'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Additional Guardian Journey circles toggle in local preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('guardian-page-view')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();

    final viewKey = const ValueKey(
      'guardian-journey-access-toggle-dev-active-journey',
    );
    final chatKey = const ValueKey(
      'guardian-journey-chat-toggle-dev-active-journey',
    );
    Semantics viewToggle() => tester.widget<Semantics>(find.byKey(viewKey));
    Semantics chatToggle() => tester.widget<Semantics>(find.byKey(chatKey));
    expect(viewToggle().properties.toggled, isTrue);
    expect(chatToggle().properties.toggled, isTrue);

    await tester.tap(find.byKey(viewKey));
    await tester.pumpAndSettle();
    expect(viewToggle().properties.toggled, isFalse);
    expect(chatToggle().properties.toggled, isFalse);
    expect(chatToggle().properties.onTap, isNull);
    expect(find.text('Turn on View before allowing Chat.'), findsNothing);

    await tester.tap(find.byKey(viewKey));
    await tester.pumpAndSettle();
    expect(viewToggle().properties.toggled, isTrue);
    expect(chatToggle().properties.toggled, isFalse);
    expect(chatToggle().properties.onTap, isNotNull);

    await tester.tap(find.byKey(chatKey));
    await tester.pumpAndSettle();
    expect(chatToggle().properties.toggled, isTrue);
  });

  testWidgets('Main removal asks inline with Cancel and Confirm', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final clearMain = find.byKey(const ValueKey('guardian-clear-main'));
    await tester.ensureVisible(clearMain);
    await tester.pumpAndSettle();
    await tester.tap(clearMain);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-clear-main-confirmation')),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Remove as Main Guardian'), findsOneWidget);
  });

  testWidgets('Make Main and removal use the same inline confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var madeMain = false;
    var removed = false;
    var changed = 0;
    await tester.pumpWidget(
      subject(
        preview: false,
        makeMainGuardian: (_) async {
          madeMain = true;
          return true;
        },
        removeGuardian: (_) async {
          removed = true;
          return null;
        },
        onChanged: () => changed++,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('guardian-page-view')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();

    final makeMain = find.byKey(const ValueKey('guardian-make-main'));
    await tester.ensureVisible(makeMain);
    await tester.pumpAndSettle();
    await tester.tap(makeMain);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('guardian-make-main-confirmation')),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(madeMain, isTrue);
    expect(changed, 1);

    final remove = find.byKey(const ValueKey('guardian-remove'));
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('guardian-remove-confirmation')),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
    expect(changed, 2);
  });

  testWidgets('preview Journey-history switch remains interactive', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    Switch toggle() => tester.widget<Switch>(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
    );
    expect(toggle().value, isFalse);

    final historyToggle = find.byKey(
      const ValueKey('guardian-history-consent-toggle'),
    );
    await tester.ensureVisible(historyToggle);
    await tester.pumpAndSettle();
    await tester.tap(historyToggle);
    await tester.pumpAndSettle();

    expect(toggle().value, isTrue);
  });

  testWidgets('past Journey summary information opens in a bottom sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-history-consent-explanation')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('guardian-history-consent-details-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Past Journey summaries'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardian-history-consent-explanation')),
      findsOneWidget,
    );
    final sheet = tester.widget<Container>(
      find.byKey(const ValueKey('guardian-history-consent-explanation')),
    );
    final decoration = sheet.decoration! as BoxDecoration;
    expect(decoration.color, ZyraColors.modalSheetSurface);
    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
