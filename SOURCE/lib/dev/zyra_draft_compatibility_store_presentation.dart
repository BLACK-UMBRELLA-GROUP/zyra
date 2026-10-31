import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';

/// LOCK 22 V1 Unlocks catalogue. Balance is read-only and the eight illustrated
/// examples remain local presentation data; selecting a pack is not payment.
class ZyraDraftCompatibilityStorePresentation extends StatefulWidget {
  const ZyraDraftCompatibilityStorePresentation({
    super.key,
    this.balance,
    this.isSeekerOne = false,
    this.canAct,
    this.onTerms,
    this.storePlatform = TargetPlatform.iOS,
  }) : assert(balance == null || balance >= 0);

  final int? balance;
  final bool isSeekerOne;
  final bool Function()? canAct;
  final VoidCallback? onTerms;
  final TargetPlatform storePlatform;

  @override
  State<ZyraDraftCompatibilityStorePresentation> createState() =>
      _ZyraDraftCompatibilityStorePresentationState();
}

class _ZyraDraftCompatibilityStorePresentationState
    extends State<ZyraDraftCompatibilityStorePresentation> {
  String _selected = 'unlock_three';
  int _revision = 0;
  int _previewPage = 0;

  @override
  void didUpdateWidget(ZyraDraftCompatibilityStorePresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revision++;
  }

  bool _current(int revision) =>
      mounted &&
      revision == _revision &&
      (ModalRoute.of(context)?.isCurrent ?? false) &&
      (widget.canAct?.call() ?? true);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      final balance = widget.balance ?? 0;
      final balanceLabel = balance == 1 ? 'Unlock left' : 'Unlocks left';
      final membershipLine = widget.isSeekerOne
          ? '3 MORE EACH MONTH WITH SEEKER ONE'
          : 'SEEKER ONE INCLUDES 3 EACH MONTH';
      final ringSize = _balanceDiameter(balance, width, scaler, direction);
      final rail = (width - 16) / 3 < scaler.scale(78);
      final cardWidth = rail
          ? _preferredCardWidth(scaler, direction)
          : (width - 16) / 3;
      final cardHeight = _cardHeight(cardWidth, scaler, direction);
      final pagerHeight = _previewHeight(
        width,
        scaler,
        direction,
        _previewPage,
      );
      final headHeight = widget.balance == null
          ? 0.0
          : ringSize +
                14 +
                _textSize(
                  balanceLabel,
                  _headStyle,
                  scaler,
                  direction,
                  width,
                ).height +
                8 +
                _textSize(
                  membershipLine,
                  _capsStyle,
                  scaler,
                  direction,
                  width,
                ).height +
                22;
      final groupHeight = headHeight + pagerHeight + 16 + cardHeight;
      final titleHeight = _textSize(
        'Compatibility Unlocks',
        _pageTitleStyle,
        scaler,
        direction,
        width,
      ).height;
      final footerHeight = _footerHeight(width, scaler, direction);
      final fits =
          constraints.hasBoundedHeight &&
          constraints.maxHeight >=
              titleHeight + 48 + groupHeight + footerHeight;
      final group = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.balance != null) ...[
            _BalanceHead(
              balance: balance,
              diameter: ringSize,
              label: balanceLabel,
              membershipLine: membershipLine,
            ),
            const SizedBox(height: 22),
          ],
          SizedBox(
            height: pagerHeight,
            child: _ScorePreviewPager(
              canAct: widget.canAct,
              onPageChanged: (page) {
                if (!mounted) return;
                setState(() => _previewPage = page);
              },
            ),
          ),
          const SizedBox(height: 16),
          _offerChoices(rail, cardWidth, cardHeight),
        ],
      );
      return ZyraShadowScrollView(
        key: const ValueKey('draft_compatibility_store_viewport'),
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: fits ? constraints.maxHeight : null,
          child: Column(
            key: const ValueKey('draft_compatibility_store_presentation'),
            mainAxisSize: fits ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Compatibility Unlocks',
                  key: const ValueKey('draft_compatibility_store_title'),
                  style: _pageTitleStyle,
                ),
              ),
              if (fits)
                Expanded(child: Center(child: group))
              else ...[
                const SizedBox(height: 32),
                group,
                const SizedBox(height: 32),
              ],
              _footer(),
            ],
          ),
        ),
      );
    },
  );

  Widget _offerChoices(bool rail, double width, double height) {
    final revision = _revision;
    Widget choice(_StoreOffer offer) => _SelectableOffer(
      offer: offer,
      selected: _selected == offer.id,
      canAct: () => _current(revision),
      onSelect: () {
        if (!_current(revision)) return;
        setState(() {
          _selected = offer.id;
          _revision++;
        });
      },
    );
    if (rail) {
      return ZyraShadowScrollView(
        key: const ValueKey('draft_compatibility_store_packs_rail'),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _offers.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              SizedBox(width: width, height: height, child: choice(_offers[i])),
            ],
          ],
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _offers.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: choice(_offers[i])),
          ],
        ],
      ),
    );
  }

  Widget _footer() {
    final revision = _revision;
    final terms = widget.onTerms;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ZyraFloatingSurface(
          radius: 999,
          gold: true,
          child: FilledButton(
            key: const ValueKey('draft_compatibility_store_continue'),
            // The approved draft has no checkout authority. Keep this disabled;
            // choosing a pack never debits the balance or grants an Unlock.
            onPressed: null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(44, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              disabledForegroundColor: ZyraColors.onPrimaryAction,
              disabledBackgroundColor: ZyraColors.goldTextFill,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Continue',
              textAlign: TextAlign.center,
              style: _buttonBody(
                size: 14,
              ).copyWith(color: ZyraColors.onPrimaryAction),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              key: const ValueKey('draft_compatibility_store_terms'),
              onPressed: ZyraTapFeedback.onTap(
                context,
                terms,
                canAct: () => _current(revision),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                foregroundColor: ZyraColors.foregroundMuted,
                disabledForegroundColor: ZyraColors.foregroundMuted,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Purchase terms', style: _muted(size: 12)),
            ),
            Text(
              ' · Purchasing isn’t available yet',
              key: const ValueKey('draft_compatibility_store_unavailable'),
              textAlign: TextAlign.center,
              style: _muted(size: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceHead extends StatelessWidget {
  const _BalanceHead({
    required this.balance,
    required this.diameter,
    required this.label,
    required this.membershipLine,
  });
  final int balance;
  final double diameter;
  final String label;
  final String membershipLine;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Container(
          key: const ValueKey('draft_compatibility_store_balance'),
          width: diameter,
          height: diameter,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ZyraColors.journeyGold.withValues(alpha: .70),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '$balance',
              key: const ValueKey('draft_compatibility_store_balance_count'),
              textAlign: TextAlign.center,
              style: _balanceCountStyle,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        label,
        key: const ValueKey('draft_compatibility_store_balance_label'),
        textAlign: TextAlign.center,
        style: _headStyle,
      ),
      const SizedBox(height: 8),
      Text(
        membershipLine,
        key: const ValueKey('draft_compatibility_store_membership_line'),
        textAlign: TextAlign.center,
        style: _capsStyle,
      ),
    ],
  );
}

class _ScorePreviewPager extends StatefulWidget {
  const _ScorePreviewPager({this.canAct, required this.onPageChanged});
  final bool Function()? canAct;
  final ValueChanged<int> onPageChanged;

  @override
  State<_ScorePreviewPager> createState() => _ScorePreviewPagerState();
}

class _ScorePreviewPagerState extends State<_ScorePreviewPager> {
  final _pages = PageController(keepPage: false);
  int _page = 0;
  int _revision = 0;
  static final _pageCount = 1 + _fictionalScores.length;

  @override
  void didUpdateWidget(_ScorePreviewPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revision++;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _current(int revision) =>
      mounted &&
      revision == _revision &&
      (ModalRoute.of(context)?.isCurrent ?? false) &&
      (widget.canAct?.call() ?? true);

  void _goTo(int page) {
    if (!_pages.hasClients || page < 0 || page >= _pageCount) return;
    _revision++;
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _arrow({required bool previous}) {
    final revision = _revision;
    final target = _page + (previous ? -1 : 1);
    return IconButton(
      key: ValueKey(
        'draft_compatibility_store_preview_${previous ? 'previous' : 'next'}',
      ),
      tooltip: previous ? 'Previous preview page' : 'Next preview page',
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: const EdgeInsets.all(10),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      color: ZyraColors.goldText,
      disabledColor: ZyraColors.goldText,
      onPressed: ZyraTapFeedback.onTap(
        context,
        target >= 0 && target < _pageCount ? () => _goTo(target) : null,
        canAct: () => _current(revision),
      ),
      icon: Icon(
        previous ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        size: 20,
      ),
    );
  }

  Widget _navigation() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _arrow(previous: true),
      Text(
        '${_page + 1} / $_pageCount',
        key: const ValueKey('draft_compatibility_store_preview_position'),
        semanticsLabel: _page == 0
            ? 'Score preview page 1 of $_pageCount: Locked score. '
                  'Swipe left or right to see the illustrated design.'
            : 'Score preview page ${_page + 1} of $_pageCount: '
                  '${_fictionalScores[_page - 1].title}. Not a real profile result.',
        textAlign: TextAlign.center,
        style: _muted(size: 12),
      ),
      _arrow(previous: false),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = _stackPreview(
        constraints.maxWidth,
        MediaQuery.textScalerOf(context),
      );
      final pages = PageView.builder(
        key: const ValueKey('draft_compatibility_store_preview_pages'),
        controller: _pages,
        physics: const ClampingScrollPhysics(),
        itemCount: _pageCount,
        onPageChanged: (page) {
          if (!mounted ||
              !(ModalRoute.of(context)?.isCurrent ?? false) ||
              !(widget.canAct?.call() ?? true)) {
            return;
          }
          setState(() {
            _page = page;
            _revision++;
          });
          widget.onPageChanged(page);
        },
        // PageView also lays out the adjacent example while its viewport still
        // has the current row's height. Let that offscreen item take its own
        // reading height; onPageChanged grows the visible card to that height.
        itemBuilder: (context, page) => OverflowBox(
          minHeight: 0,
          maxHeight: double.infinity,
          alignment: Alignment.center,
          child: page == 0
              ? _PreviewRow(
                  key: const ValueKey(
                    'draft_compatibility_store_preview_locked',
                  ),
                  icon: Icons.lock_outline_rounded,
                  title: 'Your match, revealed',
                  subtitle: 'One profile. Every score.',
                  semanticsLabel:
                      'Locked compatibility score preview. No scores or Guardian information are loaded.',
                )
              : _FictionalScorePreview(
                  sample: _fictionalScores[page - 1],
                  page: page,
                ),
        ),
      );
      return ZyraFloatingSurface(
        radius: 20,
        child: Container(
          key: const ValueKey('draft_compatibility_store_preview'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: ZyraColors.surfaceFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: pages),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _navigation(),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: pages),
                    const SizedBox(width: 6),
                    _navigation(),
                  ],
                ),
        ),
      );
    },
  );
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    this.page,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticsLabel;
  final int? page;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    child: ExcludeSemantics(
      child: Row(
        children: [
          Icon(icon, size: 20, color: ZyraColors.journeyGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  key: page == null
                      ? null
                      : ValueKey(
                          'draft_compatibility_store_example_title_$page',
                        ),
                  style: _body(size: 14),
                ),
                Text(
                  subtitle,
                  key: page == null
                      ? null
                      : ValueKey(
                          'draft_compatibility_store_example_score_$page',
                        ),
                  style: _muted(size: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Invented examples describe the included design, never a real profile.
class _FictionalScore {
  const _FictionalScore({
    required this.title,
    required this.aligned,
    this.discuss,
    this.opposed,
  });
  final String title;
  final int aligned;
  final int? discuss;
  final int? opposed;

  String get subtitle =>
      '$aligned% Aligned'
      '${discuss == null ? '' : ' · Discuss $discuss% · Opposed $opposed%'}';
}

const _fictionalScores = [
  _FictionalScore(title: 'Overall', aligned: 79),
  _FictionalScore(title: 'Lifestyle', aligned: 72, discuss: 18, opposed: 10),
  _FictionalScore(
    title: 'Work & Education',
    aligned: 84,
    discuss: 10,
    opposed: 6,
  ),
  _FictionalScore(title: 'Family Values', aligned: 88, discuss: 8, opposed: 4),
  _FictionalScore(
    title: 'Marriage Goals',
    aligned: 81,
    discuss: 13,
    opposed: 6,
  ),
  _FictionalScore(title: 'Personality', aligned: 76, discuss: 16, opposed: 8),
  _FictionalScore(title: 'Deen', aligned: 90, discuss: 7, opposed: 3),
];

class _FictionalScorePreview extends StatelessWidget {
  const _FictionalScorePreview({required this.sample, required this.page});
  final _FictionalScore sample;
  final int page;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('draft_compatibility_store_example_$page'),
    child: _PreviewRow(
      icon: Icons.insights_outlined,
      title: sample.title,
      subtitle: sample.subtitle,
      page: page,
      semanticsLabel:
          'Score preview. ${sample.title}: '
          '${sample.aligned} percent aligned. '
          '${sample.discuss == null ? '' : '${sample.discuss} percent discuss, ${sample.opposed} percent opposed. '}'
          'Not a real profile result.',
    ),
  );
}

class _StoreOffer {
  const _StoreOffer({
    required this.id,
    required this.count,
    required this.pricePence,
    required this.unitLine,
  });
  final String id;
  final int count;
  final int pricePence;
  final String unitLine;
  String get quantity => '$count ${count == 1 ? 'Unlock' : 'Unlocks'}';
}

const _offers = [
  _StoreOffer(
    id: 'unlock_single',
    count: 1,
    pricePence: ZyraMembershipCatalog.compatibilitySinglePence,
    unitLine: 'For one profile',
  ),
  _StoreOffer(
    id: 'unlock_three',
    count: 3,
    pricePence: ZyraMembershipCatalog.compatibilityThreePence,
    unitLine: '£2.33 each',
  ),
  _StoreOffer(
    id: 'unlock_five',
    count: 5,
    pricePence: ZyraMembershipCatalog.compatibilityFivePence,
    unitLine: '£2.00 each',
  ),
];

class _SelectableOffer extends StatelessWidget {
  const _SelectableOffer({
    required this.offer,
    required this.selected,
    required this.canAct,
    required this.onSelect,
  });
  final _StoreOffer offer;
  final bool selected;
  final bool Function() canAct;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('draft_compatibility_store_${offer.id}_selection'),
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    onTap: ZyraTapFeedback.onTap(context, onSelect, canAct: canAct),
    label: [
      offer.quantity,
      ZyraMembershipCatalog.pounds(offer.pricePence),
      offer.unitLine,
    ].join(', '),
    child: ExcludeSemantics(
      child: ZyraFloatingSurface(
        radius: 16,
        child: OutlinedButton(
          key: ValueKey('draft_compatibility_store_${offer.id}'),
          onPressed: ZyraTapFeedback.onTap(context, onSelect, canAct: canAct),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 92),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            foregroundColor: ZyraColors.foreground,
            backgroundColor: selected
                ? Color.alphaBlend(
                    ZyraColors.journeyGold.withValues(alpha: .12),
                    const Color(0xFFFAF5EC),
                  )
                : ZyraColors.surfaceFill,
            side: BorderSide(
              color: selected
                  ? ZyraColors.journeyGold
                  : ZyraColors.surfaceBorder,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                offer.quantity,
                textAlign: TextAlign.center,
                style: _muted(
                  size: 13,
                ).copyWith(color: selected ? ZyraColors.goldText : null),
              ),
              const SizedBox(height: 4),
              Text(
                ZyraMembershipCatalog.pounds(offer.pricePence),
                textAlign: TextAlign.center,
                style: _priceStyle,
              ),
              const SizedBox(height: 4),
              Text(
                offer.unitLine,
                textAlign: TextAlign.center,
                style: _muted(size: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Size _textSize(
  String text,
  TextStyle style,
  TextScaler scaler,
  TextDirection direction,
  double maxWidth,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    textScaler: scaler,
  )..layout(maxWidth: maxWidth.clamp(1, double.infinity).toDouble());
  final size = painter.size;
  painter.dispose();
  return size;
}

double _balanceDiameter(
  int balance,
  double width,
  TextScaler scaler,
  TextDirection direction,
) {
  final number = _textSize(
    '$balance',
    _balanceCountStyle,
    scaler,
    direction,
    width - 26,
  );
  return (number.longestSide + 26).clamp(96, width).toDouble();
}

double _preferredCardWidth(TextScaler scaler, TextDirection direction) {
  var width = 96.0;
  for (final offer in _offers) {
    for (final (text, style) in [
      (offer.quantity, _muted(size: 13)),
      (ZyraMembershipCatalog.pounds(offer.pricePence), _priceStyle),
      (offer.unitLine, _muted(size: 11)),
    ]) {
      final candidate =
          _textSize(text, style, scaler, direction, double.infinity).width + 20;
      if (candidate > width) width = candidate;
    }
  }
  return width;
}

double _cardHeight(double width, TextScaler scaler, TextDirection direction) {
  var height = 92.0;
  for (final offer in _offers) {
    final candidate =
        _textSize(
          offer.quantity,
          _muted(size: 13),
          scaler,
          direction,
          width - 14,
        ).height +
        _textSize(
          ZyraMembershipCatalog.pounds(offer.pricePence),
          _priceStyle,
          scaler,
          direction,
          width - 14,
        ).height +
        _textSize(
          offer.unitLine,
          _muted(size: 11),
          scaler,
          direction,
          width - 14,
        ).height +
        34;
    if (candidate > height) height = candidate;
  }
  return height;
}

bool _stackPreview(double width, TextScaler scaler) =>
    width < 340 || scaler.scale(14) > 18;

double _previewHeight(
  double width,
  TextScaler scaler,
  TextDirection direction,
  int page,
) {
  final stacked = _stackPreview(width, scaler);
  final counterWidth = _textSize(
    '8 / 8',
    _muted(size: 12),
    scaler,
    direction,
    double.infinity,
  ).width;
  final textWidth = width - 34 - 32 - (stacked ? 0 : counterWidth + 94);
  final title = page == 0
      ? 'Your match, revealed'
      : _fictionalScores[page - 1].title;
  final subtitle = page == 0
      ? 'One profile. Every score.'
      : _fictionalScores[page - 1].subtitle;
  final textHeight =
      _textSize(title, _body(size: 14), scaler, direction, textWidth).height +
      _textSize(
        subtitle,
        _muted(size: 12.5),
        scaler,
        direction,
        textWidth,
      ).height;
  final navigationHeight = _textSize(
    '8 / 8',
    _muted(size: 12),
    scaler,
    direction,
    double.infinity,
  ).height.clamp(44, double.infinity).toDouble();
  return 22 +
      (stacked
          ? textHeight + 4 + navigationHeight
          : textHeight.clamp(navigationHeight, double.infinity));
}

double _footerHeight(double width, TextScaler scaler, TextDirection direction) {
  final button =
      (_textSize(
                'Continue',
                _buttonBody(size: 14),
                scaler,
                direction,
                width - 32,
              ).height +
              20)
          .clamp(48, double.infinity)
          .toDouble();
  final terms = _textSize(
    'Purchase terms',
    _muted(size: 12),
    scaler,
    direction,
    width,
  );
  final notice = _textSize(
    ' · Purchasing isn’t available yet',
    _muted(size: 12),
    scaler,
    direction,
    width,
  );
  final termsHeight = (terms.height + 16).clamp(44, double.infinity).toDouble();
  return button +
      6 +
      (terms.width + notice.width <= width
          ? termsHeight.clamp(notice.height, double.infinity)
          : termsHeight + notice.height);
}

TextStyle _body({required double size}) =>
    ZyraText.body(size: size, color: ZyraColors.foreground).copyWith(
      height: 1.4,
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
    );
TextStyle _muted({required double size}) =>
    _body(size: size).copyWith(color: ZyraColors.foregroundMuted);
TextStyle _buttonBody({required double size}) =>
    ZyraText.button(size: size, color: ZyraColors.foreground).copyWith(
      height: 1.4,
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
    );
TextStyle get _pageTitleStyle =>
    ZyraText.heading(size: 28).copyWith(height: 1.2);
TextStyle get _headStyle => ZyraText.heading(size: 26).copyWith(height: 1.2);
TextStyle get _capsStyle =>
    _body(size: 11).copyWith(color: ZyraColors.goldText, letterSpacing: 1.2);
TextStyle get _balanceCountStyle => ZyraText.heading(
  size: 40,
  color: ZyraColors.journeyGold,
).copyWith(height: 1.1);
TextStyle get _priceStyle => ZyraText.heading(size: 20).copyWith(height: 1.2);
