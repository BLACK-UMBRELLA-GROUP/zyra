import 'zyra_floating_surface.dart';
import 'zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../services/zyra_wali_link_service.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_profile_image.dart';

/// Linked-Seeker identity, not a Journey counterpart or authority summary.
class GuardianDashboardProfileCard extends StatelessWidget {
  const GuardianDashboardProfileCard({
    super.key,
    required this.person,
    this.profile,
    this.detailsLoading = false,
    this.onViewProfile,
  });

  final WaliLinkedPerson person;
  final SeekerProfile? profile;
  final bool detailsLoading;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context) {
    // Reject even an accidentally mismatched injected model at presentation.
    final details = profile?.id == person.id ? profile : null;
    final photo = details?.photoUrl ?? '';
    final relationship =
        person.relationshipLabel ?? 'Relationship not recorded';
    final role = person.isMain ? 'Main Guardian' : 'Additional Guardian';
    final age = details != null && details.age > 0
        ? '${details.age} years'
        : 'Age unavailable';
    final city = details?.city.trim() ?? '';
    final location = city.isEmpty || city == '—'
        ? 'Location unavailable'
        : city;

    return ZyraFloatingSurface(
      radius: 22,
      circle: false,
      gold: false,
      child: Container(
        key: ValueKey('guardian-dashboard-seeker-snapshot-${person.id}'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ZyraColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Profile photo of ${person.firstName}',
                  image: true,
                  child: Container(
                    key: ValueKey(
                      'guardian-dashboard-profile-avatar-${person.id}',
                    ),
                    width: 62,
                    height: 62,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ZyraColors.journeyGold.withValues(alpha: .48),
                      ),
                    ),
                    child: ClipOval(
                      child: photo.isEmpty
                          ? ColoredBox(
                              color: ZyraColors.surfaceEmphasisFill,
                              child: Center(
                                child: Text(
                                  person.firstName.isEmpty
                                      ? '?'
                                      : person.firstName.characters.first,
                                  style: ZyraText.heading(size: 24),
                                ),
                              ),
                            )
                          : ZyraProfileImage(photo, width: 58, height: 58),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.firstName, style: ZyraText.heading(size: 18)),
                      const SizedBox(height: 3),
                      Semantics(
                        label:
                            'Your relationship to ${person.firstName}: '
                            '$relationship. Your role: $role.',
                        excludeSemantics: true,
                        child: Text(
                          '$relationship · $role',
                          style: ZyraText.subtext(size: 11.5),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        detailsLoading && details == null
                            ? 'Loading profile details…'
                            : '$age · $location',
                        style: ZyraText.subtext(
                          size: 11.5,
                          color: ZyraColors.ink(.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: ValueKey('guardian-dashboard-view-profile-${person.id}'),
                onPressed: ZyraTapFeedback.onTap(
                  context,
                  detailsLoading || details == null ? null : onViewProfile,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ZyraColors.journeyGold,
                  disabledForegroundColor: ZyraColors.ink(.36),
                  minimumSize: const Size(48, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'View profile',
                        style: ZyraText.body(
                          size: 12,
                          color:
                              detailsLoading ||
                                  details == null ||
                                  onViewProfile == null
                              ? ZyraColors.ink(.36)
                              : ZyraColors.goldText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 17),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
