// Public identity and caller-rendered photo presentation only.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../models/seeker_profile.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../theme/zyra_motion.dart';
import 'zyra_floating_surface.dart';
import 'zyra_profile_image.dart';

/// LOCK 4 V5. Only the caller's public profile fields and admitted
/// first photo reach this face. No private answers or photo lookup here.
class ZyraProfileDetailsPage extends StatelessWidget {
  const ZyraProfileDetailsPage({
    super.key,
    required this.profile,
    this.firstPhoto,
    this.fixedCard = false,
    this.requestAction,
    this.showUnverifiedRing = true,
    this.onCompatibility,
    this.introductionByline,
  });

  final SeekerProfile profile;
  final Widget? firstPhoto;
  final bool fixedCard;
  final Widget? requestAction;
  final VoidCallback? onCompatibility;
  final String? introductionByline;

  /// Other-member cards retain the decorative ring while their authorized
  /// projection lacks a plan (Q84). Own Preview has a verified-plan source.
  final bool showUnverifiedRing;

  static const double _avatarSize = 150;
  static const double _smallerAvatarSize = 72;
  static const double _ringWidth = 1.5;
  static const double _photoGap = 3;
  static const double _tileGap = 10;
  static const double _horizontalInset = 16;
  static const photoAlignment = Alignment(0, -.7);

  static double photoSizeFor(
    ZyraPlan? plan, {
    bool showUnverifiedRing = true,
  }) =>
      _avatarSize -
      (_hasRing(plan, showUnverifiedRing) ? 2 * (_ringWidth + _photoGap) : 0);

  static bool _hasRing(ZyraPlan? plan, bool showUnverifiedRing) =>
      plan == ZyraPlan.one || (plan == null && showUnverifiedRing);

