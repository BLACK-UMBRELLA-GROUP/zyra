import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/zyra_error_state.dart';
import '../screens/settings/help_support_screen.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_floating_surface.dart';
import 'zyra_info_row.dart';
import 'zyra_tap_feedback.dart';

/// App-stopping failures use this page. Inline errors and empty states keep
/// their own presentation.
class ZyraFullScreenError extends StatefulWidget {
  final ZyraErrorKind kind;
  final Future<void> Function()? onPrimary;
  final String referenceCode;

  const ZyraFullScreenError({
    super.key,
    required this.kind,
    required this.onPrimary,
    required this.referenceCode,
  });

  @override
  State<ZyraFullScreenError> createState() => _ZyraFullScreenErrorState();
}

class _ZyraFullScreenErrorState extends State<ZyraFullScreenError>
    with WidgetsBindingObserver {
  static const _retrySeconds = 15;
  Timer? _timer;
  int _seconds = _retrySeconds;
  bool _working = false;

  bool get _visible =>
      (ModalRoute.isCurrentOf(context) ?? true) &&
      (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
          AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetCountdown();
  }

  @override
  void didUpdateWidget(ZyraFullScreenError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind ||
        (oldWidget.onPrimary == null) != (widget.onPrimary == null)) {
      _resetCountdown();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(_resetCountdown);
  }

  void _resetCountdown() {
    _timer?.cancel();
    _seconds = _retrySeconds;
    if (!_visible ||
        _working ||
        widget.kind.needsSignIn ||
        widget.onPrimary == null) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _retrySeconds - timer.tick;
      if (remaining <= 0) {
        unawaited(_runPrimary());
      } else {
        setState(() => _seconds = remaining);
      }
    });
  }

  Future<void> _runPrimary() async {
    final action = widget.onPrimary;
    if (_working || !_visible || action == null) return;
    _timer?.cancel();
    setState(() => _working = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _resetCountdown();
        });
      }
    }
  }

  void _openSupport() {
    if (!_visible) return;
    final reference = widget.referenceCode;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HelpSupportScreen(errorReference: reference),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final content = kind.content;
    final signIn = kind.needsSignIn;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: ValueKey('zyra_error_screen_${kind.name}'),
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 37).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ZYRA',
                          textAlign: TextAlign.center,
                          style: ZyraText.wordmark(
                            size: 23,
                          ).copyWith(letterSpacing: 6),
                        ),
                        const SizedBox(height: 20),
                        const Spacer(),
                        Semantics(
                          liveRegion: true,
                          child: Column(
                            children: [
                              const _InterruptedConnectionMark(),
                              Text(
                                content.title,
                                textAlign: TextAlign.center,
                                style: ZyraText.heading(size: 26),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                content.message,
                                textAlign: TextAlign.center,
                                style: ZyraText.subtext(size: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 17),
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Text(
                            'WHAT YOU CAN TRY',
                            style: ZyraText.chapterLabel(
                              color: ZyraColors.goldText,
                            ).copyWith(fontSize: 10, letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ErrorHelpCard(kind: kind),
                        const SizedBox(height: 42),
                        const Spacer(),
                        const SizedBox(height: 20),
                        if (!signIn)
                          Text(
                            _working
                                ? 'Trying again…'
                                : 'Trying again in $_seconds s',
                            textAlign: TextAlign.center,
                            style: ZyraText.subtext(size: 12),
                          ),
                        const SizedBox(height: 4),
                        ZyraFloatingSurface(
                          radius: 999,
                          child: OutlinedButton(
                            key: const ValueKey('zyra_error_primary'),
                            onPressed: ZyraTapFeedback.onTap(
                              context,
                              _working || widget.onPrimary == null
                                  ? null
                                  : _runPrimary,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ZyraColors.goldText,
                              backgroundColor: ZyraColors.lowerSurface,
                              disabledForegroundColor: signIn
                                  ? ZyraColors.quietText
                                  : ZyraColors.goldText,
                              disabledBackgroundColor: ZyraColors.lowerSurface,
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              side: const BorderSide(color: ZyraColors.divider),
                              shape: const StadiumBorder(),
                              textStyle: ZyraText.button(size: 13),
                            ),
                            child: Text(
                              signIn
                                  ? 'Sign in again'
                                  : _working
                                  ? 'Connecting…'
                                  : 'Try again',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextButton(
                          key: const ValueKey('zyra_error_secondary'),
                          onPressed: ZyraTapFeedback.onTap(
                            context,
                            _openSupport,
                          ),
                          child: Text(
                            'Contact support',
                            style: ZyraText.button(
                              size: 13,
                              color: ZyraColors.foreground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'REFERENCE: ${widget.referenceCode}',
                          textAlign: TextAlign.center,
                          style: ZyraText.chapterLabel(
                            color: ZyraColors.foregroundMuted,
                          ).copyWith(fontSize: 10, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 3),
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

class _ErrorHelpCard extends StatelessWidget {
  const _ErrorHelpCard({required this.kind});

  final ZyraErrorKind kind;

  static const _retry = ZyraInfoRow(
    iconGap: 9,
    copySize: 11.5,
    icon: Icons.refresh_rounded,
    title: 'We keep trying',
    copy: 'ZYRA tries again on its own while this page is open.',
  );
  static const _support = ZyraInfoRow(
    iconGap: 9,
    copySize: 11.5,
    icon: Icons.help_outline_rounded,
    title: 'Still stuck?',
    copy: 'Contact support and quote the reference below.',
  );

  @override
  Widget build(BuildContext context) {
    final rows = switch (kind) {
      ZyraErrorKind.offline => const [
        ZyraInfoRow(
          iconGap: 9,
          copySize: 11.5,
          icon: Icons.wifi_rounded,
          title: 'Check Wi-Fi or mobile data',
          copy: 'Turn it off and on again, or move closer to your router.',
        ),
        _retry,
        _support,
      ],
      ZyraErrorKind.serviceUnavailable => const [
        _retry,
        ZyraInfoRow(
          iconGap: 9,
          copySize: 12,
          icon: Icons.lock_outline_rounded,
          title: 'Nothing changes while we’re away',
          copy: 'Your profile, Journeys and messages stay as they were.',
        ),
        _support,
      ],
      ZyraErrorKind.sessionExpired || ZyraErrorKind.previewAccess => const [
        ZyraInfoRow(
          iconGap: 9,
          copySize: 11.5,
          icon: Icons.lock_outline_rounded,
          title: 'Why this happens',
          copy: 'Sessions end after a long time away or a password change.',
        ),
        ZyraInfoRow(
          iconGap: 9,
          copySize: 11.5,
          icon: Icons.help_outline_rounded,
          title: 'Can’t sign in?',
          copy: 'Contact support and quote the reference below.',
        ),
      ],
      ZyraErrorKind.page => const [_retry, _support],
    };
    return ZyraFloatingSurface(
      radius: 20,
      child: Container(
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          border: Border.all(color: ZyraColors.surfaceBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.only(left: 54, right: 16),
                  child: Divider(height: 1, color: ZyraColors.divider),
                ),
              rows[i],
            ],
          ],
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
