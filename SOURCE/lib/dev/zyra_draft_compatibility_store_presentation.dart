import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// Halo focus is the shared Unlocks catalogue, not purchase authority.
/// Pack selection and a fictional-example pager are local presentation state.
/// Balance is confirmed and read-only; no real score, Guardian, spending or
/// checkout callback can enter this widget.
class ZyraDraftCompatibilityStorePresentation extends StatefulWidget {
  const ZyraDraftCompatibilityStorePresentation({
    super.key,
    this.balance,
    this.onTerms,
    this.storePlatform = TargetPlatform.iOS,
  }) : assert(balance == null || balance >= 0);

  final int? balance;
  final VoidCallback? onTerms;
  final TargetPlatform storePlatform;

  @override
  State<ZyraDraftCompatibilityStorePresentation> createState() =>
      _ZyraDraftCompatibilityStorePresentationState();
}

class _ZyraDraftCompatibilityStorePresentationState
    extends State<ZyraDraftCompatibilityStorePresentation> {
  String? _selected;

  _StoreOffer? get _selectedOffer {
    for (final offer in _offers) {
      if (offer.id == _selected) return offer;
    }
    return null;
  }

  String get _refundTerms =>
      'One-off purchase. Refunds are subject to '
      '${widget.storePlatform == TargetPlatform.android ? 'Google Play’s' : 'Apple’s'} '
      'terms and applicable law';

  void _showInformation() {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const ValueKey('draft_compatibility_store_info_dialog'),
        backgroundColor: _dialogSurface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: _accent),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Every unlock includes',
                        style: _body(size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey('draft_compatibility_store_info_close'),
                    onPressed: () {
                      if (!dialogContext.mounted ||
                          !(ModalRoute.of(dialogContext)?.isCurrent ?? false)) {
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                    },
                    tooltip: 'Close',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: Icon(Icons.close_rounded, color: _accent),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey(
                    'draft_compatibility_store_info_viewport',
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Benefit(
                        icon: Icons.insights_outlined,
                        label: 'See your overall match score',
                      ),
                      const SizedBox(height: 14),
                      const _Benefit(
                        icon: Icons.subject_outlined,
                        label:
                            'See how you match on faith, family and lifestyle',
                      ),
                      const SizedBox(height: 14),
                      const _Benefit(
                        icon: Icons.groups_outlined,
                        label: 'See who their Guardian is, where available',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _lifetime,
                        key: const ValueKey(
                          'draft_compatibility_store_lifetime',
                        ),
                        style: _body(size: 13),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _refundTerms,
                        key: const ValueKey(
                          'draft_compatibility_store_refund_terms',
                        ),
                        style: _body(size: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      final titleStyle =
          ZyraText.heading(size: width < scaler.scale(220) ? 20 : 26).copyWith(
            height: 1.2,
            leadingDistribution: TextLeadingDistribution.even,
            textBaseline: TextBaseline.alphabetic,
            letterSpacing: .25,
          );
      final wordWidth = _textSize(
        'Compatibility',
        titleStyle,
        scaler,
        direction,
        double.infinity,
      ).width;
      // Enlarged text gives info its own row instead of splitting the word.
      final stackedHeader = wordWidth > width - 52;
      final titleWidth = stackedHeader
          ? width
          : (width - 52).clamp(0, 260).toDouble();
      final titleHeight = _textSize(
        'Compatibility Unlocks',
        titleStyle,
        scaler,
        direction,
        titleWidth,
      ).height;
      final headerHeight = stackedHeader
          ? titleHeight + 44
          : titleHeight.clamp(44, double.infinity).toDouble();
      final hasBalance = (widget.balance ?? 0) > 0;
      final balanceHeight = hasBalance
          ? _balanceHeight(widget.balance!, scaler, direction, width)
          : 0.0;
      final equalCardWidth = (width - 16) / 3;
      final rail = equalCardWidth < scaler.scale(78);
      final cardWidth = rail
          ? _preferredCardWidth(scaler, direction)
          : equalCardWidth;
      final cardHeight = _cardHeight(cardWidth, scaler, direction);
      final continueHeight = _continueHeight(
        _selectedOffer,
        scaler,
        direction,
        width,
      );
      final termsHeight =
          (_textSize(
                    'Purchase terms',
                    _buttonBody(size: 12),
                    scaler,
                    direction,
                    width - 8,
                  ).height +
                  16)
              .clamp(44, double.infinity)
              .toDouble();
      final noticeHeight = _textSize(
        'Purchasing isn’t available yet.',
        _body(size: 11),
        scaler,
        direction,
        width,
      ).height;
      final fixedHeight =
          headerHeight +
          (hasBalance ? 10 + balanceHeight : 0) +
          36 +
          cardHeight +
          continueHeight +
          4 +
          termsHeight +
          noticeHeight;
      final heroHeight = _heroHeight(width, scaler, direction);
      final fillHeight =
          constraints.hasBoundedHeight &&
          constraints.maxHeight >= fixedHeight + heroHeight;
      final hero = _ScorePreviewPager(
        onInformation: _showInformation,
        ringSize: _previewRingSize(width, scaler, direction),
      );
      final title = Semantics(
        header: true,
        child: SizedBox(
          width: titleWidth,
          child: Text(
            'Compatibility Unlocks',
            key: const ValueKey('draft_compatibility_store_title'),
            textAlign: TextAlign.left,
            style: titleStyle,
          ),
        ),
      );
      final information = IconButton(
        key: const ValueKey('draft_compatibility_store_info'),
        onPressed: _showInformation,
        tooltip: 'What an unlock includes',
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: Icon(Icons.info_outline_rounded, color: _accent, size: 20),
      );
      return SingleChildScrollView(
        key: const ValueKey('draft_compatibility_store_viewport'),
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: fillHeight ? constraints.maxHeight : null,
          child: Column(
            key: const ValueKey('draft_compatibility_store_presentation'),
            mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stackedHeader)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerRight, child: information),
                    title,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: title,
                      ),
                    ),
                    const SizedBox(width: 8),
                    information,
                  ],
                ),
              if (hasBalance) ...[
                const SizedBox(height: 10),
                _BalanceStrip(balance: widget.balance!),
              ],
              const SizedBox(height: 12),
              if (fillHeight)
                Expanded(child: hero)
              else
                SizedBox(height: heroHeight, child: hero),
              const SizedBox(height: 12),
              _offerChoices(rail, cardWidth, cardHeight),
              const SizedBox(height: 12),
              _footer(),
            ],
          ),
        ),
      );
    },
  );

  Widget _offerChoices(bool rail, double width, double height) {
    Widget choice(_StoreOffer offer) => _SelectableOffer(
      offer: offer,
      selected: _selected == offer.id,
      onSelect: () {
        if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
        setState(() => _selected = offer.id);
      },
    );
    if (rail) {
      return SingleChildScrollView(
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
    final selected = _selectedOffer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const ValueKey('draft_compatibility_store_continue'),
          // Selecting is not payment. StoreKit/receipt authority is not live;
          // do not debit a balance or simulate a completed purchase here.
          onPressed: null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            disabledForegroundColor: _accent,
            disabledBackgroundColor: _accent.withValues(alpha: .05),
            side: BorderSide(color: _accent.withValues(alpha: .65)),
            shape: const StadiumBorder(),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected == null
                    ? 'Continue'
                    : 'Continue · ${ZyraMembershipCatalog.pounds(selected.pricePence)}',
                textAlign: TextAlign.center,
                style: _buttonBody(size: 14).copyWith(color: _accent),
              ),
              if (selected?.saving != null) ...[
                const SizedBox(height: 2),
                Text(
                  selected!.saving!,
                  textAlign: TextAlign.center,
                  style: _buttonBody(size: 11),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          key: const ValueKey('draft_compatibility_store_terms'),
          onPressed: widget.onTerms,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            foregroundColor: _ink,
            disabledForegroundColor: _ink,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Purchase terms',
            textAlign: TextAlign.center,
            style: _buttonBody(size: 12).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: _ink,
            ),
          ),
        ),
        Text(
          'Purchasing isn’t available yet.',
          key: const ValueKey('draft_compatibility_store_unavailable'),
          textAlign: TextAlign.center,
          style: _body(size: 11),
        ),
      ],
    );
  }
}

