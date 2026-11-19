import '../widgets/zyra_developer_title.dart';
// Shared LOCK19 monogram; LOCK8 V7 head/card presentation. No action authority.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';

class ZyraGoldRingMonogram extends StatelessWidget {
  const ZyraGoldRingMonogram({
    super.key,
    required this.name,
    required this.size,
    required this.fontSize,
    this.ringColor,
    this.guardianOne,
    this.weight = FontWeight.w200,
    this.textScaler,
    this.child,
  });
  final String name;
  final double size, fontSize;
  final Color? ringColor;

  /// A Guardian earns the ring only from a known One entitlement. Null
  /// keeps the shared decorative treatment for other kinds of artwork.
  final bool? guardianOne;
  final FontWeight weight;
  final TextScaler? textScaler;

  /// Optional outline artwork within the same shared ring geometry.
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final hasGuardianRing = guardianOne == true;
    final plainGuardian = guardianOne == false;
    final initial = guardianOne == null
        ? name.characters.firstOrNull ?? ''
        : name.trim().characters.firstOrNull?.toUpperCase() ?? '?';
    final monogram = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: plainGuardian ? ZyraColors.ivoryTop : null,
        border: plainGuardian
            ? null
            : Border.all(
                color:
                    ringColor ?? const Color(0xFFA9792E).withValues(alpha: .7),
              ),
      ),
      child:
          child ??
          Text(
            initial,
            textScaler: textScaler,
            style: ZyraText.heading(
              size: fontSize,
              color: plainGuardian
                  ? ZyraColors.secondaryText
                  : ZyraColors.journeyGold,
            ).copyWith(fontWeight: weight),
          ),
    );
    return hasGuardianRing
        ? Semantics(
            label: '$name, Guardian One',
            image: true,
            excludeSemantics: true,
            child: monogram,
          )
        : plainGuardian
        ? ZyraFloatingSurface(circle: true, child: monogram)
        : monogram;
  }
}

class ZyraMonogramHead extends StatelessWidget {
  const ZyraMonogramHead({
    super.key,
    required this.name,
    required this.title,
    required this.eyebrow,
    this.monogramKey,
  });
  final String name, title, eyebrow;
  final Key? monogramKey;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ZyraGoldRingMonogram(
        key: monogramKey,
        name: name,
        size: 96,
        fontSize: 44,
        ringColor: ZyraColors.journeyGold,
        weight: FontWeight.w300,
        textScaler: TextScaler.noScaling,
      ),
      const SizedBox(height: 14),
      ZyraDeveloperTitle(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: ZyraText.heading(
            size: 24,
          ).copyWith(fontWeight: FontWeight.w300, height: 1.2),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        eyebrow,
        textAlign: TextAlign.center,
        style: ZyraText.body(
          size: 11,
          color: ZyraColors.goldText,
        ).copyWith(letterSpacing: 1.1, height: 1.45),
      ),
    ],
  );
}

class ZyraMonogramCard extends StatelessWidget {
  const ZyraMonogramCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 20,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: child,
    ),
  );
}
