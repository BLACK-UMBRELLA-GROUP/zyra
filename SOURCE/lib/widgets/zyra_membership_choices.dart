import 'zyra_tap_feedback.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/zyra_membership_catalog.dart';
import '../models/zyra_membership_draft.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

export '../models/zyra_membership_draft.dart';

/// Shared, unsubmitted membership presentation. The route owner supplies facts;
/// this widget never derives billing history, writes access, or starts checkout.
class ZyraMembershipChoices extends StatefulWidget {
  ZyraMembershipChoices({
    super.key,
    required Set<ZyraMembershipProduct> currentProducts,
    required this.paymentHistory,
    required this.currentSummary,
    required this.onDraftChanged,
    required this.onReview,
    this.initialDraft,
    this.currentDetail,
    this.canAct,
    this.onBack,
    this.showBackButton = true,
    this.currentContent,
    this.unlocksContent,
    this.onTerms,
  }) : currentProducts = Set.unmodifiable(currentProducts);

  final Set<ZyraMembershipProduct> currentProducts;
  final ZyraMembershipPaymentHistory paymentHistory;
  final String currentSummary;
  final String? currentDetail;
  final ZyraMembershipDraft? initialDraft;
  final ValueChanged<ZyraMembershipDraft> onDraftChanged;
  final ValueChanged<ZyraMembershipReviewRequest> onReview;
  final bool Function()? canAct;
  final VoidCallback? onBack;
  final bool showBackButton;
  final Widget? currentContent;
  final Widget? unlocksContent;
  final VoidCallback? onTerms;

  @override
  State<ZyraMembershipChoices> createState() => _ZyraMembershipChoicesState();
}

