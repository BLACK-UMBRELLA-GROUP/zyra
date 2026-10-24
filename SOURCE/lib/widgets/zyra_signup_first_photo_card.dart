import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_onboarding_choice_card.dart';
import 'zyra_profile_image.dart';

/// Signup presentation only. Upload, ownership and recovery belong to the flow.
class ZyraSignupFirstPhotoCard extends StatelessWidget {
  const ZyraSignupFirstPhotoCard({
    super.key,
    required this.photo,
    required this.busy,
    required this.onChoose,
    this.progress,
    this.canChoose = true,
    this.readyText =
        'Your saved main photo is ready. You can edit your photos during profile setup.',
    this.footerText = 'Your profile stays hidden until your setup is complete.',
  });

  final String? photo;
  final bool busy;
  final String? progress;
  final VoidCallback onChoose;
  final bool canChoose;
  final String readyText;
  final String? footerText;

  @override
  Widget build(BuildContext context) => ZyraOnboardingChoiceEntrance(
    child: Column(
      children: [
        if (photo != null) ...[
          Semantics(
            label: 'Your first profile photo',
            image: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                key: const ValueKey('signup_first_photo_preview'),
                width: 170,
                height: 210,
                child: ZyraProfileImage(photo!),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (canChoose)
          IgnorePointer(
            ignoring: busy,
            child: ZyraOnboardingChoiceCard(
              key: const ValueKey('signup_first_photo_choose'),
              label: busy
                  ? progress ?? 'Preparing your photo…'
                  : photo == null
                  ? 'Choose a photo'
                  : 'Choose a different photo',
              icon: Icons.add_photo_alternate_outlined,
              selected: photo != null,
              onTap: onChoose,
            ),
          ),
        if (!canChoose)
          Text(
            readyText,
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 16, color: ZyraColors.journeyGold),
          ),
        if (footerText != null) ...[
          const SizedBox(height: 14),
          Text(
            footerText!,
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 14, color: ZyraColors.ink(0.6)),
          ),
        ],
      ],
    ),
  );
}
