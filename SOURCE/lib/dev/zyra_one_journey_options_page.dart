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
    required this.ethnicity,
    required this.photo,
    required this.onContinue,
    required this.options,
  });
  final String id, firstName, surname, details, nationality, ethnicity;
  final String? photo;
  final VoidCallback onContinue;
  final Widget options;

  Widget _identity() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          key: ValueKey('journey_options_photo_$id'),
          width: 104,
          height: 104,
          child: photo == null
              ? const Icon(Icons.person_outline, size: 40)
              : ZyraProfileImage(photo!),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              firstName,
              style: ZyraText.heading(size: 22).copyWith(height: 1.2),
            ),
            Text(
              surname,
              style: ZyraText.heading(
                size: 16,
                color: ZyraColors.ink(.7),
              ).copyWith(height: 1.2),
            ),
            const SizedBox(height: 5),
            for (final line in [
              details,
              'Nationality: $nationality',
              'Ethnicity: $ethnicity',
            ])
              Text(
                line,
                style: ZyraText.body(
                  size: 13,
                  color: ZyraColors.ink(.7),
                ).copyWith(height: 1.3),
              ),
          ],
        ),
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
        child: Container(
          constraints: const BoxConstraints(minHeight: 41),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ZyraColors.surfaceFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: Text('Continue Journey', style: ZyraText.button(size: 14)),
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
          Text('Journey', style: ZyraText.heading(size: 26)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              key: ValueKey('journey_options_card_$id'),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: ZyraColors.surfaceFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ZyraColors.journeyGold.withValues(alpha: .6),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final reading =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                      MediaQuery.boldTextOf(context) ||
                      bounds.maxHeight < 600;
                  final header = [
                    _identity(),
                    const SizedBox(height: 14),
                    _continue(context),
                    const SizedBox(height: 12),
                  ];
                  return reading
                      ? SingleChildScrollView(
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