  Widget _photo(Widget rendered, Widget fallback) {
    if (rendered is Image) {
      return Image(
        key: rendered.key,
        image: rendered.image,
        fit: BoxFit.cover,
        alignment: photoAlignment,
        color: rendered.color,
        opacity: rendered.opacity,
        colorBlendMode: rendered.colorBlendMode,
        filterQuality: rendered.filterQuality,
        isAntiAlias: rendered.isAntiAlias,
        excludeFromSemantics: true,
        gaplessPlayback: false,
        frameBuilder: (_, child, frame, synchronous) =>
            frame != null || synchronous ? child : fallback,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return ZyraProfileImageFallback(fallback: fallback, child: rendered);
  }

  Widget _avatar(double size) {
    final plan = profile.seekerPlan;
    final showRing = _hasRing(plan, showUnverifiedRing);
    final basic = plan == ZyraPlan.basic;
    final fallback = const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6E5C9), Color(0xFFEFD9C0)],
        ),
      ),
    );
    final avatar = Container(
      key: ValueKey('concept_browse_details_avatar_${profile.id}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: showRing ? ZyraColors.ivoryTop : null,
        shape: BoxShape.circle,
        border: showRing
            ? Border.all(
                width: _ringWidth,
                color: const Color.fromRGBO(169, 121, 46, .75),
              )
            : null,
      ),
      padding: EdgeInsets.all(showRing ? _photoGap : 0),
      child: firstPhoto == null
          ? ClipOval(child: fallback)
          : ClipOval(
              key: ValueKey(
                'concept_browse_details_avatar_photo_${profile.id}',
              ),
              child: KeyedSubtree(
                key: ValueKey((profile.id, profile.photos.firstOrNull)),
                child: _photo(firstPhoto!, fallback),
              ),
            ),
    );
    if (plan == null) return ExcludeSemantics(child: avatar);
    return Semantics(
      container: true,
      image: true,
      excludeSemantics: true,
      label: plan == ZyraPlan.one
          ? 'Profile photo, ${ZyraMembershipCatalog.seekerOneTitle}'
          : 'Profile photo',
      child: basic && firstPhoto == null
          ? ZyraFloatingSurface(circle: true, child: avatar)
          : avatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final facts = <(String, String)>[
      if (profile.age > 0) ('AGE', '${profile.age}'),
      if (profile.city.trim().isNotEmpty && profile.city != '—')
        ('LOCATION', profile.city.trim()),
      if (profile.publicNationality?.trim().isNotEmpty == true)
        ('NATIONALITY', profile.publicNationality!.trim()),
      if (profile.publicEthnicity?.trim().isNotEmpty == true)
        ('ETHNICITY', profile.publicEthnicity!.trim()),
    ];
    return DecoratedBox(
      key: ValueKey('concept_browse_details_${profile.id}'),
      decoration: const BoxDecoration(color: ZyraColors.cardSurface),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final avatarSize = math.max(
            _smallerAvatarSize,
            math.min(
              _avatarSize,
              constraints.maxHeight * (scale > 1.2 ? .18 : .23),
            ),
          );
          final tileWidth =
              (constraints.maxWidth - 2 * _horizontalInset - _tileGap) / 2;
          final fullWidth = constraints.maxWidth - 2 * _horizontalInset;
          final rows = <({List<(String, String)> facts, bool fullWidth})>[];
          var pending = <(String, String)>[];
          for (final fact in facts) {
            if (_DetailTile.needsFullWidth(context, fact, tileWidth)) {
              if (pending.isNotEmpty) {
                rows.add((facts: pending, fullWidth: false));
                pending = [];
              }
              rows.add((facts: [fact], fullWidth: true));
            } else {
              pending.add(fact);
              if (pending.length == 2) {
                rows.add((facts: pending, fullWidth: false));
                pending = [];
              }
            }
          }
          if (pending.isNotEmpty) {
            rows.add((facts: pending, fullWidth: false));
          }
          return SingleChildScrollView(
            key: ValueKey('concept_browse_details_scroll_${profile.id}'),
            physics: fixedCard ? ZyraMotion.fixedCardScrollPhysics : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalInset,
                    20,
                    _horizontalInset,
                    16,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _avatar(avatarSize),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${profile.firstName} ${profile.surnameLine ?? ''}'
                                          .trim(),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      style: ZyraText.heading(
                                        size: 28,
                                      ).copyWith(height: 1.1),
                                    ),
                                  ),
                                  if (profile.seekerPlan == ZyraPlan.one) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: ZyraColors.journeyGold,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        'ONE',
                                        style: ZyraText.body(
                                          size: 11,
                                          color: ZyraColors.journeyGold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (introductionByline case final byline?) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Put forward by $byline',
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: ZyraText.body(
                                    size: 14,
                                    color: ZyraColors.journeyGold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var row = 0; row < rows.length; row++) ...[
                        if (row > 0) const SizedBox(height: _tileGap),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _DetailTile(
                                rows[row].facts.first,
                                tileWidth: rows[row].fullWidth
                                    ? fullWidth
                                    : tileWidth,
                              ),
                            ),
                            if (!rows[row].fullWidth) ...[
                              const SizedBox(width: _tileGap),
                              Expanded(
                                child: rows[row].facts.length == 2
                                    ? _DetailTile(
                                        rows[row].facts[1],
                                        tileWidth: tileWidth,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (profile.mainGuardianRelationship
                          case final relation?) ...[
                        const SizedBox(height: _tileGap),
                        _InfoRow(
                          key: const ValueKey(
                            'profile-detail-main-guardian-row',
                          ),
                          availableTextWidth: constraints.maxWidth - 92,
                          icon: Icons.groups_outlined,
                          title: 'Main Guardian · $relation',
                          subtitle:
                              'Walks every Journey with ${profile.firstName}',
                          trailing: 'Verified',
                        ),
                      ],
                      const SizedBox(height: _tileGap),
                      _InfoRow(
                        key: const ValueKey('profile-detail-compatibility-row'),
                        availableTextWidth: constraints.maxWidth - 92,
                        icon: Icons.auto_graph_outlined,
                        title: 'Compatibility score',
                        subtitle: 'See how your answers match',
                        onTap: onCompatibility,
                      ),
                      if (requestAction case final action?) ...[
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: action),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile(this.fact, {required this.tileWidth});

  final (String, String) fact;
  final double tileWidth;
  static const _padding = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const _gap = 6.0;

  static TextStyle get _labelStyle => ZyraText.body(
    size: 11,
    color: ZyraColors.secondaryText,
  ).copyWith(letterSpacing: 1.1);
  static TextStyle get _valueStyle => ZyraText.button(
    size: 15,
    color: ZyraColors.foregroundBody,
  ).copyWith(letterSpacing: 0, height: 1.2);

  static double _textWidth(double tileWidth) =>
      math.max(1.0, tileWidth - _padding.horizontal - 2);

  static TextStyle _resolvedStyle(BuildContext context, TextStyle style) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    return MediaQuery.boldTextOf(context)
        ? effective.merge(const TextStyle(fontWeight: FontWeight.bold))
        : effective;
  }

  static TextPainter _painter(BuildContext context) {
    final inherited = DefaultTextStyle.of(context);
    return TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: inherited.textHeightBehavior,
      textWidthBasis: inherited.textWidthBasis,
    );
  }

  static bool needsFullWidth(
    BuildContext context,
    (String, String) fact,
    double tileWidth,
  ) {
    final painter = _painter(context);
    try {
      for (final (text, style) in [
        (fact.$1, _labelStyle),
        (fact.$2, _valueStyle),
      ]) {
        for (final word in text.split(RegExp(r'\s+'))) {
          painter.text = TextSpan(
            text: word,
            style: _resolvedStyle(context, style),
          );
          painter.layout();
          if (painter.width > _textWidth(tileWidth)) return true;
        }
      }
      return false;
    } finally {
      painter.dispose();
    }
  }

  // Keep native wrapping when it already respects whole words. Explicit line
  // breaks prevent the paragraph engine splitting a name at a stored hyphen.
  static ({String text, bool explicitLines}) _wholeWords(
    BuildContext context,
    String text,
    TextStyle style,
    double tileWidth,
  ) {
    final width = _textWidth(tileWidth);
    final effective = _resolvedStyle(context, style);
    final painter = _painter(context);
    try {
      painter.text = TextSpan(text: text, style: effective);
      painter.layout(maxWidth: width);
      final split = RegExp(r'\S+').allMatches(text).any((word) {
        final boxes = painter.getBoxesForSelection(
          TextSelection(baseOffset: word.start, extentOffset: word.end),
        );
        return boxes.any((box) => (box.top - boxes.first.top).abs() > .01);
      });
      if (!split) return (text: text, explicitLines: false);
      final lines = <String>[];
      for (final paragraph in text.split('\n')) {
        var line = '';
        for (final word in paragraph.split(RegExp(r'\s+'))) {
          if (word.isEmpty) continue;
          final candidate = line.isEmpty ? word : '$line $word';
          painter.text = TextSpan(text: candidate, style: effective);
          painter.layout();
          if (line.isNotEmpty && painter.width > width) {
            lines.add(line);
            line = word;
          } else {
            line = candidate;
          }
        }
        lines.add(line);
      }
      return (text: lines.join('\n'), explicitLines: true);
    } finally {
      painter.dispose();
    }
  }

  Text _text(BuildContext context, String value, TextStyle style) {
    final wrapped = _wholeWords(context, value, style, tileWidth);
    return Text(
      wrapped.text,
      semanticsLabel: wrapped.explicitLines ? value : null,
      softWrap: wrapped.explicitLines ? false : null,
      overflow: wrapped.explicitLines ? TextOverflow.visible : null,
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Container(
      key: ValueKey('profile-detail-tile-${fact.$1}'),
      padding: _padding,
      decoration: BoxDecoration(
        color: ZyraColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142B2420),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(context, fact.$1, _labelStyle),
          const SizedBox(height: _gap),
          _text(context, fact.$2, _valueStyle),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    super.key,
    required this.availableTextWidth,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final double availableTextWidth;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.ivoryTop,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: ZyraColors.journeyGold, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Builder(
                builder: (context) {
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  final stackVerified =
                      trailing != null && availableTextWidth < 250 * scale;
                  final titleText = Text(
                    title,
                    softWrap: true,
                    style: ZyraText.body(size: 15, color: ZyraColors.espresso),
                  );
                  final verifiedText = trailing == null
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFF2D704C),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                trailing!,
                                softWrap: true,
                                style: ZyraText.body(
                                  size: 12,
                                  color: const Color(0xFF2D704C),
                                ),
                              ),
                            ),
                          ],
                        );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stackVerified) ...[
                        titleText,
                        const SizedBox(height: 3),
                        verifiedText!,
                      ] else
                        Row(
                          children: [
                            Expanded(child: titleText),
                            const SizedBox(width: 4),
                            if (verifiedText != null)
                              verifiedText
                            else
                              const Icon(
                                Icons.chevron_right,
                                color: ZyraColors.secondaryText,
                              ),
                          ],
                        ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        softWrap: true,
                        style: ZyraText.body(
                          size: 12,
                          color: ZyraColors.secondaryText,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
