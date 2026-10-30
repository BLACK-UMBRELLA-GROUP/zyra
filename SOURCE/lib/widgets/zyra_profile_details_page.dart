// Public identity and caller-rendered photo presentation only: no services,
// private answers, photo lookup or URL construction.
import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_profile_image.dart';
import 'zyra_profiles_components.dart';

/// The first page of the current Profiles gallery. Missing public labels stay
/// missing; this widget never infers heritage from compatibility or identity.
class ZyraProfileDetailsPage extends StatelessWidget {
  const ZyraProfileDetailsPage({
    super.key,
    required this.profile,
    this.firstPhoto,
  });

  final SeekerProfile profile;

  /// The caller's existing first-photo renderer. A source reference alone
  /// never admits an image or initiates a lookup in this presenter.
  final Widget? firstPhoto;

  static const _personIcon = Icon(
    Icons.person_outline,
    size: 29,
    color: ZyraColors.journeyGold,
  );

  Widget _photo(Widget rendered) {
    if (rendered is Image) {
      // Preserve the caller's admitted provider, but keep old frames and its
      // gallery placeholder out of this person's small identity circle.
      return Image(
        key: rendered.key,
        image: rendered.image,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        color: rendered.color,
        opacity: rendered.opacity,
        colorBlendMode: rendered.colorBlendMode,
        filterQuality: rendered.filterQuality,
        isAntiAlias: rendered.isAntiAlias,
        excludeFromSemantics: true,
        gaplessPlayback: false,
        frameBuilder: (_, child, frame, synchronous) =>
            frame != null || synchronous ? child : _personIcon,
        errorBuilder: (_, _, _) => _personIcon,
      );
    }
    return ZyraProfileImageFallback(fallback: _personIcon, child: rendered);
  }

  @override
  Widget build(BuildContext context) {
    final surname = profile.surnameLine?.trim();
    final nationality = profile.publicNationality?.trim();
    final ethnicity = profile.publicEthnicity?.trim();
    final city = profile.city.trim();
    final facts = <(String, String)>[
      if (profile.age > 0) ('Age', '${profile.age}'),
      if (city.isNotEmpty && city != '—') ('Location', city),
      if (nationality?.isNotEmpty ?? false) ('Nationality', nationality!),
      if (ethnicity?.isNotEmpty ?? false) ('Ethnicity', ethnicity!),
    ];
    return ZyraProfilesDetailsContent(
      surfaceKey: ValueKey('concept_browse_details_${profile.id}'),
      scrollKey: ValueKey('concept_browse_details_scroll_${profile.id}'),
      children: [
        ExcludeSemantics(
          child: Container(
            key: ValueKey('concept_browse_details_avatar_${profile.id}'),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ZyraColors.journeyGold.withValues(alpha: .65),
              ),
              boxShadow: [
                BoxShadow(
                  color: ZyraColors.journeyGold.withValues(alpha: .07),
                  blurRadius: 24,
                ),
              ],
            ),
            child: firstPhoto == null
                ? _personIcon
                : Padding(
                    // Container includes its one-point ring
                    // before this two-point clear inner gap.
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      key: ValueKey(
                        'concept_browse_details_avatar_photo_${profile.id}',
                      ),
                      child: KeyedSubtree(
                        key: ValueKey((profile.id, profile.photos.firstOrNull)),
                        child: _photo(firstPhoto!),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          profile.firstName,
          textAlign: TextAlign.center,
          style: ZyraText.heading(size: 34),
        ),
        if (surname?.isNotEmpty ?? false) ...[
          const SizedBox(height: 2),
          Text(
            surname!,
            textAlign: TextAlign.center,
            style: ZyraText.heading(size: 22),
          ),
        ],
        const SizedBox(height: 24),
        for (final (label, value) in facts)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: ZyraColors.ink(.13))),
            ),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      label,
                      style: ZyraText.body(
                        size: 13,
                        color: ZyraColors.ink(.75),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: ZyraText.body(size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
