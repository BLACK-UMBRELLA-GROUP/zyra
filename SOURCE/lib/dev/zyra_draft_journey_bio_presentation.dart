import 'package:flutter/material.dart';

import '../data/zyra_journey_life_snapshot.dart';
import '../models/journey_bio.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_state_widgets.dart';
import 'zyra_view_request_draft_model.dart' show draftProfiles;

/// A single owner-selected, canonical Journey Bio fact.
class ZyraDraftJourneyBioField {
  const ZyraDraftJourneyBioField._({
    required this.id,
    required this.section,
    required this.label,
    required this.value,
  });

  final String id;
  final String section;
  final String label;
  final String value;
}

/// Only the information already admitted for one exact Journey subject.
///
/// Constructing this projection does not establish permission to read a Bio.
/// The caller must first establish the Journey stage and mutual profile-sharing
/// grant. The original biography, hidden values and visibility choices are not
/// retained here. Reviewed/nonempty content alone is never treated as consent.
class ZyraDraftJourneyBioProjection {
  ZyraDraftJourneyBioProjection._({
    required this.subjectId,
    required this.aboutMe,
    required List<ZyraDraftJourneyBioField> fields,
  }) : fields = List<ZyraDraftJourneyBioField>.unmodifiable(fields);

  factory ZyraDraftJourneyBioProjection.fromJourneyBio({
    required String subjectId,
    required JourneyBio bio,
  }) {
    if (subjectId.trim().isEmpty) {
      throw ArgumentError.value(
        subjectId,
        'subjectId',
        'Must identify a subject',
      );
    }
    final about = bio.aboutMe.trim();
    return ZyraDraftJourneyBioProjection._(
      subjectId: subjectId,
      aboutMe: bio.showAboutMe && about.isNotEmpty ? about : null,
      fields: [
        for (final definition in journeyBioFieldDefinitions)
          if (bio.visibleFieldIds.contains(definition.id) &&
              (bio.fieldValues[definition.id] ?? '').trim().isNotEmpty)
            ZyraDraftJourneyBioField._(
              id: definition.id,
              section: definition.section,
              label: definition.label,
              value: bio.fieldValues[definition.id]!.trim(),
            ),
      ],
    );
  }

  final String subjectId;
  final String? aboutMe;
  final List<ZyraDraftJourneyBioField> fields;

  bool get isEmpty => aboutMe == null && fields.isEmpty;

  /// Explicitly opted-in offline facts for exact invented DraftProfile IDs.
  ///
  /// This is not a peer reader or a grant. It never reads an account's own Bio,
  /// accepts a partial/real ID, or substitutes fixture data by default. Only
  /// four deliberately selected legacy fixture facts are shared, not the
  /// legacy mock's all-field defaults or its unrelated 1,000-character limit.
  static ZyraDraftJourneyBioProjection? fixtureFor(
    String subjectId, {
    bool useLegacyFixture = false,
  }) {
    if (!useLegacyFixture ||
        !draftProfiles.any((profile) => profile.id == subjectId)) {
      return null;
    }
    const selectedIds = <String>{
      'occupation',
      'education',
      'future_children',
      'home',
    };
    const biography =
        'I value faith, family and a peaceful home. I am looking for a marriage '
        'built on kindness, honesty and teamwork, where we can laugh together '
        'and help each other grow.';
    assert(biography.length <= JourneyBio.characterLimit);
    return ZyraDraftJourneyBioProjection.fromJourneyBio(
      subjectId: subjectId,
      bio: JourneyBio(
        aboutMe: biography,
        showAboutMe: true,
        reviewed: true,
        fieldValues: {
          for (final field in ZyraJourneyLifeSnapshotMock.fields)
            if (selectedIds.contains(field.id)) field.id: field.value,
        },
        visibleFieldIds: selectedIds,
      ),
    );
  }
}

/// A data-only Journey Bio reader, also usable inside the Journey step.
///
/// Null means protected/unavailable, whereas an admitted empty projection means
/// no details were shared. Portraits are optional caller-owned widgets, never
/// fetched here. No control in this view can reveal, edit or advance a Journey.
class ZyraDraftJourneyBioPresentation extends StatelessWidget {
  const ZyraDraftJourneyBioPresentation({
    super.key,
    required this.subjectId,
    required this.firstName,
    required this.projection,
    this.portrait,
    this.ownedViewport = true,
    this.showTitle = true,
    this.showProfileHeader = true,
  });

