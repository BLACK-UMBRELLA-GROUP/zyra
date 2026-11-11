// Public identity and caller-rendered photo presentation only.
import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../models/seeker_profile.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_profile_image.dart';

/// LOCK 4 V3, design 2. Only the caller's public profile fields and admitted
/// first photo reach this face. No private answers or photo lookup here.
class ZyraProfileDetailsPage extends StatelessWidget {
  const ZyraProfileDetailsPage({
    super.key,
    required this.profile,
    this.firstPhoto,
  });

  final SeekerProfile profile;
  final Widget? firstPhoto;

  static const double _avatarSize = 124;
  static const double _smallerAvatarSize = 96;
  static const double _ringWidth = 1.5;
  static const double _photoGap = 2;
  static const photoAlignment = Alignment(0, -.7);

  static double photoSizeFor(ZyraPlan? plan) =>
      _avatarSize - _photoInset(plan) * 2;

  static double _photoInset(ZyraPlan? plan) =>
      plan == ZyraPlan.basic ? 0 : _ringWidth + _photoGap;

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
    // The unavailable plan still keeps the pre-existing decorative ring.
    // Only a verified Seeker One plan gets the accompanying announcement.
    final plan = profile.seekerPlan;
    final showRing = plan != ZyraPlan.basic;
    final fallback = ColoredBox(
      color: ZyraColors.avatarSand,
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
      child: avatar,
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
      decoration: BoxDecoration(color: ZyraColors.surfaceFill),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              MediaQuery.textScalerOf(context).scale(16) > 16 &&
              constraints.maxHeight < 560;
          final avatarSize = compact ? _smallerAvatarSize : _avatarSize;
          return SingleChildScrollView(
            key: ValueKey('concept_browse_details_scroll_${profile.id}'),
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _avatar(avatarSize),
                              const SizedBox(height: 16),
                              Text(
                                profile.firstName,
                                textAlign: TextAlign.center,
                                style: ZyraText.heading(
                                  size: 34,
                                ).copyWith(height: 1.05),
                              ),
                              if (surname?.isNotEmpty ?? false)
                                Text(
                                  surname!,
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
                      if (facts.isNotEmpty) const SizedBox(height: 4),
                      for (int i = 0; i < facts.length; i += 2) ...[
                        if (i != 0) const SizedBox(height: 10),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _DetailTile(facts[i])),
                              const SizedBox(width: 10),
                              Expanded(
                                child: i + 1 < facts.length
                                    ? _DetailTile(facts[i + 1])
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Container(
      key: ValueKey('profile-detail-tile-${fact.$1}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.$1,
            style: ZyraText.body(
              size: 10.5,
              color: ZyraColors.secondaryText,
            ).copyWith(letterSpacing: 1, height: 1.05),
          ),
          Text(fact.$2, style: ZyraText.body(size: 16).copyWith(height: 1.05)),
        ],
      ),
    ),
  );
}
