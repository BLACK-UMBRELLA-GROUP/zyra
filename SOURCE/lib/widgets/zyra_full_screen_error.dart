// Branded full-screen failure state.
//
// Use this only when the whole route cannot open. Smaller failures stay next
// to the action that failed through ZyraErrorBanner; an honest empty result
// stays a ZyraEmptyState. Keeping those three meanings visually distinct is
// the core of DR-ZYRA-080.

import 'zyra_tap_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/zyra_error_state.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

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
      value: ZyraColors.isLightPalette
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        key: ValueKey('zyra_error_screen_${kind.name}'),
        body: kind == ZyraErrorKind.previewAccess
            ? ZyraCompactRecoverySurface(
                noticeKey: const ValueKey('zyra_error_compact_notice'),
                title: content.title,
                message: content.message,
                primaryLabel: content.primaryLabel,
                secondaryLabel: content.secondaryLabel,
                primaryKey: const ValueKey('zyra_error_primary'),
                secondaryKey: const ValueKey('zyra_error_secondary'),
                onPrimary: onPrimary,
                onSecondary: onSecondary,
                referenceCode: referenceCode,
              )
            : DecoratedBox(
                decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
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
                                  onPressed: ZyraTapFeedback.onTap(
                                    context,
                                    onPrimary,
                                  ),
                                  icon: Icon(
                                    kind == ZyraErrorKind.sessionExpired
                                        ? Icons.login_rounded
                                        : Icons.refresh_rounded,
                                    size: 19,
                                  ),
                                  label: Text(
                                    content.primaryLabel,
                                    style: const TextStyle(
                                      color: ZyraColors.goldText,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ZyraColors.journeyGold,
                                    backgroundColor: ZyraColors.journeyGold
                                        .withValues(alpha: 0.10),
                                    side: BorderSide(
                                      color: ZyraColors.journeyGold.withValues(
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
                                onPressed: ZyraTapFeedback.onTap(
                                  context,
                                  onSecondary,
                                ),
                                child: Text(
                                  content.secondaryLabel,
                                  style: ZyraText.subtext(
                                    size: 13,
                                    color: ZyraColors.ink(0.72),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'REFERENCE: $referenceCode',
                                style: ZyraText.chapterLabel(
                                  color: ZyraColors.ink(0.34),
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

/// Quiet, compact recovery instead of a technical full-page interruption.
/// This is presentation only: the caller still owns every permission check,
/// recovery deadline, disabled state and guarded action. It never retains a
/// private page behind an unsuccessful check or grants access itself.
class ZyraCompactRecoverySurface extends StatelessWidget {
  const ZyraCompactRecoverySurface({
    super.key,
    required this.noticeKey,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primaryKey,
    required this.secondaryKey,
    required this.onPrimary,
    required this.onSecondary,
    this.referenceCode,
  });

  final Key noticeKey;
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final Key primaryKey;
  final Key secondaryKey;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final String? referenceCode;

  Color get _accent => ZyraColors.isLightPalette
      ? const Color(0xFF76531F)
      : ZyraColors.journeyGold;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 40).clamp(0, double.infinity),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  key: noticeKey,
                  color: ZyraColors.modalSheetSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: ZyraColors.ink(0.18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: ZyraText.heading(size: 20)),
                              const SizedBox(height: 10),
                              Text(
                                message,
                                style: ZyraText.body(
                                  size: 14,
                                  color: ZyraColors.ink(0.86),
                                ).copyWith(height: 1.45),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          key: primaryKey,
                          onPressed: ZyraTapFeedback.onTap(context, onPrimary),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            foregroundColor: _accent,
                            disabledForegroundColor: ZyraColors.ink(0.42),
                            side: BorderSide(
                              color: _accent.withValues(alpha: 0.72),
                            ),
                            shape: const StadiumBorder(),
                            textStyle: ZyraText.button(size: 14),
                          ),
                          child: Text(
                            primaryLabel,
                            style: TextStyle(
                              color: onPrimary == null
                                  ? ZyraColors.ink(0.42)
                                  : ZyraColors.goldText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          key: secondaryKey,
                          onPressed: ZyraTapFeedback.onTap(
                            context,
                            onSecondary,
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            foregroundColor: ZyraColors.ink(0.86),
                            disabledForegroundColor: ZyraColors.ink(0.42),
                            textStyle: ZyraText.button(size: 14),
                          ),
                          child: Text(
                            secondaryLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (referenceCode case final reference?) ...[
                          const SizedBox(height: 6),
                          Text(
                            'REFERENCE: $reference',
                            textAlign: TextAlign.center,
                            style: ZyraText.subtext(
                              size: 11,
                              color: ZyraColors.ink(0.72),
                            ),
                          ),
                        ],
                      ],
                    ),
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
    const gold = ZyraColors.journeyGold;
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
