import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_compatibility_demo.dart';

/// Presentation only, mounted by the protected caller after its local reveal.
///
/// The supplied overall value and six existing demo tuples are display fixtures.
/// This reader never scores answers, loads a person, spends an unlock, grants
/// access, persists data or owns route navigation. Its only state is pagination.
class ZyraCompatibilityScoreReader extends StatefulWidget {
  const ZyraCompatibilityScoreReader({
    super.key,
    required this.personName,
    required this.overallScore,
  }) : assert(overallScore >= 0 && overallScore <= 100);

  final String personName;
  final int overallScore;

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
  static const _discuss = ZyraColors.journeyGold;
  static const _opposed = ZyraColors.mutedText;
  static final _pageCount = 1 + ZyraCompatibilityDemo.categories.length;

  String _name(int index) =>
      index == 0 ? 'Overall' : ZyraCompatibilityDemo.categories[index - 1].name;

  @override
  void didUpdateWidget(covariant ZyraCompatibilityScoreReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personName != widget.personName ||
        oldWidget.overallScore != widget.overallScore) {
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
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final category = index == 0
        ? null
        : ZyraCompatibilityDemo.categories[index - 1];
    final score = category?.aligned ?? widget.overallScore;
    return ZyraShadowScrollView(
      key: ValueKey('draft_compatibility_score_page_$index'),
      primary: false,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _name(index),
            key: ValueKey('draft_compatibility_score_title_$index'),
            style: ZyraText.heading(size: 25, color: _ink),
          ),
          SizedBox(height: largeText ? 16 : 24),
          KeyedSubtree(
            key: ValueKey('draft_compatibility_score_artwork_halo_$index'),
            child: _artwork(index, score, category),
          ),
          if (category == null) ...[const SizedBox(height: 24), _guardian()],
        ],
      ),
    );
  }

  Widget _artwork(
    int index,
    int score,
    ZyraCompatibilityDemoCategory? category,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ring(index, score, category),
      const SizedBox(height: 12),
      Center(child: _aligned()),
      if (category != null) ...[
        const SizedBox(height: 24),
        _metrics(index, category),
      ],
    ],
  );

  Widget _number(int index, int score) => LayoutBuilder(
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
        key: index == 0
            ? const ValueKey('draft_compatibility_overall_score')
            : ValueKey('draft_compatibility_category_score_$index'),
        semanticsLabel:
            'Score preview: ${_name(index)} with ${widget.personName}, $score percent aligned. Not a real profile result.',
        softWrap: false,
        textAlign: TextAlign.center,
        style: style.copyWith(fontSize: fitted),
      );
    },
  );

  Widget _aligned() =>
      Text('Aligned', style: ZyraText.body(size: 14, color: _muted));

  List<(String, int, Color)> _values(ZyraCompatibilityDemoCategory category) =>
      [
        ('Aligned', category.aligned, ZyraColors.journeyGold),
        ('Discuss', category.discuss, _discuss),
        ('Opposed', category.opposed, _opposed),
      ];

  Widget _metrics(int index, ZyraCompatibilityDemoCategory category) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final metric in _values(category)) ...[
        _metric(index, metric.$1, metric.$2, metric.$3),
        const SizedBox(height: 14),
      ],
    ],
  );

  Widget _metric(int index, String label, int value, Color color) => Semantics(
    label: 'Score preview: $label $value percent. Not a real profile result.',
    child: ExcludeSemantics(
      child: Container(
        key: ValueKey(
          'draft_compatibility_metric_${index}_${label.toLowerCase()}',
        ),
        width: double.infinity,
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 2)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 14,
          runSpacing: 4,
          children: [
            Text(label, style: ZyraText.body(size: 15, color: _ink)),
            Text(
              '$value%',
              style: ZyraText.body(
                size: 15,
                color: color == ZyraColors.journeyGold
                    ? ZyraColors.goldText
                    : color,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _ring(
    int index,
    int score,
    ZyraCompatibilityDemoCategory? category,
  ) => LayoutBuilder(
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
                      child: CustomPaint(
                        painter: _DemoRings(
                          values: category == null
                              ? [score]
                              : [
                                  category.aligned,
                                  category.discuss,
                                  category.opposed,
                                ],
                          colors: const [
                            ZyraColors.journeyGold,
                            _discuss,
                            _opposed,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (centered)
                    SizedBox(width: diameter - 76, child: _number(index, score))
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
          if (!centered) ...[const SizedBox(height: 18), _number(index, score)],
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

/// Paints the supplied display percentages only; it computes no compatibility.
class _DemoRings extends CustomPainter {
  const _DemoRings({required this.values, required this.colors});
  final List<int> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13;
    final ringRadius = math.max(1.0, radius);
    final rect = Rect.fromCircle(center: center, radius: ringRadius);
    paint.color = ZyraColors.warmOverlay.withValues(alpha: .075);
    canvas.drawCircle(center, ringRadius, paint);
    var start = -math.pi / 2;
    for (var value = 0; value < values.length; value++) {
      paint.color = colors[value];
      final sweep = math.pi * 2 * values[value] / 100;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DemoRings oldDelegate) =>
      oldDelegate.values.length != values.length ||
      oldDelegate.values.indexed.any((entry) => entry.$2 != values[entry.$1]);
}