class _ZyraMembershipChoicesState extends State<ZyraMembershipChoices> {
  late ZyraMembershipDraft _draft;
  late PageController _seekerController;
  late PageController _guardianController;
  final ScrollController _scrollController = ScrollController();
  int _epoch = 0;
  int _controllerRevision = 0;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft ?? ZyraMembershipDraft();
    _createControllers();
  }

  void _createControllers() {
    _controllerRevision++;
    _seekerController = PageController(
      initialPage: _draft.seekerPage,
      viewportFraction: .94,
      keepPage: false,
    );
    _guardianController = PageController(
      initialPage: _draft.guardianPage,
      viewportFraction: .94,
      keepPage: false,
    );
  }

  @override
  void didUpdateWidget(covariant ZyraMembershipChoices oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Captured actions from a previous owner/revision must not survive rebuild.
    _epoch++;
    final incoming = widget.initialDraft;
    if (incoming != oldWidget.initialDraft &&
        incoming != null &&
        incoming != _draft) {
      _draft = incoming;
      _seekerController.dispose();
      _guardianController.dispose();
      _createControllers();
    }
  }

  @override
  void dispose() {
    _epoch++;
    _seekerController.dispose();
    _guardianController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _allows(int epoch) =>
      mounted && epoch == _epoch && (widget.canAct?.call() ?? true);

  void _change(int epoch, ZyraMembershipDraft next) {
    if (!_allows(epoch) || next == _draft) return;
    setState(() {
      _epoch++;
      if (next.section != _draft.section) {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
        // Only the newly visible role controller is unattached here. Recreate
        // it from its retained draft index instead of relying on PageStorage,
        // which could also restore a different owner's historical offset.
        if (next.section == ZyraMembershipSection.seeker) {
          _seekerController.dispose();
          _seekerController = PageController(
            initialPage: next.seekerPage,
            viewportFraction: .94,
            keepPage: false,
          );
        } else if (next.section == ZyraMembershipSection.guardian) {
          _guardianController.dispose();
          _guardianController = PageController(
            initialPage: next.guardianPage,
            viewportFraction: .94,
            keepPage: false,
          );
        }
        _controllerRevision++;
      }
      _draft = next;
    });
    widget.onDraftChanged(next);
  }

  void _move(int epoch, int page) {
    if (!_allows(epoch) || page < 0 || page > 1) return;
    final controller = _draft.section == ZyraMembershipSection.seeker
        ? _seekerController
        : _guardianController;
    if (!controller.hasClients) return;
    // With Peek cards and padEnds:false the last card's leading edge cannot
    // quite reach the viewport's left edge. Clamp before jumping/animating so
    // an out-of-range target does not create a second spring-back animation.
    final target =
        (page *
                controller.position.viewportDimension *
                controller.viewportFraction)
            .clamp(
              controller.position.minScrollExtent,
              controller.position.maxScrollExtent,
            )
            .toDouble();
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      controller.jumpTo(target);
    } else {
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final epoch = ++_epoch;
    final enabled = widget.canAct?.call() ?? true;
    final review = ZyraMembershipReviewRequest.fromDraft(
      _draft,
      currentProducts: widget.currentProducts,
      paymentHistory: widget.paymentHistory,
    );
    return SingleChildScrollView(
      key: const ValueKey('membership-choices-scroll'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showBackButton && widget.onBack != null) ...[
            _BackAction(
              onPressed: enabled
                  ? () {
                      if (_allows(epoch)) widget.onBack?.call();
                    }
                  : null,
            ),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Expanded(child: Text('Membership', style: ZyraText.pageTitle())),
              const SizedBox(width: 8),
              IconButton(
                key: const ValueKey('membership-terms'),
                tooltip: 'Membership terms',
                onPressed: ZyraTapFeedback.onTap(
                  context,
                  enabled && widget.onTerms != null
                      ? () {
                          if (_allows(epoch)) widget.onTerms?.call();
                        }
                      : null,
                ),
                color: ZyraColors.journeyGold,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.description_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MembershipSectionSlider(
            section: _draft.section,
            onSelected: enabled
                ? (section) => _change(epoch, _draft.copyWith(section: section))
                : null,
          ),
          const SizedBox(height: 18),
          if (_draft.section == ZyraMembershipSection.current) ...[
            _MembershipPanel(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  key: const ValueKey('membership-current'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.currentSummary,
                      style: ZyraText.heading(size: 23),
                    ),
                    if (widget.currentDetail?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(widget.currentDetail!, style: ZyraText.subtext()),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.currentContent != null) ...[
              const SizedBox(height: 20),
              widget.currentContent!,
            ],
          ] else if (_draft.section == ZyraMembershipSection.unlocks) ...[
            if (widget.unlocksContent != null) widget.unlocksContent!,
          ] else ...[
            if (_draft.section == ZyraMembershipSection.family)
              _FamilyCard(
                draft: _draft,
                onChanged: enabled ? (next) => _change(epoch, next) : null,
              )
            else
              _personalPager(context, epoch, enabled),
            const SizedBox(height: 18),
            _GoldButton(
              key: const ValueKey('membership-review-selection'),
              label: 'Review selection',
              icon: Icons.arrow_forward_rounded,
              onPressed: enabled && review != null
                  ? () {
                      if (!_allows(epoch)) return;
                      final fresh = ZyraMembershipReviewRequest.fromDraft(
                        _draft,
                        currentProducts: widget.currentProducts,
                        paymentHistory: widget.paymentHistory,
                      );
                      if (fresh != null) widget.onReview(fresh);
                    }
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _personalPager(BuildContext context, int epoch, bool enabled) {
    final section = _draft.section;
    final isSeeker = section == ZyraMembershipSection.seeker;
    final controller = isSeeker ? _seekerController : _guardianController;
    final products = isSeeker
        ? const [
            ZyraMembershipProduct.seekerOne,
            ZyraMembershipProduct.seekerBasic,
          ]
        : const [
            ZyraMembershipProduct.guardianOne,
            ZyraMembershipProduct.guardianBasic,
          ];
    return Column(
      children: [
        _NaturalMembershipPager(
          key: ValueKey('membership-pager-${section.name}'),
          measurement: Stack(
            children: [
              for (final product in products)
                _PersonalCard(
                  product: product,
                  paymentHistory: widget.paymentHistory,
                  current: widget.currentProducts.contains(product),
                  selected: _draft.selectedProducts.contains(product),
                  onSelect: null,
                  onRemove: null,
                  measureOnly: true,
                ),
            ],
          ),
          viewport: PageView.builder(
            key: ValueKey(
              'membership-page-view-${section.name}-$_controllerRevision',
            ),
            controller: controller,
            padEnds: false,
            itemCount: 2,
            physics: enabled
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              if (!_allows(epoch) || _draft.section != section) return;
              _change(
                epoch,
                isSeeker
                    ? _draft.copyWith(seekerPage: page)
                    : _draft.copyWith(guardianPage: page),
              );
            },
            itemBuilder: (context, index) {
              final product = products[index];
              final current = widget.currentProducts.contains(product);
              final selected = _draft.selectedProducts.contains(product);
              final unresolvedBasic =
                  ZyraMembershipCatalog.isBasic(product) &&
                  widget.paymentHistory == ZyraMembershipPaymentHistory.unknown;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _PersonalCard(
                  product: product,
                  paymentHistory: widget.paymentHistory,
                  current: current,
                  selected: selected,
                  onSelect: enabled && !unresolvedBasic && !selected
                      ? () => _change(
                          epoch,
                          _draft.selectProduct(
                            product,
                            currentProducts: widget.currentProducts,
                          ),
                        )
                      : null,
                  onRemove: enabled && selected
                      ? () =>
                            _change(epoch, _draft.removeRoleSelection(section))
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const ValueKey('membership-previous'),
              tooltip: 'Previous membership card',
              onPressed: ZyraTapFeedback.onTap(
                context,
                enabled && _draft.page > 0
                    ? () => _move(epoch, _draft.page - 1)
                    : null,
              ),
              color: ZyraColors.journeyGold,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '${_draft.page + 1} / 2',
                key: const ValueKey('membership-page-count'),
                style: ZyraText.subtext(size: 13),
              ),
            ),
            IconButton(
              key: const ValueKey('membership-next'),
              tooltip: 'Next membership card',
              onPressed: ZyraTapFeedback.onTap(
                context,
                enabled && _draft.page < 1
                    ? () => _move(epoch, _draft.page + 1)
                    : null,
              ),
              color: ZyraColors.journeyGold,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

/// PageView requires a bounded height. Measure the real card trees first in
/// the same layout pass, without painting, semantics, focus or hit testing.
/// Unlike a scaler-based estimate this includes actual font metrics, wrapping,
/// selected-state buttons and the accessible halo fallback immediately.
class _NaturalMembershipPager extends MultiChildRenderObjectWidget {
  _NaturalMembershipPager({
    super.key,
    required Widget measurement,
    required Widget viewport,
  }) : super(
         children: [
           _MeasuredOffstage(child: ExcludeFocus(child: measurement)),
           viewport,
         ],
       );

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _NaturalMembershipPagerBox();
}

class _MeasuredOffstage extends Offstage {
  const _MeasuredOffstage({required super.child});

  @override
  RenderOffstage createRenderObject(BuildContext context) =>
      _MeasuredOffstageBox();
}

class _MeasuredOffstageBox extends RenderOffstage {
  double measuredHeight = 0;

  // Natural child height affects the visible pager. Unlike ordinary Offstage,
  // this object must propagate child layout invalidations to its parent.
  @override
  bool get sizedByParent => false;

  @override
  void performLayout() {
    final measuredChild = child;
    if (measuredChild == null) {
      measuredHeight = 0;
    } else {
      measuredChild.layout(constraints, parentUsesSize: true);
      measuredHeight = measuredChild.size.height;
    }
    size = constraints.smallest;
  }
}

class _MembershipPagerParentData extends ContainerBoxParentData<RenderBox> {}

class _NaturalMembershipPagerBox extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = _MembershipPagerParentData();
    }
  }

  @override
  void performLayout() {
    final measurement = firstChild! as _MeasuredOffstageBox;
    final viewport = childAfter(measurement)!;
    final width = constraints.maxWidth;
    // These are the PageView's .94 viewport fraction and card's trailing10px.
    final cardWidth = math.max(0.0, width * .94 - 10);
    measurement.layout(
      BoxConstraints.tightFor(width: cardWidth),
      parentUsesSize: true,
    );
    // Use actual content height, not an empty minimum-height floor that pushes
    // controls below the fold. Large text still grows naturally and scrolls.
    final height = measurement.measuredHeight;
    viewport.layout(
      BoxConstraints.tightFor(width: width, height: height),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.paintChild(lastChild!, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      lastChild!.hitTest(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitor(lastChild!);
  }
}

/// Browsing these labels never changes the chosen section. The strip has its
/// own horizontal position, separate from the page's vertical position and the
/// One/Basic pagers inside each personal role.
class _MembershipSectionSlider extends StatefulWidget {
  const _MembershipSectionSlider({
    required this.section,
    required this.onSelected,
  });

  final ZyraMembershipSection section;
  final ValueChanged<ZyraMembershipSection>? onSelected;

  @override
  State<_MembershipSectionSlider> createState() =>
      _MembershipSectionSliderState();
}

class _MembershipSectionSliderState extends State<_MembershipSectionSlider> {
  static const _sections = [
    ZyraMembershipSection.current,
    ZyraMembershipSection.unlocks,
    ZyraMembershipSection.seeker,
    ZyraMembershipSection.guardian,
    ZyraMembershipSection.family,
  ];
  final ScrollController _controller = ScrollController();
  final _anchors = {for (final section in _sections) section: GlobalKey()};
  int _revealRevision = 0;
  double? _width;
  Object? _readingMetrics;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final metrics = (
      media.textScaler,
      media.boldText,
      media.disableAnimations,
      media.accessibleNavigation,
      Directionality.of(context),
      Localizations.maybeLocaleOf(context),
      DefaultTextStyle.of(context).style,
    );
    if (metrics != _readingMetrics) {
      _readingMetrics = metrics;
      _revealSelected(animate: false);
    }
  }

  @override
  void didUpdateWidget(covariant _MembershipSectionSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) _revealSelected(animate: true);
  }

  void _revealSelected({required bool animate}) {
    final revision = ++_revealRevision;
    final section = widget.section;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _revealRevision ||
          section != widget.section ||
          !_controller.hasClients ||
          !_controller.position.hasContentDimensions) {
        return;
      }
      final target = _anchors[section]?.currentContext?.findRenderObject();
      if (target == null || !target.attached) return;
      final media = MediaQuery.of(context);
      // Only this horizontal position is revealed; do not move the outer
      // vertical page or either role's plan pager as a side effect.
      _controller.position.ensureVisible(
        target,
        alignment: .5,
        duration:
            animate && !media.disableAnimations && !media.accessibleNavigation
            ? const Duration(milliseconds: 220)
            : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _revealRevision++;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Keep the callback bound to this render's owner/epoch. A captured old
      // button must not borrow a replacement widget's newer guarded action.
      final onSelected = widget.onSelected;
      if (_width != constraints.maxWidth) {
        _width = constraints.maxWidth;
        _revealSelected(animate: false);
      }
      return SingleChildScrollView(
        key: const ValueKey('membership-section-slider'),
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final section in _sections) ...[
              if (section != _sections.first) const SizedBox(width: 8),
              _SectionPill(
                key: _anchors[section],
                section: section,
                selected: widget.section == section,
                onPressed: onSelected == null
                    ? null
                    : () => onSelected(section),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _SectionPill extends StatelessWidget {
  const _SectionPill({
    super.key,
    required this.section,
    required this.selected,
    required this.onPressed,
  });

  final ZyraMembershipSection section;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      selected: selected,
      child: OutlinedButton(
        key: ValueKey('membership-section-${section.name}'),
        onPressed: ZyraTapFeedback.onTap(context, onPressed),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected
              ? ZyraColors.journeyGold
              : ZyraColors.foregroundSecondary,
          backgroundColor: selected ? ZyraColors.surfaceEmphasisFill : null,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          side: BorderSide(
            color: selected ? ZyraColors.journeyGold : ZyraColors.surfaceBorder,
          ),
          shape: const StadiumBorder(),
        ),
        child: Text(
          switch (section) {
            ZyraMembershipSection.current => 'Current',
            ZyraMembershipSection.seeker => 'Seeker',
            ZyraMembershipSection.guardian => 'Guardian',
            ZyraMembershipSection.family => 'ZYRA Family',
            ZyraMembershipSection.unlocks => 'Compatibility Unlocks',
          },
          textAlign: TextAlign.center,
          softWrap: false,
          maxLines: 1,
          style: ZyraText.button(
            size: 12,
            color: onPressed == null
                ? ZyraColors.ink(.4)
                : selected
                ? ZyraColors.goldText
                : ZyraColors.foregroundSecondary,
          ),
        ),
      ),
    ),
  );
}

class _PersonalCard extends StatelessWidget {
  const _PersonalCard({
    required this.product,
    required this.paymentHistory,
    required this.current,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    this.measureOnly = false,
  });

  final ZyraMembershipProduct product;
  final ZyraMembershipPaymentHistory paymentHistory;
  final bool current;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onRemove;
  final bool measureOnly;

  bool get _seeker =>
      product == ZyraMembershipProduct.seekerOne ||
      product == ZyraMembershipProduct.seekerBasic;

  List<String> get _benefits => switch (product) {
    ZyraMembershipProduct.seekerOne => [
      'Up to 3 active Journeys',
      'One membership for your Seeker role',
      'Basic has no joining fee after a membership payment',
    ],
    ZyraMembershipProduct.seekerBasic => [
      '1 active Journey',
      'No monthly subscription',
      switch (paymentHistory) {
        ZyraMembershipPaymentHistory.unknown =>
          'The joining fee needs confirmed membership payment history',
        ZyraMembershipPaymentHistory.neverPaid =>
          'A one-time joining fee for your first membership payment',
        ZyraMembershipPaymentHistory.paidBefore =>
          'Your previous membership payment covers the joining fee',
      },
    ],
    ZyraMembershipProduct.guardianOne => [
      'View and Chat in permitted Journeys',
      'Journey access follows the linked Seeker’s permissions',
      'Membership does not create a Guardian link',
    ],
    ZyraMembershipProduct.guardianBasic => [
      'View when the Seeker permits',
      'Chat is not included',
      'No monthly subscription',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final basic = ZyraMembershipCatalog.isBasic(product);
    final price = ZyraMembershipCatalog.membershipPrice(
      product,
      history: paymentHistory,
    );
    return _MembershipPanel(
      highlighted: selected,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          mainAxisSize: measureOnly ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  ZyraMembershipCatalog.title(product),
                  style: ZyraText.heading(size: 23),
                ),
                if (current || selected)
                  Text(
                    current ? 'Current' : 'Selected change',
                    style: ZyraText.subtext(
                      size: 11,
                      color: ZyraColors.goldText,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final diameter = math.min(196.0, constraints.maxWidth);
                final stroke = diameter < 185 ? 8.0 : 10.0;
                final amount = basic
                    ? 'Basic'
                    : ZyraMembershipCatalog.pounds(
                        _seeker
                            ? ZyraMembershipCatalog.seekerOneMonthlyPence
                            : ZyraMembershipCatalog.guardianOneMonthlyPence,
                      );
                final period = basic ? 'No monthly subscription' : '/ month';
                final amountStyle = ZyraText.heading(
                  size: 28,
                  color: ZyraColors.journeyGold,
                );
                final periodStyle = ZyraText.subtext(size: 11);
                final innerSize = diameter - stroke * 2 - 28;
                double textHeight(String text, TextStyle style) {
                  final painter = TextPainter(
                    text: TextSpan(
                      text: text,
                      style: DefaultTextStyle.of(context).style.merge(style),
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(maxWidth: innerSize);
                  final result = painter.height;
                  painter.dispose();
                  return result;
                }

                // Retain the approved halo at ordinary type sizes. Accessible
                // copy that cannot fit is laid out naturally underneath it,
                // at the member's full text scale, never clipped or shrunk.
                final textInside =
                    24 +
                        5 +
                        textHeight(amount, amountStyle) +
                        3 +
                        textHeight(period, periodStyle) <=
                    innerSize;
                final amountText = Text(
                  amount,
                  style: amountStyle,
                  textAlign: TextAlign.center,
                );
                final periodText = Text(
                  period,
                  style: periodStyle,
                  textAlign: TextAlign.center,
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        key: ValueKey('membership-halo-${product.name}'),
                        width: diameter,
                        height: diameter,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ZyraColors.journeyGold,
                            width: stroke,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _seeker
                                  ? Icons.person_outline_rounded
                                  : Icons.shield_outlined,
                              size: 24,
                              color: ZyraColors.journeyGold,
                            ),
                            if (textInside) ...[
                              const SizedBox(height: 5),
                              amountText,
                              const SizedBox(height: 3),
                              periodText,
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!textInside) ...[
                      const SizedBox(height: 16),
                      amountText,
                      const SizedBox(height: 3),
                      periodText,
                    ],
                  ],
                );
              },
            ),
            if (basic) ...[
              const SizedBox(height: 16),
              Text(
                price,
                textAlign: TextAlign.center,
                style: ZyraText.body(color: ZyraColors.goldText),
              ),
            ],
            const SizedBox(height: 24),
            for (final benefit in _benefits) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(benefit, style: ZyraText.body())),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (measureOnly) const SizedBox(height: 16) else const Spacer(),
            _GoldButton(
              key: ValueKey('membership-select-${product.name}'),
              label: selected
                  ? 'Selected'
                  : current
                  ? 'Keep current plan'
                  : basic
                  ? 'Choose Basic'
                  : 'Choose One',
              icon: current || selected ? Icons.check_rounded : null,
              onPressed: onSelect,
            ),
            if (selected)
              TextButton(
                key: ValueKey('membership-remove-${product.name}'),
                onPressed: ZyraTapFeedback.onTap(context, onRemove),
                child: Text(
                  _seeker ? 'Remove Seeker choice' : 'Remove Guardian choice',
                  textAlign: TextAlign.center,
                  style: ZyraText.button(size: 12, color: ZyraColors.goldText),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.draft, required this.onChanged});

  final ZyraMembershipDraft draft;
  final ValueChanged<ZyraMembershipDraft>? onChanged;

  @override
  Widget build(BuildContext context) {
    final quote = draft.familyQuote;
    return _MembershipPanel(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ZYRA Family', style: ZyraText.heading(size: 23)),
            const SizedBox(height: 14),
            Text(
              'Choose the paid places your family needs.',
              style: ZyraText.body(),
            ),
            const SizedBox(height: 24),
            _FamilyStepper(
              role: 'Seeker',
              count: draft.familySeekers,
              pricePence: ZyraMembershipCatalog.seekerOneMonthlyPence,
              onChanged: onChanged == null
                  ? null
                  : (count) => onChanged!(draft.copyWith(familySeekers: count)),
            ),
            _FamilyStepper(
              role: 'Guardian',
              count: draft.familyGuardians,
              pricePence: ZyraMembershipCatalog.guardianOneMonthlyPence,
              onChanged: onChanged == null
                  ? null
                  : (count) =>
                        onChanged!(draft.copyWith(familyGuardians: count)),
            ),
            const SizedBox(height: 24),
            Divider(color: ZyraColors.surfaceBorder),
            const SizedBox(height: 20),
            Text('Monthly total', style: ZyraText.chapterLabel()),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                quote.hasMembers
                    ? ZyraMembershipCatalog.pounds(quote.formulaMonthlyPence)
                    : 'Choose places',
                key: const ValueKey('membership-family-total'),
                style: ZyraText.heading(
                  size: 32,
                  color: ZyraColors.journeyGold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${quote.discountPercent}% saving',
              key: const ValueKey('membership-family-saving'),
              style: ZyraText.body(color: ZyraColors.goldText),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _FamilyStepper extends StatelessWidget {
  const _FamilyStepper({
    required this.role,
    required this.count,
    required this.pricePence,
    required this.onChanged,
  });

  final String role;
  final int count;
  final int pricePence;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final label = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$role One', style: ZyraText.body(size: 15)),
            const SizedBox(height: 4),
            Text(
              '${ZyraMembershipCatalog.pounds(pricePence)} each / month before savings',
              style: ZyraText.subtext(size: 11),
            ),
          ],
        );
        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              controlKey: ValueKey(
                'membership-family-${role.toLowerCase()}-minus',
              ),
              label: 'Remove $role One place',
              icon: Icons.remove_rounded,
              onPressed: onChanged != null && count > 0
                  ? () => onChanged!(count - 1)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Semantics(
                label: '$role One place count',
                value: '$count',
                child: Text(
                  '$count',
                  key: ValueKey(
                    'membership-family-${role.toLowerCase()}-count',
                  ),
                  style: ZyraText.body(size: 17),
                ),
              ),
            ),
            _StepButton(
              controlKey: ValueKey(
                'membership-family-${role.toLowerCase()}-plus',
              ),
              label: 'Add $role One place',
              icon: Icons.add_rounded,
              onPressed:
                  onChanged != null &&
                      count < ZyraMembershipCatalog.familyMaxPerRole
                  ? () => onChanged!(count + 1)
                  : null,
            ),
          ],
        );
        if (constraints.maxWidth < 340 || scale > 1.2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label, const SizedBox(height: 12), controls],
          );
        }
        return Row(
          children: [
            Expanded(child: label),
            const SizedBox(width: 12),
            controls,
          ],
        );
      },
    ),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.controlKey,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final Key controlKey;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    key: controlKey,
    tooltip: label,
    onPressed: ZyraTapFeedback.onTap(context, onPressed),
    color: ZyraColors.journeyGold,
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      side: BorderSide(color: ZyraColors.surfaceBorder),
    ),
    icon: Icon(icon),
  );
}

/// The existing membership disclosures, moved out of the plan-card flow.
/// Route owners guard opening; this sheet cannot purchase or change access.
class ZyraMembershipTermsSheet extends StatelessWidget {
  const ZyraMembershipTermsSheet({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      decoration: BoxDecoration(
        color: ZyraColors.waliSheetBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Membership terms', style: ZyraText.heading(size: 20)),
            const SizedBox(height: 16),
            Text(
              '${ZyraMembershipCatalog.basicTerms}\n\n'
              '${ZyraMembershipCatalog.guardianBasicTerms}\n\n'
              '${ZyraMembershipCatalog.trialTerms}\n\n'
              '${ZyraMembershipCatalog.availability}\n\n'
              'Using both experiences does not make you your own Guardian. '
              'Guardian permissions and romantic exclusions still apply.\n\n'
              'Blocking, reporting, privacy and account controls do not require '
              'a subscription. Membership changes do not erase Guardian links '
              'or Journey history.',
              style: ZyraText.body(size: 13),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: ZyraTapFeedback.onTap(
                context,
                () => Navigator.of(context).pop(),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: ZyraColors.journeyGold,
              ),
              child: Text(
                'Close',
                style: ZyraText.button(color: ZyraColors.goldText),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Review is deliberately read-only while store purchasing is unavailable.
/// This presenter does not accept a checkout callback or activate a choice.
class ZyraMembershipReviewPresentation extends StatelessWidget {
  const ZyraMembershipReviewPresentation({
    super.key,
    required this.request,
    required this.paymentHistory,
    this.onBack,
    this.canAct,
    this.footer,
  });

  final ZyraMembershipReviewRequest request;
  final ZyraMembershipPaymentHistory paymentHistory;
  final VoidCallback? onBack;
  final bool Function()? canAct;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final family = request.familyQuote;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onBack != null) ...[
            _BackAction(
              onPressed: () {
                if (canAct?.call() ?? true) onBack?.call();
              },
            ),
            const SizedBox(height: 18),
          ],
          Text('Review selection', style: ZyraText.pageTitle()),
          const SizedBox(height: 24),
          _MembershipPanel(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (family != null) ...[
                    Text('ZYRA Family', style: ZyraText.heading(size: 23)),
                    const SizedBox(height: 18),
                    _ReviewLine(
                      title:
                          '${family.seekers} Seeker One ${family.seekers == 1 ? 'place' : 'places'}',
                    ),
                    _ReviewLine(
                      title:
                          '${family.guardians} Guardian One ${family.guardians == 1 ? 'place' : 'places'}',
                    ),
                    const SizedBox(height: 20),
                    Text('Monthly total', style: ZyraText.chapterLabel()),
                    const SizedBox(height: 8),
                    Text(
                      ZyraMembershipCatalog.pounds(family.formulaMonthlyPence),
                      style: ZyraText.heading(
                        size: 32,
                        color: ZyraColors.journeyGold,
                      ),
                    ),
                    Text(
                      '${family.discountPercent}% saving',
                      style: ZyraText.body(color: ZyraColors.goldText),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Include a place for your own role; both roles require two places. Family places provide One access for their assigned role.',
                      style: ZyraText.body(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Pricing preview. The final store price is confirmed before purchase. Family checkout and allocation are unavailable here; no links or Journey permissions are created.',
                      style: ZyraText.body(),
                    ),
                  ] else ...[
                    for (final product in ZyraMembershipCatalog.products)
                      if (request.products.contains(product))
                        _ReviewLine(
                          title: ZyraMembershipCatalog.title(product),
                          detail: ZyraMembershipCatalog.membershipPrice(
                            product,
                            history: paymentHistory,
                          ),
                        ),
                    const SizedBox(height: 18),
                    Text(
                      ZyraMembershipCatalog.basicTerms,
                      style: ZyraText.body(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    ZyraMembershipCatalog.availability,
                    key: const ValueKey('membership-review-store-unavailable'),
                    style: ZyraText.body(),
                  ),
                ],
              ),
            ),
          ),
          if (onBack != null) ...[
            const SizedBox(height: 20),
            _GoldButton(
              label: 'Back to cards',
              onPressed: () {
                if (canAct?.call() ?? true) onBack?.call();
              },
            ),
          ],
          if (footer != null) ...[const SizedBox(height: 20), footer!],
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.title, this.detail});
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: ZyraText.heading(size: 20)),
        if (detail != null) ...[
          const SizedBox(height: 6),
          Text(detail!, style: ZyraText.body(color: ZyraColors.goldText)),
        ],
      ],
    ),
  );
}

class _MembershipPanel extends StatelessWidget {
  const _MembershipPanel({required this.child, this.highlighted = false});
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: highlighted ? ZyraColors.journeyGold : ZyraColors.surfaceBorder,
      ),
    ),
    child: child,
  );
}

class _BackAction extends StatelessWidget {
  const _BackAction({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: ZyraTapFeedback.onTap(context, onPressed),
      icon: const Icon(Icons.arrow_back_rounded, color: ZyraColors.journeyGold),
      label: Text('Back', style: ZyraText.button(color: ZyraColors.goldText)),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
    ),
  );
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: ZyraTapFeedback.onTap(context, onPressed),
    style: OutlinedButton.styleFrom(
      foregroundColor: ZyraColors.journeyGold,
      disabledForegroundColor: ZyraColors.ink(.4),
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      side: BorderSide(
        color: onPressed != null
            ? ZyraColors.journeyGold
            : ZyraColors.surfaceBorder,
      ),
      shape: const StadiumBorder(),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ZyraText.button(
              color: onPressed == null
                  ? ZyraColors.ink(.4)
                  : ZyraColors.goldText,
            ),
          ),
        ),
        if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
      ],
    ),
  );
}
