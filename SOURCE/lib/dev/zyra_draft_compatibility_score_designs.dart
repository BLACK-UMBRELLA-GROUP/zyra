import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/zyra_compatibility_area.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_compatibility_area_row.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

/// The admitted owner supplies only the actions available for a locked area.
class ZyraCompatibilityAreaGate {
  const ZyraCompatibilityAreaGate({
    required this.guardian,
    this.canAct,
    this.onUpgrade,
    this.balance = 0,
    this.onUnlock,
    this.onBuyMore,
  }) : assert(
         canAct != null ||
             (onUpgrade == null && onUnlock == null && onBuyMore == null),
       );

  final bool guardian;
  final int balance;
  final bool Function()? canAct;
  final VoidCallback? onUpgrade, onUnlock, onBuyMore;
}

/// Presentation only, mounted by the protected caller after its local reveal.
///
/// The caller supplies the Overall value and any admitted area bands.
/// This reader never scores answers, loads a person, spends an unlock, grants
/// access, persists data or owns route navigation. Its only state is pagination.
class ZyraCompatibilityScoreReader extends StatefulWidget {
  const ZyraCompatibilityScoreReader({
    super.key,
    required this.personName,
    required this.overallScore,
    this.areaGate,
    this.areaBands,
  }) : assert(overallScore >= 0 && overallScore <= 100),
       assert(areaGate == null || areaBands == null);

  final String personName;
  final int overallScore;
  final ZyraCompatibilityAreaGate? areaGate;
  final Map<ZyraCompatibilityArea, ZyraCompatibilityBand>? areaBands;

  @override
  State<ZyraCompatibilityScoreReader> createState() =>
      _ZyraCompatibilityScoreReaderState();
}

