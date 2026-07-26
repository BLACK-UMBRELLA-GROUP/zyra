// The onboarding "continue" FAB.
// Spec: Onboarding Rules & UX §SCREEN ANATOMY — FAB.
// Always visible, never hidden. Dimmed when the current answer is
// invalid/missing, active once valid. Bottom right, 14px from bottom,
// 16px from right, 26px circle.

import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';

class FabContinueButton extends StatelessWidget {
  final bool active;
  final VoidCallback? onPressed;

  const FabContinueButton({super.key, required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 14,
      right: 16,
      child: GestureDetector(
        onTap: active ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? ZyraColors.fabActiveBg : ZyraColors.fabDimmedBg,
            border: Border.all(
              color: active ? ZyraColors.fabActiveBorder : ZyraColors.fabDimmedBorder,
              width: 0.5,
            ),
          ),
          child: Icon(
            Icons.arrow_forward,
            size: 20,
            color: active ? ZyraColors.fabActiveArrow : ZyraColors.fabDimmedArrow,
          ),
        ),
      ),
    );
  }
}
