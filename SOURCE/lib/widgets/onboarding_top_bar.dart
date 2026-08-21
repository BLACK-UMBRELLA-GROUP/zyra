// Top bar for onboarding question screens.
// Spec: Onboarding Rules & UX §SCREEN ANATOMY — TOP BAR.
// Single row, always present: [progress area, flex-grows] [··· help button]

import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

class OnboardingTopBar extends StatelessWidget {
  final String chapterName;
  final double chapterProgress; // 0.0 - 1.0, resets each chapter
  final bool chapterComplete;
  final VoidCallback onHelpTap;

  const OnboardingTopBar({
    super.key,
    required this.chapterName,
    required this.chapterProgress,
    required this.onHelpTap,
    this.chapterComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = chapterComplete
        ? ZyraColors.progressCompleteFill
        : ZyraColors.progressFill;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chapterName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZyraText.chapterLabel(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(chapterProgress * 100).round()}%',
                        style: ZyraText.chapterLabel(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ··· bare dots, no circle, no background — opens help sheet
                GestureDetector(
                  onTap: onHelpTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('···', style: ZyraText.body(size: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 1.5,
                child: LinearProgressIndicator(
                  value: chapterProgress.clamp(0.0, 1.0),
                  backgroundColor: ZyraColors.progressTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
