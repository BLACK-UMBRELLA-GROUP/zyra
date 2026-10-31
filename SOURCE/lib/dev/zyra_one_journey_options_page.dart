import '../widgets/zyra_floating_surface.dart';
// LOCK13 presentation only. The shell retains every destination and gate.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_tap_feedback.dart';

class ZyraOneJourneyOptionsPage extends StatelessWidget {
  const ZyraOneJourneyOptionsPage({
    super.key,
    required this.id,
    required this.firstName,
    required this.surname,
    required this.details,
    required this.nationality,
    required this.stageNumber,
    required this.stageLabel,
    required this.photo,
    required this.onContinue,
    required this.options,
  });
  final String id, firstName, surname, details, nationality, stageLabel;
  final int stageNumber;
  final String? photo;
  final VoidCallback onContinue;
  final Widget options;

  Widget _identity() => Column(
    children: [
      Container(
        key: ValueKey('journey_options_photo_$id'),
        width: 88,
        height: 88,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ZyraColors.journeyGold.withValues(alpha: .7),
          ),
        ),
        child: ClipOval(
          child: photo == null
              ? const Icon(Icons.person_outline, size: 40)
              : ZyraProfileImage(photo!),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        '$firstName $surname'.trim(),
        textAlign: TextAlign.center,
        style: ZyraText.heading(
          size: 24,
        ).copyWith(height: 1.2, fontWeight: FontWeight.w300),
      ),
      const SizedBox(height: 8),
      Text(
        'STAGE $stageNumber OF 8 · ${stageLabel.toUpperCase()}',
        textAlign: TextAlign.center,
        style: ZyraText.body(
          size: 11,
          color: ZyraColors.goldText,
        ).copyWith(height: 1.3, letterSpacing: 1.2),
      ),
      const SizedBox(height: 10),
      Text(
        '$details · $nationality',
        textAlign: TextAlign.center,
        style: ZyraText.body(
          size: 13,
          color: ZyraColors.mutedText,
        ).copyWith(height: 1.3),
      ),
    ],
  );

  Widget _continue(BuildContext context) => Material(
    type: MaterialType.transparency,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      key: ValueKey('draft_journey_$id'),
      onTap: ZyraTapFeedback.onTap(context, onContinue),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: ZyraFloatingSurface(
          radius: 999,
          circle: false,
          gold: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ZyraColors.goldTextFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Continue Journey',
                textAlign: TextAlign.center,
                style: ZyraText.button(size: 14, color: ZyraColors.espresso),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 98),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Journey',
            style: ZyraText.heading(size: 26).copyWith(height: 1.2),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: SizedBox(
              key: ValueKey('journey_options_card_$id'),
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final reading =
                      MediaQuery.textScalerOf(context).scale(1) > 1 ||
                      MediaQuery.boldTextOf(context) ||
                      bounds.maxHeight < 700 ||
                      bounds.maxWidth < 350;
                  final header = [
                    _identity(),
                    const SizedBox(height: 12),
                    _continue(context),
                    const SizedBox(height: 12),
                  ];
                  return reading
                      ? ZyraShadowScrollView(
                          key: ValueKey('journey_options_scroll_$id'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [...header, options],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...header,
                            Expanded(child: options),
                          ],
                        );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