class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('draft_compatibility_store_balance'),
    label: 'Unlocks remaining: $balance',
    child: ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          border: Border.all(color: ZyraColors.surfaceBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final label = Text(
              'Unlocks remaining',
              key: const ValueKey('draft_compatibility_store_balance_label'),
              style: _body(size: 14),
            );
            final count = Container(
              key: const ValueKey('draft_compatibility_store_balance_capsule'),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ZyraColors.modalSheetSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withValues(alpha: .70)),
              ),
              child: Text(
                '$balance',
                key: const ValueKey('draft_compatibility_store_balance_count'),
                textAlign: TextAlign.center,
                style: _balanceCountStyle,
              ),
            );
            if (_balanceNeedsStack(
              balance,
              MediaQuery.textScalerOf(context),
              Directionality.of(context),
              constraints.maxWidth,
            )) {
              return Column(
                key: const ValueKey(
                  'draft_compatibility_store_balance_stacked',
                ),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label,
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerRight, child: count),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: label),
                const SizedBox(width: 16),
                count,
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _ScorePreviewPager extends StatefulWidget {
  const _ScorePreviewPager({
    required this.onInformation,
    required this.ringSize,
  });
  final VoidCallback onInformation;
  final double ringSize;

  @override
  State<_ScorePreviewPager> createState() => _ScorePreviewPagerState();
}