  final String subjectId;
  final String firstName;
  final ZyraDraftJourneyBioProjection? projection;
  final Widget? portrait;
  final bool ownedViewport;
  final bool showTitle;
  final bool showProfileHeader;

  @override
  Widget build(BuildContext context) {
    final supplied = projection;
    final admitted = supplied != null && supplied.subjectId == subjectId
        ? supplied
        : null;
    final sections = <String, List<ZyraDraftJourneyBioField>>{};
    for (final field in admitted?.fields ?? <ZyraDraftJourneyBioField>[]) {
      sections.putIfAbsent(field.section, () => []).add(field);
    }
    final content = Column(
      key: ValueKey('draft_journey_bio_$subjectId'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            'Journey Bio',
            key: const ValueKey('draft_journey_bio_title'),
            style: ZyraText.pageTitle(),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 20),
        ],
        if (showProfileHeader) ...[
          _ProfileHeader(
            subjectId: subjectId,
            firstName: firstName,
            // A mismatched or unavailable projection must not paint another
            // subject's supplied portrait either.
            portrait: admitted == null ? null : portrait,
          ),
          const SizedBox(height: 24),
        ],
        if (admitted == null)
          const _BioStatus(unavailable: true)
        else if (admitted.isEmpty)
          const _BioStatus(unavailable: false)
        else ...[
          if (admitted.aboutMe != null) ...[
            const _SectionHeading(label: 'About me'),
            const SizedBox(height: 10),
            _BioSurface(
              child: Text(
                admitted.aboutMe!,
                key: const ValueKey('draft_journey_bio_about'),
                style: ZyraText.body(size: 14).copyWith(height: 1.65),
              ),
            ),
            if (sections.isNotEmpty) const SizedBox(height: 24),
          ],
          for (final entry in sections.entries) ...[
            _SectionHeading(label: entry.key),
            const SizedBox(height: 10),
            _BioSurface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < entry.value.length; index++) ...[
                    if (index > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Divider(
                          height: 1,
                          color: ZyraColors.surfaceBorder,
                        ),
                      ),
                    _BioField(field: entry.value[index]),
                  ],
                ],
              ),
            ),
            if (entry.key != sections.keys.last) const SizedBox(height: 24),
          ],
        ],
      ],
    );
    if (!ownedViewport) return content;
    return SafeArea(
      child: SingleChildScrollView(
        key: PageStorageKey('draft_journey_bio_scroll_$subjectId'),
        primary: false,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: content,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.subjectId,
    required this.firstName,
    this.portrait,
  });

  final String subjectId;
  final String firstName;
  final Widget? portrait;

  @override
  Widget build(BuildContext context) {
    final name = firstName.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Container(
            key: ValueKey('draft_journey_bio_portrait_$subjectId'),
            width: 88,
            height: 108,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: ZyraColors.surfaceFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child:
                portrait ??
                Center(
                  child: Text(
                    name.isEmpty ? '—' : name.characters.first.toUpperCase(),
                    style: ZyraText.heading(
                      size: 32,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Journey profile' : name,
                key: const ValueKey('draft_journey_bio_name'),
                style: ZyraText.heading(size: 25),
              ),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: Container(
                  height: 2,
                  width: 32,
                  decoration: BoxDecoration(
                    color: ZyraColors.journeyGold.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: ZyraText.subtext(size: 13, color: ZyraColors.journeyGold),
  );
}

class _BioSurface extends StatelessWidget {
  const _BioSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: ZyraColors.surfaceBorder),
    ),
    child: child,
  );
}

class _BioField extends StatelessWidget {
  const _BioField({required this.field});
  final ZyraDraftJourneyBioField field;

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey('draft_journey_bio_field_${field.id}'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(field.label, style: ZyraText.subtext(size: 12)),
      const SizedBox(height: 5),
      Text(field.value, style: ZyraText.body(size: 14.5).copyWith(height: 1.4)),
    ],
  );
}

class _BioStatus extends StatelessWidget {
  const _BioStatus({required this.unavailable});
  final bool unavailable;

  @override
  Widget build(BuildContext context) => !unavailable
      ? const ZyraEmptyState(
          key: ValueKey('draft_journey_bio_empty'),
          icon: Icons.notes_outlined,
          title: 'No details shared yet.',
          message: '',
        )
      : _BioSurface(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.lock_outline,
                    size: 28,
                    color: ZyraColors.journeyGold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Journey Bio is unavailable.',
                  key: const ValueKey('draft_journey_bio_unavailable'),
                  textAlign: TextAlign.center,
                  style: ZyraText.body(size: 15),
                ),
              ],
            ),
          ),
        );
}
