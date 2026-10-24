// Notification education anchored to the floating nav.
// Screens provide context only; ZyraPromotionEngine decides if anything is
// allowed to appear. The five-second line is time-to-hide, never urgency.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/zyra_promotion_engine.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'floating_nav_bar.dart';

class ZyraBottomPromotion extends StatefulWidget {
  final ZyraPromotionRole role;
  final ZyraPromotionPlacement placement;
  final bool isCalmLanding;

  /// Legacy constructor inputs; this widget only shows notification education.
  final bool isEntitled;
  final bool upgradeOfferAvailable;
  final ValueChanged<ZyraPromotionProduct> onOpenPlan;
  final ZyraPromotionEngine? engine;

  const ZyraBottomPromotion({
    super.key,
    required this.role,
    required this.placement,
    required this.isCalmLanding,
    required this.isEntitled,
    required this.upgradeOfferAvailable,
    required this.onOpenPlan,
    this.engine,
  });

  @override
  State<ZyraBottomPromotion> createState() => _ZyraBottomPromotionState();
}

class _ZyraBottomPromotionState extends State<ZyraBottomPromotion>
    with SingleTickerProviderStateMixin {
  static const _visibleFor = Duration(seconds: 5);
  late final ZyraPromotionEngine _engine;
  late final AnimationController _timer;
  String? _impressionKey;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? ZyraPromotionEngine.instance;
    _timer = AnimationController(vsync: this, duration: _visibleFor)
      ..addStatusListener(_onTimerStatus);
    _engine.addListener(_onEngineChange);
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChange);
    _timer
      ..removeStatusListener(_onTimerStatus)
      ..dispose();
    super.dispose();
  }

  void _onEngineChange() {
    if (mounted) setState(() {});
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final offer = _decision.offer;
    if (offer != null) {
      _engine.dismiss(offer, dismissal: ZyraPromotionDismissal.close);
    }
  }

  ZyraPromotionDecision get _decision => _engine.decisionForSurface(
    role: widget.role,
    placement: widget.placement,
    isCalmLanding: widget.isCalmLanding,
    isEntitled: widget.isEntitled,
    upgradeOfferAvailable: widget.upgradeOfferAvailable,
  );

  void _arm(ZyraPromotionOffer offer) {
    final key =
        '${offer.product.name}/${offer.feature.name}/'
        '${offer.placement.name}/${offer.trigger.name}/'
        '${offer.developerPreview}';
    if (_impressionKey == key) return;
    _impressionKey = key;
    _timer
      ..stop()
      ..reset()
      ..forward();
    _engine.recordImpression(offer);
  }

  Future<void> _dismiss(
    ZyraPromotionOffer offer,
    ZyraPromotionDismissal dismissal,
  ) async {
    _timer.stop();
    await _engine.dismiss(offer, dismissal: dismissal);
  }

  Future<void> _act(ZyraPromotionOffer offer) async {
    if (offer.product != ZyraPromotionProduct.notifications ||
        offer.dependency != ZyraPromotionDependency.ready) {
      return;
    }
    _timer.stop();
    await _engine.recordOpened(offer);
    if (!mounted) return;
    final state = await _engine.requestNotificationPermission(offer);
    if (!mounted) return;
    if (state != ZyraNotificationPermissionState.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Device notifications are not connected in this build yet.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final decision = _decision;
    final offer = decision.offer;
    if (offer == null ||
        offer.product != ZyraPromotionProduct.notifications ||
        !widget.isCalmLanding) {
      _timer.stop();
      _impressionKey = null;
      return SizedBox.shrink();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _arm(offer);
    });

    final safeBottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      ZyraNavBarMetrics.bottomInset,
    );
    return Positioned(
      left: 18,
      right: 18,
      bottom: safeBottom + ZyraNavBarMetrics.restingHeight + 12,
      child: Semantics(
        container: true,
        label: '${offer.title}. ${offer.message}',
        child: Material(
          color: Colors.transparent,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                ZyraColors.surfaceEmphasisFill,
                ZyraColors.waliSheetBg,
              ),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: ZyraColors.surfaceEmphasisBorder,
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 11, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            offer.product == ZyraPromotionProduct.notifications
                                ? Icons.notifications_none_rounded
                                : Icons.auto_awesome_outlined,
                            size: 18,
                            color: ZyraColors.accentBorder,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              offer.title,
                              style: ZyraText.body(
                                size: 13.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('promotion_close'),
                            tooltip: 'Dismiss',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () =>
                                _dismiss(offer, ZyraPromotionDismissal.close),
                            icon: Icon(
                              Icons.close,
                              size: 15,
                              color: ZyraColors.ink(0.38),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(27, 1, 4, 7),
                        child: Text(
                          offer.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: ZyraText.subtext(
                            size: 10.5,
                            color: ZyraColors.ink(0.54),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 27, right: 4),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 3,
                          children: [
                            if (offer.product ==
                                ZyraPromotionProduct.notifications) ...[
                              TextButton(
                                key: const ValueKey(
                                  'notification_promotion_not_now',
                                ),
                                onPressed: () => _dismiss(
                                  offer,
                                  ZyraPromotionDismissal.notNow,
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                ),
                                child: Text(
                                  'Not now',
                                  style: ZyraText.subtext(
                                    size: 10.5,
                                    color: ZyraColors.ink(0.54),
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const ValueKey(
                                  'notification_promotion_never',
                                ),
                                onPressed: () => _dismiss(
                                  offer,
                                  ZyraPromotionDismissal.dontShow,
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                ),
                                child: Text(
                                  'Don’t ask again',
                                  maxLines: 1,
                                  style: ZyraText.subtext(
                                    size: 9.5,
                                    color: ZyraColors.ink(0.38),
                                  ),
                                ),
                              ),
                            ],
                            FilledButton(
                              key: const ValueKey('promotion_primary_action'),
                              onPressed:
                                  offer.product ==
                                          ZyraPromotionProduct.notifications &&
                                      offer.dependency !=
                                          ZyraPromotionDependency.ready
                                  ? null
                                  : () => _act(offer),
                              style: FilledButton.styleFrom(
                                backgroundColor: ZyraColors.accentBg,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: BorderSide(
                                    color: ZyraColors.accentBorder,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                              child: Text(
                                offer.actionLabel,
                                style: ZyraText.button(size: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _timer,
                  builder: (context, _) => LinearProgressIndicator(
                    key: const ValueKey('promotion_countdown'),
                    value: 1 - _timer.value,
                    minHeight: 2,
                    backgroundColor: ZyraColors.foreground.withValues(
                      alpha: 0.05,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ZyraColors.accentBorder.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
