import '../../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import 'zyra_code_screen.dart';

/// Seeker entry point for permanent ZYRA Codes.
class LinkGuardianScreen extends StatelessWidget {
  final VoidCallback onLinked;
  final String? gender;
  final ZyraCodeLocalPreview? localPreview;
  final Widget? previewLeading;

  const LinkGuardianScreen({
    super.key,
    required this.onLinked,
    this.gender,
    this.localPreview,
    this.previewLeading,
  });

  @override
  Widget build(BuildContext context) {
    return ZyraCodeScreen(
      asGuardian: false,
      onLinked: onLinked,
      localPreview: localPreview,
      previewLeading: previewLeading,
    );
  }
}

/// Compatibility wrapper for older callers that embedded the one-use-code
/// panel. It now opens the single governed ZYRA Code surface.
class LinkGuardianPanel extends StatelessWidget {
  final VoidCallback onLinked;

  const LinkGuardianPanel({super.key, required this.onLinked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ZyraColors.accentBg,
          border: Border.all(color: ZyraColors.accentBorder),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: ZyraTapFeedback.onTap(
              context,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ZyraCodeScreen(asGuardian: false, onLinked: onLinked),
                ),
              ),
            ),
            child: Center(
              child: Text('Add a Guardian', style: ZyraText.button()),
            ),
          ),
        ),
      ),
    );
  }
}