class _ZyraCompatibilityScoreReaderState
    extends State<ZyraCompatibilityScoreReader> {
  // A newly revealed reader always starts on Overall, never a PageStorage page
  // left behind by another reveal. Rebuilding the same reveal keeps its pager.
  // Duplicate only the two end pages. After settling on a duplicate, recenter
  // invisibly on its identical real page, so every wrap travels one page.
  final _pages = PageController(initialPage: 1, keepPage: false);
  int _page = 0;
  int _personRevision = 0;
  bool _recentering = false;

  static const _ink = ZyraColors.espresso;
  static const _muted = ZyraColors.secondaryText;
  static const _pageCount = 2;

  String _name(int index) => index == 0 ? 'Overall' : 'Every area';

  @override
  void didUpdateWidget(covariant ZyraCompatibilityScoreReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personName != widget.personName ||
        oldWidget.overallScore != widget.overallScore ||
        (oldWidget.areaGate == null) != (widget.areaGate == null)) {
      final revision = ++_personRevision;
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || revision != _personRevision || !_pages.hasClients) {
          return;
        }
        _pages.jumpToPage(1);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (!_pages.hasClients) {
      return;
    }
    _recenterLoop();
    final target = _pages.page!.round() + (index - _page);
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      _pages.jumpToPage(target);
    } else {
      _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _recenterLoop() {
    if (_recentering || !_pages.hasClients) return;
    final index = _pages.page!.round();
    final target = index == 0
        ? _pageCount
        : (index == _pageCount + 1 ? 1 : null);
    if (target == null) return;
    // jumpToPage can itself dispatch ScrollEnd before updating the pixels.
    _recentering = true;
    try {
      _pages.jumpToPage(target);
    } finally {
      _recentering = false;
    }
  }

  bool _settleLoop(ScrollEndNotification notification) {
    if (notification.depth == 0) _recenterLoop();
    return false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : (MediaQuery.sizeOf(context).height * .72)
                .clamp(300.0, 760.0)
                .toDouble();
      return SizedBox(
        key: const ValueKey('draft_compatibility_score_reader'),
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ZyraColors.cardSurface, ZyraColors.lowerSurface],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _ink.withValues(alpha: .13)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              children: [
                Expanded(
                  child: NotificationListener<ScrollEndNotification>(
                    onNotification: _settleLoop,
                    child: PageView.builder(
                      key: const ValueKey('draft_compatibility_score_pages'),
                      controller: _pages,
                      itemCount: _pageCount + 2,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _page = (index - 1) % _pageCount),
                      itemBuilder: (context, index) =>
                          _scorePage((index - 1) % _pageCount),
                    ),
                  ),
                ),
                _navigation(),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _navigation() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
    child: Row(
      children: [
        _arrow(previous: true),
        Expanded(
          child: Text(
            '${_page + 1} / $_pageCount',
            key: const ValueKey('draft_compatibility_score_position'),
            semanticsLabel: 'Page ${_page + 1} of $_pageCount: ${_name(_page)}',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 13, color: _ink),
          ),
        ),
        _arrow(previous: false),
      ],
    ),
  );

  Widget _arrow({required bool previous}) {
    return IconButton(
      key: ValueKey(
        'draft_compatibility_score_${previous ? 'previous' : 'next'}',
      ),
      tooltip: previous ? 'Previous page' : 'Next page',
      enableFeedback: false,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: const EdgeInsets.all(12),
      color: ZyraColors.journeyGold,
      onPressed: ZyraTapFeedback.onTap(
        context,
        () => _goTo(_page + (previous ? -1 : 1)),
      ),
      icon: Icon(
        previous ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
        size: 22,
      ),
    );
  }

  Widget _scorePage(int index) {
    if (index == 1) return _areasPage();
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return ZyraShadowScrollView(
      key: const ValueKey('draft_compatibility_score_page_0'),
      primary: false,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Overall',
            key: const ValueKey('draft_compatibility_score_title_0'),
            style: ZyraText.heading(size: 25, color: _ink),
          ),
          SizedBox(height: largeText ? 16 : 24),
          KeyedSubtree(
            key: const ValueKey('draft_compatibility_score_artwork_halo_0'),
            child: _ring(widget.overallScore),
          ),
          const SizedBox(height: 12),
          Text(
            'You and ${widget.personName}',
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 14, color: _muted),
          ),
          const SizedBox(height: 24),
          _guardian(),
        ],
      ),
    );
  }

  Widget _areasPage() => LayoutBuilder(
    builder: (context, constraints) {
      final gate = widget.areaGate;
      // At compact heights, one wrapping label should grow only its own row.
      final shareHeight = constraints.maxHeight >= 540;
      final width = math.max(0.0, constraints.maxWidth - 40);
      final rows = [
        for (final area in ZyraCompatibilityArea.values)
          ZyraCompatibilityAreaRow(
            key: ValueKey(area),
            area: area,
            availableWidth: width,
            band: gate == null
                ? (widget.areaBands?[area] ??
                      ZyraCompatibilityBand.notEnoughAnswers)
                : null,
          ),
      ];
      return SingleChildScrollView(
        key: const ValueKey('draft_compatibility_areas'),
        primary: false,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - 20),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Every area',
                  key: const ValueKey('draft_compatibility_score_title_1'),
                  style: ZyraText.heading(size: 26, color: _ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'How you and ${widget.personName} line up, area by area.',
                  style: ZyraText.subtext(size: 12, color: _muted),
                ),
                const SizedBox(height: 6),
                for (final row in rows)
                  if (shareHeight) Expanded(child: row) else row,
                if (gate != null) _lockedAreaActions(context, gate),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _lockedAreaActions(
    BuildContext context,
    ZyraCompatibilityAreaGate gate,
  ) {
    final hasUnlock = gate.balance > 0;
    final primary = gate.guardian
        ? gate.onUpgrade
        : hasUnlock
        ? gate.onUnlock
        : gate.onBuyMore;
    if (primary == null && gate.onUpgrade == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        ZyraFloatingSurface(
          radius: 999,
          gold: true,
          child: FilledButton(
            key: const ValueKey('draft_compatibility_area_action'),
            onPressed: ZyraTapFeedback.onTap(
              context,
              primary,
              canAct: gate.canAct,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: ZyraColors.goldTextFill,
              foregroundColor: ZyraColors.onPrimaryAction,
              shape: const StadiumBorder(),
            ),
            child: Text(
              gate.guardian
                  ? 'See Guardian One'
                  : hasUnlock
                  ? 'See every area for ${widget.personName}'
                  : 'Get an Unlock for ${widget.personName}',
              textAlign: TextAlign.center,
              style: ZyraText.button(size: 14),
            ),
          ),
        ),
        if (!gate.guardian) ...[
          const SizedBox(height: 7),
          Text(
            hasUnlock
                ? 'Uses 1 Unlock · ${gate.balance} left'
                : '0 Unlocks left',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(
              size: 11.5,
            ).copyWith(height: 1.2, letterSpacing: 0),
          ),
          TextButton(
            key: const ValueKey('draft_compatibility_area_upgrade'),
            onPressed: ZyraTapFeedback.onTap(
              context,
              gate.onUpgrade,
              canAct: gate.canAct,
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Seeker One shows every area in every Journey ›',
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: 13,
                color: ZyraColors.goldText,
              ).copyWith(height: 1.35, letterSpacing: 0),
            ),
          ),
        ],
      ],
    );
  }

  Widget _number(int score) => LayoutBuilder(
    builder: (context, constraints) {
      const size = 60.0;
      var style = DefaultTextStyle.of(context).style
          .merge(ZyraText.heading(size: size, color: ZyraColors.journeyGold))
          .copyWith(height: 1.08, inherit: false);
      if (MediaQuery.boldTextOf(context)) {
        style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
      }
      double widthAt(double fontSize) {
        final measured = TextPainter(
          text: TextSpan(
            text: '$score%',
            style: style.copyWith(fontSize: fontSize),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
        )..layout();
        final width = measured.width;
        measured.dispose();
        return width;
      }

      // Numerical artwork adapts to its own frame, not a whole-page scale.
      // Keep the complete number and percent together, including 100% at 200%.
      var fitted = size;
      if (constraints.hasBoundedWidth && widthAt(size) > constraints.maxWidth) {
        var lower = 0.0;
        var upper = size;
        // Measure every candidate: bold glyphs and nonlinear accessibility
        // scaling must not be approximated by one linear-size ratio.
        for (var attempt = 0; attempt < 18; attempt++) {
          final candidate = (lower + upper) / 2;
          if (widthAt(candidate) <=
              (constraints.maxWidth - .25).clamp(0, double.infinity)) {
            lower = candidate;
          } else {
            upper = candidate;
          }
        }
        fitted = lower;
      }
      return Text(
        '$score%',
        key: const ValueKey('draft_compatibility_overall_score'),
        semanticsLabel:
            'Score preview: Overall with ${widget.personName}, $score percent aligned. Not a real profile result.',
        softWrap: false,
        textAlign: TextAlign.center,
        style: style.copyWith(fontSize: fitted),
      );
    },
  );

  Widget _ring(int score) => LayoutBuilder(
    builder: (context, constraints) {
      final diameter = math.min(248.0, constraints.maxWidth);
      final style = ZyraText.heading(
        size: 60,
        color: ZyraColors.journeyGold,
      ).copyWith(height: 1.08);
      final painter = TextPainter(
        text: TextSpan(text: '$score%', style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
      )..layout();
      final centered =
          painter.width <= diameter - 76 && painter.height <= diameter - 76;
      painter.dispose();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ZyraColors.journeyGold.withValues(alpha: .085),
                    blurRadius: 34,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: CustomPaint(painter: _OverallRing(score)),
                    ),
                  ),
                  if (centered)
                    SizedBox(width: diameter - 76, child: _number(score))
                  else
                    Icon(
                      Icons.balance_rounded,
                      color: ZyraColors.journeyGold.withValues(alpha: .65),
                      size: 34,
                    ),
                ],
              ),
            ),
          ),
          if (!centered) ...[const SizedBox(height: 18), _number(score)],
        ],
      );
    },
  );

  Widget _guardian() => Container(
    key: const ValueKey('draft_compatibility_guardian'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _ink.withValues(alpha: .035),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _ink.withValues(alpha: .10)),
    ),
    child: Column(
      key: const ValueKey('draft_compatibility_guardian_result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Demo Guardian · Father',
          style: ZyraText.body(size: 13, color: _ink),
        ),
        const SizedBox(height: 5),
        Text(
          'Main Guardian',
          style: ZyraText.subtext(size: 11.5, color: _muted),
        ),
      ],
    ),
  );
}

/// Paints only the supplied Overall result.
class _OverallRing extends CustomPainter {
  const _OverallRing(this.score);

  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(1.0, math.min(size.width, size.height) / 2 - 16);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..color = ZyraColors.warmOverlay.withValues(alpha: .075);
    canvas.drawCircle(center, radius, paint);
    paint.color = ZyraColors.journeyGold;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * score / 100, false, paint);
  }

  @override
  bool shouldRepaint(covariant _OverallRing oldDelegate) =>
      oldDelegate.score != score;
}
