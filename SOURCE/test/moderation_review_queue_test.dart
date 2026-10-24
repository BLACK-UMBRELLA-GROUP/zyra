import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_moderation_review.dart';
import 'package:zyra/screens/dev/moderation_review_queue_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_moderation_preview_store.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraModerationPreviewStore.instance.clear();
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraModerationPreviewStore.instance.clear();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('developer queue shows all three moderation states', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: ModerationReviewQueueScreen()),
    );
    await tester.pump();

    expect(find.text('INTERNAL PREVIEW · LOCAL STATE ONLY'), findsOneWidget);
    expect(find.text('Report profile'), findsOneWidget);
    expect(find.text('Report photo'), findsOneWidget);
    expect(find.text(ZyraModerationReviewStatus.pending.name), findsWidgets);
    expect(find.text(ZyraModerationReviewStatus.approved.name), findsWidgets);
    expect(find.text(ZyraModerationReviewStatus.rejected.name), findsWidgets);
  });

  testWidgets('photo report preview enters the pending queue', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: ModerationReviewQueueScreen()),
    );
    await tester.pump();
    final before = ZyraModerationPreviewStore.instance.items.length;

    await tester.tap(
      find.byKey(const ValueKey('moderation-report-photo-preview')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Report this photo'), findsOneWidget);

    await tester.tap(find.text('Nudity or sexual content'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send report'));
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Report sent'), findsOneWidget);

    final items = ZyraModerationPreviewStore.instance.items;
    expect(items, hasLength(before + 1));
    expect(items.first.contentType, ZyraReportedContentType.photo);
    expect(items.first.status, ZyraModerationReviewStatus.pending);
  });
}