class _ScorePreviewPagerState extends State<_ScorePreviewPager> {
  final _pages = PageController(keepPage: false);
  int _page = 0;

  static final _pageCount = 1 + _fictionalScores.length;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (!mounted ||
        !(ModalRoute.of(context)?.isCurrent ?? false) ||
        !_pages.hasClients ||
        page < 0 ||
        page >= _pageCount) {
      return;
    }
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

  Widget _arrow({required bool previous}) => IconButton(
    key: ValueKey(
      'draft_compatibility_store_preview_${previous ? 'previous' : 'next'}',
    ),
    tooltip: previous ? 'Previous preview page' : 'Next preview page',
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    padding: const EdgeInsets.all(10),
    // Keep the complete hit target at the same 44px reserved by _heroHeight.
    // Material's padded 48px target otherwise steals height from the page.
    style: IconButton.styleFrom(
      minimumSize: const Size(44, 44),
      maximumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    color: _accent,
    disabledColor: _ink.withValues(alpha: .35),
    onPressed: (previous ? _page > 0 : _page < _pageCount - 1)
        ? () => _goTo(_page + (previous ? -1 : 1))
        : null,
    icon: Icon(
      previous ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
      size: 22,
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('draft_compatibility_store_preview'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: ZyraColors.surfaceBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PageView.builder(
            key: const ValueKey('draft_compatibility_store_preview_pages'),
            controller: _pages,
            physics: const ClampingScrollPhysics(),
            itemCount: _pageCount,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, page) => page == 0
                ? _lockedPage()
                : _FictionalScorePreview(
                    sample: _fictionalScores[page - 1],
                    page: page,
                    ringSize: widget.ringSize,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _arrow(previous: true),
            Expanded(
              child: Text(
                '${_page + 1} / $_pageCount',
                key: const ValueKey(
                  'draft_compatibility_store_preview_position',
                ),
                semanticsLabel: _page == 0
                    ? 'Score preview page 1 of $_pageCount: Locked score. '
                          'Swipe left or right to see the illustrated design.'
                    : 'Score preview page ${_page + 1} of $_pageCount: '
                          '${_fictionalScores[_page - 1].title}. Not a real profile result.',
                textAlign: TextAlign.center,
                style: _body(size: 11),
              ),
            ),
            _arrow(previous: false),
          ],
        ),
      ],
    ),
  );

  Widget _lockedPage() => Column(
    key: const ValueKey('draft_compatibility_store_preview_locked'),
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Semantics(
          key: const ValueKey('draft_compatibility_store_preview_semantics'),
          label:
              'Locked compatibility score preview. No scores or Guardian information are loaded.',
          child: ExcludeSemantics(
            child: Container(
              key: const ValueKey('draft_compatibility_store_halo'),
              width: widget.ringSize,
              height: widget.ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accent.withValues(alpha: .30),
                  width: 7,
                ),
              ),
              child: Icon(Icons.lock_outline_rounded, size: 30, color: _accent),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Your match, revealed',
        textAlign: TextAlign.center,
        style: _body(size: 21).copyWith(height: 1.25),
      ),
      const SizedBox(height: 2),
      Text(
        'One profile. Every score.',
        textAlign: TextAlign.center,
        style: _body(size: 13),
      ),
      const SizedBox(height: 8),
      TextButton(
        key: const ValueKey('draft_compatibility_store_included'),
        onPressed: widget.onInformation,
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: _accent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'What’s included',
          textAlign: TextAlign.center,
          style: _buttonBody(size: 13).copyWith(color: _accent),
        ),
      ),
    ],
  );
}

