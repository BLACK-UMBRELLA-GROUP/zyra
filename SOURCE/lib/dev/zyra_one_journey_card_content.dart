// Locked Journey-card interior. The caller retains the existing card shell,
// true per-person data and guarded actions; this file owns no app authority.
import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

enum ZyraOneJourneyCardDesign {
  portraitSplit('Portrait split', 'Portrait left, identity and actions right.');

  const ZyraOneJourneyCardDesign(this.label, this.description);
  final String label;
  final String description;
}

class ZyraOneJourneyCardContent extends StatelessWidget {
  const ZyraOneJourneyCardContent({
    super.key,
    required this.design,
    required this.profile,
    required this.photo,
    required this.action,
    required this.fillHeight,
    this.primaryButton,
    this.optionsButton,
    this.report,
    this.stateLabel,
    this.stageLabel,
    this.inlineOptions,
    this.inlineOptionsFillHeight = true,
  });

  final ZyraOneJourneyCardDesign design;
  final SeekerProfile profile;
  final Widget photo;
  final Widget action;
  final Widget? primaryButton;
  final Widget? optionsButton;
  final Widget? report;
  // Retained caller metadata, deliberately not displayed by the locked layout.
  final String? stateLabel;
  final String? stageLabel;
  final bool fillHeight;
  final Widget? inlineOptions;
  final bool inlineOptionsFillHeight;

  Widget _portrait() => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(width: 104, height: 104, child: photo),
  );

  Widget _identity() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.firstName, style: ZyraText.heading(size: 19)),
          if ((profile.surnameLine ?? '').trim().isNotEmpty)
            Text(
              profile.surnameLine!.trim(),
              style: ZyraText.heading(size: 15, color: ZyraColors.ink(.86)),
            ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '${profile.age} · ${profile.city}',
        style: ZyraText.subtext(size: 12.5, color: ZyraColors.ink(.78)),
      ),
      if ((profile.publicNationality ?? '').trim().isNotEmpty)
        Text(
          'Nationality: ${profile.publicNationality!.trim()}',
          style: ZyraText.subtext(size: 12, color: ZyraColors.ink(.78)),
        ),
      if ((profile.publicEthnicity ?? '').trim().isNotEmpty)
        Text(
          'Ethnicity: ${profile.publicEthnicity!.trim()}',
          style: ZyraText.subtext(size: 12, color: ZyraColors.ink(.78)),
        ),
    ],
  );

  Widget _header() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _portrait(),
      const SizedBox(width: 12),
      Expanded(child: _identity()),
      ?report,
    ],
  );

  Widget _quietMinimal() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(),
      const SizedBox(height: 8),
      if (fillHeight && inlineOptions == null) const Spacer(),
      action,
      if (inlineOptions != null) ...[
        const SizedBox(height: 16),
        if (inlineOptionsFillHeight)
          Expanded(child: inlineOptions!)
        else
          inlineOptions!,
      ],
    ],
  );

  Widget _comparisonPortrait({required double referenceHeight}) => SizedBox(
    key: ValueKey('journey_card_photo_${design.name}'),
    height: referenceHeight,
    child: ClipRRect(borderRadius: BorderRadius.circular(14), child: photo),
  );

  Widget _comparisonIdentity({bool withOptions = false}) => Row(
    key: ValueKey('journey_card_identity_${design.name}'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _identity()),
      if (withOptions && optionsButton != null) optionsButton!,
      ?report,
    ],
  );

  Widget _sidePortrait() {
    final portrait = Expanded(
      flex: 46,
      child: _comparisonPortrait(referenceHeight: 144),
    );
    final identityAndAction = Expanded(
      flex: 54,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _comparisonIdentity(withOptions: true),
          const SizedBox(height: 10),
          const Spacer(),
          primaryButton ?? action,
        ],
      ),
    );
    // IntrinsicHeight supplies a finite natural envelope when this card is
    // not filling a slot, while tight multi-card slots stretch the portrait.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [portrait, const SizedBox(width: 12), identityAndAction],
      ),
    );
  }

  Widget _expandedOptions() {
    final options = KeyedSubtree(
      key: const ValueKey('journey_card_expanded_options'),
      child: inlineOptions!,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: const ValueKey('journey_card_expanded_header'),
          child: _header(),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey('journey_card_expanded_action'),
          child: action,
        ),
        const SizedBox(height: 12),
        // Extra height belongs between the options, not around this action.
        // The whole-card reading fallback remains natural-height and scrolls.
        if (inlineOptionsFillHeight) Expanded(child: options) else options,
      ],
    );
  }

  @override
  Widget build(BuildContext context) => switch (design) {
    ZyraOneJourneyCardDesign.portraitSplit when inlineOptions != null =>
      _expandedOptions(),
    ZyraOneJourneyCardDesign.portraitSplit
        when MediaQuery.textScalerOf(context).scale(1) > 1.3 =>
      _quietMinimal(),
    ZyraOneJourneyCardDesign.portraitSplit => _sidePortrait(),
  };
}
