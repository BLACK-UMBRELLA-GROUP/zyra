// Branded full-screen failure state.
//
// Use this only when the whole route cannot open. Smaller failures stay next
// to the action that failed through ZyraErrorBanner; an honest empty result
// stays a ZyraEmptyState. Keeping those three meanings visually distinct is
// the core of DR-ZYRA-080.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/zyra_error_state.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_trails_meet_rule.dart';

class ZyraFullScreenError extends StatelessWidget {
  final ZyraErrorKind kind;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final String referenceCode;

  const ZyraFullScreenError({
    super.key,
    required this.kind,
    required this.onPrimary,
    required this.onSecondary,
    required this.referenceCode,
  });

  @override
  Widget build(BuildContext context) {
    final content = kind.content;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: ValueKey('zyra_error_screen_${kind.name}'),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 28, 30, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 52,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Text('ZYRA', style: ZyraText.wordmark(size: 29)),
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _InterruptedConnectionMark(),
                                const SizedBox(height: 30),
                                Text(
                                  content.title,
                                  textAlign: TextAlign.center,
                                  style: ZyraText.heading(size: 29),
                                ),
                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 310,
                                  ),
                                  child: Text(
                                    content.message,
                                    textAlign: TextAlign.center,
                                    style: ZyraText.subtext(size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            key: const ValueKey('zyra_error_primary'),
                            onPressed: onPrimary,
                            icon: Icon(
                              kind == ZyraErrorKind.sessionExpired
                                  ? Icons.login_rounded
                                  : Icons.refresh_rounded,
                              size: 19,
                            ),
                            label: Text(content.primaryLabel),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ZyraTrailsMeetRule.gold,
                              backgroundColor: ZyraTrailsMeetRule.gold
                                  .withValues(alpha: 0.10),
                              side: BorderSide(
                                color: ZyraTrailsMeetRule.gold.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                              shape: const StadiumBorder(),
                              textStyle: ZyraText.button(size: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextButton(
                          key: const ValueKey('zyra_error_secondary'),
                          onPressed: onSecondary,
                          child: Text(
                            content.secondaryLabel,
                            style: ZyraText.subtext(
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'REFERENCE: $referenceCode',
                          style: ZyraText.chapterLabel(
                            color: Colors.white.withValues(alpha: 0.34),
                          ).copyWith(letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InterruptedConnectionMark extends StatelessWidget {
  const _InterruptedConnectionMark();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Connection interrupted',
    child: const RepaintBoundary(
      child: SizedBox(
        key: ValueKey('zyra_error_connection_mark'),
        width: 148,
        height: 54,
        child: CustomPaint(painter: _InterruptedConnectionPainter()),
      ),
    ),
  );
}

class _InterruptedConnectionPainter extends CustomPainter {
  const _InterruptedConnectionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = ZyraTrailsMeetRule.gold;
    final y = size.height / 2;
    final left = size.width * 0.20;
    final right = size.width * 0.80;
    final centre = size.width / 2;

    final rail = Paint()
      ..color = gold.withValues(alpha: 0.58)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(centre - 8, y), rail);
    canvas.drawLine(Offset(centre + 8, y), Offset(right, y), rail);

    final glow = Paint()
      ..color = gold.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final dot = Paint()..color = gold;
    for (final x in [left, right]) {
      canvas.drawCircle(Offset(x, y), 7, glow);
      canvas.drawCircle(Offset(x, y), 4.2, dot);
    }

    final breakMark = Paint()
      ..color = gold.withValues(alpha: 0.92)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(centre - 4, y + 5)
      ..lineTo(centre, y - 1)
      ..lineTo(centre + 4, y + 5);
    canvas.drawPath(path, breakMark);
  }

  @override
  bool shouldRepaint(covariant _InterruptedConnectionPainter oldDelegate) =>
      false;
}
