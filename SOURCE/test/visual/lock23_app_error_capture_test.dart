import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LOCK23_CAPTURE_DIR');

void main() {
  if (_output.isNotEmpty) {
    setUpAll(() => baselineSetUp(evidenceRoot: _output));
    tearDownAll(baselineTearDown);
  }

  for (final sample in [
    ('e01', ZyraErrorKind.offline, 'ZY-4Z99'),
    ('e02', ZyraErrorKind.serviceUnavailable, 'ZY-7K2M'),
    ('e03', ZyraErrorKind.previewAccess, 'ZY-BYUR'),
    ('e04', ZyraErrorKind.offline, 'ZY-4Z99'),
    ('e05', ZyraErrorKind.serviceUnavailable, 'ZY-7K2M'),
  ]) {
    final (name, kind, reference) = sample;
    testWidgets('LOCK 23 $name capture', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<void>();
      final harness = BaselineHarness(
        tester,
        group: 'lock23_$name',
        outputRoot: _output,
        evidenceRoot: _output,
        flatOutput: true,
      );
      try {
        await harness.mountPresentation(
          child: ZyraFullScreenError(
            kind: kind,
            referenceCode: reference,
            onPrimary: () => pending.future,
          ),
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: name == 'e05',
            model: ViewRequestDraftModel(capacity: 3).snapshot(),
            tab: 0,
            pages: const [],
          ),
        );
        if (name == 'e04') {
          await tester.tap(find.byKey(const ValueKey('zyra_error_primary')));
          await tester.pump();
          expect(find.text('Connecting…'), findsOneWidget);
        }
        final previous = debugDisableShadows;
        debugDisableShadows = false;
        try {
          void repaint(RenderObject node) {
            node.markNeedsPaint();
            node.visitChildren(repaint);
          }

          repaint(
            tester.renderObject(
              find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
            ),
          );
          await tester.pump();
          await harness.capture(
            'app_error',
            name,
            kind.name,
            'Production error widget, synthetic reference, no backend',
            fileName: '$name.png',
          );
        } finally {
          debugDisableShadows = previous;
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        pending.complete();
        await tester.pump();
      }
    }, skip: _output.isEmpty);
  }
}
