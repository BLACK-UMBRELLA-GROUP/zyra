import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_rendered_text_contrast.dart';
import 'visual/baseline_capture_support.dart';

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);
  for (final ink in const [Color(0xFF845F24), Color(0xFFC08A3A)]) {
    testWidgets('underlined link measures its actual ivory backdrop $ink', (
      t,
    ) async {
      const boundaryKey = ValueKey('underlined-link-control');
      await t.pumpWidget(
        MaterialApp(
          home: Material(
            child: RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(
                color: const Color(0xFFEEE6D8),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'If one is wrong, '),
                        TextSpan(
                          text: 'contact support',
                          style: TextStyle(
                            color: ink,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    style: ZyraText.body(
                      size: 12.5,
                      color: const Color(0xFF4F443A),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final result = await auditZyraRenderedText(t, boundary);
      if (ink == const Color(0xFF845F24)) {
        expect(result.failures, isEmpty, reason: '${result.toJson()}');
      } else {
        expect(
          result.failures.any(
            (failure) =>
                failure['text'] == 'contact support' &&
                failure['contrast_pass'] == false,
          ),
          isTrue,
        );
      }
    });
  }
}
