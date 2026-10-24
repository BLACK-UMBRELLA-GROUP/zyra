// Public identity presentation only: no services, private answers or photos.
import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// The first page of the current Profiles gallery. Missing public labels stay
/// missing; this widget never infers heritage from compatibility or identity.
class ZyraProfileDetailsPage extends StatelessWidget {
  const ZyraProfileDetailsPage({super.key, required this.profile});

  final SeekerProfile profile;

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
    return DecoratedBox(
      key: ValueKey('concept_browse_details_${profile.id}'),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        // The shared viewport owns clipping and the single sent-only outline,
        // exactly as on photos. No second frame or rounded moving seam here.
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          key: ValueKey('concept_browse_details_scroll_${profile.id}'),
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ZyraColors.journeyGold.withValues(
                              alpha: .65,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ZyraColors.journeyGold.withValues(
                                alpha: .07,
                              ),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 29,
                          color: ZyraColors.journeyGold,
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
                          border: Border(
                            top: BorderSide(color: ZyraColors.ink(.13)),
                          ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
