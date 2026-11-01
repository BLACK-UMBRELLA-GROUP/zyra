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
    this.weight = FontWeight.w200,
    this.textScaler,
  });
  final String name;
  final double size, fontSize;
  final Color? ringColor;
  final FontWeight weight;
  final TextScaler? textScaler;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: ringColor ?? const Color(0xFFA9792E).withValues(alpha: .7),
      ),
    ),
    child: Text(
      name.characters.firstOrNull ?? '',
      textScaler: textScaler,
      style: ZyraText.heading(
        size: fontSize,
        color: ZyraColors.journeyGold,
      ).copyWith(fontWeight: weight),
    ),
  );
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
      Text(
        title,
        textAlign: TextAlign.center,
        style: ZyraText.heading(
          size: 24,
        ).copyWith(fontWeight: FontWeight.w300, height: 1.2),
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
