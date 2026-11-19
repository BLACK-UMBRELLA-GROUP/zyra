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
import 'zyra_profile_name_block.dart';

/// LOCK 4 V4, design 2. Only the caller's public profile fields and admitted
/// first photo reach this face. No private answers or photo lookup here.
class ZyraProfileDetailsPage extends StatelessWidget {
  const ZyraProfileDetailsPage({
    super.key,
    required this.profile,
    this.firstPhoto,
    this.fixedCard = false,
    this.requestAction,
    this.showUnverifiedRing = true,
  });

  final SeekerProfile profile;
  final Widget? firstPhoto;
  final bool fixedCard;
  final Widget? requestAction;

  /// Other-member cards retain the decorative ring while their authorized
  /// projection lacks a plan (Q84). Own Preview has a verified-plan source.
  final bool showUnverifiedRing;

  static const double _avatarSize = 124;
  static const double _smallerAvatarSize = 96;
  static const double _ringWidth = 1.5;
  static const double _photoGap = 2;
  static const double _tileGap = 12;
  static const double _horizontalInset = 22;
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
    final fallback = ColoredBox(
      color: basic ? ZyraColors.ivoryTop : ZyraColors.avatarSand,
      child: Center(
        child: Text(
          profile.firstName.trim().characters.firstOrNull?.toUpperCase() ?? '?',
          textScaler: TextScaler.noScaling,
          style: ZyraText.heading(size: size * .38, color: ZyraColors.espresso),
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
    final surname = profile.surnameLine?.trim();
    final nationality = profile.publicNationality?.trim();
    final ethnicity = profile.publicEthnicity?.trim();
    final city = profile.city.trim();
    final facts = [
      if (profile.age > 0) ('AGE', '${profile.age}'),
      if (city.isNotEmpty && city != '—') ('LOCATION', city),
      if (nationality?.isNotEmpty ?? false) ('NATIONALITY', nationality!),
      if (ethnicity?.isNotEmpty ?? false) ('ETHNICITY', ethnicity!),
    ];
    return DecoratedBox(
      key: ValueKey('concept_browse_details_${profile.id}'),
      decoration: const BoxDecoration(color: ZyraColors.cardSurface),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              MediaQuery.textScalerOf(context).scale(16) > 16 &&
              constraints.maxHeight < 560;
          final avatarSize = compact ? _smallerAvatarSize : _avatarSize;
          final tileWidth =
              (constraints.maxWidth - 2 * _horizontalInset - _tileGap) / 2;
          final rowHeight = facts.fold(
            (math.max(196.0, constraints.maxHeight * .4) - _tileGap) / 2,
            (height, fact) => math.max(
              height,
              _DetailTile.heightFor(context, fact, tileWidth),
            ),
          );
          return SingleChildScrollView(
            key: ValueKey('concept_browse_details_scroll_${profile.id}'),
            physics: fixedCard ? ZyraMotion.fixedCardScrollPhysics : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalInset,
                    28,
                    _horizontalInset,
                    22,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _avatar(avatarSize),
                              const SizedBox(height: 16),
                              ZyraFittedProfileFirstName(
                                profile.firstName,
                                maxWidth:
                                    constraints.maxWidth - 2 * _horizontalInset,
                                semanticsLabel:
                                    '${profile.firstName} ${surname ?? ''}'
                                        .trim(),
                                textAlign: TextAlign.center,
                                style: ZyraText.heading(
                                  size: 34,
                                ).copyWith(height: 1.05),
                              ),
                              if (surname?.isNotEmpty ?? false)
                                Text(
                                  surname!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  semanticsLabel: '',
                                  textAlign: TextAlign.center,
                                  style: ZyraText.heading(
                                    size: 22,
                                    color: ZyraColors.secondaryText,
                                  ).copyWith(height: 1.05),
                                ),
                            ],
                          ),
                        ),
                      ),
                      for (int i = 0; i < facts.length; i += 2) ...[
                        if (i != 0) const SizedBox(height: _tileGap),
                        ConstrainedBox(
                          constraints: BoxConstraints(minHeight: rowHeight),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _DetailTile(facts[i])),
                                const SizedBox(width: _tileGap),
                                Expanded(
                                  child: i + 1 < facts.length
                                      ? _DetailTile(facts[i + 1])
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (requestAction case final action?) ...[
                        const SizedBox(height: _tileGap),
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
  const _DetailTile(this.fact);

  final (String, String) fact;
  static const _padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const _gap = 6.0;

  static TextStyle get _labelStyle => ZyraText.body(
    size: 11,
    color: ZyraColors.secondaryText,
  ).copyWith(letterSpacing: 1.1);
  static TextStyle get _valueStyle => ZyraText.button(
    size: 18,
    color: ZyraColors.foregroundBody,
  ).copyWith(letterSpacing: 0, height: 1.2);

  static double heightFor(
    BuildContext context,
    (String, String) fact,
    double tileWidth,
  ) {
    final inherited = DefaultTextStyle.of(context);
    final bold = MediaQuery.boldTextOf(context);
    TextStyle resolve(TextStyle style) {
      final effective = inherited.style.merge(style);
      return bold
          ? effective.merge(const TextStyle(fontWeight: FontWeight.bold))
          : effective;
    }

    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: inherited.textHeightBehavior,
      textWidthBasis: inherited.textWidthBasis,
    );
    final width = math.max(1.0, tileWidth - _padding.horizontal - 2);
    painter.text = TextSpan(text: fact.$1, style: resolve(_labelStyle));
    painter.layout(maxWidth: width);
    final labelHeight = painter.height;
    painter.text = TextSpan(text: fact.$2, style: resolve(_valueStyle));
    painter.layout(maxWidth: width);
    final valueHeight = painter.height;
    painter.dispose();
    return _padding.vertical + 2 + labelHeight + _gap + valueHeight;
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Container(
      key: ValueKey('profile-detail-tile-${fact.$1}'),
      padding: _padding,
      decoration: BoxDecoration(
        color: ZyraColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.$1, style: _labelStyle),
          const SizedBox(height: _gap),
          Text(fact.$2, style: _valueStyle),
        ],
      ),
    ),
  );
}
