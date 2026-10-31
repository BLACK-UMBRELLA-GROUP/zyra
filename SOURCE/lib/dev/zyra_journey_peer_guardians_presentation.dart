import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/zyra_guardian_info_service.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// A read-only presentation of the Guardians disclosed for one other Seeker.
///
/// The caller owns subject selection and disclosure permission. This widget
/// neither fetches information nor substitutes a roster when it is unavailable.
/// Null means protected/unavailable; an empty list means confirmed none.
class ZyraJourneyPeerGuardiansPresentation extends StatelessWidget {
  ZyraJourneyPeerGuardiansPresentation({
    super.key,
    required this.subjectId,
    required this.firstName,
    required List<GuardianInfo>? guardians,
  }) : guardians = guardians == null
           ? null
           : List<GuardianInfo>.unmodifiable([
               ...guardians.where((guardian) => guardian.isMain),
               ...guardians.where((guardian) => !guardian.isMain),
             ]);

  final String subjectId;
  final String firstName;
  final List<GuardianInfo>? guardians;

  @override
  Widget build(BuildContext context) {
    final people = guardians;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          key: ValueKey('peer_guardians_$subjectId'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Journey with $firstName',
              key: const ValueKey('peer_guardians_context'),
              style: ZyraText.subtext(size: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Guardians',
              key: const ValueKey('peer_guardians_title'),
              style: ZyraText.pageTitle(),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: people == null || people.isEmpty
                  ? _GuardianStatus(unavailable: people == null)
                  : _PeerGuardianPager(
                      // DTOs have no Guardian ID. Preserve equivalent roster
                      // rebuilds, but never carry an ordinal into a changed
                      // subject/disclosure or an altered/shrunk roster.
                      key: _PeerRosterKey(subjectId, people),
                      subjectId: subjectId,
                      people: people,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _GuardianValue = (String, String?, bool, String?, String?);

class _PeerRosterKey extends LocalKey {
  _PeerRosterKey(this.subjectId, List<GuardianInfo> people)
    : values = List<_GuardianValue>.unmodifiable([
        for (final person in people)
          (
            person.firstName,
            person.relationship,
            person.isMain,
            person.city,
            person.gender,
          ),
      ]);

  final String subjectId;
  final List<_GuardianValue> values;

  @override
  bool operator ==(Object other) =>
      other is _PeerRosterKey &&
      subjectId == other.subjectId &&
      listEquals(values, other.values);

  @override
  int get hashCode => Object.hash(subjectId, Object.hashAll(values));
}

class _PeerGuardianPager extends StatefulWidget {
  const _PeerGuardianPager({
    super.key,
    required this.subjectId,
    required this.people,
  });

  final String subjectId;
  final List<GuardianInfo> people;

  @override
  State<_PeerGuardianPager> createState() => _PeerGuardianPagerState();
}

class _PeerGuardianPagerState extends State<_PeerGuardianPager> {
  final _controller = PageController(keepPage: false);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: PageView.builder(
          key: ValueKey('peer_guardians_pager_${widget.subjectId}'),
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.people.length,
          onPageChanged: (value) {
            if (mounted && value >= 0 && value < widget.people.length) {
              setState(() => _page = value);
            }
          },
          itemBuilder: (context, index) => Semantics(
            key: ValueKey('peer_guardian_${widget.subjectId}_$index'),
            label:
                'Guardian ${index + 1} of ${widget.people.length}: '
                '${widget.people[index].firstName}',
            child: _PeerGuardianContent(
              subjectId: widget.subjectId,
              index: index,
              guardian: widget.people[index],
            ),
          ),
        ),
      ),
      if (widget.people.length > 1) ...[
        const SizedBox(height: 12),
        Semantics(
          key: ValueKey('peer_guardians_position_${widget.subjectId}'),
          liveRegion: true,
          label: 'Guardian ${_page + 1} of ${widget.people.length}',
          child: ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var index = 0; index < widget.people.length; index++)
                  AnimatedContainer(
                    key: ValueKey(
                      'peer_guardian_dot_${widget.subjectId}_$index',
                    ),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    width: index == _page ? 20 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? ZyraColors.journeyGold
                          : ZyraColors.ink(.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    ],
  );
}

class _PeerGuardianContent extends StatelessWidget {
  const _PeerGuardianContent({
    required this.subjectId,
    required this.index,
    required this.guardian,
  });

  final String subjectId;
  final int index;
  final GuardianInfo guardian;

  @override
  Widget build(BuildContext context) {
    final name = guardian.firstName.trim();
    final relationship = guardian.relationshipLabel;
    final city = guardian.city?.trim();
    final gender = switch (guardian.gender) {
      'male' => 'Male',
      'female' => 'Female',
      _ => null,
    };
    final hasCity = city != null && city.isNotEmpty;
    final initial = name.isEmpty ? 'G' : name.characters.first.toUpperCase();
    final accent = ZyraColors.journeyGold;
    final avatar = ExcludeSemantics(
      child: Container(
        key: ValueKey('peer_guardian_avatar_${subjectId}_$index'),
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ZyraColors.surfaceFill,
          border: Border.all(color: ZyraColors.surfaceEmphasisBorder),
        ),
        child: Text(
          initial,
          // Decorative artwork stays in its fixed circle; the accessible
          // name beside/below it retains full text scaling.
          textScaler: TextScaler.noScaling,
          style: ZyraText.heading(size: 24.32),
        ),
      ),
    );
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Guardian' : name,
          style: ZyraText.heading(size: 27),
        ),
        if (relationship != null) ...[
          const SizedBox(height: 3),
          Text(
            relationship,
            style: ZyraText.subtext(size: 12.5, color: ZyraColors.ink(.58)),
          ),
        ],
      ],
    );
    final stackIdentity = MediaQuery.textScalerOf(context).scale(27) > 27 * 1.3;
    // Match the main Guardian page's quiet identity, role strip and sections,
    // without mounting any owner-management widget or inventing missing data.
    // Natural reading retains full text size rather than scaling a page down.
    return SingleChildScrollView(
      key: ValueKey('peer_guardian_reader_${subjectId}_$index'),
      primary: false,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stackIdentity) ...[
            Align(alignment: Alignment.centerLeft, child: avatar),
            const SizedBox(height: 14),
            identity,
          ] else
            Row(
              children: [
                avatar,
                const SizedBox(width: 14),
                Expanded(child: identity),
              ],
            ),
          const SizedBox(height: 14),
          Container(
            key: ValueKey('peer_guardian_role_${subjectId}_$index'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ZyraColors.surfaceFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: guardian.isMain
                    ? accent.withValues(alpha: .38)
                    : ZyraColors.surfaceBorder,
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    guardian.isMain
                        ? Icons.verified_user_outlined
                        : Icons.shield_outlined,
                    size: 17,
                    color: guardian.isMain ? accent : ZyraColors.ink(.58),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    guardian.isMain ? 'Main Guardian' : 'Additional Guardian',
                    style: ZyraText.body(
                      size: 12.25,
                      color: guardian.isMain ? ZyraColors.goldText : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasCity || gender != null) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: ZyraColors.ink(.12)),
            const SizedBox(height: 16),
            if (hasCity) _RecordedDetail(label: 'City', value: city),
            if (hasCity && gender != null) const SizedBox(height: 16),
            if (gender != null) _RecordedDetail(label: 'Gender', value: gender),
          ],
        ],
      ),
    );
  }
}

class _RecordedDetail extends StatelessWidget {
  const _RecordedDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: ZyraText.subtext(size: 11.5)),
      const SizedBox(height: 4),
      Text(value, style: ZyraText.body(size: 15)),
    ],
  );
}

class _GuardianStatus extends StatelessWidget {
  const _GuardianStatus({required this.unavailable});

  final bool unavailable;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              unavailable ? Icons.lock_outline : Icons.people_outline,
              size: 36,
              color: ZyraColors.foregroundMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            unavailable
                ? 'Guardian details are unavailable.'
                : 'No Guardians linked.',
            key: ValueKey(
              unavailable
                  ? 'peer_guardians_unavailable'
                  : 'peer_guardians_empty',
            ),
            style: ZyraText.body(size: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