/// These constant, invented results describe the UI, never a real profile.
/// They are deliberately separate from protected score readers and services.
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
  const _FictionalScorePreview({
    required this.sample,
    required this.page,
    required this.ringSize,
  });
  final _FictionalScore sample;
  final int page;
  final double ringSize;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('draft_compatibility_store_example_$page'),
    label:
        'Score preview. ${sample.title}: '
        '${sample.aligned} percent aligned. '
        '${sample.discuss == null ? '' : '${sample.discuss} percent discuss, ${sample.opposed} percent opposed. '}'
        'Not a real profile result.',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final number = _textSize(
            '${sample.aligned}%',
            _exampleNumberStyle,
            MediaQuery.textScalerOf(context),
            Directionality.of(context),
            double.infinity,
          );
          final outside =
              number.width > ringSize - 28 || number.height > ringSize - 28;
          final score = Text(
            '${sample.aligned}%',
            key: ValueKey('draft_compatibility_store_example_score_$page'),
            textAlign: TextAlign.center,
            style: _exampleNumberStyle,
          );
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sample.title,
                key: ValueKey('draft_compatibility_store_example_title_$page'),
                textAlign: TextAlign.center,
                style: _exampleTitleStyle,
              ),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          value: sample.aligned / 100,
                          strokeWidth: 7,
                          color: _accent,
                          backgroundColor: _accent.withValues(alpha: .18),
                        ),
                      ),
                      if (outside)
                        Icon(Icons.balance_rounded, size: 30, color: _accent)
                      else
                        score,
                    ],
                  ),
                ),
              ),
              if (outside) ...[const SizedBox(height: 6), score],
              const SizedBox(height: 6),
              Text(
                'Aligned',
                textAlign: TextAlign.center,
                style: _body(size: 13),
              ),
              if (sample.discuss != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  key: ValueKey(
                    'draft_compatibility_store_example_details_$page',
                  ),
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text('Discuss ${sample.discuss}%', style: _body(size: 11)),
                    Text('Opposed ${sample.opposed}%', style: _body(size: 11)),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: _accent),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: _body(size: 14))),
    ],
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
  String get quantity => '$count ${count == 1 ? 'unlock' : 'unlocks'}';

  // Floor integer-pence percentages so the saving is never overstated.
  String? get saving {
    if (count == 1) return null;
    final singles = count * ZyraMembershipCatalog.compatibilitySinglePence;
    final percent = ((singles - pricePence) * 100) ~/ singles;
    return 'Save $percent% vs singles';
  }
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
    required this.onSelect,
  });
  final _StoreOffer offer;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('draft_compatibility_store_${offer.id}_selection'),
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    onTap: onSelect,
    label: [
      offer.quantity,
      ZyraMembershipCatalog.pounds(offer.pricePence),
      offer.unitLine,
      if (offer.saving != null) offer.saving!,
    ].join(', '),
    child: ExcludeSemantics(
      child: OutlinedButton(
        key: ValueKey('draft_compatibility_store_${offer.id}'),
        onPressed: onSelect,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 96),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          foregroundColor: _ink,
          backgroundColor: selected
              ? _accent.withValues(alpha: .12)
              : ZyraColors.surfaceFill,
          side: BorderSide(
            color: selected ? _accent : ZyraColors.surfaceBorder,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
              style: _buttonBody(size: 13),
            ),
            const SizedBox(height: 3),
            Text(
              ZyraMembershipCatalog.pounds(offer.pricePence),
              textAlign: TextAlign.center,
              style: _buttonBody(
                size: 19,
              ).copyWith(color: _accent, height: 1.2),
            ),
            const SizedBox(height: 3),
            Text(
              offer.unitLine,
              textAlign: TextAlign.center,
              style: _buttonBody(size: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

const _lifetime =
    'An unlock is permanent. Once you unlock a profile it stays unlocked, '
    'including after a Journey ends.';

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
  )..layout(maxWidth: maxWidth);
  final size = painter.size;
  painter.dispose();
  return size;
}

double _balanceHeight(
  int balance,
  TextScaler scaler,
  TextDirection direction,
  double width,
) {
  final innerWidth = (width - 34).clamp(1, double.infinity).toDouble();
  final stacked = _balanceNeedsStack(balance, scaler, direction, innerWidth);
  final count = _balanceCountSize(
    balance,
    scaler,
    direction,
    stacked ? innerWidth : double.infinity,
  );
  final label = _textSize(
    'Unlocks remaining',
    _body(size: 14),
    scaler,
    direction,
    stacked ? innerWidth : innerWidth - count.width - 16,
  );
  final contentHeight = stacked
      ? label.height + 4 + count.height
      : (label.height > count.height ? label.height : count.height);
  return (contentHeight + 18).clamp(52, double.infinity).toDouble();
}

bool _balanceNeedsStack(
  int balance,
  TextScaler scaler,
  TextDirection direction,
  double innerWidth,
) =>
    _textSize(
          'Unlocks remaining',
          _body(size: 14),
          scaler,
          direction,
          double.infinity,
        ).width +
        16 +
        _balanceCountSize(balance, scaler, direction, double.infinity).width >
    innerWidth;

// Includes the capsule's padding AND one-pixel border. The fixed-page
// measurement must agree with real layout even for a wrapped large balance.
Size _balanceCountSize(
  int balance,
  TextScaler scaler,
  TextDirection direction,
  double maxWidth,
) {
  final text = _textSize(
    '$balance',
    _balanceCountStyle,
    scaler,
    direction,
    (maxWidth - 18).clamp(1, double.infinity).toDouble(),
  );
  return Size(
    (text.width + 18).clamp(36, double.infinity).toDouble(),
    (text.height + 10).clamp(32, double.infinity).toDouble(),
  );
}

double _preferredCardWidth(TextScaler scaler, TextDirection direction) {
  var width = 96.0;
  for (final offer in _offers) {
    final labels = [
      (offer.quantity, _buttonBody(size: 13)),
      (
        ZyraMembershipCatalog.pounds(offer.pricePence),
        _buttonBody(size: 19).copyWith(height: 1.2),
      ),
      (offer.unitLine, _buttonBody(size: 11)),
    ];
    for (final (text, style) in labels) {
      final candidate =
          _textSize(text, style, scaler, direction, double.infinity).width + 20;
      if (candidate > width) width = candidate;
    }
  }
  return width;
}

double _cardHeight(double width, TextScaler scaler, TextDirection direction) {
  var height = 96.0;
  for (final offer in _offers) {
    final candidate =
        _textSize(
          offer.quantity,
          _buttonBody(size: 13),
          scaler,
          direction,
          width - 12,
        ).height +
        _textSize(
          ZyraMembershipCatalog.pounds(offer.pricePence),
          _buttonBody(size: 19).copyWith(height: 1.2),
          scaler,
          direction,
          width - 12,
        ).height +
        _textSize(
          offer.unitLine,
          _buttonBody(size: 11),
          scaler,
          direction,
          width - 12,
        ).height +
        34;
    if (candidate > height) height = candidate;
  }
  return height;
}

double _continueHeight(
  _StoreOffer? offer,
  TextScaler scaler,
  TextDirection direction,
  double width,
) {
  final title = offer == null
      ? 'Continue'
      : 'Continue · ${ZyraMembershipCatalog.pounds(offer.pricePence)}';
  final titleHeight = _textSize(
    title,
    _buttonBody(size: 14),
    scaler,
    direction,
    width - 32,
  ).height;
  final savingHeight = offer?.saving == null
      ? 0.0
      : _textSize(
              offer!.saving!,
              _buttonBody(size: 11),
              scaler,
              direction,
              width - 32,
            ).height +
            2;
  return (titleHeight + savingHeight + 20)
      .clamp(48, double.infinity)
      .toDouble();
}

double _heroHeight(double width, TextScaler scaler, TextDirection direction) {
  final innerWidth = (width - 34).clamp(1, double.infinity).toDouble();
  final ringSize = _previewRingSize(width, scaler, direction);
  final heading = _textSize(
    'Your match, revealed',
    _body(size: 21).copyWith(height: 1.25),
    scaler,
    direction,
    innerWidth,
  ).height;
  final subtitle = _textSize(
    'One profile. Every score.',
    _body(size: 13),
    scaler,
    direction,
    innerWidth,
  ).height;
  final included =
      (_textSize(
                'What’s included',
                _buttonBody(size: 13),
                scaler,
                direction,
                innerWidth - 16,
              ).height +
              20)
          .clamp(44, double.infinity)
          .toDouble();
  var pageHeight = ringSize + 12 + heading + 2 + subtitle + 8 + included;
  for (final sample in _fictionalScores) {
    final titleHeight = _textSize(
      sample.title,
      _exampleTitleStyle,
      scaler,
      direction,
      innerWidth,
    ).height;
    final number = _textSize(
      '${sample.aligned}%',
      _exampleNumberStyle,
      scaler,
      direction,
      double.infinity,
    );
    final outside =
        number.width > ringSize - 28 || number.height > ringSize - 28;
    final numberHeight = outside
        ? 6 +
              _textSize(
                '${sample.aligned}%',
                _exampleNumberStyle,
                scaler,
                direction,
                innerWidth,
              ).height
        : 0.0;
    final alignedHeight = _textSize(
      'Aligned',
      _body(size: 13),
      scaler,
      direction,
      innerWidth,
    ).height;
    var detailsHeight = 0.0;
    if (sample.discuss != null) {
      final discuss = _textSize(
        'Discuss ${sample.discuss}%',
        _body(size: 11),
        scaler,
        direction,
        innerWidth,
      );
      final opposed = _textSize(
        'Opposed ${sample.opposed}%',
        _body(size: 11),
        scaler,
        direction,
        innerWidth,
      );
      detailsHeight =
          6 +
          (discuss.width + 16 + opposed.width <= innerWidth
              ? (discuss.height > opposed.height
                    ? discuss.height
                    : opposed.height)
              : discuss.height + 4 + opposed.height);
    }
    final sampleHeight =
        titleHeight +
        8 +
        ringSize +
        numberHeight +
        6 +
        alignedHeight +
        detailsHeight;
    if (sampleHeight > pageHeight) pageHeight = sampleHeight;
  }
  final navigationHeight = _textSize(
    '8 / 8',
    _body(size: 11),
    scaler,
    direction,
    (innerWidth - 88).clamp(1, double.infinity).toDouble(),
  ).height.clamp(44, double.infinity).toDouble();
  return pageHeight + 34 + 8 + navigationHeight;
}

double _previewRingSize(
  double width,
  TextScaler scaler,
  TextDirection direction,
) {
  var diameter = width < 340 ? 112.0 : 136.0;
  for (final sample in _fictionalScores) {
    final number = _textSize(
      '${sample.aligned}%',
      _exampleNumberStyle,
      scaler,
      direction,
      double.infinity,
    );
    final measured =
        (number.width > number.height ? number.width : number.height) + 32;
    if (measured > diameter) diameter = measured;
  }
  return diameter.clamp(0, (width - 34).clamp(0, double.infinity)).toDouble();
}

// Opaque reading copy; the existing light palette uses dark gold for contrast.
Color get _ink => ZyraColors.foreground;
Color get _accent => ZyraColors.isLightPalette
    ? const Color(0xFF76531F)
    : ZyraColors.journeyGold;
Color get _dialogSurface => ZyraColors.isLightPalette
    ? const Color(0xFFF4EFF6)
    : const Color(0xFF30253E);
TextStyle _body({required double size}) =>
    ZyraText.body(size: size, color: _ink).copyWith(
      height: 1.45,
      // Match the app's inherited reading metrics explicitly so intrinsic
      // measurement and rendered multiline paragraphs use identical leading.
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
      letterSpacing: .25,
    );
TextStyle _buttonBody({required double size}) =>
    _body(size: size).copyWith(letterSpacing: .1);
TextStyle get _balanceCountStyle => _body(
  size: 18,
).copyWith(color: _accent, fontWeight: FontWeight.w400, letterSpacing: .1);
TextStyle get _exampleTitleStyle => _body(size: 20).copyWith(height: 1.25);
TextStyle get _exampleNumberStyle =>
    ZyraText.heading(size: 36, color: _accent).copyWith(
      height: 1.1,
      leadingDistribution: TextLeadingDistribution.even,
      textBaseline: TextBaseline.alphabetic,
      letterSpacing: .25,
    );
