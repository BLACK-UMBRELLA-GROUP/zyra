// Real glassmorphism icon button — backdrop blur (not just a flat
// translucent tint), border, inset highlight. Adapted from the
// founder's old Lovable prototype (src/components/AppShell.tsx
// GLASS_BTN: "bg-white/15 backdrop-blur-2xl border border-white/25" +
// inset shadow) — Flutter needs an actual BackdropFilter to get the
// same frosted-glass-over-photo effect; a flat translucent Container
// alone (what the rest of this app used before) doesn't blur what's
// behind it.

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double size;
  final Color tint;
  final VoidCallback? onTap;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.iconColor = Colors.white,
    this.size = 40,
    this.tint = const Color(0x26FFFFFF), // white/15
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint,
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
              boxShadow: const [
                BoxShadow(color: Color(0x2EFFFFFF), blurRadius: 0, spreadRadius: 0, offset: Offset(0, 1)),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}

/// Larger glass circle used for the brief decision-flash moment
/// (Decline/Save/Like confirmation), matching the Lovable prototype's
/// `flash` overlay: tinted background per action, backdrop blur, white
/// border, inset sheen.
class GlassFlashCircle extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const GlassFlashCircle({super.key, required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tint,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}
